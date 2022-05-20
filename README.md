# terraform-gcp-tfc-bootstrap

This is an opinated Terraform Module that deploys Terraform Cloud for the use case of GCP. By the end of this setup it will manage itself in Terraform Cloud as well as provide a framework for you to manage other workspaces.

## Assumptions

* You are using GitHub
* You are using Slack
* You plan to keep all your terraform-cloud resources within a single repository (ex. terraform-cloud)
* You plan to keep all your GCP managed resources within a single repository (ex. gcp-infrastructure)
* You have a terraform cloud account and have not yet create an organization


## Usage

Example: `main.tf`

```hcl
locals {
  environments = ["development", "uat", "production"]
}

module "workspaces" {
  source            = "git::https://github.com/GlueOps/terraform-gcp-tfc-bootstrap.git"
  org_name          = "antoniostacos"
  tfc_email         = "antoniostacos@glueops.dev"
  github_token_id   = "XXXXXXXXXXXXXXX"
  slack_token       = "XXXXXXXXXXXXXXX"
  githhub_org_name  = "antoniostacos"
  vcs_repo          = "gcp-infrastructure"
  workspaces = [
    {
      workspace         = "gcp-cloudbuild-trigger"
      vcs_branch        = "main"
      envs              = local.environments
      working_directory = "cloudbuild-trigger/tf"
      auto_apply        = true
    },
    {
      workspace         = "gcp-iam"
      vcs_branch        = "feature/iam"
      envs              = local.environments
      working_directory = "iam/tf"
      auto_apply        = false
    }
  ]
}

```




## Inputs Required:

| Name | Description | Required |
| --- | ----------- | -------- |
| org_name | Name of Terraform Cloud Organization | Yes |
| tfc_email  | Email that should be used to recieve billing/marketing notifications from terraform cloud | Yes |
| slack_token | slack token used for webhook notifications |Yes |
| github_token_id  |  [Connecting GitHub to Terraform Cloud](https://www.terraform.io/cloud-docs/vcs/github) | Yes |
| githhub_org_name  | Name of your github organization | Yes |
| vcs_repo  | name of the repository containing your GCP terraform | Yes |
| terraform_version | Default "1.1.9" | No |
| notification_triggers  | Default ["run:needs_attention"]  | No |
| workspaces  | Example documented below. | Yes |

#### Workspaces example:

```hcl
    {
      workspace         = "gcp-iam"
      vcs_branch        = "main"
      envs              = ["dev","uat"]
      working_directory = "iam/tf"
      auto_apply        = false
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
```bash
terraform apply --target=module.workspaces.tfe_workspace.terraform-cloud --target=module.workspaces.tfe_workspace.gcp-organization
```

6. Create a slack token to enter for the final apply. https://{your-workspace}.slack.com/apps/A0F7XDUAZ-incoming-webhooks

7. Run terraform apply and paste in the slack token you created.

```bash
terraform apply
```

8. Create an organization token: https://www.terraform.io/cloud-docs/users-teams-organizations/api-tokens#organization-api-tokens
9. Put org token as a variable in the `terraform-cloud` workspace within *Terraform Cloud* as a sensitive, Terraform variable, called tfc_token, using the description: tfc org token.

10. Migrating to TFC. Update your backend.tf so it looks like this...
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

## Set up GCP Service User

1. At the Organization level, grant `Billing Account Administrator`, `Owner`, and `Organization Administrator` permissions to your user.
2. Create project for service accounts, e.g. `antoniostacos-1-svc-accounts`
ref: https://lunajacob.medium.com/setting-up-terraform-cloud-with-gcp-e1fe6c99a78e

3. Create a billing account for GCP and link the billing account to your service project.

4. Enable `Cloud Billing API` for service account, at https://console.cloud.google.com/apis/library/cloudbilling.googleapis.com.
   Enable `Resource Manager API` for service account, at https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com
   Enable `Cloud KMS API` for service account, at https://console.developers.google.com/apis/api/cloudkms.googleapis.com
   Enable `AppEngine API` for service account, at https://console.cloud.google.com/apis/library/appengine.googleapis.com
   Enable `CloudBuild API` for service account, at https://console.cloud.google.com/apis/library/cloudbuild.googleapis.com
   Enable `Kubernetes Engine API` for service account, at https://console.developers.google.com/apis/library/container.googleapis.com


5. open CloudShell in the service account project and run the following:
```
gcloud iam service-accounts create svc-terraform \
--description "Service account for all projects, used by Terraform Cloud" \
--display-name "svc-account for Terraform Cloud"
```

6. Retrieve service account email address using: `gcloud iam service-accounts list`
```
$ gcloud iam service-accounts list
DISPLAY NAME: svc-account for Terraform Cloud
EMAIL: svc-terraform@antoniostacos-1-svc-accounts.iam.gserviceaccount.com
DISABLED: False
```


7. At the `Organization` level, grant `Billing Account Administrator`, `Organization Administrator`, and `Project Creator` roles to `svc-terraform@antoniostacos-1-svc-accounts.iam.gserviceaccount.com`, so they apply to all projects.
Navigate to IAM and use the email address you saved to apply permissions.

## Add GCP Credentials in TFC.

1. Create credentials for your service account (svc-terraform@antoniostacos-1-svc-accounts.iam.gserviceaccount.co): https://developers.google.com/workspace/guides/create-credentials#service-account (Make sure you do JSON format). Once you download the credentials in JSON format, remove all the `\n` (newline) characters (e.g. in vim, use :%s/\n//g).

2. Take the credentials without newlines and add them to the variable set in `tfc_core` variable set in Terraform Cloud. Add it as a sensitive Environment variable called GOOGLE_CREDENTIALS.

3. Keep note of the svc-terraform@antoniostacos-1-svc-accounts.iam.gserviceaccount.com as you will need it if you are using our other modules to bootstrap your GCP projects/organization.




