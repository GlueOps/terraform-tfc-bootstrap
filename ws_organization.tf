resource "tfe_workspace" "gcp-organization" {
  name              = "gcp-organization"
  organization      = tfe_organization.primary_org.id
  terraform_version = var.terraform_version
  description       = "Terraform for managing the GCP organization and all associated projects."
  working_directory = "organization/tf"
  vcs_repo {
    identifier     = "${var.githhub_org_name}/${var.vcs_repo}"
    branch         = "main"
    oauth_token_id = var.github_token_id

  }
  count = var.cloud == "gcp" ? 1 : 0
}



resource "tfe_workspace" "aws-organization" {
  name              = "aws-organization"
  organization      = tfe_organization.primary_org.id
  terraform_version = var.terraform_version
  description       = "Terraform for managing the AWS organization and all associated accounts."
  working_directory = "organization/tf"
  vcs_repo {
    identifier     = "${var.githhub_org_name}/${var.vcs_repo}"
    branch         = "main"
    oauth_token_id = var.github_token_id

  }
  count = var.cloud == "aws" ? 1 : 0
}
