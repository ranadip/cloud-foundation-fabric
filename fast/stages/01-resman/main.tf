/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  # convenience flags that express where billing account resides
  billing_ext     = var.billing_account.organization_id == null
  billing_org     = var.billing_account.organization_id == var.organization.id
  billing_org_ext = !local.billing_ext && !local.billing_org
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => v
    if(
      v != null
      &&
      (
        try(v.type, null) == "sourcerepo"
        ||
        contains(
          keys(local.identity_providers),
          coalesce(try(v.identity_provider, null), ":")
        )
      )
      &&
      fileexists("${path.module}/templates/workflow-${try(v.type, "")}.yaml")
    )
  }
  cicd_workflow_var_files = {
    stage_2 = [
      "00-bootstrap.auto.tfvars.json",
      "01-resman.auto.tfvars.json",
      "globals.auto.tfvars.json"
    ]
    stage_3 = [
      "00-bootstrap.auto.tfvars.json",
      "01-resman.auto.tfvars.json",
      "globals.auto.tfvars.json",
      "02-networking.auto.tfvars.json",
      "02-security.auto.tfvars.json"
    ]
  }

  custom_roles = coalesce(var.custom_roles, {})
  groups = {
    for k, v in var.groups :
    k => "${v}@${var.organization.domain}"
  }
  groups_iam = {
    for k, v in local.groups :
    k => "group:${v}"
  }
  identity_providers = coalesce(
    try(var.automation.federated_identity_providers, null), {}
  )
}
