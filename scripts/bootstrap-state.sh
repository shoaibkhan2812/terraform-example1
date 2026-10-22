#!/usr/bin/env bash
# Run ONE TIME from a trusted machine after az login, before GitHub CI.
# Required: permission to create RG/storage AND Storage Blob Data Contributor to create the blob container.
set -euo pipefail
: "${TFSTATE_RESOURCE_GROUP:?Set TFSTATE_RESOURCE_GROUP, e.g. rg-terraform-state}"
: "${TFSTATE_STORAGE_ACCOUNT:?Set TFSTATE_STORAGE_ACCOUNT (globally unique 3-24 lowercase letters/digits)}"
: "${TFSTATE_CONTAINER:?Set TFSTATE_CONTAINER, e.g. tfstate}"
LOCATION="${LOCATION:-centralindia}"

az group create --name "$TFSTATE_RESOURCE_GROUP" --location "$LOCATION" --output none
az storage account create \
  --resource-group "$TFSTATE_RESOURCE_GROUP" \
  --name "$TFSTATE_STORAGE_ACCOUNT" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none
az storage container create \
  --account-name "$TFSTATE_STORAGE_ACCOUNT" \
  --name "$TFSTATE_CONTAINER" \
  --auth-mode login \
  --output none

echo "Backend is ready. Enable blob versioning, soft delete and restrict access before production use."
