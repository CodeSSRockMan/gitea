#!/bin/bash
export REGION="us-east-1"
export MASTER_TAG="jenkins-master"
export AGENT_TAG="jenkins-agent-ephemeral"
export AGENT_ROLE_NAME="jenkins-agent-role"
export AGENT_PROFILE_NAME="jenkins-agent-profile"
export AGENT_SG_NAME="jenkins-agent-sg"
export DOCKER_HUB_USER="hescobarsanchez"
export IMAGE_NAME="ansible-aws-gcp"
export IMAGE_TAG="latest"
export IMAGE_REF="${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

# Donde acumularemos las variables de estado
export STATE_FILE="/tmp/bootstrap_state.env"
> "$STATE_FILE"
