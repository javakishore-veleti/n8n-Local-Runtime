#!/bin/sh
set -e

# Resolve user home (portable)
USER_HOME="$(cd ~ && pwd)"

# Absolute paths (NO ~ anywhere)
LOCAL_AI_DATA="${USER_HOME}/runtime_data/local-ai-data/n8n-local-data"
LOCAL_AI_DEPLOY="${USER_HOME}/runtime_data/local-ai-data/n8n-local-deployment-data"
export MY_PROFILE_DATA="${USER_HOME}/runtime_data/local-ai-data/my_profile_data"

# Export for docker compose
export LOCAL_AI_DATA
export LOCAL_AI_DEPLOY


# Create required directories (idempotent)
mkdir -p \
  "${LOCAL_AI_DATA}" \
  "${LOCAL_AI_DEPLOY}/n8n" \
  "${LOCAL_AI_DEPLOY}/postgres" \
  "${LOCAL_AI_DEPLOY}/pgadmin" \
  "${LOCAL_AI_DEPLOY}/grafana" \
  "${LOCAL_AI_DEPLOY}/prometheus" \
  "${LOCAL_AI_DEPLOY}/neo4j" \
  "${LOCAL_AI_DEPLOY}/mongodb" \
  "${LOCAL_AI_DEPLOY}/redis" \
  "${LOCAL_AI_DEPLOY}/qdrant"

echo "✅ local-n8n-platform directories ready"
echo "📁 LOCAL_AI_DATA   = ${LOCAL_AI_DATA}"
echo "📁 LOCAL_AI_DEPLOY = ${LOCAL_AI_DEPLOY}"

# --- Create profile data folders ---
mkdir -p \
  "${MY_PROFILE_DATA}/demographics/do-not-consider" \
  "${MY_PROFILE_DATA}/travel-preferences/do-not-consider" \
  "${MY_PROFILE_DATA}/banking-preferences/do-not-consider" \
  "${MY_PROFILE_DATA}/car-driving-preferences/do-not-consider" \
  "${MY_PROFILE_DATA}/recreation-preferences/do-not-consider"

echo "✅ local-n8n-platform directories ready"


echo "MY_PROFILE_DATA ${MY_PROFILE_DATA}"
echo "LOCAL_AI_DEPLOY ${LOCAL_AI_DEPLOY}"
echo "LOCAL_AI_DATA ${LOCAL_AI_DATA}"

# Start stack (env vars passed explicitly)
docker compose \
  -f DevOps/Local/docker-compose.yml \
  up -d
