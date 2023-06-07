#######################
#   Atlas Cluster     #
#######################

resource "mongodbatlas_cluster" "cluster" {
  count = var.cluster_name == "" ? 0 : 1
  project_id = mongodbatlas_privatelink_endpoint_service.test.project_id
  name                   = var.cluster_name
  mongo_db_major_version = var.mongodbversion
  cluster_type           = var.cluster_type
  replication_specs {
    num_shards = var.num_shards
    dynamic "regions_config" {
      for_each = var.regions_config
      content {
        region_name           = lookup(regions_config.value, "region_name",  "CENTRAL_US")  
        electable_nodes       = lookup(regions_config.value, "electable_nodes",  3)
        priority              = lookup(regions_config.value, "priority",  7)
        read_only_nodes       = lookup(regions_config.value, "read_only_nodes",  0)
    }
    }
  }
  
  # Provider Settings "block"
  cloud_backup                 = var.cloud_backup
  auto_scaling_disk_gb_enabled = var.auto_scaling_disk_gb_enabled
  provider_name                = var.cloud_provider
  provider_instance_size_name  = var.provider_instance_size_name
  termination_protection_enabled = var.termination_protection_enabled
  dynamic "advanced_configuration" {
    for_each = [var.advanced_configuration]
    content {
      javascript_enabled                   = lookup(advanced_configuration.value, "javascript_enabled",  true) 
      minimum_enabled_tls_protocol         = lookup(advanced_configuration.value, "minimum_enabled_tls_protocol", null) #"TLS1_2"
      oplog_min_retention_hours            = lookup(advanced_configuration.value, "oplog_min_retention_hours", 24)
    }
 }
}



# ===== Service Account for KMS ===== #
resource "google_service_account" "encryption_at_rest" {
  project       = var.gcp_project
  account_id    = substr("atlas-encrypt-sa-${mongodbatlas_cluster.cluster.0.name}", 0, 25)
  display_name  = "atlas-encrypt-${var.cluster_name}"
}

resource "google_project_iam_member" "encryption_at_rest" {
  for_each  = toset([
    "roles/cloudkms.admin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/owner",
  ])
  project   = var.gcp_project
  role      = each.value
  member    = "serviceAccount:atlas-encrypt-sar@${var.gcp_project}.iam.gserviceaccount.com"
}

# ====== Create service account key ===== #
resource "google_service_account_key" "encryption_at_rest" {
  service_account_id = "atlas-encrypt-sar@${var.gcp_project}.iam.gserviceaccount.com"
  public_key_type     = "TYPE_X509_PEM_FILE"

}

#######################
#        KMS          #
#######################

# ===== Create keyring for encryption_at_rest ===== #
resource "google_kms_key_ring" "encryption_at_rest" {
  project   = var.gcp_project
  name      = "atlas-keyring-${random_pet.random_pet_for_instance.id}"
  location  = "global"
}

resource "google_kms_crypto_key" "crypto_key" {
  name      = "atlas-crypto-key-${random_pet.random_pet_for_instance.id}"
  key_ring  = google_kms_key_ring.encryption_at_rest.id

  depends_on = [google_kms_key_ring.encryption_at_rest]
}

# ===== Atlas encryption_at_rest ===== #
resource "mongodbatlas_encryption_at_rest" "kms" {
  project_id                = var.project_id_mongo
  google_cloud_kms_config {
    enabled                 = true
    service_account_key     = base64decode(google_service_account_key.encryption_at_rest.private_key)
    key_version_resource_id = "${google_kms_crypto_key.crypto_key.id}/cryptoKeyVersions/1"
  }

  depends_on = [google_kms_crypto_key.crypto_key, google_service_account_key.encryption_at_rest]
}




# ==== On Mongo Cloud(organization) ->Access Manager -> APÌ Keys -> Private Key & Access List (add the ip of the machine which runs terraform commands) ==== #
resource "mongodbatlas_cloud_backup_schedule" "test" {
  count                    = var.mongodb_enabled ? 1 : 0
  project_id   = mongodbatlas_cluster.cluster.0.project_id
  cluster_name = mongodbatlas_cluster.cluster.0.name

  reference_hour_of_day    = 3
  reference_minute_of_hour = 45
  restore_window_days      = 4


  // This will now add the desired policy items to the existing mongodbatlas_cloud_backup_schedule resource
  policy_item_daily {
    frequency_interval = 1        #accepted values = 1 -> every 1 day
    retention_unit     = "days"
    retention_value    = 2
  }
  policy_item_weekly {
    frequency_interval = 4        # accepted values = 1 to 7 -> every 1=Monday,2=Tuesday,3=Wednesday,4=Thursday,5=Friday,6=Saturday,7=Sunday day of the week
    retention_unit     = "weeks"
    retention_value    = 3
  }
  
  depends_on = [mongodbatlas_cluster.cluster]
}


resource "random_pet" "random_pet_for_instance" {
  length    = 1
  separator = "-"
}
