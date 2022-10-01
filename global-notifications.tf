
locals {
  trigger = {
    gcp = contains(var.clouds, "gcp") ? tfe_workspace.gcp-organization[0].id : 0
    aws = vontains(var.clouds, "aws") ? tfe_workspace.aws-organization[0].id : 0
  }
  triggers = [for k, v in local.trigger : v if v != 0]
}

resource "tfe_notification_configuration" "slack" {
  for_each         = toset(concat([tfe_workspace.terraform-cloud.id],local.triggers))
  name             = "needs_attention"
  enabled          = true
  destination_type = "slack"
  url              = "https://hooks.slack.com/services/${var.slack_token}"
  triggers         = var.notification_triggers
  workspace_id     = each.key
}

