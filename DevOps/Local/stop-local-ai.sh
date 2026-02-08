#!/bin/sh
set -e

export USER_HOME="${HOME}"

export LOCAL_AI_DATA="${USER_HOME}/runtime_data/local-ai-data/n8n-local-data"
export LOCAL_AI_DEPLOY="${USER_HOME}/runtime_data/local-ai-data/n8n-local-deployment-data"
export MY_PROFILE_DATA="${USER_HOME}/runtime_data/local-ai-data/my_profile_data"

docker compose -f DevOps/Local/docker-compose.yml down
