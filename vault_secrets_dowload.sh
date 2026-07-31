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
VAULT_SECRET_VERSION="${VAULT_SECRET_VERSION:-}"                # Optional: specify version (e.g. 1, 2)
OUTPUT_FILE="${1:-terraform.tfstate}"                          # Target file name (default: terraform.tfstate)

# ==========================================
# Validation
# ==========================================
if [[ -z "$VAULT_ROLE_ID" || -z "$VAULT_SECRET_ID" ]]; then
  echo "❌ Error: VAULT_ROLE_ID and VAULT_SECRET_ID environment variables must be set."
  exit 1
fi

# Prevent accidental overwrite without user awareness
if [[ -f "$OUTPUT_FILE" && "${OVERWRITE_EXISTING:-false}" != "true" ]]; then
  echo "⚠️ Warning: '$OUTPUT_FILE' already exists locally."
  echo "Set OVERWRITE_EXISTING=true to overwrite it automatically."
  read -p "Do you want to overwrite it? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 0
  fi
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
  echo "❌ Error: Failed to retrieve Vault token from login response."
  exit 1
fi

echo "✅ AppRole authentication successful!"

# ==========================================
# Step 2: Build API endpoint (supports versioning)
# ==========================================
API_URL="${VAULT_ADDR}/v1/${VAULT_KV_MOUNT}/data/${VAULT_SECRET_PATH}"

if [[ -n "$VAULT_SECRET_VERSION" ]]; then
  API_URL="${API_URL}?version=${VAULT_SECRET_VERSION}"
  echo "📥 Fetching version $VAULT_SECRET_VERSION of state from Vault path: ${VAULT_KV_MOUNT}/data/${VAULT_SECRET_PATH} ..."
else
  echo "📥 Fetching latest state version from Vault path: ${VAULT_KV_MOUNT}/data/${VAULT_SECRET_PATH} ..."
fi

# ==========================================
# Step 3: Fetch State from Vault KV v2 API
# ==========================================
FETCH_RESPONSE=$(curl -s --fail --header "X-Vault-Token: ${VAULT_TOKEN}" "$API_URL")

# Extract the tfstate object
TFSTATE_DATA=$(echo "$FETCH_RESPONSE" | jq '.data.data.tfstate')

if [[ "$TFSTATE_DATA" == "null" || -z "$TFSTATE_DATA" ]]; then
  echo "❌ Error: No 'tfstate' payload found at specified path."
  exit 1
fi

# ==========================================
# Step 4: Write state to local destination file
# ==========================================
echo "$TFSTATE_DATA" > "$OUTPUT_FILE"

# Extract metadata for feedback
FETCHED_VERSION=$(echo "$FETCH_RESPONSE" | jq -r '.data.metadata.version')

echo "🎉 Success! Downloaded version $FETCHED_VERSION and saved state to '$OUTPUT_FILE'."