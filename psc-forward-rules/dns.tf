# 1. Create a Private DNS Zone for Google APIs
resource "google_dns_managed_zone" "googleapis_zone" {
  project     = var.consumer_project_id
  name        = "googleapis-private-zone"
  dns_name    = "googleapis.com."
  description = "Private zone for Google APIs"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.consumer_vpc.id
    }
  }
}

# 2. Map the API hostname to the restricted Google API range (199.36.153.4/30)
resource "google_dns_record_set" "googleapis_cname" {
  project      = var.consumer_project_id
  managed_zone = google_dns_managed_zone.googleapis_zone.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["restricted.googleapis.com."]
}

resource "google_dns_record_set" "restricted_api_a" {
  project      = var.consumer_project_id
  managed_zone = google_dns_managed_zone.googleapis_zone.name
  name         = "restricted.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas      = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
}



resource "google_dns_managed_zone" "cloudsql_private_zone" {
  project     = var.consumer_project_id
  name        = "private-cloudsql-zone"
  dns_name    = "${var.region}.sql.goog."
  description = "Private zone for Cloudsql"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.consumer_vpc.id
    }
  }
}

resource "google_dns_record_set" "cloudsql_private" {
  project      = var.consumer_project_id
  managed_zone = google_dns_managed_zone.cloudsql_private_zone.name
  name         = google_sql_database_instance.instance.dns_name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_forwarding_rule.psc_endpoint.ip_address]
}