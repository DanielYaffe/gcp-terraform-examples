variable "organization_id" {
  type        = string
  description = "The numeric ID of the GCP Organization."
}

variable "billing_project_id" {
  type        = string
  description = "The project ID used for billing/API calls to manage Org-level resources."
}
variable "producer_project_id" {
  type        = string
  description = "The project ID used for the producer"
}
variable "consumer_project_id" {
  type        = string
  description = "The project ID used for the producer"
}
variable "region" {
  type        = string
  description = "The project Region."
  default     = "europe-west1"
}
