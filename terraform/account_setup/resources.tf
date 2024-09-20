// Define the resources to create
// Provisions the following resources: 
//    GKE Cluster, GKE Node Pool

locals {
  gke_cluster_name       = lower(join("-", ["se", var.org_id]))
  resource_purpose       = lower(join("-", ["official-se", var.org_id]))
}

import {
  id = "projects/${var.proj_id}/locations/{{location}}/clusters/{{cluster_id}}"
  to = google_container_cluster.gke_cluster
}

import {
  id = "{{project_id}}/{{location}}/{{cluster_id}}/{{pool_id}}"
  to = google_container_node_pool.gke_node_pool
}

