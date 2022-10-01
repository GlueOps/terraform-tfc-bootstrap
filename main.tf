


locals {
  env_data = flatten([
    for wks in var.workspaces : [
      for env in wks.envs : [
        {
          workspace         = wks.workspace
          vcs_repo          = wks.vcs_repo
          vcs_branch        = wks.vcs_branch
          env               = env
          working_directory = wks.working_directory
          auto_apply        = wks.auto_apply
          cloud             = wks.cloud
        }
      ]
    ]
  ])
}

resource "tfe_organization" "primary_org" {
  name                     = var.org_name
  email                    = var.tfc_email
  collaborator_auth_policy = "two_factor_mandatory"
}

module "workspaces" {
  source   = "git::https://github.com/GlueOps/terraform-multi-environment-workspace.git?ref=v0.1.1"
  for_each = { for ws in local.env_data : "${ws.workspace}-${ws.env}" => ws }

  tf_cloud_workspace_name       = each.key
  organization                  = tfe_organization.primary_org.id
  terraform_version             = var.terraform_version
  working_directory             = each.value.working_directory
  oauth_token_id                = var.github_token_id
  tf_local_workspace            = each.value.env
  vcs_repo                      = "${var.githhub_org_name}/${each.value.vcs_repo}"
  vcs_branch                    = each.value.vcs_branch
  workspace_ids_to_trigger_runs = [local.trigger[each.value.cloud]]
  auto_apply                    = each.value.auto_apply
  slack_token                   = var.slack_token
}

