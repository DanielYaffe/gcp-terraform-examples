variable "organization_id" {
  type        = string
  description = "The numeric ID of the GCP Organization."
}

variable "billing_project_id" {
  type        = string
  description = "The project ID used for billing/API calls to manage Org-level resources."
}