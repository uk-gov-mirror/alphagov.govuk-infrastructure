# This script runs an arbitrary task using an existing task defintion in a
# new container, using ECS RunTask.
# It is expected to be run via the run-task Concourse task.

set -eu

# Raise error if env vars not set
: "${ASSUME_ROLE_ARN:?ASSUME_ROLE_ARN not set}"
: "${GOVUK_ENVIRONMENT:?GOVUK_ENVIRONMENT not set}"
: "${APPLICATION:?APPLICATION not set}"
: "${COMMAND:?COMMAND not set}"
: "${CLUSTER:?COMMAND not set}"

mkdir -p ~/.aws

cat <<EOF > ~/.aws/config
[profile default]
role_arn = $ASSUME_ROLE_ARN
credential_source = Ec2InstanceMetadata
EOF

# TODO: Change this to point at govuk module once govuk-test is gone
cd "src/terraform/deployments/govuk-$GOVUK_ENVIRONMENT"

terraform init -backend-config "role_arn=$ASSUME_ROLE_ARN"

task_definition_arn=$(cat terraform-outputs/task_definition_arn)
private_subnets=$(terraform output -json private_subnets)
security_group=$(terraform output -json $APPLICATION'_security_groups')
network_config='awsvpcConfiguration={subnets='$private_subnets',securityGroups='$security_groups',assignPublicIp=DISABLED}'

echo "Starting task..."

task=$(aws ecs run-task --cluster $CLUSTER \
--task-definition $task_definition_arn --launch-type FARGATE --count 1 \
--network-configuration $network_config \
--overrides '{
  "containerOverrides": [{
    "name": "'"$APPLICATION"'",
    "command": ["/bin/bash", "-c", "'"$COMMAND"'"]
  }]
}')

task_arn=$(echo $task | jq .tasks[0].taskArn)

echo "waiting for task $task_arn to finish..."

aws ecs wait tasks-stopped --tasks=[$task_arn] --cluster $CLUSTER

echo "task finished."

task_results=$(aws ecs describe-tasks --tasks=[$task_arn] --cluster $CLUSTER)
echo $task_results

exit_code=$(echo $task_results | jq [.tasks[0].containers[].exitCode] | jq add)

echo "Exiting with code $exit_code"

exit exit_code
