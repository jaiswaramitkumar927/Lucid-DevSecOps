#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# Configuration / Input Variables
# ==========================================
VAULT_ADDR="${VAULT_ADDR:-https://vault.example.com:8200}"
VAULT_ROLE_ID="${VAULT_ROLE_ID:-}"
VAULT_SECRET_ID="${VAULT_SECRET_ID:-}"
VAULT_KV_MOUNT="${VAULT_KV_MOUNT:-secret}"                     # Default KV engine name
VAULT_SECRET_PATH="${VAULT_SECRET_PATH:-terraform/bootstrap}"  # Secret path in Vault
TFSTATE_FILE="${1:-terraform.tfstate}"                         # File to upload (default: terraform.tfstate)

# ==========================================
# Validation
# ==========================================
if [[ -z "$VAULT_ROLE_ID" || -z "$VAULT_SECRET_ID" ]]; then
  echo "❌ Error: VAULT_ROLE_ID and VAULT_SECRET_ID environment variables must be set."
  exit 1
fi

if [[ ! -f "$TFSTATE_FILE" ]]; then
  echo "❌ Error: State file '$TFSTATE_FILE' not found!"
  exit 1
fi

echo "🔐 Authenticating with Vault via AppRole at $VAULT_ADDR..."

# ==========================================
# Step 1: Authenticate with AppRole to get Client Token
# ==========================================
LOGIN_RESPONSE=$(curl -s --fail --request POST \
  --data "{\"role_id\":\"${VAULT_ROLE_ID}\",\"secret_id\":\"${VAULT_SECRET_ID}\"}" \
  "${VAULT_ADDR}/v1/auth/approle/login")

VAULT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.auth.client_token')

if [[ -z "$VAULT_TOKEN" || "$VAULT_TOKEN" == "null" ]]; then
  echo "❌ Error: Failed to retrieve Vault token."
  exit 1
fi

echo "✅ AppRole authentication successful!"

# ==========================================
# Step 2: Read state file & format payload for KV v2 engine
# ==========================================
# Reads the state file, places it under a key named "tfstate", and wraps it for KV v2
PAYLOAD=$(jq -n --slurpfile tfstate "$TFSTATE_FILE" '{data: {tfstate: $tfstate[0]}}')

echo "📤 Uploading '$TFSTATE_FILE' to Vault path: ${VAULT_KV_MOUNT}/data/${VAULT_SECRET_PATH} ..."

# ==========================================
# Step 3: Write to Vault KV v2 API
# ==========================================
UPLOAD_RESPONSE=$(curl -s --fail --request POST \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --data "$PAYLOAD" \
  "${VAULT_ADDR}/v1/${VAULT_KV_MOUNT}/data/${VAULT_SECRET_PATH}")

VERSION=$(echo "$UPLOAD_RESPONSE" | jq -r '.data.version')

echo "🎉 Success! State file uploaded to Vault under path '${VAULT_KV_MOUNT}/${VAULT_SECRET_PATH}' (Version: ${VERSION})."