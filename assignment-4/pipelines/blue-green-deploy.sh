#!/usr/bin/env bash
set -euo pipefail

IMAGE_URI="$1"
AWS_REGION="${2:-us-east-1}"

ALB_ARN=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?contains(LoadBalancerName,'swapi')].LoadBalancerArn" \
    --output text --region "$AWS_REGION")

LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn "$ALB_ARN" \
    --query "Listeners[?Port==\`80\`].ListenerArn" \
    --output text --region "$AWS_REGION")

TG_BLUE_ARN=$(aws elbv2 describe-target-groups \
    --names "tg-blue" --query "TargetGroups[0].TargetGroupArn" \
    --output text --region "$AWS_REGION")
TG_GREEN_ARN=$(aws elbv2 describe-target-groups \
    --names "tg-green" --query "TargetGroups[0].TargetGroupArn" \
    --output text --region "$AWS_REGION")

LIVE_TG_ARN=$(aws elbv2 describe-rules \
    --listener-arn "$LISTENER_ARN" \
    --query "Rules[?IsDefault==\`true\`].Actions[0].TargetGroupArn" \
    --output text --region "$AWS_REGION")

if [ "$LIVE_TG_ARN" = "$TG_BLUE_ARN" ]; then
    IDLE_TG_ARN="$TG_GREEN_ARN"
    IDLE_COLOR="green"
    LIVE_COLOR="blue"
    IDLE_ASG="asg-green"
else
    IDLE_TG_ARN="$TG_BLUE_ARN"
    IDLE_COLOR="blue"
    LIVE_COLOR="green"
    IDLE_ASG="asg-blue"
fi

echo "Current live: $LIVE_COLOR | Deploying to: $IDLE_COLOR"

LAUNCH_TEMPLATE=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$IDLE_ASG" \
    --query "AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId" \
    --output text --region "$AWS_REGION")

NEW_VERSION=$(aws ec2 create-launch-template-version \
    --launch-template-id "$LAUNCH_TEMPLATE" \
    --source-version "\$Latest" \
    --launch-template-data "{\"ImageId\":\"${IMAGE_URI}\"}" \
    --query "LaunchTemplateVersion.VersionNumber" \
    --output text --region "$AWS_REGION")

aws autoscaling start-instance-refresh \
    --auto-scaling-group-name "$IDLE_ASG" \
    --preferences '{"MinHealthyPercentage":100}' \
    --region "$AWS_REGION"

echo "Waiting for instance refresh on $IDLE_ASG..."
for i in $(seq 1 30); do
    STATUS=$(aws autoscaling describe-instance-refreshes \
        --auto-scaling-group-name "$IDLE_ASG" \
        --query "InstanceRefreshes[0].Status" \
        --output text --region "$AWS_REGION")
    echo "  Refresh status: $STATUS"
    [ "$STATUS" = "Successful" ] && break
    [ "$STATUS" = "Failed" ] && { echo "Instance refresh failed"; exit 1; }
    sleep 30
done

echo "Waiting for all targets in $IDLE_COLOR target group to become healthy..."
for i in $(seq 1 20); do
    UNHEALTHY=$(aws elbv2 describe-target-health \
        --target-group-arn "$IDLE_TG_ARN" \
        --query "TargetHealthDescriptions[?TargetHealth.State!='healthy'] | length(@)" \
        --output text --region "$AWS_REGION")
    [ "$UNHEALTHY" = "0" ] && break
    echo "  Unhealthy targets: $UNHEALTHY — waiting..."
    sleep 15
done

TEST_LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn "$ALB_ARN" \
    --query "Listeners[?Port==\`8081\`].ListenerArn" \
    --output text --region "$AWS_REGION")

ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$ALB_ARN" \
    --query "LoadBalancers[0].DNSName" \
    --output text --region "$AWS_REGION")

echo "Running smoke test against $IDLE_COLOR via port 8081..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${ALB_DNS}:8081/health" || echo "000")
echo "Smoke test HTTP status: $HTTP_STATUS"

if [ "$HTTP_STATUS" != "200" ]; then
    echo "ERROR: Smoke test failed (HTTP $HTTP_STATUS). NOT switching listener. Pipeline failing."
    LOG_ENTRY="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"sha\":\"${GIT_COMMIT:-unknown}\",\"image\":\"${IMAGE_URI}\",\"from\":\"${LIVE_COLOR}\",\"to\":\"${IDLE_COLOR}\",\"result\":\"failed\"}"
    echo "$LOG_ENTRY" | aws s3 cp - s3://swapi-terraform-state-d76255a5/deploy-log.jsonl \
        --content-type text/plain --region "$AWS_REGION" 2>/dev/null || true
    exit 1
fi

echo "Smoke test passed. Switching ALB listener to $IDLE_COLOR..."
aws elbv2 modify-listener \
    --listener-arn "$LISTENER_ARN" \
    --default-actions "Type=forward,TargetGroupArn=${IDLE_TG_ARN}" \
    --region "$AWS_REGION"

echo "Traffic switched. $IDLE_COLOR is now live. $LIVE_COLOR is the new rollback color."

LOG_ENTRY="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"sha\":\"${GIT_COMMIT:-unknown}\",\"image\":\"${IMAGE_URI}\",\"from\":\"${LIVE_COLOR}\",\"to\":\"${IDLE_COLOR}\",\"result\":\"success\"}"
EXISTING=$(aws s3 cp s3://swapi-terraform-state-d76255a5/deploy-log.jsonl - --region "$AWS_REGION" 2>/dev/null || echo "")
echo -e "${EXISTING}\n${LOG_ENTRY}" | aws s3 cp - s3://swapi-terraform-state-d76255a5/deploy-log.jsonl \
    --content-type text/plain --region "$AWS_REGION"

echo "Deployment complete."
