// Define the resources to create
// Provisions the following resources: 
//    GKE Cluster, GKE Node Pool
//    Organizations, Projects

locals {
  gke_cluster_name  = lower(join("-", ["se", var.org_id]))
  resource_purpose  = lower(join("-", ["official-se", var.org_id]))
  delegate_selector = lower(join("-", ["se", var.org_id, "account-delegate"]))
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

// GKE Node Pool
//resource "google_container_node_pool" "gke_node_pool" {
//  name       = "${google_container_cluster.gke_cluster.name}-pool-01"
//  cluster    = google_container_cluster.gke_cluster.id
//  node_count = var.gke_min_node_count
//
//  autoscaling {
//    min_node_count = var.gke_min_node_count
//    max_node_count = var.gke_max_node_count
//  }
//
//  management {
//    auto_upgrade = true
//  }
//
//  node_config {
//    machine_type = var.gke_machine_type
//    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
//
//    metadata = {
//      disable-legacy-endpoints = "true"
//    }
//
//    workload_metadata_config {
//      mode = "GKE_METADATA"
//    }
//  }
//
//  timeouts {
//    create = "60m"
//    update = "60m"
//  }
//}

// GCP Secret Manager
resource "harness_platform_connector_gcp_secret_manager" "gcp_sm" {
  identifier  = "GCP_Secret_Manager"
  name        = "GCP Secret Manager"
  description = "Secret Manager in Project: sales-209522\nUsed for all Account level connectors"

  delegate_selectors = [local.delegate_selector]
  credentials_ref    = "account.GCP_Sales_Admin"
}

// GCP Secrets
resource "harness_platform_secret_text" "gcp_secrets" {
  for_each = var.secrets

  identifier = each.value.secret_id
  name       = each.value.secret_name

  secret_manager_identifier = harness_platform_connector_gcp_secret_manager.gcp_sm.identifier
  value_type                = "Reference"
  value                     = each.value.secret_ref_name

  additional_metadata {
    values {
      version = each.value.secret_ver
    }
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

