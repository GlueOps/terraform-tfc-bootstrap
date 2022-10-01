variable "slack_token" { sensitive = true }

variable "org_name" {}
variable "tfc_email" {}

variable "github_token_id" {}
variable "githhub_org_name" {}
variable "vcs_repo" {}
variable "terraform_version" { default = "1.2.9" }
variable "clouds" { default = ["gcp"] }
variable "terraform_cloud_repo" { default = "terraform-cloud" }


variable "projects" {
  type = list(string)
  default = [
    "dev",
    "test",
    "stage",
    "prod",
  ]
}

variable "notification_triggers" {
  type    = list(string)
  default = ["run:needs_attention"]
}

variable "workspaces" {
  default = [
    {
      workspace         = "gcp-gke"
      vcs_repo          = "gcp-infrastructure"
      vcs_branch        = "main"
      envs              = ["dev", "stage", "prod"]
      working_directory = "gke/tf"
      auto_apply        = false
      cloud             = "gcp"
  }]
}

