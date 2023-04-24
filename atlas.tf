

provider "mongodbatlas" {
  public_key  = var.atlas_pub_key
  private_key = var.atlas_priv_key
}

resource "mongodbatlas_project" "demo" {
  name   = local.project_id
  org_id = var.atlas_org_id
}

resource "mongodbatlas_project_ip_access_list" "acl" {
  project_id = mongodbatlas_project.demo.id
  cidr_block = "0.0.0.0/0"
}

resource "mongodbatlas_cluster" "cluster" {
  project_id = mongodbatlas_project.demo.id
  name       = local.project_id
  cluster_type           = "REPLICASET"
  provider_name               = "GCP"
  # backing_provider_name       = "GCP"
  provider_region_name        = var.atlas_cluster_region
  provider_instance_size_name = var.atlas_cluster_tier
  cloud_backup                 = true
  auto_scaling_disk_gb_enabled            = true
  mongo_db_major_version                  = "4.4"
  # auto_scaling_compute_enabled            = true
  # auto_scaling_compute_scale_down_enabled = true

  labels {
    key   = "environment"
    value = "prod"
  }

  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "CENTRAL_US"
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }
}

resource "mongodbatlas_database_user" "user" {
  project_id         = mongodbatlas_project.demo.id
  auth_database_name = "admin"

  username = var.db_user
  password = random_string.mongodb_password.result

  roles {
    role_name     = "readWrite"
    database_name = var.db_name
  }
}

locals {
  # the demo app only takes URIs with the credentials embedded and the atlas
  # provider doesn't give us a good way to get the hostname without the protocol
  # part so we end up doing some slicing and dicing to get the creds into the URI
  atlas_uri = replace(
    mongodbatlas_cluster.cluster.srv_address,
    "://",
    "://${var.db_user}:${mongodbatlas_database_user.user.password}@"
  )
}

# resource "mongodbatlas_cloud_backup_schedule" "test" {
#   project_id   = mongodbatlas_cluster.cluster.project_id
#   cluster_name = mongodbatlas_cluster.cluster.name

#   reference_hour_of_day    = 3
#   reference_minute_of_hour = 45
#   restore_window_days      = 4


#   // This will now add the desired policy items to the existing mongodbatlas_cloud_backup_schedule resource
#   policy_item_hourly {
#     frequency_interval = 1
#     retention_unit     = "days"
#     retention_value    = 1
#   }
#   policy_item_daily {
#     frequency_interval = 1
#     retention_unit     = "days"
#     retention_value    = 2
#   }
# }
