# ==============================================================================
# Task 1: Development VPC (griffin-dev-vpc) & Subnets
# ==============================================================================
resource "google_compute_network" "griffin_dev_vpc" {
  name                    = "griffin-dev-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.enabled_apis]
}

resource "google_compute_subnetwork" "griffin_dev_wp" {
  name          = "griffin-dev-wp"
  ip_cidr_range = "192.168.16.0/20"
  region        = var.region
  network       = google_compute_network.griffin_dev_vpc.id
}

resource "google_compute_subnetwork" "griffin_dev_mgmt" {
  name          = "griffin-dev-mgmt"
  ip_cidr_range = "192.168.32.0/20"
  region        = var.region
  network       = google_compute_network.griffin_dev_vpc.id
}

# ==============================================================================
# Task 2: Production VPC (griffin-prod-vpc) & Subnets
# ==============================================================================
resource "google_compute_network" "griffin_prod_vpc" {
  name                    = "griffin-prod-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.enabled_apis]
}

resource "google_compute_subnetwork" "griffin_prod_wp" {
  name          = "griffin-prod-wp"
  ip_cidr_range = "192.168.48.0/20"
  region        = var.region
  network       = google_compute_network.griffin_prod_vpc.id
}

resource "google_compute_subnetwork" "griffin_prod_mgmt" {
  name          = "griffin-prod-mgmt"
  ip_cidr_range = "192.168.64.0/20"
  region        = var.region
  network       = google_compute_network.griffin_prod_vpc.id
}
