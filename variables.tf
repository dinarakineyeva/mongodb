variable "project_id_mongo" {}

variable "gcp_project" {}

variable "network_name" {}

variable "cloud_provider" {
  type        = string
  description = "The cloud provider to use, must be AWS, GCP or AZURE"
}
variable "cluster_name" {
  type        = string
  description = "The MongoDB Atlas Cluster Name"
}
variable "mongodbversion" {
  type        = string
  description = "The Major MongoDB Version"
}

variable "cluster_type" {}
variable "cloud_backup" {}
variable "auto_scaling_disk_gb_enabled" {}
variable "provider_instance_size_name" {}
variable "num_shards" {}
variable "region_name" {}
variable "electable_nodes" {}
variable "priority" {}
variable "read_only_nodes" {}
variable "db_username" {
  type        = string
  description = "MongoDB Atlas Database User Name"
}
variable "db_password" {
  type        = string
  description = "MongoDB Atlas Database User Password"
}
variable "auth_database_name" {
  type        = string
  description = "The database in the cluster to limit the database user to, the database does not have to exist yet"
}
variable "db_role_name" {}
variable "database_name" {}
variable "db_key" {}
variable "db_value" {}
# variable "mongodb_cidr_block" {}
# variable "comment" {}
variable "gcp_region" {}
variable "subnet_name" {}
variable "google_compute_address_type" {}
variable "google_compute_address" {}
