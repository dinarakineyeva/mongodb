
terraform {
  # The configuration for this backend will be filled in by Terragrunt
  required_version = ">= 0.13"
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
  }
}
