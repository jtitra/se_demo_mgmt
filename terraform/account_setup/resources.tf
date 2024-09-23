// Define the resources to create
// Provisions the following resources: 
//    GKE Cluster, GKE Node Pool
//    Organizations, Projects, Resource Groups
//    User Groups, Roles, Role Bindings
//    Pipelines, Workspaces, K8s Connector

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

// User Groups
resource "harness_platform_usergroup" "user_groups" {
  for_each = var.groups

  identifier  = each.value.group_id
  name        = each.value.group_name
  description = each.value.group_desc
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

// Role Bindings
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

// Pipelines
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

resource "harness_platform_pipeline" "audit_events" {
  identifier  = "Audit_Events"
  name        = "Audit Events"
  org_id      = var.organizations.management.org_id
  project_id  = var.organizations.management.projects.proj0.proj_id
  description = "Daily audit of the Platform_Engineering project."
  yaml        = <<-EOT
    pipeline:
      name: Audit Events
      identifier: Audit_Events
      projectIdentifier: ${var.organizations.management.projects.proj0.proj_id}
      orgIdentifier: ${var.organizations.management.org_id}
      tags: {}
      stages:
        - stage:
            name: Platform Engineering
            identifier: Platform_Engineering
            description: ""
            type: CI
            spec:
              cloneCodebase: false
              execution:
                steps:
                  - step:
                      type: Run
                      name: Audit Demo Environment
                      identifier: Audit_Demo_Environment
                      spec:
                        connectorRef: account.GCP_Sales_Admin
                        image: us-east1-docker.pkg.dev/sales-209522/titra/python-tools:0.0.1
                        shell: Python
                        command: |-
                          from datetime import datetime, timedelta
                          import difflib
                          import smtplib
                          from email.mime.text import MIMEText
                          from email.mime.multipart import MIMEMultipart
                          from bs4 import BeautifulSoup
                          import requests

                          #### GLOBAL VARIABLES ####
                          HARNESS_API = "https://app.harness.io"
                          HARNESS_ACCOUNT_ID = "<+account.identifier>"
                          HARNESS_API_KEY = "<+secrets.getValue("harness_api_key")>"
                          HARNESS_ORG_ID = ${var.organizations.demo.org_id}
                          HARNESS_PROJECT_ID = "<+stage.identifier>"
                          SMTP_SERVER = "postfix.smtp.svc.cluster.local"


                          def get_start_timestamp(time_delta):
                              now = datetime.now()
                              start_time = now - timedelta(hours=time_delta)
                              start_timestamp = int(start_time.timestamp() * 1000)  # Convert datetime to timestamp in milliseconds
                              return start_timestamp


                          def parse_and_format_response(data):
                              content = data.get("data", {}).get("content", [])
                              if not content:
                                  return [], []
                              rows = []
                              headers = ["DateTime", "User", "Module", "Action", "ResourceType", "ResourceIdentifier", "ResourceName", "RequestMethod"]
                              for item in content:
                                  timestamp = item.get("timestamp")
                                  date_str = datetime.fromtimestamp(timestamp / 1000).strftime("%Y-%m-%d %H:%M:%S") if timestamp else ""
                                  user = item.get("authenticationInfo", {}).get("principal", {}).get("identifier", "")
                                  module = item.get("module", "")
                                  action = item.get("action", "")
                                  resource_type = item.get("resource", {}).get("type", "")
                                  resource_identifier = item.get("resource", {}).get("identifier", "")
                                  resource_labels = item.get("resource", {}).get("labels", {})
                                  resource_name = resource_labels.get("resourceName", "")
                                  request_method = item.get("httpRequestInfo", {}).get("requestMethod", "")
                                  rows.append([date_str, user, module, action, resource_type, resource_identifier, resource_name, request_method])
                              return headers, rows


                          def get_audit_events(base_url, account_id, api_key, org_id, project_id, time_delta, page_size=100):
                              start_timestamp = get_start_timestamp(time_delta)
                              url = f"{base_url}/audit/api/audits/list?accountIdentifier={account_id}&pageSize={page_size}"
                              headers = {
                                  "Content-Type": "application/json",
                                  "x-api-key": api_key
                              }
                              payload = {
                                  "scopes": [
                                      {
                                          "accountIdentifier": f"{account_id}",
                                          "orgIdentifier": f"{org_id}",
                                          "projectIdentifier": f"{project_id}"
                                      }
                                  ],
                                  "filterType": "Audit",
                                  "staticFilter": "EXCLUDE_LOGIN_EVENTS",
                                  "startTime": start_timestamp
                              }
                              response = requests.post(url, headers=headers, json=payload)
                              if response.status_code == 200:
                                  return response.json()
                              else:
                                  print(f"Failed to retrieve audit events. Status code: {response.status_code}")
                                  return None


                          def get_audit_yaml(base_url, account_id, api_key, audit_id):
                              url = f"{base_url}/gateway/audit/api/auditYaml?accountIdentifier={account_id}&auditId={audit_id}"
                              headers = {
                                  "Content-Type": "application/json",
                                  "x-api-key": api_key
                              }
                              response = requests.get(url, headers=headers)
                              if response.status_code == 200:
                                  return response.json()
                              elif response.status_code == 400:
                                  error_message = f"Invalid request: Yaml Diff corresponding to audit with id {audit_id} does not exist"
                                  if response.json().get("message") == error_message:
                                      return response.json()
                              else:
                                  print(f"    ERROR: Failed to retrieve audit YAML for auditId {audit_id}. Status code: {response.status_code}")
                                  return None


                          def compute_yaml_diff(old_yaml, new_yaml):
                              old_lines = old_yaml.splitlines()
                              new_lines = new_yaml.splitlines()
                              differ = difflib.HtmlDiff(wrapcolumn=80)
                              diff_html = differ.make_file(
                                  old_lines, new_lines,
                                  fromdesc="Old YAML", todesc="New YAML",
                                  context=True, numlines=5
                              )
                              # Extract the tbody(s)
                              soup = BeautifulSoup(diff_html, "html.parser")
                              tbodies = soup.find_all("tbody")
                              tbody_str = "".join([str(tbody) for tbody in tbodies])
                              return tbody_str if tbody_str else None


                          def generate_html_table(headers, rows):
                              table_html = "<table border='1' cellspacing='0' cellpadding='5'>\n"
                              table_html += "  <tr>\n"
                              for header in headers:
                                  table_html += f"    <th>{header}</th>\n"
                              table_html += "  </tr>\n"
                              for row in rows:
                                  table_html += "  <tr>\n"
                                  for cell in row:
                                      table_html += f"    <td>{cell}</td>\n"
                                  table_html += "  </tr>\n"
                              table_html += "</table>\n"
                              return table_html


                          def generate_html_email(audit_table_html, diffs_html_list):
                              html_content = f"""
                              <html>
                              <head>
                                  <style type="text/css">
                                    table.diff {{font-family:Courier; border:medium;}}
                                    .diff_header {{background-color:#e0e0e0}}
                                    td.diff_header {{text-align:right}}
                                    .diff_next {{background-color:#c0c0c0}}
                                    .diff_add {{background-color:#aaffaa}}
                                    .diff_chg {{background-color:#ffff77}}
                                    .diff_sub {{background-color:#ffaaaa}}
                                      table {{
                                          width: 80%;
                                          border-collapse: collapse;
                                          font-size: small;
                                      }}
                                      th, td {{
                                          border: 1px solid #dddddd;
                                          text-align: left;
                                          padding: 8px;
                                      }}
                                      th {{
                                          background-color: #f2f2f2;
                                      }}
                                      .diff {{
                                          margin-top: 20px;
                                      }}
                                  </style>
                              </head>
                              <body>
                                  <h2>Audit Events in the Last 24 Hours</h2>
                                  {audit_table_html}
                                  <h2>YAML Diffs</h2>
                                  {''.join(diffs_html_list)}
                              </body>
                              </html>
                              {add_collapsible_script()}
                              """
                              return html_content


                          def generate_diff_section(resource_name, resource_identifier, diff_html=None):
                              if diff_html:
                                  diff_section = f"""
                                  <div class="diff">
                                      <h3 class="collapsible-header">YAML Diff for Resource: {resource_name} (ID: {resource_identifier})</h3>
                                      <table class="collapsible-content" style="display:table;">
                                          <tr><th class="diff_next"><br/></th><th class="diff_header" colspan="2">Old YAML</th><th class="diff_next"><br/></th><th class="diff_header" colspan="2">New YAML</th></tr></thead>
                                          {diff_html}
                                      </table>
                                  </div>
                                  """
                              else:
                                  diff_section = f"""
                                  <div class="diff">
                                      <h3 class="collapsible-header">YAML Diff for Resource: {resource_name} (ID: {resource_identifier})</h3>
                                      <p>There is no YAML difference associated with this event.</p>
                                  </div>
                                  """
                              return diff_section


                          def retrieve_yaml_diff(yaml_data, resource_name, resource_identifier, diffs_html_list):
                              if yaml_data and yaml_data.get("status") == "SUCCESS":
                                  print("    DEBUG: Audit YAML Successfully retrieved.")
                                  old_yaml = yaml_data["data"].get("oldYaml", "")
                                  new_yaml = yaml_data["data"].get("newYaml", "")
                                  diff_html = compute_yaml_diff(old_yaml, new_yaml)
                                  diff_section = generate_diff_section(resource_name, resource_identifier, diff_html)
                                  diffs_html_list.append(diff_section)
                              elif yaml_data and yaml_data.get("status") == "ERROR":
                                  print("    DEBUG: Failed to retrieve Audit YAML.")
                                  diff_section = generate_diff_section(resource_name, resource_identifier)
                                  diffs_html_list.append(diff_section)
                              return diffs_html_list


                          def add_collapsible_script():
                              collapsible_script = """
                              <style>
                                .collapsible-content {
                                    display: none;
                                }
                                .collapsible-header {
                                    cursor: pointer;
                                    background-color: #f2f2f2;
                                }
                              </style>
                              <script>
                                document.addEventListener("DOMContentLoaded", function() {
                                    const headers = document.querySelectorAll(".collapsible-header");
                                    headers.forEach(header => {
                                        header.addEventListener("click", function() {
                                            const content = this.nextElementSibling;
                                            if (content.style.display === "none" || content.style.display === "") {
                                                content.style.display = "table";
                                            } else {
                                                content.style.display = "none";
                                            }
                                        });
                                    });
                                });
                              </script>
                              """
                              return collapsible_script


                          def send_email(smtp_server, to_email, subject, body):
                              smtp_port = 25
                              from_email = "notifications@harness-demo.site"

                              # Create the email content
                              message = MIMEMultipart()
                              message["From"] = from_email
                              message["To"] = to_email
                              message["Subject"] = subject
                              message.attach(MIMEText(body, "html"))

                              try:
                                  server = smtplib.SMTP(smtp_server, smtp_port)
                                  server.sendmail(from_email, to_email, message.as_string())
                                  print("Email sent successfully.")
                              except Exception as e:
                                  print(f"Error sending email: {e}")
                              finally:
                                  server.quit()


                          def main():
                              audit_data = get_audit_events(HARNESS_API, HARNESS_ACCOUNT_ID, HARNESS_API_KEY, HARNESS_ORG_ID, HARNESS_PROJECT_ID, 24)
                              if not audit_data:
                                  return

                              # Parse data and generate HTML table
                              headers, rows = parse_and_format_response(audit_data)
                              audit_table_html = generate_html_table(headers, rows)
                              content = audit_data.get("data", {}).get("content", [])
                              diffs_html_list = []

                              for item in content:
                                  action = item.get("action", "")
                                  if action == "UPDATE":
                                      audit_id = item.get("auditId")
                                      resource_identifier = item.get("resource", {}).get("identifier", "")
                                      resource_name = item.get("resource", {}).get("labels", {}).get("resourceName", "")
                                      print(f"  DEBUG: Attempting to get details for audit_id: {audit_id}")
                                      yaml_data = get_audit_yaml(HARNESS_API, HARNESS_ACCOUNT_ID, HARNESS_API_KEY, audit_id)
                                      diffs_html_list = retrieve_yaml_diff(yaml_data, resource_name, resource_identifier, diffs_html_list)

                              # Generate HTML email content
                              html_str = generate_html_email(audit_table_html, diffs_html_list)
                              temp_html = BeautifulSoup(html_str, 'html.parser')
                              email_html_content = temp_html.prettify()
                              send_email(SMTP_SERVER, "joseph.titra@harness.io", "Daily - Demo Env Changes - Platform_Engineering ", email_html_content)


                          if __name__ == "__main__":
                              main()
              infrastructure:
                type: KubernetesDirect
                spec:
                  connectorRef: ${var.audit_config.k8s_conn_id}
                  namespace: project0
                  automountServiceAccountToken: true
                  nodeSelector: {}
                  os: Linux
  EOT

  depends_on = [harness_platform_connector_kubernetes.proj0_connector]
}

// Workspaces
resource "harness_platform_workspace" "workspaces" {
  for_each = var.organizations

  identifier              = each.value.org_id
  name                    = each.value.org_name
  org_id                  = var.organizations.management.org_id
  project_id              = var.organizations.management.projects.proj0.proj_id
  provisioner_type        = var.workspace.prov_type
  provisioner_version     = var.workspace.prov_version
  repository              = var.workspace.repo_name
  repository_branch       = var.workspace.repo_branch
  repository_path         = var.workspace.repo_path
  cost_estimation_enabled = true
  provider_connector      = var.workspace.prov_connector
  repository_connector    = harness_platform_connector_github.github.id

  terraform_variable {
    key        = "api_key"
    value      = var.workspace.repo_api_key
    value_type = "secret"
  }

  terraform_variable_file {
    repository           = var.workspace.repo_name
    repository_branch    = var.workspace.repo_branch
    repository_path      = "${each.value.org_id}/terraform.tfvars"
    repository_connector = harness_platform_connector_github.github.id
  }
}

// K8s Connector
resource "harness_platform_connector_kubernetes" "proj0_connector" {
  identifier  = var.audit_config.k8s_conn_id
  name        = var.audit_config.k8s_conn_name
  org_id      = var.organizations.management.org_id
  description = var.audit_config.k8s_conn_desc

  service_account {
    master_url                = var.audit_config.k8s_conn_url
    service_account_token_ref = var.audit_config.k8s_conn_sa_ref
    ca_cert_ref               = var.audit_config.k8s_conn_ca_ref
  }
  delegate_selectors = [local.delegate_selector]
}
