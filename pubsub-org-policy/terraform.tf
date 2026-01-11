terraform {
  required_version = ">= 1.10.0"

  backend "gcs" {
    bucket       = "terraform-state-bob"
    prefix       = "global/pubsub-policy"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.billing_project_id
  region  = "europe-west1"
  user_project_override = true
  billing_project = var.billing_project_id
}