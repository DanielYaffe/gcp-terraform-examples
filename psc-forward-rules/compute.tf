# 1. Create the Cloud Run Service Account
resource "google_service_account" "run_sa" {
  project      = var.consumer_project_id
  account_id   = "cloud-run-db-user"
  display_name = "Cloud Run Service Account for DB Access"
}

# 2. Grant IAM Roles (Cloud Run needs these to talk to the SQL API)
resource "google_project_iam_member" "sql_instance_user" {
  project = var.producer_project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "sql_client" {
  project = var.producer_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

# 3. Create the Database Instance (PSC + IAM Auth enabled)
resource "google_sql_database_instance" "instance" {
  project          = var.producer_project_id
  name             = "psc-sql-db"
  region           = var.region
  database_version = "POSTGRES_15"
  deletion_protection = false
  
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = false
      psc_config {
        psc_enabled               = true
        allowed_consumer_projects = [var.consumer_project_id]
      }
    }
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }
}

# 4. Create the IAM User in the Database
resource "google_sql_user" "iam_user" {
  project  = var.producer_project_id
  # Username must exclude '.gserviceaccount.com' for Postgres/MySQL
  name     = trimsuffix(google_service_account.run_sa.email, ".gserviceaccount.com")
  instance = google_sql_database_instance.instance.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

# 5. PSC Endpoint in Consumer Project
resource "google_compute_address" "psc_ip" {
  project      = var.consumer_project_id
  name         = "psc-sql-ip"
  subnetwork   = google_compute_subnetwork.psc_subnet.id
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  region       = var.region
}

resource "google_compute_forwarding_rule" "psc_endpoint" {
  project               = var.consumer_project_id
  name                  = "sql-psc-endpoint"
  region                = var.region
  network               = google_compute_network.consumer_vpc.id
  ip_address            = google_compute_address.psc_ip.id
  target                = google_sql_database_instance.instance.psc_service_attachment_link
  load_balancing_scheme = ""
}

# 6. Cloud Run Service using the new Service Account
resource "google_cloud_run_v2_service" "app" {
  project  = var.consumer_project_id
  name     = "user-display-service"
  location = var.region
  depends_on = [null_resource.docker_lifecycle]
  deletion_protection=false
  template {
    service_account = google_service_account.run_sa.email # <--- Identity assigned here
    
    vpc_access {
      network_interfaces {
        network    = google_compute_network.consumer_vpc.id
        subnetwork = google_compute_subnetwork.run_subnet.id
      }
      egress = "ALL_TRAFFIC"
    }
    


    containers {
      image = "${var.region}-docker.pkg.dev/${var.consumer_project_id}/${google_artifact_registry_repository.repo.repository_id}/db-checker:latest"
     env {
        name  = "INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.instance.connection_name # e.g. project:region:instance
      }
      env {
        name  = "DB_USER"
        value = trimsuffix(google_service_account.run_sa.email, ".gserviceaccount.com")
      }
      env {
        name  = "DB_NAME"
        value = "postgres"
      }
    }
  }
}
# This resource makes the Cloud Run service public
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.consumer_project_id
  location = var.region
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}