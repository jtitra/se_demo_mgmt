// Define the resources to create
// Provisions the following resources: 
//    K8s Connector, Environments, Infrastructures
//    DAST Scan Template, Projects, Services
//    Secrets, Monitored Services, OPA Policies
//    Policy Set, Pipeline, Code Repo, Prometheus Connector
locals {
  k8s_org_connector_desc = join(" ", ["Connector for", var.org_id, "K8s cluster"])
  delegate_selector      = lower(join("-", ["se", var.org_id, "org-delegate"]))
  k8s_org_connector_id   = lower(join("_", ["se", var.org_id, "k8s"]))
  k8s_org_connector_name = join(" ", ["SE", var.org_id, "K8s"])
  primary_demo_project   = "Platform_Engineering"
  environment_infrastructures_list = flatten([
    for env_key, env_value in var.environments : [
      for infra_key, infra_value in env_value.infrastructures : {
        env_key     = env_key
        env_value   = env_value
        infra_key   = infra_key
        infra_value = infra_value
      }
    ]
  ])
  environment_infrastructures = {
    for item in local.environment_infrastructures_list :
    "${item.env_key}_${item.infra_key}" => {
      env_key   = item.env_key
      env       = item.env_value
      infra_key = item.infra_key
      infra     = item.infra_value
    }
  }
  services_map = {
    for s in flatten([
      for env_key, env_value in var.environments : [
        for infra_key, infra_value in env_value.infrastructures : [
          for service_key, service_value in infra_value.services : {
            key           = "${env_key}_${infra_key}_${service_key}"
            env_key       = env_key
            env_value     = env_value
            infra_key     = infra_key
            infra_value   = infra_value
            service_key   = service_key
            service_value = service_value
          }
        ]
      ]
      ]) : s.key => {
      env_key       = s.env_key
      env_value     = s.env_value
      infra_key     = s.infra_key
      infra_value   = s.infra_value
      service_key   = s.service_key
      service_value = s.service_value
    }
  }
}

// K8s Connector
resource "harness_platform_connector_kubernetes" "org_connector" {
  identifier  = local.k8s_org_connector_id
  name        = local.k8s_org_connector_name
  org_id      = var.org_id
  description = local.k8s_org_connector_desc

  inherit_from_delegate {
    delegate_selectors = [local.delegate_selector]
  }
}

// Environments
resource "harness_platform_environment" "environment" {
  for_each = var.environments

  identifier = each.value.env_identifier
  name       = each.value.env_name
  org_id     = var.org_id
  type       = each.value.env_type
}

// Infrastructures
resource "harness_platform_infrastructure" "infrastructure" {
  for_each = local.environment_infrastructures

  identifier      = each.value.infra.infra_identifier
  name            = each.value.infra.infra_name
  org_id          = var.org_id
  env_id          = harness_platform_environment.environment[each.value.env_key].identifier
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<-EOT
    infrastructureDefinition:
      name: ${each.value.infra.infra_name}
      identifier: ${each.value.infra.infra_identifier}
      description: ""
      tags:
        owner: ${var.org_id}
      orgIdentifier: ${var.org_id}
      environmentRef: ${harness_platform_environment.environment[each.value.env_key].identifier}
      deploymentType: Kubernetes
      type: KubernetesDirect
      spec:
        connectorRef: org.${harness_platform_connector_kubernetes.org_connector.identifier}
        namespace: ${each.value.infra.namespace}
        releaseName: release-<+INFRA_KEY>
      allowSimultaneousDeployments: true
  EOT
}

// DAST Scans Templates
resource "harness_platform_template" "dast_v1" {
  identifier    = "DAST_Scans"
  name          = "DAST Scans"
  org_id        = var.org_id
  version       = "1.0"
  is_stable     = true
  template_yaml = <<-EOT
    template:
      name: DAST Scans
      identifier: DAST_Scans
      versionLabel: "1.0"
      type: Stage
      orgIdentifier: ${var.org_id}
      spec:
        type: SecurityTests
        spec:
          cloneCodebase: true
          infrastructure:
            type: KubernetesDirect
            spec:
              connectorRef: org.${harness_platform_connector_kubernetes.org_connector.identifier}
              namespace: build
              automountServiceAccountToken: true
              nodeSelector: {}
              containerSecurityContext:
                privileged: true
                allowPrivilegeEscalation: true
                runAsNonRoot: false
              os: Linux
          execution:
            steps:
              - parallel:
                  - step:
                      type: Security
                      name: Fortify
                      identifier: fortify
                      spec:
                        privileged: true
                        settings:
                          product_name: fortify
                          product_config_name: fortify-default
                          policy_type: manualUpload
                          scan_type: repository
                          repository_project: jhttp_isolated
                          repository_branch: main
                          customer_artifacts_path: sto_tests/scan_tools/fortify/test_data
                          manual_upload_filename: "001"
                        imagePullPolicy: Always
                      failureStrategies:
                        - onFailure:
                            errors:
                              - AllErrors
                            action:
                              type: Ignore
                      when:
                        stageStatus: Success
                  - step:
                      type: Security
                      name: Veracode
                      identifier: veracode
                      spec:
                        privileged: true
                        settings:
                          product_name: veracode
                          product_config_name: default
                          policy_type: ingestionOnly
                          scan_type: repository
                          repository_project: jhttp_isolated
                          repository_branch: <+codebase.branch>
                          customer_artifacts_path: sto_tests/scan_tools/veracode/test_data
                          manual_upload_filename: "002"
                        imagePullPolicy: Always
                      failureStrategies:
                        - onFailure:
                            errors:
                              - AllErrors
                            action:
                              type: Ignore
                      when:
                        stageStatus: Success
                  - step:
                      type: Checkmarx
                      name: Checkmarx
                      identifier: Checkmarx
                      spec:
                        mode: ingestion
                        config: default
                        target:
                          name: jhttp_isolated
                          type: repository
                          variant: dev
                        advanced:
                          log:
                            level: info
                        ingestion:
                          file: sto_tests/scan_tools/checkmarx/test_data/001
          sharedPaths:
            - /var/run
          slsa_provenance:
            enabled: false
        when:
          pipelineStatus: Success
          condition: <+codebase.sourceBranch>=~ ".*-patch.*" || <+pipeline.variables.devonly> == "false"
        failureStrategies:
          - onFailure:
              errors:
                - AllErrors
              action:
                type: MarkAsSuccess
  EOT
}

resource "harness_platform_template" "dast_v2" {
  identifier    = "DAST_Scans"
  name          = "DAST Scans"
  org_id        = var.org_id
  version       = "2.0"
  is_stable     = false
  template_yaml = <<-EOT
    template:
      name: DAST Scans
      identifier: DAST_Scans
      versionLabel: "2.0"
      type: Stage
      orgIdentifier: ${var.org_id}
      spec:
        type: SecurityTests
        spec:
          cloneCodebase: true
          platform:
            os: Linux
            arch: Amd64
          runtime:
            type: Cloud
            spec: {}
          execution:
            steps:
              - parallel:
                  - step:
                      type: Zap
                      name: ZAP
                      identifier: ZAP
                      spec:
                        mode: ingestion
                        config: default
                        target:
                          type: instance
                          detection: manual
                          name: frontend
                          variant: main
                        advanced:
                          log:
                            level: info
                        ingestion:
                          file: automation/sto_test/scan_tools/zap/001
                  - step:
                      type: Security
                      name: Veracode
                      identifier: Veracode
                      spec:
                        privileged: true
                        settings:
                          product_name: veracode
                          product_config_name: default
                          policy_type: ingestionOnly
                          scan_type: repository
                          repository_project: jhttp_isolated
                          repository_branch: <+codebase.branch>
                          customer_artifacts_path: automation/sto_test/scan_tools/veracode
                          manual_upload_filename: "001"
                        imagePullPolicy: Always
                      failureStrategies:
                        - onFailure:
                            errors:
                              - AllErrors
                            action:
                              type: Ignore
                      when:
                        stageStatus: Success
                        condition: "false"
          sharedPaths:
            - /var/run
          slsa_provenance:
            enabled: false
  EOT
}

// Compile Template
resource "harness_platform_template" "compile" {
  identifier    = "Compile_Application"
  name          = "Compile Application"
  org_id        = var.org_id
  version       = "1.0"
  is_stable     = true
  template_yaml = <<-EOT
    template:
      name: Compile Application
      identifier: Compile_Application
      versionLabel: "1.0"
      type: Step
      orgIdentifier: ${var.org_id}
      tags: {}
      spec:
        type: Run
        spec:
          connectorRef: account.harnessImage
          image: node:20-alpine
          shell: Sh
          command: |-
            cd frontend-app/harness-webapp
            npm install
            npm install -g @angular/cli

            mkdir -p ./src/environments
            echo "export const environment = {
              production: true,
              defaultApiUrl: "'"https://devsecops.harness-demo.site/backend"'",
              defaultSDKKey: "'"<+variable.sdk>"'"
            };" > ./src/environments/environment.prod.ts


            echo "export const environment = {
              production: true,
              defaultApiUrl: "'"https://devsecops.harness-demo.site/backend"'",
              defaultSDKKey: "'"<+variable.sdk>"'"
            };" > ./src/environments/environment.ts

            npm run build
  EOT
}

// HCR Pull Request Template
resource "harness_platform_template" "hcr_pr" {
  identifier    = "Harness_Code_Pull_Request_Comment"
  name          = "Harness Code Pull Request Comment"
  version       = "v1"
  is_stable     = true
  template_yaml = <<-EOT
    template:
      name: Harness Code Pull Request Comment
      identifier: Harness_Code_Pull_Request_Comment
      versionLabel: v1
      type: Step
      spec:
        type: Run
        spec:
          shell: Sh
          command: |-
            full_url="<+pipeline.executionUrl>"
            base_url=$(echo "$full_url" | awk -F'/' '{print $1"//"$3}')

            curl -i -X POST \
              "$base_url/code/api/v1/repos/<+pipeline.properties.ci.codebase.repoName>/pullreq/<+trigger.prNumber>/comments?accountIdentifier=<+account.identifier>&orgIdentifier=<+org.identifier>&projectIdentifier=<+project.identifier>" \
              -H 'Content-Type: application/json' \
              -H "x-api-key: $secret" \
              -d '{

                "text": "'"$comment"'"
              }'
          envVariables:
            comment: <+input>
            secret: <+input>
        when:
          stageStatus: Success
          condition: <+trigger.event> == "PR"
      tags: {}
      icon: data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAbZJREFUWEe9lj16hCAQQGc7OJIpadPlHNulpaRNl3OkS0upx9hjQJd8AwwZBQ26otWufrvvzS/e4IJLCPGDGO/9bYkrbpztg3CndfhbaUwh0VWAwymwpUQ3gRlcqci3tshEF4EqnFKwkDhdgBou1J0i542VBCatQQkBpwog3CaAUgpc+pz57PvpAhw+DEOstZR/EhU4juUpGajBc9ejRBpDvEeR0054WmALHoDTBKEcWhdwfP6UADUc1p3SzvsN4XShRG0bHhYIo/buY60/BDjnZkuUw1HQVLbg4QxwOCgD8LAg72OWaIUfEqjBc8PdR6AxjItvPXL6za4SbMGXEi3wXRlogWMp7APg9UtUG27WJOlLUwb2wPF/UaB29h8S6An/twS94ZsCV8BXBa6CVwWuhBcCV8NnAnSw0Ki4z5dyatKc7x212vgVmzAeqx6GYQQpFRQCHeBFBkggnHBcohM8C/Do8eY0xfQrFVfq91s8dvdsuK2082dhFXMBguN9fI0zRgSBHvBZBpyzOXL+MosCeLXu9tbIcxNS9BQxPSBwT3jIAI2f1j6km65eES8zlAV6R7pWml+qnXFeyJAaBAAAAABJRU5ErkJggg==
  EOT
}

// Projects
resource "harness_platform_project" "projects" {
  for_each = var.projects

  identifier  = each.value.proj_id
  name        = each.value.proj_name
  description = each.value.proj_desc
  org_id      = var.org_id
  color       = each.value.proj_color
}

// Services
resource "harness_platform_service" "boutiquepm_service" {
  identifier = "Boutique_PMSerivce"
  name       = "Boutique - PMService"
  org_id     = var.org_id
  yaml       = <<-EOT
    service:
      name: Boutique - PMService
      identifier: Boutique_PMSerivce
      orgIdentifier: ${var.org_id}
      serviceDefinition:
        spec:
          artifacts:
            primary:
              primaryArtifactRef: <+input>
              sources:
                - spec:
                    connectorRef: account.harnessImage
                    imagePath: seworkshop/boutique-pmservice
                    tag: <+pipeline.stages.Build_Test_Push.spec.execution.steps.ProvenanceStepGroup_Build_and_push_image_to_DockerHub.steps.Build_and_push_image_to_DockerHub.artifact_ProvenanceStepGroup_Build_and_push_image_to_DockerHub_Build_and_push_image_to_DockerHub.stepArtifacts.publishedImageArtifacts[0].tag>
                    digest: ""
                  identifier: boutique_pmservice
                  type: DockerRegistry
          manifests:
            - manifest:
                identifier: boutique_pm_service
                type: K8sManifest
                spec:
                  store:
                    type: Github
                    spec:
                      connectorRef: account.Github
                      gitFetchType: Branch
                      paths:
                        - boutique/15-pmservice.yaml
                      repoName: wings-software/e2e-enterprise-demo
                      branch: main
                  valuesPaths:
                    - boutique/values.yaml
                  skipResourceVersioning: false
                  enableDeclarativeRollback: false
          variables:
            - name: cart_service_password
              type: Secret
              description: ""
              required: false
              value: org.Cart_Service_Password_Dev
        type: Kubernetes
  EOT
}

resource "harness_platform_service" "devsecops_services" {
  for_each = {
    for key, value in local.services_map :
    key => value
    if value.infra_key == "devsecops"
  }

  identifier = each.value.service_value.serv_identifier
  name       = each.value.service_value.serv_name
  org_id     = var.org_id
  yaml       = <<-EOT
    service:
      name: ${each.value.service_value.serv_name}
      identifier: ${each.value.service_value.serv_identifier}
      orgIdentifier: ${var.org_id}
      serviceDefinition:
        spec:
          manifests:
            - manifest:
                identifier: ${each.value.service_value.artifact_identifier}
                type: K8sManifest
                spec:
                  store:
                    type: HarnessCode
                    spec:
                      gitFetchType: Branch
                      paths:
                        - harness-deploy/${each.value.service_value.artifact_identifier}/manifests
                      repoName: devsecops
                      branch: main
                  valuesPaths:
                    - harness-deploy/${each.value.service_value.artifact_identifier}/values.yaml
                  skipResourceVersioning: false
                  enableDeclarativeRollback: false
          artifacts:
            primary:
              primaryArtifactRef: <+input>
              sources:
                - spec:
                    connectorRef: account.harnessImage
                    imagePath: seworkshop/devsecops-demo
                    tag: ${each.value.service_value.artifact_tag}
                    digest: ""
                  identifier: ${each.value.service_value.artifact_identifier}
                  type: DockerRegistry
        type: Kubernetes
  EOT
}

// Secrets
resource "harness_platform_secret_text" "cart_service_secret" {
  identifier  = "Cart_Service_Password_Dev"
  name        = "Cart Service Password Dev"
  org_id      = var.org_id
  description = "Example secret used by boutique/values.yaml and boutique/06-frontend.yaml for demonstrating using secrets in pipeline and redacting secrets in logs"

  secret_manager_identifier = "org.harnessSecretManager"
  value_type                = "Inline"
  value                     = "devpassword"
}

// Monitored Services
resource "harness_platform_monitored_service" "boutique_monitored_services" {
  for_each = {
    for key, value in local.services_map :
    key => value
    if value.infra_key == "boutique"
  }

  org_id     = var.org_id
  project_id = local.primary_demo_project
  identifier = each.value.service_value.serv_identifier
  request {
    name            = each.value.service_value.serv_name
    type            = "Application"
    service_ref     = "org.${harness_platform_service.boutiquepm_service.identifier}"
    environment_ref = "org.${harness_platform_environment.environment[each.value.env_key].identifier}"
    health_sources {
      name       = "Prometheus"
      identifier = "prometheus"
      type       = "Prometheus"
      spec = jsonencode({
        connectorRef = "org.prometheus"
        metricDefinitions = [
          {
            identifier = "Prometheus_Metric",
            metricName = "Prometheus Metric",
            riskProfile = {
              riskCategory = "Performance_Other"
              thresholdTypes = [
                "ACT_WHEN_HIGHER"
              ]
            }
            analysis = {
              liveMonitoring = {
                enabled = true
              }
              deploymentVerification = {
                enabled                  = true
                serviceInstanceFieldName = "pod"
              }
            }
            query         = "avg(container_cpu_system_seconds_total { namespace=\"${each.value.infra_value.namespace}\" , container=\"test\"})"
            groupName     = "Infrastructure"
            isManualQuery = true
          }
        ]
      })
    }
  }
}

resource "harness_platform_monitored_service" "devsecops_monitored_services" {
  for_each = {
    for key, value in local.services_map :
    key => value
    if value.infra_key == "devsecops"
  }

  org_id     = var.org_id
  project_id = local.primary_demo_project
  identifier = "${each.value.service_value.serv_identifier}_${each.value.env_key}"
  request {
    name            = each.value.service_value.serv_name
    type            = "Application"
    service_ref     = "org.${harness_platform_service.devsecops_services[each.key].identifier}"
    environment_ref = "org.${harness_platform_environment.environment[each.value.env_key].identifier}"
    health_sources {
      name       = "Prometheus"
      identifier = "prometheus"
      type       = "Prometheus"
      spec = jsonencode({
        connectorRef = "org.prometheus"
        metricDefinitions = [
          {
            identifier = "Prometheus_Metric",
            metricName = "Prometheus Metric",
            riskProfile = {
              riskCategory = "Performance_Other"
              thresholdTypes = [
                "ACT_WHEN_HIGHER"
              ]
            }
            analysis = {
              liveMonitoring = {
                enabled = true
              }
              deploymentVerification = {
                enabled                  = true
                serviceInstanceFieldName = "pod"
              }
            }
            query         = "avg(container_cpu_system_seconds_total { namespace=\"${each.value.infra_value.namespace}\" , container=\"test\"})"
            groupName     = "Infrastructure"
            isManualQuery = true
          }
        ]
      })
    }
  }
}

// OPA Policies
resource "harness_platform_policy" "sca_policy" {
  identifier = "Require_SCA_Scans"
  name       = "Require SCA Scans"
  org_id     = var.org_id
  project_id = local.primary_demo_project
  rego       = <<-REGO
    package pipeline

    required_sca_steps = ["Owasp", "OsvScanner"]
    required_container_steps = ["AquaTrivy"]
    required_scan_steps = array.concat(required_sca_steps, required_container_steps)

    deny[msg] {
        required_step := required_scan_steps[_]
        not missing_scan_step(required_step)
        msg := sprintf("The CI stage is missing the required '%s' step. It's easy to add using the Harness Built-in Scanners.", [required_step])
    }

    deny[msg] {
        first_step := required_sca_steps[_]
        second_step := "BuildAndPushDockerRegistry"
        missing_scan_step(first_step)
        not incorrect_scan_placement(first_step, second_step)
        msg := create_message(first_step, second_step)
    }

    deny[msg] {
        first_step := "Compile_Application"
        second_step := required_sca_steps[_]
        missing_scan_step(second_step)
        not incorrect_scan_placement(first_step, second_step)
        msg := create_message(first_step, second_step)
    }

    deny[msg] {
        first_step := "BuildAndPushDockerRegistry"
        second_step := required_container_steps[_]
        missing_scan_step(second_step)
        not incorrect_scan_placement(first_step, second_step)
        msg := create_message(first_step, second_step)
    }

    contains(arr, elem) {
        arr[_] == elem
    }

    missing_scan_step(required_step) {
        stage = input.pipeline.stages[_].stage
        stage.type == "CI"
        steps := get_all_steps(stage)
        step_types := [step | step := steps[_].step_type ]
        contains(step_types, required_step)
    }

    incorrect_scan_placement(first_step, second_step) {
        stage := input.pipeline.stages[_].stage
        stage.type == "CI"
        steps := get_all_steps(stage)
        verify_scan_placement(steps, first_step, second_step)
    }

    get_all_steps(stage) = steps {
        parallel_steps := [{ "step_type": step_type, "step_index": step_index, "sub_index": sub_index,  } |
            step_type := stage.spec.execution.steps[step_index].parallel[sub_index].step.type
        ]
        sequential_steps := [{ "step_type": step_type, "step_index": step_index, "sub_index": 0,  } |
            step_type := stage.spec.execution.steps[step_index].step.type
        ]
        template_steps := [{ "step_type": step_type, "step_index": step_index, "sub_index": 0,  } |
            step_type := stage.spec.execution.steps[step_index].step.template.templateRef
        ]
        temp_steps := array.concat(parallel_steps, sequential_steps)
        steps := array.concat(temp_steps, template_steps)
        print("Debug: all_steps ", steps)
    }

    get_step_index(steps, step_type) = step_index {
        some index
        steps[index].step_type == step_type
        step_index := steps[index].step_index
    }

    verify_scan_placement(steps, first_step, second_step) {
        first_index := get_step_index(steps, first_step)
        second_index := get_step_index(steps, second_step)
        first_index < second_index
    }

    create_message(first_step_type, second_step_type) = msg {
        msg := sprintf("'%s' must occur prior to the '%s' step.", [first_step_type, second_step_type])
    }
  REGO
}

resource "harness_platform_policy" "sast_policy" {
  identifier = "Require_SAST_Scans"
  name       = "Require SAST Scans"
  org_id     = var.org_id
  project_id = local.primary_demo_project
  rego       = <<-REGO
    package pipeline

    required_scan_steps = ["Semgrep"]

    deny[msg] {
        required_step := required_scan_steps[_]
        not missing_scan_step(required_step)
        msg := sprintf("Future Requirement: In Q4, the CI stage will require a '%s' step. Please ensure this step is added using the Harness Built-in Scanners before that deadline.", [required_step])
    }

    deny[msg] {
        first_step := required_scan_steps[_]
        second_step := "BuildAndPushDockerRegistry"
        missing_scan_step(first_step)
        not incorrect_scan_placement(first_step, second_step)
        msg := create_message(first_step, second_step)
    }

    deny[msg] {
        first_step := "Compile_Application"
        second_step := required_scan_steps[_]
        missing_scan_step(second_step)
        not incorrect_scan_placement(first_step, second_step)
        msg := create_message(first_step, second_step)
    }

    contains(arr, elem) {
        arr[_] == elem
    }

    missing_scan_step(required_step) {
        stage = input.pipeline.stages[_].stage
        stage.type == "CI"
        steps := get_all_steps(stage)
        step_types := [step | step := steps[_].step_type ]
        contains(step_types, required_step)
    }

    incorrect_scan_placement(first_step, second_step) {
        stage := input.pipeline.stages[_].stage
        stage.type == "CI"
        steps := get_all_steps(stage)
        verify_scan_placement(steps, first_step, second_step)
    }

    get_all_steps(stage) = steps {
        parallel_steps := [{ "step_type": step_type, "step_index": step_index, "sub_index": sub_index,  } |
            step_type := stage.spec.execution.steps[step_index].parallel[sub_index].step.type
        ]
        sequential_steps := [{ "step_type": step_type, "step_index": step_index, "sub_index": 0,  } |
            step_type := stage.spec.execution.steps[step_index].step.type
        ]
        template_steps := [{ "step_type": step_type, "step_index": step_index, "sub_index": 0,  } |
            step_type := stage.spec.execution.steps[step_index].step.template.templateRef
        ]
        temp_steps := array.concat(parallel_steps, sequential_steps)
        steps := array.concat(temp_steps, template_steps)
        print("Debug: all_steps ", steps)
    }

    get_step_index(steps, step_type) = step_index {
        some index
        steps[index].step_type == step_type
        step_index := steps[index].step_index
    }

    verify_scan_placement(steps, first_step, second_step) {
        first_index := get_step_index(steps, first_step)
        second_index := get_step_index(steps, second_step)
        first_index < second_index
    }

    create_message(first_step_type, second_step_type) = msg {
        msg := sprintf("'%s' must occur prior to the '%s' step.", [first_step_type, second_step_type])
    }
  REGO
}

resource "harness_platform_policy" "dast_policy" {
  identifier = "Require_DAST_Scans"
  name       = "Require DAST Scans"
  org_id     = var.org_id
  project_id = local.primary_demo_project
  rego       = <<-REGO
    package pipeline

    required_stages = ["DAST_Scans"]

    deny[msg] {
        required_stage := required_stages[_]
        not missing_stage(required_stage)
        msg := sprintf("The pipeline is missing the required '%s' stage.", [required_stage])
    }

    contains(arr, elem) {
        arr[_] == elem
    }

    missing_stage(required_stage) {
        stage_input := input.pipeline.stages
        stages := get_all_stages(stage_input)
        stage_types := [stage | stage := stages[_].stage_type ]
        contains(stage_types, required_stage)
    }

    get_all_stages(stages) = all_stages {
        parallel_stages := [{ "stage_type": stage_type, "stage_index": stage_index, "sub_index": sub_index,  } |
            stage_type := stages[stage_index].parallel[sub_index].stage.type
        ]
        parallel_template_stages := [{ "stage_type": stage_type, "stage_index": stage_index, "sub_index": sub_index,  } |
            stage_type := stages[stage_index].parallel[sub_index].stage.template.templateRef
        ]
        sequential_stages := [{ "stage_type": stage_type, "stage_index": stage_index, "sub_index": 0,  } |
            stage_type := stages[stage_index].stage.type
        ]
        sequential_template_stages := [{ "stage_type": stage_type, "stage_index": stage_index, "sub_index": 0,  } |
            stage_type := stages[stage_index].stage.template.templateRef
        ]    
        all_sequential_stages := array.concat(sequential_stages, sequential_template_stages)
        all_parallel_stages := array.concat(parallel_stages, parallel_template_stages)
        all_stages := array.concat(all_sequential_stages, all_parallel_stages)
        print("Debug: all_stages ", all_stages)
    }
  REGO
}

resource "harness_platform_policy" "approval_gate" {
  identifier = "Mandate_JIRA_or_ServiceNow_Gates"
  name       = "Mandate JIRA or ServiceNow Gates"
  org_id     = var.org_id
  project_id = local.primary_demo_project
  rego       = <<-REGO
    # Required for Production Deployments:
    #         An approval stage prior to deployment
    #         That approval stage to contain a JiraApproval step
    package pipeline

    # Required approval type(s)
    required_steps = ["JiraApproval"]

    deny[msg] {
        some prod_index
        input.pipeline.stages[prod_index].stage.spec.infrastructure.environment.type == "Production"
        not approval_before_prod(prod_index)
        msg := sprintf("Deployment to higher environments require an approval stage. '%s' does not have an Approval stage", [input.pipeline.stages[prod_index].stage.name])
    }

    deny[msg] {
        stage = input.pipeline.stages[_].stage
        stage.type == "Approval"
        existing_steps := [s | s = stage.spec.execution.steps[_].step.type]
        required_step := required_steps[_]
        not contains(existing_steps, required_step)
        msg := sprintf("Approval stage '%s' is missing required step '%s'", [stage.name, required_step])
    }

    approval_before_prod(prod_index) {
        some approval_index
        approval_index < prod_index
        input.pipeline.stages[approval_index].stage.type == "Approval"
    }

    contains(arr, elem) {
        arr[_] = elem
    }
  REGO
}

resource "harness_platform_policy" "org_naming" {
  for_each = var.org_policies

  identifier = "Org_Level_${each.value.pol_type}_Naming_Convention"
  name       = "Org Level ${each.value.pol_type} Naming Convention"
  org_id     = var.org_id
  rego       = each.value.pol_rego
}

// Policy Sets
resource "harness_platform_policyset" "sto_policyset" {
  identifier = "Security_Scan_Steps_Required"
  name       = "Security Scan Steps Required"
  org_id     = var.org_id
  project_id = local.primary_demo_project
  action     = "onsave"
  type       = "pipeline"
  enabled    = false # Change to 'true' once testing is complete
  policies {
    identifier = harness_platform_policy.sca_policy.id
    severity   = "error"
  }
  policies {
    identifier = harness_platform_policy.sast_policy.id
    severity   = "warning"
  }
  policies {
    identifier = harness_platform_policy.dast_policy.id
    severity   = "error"
  }
}

resource "harness_platform_policyset" "org_naming" {
  for_each = var.org_policies

  identifier = "Org_Level_${each.value.pol_type}s_Naming_Convention"
  name       = "Org Level ${each.value.pol_type}s Naming Convention"
  org_id     = var.org_id
  action     = "onsave"
  type       = lower(each.value.pol_type)
  enabled    = true
  policies {
    identifier = harness_platform_policy.org_naming["${lower(each.value.pol_type)}"].id
    severity   = "error"
  }
}

resource "harness_platform_policyset" "approval_required" {
  identifier = "Approval_Required_for_Prod_Deployments"
  name       = "Approval Required for Prod Deployments"
  org_id     = var.org_id
  project_id = local.primary_demo_project
  action     = "onsave"
  type       = "pipeline"
  enabled    = true
  policies {
    identifier = harness_platform_policy.approval_gate.id
    severity   = "error"
  }
}

// Pipeline
resource "harness_platform_pipeline" "devsecops" {
  identifier  = "Secure_Build_and_Deploy"
  name        = "Secure Build and Deploy"
  org_id      = var.org_id
  project_id  = local.primary_demo_project
  description = "https://devsecops.harness-demo.site"
  yaml        = <<-EOT
    pipeline:
      name: Secure Build and Deploy
      identifier: Secure_Build_and_Deploy
      projectIdentifier: ${local.primary_demo_project}
      orgIdentifier: ${var.org_id}
      tags: {}
      properties:
        ci:
          codebase:
            repoName: org.devsecops
            build: <+input>
            sparseCheckout: []
      stages:
        - stage:
            name: Build
            identifier: Build
            description: ""
            type: CI
            spec:
              cloneCodebase: true
              platform:
                os: Linux
                arch: Amd64
              runtime:
                type: Cloud
                spec: {}
              execution:
                steps:
                  - step:
                      type: Test
                      name: Test Intelligence
                      identifier: Test_Intelligence
                      spec:
                        shell: Sh
                        command: |-
                          cd ./python-tests
                          pytest
                        intelligenceMode: true
                  - step:
                      name: Compile
                      identifier: Compile
                      template:
                        templateRef: org.${harness_platform_template.compile.identifier}
                        versionLabel: "${harness_platform_template.compile.version}"
                  - parallel:
                      - step:
                          type: Owasp
                          name: OWASP
                          identifier: OWASP
                          spec:
                            mode: orchestration
                            config: default
                            target:
                              type: repository
                              detection: auto
                            advanced:
                              log:
                                level: info
                          when:
                            stageStatus: Success
                      - step:
                          type: OsvScanner
                          name: OSV Scan
                          identifier: OSV_Scan
                          spec:
                            mode: orchestration
                            config: default
                            target:
                              type: repository
                              detection: auto
                            advanced:
                              log:
                                level: info
                          when:
                            stageStatus: Success
                  - step:
                      type: BuildAndPushDockerRegistry
                      name: Push to Dockerhub
                      identifier: Push_to_Dockerhub
                      spec:
                        connectorRef: account.harnessImage
                        repo: seworkshop/devsecops-demo
                        tags:
                          - ${local.services_map.dev_devsecops_devsec_frontend.service_value.artifact_tag}
                        dockerfile: /harness/frontend-app/harness-webapp/Dockerfile
                        context: /harness/frontend-app/harness-webapp
                  - parallel:
                      - step:
                          type: Background
                          name: dind
                          identifier: dind
                          spec:
                            connectorRef: account.harnessImage
                            image: docker:dind
                            shell: Sh
                      - step:
                          type: AquaTrivy
                          name: Aqua Trivy
                          identifier: Aqua_Trivy
                          spec:
                            mode: orchestration
                            config: default
                            target:
                              type: container
                              detection: auto
                            advanced:
                              log:
                                level: info
                            privileged: true
                            image:
                              type: docker_v2
                              name: seworkshop/devsecops-demo
                              tag: ${local.services_map.dev_devsecops_devsec_frontend.service_value.artifact_tag}
                            sbom:
                              format: spdx-json
        - stage:
            name: Frontend - Deployment
            identifier: Frontend_Deployment
            description: ""
            type: Deployment
            spec:
              deploymentType: Kubernetes
              service:
                serviceRef: org.DevSecOps_Frontend
                serviceInputs:
                  serviceDefinition:
                    type: Kubernetes
                    spec:
                      artifacts:
                        primary:
                          primaryArtifactRef: <+input>
                          sources: <+input>
              environment:
                environmentRef: org.dev
                deployToAll: false
                infrastructureDefinitions:
                  - identifier: devsecops
              execution:
                steps:
                  - step:
                      name: Rollout Deployment
                      identifier: rolloutDeployment
                      type: K8sRollingDeploy
                      timeout: 10m
                      spec:
                        skipDryRun: false
                        pruningEnabled: false
                rollbackSteps:
                  - step:
                      name: Rollback Rollout Deployment
                      identifier: rollbackRolloutDeployment
                      type: K8sRollingRollback
                      timeout: 10m
                      spec:
                        pruningEnabled: false
            tags: {}
            failureStrategies:
              - onFailure:
                  errors:
                    - AllErrors
                  action:
                    type: StageRollback
        - parallel:
            - stage:
                name: Backend - Deployment
                identifier: Backend_Deployment
                description: ""
                type: Deployment
                spec:
                  deploymentType: Kubernetes
                  service:
                    serviceRef: org.DevSecOps_Backend
                    serviceInputs:
                      serviceDefinition:
                        type: Kubernetes
                        spec:
                          artifacts:
                            primary:
                              primaryArtifactRef: <+input>
                              sources: <+input>
                  environment:
                    useFromStage:
                      stage: Frontend_Deployment
                  execution:
                    steps:
                      - stepGroup:
                          name: Canary Deployment
                          identifier: canaryDeployment
                          steps:
                            - step:
                                name: Canary Deployment
                                identifier: canaryDeployment
                                type: K8sCanaryDeploy
                                timeout: 10m
                                spec:
                                  instanceSelection:
                                    type: Count
                                    spec:
                                      count: 1
                                  skipDryRun: false
                            - step:
                                type: Verify
                                name: Verify
                                identifier: Verify
                                spec:
                                  isMultiServicesOrEnvs: false
                                  type: Canary
                                  monitoredService:
                                    type: Default
                                    spec: {}
                                  spec:
                                    sensitivity: LOW
                                    duration: 5m
                                timeout: 2h
                                failureStrategies:
                                  - onFailure:
                                      errors:
                                        - Verification
                                      action:
                                        type: ManualIntervention
                                        spec:
                                          timeout: 2h
                                          onTimeout:
                                            action:
                                              type: StageRollback
                                  - onFailure:
                                      errors:
                                        - Unknown
                                      action:
                                        type: ManualIntervention
                                        spec:
                                          timeout: 2h
                                          onTimeout:
                                            action:
                                              type: Ignore
                            - step:
                                name: Canary Delete
                                identifier: canaryDelete
                                type: K8sCanaryDelete
                                timeout: 10m
                                spec: {}
                      - stepGroup:
                          name: Primary Deployment
                          identifier: primaryDeployment
                          steps:
                            - step:
                                name: Rolling Deployment
                                identifier: rollingDeployment
                                type: K8sRollingDeploy
                                timeout: 10m
                                spec:
                                  skipDryRun: false
                    rollbackSteps:
                      - step:
                          name: Canary Delete
                          identifier: rollbackCanaryDelete
                          type: K8sCanaryDelete
                          timeout: 10m
                          spec: {}
                      - step:
                          name: Rolling Rollback
                          identifier: rollingRollback
                          type: K8sRollingRollback
                          timeout: 10m
                          spec: {}
                tags: {}
                failureStrategies:
                  - onFailure:
                      errors:
                        - AllErrors
                      action:
                        type: StageRollback
            - stage:
                name: DAST Scans
                identifier: DAST_Scans
                template:
                  templateRef: org.${harness_platform_template.dast_v2.identifier}
                  versionLabel: "${harness_platform_template.dast_v2.version}"
  EOT
}

// Code Repo
resource "harness_platform_repo" "org_repos" {
  for_each = var.repos

  identifier     = each.value.repo_id
  org_id         = var.org_id
  default_branch = each.value.default_branch
  source {
    repo = each.value.source_repo
    type = each.value.source_type
  }
}

// Prometheus Connector
resource "harness_platform_connector_prometheus" "prometheus" {
  identifier         = "prometheus"
  name               = "Prometheus"
  org_id             = var.org_id
  description        = "Connector to SE Demo Cluster Prometheus Instance"
  url                = "http://prometheus-k8s.monitoring.svc.cluster.local:9090/"
  delegate_selectors = [local.delegate_selector]
}
