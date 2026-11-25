# ==============================================================================
# Task 6 Prereq: Dedicated Cloud SQL Auth Proxy Service Account
# ==============================================================================
resource "google_service_account" "cloud_sql_proxy" {
  account_id   = "cloud-sql-proxy"
  display_name = "Cloud SQL Proxy Service Account"
  depends_on   = [google_project_service.enabled_apis]
}

resource "google_project_iam_member" "cloud_sql_proxy_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_proxy.email}"
}

# ==============================================================================
# Task 9: Least-Privilege Monitoring Access for Additional Engineer
# ==============================================================================
resource "google_project_iam_member" "additional_engineer_monitoring" {
  count   = var.additional_engineer_email != "" ? 1 : 0
  project = var.project_id
  role    = var.additional_engineer_role
  member  = "user:${var.additional_engineer_email}"
}
