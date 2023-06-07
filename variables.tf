#=======================Mongo Atlas Variables=========================#
variable "project_id_mongo" {
  description = "The project ID for MongoDB Atlas. This variable is used to specify the project ID of the MongoDB Atlas project."
}

variable "cloud_provider" {
type = string
description = "The cloud provider to use. This variable is used to specify the cloud provider for the MongoDB Atlas cluster. Valid values are AWS, GCP, or AZURE."
}

variable "cluster_name" {
  type = string
  description = "The name of the MongoDB Atlas cluster. This variable is used to specify the name of the MongoDB Atlas cluster."
}

variable "mongodbversion" {
  type = string
  description = "(Optional) Version of the cluster to deploy. Atlas supports the following MongoDB versions for M10+ clusters: 4.2, 4.4, 5.0, or 6.0. If omitted, Atlas deploys a cluster that runs MongoDB 5.0. If provider_instance_size_name: M0, M2 or M5, Atlas deploys MongoDB 5.0. Atlas always deploys the cluster with the latest stable release of the specified version."
}

variable "termination_protection_enabled" {
  type = bool  
  description = "Indicates whether termination protection is enabled for the cluster. This variable is used to enable or disable termination protection for the MongoDB Atlas cluster."
}

variable "cluster_type" {
  type        = string
  description = "(Required) Specifies the type of the cluster that you want to modify. You cannot convert a sharded cluster deployment to a replica set deployment. Types: 'REPLICASET' Replica set 'SHARDED' Sharded cluster 'GEOSHARDED' Global Cluster."
}

variable "cloud_backup" {
  type        = bool   
  description = "(Optional) Flag indicating if the cluster uses Cloud Backup for backups.If true, the cluster uses Cloud Backup for backups. If cloud_backup and backup_enabled are false, the cluster does not use Atlas backups."
}

variable "auto_scaling_disk_gb_enabled" {
  type        = bool
  description = " (Optional) Specifies whether cluster tier auto-scaling is enabled. The default is false."
}

variable "provider_instance_size_name" {
  type        = string
  description = "(Required) Atlas provides different instance sizes, each with a default storage capacity and RAM size. The instance size you select is used for all the data-bearing servers in your cluster. M0, M2, M5, M10 or higher. "
}

variable "advanced_configuration" {
  description = "Advanced configuration options for the MongoDB Atlas cluster. This variable is used to specify advanced configuration options as an object. 'Javascript_enabled' - (Optional) When true, the cluster allows execution of operations that perform server-side executions of JavaScript. When false, the cluster disables execution of those operations. 'minimum_enabled_tls_protocol' - (Optional) Sets the minimum Transport Layer Security (TLS) version the cluster accepts for incoming connections."
    type = object({
    javascript_enabled = bool
    minimum_enabled_tls_protocol = string
    oplog_min_retention_hours = number
    })
    default = {
    javascript_enabled = true
    minimum_enabled_tls_protocol = "TLS1_2"
    oplog_min_retention_hours = 24
    }
}

variable "num_shards" {
  type        = number
  description = "(Required) Number of shards to deploy in the specified zone, minimum 1"
}

variable "region_name" {
  type        = string
  description = "(Optional) Physical location of your MongoDB cluster. The region you choose can affect network latency for clients accessing your databases. Requires the Atlas region name, see the reference list for AWS, GCP, Azure."
}

variable "electable_nodes" {
  type      = number
  description = "(Optional) Number of electable nodes for Atlas to deploy to the region. Electable nodes can become the primary and can facilitate local reads."
}

variable "priority" {
  type        = number  
  description = " (Optional) Election priority of the region. For regions with only read-only nodes, set this value to 0."
}

variable "read_only_nodes" {
  type        = number
  description = "(Optional) Number of read-only nodes for Atlas to deploy to the region. Read-only nodes can never become the primary, but can facilitate local-reads. Specify 0 if you do not want any read-only nodes in the region."
}

variable "mongodb_enabled" {
  description = "value"
  type = bool
  default = false
}

#==================Google Cloud Platform Variables====================#

variable "gcp_project" {
  description = "The project ID for the Google Cloud Platform (GCP) project. This variable is used to specify the project ID of the GCP project."
}

variable "google_compute_address_type" {
  type        = string
  description = "(Optional) The type of address to reserve. Note: if you set this argument's value as INTERNAL you need to leave the network_tier argument unset in that resource block. Default value is EXTERNAL. Possible values are: INTERNAL, EXTERNAL."
}

variable "google_compute_address" {
  type        = string
  description = " (Optional) The static external IP address represented by this resource. Only IPv4 is supported. An address may only be specified for INTERNAL address types. The IP address must be inside the specified subnetwork, if any. Set by the API if undefined."
}

#privatelink variables
variable "gcp_region" {
  type        = string
  description = " (Required) Cloud provider region in which you want to create the private endpoint connection. Accepted values are: AWS regions, AZURE regions and GCP regions"
}

variable "network_name" {
  description = "value"
}
variable "subnet_name" {
  description = "value"
}

variable "compute_address_name" {
  description = "value"
}

#========================Mongo User Variables=========================#

variable "db_username" {
  type        = string
  description = "(Required) Username for authenticating to MongoDB. "
}

variable "db_password" {
  type        = string
  description = " (Required) User's initial password."
}

variable "auth_database_name" {
  type        = string
  description = "(Required) Database against which Atlas authenticates the user. A user must provide both a username and authentication database to log into MongoDB."
}

variable "db_role_name" {
  type        = string   
  description = "(Required) Name of the role to grant. "
}
variable "database_name" {
  type        = string
  description = "(Required) Database on which the user has the specified role. A role on the admin database can include privileges that apply to the other databases."
}

variable "db_key" {
  type        = string 
  description = "Containing key-value pairs that tag and categorize the database user. Each key and value has a maximum length of 255 characters.The key that you want to write."
}
variable "db_value" {
  type        = string
  description = "Containing key-value pairs that tag and categorize the database user. Each key and value has a maximum length of 255 characters.The value that you want to write."
}
