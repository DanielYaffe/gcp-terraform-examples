# Create the Tag Key
resource "google_tags_tag_key" "security_level" {
  parent      = "organizations/${var.organization_id}"
  short_name  = "security-level"
  description = "Defines the sensitivity of the resource."
}

# Create the 'sensitive' Tag Value
resource "google_tags_tag_value" "sensitive" {
  parent     = "tagKeys/${google_tags_tag_key.security_level.name}"
  short_name = "sensitive"
}

# Create the 'non-sensitive' Tag Value
resource "google_tags_tag_value" "non_sensitive" {
  parent     = "tagKeys/${google_tags_tag_key.security_level.name}"
  short_name = "non-sensitive"
}