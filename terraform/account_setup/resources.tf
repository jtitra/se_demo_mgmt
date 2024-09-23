// Define the resources to create
// Provisions the following resources: 
//    GKE Cluster, GKE Node Pool
//    Organizations, Projects

locals {
  gke_cluster_name = lower(join("-", ["se", var.org_id]))
  resource_purpose = lower(join("-", ["official-se", var.org_id]))
  organization_projects_list = flatten([
    for org_key, org_value in var.organizations : [
      for proj_key, proj_value in org_value.projects : {
        org_key    = org_key
        org_value  = org_value
        proj_key   = proj_key
        proj_value = proj_value
      }
    ]
  ])
  organization_projects = {
    for item in local.organization_projects_list :
    "${item.org_key}_${item.proj_key}" => {
      org_key  = item.org_key
      env      = item.org_value
      proj_key = item.proj_key
      proj     = item.proj_value
    }
  }
}

// GKE Cluster
resource "google_container_cluster" "gke_cluster" {
  name     = local.gke_cluster_name
  location = var.gcp_zone

  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  resource_labels = {
    env     = local.gke_cluster_name
    purpose = local.resource_purpose
    owner   = var.resource_owner
  }

  timeouts {
    create = "60m"
    update = "60m"
  }
}

// Organizations
resource "harness_platform_organization" "orgs" {
  for_each = var.organizations

  identifier  = each.value.org_id
  name        = each.value.org_name
  description = each.value.org_desc
}

// Projects
resource "harness_platform_project" "project" {
  for_each = local.organization_projects

  identifier  = each.value.proj.proj_id
  name        = each.value.proj.proj_name
  description = each.value.proj.proj_desc
  org_id      = each.value.org_key
  color       = each.value.proj.proj_color

  depends_on = [harness_platform_organization.orgs]
}

