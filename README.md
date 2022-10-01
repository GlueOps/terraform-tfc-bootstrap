# terraform-tfc-bootstrap

This is an opinated Terraform Module that deploys Terraform Cloud for mananging cloud infrastructure. By the end of this setup it will manage itself in Terraform Cloud as well as provide a framework for you to manage other workspaces.

This Module can be used in conjunction with [terraform-gcp-organization-bootstrap](https://github.com/GlueOps/terraform-gcp-organization-bootstrap) or [terraform-aws-organization-bootstrap](https://github.com/GlueOps/terraform-aws-organization-bootstrap) to configure a new cloud environment with accounts / projects.

## Assumptions

* You are using GitHub
* You are using Slack
* You plan to keep all your terraform-cloud resources within a single repository (ex. terraform-cloud)
* You plan to keep all your Cloud managed resources within a single repository (ex. gcp-infrastructure or aws-infrastructure)
* You have a terraform cloud account and have not yet create an organization


## Usage

Example: `main.tf`

```hcl
locals {
  environments = ["development", "uat", "production"]
}

module "workspaces" {
  source                = "git::https://github.com/GlueOps/terraform-tfc-bootstrap.git"
  org_name              = "antoniostacos"
  tfc_email             = "camarero@antoniostacos.net"
  github_token_id       = "XXXXXXXXXXXXXXX"
  slack_token           = "XXXXXXXXXXXXXXX"
  githhub_org_name      = "antoniostacos"
  gcp_vcs_repo          = "gcp-infrastructure"
  clouds                 = ["gcp"]
  terraform_cloud_repo  = "terraform-cloud"
  workspaces = [
    {
      workspace         = "gcp-cloudbuild-trigger"
      vcs_repo          = "gcp-infrastructure"
      vcs_branch        = "main"
      envs              = local.environments
      working_directory = "cloudbuild-trigger/tf"
      auto_apply        = true
      cloud             = "gcp"
    },
    {
      workspace         = "gcp-iam"
      vcs_repo          = "gcp-infrastructure"
      vcs_branch        = "feature/iam"
      envs              = local.environments
      working_directory = "iam/tf"
      auto_apply        = false
      cloud             = "gcp"
    }
  ]
}

```




## Inputs Required:

| Name                  | Description                                                                               | Required |
| --------------------- | ----------------------------------------------------------------------------------------- | -------- |
| org_name              | Name of Terraform Cloud Organization                                                      | Yes      |
| tfc_email             | Email that should be used to recieve billing/marketing notifications from terraform cloud | Yes      |
| slack_token           | slack token used for webhook notifications                                                | Yes      |
| github_token_id       | [Connecting GitHub to Terraform Cloud](https://www.terraform.io/cloud-docs/vcs/github)    | Yes      |
| githhub_org_name      | Name of your github organization                                                          | Yes      |
| gcp_vcs_repo          | name of the repository containing your GCP terraform                                      | Yes      |
| aws_vcs_repo          | name of the repository containing your AWS terraform                                      | Yes      |
| terraform_version     | Default "1.2.9"                                                                           | No       |
| notification_triggers | Default ["run:needs_attention"]                                                           | No       |
| workspaces            | Example documented below.                                                                 | Yes      |
| clouds                | Defaults to ["gcp"] but also supports ["gcp","aws"].                                      | No       |
| terraform_cloud_repo  | Defaults to "terraform-cloud".                                                            | No       |

#### Workspaces example:

```hcl
    {
      workspace         = "gcp-iam"
      gcp_vcs_repo      = "gcp-infrastructure"
      vcs_branch        = "main"
      envs              = ["dev","uat"]
      working_directory = "iam/tf"
      auto_apply        = false
      cloud             = ["gcp"]
    }
```
The above will create two workspaces in terraform cloud that are called `gcp-iam-dev` and `gcp-iam-uat`, they will not have auto_apply enabled, they will both take changes made to the folder `iam/tf` within the `main` branch of the `gcp-infrastructure` repository.


## Let's start deploying this:

1. Your backend.tf should look something like this:
```hcl
  provider "tfe" {}
```

2. Login to terraform cloud and create the new organization:
```bash
terraform login
terraform init
terraform apply --target=module.workspaces.tfe_organization.primary_org
```

3. [Connecting GitHub to Terraform Cloud](https://www.terraform.io/cloud-docs/vcs/github)
 
4. Get `OAuth Token ID` generated from Step #3 (This is inside Terraform Cloud Console) and update the input `github_token_id` to use the token ID

5. Run another targeted apply to deploy the `terraform-cloud` workspace:
For GCP:
```bash
terraform apply --target=module.workspaces.tfe_workspace.terraform-cloud --target=module.workspaces.tfe_workspace.gcp-organization
```
For AWS:
```bash
terraform apply --target=module.workspaces.tfe_workspace.terraform-cloud --target=module.workspaces.tfe_workspace.aws-organization
```

1. Create a slack token to enter for the final apply. https://{your-workspace}.slack.com/apps/A0F7XDUAZ-incoming-webhooks

2. Run terraform apply and paste in the slack token you created.

```bash
terraform apply
```

1. Create an organization token: https://www.terraform.io/cloud-docs/users-teams-organizations/api-tokens#organization-api-tokens
2. Put org token as a variable in the `terraform-cloud` workspace within *Terraform Cloud* as a sensitive, Terraform variable, called tfc_token, using the description: tfc org token.

3.  Migrating to TFC. Update your backend.tf so it looks like this...
```hcl
# variable "tfc_token" {}

terraform {
  required_version = "1.1.9"
  backend "remote" {
    organization = "antoniostacos"
    workspaces {
      name = "terraform-cloud"
    }
  }
  required_providers {
    tfe = "0.31.0"
  }
}


provider "tfe" {
  # token = var.tfc_token
}
```
* Run `terraform init` and then type `yes` when prompted to migrate because the backend changed.
* Update your backend.tf to look like this.
```hcl
variable "tfc_token" {}

terraform {
  required_version = "1.1.9"
  backend "remote" {
    organization = "antoniostacos"
    workspaces {
      name = "terraform-cloud"
    }
  }
  required_providers {
    tfe = "0.31.0"
  }
}

provider "tfe" {
  token = var.tfc_token
}
```
* Commit main.tf and backend.tf and push them up to github

11. Add a variable set called `tfc_core` that applies to all workspaces: https://learn.hashicorp.com/tutorials/terraform/cloud-multiple-variable-sets. Create a sensitive environment variable under `tfc_core` called TF_VAR_slack_token using the slack token you created earlier.


# For GCP:

## Set up GCP Service User

https://github.com/GlueOps/terraform-gcp-organization-bootstrap

## Add GCP Credentials in TFC.

1. Create credentials for your service account (svc-terraform@antoniostacos-1-svc-accounts.iam.gserviceaccount.co): https://developers.google.com/workspace/guides/create-credentials#service-account (Make sure you do JSON format). Once you download the credentials in JSON format, remove all the `\n` (newline) characters (e.g. in vim, use :%s/\n//g).

2. Take the credentials without newlines and add them to the variable set in `tfc_core` variable set in Terraform Cloud. Add it as a sensitive Environment variable called GOOGLE_CREDENTIALS.

3. Keep note of the svc-terraform@antoniostacos-1-svc-accounts.iam.gserviceaccount.com as you will need it if you are using our other modules to bootstrap your GCP projects/organization.

# For AWS:

1. Create an IAM account in the ROOT/Organization account called `svc-terraform` and give it full administrator access.

2. Take the credentials and add them to the variable set `tfc_core` in Terraform cloud and mark the `AWS_SECRET_ACCESS_KEY` as a secret variable.
   * AWS_ACCESS_KEY_ID
   * AWS_SECRET_ACCESS_KEY
