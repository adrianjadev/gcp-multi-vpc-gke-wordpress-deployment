# ==============================================================================
# Task 3: Dual-Homed Multi-NIC Bastion Host & Tag-Scoped SSH Firewalls
# ==============================================================================
resource "google_compute_instance" "griffin_dev_bastion" {
  name         = "griffin-dev-bastion"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  # nic0: Development management subnet (with ephemeral external IP for SSH)
  network_interface {
    subnetwork = google_compute_subnetwork.griffin_dev_mgmt.id
    access_config {
      # Ephemeral public IP (remove access_config and use IAP in production)
    }
  }

  # nic1: Production management subnet (private IP only)
  network_interface {
    subnetwork = google_compute_subnetwork.griffin_prod_mgmt.id
  }

  allow_stopping_for_update = true
  depends_on                = [google_project_service.enabled_apis]
}

resource "google_compute_firewall" "allow_dev_bastion_ssh" {
  name    = "allow-dev-bastion-ssh"
  network = google_compute_network.griffin_dev_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.bastion_ssh_source_ranges
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_prod_bastion_ssh" {
  name    = "allow-prod-bastion-ssh"
  network = google_compute_network.griffin_prod_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.bastion_ssh_source_ranges
  target_tags   = ["ssh"]
}
