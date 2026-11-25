variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region for VPC subnets and Cloud SQL"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud zone for Bastion Host, Cloud SQL, and GKE cluster"
  type        = string
  default     = "us-central1-c"
}

variable "bastion_ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH into the Bastion Host (restrict to 35.235.240.0/20 for IAP in production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-n1-standard-1"
}

variable "wp_db_user" {
  description = "MySQL username for WordPress"
  type        = string
  default     = "wp_user"
}

variable "wp_db_password" {
  description = "MySQL password for the WordPress database user"
  type        = string
  sensitive   = true
}

variable "gke_machine_type" {
  description = "Machine type for GKE worker nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "gke_node_count" {
  description = "Number of worker nodes in the GKE primary node pool"
  type        = number
  default     = 2
}

variable "additional_engineer_email" {
  description = "Email of an additional engineer to grant monitoring access (leave empty to skip)"
  type        = string
  default     = ""
}

variable "additional_engineer_role" {
  description = "Least-privilege IAM role assigned to the additional engineer"
  type        = string
  default     = "roles/monitoring.editor"
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of Cloud SQL and GKE (set to true for production)"
  type        = bool
  default     = false
}
