# The connection strings available for the GCP MognoDB Atlas cluster
output "connection_string" {
  value = mongodbatlas_cluster.cluster.connection_strings
}
