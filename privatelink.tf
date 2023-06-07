resource "mongodbatlas_privatelink_endpoint" "mongoatlas_primary" {
  project_id    = var.project_id_mongo
  provider_name = "GCP"
  region        = var.gcp_region
  # depends_on = [ mongodbatlas_cluster.cluster ]
}

# ===== Create a Google Network ===== #
resource "google_compute_network" "default" {
  project = var.gcp_project
  name    = var.network_name
}

# ==== Create a Google Sub Network ===== #
resource "google_compute_subnetwork" "default" {
  project       = google_compute_network.default.project
  name          = var.subnet_name 
  ip_cidr_range = "10.0.0.0/16"
  region        = var.gcp_region
  network       = google_compute_network.default.id
}


# ===== Create Google 50 Addresses ===== #
resource "google_compute_address" "compute_address" {
  count        = 50
  project      = google_compute_subnetwork.default.project
  name         = "${var.compute_address_name}-${count.index}"
  subnetwork   = google_compute_subnetwork.default.id
  address_type = var.google_compute_address_type
  address      = "${var.google_compute_address}${count.index}"
  # address = "10.0.42.${count.index}"
  region  = google_compute_subnetwork.default.region

  depends_on = [mongodbatlas_privatelink_endpoint.mongoatlas_primary]
}

# ==== Create 50 Forwarding rules ===== #
resource "google_compute_forwarding_rule" "compute_forwarding_rule" {
  count                 = 50
  project               = google_compute_address.compute_address[count.index].project
  region                = google_compute_address.compute_address[count.index].region
  name                  = google_compute_address.compute_address[count.index].name
  target                = mongodbatlas_privatelink_endpoint.mongoatlas_primary.service_attachment_names[count.index]
  ip_address            = google_compute_address.compute_address[count.index].id
  network               = google_compute_network.default.id
  load_balancing_scheme = ""
}

resource "mongodbatlas_privatelink_endpoint_service" "test" {
  project_id          = mongodbatlas_privatelink_endpoint.mongoatlas_primary.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.mongoatlas_primary.private_link_id
  provider_name       = "GCP"
  endpoint_service_id = google_compute_network.default.name
  gcp_project_id      = var.gcp_project

  dynamic "endpoints" {
    for_each = mongodbatlas_privatelink_endpoint.mongoatlas_primary.service_attachment_names

    content {
      ip_address    = google_compute_address.compute_address[endpoints.key].address
      endpoint_name = google_compute_forwarding_rule.compute_forwarding_rule[endpoints.key].name
    }
  }

  depends_on = [google_compute_forwarding_rule.compute_forwarding_rule]
}
