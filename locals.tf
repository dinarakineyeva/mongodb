locals {
  region_str    = split("-", var.gcp_region)
  region_letter = substr(local.region_str[1], 0, 1)
  region_number = substr(local.region_str[1], length(local.region_str[1]) - 1, 1)
  cluster_name  = lower("mongodb${local.region_letter}${local.region_number}${var.environment}")

  mongodb_database_name = "db"
  mongodb_rw_role_actions = [
    "FIND", "INSERT", "REMOVE", "UPDATE", "BYPASS_DOCUMENT_VALIDATION", "CREATE_COLLECTION", "CREATE_INDEX",
    "DROP_COLLECTION", "CHANGE_STREAM", "COLL_MOD", "COMPACT", "CONVERT_TO_CAPPED", "DROP_INDEX", "RE_INDEX",
    "COLL_STATS", "DB_HASH", "LIST_INDEXES", "VALIDATE"
  ]
  mongodb_ro_role_actions = [
    "FIND", "BYPASS_DOCUMENT_VALIDATION", "COLL_MOD", "COLL_STATS", "DB_HASH", "LIST_INDEXES", "VALIDATE"
  ]

  mongodb_admin_role_actions = [
    "ENABLE_PROFILER", "DROP_DATABASE", "RENAME_COLLECTION_SAME_DB", "DB_STATS", "LIST_COLLECTIONS"
  ]
  mongodb_admin_built_in_roles = [
    "read", "readWrite", "dbAdmin"
  ]

  mongodb_ro_username    = "${var.environment}_${local.mongodb_database_name}_ro"
  mongodb_ro_password    = random_password.database-password.result
  mongodb_rw_username    = "${var.environment}_${local.mongodb_database_name}_rw"
  mongodb_rw_password    = random_password.database-password.result
  mongodb_admin_username = "${var.environment}_${local.mongodb_database_name}_admin"
  mongodb_admin_password = random_password.database-password.result


  endpoint_service_id = google_compute_network.default.name
  private_endpoints   = try(flatten([for cs in mongodbatlas_cluster.cluster[0].connection_strings : cs.private_endpoint]), [])
  connection_strings = [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], local.endpoint_service_id)
  ]
}
