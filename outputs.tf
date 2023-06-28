output "user1" {
  value = mongodbatlas_database_user.user.username
}

output "database_ro_username" {
  value = mongodbatlas_database_user.database-ro-user.username
}

output "database_rw_username" {
  value = mongodbatlas_database_user.database-rw-user.username
}

output "database_admin_username" {
  value = mongodbatlas_database_user.database-admin-user.username
}

output "cluster_connection_strings" {
  value = mongodbatlas_cluster.cluster[*].connection_strings
}

output "mongo_project_id" {
  value = mongodbatlas_project.project.id
}
