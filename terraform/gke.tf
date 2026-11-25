# ==============================================================================
# Task 5: GKE Cluster (griffin-dev) & Dedicated Primary Node Pool
# ==============================================================================
resource "google_container_cluster" "griffin_dev" {
  name     = "griffin-dev"
  location = var.zone

  network    = google_compute_network.griffin_dev_vpc.id
  subnetwork = google_compute_subnetwork.griffin_dev_wp.id

  # Best practice: remove default node pool and manage node pools separately
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = var.deletion_protection
  depends_on          = [google_project_service.enabled_apis]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "griffin-dev-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.griffin_dev.name
  node_count = var.gke_node_count

  node_config {
    machine_type = var.gke_machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
