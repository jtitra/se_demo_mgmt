// Define the resources to create
// Provisions the following resources: 
//    GKE Cluster, GKE Node Pool

locals {
  gke_cluster_name       = lower(join("-", ["se", var.org_id]))
  resource_purpose       = lower(join("-", ["official-se", var.org_id]))
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
resource "google_container_node_pool" "gke_node_pool" {
  name       = "${google_container_cluster.gke_cluster.name}-pool-01"
  cluster    = google_container_cluster.gke_cluster.id
  node_count = var.gke_min_node_count

  autoscaling {
    min_node_count = var.gke_min_node_count
    max_node_count = var.gke_max_node_count
  }

  management {
    auto_upgrade = true
  }

  node_config {
    machine_type = var.gke_machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
  }
}

// Organizations
resource "harness_platform_organization" "orgs" {
  for_each = var.projects

  identifier  = each.value.org_id
  name        = each.value.org_name
  description = each.value.org_desc
}

// Projects
resource "harness_platform_project" "project" {
  for_each = var.projects

  identifier  = each.value.proj_id
  name        = each.value.proj_name
  description = each.value.proj_desc
  org_id      = var.org_id
  color       = each.value.proj_color
}

