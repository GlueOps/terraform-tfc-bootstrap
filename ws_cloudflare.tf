resource "tfe_workspace" "cloudflare-infrastructure" {
  name              = "cloudflare-infrastructure"
  organization      = tfe_organization.primary_org.id
  terraform_version = var.terraform_version
  description       = "Terraform for managing all of cloudflare"
  vcs_repo {
    identifier     = "${var.githhub_org_name}/${var.cloudflare_vcs_repo}"
    branch         = "main"
    oauth_token_id = var.github_token_id

  }
  count = var.cloudflare_enabled == true ? 1 : 0
}
