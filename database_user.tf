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

# ===== custom roles ==== #
resource "mongodbatlas_custom_db_role" "database-rw-role" {
  project_id = var.project_id_mongo
  role_name  = "${local.mongodb_database_name}_rw"

 dynamic "actions" {
   for_each = local.mongodb_rw_role_actions
   content {
     action = actions.value
     resources {
       collection_name = ""
       database_name = local.mongodb_database_name
     }
   }
 }
}

resource "mongodbatlas_custom_db_role" "database-admin-role" {
  project_id = var.project_id_mongo
  role_name = "${local.mongodb_database_name}_admin"

  dynamic "actions" {
    for_each = concat(local.mongodb_rw_role_actions, local.mongodb_admin_role_actions)
    content {
      action = actions.value
      resources {
        collection_name = ""
        database_name = local.mongodb_database_name
      }
    }
  }

  dynamic "inherited_roles" {
    for_each = local.mongodb_admin_built_in_roles
    content {
      database_name = local.mongodb_database_name
      role_name = inherited_roles.value
    }
  }
}


# ==== database read-write user ==== #
resource mongodbatlas_database_user "database-rw-user" {
  project_id = var.project_id_mongo
  auth_database_name = var.auth_database_name
  username = local.mongodb_rw_username
  password = local.mongodb_rw_password

  roles {
    role_name = mongodbatlas_custom_db_role.database-rw-role.role_name
    database_name = var.database_name
  }

  
}

# ===== database admin user ===== #
resource "mongodbatlas_database_user" "database-admin-user" {
  project_id = var.project_id_mongo
  auth_database_name = var.auth_database_name
  username = local.mongodb_admin_username
  password = local.mongodb_admin_password

  roles {
    role_name = mongodbatlas_custom_db_role.database-admin-role.role_name
    database_name = var.database_name
  } 
}

resource "random_password" "database-rw-password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "random_password" "database-admin-password" {
  length = 16
  special = true
  override_special = "_%@"
}
