#!/bin/sh
set -e

export USER_HOME="${HOME}"

export LOCAL_AI_DATA="${USER_HOME}/runtime_data/local-ai-data/n8n-local-data"
export LOCAL_AI_DEPLOY="${USER_HOME}/runtime_data/local-ai-data/n8n-local-deployment-data"

docker compose -f DevOps/Local/docker-compose.yml down -v

echo "⚠️ Removing deployment data only"
rm -rf "${LOCAL_AI_DEPLOY}"

echo "✅ local-n8n-platform deployment destroyed (data lake untouched)"
