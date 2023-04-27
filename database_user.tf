# DATABASE USER  [Configure Database Users](https://docs.atlas.mongodb.com/security-add-mongodb-users/)
resource "mongodbatlas_database_user" "user" {
  username           = var.db_username
  password           = var.db_password
  project_id         = var.project_id_mongo
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
