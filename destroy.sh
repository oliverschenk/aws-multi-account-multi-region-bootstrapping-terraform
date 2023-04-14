#!/bin/bash
set -e

DEFAULT_REGION='ap-southeast-2'

function usage {
    echo "DESCRIPTION:"
    echo "  Script for initializing an AWS account structure. See README for more details."
    echo "  *** MUST BE RUN WITH ADMIN CREDENTIALS FOR terraform-init USER IN THE MANAGEMENT ACCOUNT ***"
    echo ""
    echo "USAGE:"
    echo "  destroy.sh -a terraform_init_access_key -s terraform_init_secret_key -k keybase_profile"
    echo "  [-r default_region] [-t tf_account_id]"
    echo ""
    echo "OPTIONS"
    echo "  -r   the default region for this deployment"
    echo "  -t   account ID where Terraform state is stored, used with -l option"
}

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}

while getopts "a:s:k:r:t:h" option; do
    case ${option} in
        a ) ACCESS_KEY=$OPTARG;;
        s ) SECRET_KEY=$OPTARG;;
        k ) KEYBASE_PROFILE=$OPTARG;;
        r ) DEFAULT_REGION=$OPTARG;;
        t ) TF_AWS_ACCT=$OPTARG;;
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
if [[ -z "${TF_AWS_ACCT}" ]]; then
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

export TF_AWS_ACCT=${TF_AWS_ACCT}

pushd ./src

echo "Terraform state account is set to: $TF_AWS_ACCT"
echo ""

export_management_keys

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

echo "=== DESTROYING ALL ACCOUNT RESOURCES ==="
export_admin_keys

echo "=== DESTROYING INFRASTRUCTURE FOR EACH ACCOUNT ==="
pushd ./accounts
terragrunt run-all plan -destroy

popd

export_management_keys

echo "=== DESTROYING temp-admin USER ==="
pushd ./bootstrap/temp-admin
terragrunt destroy -var terraform_state_account_id=${TF_AWS_ACCT} -var keybase=${KEYBASE_PROFILE}
popd
echo "=== temp-admin USER DESTROYED ==="

pushd ./bootstrap/organization
echo "=== DESTROYING ORGANISATION CONFIGS ==="
terragrunt plan -destroy
popd

echo "Resources destroyed"