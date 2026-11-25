terraform {
  required_version = ">= 1.5.7"

  # Optional: Uncomment for remote team state after creating a GCS state bucket
  # backend "gcs" {
  #   bucket = "YOUR_UNIQUE_TF_STATE_BUCKET"
  #   prefix = "terraform/griffin-network"
  # }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required Google Cloud APIs automatically
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
