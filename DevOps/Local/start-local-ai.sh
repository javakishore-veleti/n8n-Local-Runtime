#!/bin/sh
set -e

export USER_HOME="${HOME}"

export LOCAL_AI_DATA="${USER_HOME}/runtime_data/local-ai-data/n8n-local-data"
export LOCAL_AI_DEPLOY="${USER_HOME}/runtime_data/local-ai-data/n8n-local-deployment-data"

mkdir -p \
  "${LOCAL_AI_DATA}" \
  "${LOCAL_AI_DEPLOY}/n8n" \
  "${LOCAL_AI_DEPLOY}/postgres" \
  "${LOCAL_AI_DEPLOY}/pgadmin" \
  "${LOCAL_AI_DEPLOY}/grafana" \
  "${LOCAL_AI_DEPLOY}/prometheus" \
  "${LOCAL_AI_DEPLOY}/neo4j" \
  "${LOCAL_AI_DEPLOY}/mongodb"

echo "✅ local-n8n-platform directories ready"

docker compose -f DevOps/Local/docker-compose.yml up -d
