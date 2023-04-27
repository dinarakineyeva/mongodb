resource "mongodbatlas_cluster" "cluster" {
  project_id             = var.project_id_mongo
  name                   = var.cluster_name
  mongo_db_major_version = var.mongodbversion
  cluster_type           = var.cluster_type
  replication_specs {
    num_shards = var.num_shards
    regions_config {
      region_name     = var.region_name
      electable_nodes = var.electable_nodes
      priority        = var.priority
      read_only_nodes = var.read_only_nodes
    }
  }
  # Provider Settings "block"
  cloud_backup                 = var.cloud_backup
  auto_scaling_disk_gb_enabled = var.auto_scaling_disk_gb_enabled
  provider_name                = var.cloud_provider
  provider_instance_size_name  = var.provider_instance_size_name
}
