# Resource Location Policy
resource "google_org_policy_policy" "location_policy" {
  name   = "organizations/${var.organization_id}/policies/gcp.resourceLocations"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      condition {
        title      = "Restrict Location for Sensitive Resources"
        expression = "resource.matchTag('${var.organization_id}/${google_tags_tag_key.security_level.short_name}', '${google_tags_tag_value.sensitive.short_name}')"
      }
      values {
        allowed_values = ["in:europe-west1-locations"]
      }
    }
  }
}

# Pub/Sub In-Transit Policy
resource "google_org_policy_policy" "enforce_in_transit" {
  name   = "organizations/${var.organization_id}/policies/pubsub.enforceInTransitRegions"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      condition {
        title      = "Enforce In-Transit for Sensitive Resources"
        expression = "resource.matchTag('${var.organization_id}/${google_tags_tag_key.security_level.short_name}', '${google_tags_tag_value.sensitive.short_name}')"
      }
      enforce = "TRUE"
    }
    rules {
      enforce = "FALSE"
    }
  }
}