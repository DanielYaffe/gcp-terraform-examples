# 1. Create the Artifact Registry Repository
resource "google_artifact_registry_repository" "repo" {
  project       = var.consumer_project_id
  location      = var.region # Using your region variable here
  repository_id = "cloud-run-images"
  description   = "Docker repository for Cloud Run connection test app"
  format        = "DOCKER"
}

# 2. Automation: Build, Tag, and Push the image
resource "null_resource" "docker_lifecycle" {
  # Re-run only if the code or Dockerfile changes
  triggers = {
    python_hash = md5(file("${path.module}/main.py"))
    docker_hash = md5(file("${path.module}/Dockerfile"))
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet && docker build -t ${var.region}-docker.pkg.dev/${var.consumer_project_id}/${google_artifact_registry_repository.repo.repository_id}/db-checker:latest . && docker push ${var.region}-docker.pkg.dev/${var.consumer_project_id}/${google_artifact_registry_repository.repo.repository_id}/db-checker:latest
    EOT
  }

  depends_on = [google_artifact_registry_repository.repo]
}