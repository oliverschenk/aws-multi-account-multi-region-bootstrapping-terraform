# AWS Multi-account Multi-region Bootstrapping with Terraform

This is a sample project on multi-account and multi-region deployments in AWS. 

For detailed information see the [AWS Multi-account Multi-region Bootstrapping with Terraform](https://medium.com/@oliver.schenk/aws-multi-account-multi-region-bootstrapping-with-terraform-39aeed097ad2) article on Medium.

## Cost considerations

The resources deployed in this project includes a number of accounts and features, but the cost should be relatively low if you don't start deploying resources outside of this guide.

You will most likely see some charges that could include, but is not limited to, the following:

- S3 due to CodeBuild artifacts, Terraform state and logging
- CodeCommit, CodeBuild, CodePipeline due to the CI/CD pipline
- KMS for encryption
- CodeTrail for audit logs

> **You are responsible for managing your own costs.**

## Architecture

The aim of this project is to bootstrap a foundational multi-account structure. This includes AWS Organizations, five member accounts, a CI/CD pipeline for this project and the basic roles needed to manage Terraform state and deploy resources into member accounts.

The AWS Organization that is created has the following OU structure and member accounts.

- **Root OU**
  - Management Account
  - **Deployment OU**
    - Deployment Account
  - **Infrastructure OU**
    - Shared Services Account
  - **Sandbox OU**
    - Development Account
  - **Security OU**
    - Logging Account
    - Security Account
  - **Workloads OU**
    - **Prod OU**
    - **Test OU**

The OUs structure shown can be customised to your own needs in the `bootstrap/organization/main.tf` Terraform source if you have different requirements. The basic purpose of each is listed below.

- **Deployment OU** - This is where accounts relating to CI/CD and source code go.
- **Infrastructure OU** - This is where networking, operational tooling like AWS Systems Manager, shared services like IAM Identity Center and shared VPC for bastion hosts go.
- **Sandbox OU** - Accounts for developers either randomly allocated or one per developer go here. This project just adds one generic account.
- **Security OU** - This is where logging accounts and security tool accounts go for the security team. This project only adds CloudTrail, but there are dozens of tools offered by AWS for Security management.
- **Workloads OU** - This is where your main customer facing workloads go for test and production. You would host these in separate projects and CI/CD pipelines to this project.

Again, you will most likely customise this project according to your own needs.

## Project Structure

The source code is structured to contain four primary areas of interest. It is best to read the [main article related to this project](https://medium.com/@oliver.schenk/aws-multi-account-multi-region-bootstrapping-with-terraform-39aeed097ad2) to understand more about the details given below.

### Root folder and src/common_vars.yaml

The `common_vars.yaml` file is where you adjust the configuration to suit your own requirements. For example namespace, names, account email addresses, notification settings, etc...

The `deploy.sh` script will run the deployment.

> To understand exactly what steps the bootstrapping process is taking, read the `deploy.sh` bash script. This might help at least understand the high level steps.

The `TerraformInit-IAM-Policy.json` is the policy that needs to be manually attached to the `terraform-init` user in the Management account. This is explained in the main instructions.

The `destroy.sh` script can be used to destroy resource. See the later second on how to destroy the resources.

### src/bootstrap

This contains the code for the first phase of the deployment, which is setting up the AWS Organization, OUs and member accounts. This also includes initial Terraform state and Terraform deployment cross-account roles.

The resources in this folder should only be the bare minimum required that can't be deployed by the Deployment acccount. All other resources should be defined in the `src/accounts` folder under the relevant region and account.

> After initial deployment the CI/CD pipeline will become active, however it will NOT deploy any changes to the resources in the bootstrap folder. If you need to change the underlying AWS Organization, accounts or cross-account roles for Terraform state or deployment, then you will need to run them locally using the `deploy.sh` script.

Once the accounts and cross-account roles are created, the bootstrap script creates a `temp-admin` user using the `temp-admin` Terraform module. This user is then used to deploy resources into the member accounts from the *Deployment* account (which after this bootstraping process is then taken over by the CI/CD pipeline). The `temp-admin` user is deleted at the end of the `deploy.sh` script.

### src/accounts

This contains the code for deploying resources related to each individual account and region. Most of the accounts are empty, as they are just for demonstration of the structure, except for the Deployment account, which contains the CI/CD pipeline.

> After initial deployment the CI/CD pipeline will become active. This means if you push any changes into your CodeCommit repo for this project, the CI/CD pipeline will deploy the resources in this folder based on the `buildspec-plan.yaml` and `buildspec-apply.yaml` files.

### src/accounts.json

The accounts.json file is automatically generated by the `deploy.sh` script during the bootstrapping process. It is used by the Terraform and Terragrunt code to obtain account IDs where needed.

> You should not modify this file directly.

If you add any further accounts, you will need to run the `deploy.sh` script again in any case, which will generate a new `accounts.json` file for you.

### src/modules

This is where re-usable Terraform modules go.

## Environment and Tooling

This project was tested in a WSL2 Ubuntu environment running on a Windows 11 host operating system.

You can use either a similar setup or a native Linux style operating system. The scripting language used by the initialisation script in this project is *bash*.

The infrastructure is written in Terraform and uses Terragrunt as a supporting layer.

You will need the following tools in order to get started. The simplest way to install them might be to use [Homebrew](https://brew.sh/) and then you can install some of the following tools without much fuss.

**AWS CLI**

This is used for deployment of AWS resources

**Terraform**

This is the primary infrastructure as code framework and 
language

**Terragrunt**

This is used to keep Terraform DRY and reduces boilerplate

**git**

This is used to push the initial code into the CodeCommit 
repo for the CI/CD pipeline

**git-remote-codecommit**

This is needed to allow git to interact with a private CodeCommit repo using AWS credentials. You'll also need to install `pip` to get this installed as you won't find it on Homebrew.

See: https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-git-remote-codecommit.html

**jq**

This is used to prettify the JSON output of `accounts.json`

**Keybase (with Keybase account)**

This is used to encrypt the temporary admin credentials. Given the credentials are only temporary you could do without this step, but it was done as a best practice in any case.

If you don't want to use Keybase you'll have to adjust the `deploy.sh` script and the `aws_iam_access_key.temp_admin` resource in `src/bootstrap/temp-admin` to remove any references to Keybase. This will then give you un-encrypted outputs.

## Configuration

Adjust the variables in the `common_vars.yaml` file to suit your own needs.

In the `deploy.sh` script change the `DEFAULT_REGION` to your own requirements or else specify the region with the `-r` flag when running the script.

## Prepare Management account

To deploy the resources in this project you will need to sign-up for an AWS account or use an existing account. It is suggested that you use a new account as it means you can follow the steps with least modification.

This project includes AWS Organizations, so if you already have it enabled in an existing account you may see errors unless you change the reference to AWS Organizations in the Terraform code under `bootstrap/organization/main.tf` to a `data` resource and then update all the references accordingly.

Again, it might be best to deploy to a brand new account.

## Running the script

### For the first time

If you are running this script for the first time then the bootstrapping process should use a local Terraform state as you don't yet have a remote state. You should also push the code to the CodeCommit repo using the `-p` flag.

```
./deploy.sh \
  -a <terraform_init_access_key> \
  -s <terraform_init_secret_key> \
  -k <your_keybase_account>\
  -p
```

### Subsequent times

You may need to run the `deploy.sh` script more than once if you've encountered errors or if you made changes to the code in the `src/boostrap/organization` folder.

If you've successfully run the first phase of the bootstrapping process and your accounts were created, it should copy the local state to S3 remote state. 

If at least this part was successful you can skip the local state part by using the `-l` flag and specify the Terraform state account ID (the *Deployment* account) using the `-t` flag.

```
./deploy.sh \
  -a <terraform_init_access_key> \
  -s <terraform_init_secret_key> \
  -k <your_keybase_account> \
  -l \
  -t <deployment_account_id>
  ```

You should see the Terraform state account number output in your terminal.

## How to access the CodeCommit repository

This project will create a CodeCommit repository in the *Deployment* account. The bootstrapping script will make a copy of this project automatically and commit and push the code into CodeCommit.

Once the bootstrapping process is completed you will then be able to clone this project and start using this to make any further changes. To access a private CodeCommit repository you can make use of the `git-remote-codecommit` integration with git.

For more details see the following: https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-git-remote-codecommit.html

To set up the necessary credentials you should use IAM Identity Center in the Console, create a user group, user and permission set for access to CodeCommit and attach it to the *Deplyoment* account. You'll then be able to use AWS Single Sign-On (SSO) through the AWS CLI using `aws configure sso`.

The repository will be: `codecommit://aws_profile@repo_name`

## Destroying resources

Destroying the resources created in this project is not quite as easy as creating them, because there are a few factors involved. I've included a `destroy.sh` script, but there are a few things you need to do first before this will work.

This may sound obvious, but you should only destroy the resources in this project if you haven't already used the accounts created for other deployments and projects!

The first issue is that AWS Organization and the member accounts are marked with a lifecycle policy where `prevent_destroy = true`. This will cause Terraform to throw an error if you try to destroy these resources. This is good in a real deployment, but a bit annoying if you just want to play around with the code in this article.

To get ready to destroy these resources you'll have to make some changes and then apply those using the deploy.sh script. The first change is remove the `lifecycle` block from all of the relevant resources. The second change is add `close_on_deletion = true` in all of the aws_organizations_account resources to ensure deleting the account also results in its closure.

Another thing to note is that the AWS Organization quota will only allow you to close a maximum of 10 accounts, but this should be ok for this project. The bigger issue is only 3 accounts may be closed concurrently, so you may still end up having to login to your Management account and then remove those accounts in AWS Organizations manually.

Finally, before you can use the `destroy.sh` script, you'll need the `terraform-init` user and access keys for this user. If you removed this user, or no longer have the access keys, you'll need to create this user and get new access keys from the Management account.

With all this in place you can try to use the `destroy.sh` script. It's hard to test for all possible deployments, but it essentially runs everything in reverse and doesn't bother with local state.

Good luck, in the worst case you'll have to manually delete the accounts.