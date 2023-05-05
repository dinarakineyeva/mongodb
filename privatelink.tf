resource "mongodbatlas_privatelink_endpoint" "mongoatlas_primary" {
  project_id    = var.project_id_mongo
  provider_name = "GCP"
  region        = var.gcp_region
}


# Create Google 10 Addresses
resource "google_compute_address" "compute_address" {
  count        = 50
  project      = var.gcp_project
  name         = "test-mongo-${count.index}"
  subnetwork   = var.subnet_name
  address_type = var.google_compute_address_type
  # address      = "${var.google_compute_address}${count.index + 5}"
  address      = "10.128.0.${count.index + 3}"
  region = var.gcp_region

  depends_on = [mongodbatlas_privatelink_endpoint.mongoatlas_primary]
}

# Create 10 Forwarding rules
resource "google_compute_forwarding_rule" "compute_forwarding_rule" {
  count                 = 50
  project               = var.gcp_project
  region                = var.gcp_region
  name                  = "test-mongo${count.index}"
  target                = mongodbatlas_privatelink_endpoint.mongoatlas_primary.service_attachment_names[count.index]
  ip_address            = google_compute_address.compute_address[count.index].id
  network               = var.network_name
  load_balancing_scheme = ""
}

resource "mongodbatlas_privatelink_endpoint_service" "test" {
  project_id          = mongodbatlas_privatelink_endpoint.mongoatlas_primary.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.mongoatlas_primary.private_link_id
  provider_name       = "GCP"
  endpoint_service_id = var.network_name
  gcp_project_id      = var.gcp_project

  dynamic "endpoints" {
    for_each = mongodbatlas_privatelink_endpoint.mongoatlas_primary.service_attachment_names

    content {
      ip_address    = google_compute_address.compute_address[endpoints.key].address
      endpoint_name = google_compute_address.compute_address[endpoints.key].name
    }
  }

  depends_on = [google_compute_forwarding_rule.compute_forwarding_rule]
}

