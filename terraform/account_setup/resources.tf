// Define the resources to create
// Provisions the following resources: 
//    GKE Cluster, GKE Node Pool

locals {
  gke_cluster_name       = lower(join("-", ["se", var.org_id]))
  resource_purpose       = lower(join("-", ["official-se", var.org_id]))
}

import {
  id = "projects/${var.gcp_project_id}/locations/${var.gcp_zone}/clusters/${local.gke_cluster_name}"
  to = google_container_cluster.gke_cluster
}

import {
  id = "${var.gcp_project_id}/${var.gcp_zone}/${local.gke_cluster_name}/${local.gke_cluster_name}-pool-01"
  to = google_container_node_pool.gke_node_pool
}

