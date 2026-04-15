#!/bin/bash

# ==============================================================================
# Kubeconfig Manager Script
# Path: ~/.kube/configs/<folder>/<file>.yaml
# Requirements: yq (Go version by Mike Farah)
# Note: This script assumes each file contains exactly ONE context/cluster/user.
# ==============================================================================

KUBE_CONFIG_DIR="$HOME/.kube/configs"

# Check if script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be SOURCED to update your current shell."
    echo "Usage: source $0"
    exit 1
fi

refresh_kube() {
  # 1. Dependency Check
  if ! command -v yq &> /dev/null; then
      echo "ERROR: 'yq' is required. Install it: brew install yq"
      return 1
  fi

  if [ ! -d "$KUBE_CONFIG_DIR" ]; then
    echo "WARNING: Directory $KUBE_CONFIG_DIR not found. Creating it..."
    mkdir -p "$KUBE_CONFIG_DIR"
    return 0
  fi

  local all_configs="$HOME/.kube/config"

  # 2. Find and process YAML/YML files
  while IFS= read -r file; do
    
    # Generate unique name (folder-filename)
    local filename=$(basename "$file" | sed 's/\.[^.]*$//')
    local parent_path=$(dirname "$file")
    local parent_folder=$(basename "$parent_path")
    local unique_name=""
    
    if [[ "$parent_folder" == "configs" ]]; then
        unique_name="$filename"
    else
        unique_name="${parent_folder}-${filename}"
    fi

    # 3. Validation & Update
    # Check if the file has more than one context (Safety check)
    local context_count=$(yq '.contexts | length' "$file")
    if [[ "$context_count" -gt 1 ]]; then
      echo "SKIPPING: $file contains multiple contexts. Only single-context files are supported."
      continue
    fi

    local current_ctx_name=$(yq '.contexts[0].name' "$file")

    if [[ "$current_ctx_name" != "$unique_name" ]]; then
      echo "INFO: Harmonizing Kubeconfig: $unique_name"
      
      # Backup strategy: Create a .tmp file first for safety
      yq "
        .contexts[0].name = \"$unique_name\" |
        .contexts[0].context.cluster = \"$unique_name\" |
        .contexts[0].context.user = \"$unique_name\" |
        .clusters[0].name = \"$unique_name\" |
        .users[0].name = \"$unique_name\"
      " "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
      
      # Ensure secure permissions (Read/Write for owner only)
      chmod 600 "$file"
    fi

    all_configs="$all_configs:$file"

  done < <(find "$KUBE_CONFIG_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \))

  # 4. Export to environment
  export KUBECONFIG="$all_configs"
  echo "SUCCESS: KUBECONFIG updated with merged configs."
}

refresh_kube