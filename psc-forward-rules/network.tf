# --- PRODUCER PROJECT ---
resource "google_compute_network" "producer_vpc" {
  project                 = var.producer_project_id
  name                    = "producer-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "producer_subnet" {
  project       = var.producer_project_id
  name          = "producer-db-subnet"
  ip_cidr_range = "10.0.5.0/24"
  region        = var.region
  network       = google_compute_network.producer_vpc.id
}

# --- CONSUMER PROJECT ---
resource "google_compute_network" "consumer_vpc" {
  project                 = var.consumer_project_id
  name                    = "consumer-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "run_subnet" {
  project       = var.consumer_project_id
  name          = "cloud-run-residency-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
  network       = google_compute_network.consumer_vpc.id
}

resource "google_compute_subnetwork" "psc_subnet" {
  project       = var.consumer_project_id
  name          = "dedicated-psc-subnet"
  ip_cidr_range = "10.2.0.0/20"
  region        = var.region
  network       = google_compute_network.consumer_vpc.id
}