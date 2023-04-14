#!/bin/bash
set -e

DEFAULT_REGION='ap-southeast-2'

function usage {
    echo "DESCRIPTION:"
    echo "  Script for initializing an AWS account structure. See README for more details."
    echo "  *** MUST BE RUN WITH ADMIN CREDENTIALS FOR terraform-init USER IN THE MANAGEMENT ACCOUNT ***"
    echo ""
    echo "USAGE:"
    echo "  deploy.sh -a terraform_init_access_key -s terraform_init_secret_key -k keybase_profile"
    echo "  [-r default_region] [-l] [-t tf_account_id] [-p]"
    echo ""
    echo "OPTIONS"
    echo "  -l   skip using local state, can be used after the inital run, must provide tf_account_id"
    echo "  -p   push code to remote repo, should only be used once to bootstrap CodeCommit"
    echo "  -r   the default region for this deployment"
    echo "  -t   account ID where Terraform state is stored, used with -l option"
}

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}

while getopts "a:s:k:r:lt:ph" option; do
    case ${option} in
        a ) ACCESS_KEY=$OPTARG;;
        s ) SECRET_KEY=$OPTARG;;
        k ) KEYBASE_PROFILE=$OPTARG;;
        r ) DEFAULT_REGION=$OPTARG;;
        l ) SKIP_LOCAL_STATE=1;;
        t ) TF_AWS_ACCT=$OPTARG;;
        p ) PUSH_CODE=1;;
        h )
            usage
            exit 0
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${ACCESS_KEY}" ]]; then
    echo "Please provide the terraform-init user's AWS access key as -a key" 1>&2
    VALIDATION_ERROR=1
fi
if [[ -z "${SECRET_KEY}" ]]; then
    echo "Please provide the terraform-init user's AWS secret access key as -s secret " 1>&2
    VALIDATION_ERROR=1
fi
if [[ -z "${KEYBASE_PROFILE}" ]]; then
    echo "Please provide the keybase profile as -k profile " 1>&2
    VALIDATION_ERROR=1
fi
if [[ -n "${SKIP_LOCAL_STATE}" && -z "${TF_AWS_ACCT}" ]]; then
    echo "Please provide the account ID where Terraform state is stored as -t tf_account_id " 1>&2
    VALIDATION_ERROR=1
fi
if [[ -n "${VALIDATION_ERROR}" ]]; then
    usage
    exit 1
fi

export AWS_DEFAULT_REGION=${DEFAULT_REGION}
echo "Set default region: $AWS_DEFAULT_REGION"
echo ""

function export_management_keys {
    echo "USING MANAGEMENT CREDENTIALS"
    echo ""
    export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
}

function export_admin_keys {
    echo "USING ADMIN CREDENTIALS"
    echo ""
    export AWS_ACCESS_KEY_ID=${ADMIN_ACCESS_KEY}
    export AWS_SECRET_ACCESS_KEY=${ADMIN_SECRET_KEY}
}

pushd ./src

pushd ./bootstrap/organization

export_management_keys

if [[ -n "${SKIP_LOCAL_STATE}" ]]; then
    echo "=== RUNNING ORG CONFIGS WITH REMOTE STATE ==="
    export TF_AWS_ACCT=${TF_AWS_ACCT}

    echo "Running terragrunt init"
    terragrunt init
    echo "Running terragrunt apply"
    terragrunt apply
else
    echo "=== RUNNING ORG CONFIGS WITH LOCAL STATE ==="
    
    echo "Copying local state override file from overrides/backend-local.override.tf"
    cp overrides/backend-local-override.tf .
    echo ""
 
    echo "Running terragrunt init using local state"
    terragrunt init --terragrunt-config terragrunt-local.hcl
    echo "Running terragrunt apply using local state"
    terragrunt apply --terragrunt-config terragrunt-local.hcl

    echo "Exporting Terraform state account"
    DEPLOYMENT_AWS_ACCT=$(terraform output -json account_ids | jq -r '."deployment"')
    export TF_AWS_ACCT=${DEPLOYMENT_AWS_ACCT}

    echo "=== COPYING LOCAL STATE TO S3 ==="
    echo "Removing backend-local-override.tf"
    rm ./backend-local-override.tf || true
    sleep 10 # give AWS some time for the IAM policy to take effect
    echo "Running terragrunt init to initialise Terraform state S3 backend"
    terragrunt init
fi

echo "Terraform state account is set to: $TF_AWS_ACCT"
echo ""

echo "Outputting account IDs into accounts.json"
terraform output -json account_ids | jq > ../../accounts.json
cat ../../accounts.json
echo ""
popd

echo "=== CREATING temp-admin USER ==="
pushd ./bootstrap/temp-admin
echo "Running terragrunt init"
terragrunt init
echo "Running terragrunt apply using Terraform state account $TF_AWS_ACCT and keybase profile $KEYBASE_PROFILE"
terragrunt apply -var terraform_state_account_id=${TF_AWS_ACCT} -var keybase=${KEYBASE_PROFILE}

echo "Storing and decrypting temp-admin access keys"
ADMIN_ACCESS_KEY=$(terraform output -raw temp_admin_access_key)
ADMIN_SECRET_KEY=$(terraform output -raw temp_admin_secret_key | base64 --decode | keybase --pinentry=none pgp decrypt)
popd

echo "Sleeping for 10 seconds to allow AWS keys to be ready"
sleep 10 # give AWS some time for the new access key to be ready

echo "=== APPLYING ALL ACCOUNT RESOURCES ==="
export_admin_keys

echo "=== APPLYING INFRASTRUCTURE FOR EACH ACCOUNT ==="
pushd ./accounts
terragrunt run-all init
terragrunt run-all apply

pushd ./ap-southeast-2/deployment/codecommit
REPO_NAME=$(terragrunt output -raw repository_name)
echo "Stored CodeCommit repository name: $REPO_NAME"
popd

popd

popd # go to root folder of this repo

if [[ -n "${PUSH_CODE}" ]]; then
    echo "=== PREPARING TO PUSH CODE TO CODE COMMIT REPOSITORY ==="
    echo "Cleaning up Terragrunt and Terraform cache"
    find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \; # clean Terragrunt cache data
    find . -type d -name ".terraform" -prune -exec rm -rf {} \; # clean Terraform cache data
    echo "Preparing source code folder"
    rm -rf repository    # clean if already exists
    mkdir repository
    echo "Cloning CodeCommig repository: codecommit://$REPO_NAME in to repository folder"
    git clone codecommit://$REPO_NAME repository
    echo "Transfering source code into cloned repository folder"
    rsync -av . ./repository --exclude repository
    pushd ./repository
    echo "Running git add and commit for initial commit"
    git --git-dir=.git add .
    git --git-dir=.git commit -m "Bootstrap commit"
    echo "Pushing to remote repository"
    git --git-dir=.git push
    popd
    echo "Cleaning up repository folder"
    rm -rf repository
fi

echo "=== DESTROYING temp-admin USER ==="
pushd ./src/bootstrap/temp-admin
export_management_keys
terragrunt destroy -var terraform_state_account_id=${TF_AWS_ACCT} -var keybase=${KEYBASE_PROFILE}
popd
echo "=== temp-admin USER DESTROYED ==="

echo "You can now clone the repository into a new folder and work with git going forward."
echo "The deployed CI/CD pipeline will take care of the build and deployment process."
echo ""
echo "See README for more information about how to best access the CodeCommit repository using git."
