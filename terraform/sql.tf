# ==============================================================================
# Task 4: Cloud SQL (MySQL 8.0) Instance, WordPress Database & User
# ==============================================================================
resource "google_sql_database_instance" "griffin_dev_db" {
  name                = "griffin-dev-db"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = var.deletion_protection

  settings {
    tier    = var.db_tier
    edition = "ENTERPRISE"

    location_preference {
      zone = var.zone
    }
  }

  depends_on = [google_project_service.enabled_apis]
}

resource "google_sql_database" "wordpress" {
  name     = "wordpress"
  instance = google_sql_database_instance.griffin_dev_db.name
}

resource "google_sql_user" "wp_user" {
  name     = var.wp_db_user
  instance = google_sql_database_instance.griffin_dev_db.name
  host     = "%"
  password = var.wp_db_password
}
