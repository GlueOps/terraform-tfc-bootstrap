
locals {
  trigger = {
    gcp = var.cloud == "gcp" ? tfe_workspace.gcp-organization[0].id : 0
    aws = var.cloud == "aws" ? tfe_workspace.aws-organization[0].id : 0
  }
}

resource "tfe_notification_configuration" "slack" {
  for_each         = toset([tfe_workspace.terraform-cloud.id, local.trigger[var.cloud]])
  name             = "needs_attention"
  enabled          = true
  destination_type = "slack"
  url              = "https://hooks.slack.com/services/${var.slack_token}"
  triggers         = var.notification_triggers
  workspace_id     = each.key
}

