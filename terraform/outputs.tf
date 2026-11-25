output "sql_connection_name" {
  description = "Cloud SQL Instance Connection Name for the Cloud SQL Auth Proxy sidecar"
  value       = google_sql_database_instance.griffin_dev_db.connection_name
}

output "cloud_sql_proxy_sa_email" {
  description = "Service account email used by the Cloud SQL Auth Proxy sidecar"
  value       = google_service_account.cloud_sql_proxy.email
}

output "bastion_external_ip" {
  description = "External IP address of the dual-NIC Bastion Host (nic0)"
  value       = google_compute_instance.griffin_dev_bastion.network_interface[0].access_config[0].nat_ip
}

output "bastion_ssh_command" {
  description = "gcloud command to SSH into the Bastion Host"
  value       = "gcloud compute ssh ${google_compute_instance.griffin_dev_bastion.name} --zone=${var.zone}"
}

output "gke_get_credentials_command" {
  description = "gcloud command to configure kubectl for the griffin-dev GKE cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.griffin_dev.name} --zone=${var.zone}"
}
