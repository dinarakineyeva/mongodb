output "user1" {
  value = mongodbatlas_database_user.user.username
}

output "database-rw-user" {
  value = mongodbatlas_database_user.database-rw-user.username
}

output "database-admin-user" {
  value = mongodbatlas_database_user.database-admin-user.username
}


output "connection_string" {
  value = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
}
