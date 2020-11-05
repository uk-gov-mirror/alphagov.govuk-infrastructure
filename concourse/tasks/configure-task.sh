#!/usr/bin/env sh
# This script runs an arbitrary task using an existing task defintion in a
# new container, using ECS RunTask.
# It is expected to be run via the run-task Concourse task.

set -eu

root_dir=$(pwd)

# Raise error if env vars not set
: "${ASSUME_ROLE_ARN:?ASSUME_ROLE_ARN not set}"
: "${GOVUK_ENVIRONMENT:?GOVUK_ENVIRONMENT not set}"
: "${AWS_REGION:?AWS_REGION not set}"
: "${APPLICATION:?APPLICATION not set}"

mkdir -p ~/.aws

cat <<EOF > ~/.aws/config
[profile default]
role_arn = $ASSUME_ROLE_ARN
credential_source = Ec2InstanceMetadata
EOF

# TODO: Change this to point at govuk module once govuk-test is gone
cd "src/terraform/deployments/govuk-$GOVUK_ENVIRONMENT"

terraform init

echo "terraform initialized, now getting terraform outputs"

private_subnets=$(terraform output -json private_subnets)
security_groups=$(terraform output -json $APPLICATION'_security_groups')
network_config='awsvpcConfiguration={subnets='$private_subnets',securityGroups='$security_groups',assignPublicIp=DISABLED}'

echo $network_config > "$root_dir/terraform-outputs/task_network_config"
