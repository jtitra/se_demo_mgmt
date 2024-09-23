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

// Connectors
resource "harness_platform_connector_datadog" "datadog" {
  identifier = "Datadog"
  name       = "Datadog"

  url                 = "https://app.datadoghq.com/api/"
  delegate_selectors  = [local.delegate_selector]
  application_key_ref = "account.DataDogAppKeyDiego"
  api_key_ref         = "account.DataDogApiKeyDiego"
}

resource "harness_platform_connector_datadog" "datadog_backup" {
  identifier  = "Datadog_Backup"
  name        = "Datadog - Backup"
  description = "Owned by Diego - Datadog"

  url                 = "https://app.datadoghq.com/api/"
  delegate_selectors  = [local.delegate_selector]
  application_key_ref = "account.DataDogAppKey"
  api_key_ref         = "account.DataDogAPIKey"
}

resource "harness_platform_connector_docker" "docker_v1" {
  identifier  = "harnessImageV1"
  name        = "Harness Docker Connector"
  description = "Harness internal connector"

  type               = "DockerHub"
  url                = "https://index.docker.io/v1/"
  delegate_selectors = [local.delegate_selector]
  credentials {
    username     = "seworkshop"
    password_ref = "account.docker-pw"
  }
}

resource "harness_platform_connector_git" "hcr_account_level" {
  identifier  = "HCRAccountLevel"
  name        = "HCR-AccountLevel"
  description = "Git connector for all account level repos in Harness Code Repo"

  url                = "https://git.harness.io/${var.account_id}"
  connection_type    = "Account"
  validation_repo    = "account.se_demo_mgmt"
  delegate_selectors = [local.delegate_selector]
  credentials {
    http {
      username     = "joseph.titra@harness.io"
      password_ref = "account.HCR-AccountLevel_API_Key"
    }
  }
}

resource "harness_platform_connector_github" "github" {
  identifier  = "Github"
  name        = "Github"
  description = "Account-wide credentials aligned to DanFlores.\nPlease use OAuth: https://developer.harness.io/docs/platform/git-experience/oauth-integration"
  tags        = ["foo:bar"]

  url                = "https://github.com"
  connection_type    = "Account"
  validation_repo    = "wings-software/e2e-enterprise-demo"
  delegate_selectors = [local.delegate_selector]
  credentials {
    http {
      username  = "danf425"
      token_ref = "account.Github-danf425"
    }
  }
  api_authentication {
    token_ref = "account.Github-danf425"
  }
}

resource "harness_platform_connector_appdynamics" "appd_prod" {
  identifier  = "AppDynamics_Prod"
  name        = "AppDynamics - Prod"
  description = "Prod Demo Data"

  url                = "https://harness-test.saas.appdynamics.com/controller/"
  account_name       = "harness-test"
  delegate_selectors = [local.delegate_selector]
  username_password {
    username     = "raghu@harness.io"
    password_ref = "account.AppDProdKey"
  }
}

resource "harness_platform_connector_artifactory" "artifactory_self_hosted" {
  identifier = "Artifactory_Self_Hosted"
  name       = "Artifactory - Self Hosted"

  url                = "https://harness-artifactory.harness.io/artifactory/"
  delegate_selectors = [local.delegate_selector]
  credentials {
    username     = "shawn_pearson"
    password_ref = "account.Artifactory-ShawnsPW"
  }
}

resource "harness_platform_connector_service_now" "snow_dev" {
  identifier = "ServiceNow_Dev"
  name       = "ServiceNow - Dev"

  service_now_url    = "https://ven03172.service-now.com/"
  delegate_selectors = [local.delegate_selector]
  auth {
    auth_type = "UsernamePassword"
    username_password {
      username     = "demo-admin"
      password_ref = "account.ServiceNow_API_Key"
    }
  }
}

resource "harness_platform_connector_aws" "aws_sales" {
  identifier = "AWS"
  name       = "AWS - Sales Account"

  manual {
    access_key_ref     = "account.AWS_Access_Key"
    secret_key_ref     = "account.AWS_Secret_Access_Key"
    delegate_selectors = [local.delegate_selector]
    region             = "us-east-2"
  }
}

// Error: Invalid request: Secret [AWS_Access_Key] is stored in secret manager [GCP_Secret_Manager]. Secret manager credentials should be stored in [Harness Built-in Secret Manager]
//resource "harness_platform_connector_aws_secret_manager" "aws_sm" {
//  identifier = "AWS_Secrets_Manager"
//  name       = "AWS Secrets Manager"
//  default    = false
//
//  secret_name_prefix = "harness/software-delivery-demo"
//  region             = "us-east-1"
//  delegate_selectors = [local.delegate_selector]
//  credentials {
//    manual {
//      secret_key_ref = "account.AWS_Access_Key"
//      access_key_ref = "account.AWS_Secret_Access_Key"
//    }
//  }
//}

resource "harness_platform_connector_jira" "jira_se" {
  identifier = "Harness_JIRA"
  name       = "Harness JIRA"

  url                = "https://harness.atlassian.net"
  delegate_selectors = [local.delegate_selector]
  auth {
    auth_type = "UsernamePassword"
    username_password {
      username     = "se-accounts@harness.io"
      password_ref = "account.Harness_JIRA_Key"
    }
  }
}

resource "harness_platform_connector_newrelic" "new_relic" {
  identifier = "New_Relic"
  name       = "New Relic"

  url                = "https://insights-api.newrelic.com/"
  delegate_selectors = [local.delegate_selector]
  account_id         = "1805869"
  api_key_ref        = "account.NewRelic"
}

// Cloud Cost Connectors
resource "harness_platform_connector_gcp_cloud_cost" "ccm_gcp_dev" {
  identifier = "CCM_Harness_GCP_Dev"
  name       = "CCM - Harness GCP Dev"

  features_enabled      = ["BILLING"]
  gcp_project_id        = "durable-circle-282815"
  service_account_email = "harness-ce-mjqzm-30979@prod-prod0-3966.iam.gserviceaccount.com"
  billing_export_spec {
    data_set_id = "bill_test_doc"
    table_id    = "gcp_billing_export_v1_014665_7E972A_C61BCD"
  }
}

resource "harness_platform_connector_gcp_cloud_cost" "ccm_gcp" {
  identifier = "CCM_Harness_GCP"
  name       = "CCM - Harness GCP"

  features_enabled      = ["BILLING", "VISIBILITY"]
  gcp_project_id        = "prod-setup-205416"
  service_account_email = "harness-ce-mjqzm-30979@prod-prod0-3966.iam.gserviceaccount.com"
  billing_export_spec {
    data_set_id = "billing_prod_all_projects"
    table_id    = ""
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

// Resource Groups
resource "harness_platform_resource_group" "demo_org_rg" {
  identifier = var.organizations.demo.rg_id
  name       = var.organizations.demo.rg_name

  account_id           = var.account_id
  allowed_scope_levels = ["account"]
  included_scopes {
    filter     = "EXCLUDING_CHILD_SCOPES"
    account_id = var.account_id
    org_id     = var.organizations.demo.org_id
  }
  resource_filter {
    include_all_resources = true
  }
}

resource "harness_platform_resource_group" "sandbox_org_rg" {
  identifier = var.organizations.sandbox.rg_id
  name       = var.organizations.sandbox.rg_name

  account_id           = var.account_id
  allowed_scope_levels = ["account"]
  included_scopes {
    filter     = "INCLUDING_CHILD_SCOPES"
    account_id = var.account_id
    org_id     = var.organizations.sandbox.org_id
  }
  resource_filter {
    include_all_resources = false

    dynamic "resources" {
      for_each = var.sandbox_org_resource_types
      content {
        resource_type = resources.value
      }
    }
  }
}

// Roles
resource "harness_platform_roles" "roles" {
  for_each = var.roles

  identifier           = each.value.role_id
  name                 = each.value.role_name
  description          = each.value.role_desc
  permissions          = each.value.role_perms
  allowed_scope_levels = ["account"]
}

// User Groups
resource "harness_platform_usergroup" "user_groups" {
  for_each = var.groups

  identifier  = each.value.group_id
  name        = each.value.group_name
  description = each.value.group_desc
}

// Role Binding
resource "harness_platform_role_assignments" "role_bindings" {
  for_each = var.role_bindings

  resource_group_identifier = each.value.rg_id
  role_identifier           = each.value.role_id
  principal {
    identifier = each.value.prin_id
    type       = "USER_GROUP"
  }
  disabled = false
  managed  = false

  depends_on = [harness_platform_usergroup.user_groups, harness_platform_roles.roles]
}

// Pipeline
resource "harness_platform_pipeline" "provision_org" {
  identifier  = "Provision_New_Org"
  name        = "Provision New Org"
  org_id      = var.organizations.management.org_id
  project_id  = var.organizations.management.projects.proj0.proj_id
  description = "Execute this to provision a new Org for the SE Demo."
  yaml        = <<-EOT
    pipeline:
      identifier: Provision_New_Org
      name: Provision New Org
      orgIdentifier: ${var.organizations.management.org_id}
      projectIdentifier: ${var.organizations.management.projects.proj0.proj_id}
      tags: {}
      stages:
        - stage:
            name: IaCM
            identifier: IaCM
            description: ""
            type: IACM
            spec:
              workspace: <+input>
              execution:
                steps:
                  - step:
                      type: IACMTerraformPlugin
                      name: init
                      identifier: init
                      timeout: 10m
                      spec:
                        command: init
                  - step:
                      type: IACMTerraformPlugin
                      name: plan
                      identifier: plan
                      timeout: 10m
                      spec:
                        command: plan
                  - step:
                      type: Wiz
                      name: Wiz Scan
                      identifier: Wiz_Scan
                      spec:
                        mode: orchestration
                        config: wiz-iac-templates
                        target:
                          type: repository
                          detection: auto
                        advanced:
                          log:
                            level: info
                          args:
                            cli: "-p annam-custom-misconfig-policy"
                        auth:
                          access_token: <+secrets.getValue("account.wiz_access_token")>
                          access_id: <+secrets.getValue("account.wiz_access_id")>
                      when:
                        stageStatus: Success
                        condition: "false"
                  - step:
                      type: IACMApproval
                      name: IACMApproval
                      identifier: IACMApproval
                      spec:
                        autoApprove: false
                      timeout: 1h
                      when:
                        stageStatus: Success
                        condition: <+pipeline.variables.require_approval>
                  - step:
                      type: IACMTerraformPlugin
                      name: apply
                      identifier: apply
                      timeout: 1h
                      spec:
                        command: apply
              platform:
                os: Linux
                arch: Amd64
              runtime:
                type: Cloud
                spec: {}
            tags: {}
        - stage:
            name: Deploy Delegate
            identifier: Deploy_Delegate
            description: ""
            type: CI
            spec:
              cloneCodebase: false
              platform:
                os: Linux
                arch: Amd64
              runtime:
                type: Cloud
                spec: {}
              execution:
                steps:
                  - step:
                      type: Run
                      name: Read Secret
                      identifier: Read_Secret
                      spec:
                        shell: Sh
                        command: |-
                          #!/bin/bash

                          printf "%s" "$KEY" > key.json
                          echo "  DEBUG: Key output to: key.json"

                          echo "Formatting Key"
                          jq . key.json > formatted_key.json
                          echo "  DEBUG: Key output to: formatted_key.json"
                        envVariables:
                          KEY: <+secrets.getValue("account.GCP_Sales_Admin")>
                  - stepGroup:
                      name: Org Level Delegate
                      identifier: Org_Level_Delegate
                      steps:
                        - step:
                            type: Run
                            name: Get Delegate YAML
                            identifier: Get_Delegate_YAML
                            spec:
                              shell: Sh
                              command: |-
                                #!/bin/bash

                                ORG_ID_LOWER=$(echo "$ORG_ID" | tr '[:upper:]' '[:lower:]')
                                YAML_FILE="se-$${ORG_ID_LOWER}-org-delegate.yaml"
                                JSON_BODY="{\"name\": \"se-$${ORG_ID_LOWER}-org-delegate\", \"clusterPermissionType\": \"CLUSTER_ADMIN\", \"customClusterNamespace\": \"se-$${ORG_ID_LOWER}-org-delegate\"}"

                                echo "    DEBUG: JSON_BODY: $${JSON_BODY}"

                                echo "Getting Delegate YAML"
                                response=$(curl -s -X POST "https://demo.harness.io/ng/api/download-delegates/kubernetes?accountId=MjQzMTU3ZGEtN2NhOS00Ym&orgIdentifier=$${ORG_ID}" \
                                    -H 'x-api-key: <+secrets.getValue("temp_code_pat")>' \
                                    -H "content-type: application/json" \
                                    --data-raw "$${JSON_BODY}" \
                                    --output $YAML_FILE \
                                    --write-out "%%{http_code}")

                                if [ "$response" -eq 200 ]; then
                                    echo "Request successful."
                                    echo "    DEBUG: YAML File Contents"
                                    cat $YAML_FILE
                                else
                                    echo "Request failed. HTTP $${response}"
                                    exit 1
                                fi
                              envVariables:
                                ORG_ID: <+pipeline.stages.IaCM.spec.workspace>
                        - step:
                            type: Run
                            name: Update YAML
                            identifier: Update_YAML
                            spec:
                              shell: Sh
                              command: |-
                                #!/bin/bash

                                ORG_ID_LOWER=$(echo "$ORG_ID" | tr '[:upper:]' '[:lower:]')
                                YAML_FILE="se-$${ORG_ID_LOWER}-org-delegate.yaml"

                                echo "Updating Namespace"
                                if [ "$ORG_ID_LOWER" = "demo" ]; then
                                    sed -i 's/harness-delegate-ng/se-demo-org-delegate/g' $YAML_FILE
                                elif [ "$ORG_ID_LOWER" = "sandbox" ]; then
                                    sed -i 's/harness-delegate-ng/se-sandbox-org-delegate/g' $YAML_FILE
                                else
                                    echo "Error: Unknown environment"
                                    exit 1
                                fi

                                echo "    DEBUG: YAML File Contents"
                                cat $YAML_FILE
                              envVariables:
                                ORG_ID: <+pipeline.stages.IaCM.spec.workspace>
                        - step:
                            type: Run
                            name: Create Delegate
                            identifier: Create_Delegate
                            spec:
                              connectorRef: GCP_Sales
                              image: us-east1-docker.pkg.dev/sales-209522/instruqt/packer-build:0.0.3
                              shell: Sh
                              command: |-
                                #!/bin/bash

                                ORG_ID_LOWER=$(echo "$ORG_ID" | tr '[:upper:]' '[:lower:]')
                                YAML_FILE="se-$${ORG_ID_LOWER}-org-delegate.yaml"
                                echo "    DEBUG: ORG_ID: $${ORG_ID}"
                                echo "    DEBUG: ORG_ID_LOWER: $${ORG_ID_LOWER}"

                                gcloud components install kubectl
                                gcloud components install gke-gcloud-auth-plugin

                                echo "Connecting to Cluster"
                                gcloud auth activate-service-account --key-file="formatted_key.json"
                                if [ "$ORG_ID_LOWER" == "demo" ]; then
                                    echo "Running kubeconfig command for demo env"
                                    <+workspace.Demo.gcloud_kubeconfig_command>
                                elif [ "$ORG_ID_LOWER" == "sandbox" ]; then
                                    echo "Running kubeconfig command for sandbox env"
                                    <+workspace.Sandbox.gcloud_kubeconfig_command>
                                else
                                    echo "Error: Unknown environment"
                                    exit 1
                                fi

                                echo "Applying Delegate YAML"
                                kubectl apply -f $YAML_FILE
                              envVariables:
                                ORG_ID: <+pipeline.stages.IaCM.spec.workspace>
            when:
              pipelineStatus: Success
              condition: <+pipeline.variables.deploy_delegate>
      variables:
        - name: require_approval
          type: String
          description: if true approval is required
          required: true
          value: <+input>.allowedValues(false,true)
        - name: deploy_delegate
          type: String
          description: if true a delegate is deployed
          required: true
          value: <+input>.allowedValues(false,true)
  EOT
}


