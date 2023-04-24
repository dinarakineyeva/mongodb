

###-----------------------------------------------------------------------------
### general config
###-----------------------------------------------------------------------------

variable "project_name" {
  type        = string
  description = "the base name to use when creating resources. a randomized suffix will be added."
  default     = "gcp-demo"
}


###-----------------------------------------------------------------------------
### Google Cloud
###-----------------------------------------------------------------------------

# variable "google_billing_account" {
#   type        = string
#   description = "the ID of your Google Cloud billing account"
# }


###-----------------------------------------------------------------------------
### region config
###-----------------------------------------------------------------------------

# Please refer to https://www.mongodb.com/docs/atlas/reference/google-gcp/#std-label-google-gcp
# for a mapping of Atlas region names to Google Cloud region names. In most cases
# you should use the same region for both services.

variable "google_cloud_region" {
  type        = string
  description = "the Google Cloud region in which to create resources"
  default     = "us-central1"
}

variable "atlas_cluster_region" {
  type        = string
  description = "the Atlas region in which to create the database cluster"
  default     = "CENTRAL_US"
}





###-----------------------------------------------------------------------------
### MongoDB Atlas
###-----------------------------------------------------------------------------

variable "atlas_cluster_tier" {
  type        = string
  description = "the tier of cluster you want to create. see the Atlas docs for details."
  default     = "M10" # M0 is the free tier
}

variable "atlas_org_id" {
  type        = string
  description = "the ID of your MongoDB Atlas organization"
  default = "642adea619316a2bfd69f142"
}

variable "atlas_pub_key" {
  type        = string
  description = "public key for MongoDB Atlas"
  default = "ghmdvpkc"
}

variable "atlas_priv_key" {
  type        = string
  description = "private key for MongoDB Atlas"
  default = "54f705ae-5b9c-45ce-80bf-f5d323348cc1"
}

###-----------------------------------------------------------------------------
### MongoDB database
###-----------------------------------------------------------------------------

variable "db_name" {
  type        = string
  description = "the name of the database to configure"
  default     = "meanStackExample"
}

variable "db_user" {
  type        = string
  description = "the username used to connect to the mongodb cluster"
  default     = "mongo"
}




