
resource "tfe_workspace" "terraform-cloud" {
  name              = "terraform-cloud"
  organization      = tfe_organization.primary_org.id
  terraform_version = var.terraform_version
  description       = "Workspace for managing all TFC workspaces with TFC."
  vcs_repo {
    identifier     = "${var.githhub_org_name}/${var.terraform_cloud_repo}"
    branch         = "main"
    oauth_token_id = var.github_token_id

  }
}

