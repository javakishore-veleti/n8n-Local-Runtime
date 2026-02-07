#!/usr/bin/env sh
set -e

echo "🚀 Starting local-n8n-platform..."

USER_HOME="$HOME"
if [ -z "$USER_HOME" ]; then
  echo "❌ HOME is not set"
  exit 1
fi

# Base AI data lake (tool-agnostic)
export LOCAL_AI_DATA="${LOCAL_AI_DATA:-$USER_HOME/runtime_data/local-ai-data}"

# Deployment-specific data
export LOCAL_AI_DEPLOY="${LOCAL_AI_DEPLOY:-$USER_HOME/runtime_data/local-ai-deployment}"

# Normalize paths for Windows Git Bash
case "$(uname -s)" in
  MINGW*|MSYS*)
    LOCAL_AI_DATA="$(cd "$LOCAL_AI_DATA" && pwd -W)"
    LOCAL_AI_DEPLOY="$(cd "$LOCAL_AI_DEPLOY" && pwd -W)"
    ;;
esac

echo "📁 LOCAL_AI_DATA=$LOCAL_AI_DATA"
echo "📁 LOCAL_AI_DEPLOY=$LOCAL_AI_DEPLOY"

# -------------------------------
# Create base directories
# -------------------------------
mkdir -p \
  "$LOCAL_AI_DATA/my_profile_data" \
  "$LOCAL_AI_DEPLOY/n8n" \
  "$LOCAL_AI_DEPLOY/postgres" \
  "$LOCAL_AI_DEPLOY/pgadmin" \
  "$LOCAL_AI_DEPLOY/grafana" \
  "$LOCAL_AI_DEPLOY/prometheus" \
  "$LOCAL_AI_DEPLOY/neo4j" \
  "$LOCAL_AI_DEPLOY/mongodb"

# -------------------------------
# Create profile subfolders (idempotent)
# -------------------------------
PROFILE_BASE="$LOCAL_AI_DATA/my_profile_data"

mkdir -p \
  "$PROFILE_BASE/demographics/do-not-consider" \
  "$PROFILE_BASE/travel-preferences/do-not-consider" \
  "$PROFILE_BASE/banking-preferences/do-not-consider" \
  "$PROFILE_BASE/car-driving-preferences/do-not-consider" \
  "$PROFILE_BASE/recreation-preferences/do-not-consider"

echo "✅ Local AI data lake and profile structure ready"

# -------------------------------
# Start Docker Compose
# -------------------------------
docker compose -f DevOps/Local/docker-compose.yml up -d
