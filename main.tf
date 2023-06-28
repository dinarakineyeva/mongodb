#######################
#   Atlas Cluster     #
#######################
resource "mongodbatlas_project" "project" {
  name   = "${var.environment}-${var.project_name}"
  org_id = var.org_id
}

resource "mongodbatlas_cluster" "cluster" {
  count                  = length(var.cluster_name)
  project_id             = mongodbatlas_privatelink_endpoint_service.test.project_id
  name                   = "${local.cluster_name}-${var.cluster_name[count.index]}"
  mongo_db_major_version = var.mongodbversion
  cluster_type           = var.cluster_type
  replication_specs {
    num_shards = var.num_shards
    dynamic "regions_config" {
      for_each = var.regions_config
      content {
        region_name     = lookup(regions_config.value, "region_name", "CENTRAL_US")
        electable_nodes = lookup(regions_config.value, "electable_nodes", 3)
        priority        = lookup(regions_config.value, "priority", 7)
        read_only_nodes = lookup(regions_config.value, "read_only_nodes", 0)
      }
    }
  }

  # Provider Settings "block"
  cloud_backup                   = var.cloud_backup
  auto_scaling_disk_gb_enabled   = var.auto_scaling_disk_gb_enabled
  provider_name                  = var.cloud_provider
  provider_instance_size_name    = var.provider_instance_size_name
  termination_protection_enabled = var.termination_protection_enabled
  dynamic "advanced_configuration" {
    for_each = [var.advanced_configuration]
    content {
      javascript_enabled           = lookup(advanced_configuration.value, "javascript_enabled", true)
      minimum_enabled_tls_protocol = lookup(advanced_configuration.value, "minimum_enabled_tls_protocol", null) #"TLS1_2"
      oplog_min_retention_hours    = lookup(advanced_configuration.value, "oplog_min_retention_hours", 24)
    }
  }
}

# ===== Service Account for KMS ===== #
resource "google_service_account" "encryption_at_rest" {
  project      = var.gcp_project
  account_id   = "atlas-encrypt-mongo-${var.environment}"
  display_name = "atlas-encrypt-${var.environment}"
}

resource "google_project_iam_member" "encryption_at_rest" {
  for_each = toset([
    "roles/cloudkms.admin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/owner",
  ])
  project = var.gcp_project
  role    = each.value
  member  = "serviceAccount:atlas-encrypt-mongo-${var.environment}@${var.gcp_project}.iam.gserviceaccount.com"
}

# ====== Create service account key ===== #
resource "google_service_account_key" "encryption_at_rest" {
  service_account_id = "atlas-encrypt-mongo-${var.environment}@${var.gcp_project}.iam.gserviceaccount.com"
  public_key_type    = "TYPE_X509_PEM_FILE"

}

#######################
#        KMS          #
#######################

# ===== Create keyring for encryption_at_rest ===== #
resource "google_kms_key_ring" "encryption_at_rest" {
  project  = var.gcp_project
  name     = "atlas-keyring-${random_id.rng.hex}"
  location = "global"
}

resource "google_kms_crypto_key" "crypto_key" {
  name     = "atlas-crypto-key-${random_id.rng.hex}"
  key_ring = google_kms_key_ring.encryption_at_rest.id

  depends_on = [google_kms_key_ring.encryption_at_rest]
}

# ===== Atlas encryption_at_rest ===== #
resource "mongodbatlas_encryption_at_rest" "kms" {
  project_id = mongodbatlas_project.project.id
  google_cloud_kms_config {
    enabled                 = true
    service_account_key     = base64decode(google_service_account_key.encryption_at_rest.private_key)
    key_version_resource_id = "${google_kms_crypto_key.crypto_key.id}/cryptoKeyVersions/1"
  }

  depends_on = [google_kms_crypto_key.crypto_key, google_service_account_key.encryption_at_rest]
}

# ==== On Mongo Cloud(organization) ->Access Manager -> APÌ Keys -> Private Key & Access List (add the ip of the machine which runs terraform commands) ==== #
resource "mongodbatlas_cloud_backup_schedule" "test" {
  count        = var.mongodb_enabled ? 1 : 0
  project_id   = mongodbatlas_cluster.cluster.0.project_id
  cluster_name = mongodbatlas_cluster.cluster.0.name

  reference_hour_of_day    = 3
  reference_minute_of_hour = 45
  restore_window_days      = 4


  // This will now add the desired policy items to the existing mongodbatlas_cloud_backup_schedule resource
  policy_item_daily {
    frequency_interval = 1 #accepted values = 1 -> every 1 day
    retention_unit     = "days"
    retention_value    = 2
  }
  policy_item_weekly {
    frequency_interval = 4 # accepted values = 1 to 7 -> every 1=Monday,2=Tuesday,3=Wednesday,4=Thursday,5=Friday,6=Saturday,7=Sunday day of the week
    retention_unit     = "weeks"
    retention_value    = 3
  }

  depends_on = [mongodbatlas_cluster.cluster]
}

resource "mongodbatlas_cloud_backup_snapshot" "test" {
  project_id        = mongodbatlas_cluster.cluster.0.project_id
  cluster_name      = mongodbatlas_cluster.cluster.0.name
  description       = var.description
  retention_in_days = var.retention_in_days
}


##########################
#  privatelink endpoint  #
##########################
resource "mongodbatlas_privatelink_endpoint" "mongoatlas_primary" {
  project_id    = mongodbatlas_project.project.id
  provider_name = "GCP"
  region        = var.gcp_region
  # depends_on = [ mongodbatlas_cluster.cluster ]
}

# ===== Create a Google Network ===== #
resource "google_compute_network" "default" {
  project = var.gcp_project
  name    = "${var.environment}-network"
}

# ==== Create a Google Sub Network ===== #
resource "google_compute_subnetwork" "default" {
  project       = google_compute_network.default.project
  name          = "${var.environment}-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.gcp_region
  network       = google_compute_network.default.id
}


# ===== Create Google 50 Addresses ===== #
resource "google_compute_address" "compute_address" {
  count        = 50
  project      = google_compute_subnetwork.default.project
  name         = "${var.compute_address_name}-${count.index}"
  subnetwork   = google_compute_subnetwork.default.id
  address_type = var.google_compute_address_type
  address      = "${var.google_compute_address}${count.index}"
  region       = google_compute_subnetwork.default.region

  depends_on = [mongodbatlas_privatelink_endpoint.mongoatlas_primary]
}

# ==== Create 50 Forwarding rules ===== #
resource "google_compute_forwarding_rule" "compute_forwarding_rule" {
  count                 = 50
  project               = google_compute_address.compute_address[count.index].project
  region                = google_compute_address.compute_address[count.index].region
  name                  = google_compute_address.compute_address[count.index].name
  target                = mongodbatlas_privatelink_endpoint.mongoatlas_primary.service_attachment_names[count.index]
  ip_address            = google_compute_address.compute_address[count.index].id
  network               = google_compute_network.default.id
  load_balancing_scheme = ""
}

resource "mongodbatlas_privatelink_endpoint_service" "test" {
  project_id          = mongodbatlas_privatelink_endpoint.mongoatlas_primary.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.mongoatlas_primary.private_link_id
  provider_name       = "GCP"
  endpoint_service_id = google_compute_network.default.name
  gcp_project_id      = var.gcp_project

  dynamic "endpoints" {
    for_each = mongodbatlas_privatelink_endpoint.mongoatlas_primary.service_attachment_names

    content {
      ip_address    = google_compute_address.compute_address[endpoints.key].address
      endpoint_name = google_compute_forwarding_rule.compute_forwarding_rule[endpoints.key].name
    }
  }

  depends_on = [google_compute_forwarding_rule.compute_forwarding_rule]
}

# DATABASE USER  [Configure Database Users](https://docs.atlas.mongodb.com/security-add-mongodb-users/)
resource "mongodbatlas_database_user" "user" {
  username           = var.db_username
  password           = var.db_password
  project_id         = mongodbatlas_project.project.id
  auth_database_name = var.auth_database_name

  roles {
    role_name     = var.db_role_name
    database_name = var.database_name # The database name and collection name need not exist in the cluster before creating the user.
  }
  labels {
    key   = var.db_key
    value = var.db_value
  }
}

# ===== custom roles ==== #
resource "mongodbatlas_custom_db_role" "database-ro-role" {
  project_id = mongodbatlas_project.project.id
  role_name  = "${local.mongodb_database_name}_rw"

  dynamic "actions" {
    for_each = local.mongodb_ro_role_actions
    content {
      action = actions.value
      resources {
        collection_name = ""
        database_name   = local.mongodb_database_name
      }
    }
  }
}

resource "mongodbatlas_custom_db_role" "database-rw-role" {
  project_id = mongodbatlas_project.project.id
  role_name  = "${local.mongodb_database_name}_rw_role"

  dynamic "actions" {
    for_each = local.mongodb_rw_role_actions
    content {
      action = actions.value
      resources {
        collection_name = ""
        database_name   = local.mongodb_database_name
      }
    }
  }
}

resource "mongodbatlas_custom_db_role" "database-admin-role" {
  project_id = mongodbatlas_project.project.id
  role_name  = "${local.mongodb_database_name}_admin"

  dynamic "actions" {
    for_each = concat(local.mongodb_rw_role_actions, local.mongodb_admin_role_actions)
    content {
      action = actions.value
      resources {
        collection_name = ""
        database_name   = local.mongodb_database_name
      }
    }
  }

  dynamic "inherited_roles" {
    for_each = local.mongodb_admin_built_in_roles
    content {
      database_name = local.mongodb_database_name
      role_name     = inherited_roles.value
    }
  }
}

# ==== database read-only user ==== #
resource "mongodbatlas_database_user" "database-ro-user" {
  project_id         = mongodbatlas_project.project.id
  auth_database_name = var.auth_database_name
  username           = local.mongodb_ro_username
  password           = local.mongodb_ro_password

  roles {
    role_name     = mongodbatlas_custom_db_role.database-ro-role.role_name
    database_name = var.database_name
  }
}

# ==== database read-write user ==== #
resource "mongodbatlas_database_user" "database-rw-user" {
  project_id         = mongodbatlas_project.project.id
  auth_database_name = var.auth_database_name
  username           = local.mongodb_rw_username
  password           = local.mongodb_rw_password

  roles {
    role_name     = mongodbatlas_custom_db_role.database-rw-role.role_name
    database_name = var.database_name
  }
}

# ===== database admin user ===== #
resource "mongodbatlas_database_user" "database-admin-user" {
  project_id         = mongodbatlas_project.project.id
  auth_database_name = var.auth_database_name
  username           = local.mongodb_admin_username
  password           = local.mongodb_admin_password

  roles {
    role_name     = mongodbatlas_custom_db_role.database-admin-role.role_name
    database_name = var.database_name
  }
}

resource "random_password" "database-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# resource "random_password" "database-admin-password" {
#   length           = 16
#   special          = true
#   override_special = "_%@"
# }

resource "random_id" "rng" {
  keepers = {
    first = "${timestamp()}"
  }
  byte_length = 8
}
