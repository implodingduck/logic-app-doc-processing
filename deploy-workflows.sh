#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOWS_DIR="${SCRIPT_DIR}/workflows"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

if [ ! -d "$WORKFLOWS_DIR" ]; then
  echo "ERROR: Workflows directory not found at $WORKFLOWS_DIR"
  exit 1
fi

WORKFLOW_FILES=$(find "$WORKFLOWS_DIR" -maxdepth 1 -name '*.json' -type f)
if [ -z "$WORKFLOW_FILES" ]; then
  echo "ERROR: No workflow JSON files found in $WORKFLOWS_DIR"
  exit 1
fi

# Extract Logic App name and resource group from Terraform state
echo "Reading Logic App details from Terraform state..."
LOGICAPP_ID=$(cd "$TERRAFORM_DIR" && terraform state show azapi_resource.logicapp 2>/dev/null | grep '^\s*id\s' | head -1 | awk -F'"' '{print $2}')

if [ -z "$LOGICAPP_ID" ]; then
  echo "ERROR: Could not determine Logic App resource ID from Terraform state."
  echo "Make sure you have run 'terraform apply' in the terraform directory."
  exit 1
fi

RESOURCE_GROUP=$(echo "$LOGICAPP_ID" | grep -oP '(?i)resourceGroups/\K[^/]+')
LOGICAPP_NAME=$(echo "$LOGICAPP_ID" | grep -oP '(?i)sites/\K[^/]+')

echo "Logic App Name:    $LOGICAPP_NAME"
echo "Resource Group:    $RESOURCE_GROUP"

# Build the deployment package
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

for wf_file in $WORKFLOW_FILES; do
  wf_name=$(basename "$wf_file" .json)
  echo "Packaging workflow: $wf_name"
  mkdir -p "$TEMP_DIR/$wf_name"
  cp "$wf_file" "$TEMP_DIR/$wf_name/workflow.json"
done

ZIP_FILE="${TEMP_DIR}.zip"
trap 'rm -rf "$TEMP_DIR" "$ZIP_FILE"' EXIT

(cd "$TEMP_DIR" && zip -r "$ZIP_FILE" ./*)

echo "Deploying workflows to Logic App '$LOGICAPP_NAME'..."
az logicapp deployment source config-zip \
  --name "$LOGICAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --src "$ZIP_FILE"

echo "Deployment complete!"
