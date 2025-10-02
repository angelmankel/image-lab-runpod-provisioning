#!/bin/bash

################################################################################
# ComfyUI Model & Node Sync Script
# 
# This script syncs models and custom nodes to an existing ComfyUI installation
# Works with pre-installed ComfyUI containers (like ashleykza's)
# Usage: ./sync_comfyui.sh [config_file]
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
COMFYUI_DIR="${COMFYUI_DIR:-/workspace/ComfyUI}"
MODELS_DIR="${MODELS_DIR:-/workspace/ComfyUI/models}"

# API Keys from RunPod secrets
HUGGINGFACE_TOKEN="${HUGGINGFACE_TOKEN:-${hf:-}}"
CIVITAI_API_KEY="${CIVITAI_API_KEY:-${civitai_usenet:-}}"

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_skip() {
    echo -e "${BLUE}[SKIP]${NC} $1"
}

# Function to check if ComfyUI exists
check_comfyui() {
    if [ ! -d "$COMFYUI_DIR" ]; then
        log_error "ComfyUI not found at $COMFYUI_DIR"
        exit 1
    fi
    log_info "Found ComfyUI at $COMFYUI_DIR"
}

# Function to install system dependencies if needed
install_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if aria2c is installed
    if ! command -v aria2c &> /dev/null; then
        log_info "Installing aria2c for faster downloads..."
        apt-get update && apt-get install -y aria2
    fi
    
    # Check if pip packages are available
    if ! python -c "import huggingface_hub" 2>/dev/null; then
        log_info "Installing huggingface-hub..."
        pip install huggingface-hub
    fi
}

# Function to configure API keys
configure_api_keys() {
    if [ -n "$HUGGINGFACE_TOKEN" ]; then
        log_info "Configuring HuggingFace token..."
        huggingface-cli login --token "$HUGGINGFACE_TOKEN" --add-to-git-credential 2>/dev/null || true
    else
        log_warn "No HuggingFace token found"
    fi
    
    if [ -n "$CIVITAI_API_KEY" ]; then
        log_info "CivitAI API key detected"
    else
        log_warn "No CivitAI API key found"
    fi
}

# Function to sync custom nodes
sync_custom_nodes() {
    log_info "Syncing custom nodes..."
    
    if [ -z "${CUSTOM_NODES:-}" ]; then
        log_info "No custom nodes specified"
        return
    fi
    
    cd "$COMFYUI_DIR/custom_nodes"
    
    # Read nodes line by line, ignoring empty lines and comments
    while IFS= read -r node_repo; do
        # Skip empty lines and comments
        [[ -z "$node_repo" || "$node_repo" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        node_repo=$(echo "$node_repo" | xargs)
        [[ -z "$node_repo" ]] && continue
        
        node_name=$(basename "$node_repo" .git)
        
        if [ -d "$node_name" ]; then
            log_skip "Custom node already exists: $node_name"
            # Optionally update it
            if [ "${UPDATE_NODES:-false}" = "true" ]; then
                log_info "Updating $node_name..."
                cd "$node_name"
                git pull
                cd ..
            fi
        else
            log_info "Installing custom node: $node_name"
            git clone "$node_repo"
            
            # Install requirements if they exist
            if [ -f "$node_name/requirements.txt" ]; then
                log_info "Installing requirements for $node_name..."
                pip install -r "$node_name/requirements.txt"
            fi
        fi
    done <<< "$CUSTOM_NODES"
}

# Function to download from HuggingFace
download_huggingface_model() {
    local model_path="$1"
    local target_file="$2"
    
    if [ -f "$target_file" ]; then
        log_skip "Model already exists: $(basename "$target_file")"
        return 0
    fi
    
    log_info "Downloading from HuggingFace: $model_path"
    
    python -c "
from huggingface_hub import hf_hub_download
import os

# Parse the model path
parts = '$model_path'.split('/', 2)
repo_id = parts[0] + '/' + parts[1] if len(parts) > 1 else '$model_path'
filename = parts[2] if len(parts) > 2 else os.path.basename('$target_file')

try:
    file_path = hf_hub_download(
        repo_id=repo_id,
        filename=filename,
        local_dir=os.path.dirname('$target_file'),
        local_dir_use_symlinks=False,
        token='$HUGGINGFACE_TOKEN' if '$HUGGINGFACE_TOKEN' else None
    )
    # Move to target location if needed
    import shutil
    if file_path != '$target_file':
        shutil.move(file_path, '$target_file')
    print(f'Downloaded to: $target_file')
except Exception as e:
    print(f'Error downloading: {e}')
    exit(1)
"
}

# Function to download from CivitAI
download_civitai_model() {
    local model_id="$1"
    local target_file="$2"
    
    if [ -f "$target_file" ]; then
        log_skip "Model already exists: $(basename "$target_file")"
        return 0
    fi
    
    log_info "Downloading from CivitAI: Model ID $model_id"
    
    local download_url="https://civitai.com/api/download/models/${model_id}"
    
    if [ -n "$CIVITAI_API_KEY" ]; then
        download_url="${download_url}?token=${CIVITAI_API_KEY}"
    fi
    
    aria2c -x 16 -s 16 -k 1M \
        --dir="$(dirname "$target_file")" \
        --out="$(basename "$target_file")" \
        "$download_url"
}

# Function to download from direct URL
download_direct_url() {
    local url="$1"
    local target_file="$2"
    
    if [ -f "$target_file" ]; then
        log_skip "Model already exists: $(basename "$target_file")"
        return 0
    fi
    
    log_info "Downloading from URL: $url"
    
    aria2c -x 16 -s 16 -k 1M \
        --dir="$(dirname "$target_file")" \
        --out="$(basename "$target_file")" \
        "$url"
}

# Function to sync models
sync_models() {
    log_info "Syncing models..."
    
    if [ -z "${MODELS:-}" ]; then
        log_info "No models specified"
        return
    fi
    
    # Create flat models directory
    mkdir -p "$MODELS_DIR"
    
    # Read models line by line, ignoring empty lines and comments
    while IFS= read -r model_entry; do
        # Skip empty lines and comments
        [[ -z "$model_entry" || "$model_entry" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        model_entry=$(echo "$model_entry" | xargs)
        [[ -z "$model_entry" ]] && continue
        
        # Parse format: source:identifier:filename
        IFS=':' read -r model_source model_identifier model_filename <<< "$model_entry"
        
        # Determine filename if not provided
        if [ -z "$model_filename" ]; then
            model_filename=$(basename "$model_identifier")
        fi
        
        target_file="$MODELS_DIR/$model_filename"
        
        # Download based on source
        case $model_source in
            hf|huggingface)
                download_huggingface_model "$model_identifier" "$target_file"
                ;;
            civitai)
                download_civitai_model "$model_identifier" "$target_file"
                ;;
            url|http|https)
                if [[ $model_source == "url" ]]; then
                    download_direct_url "$model_identifier" "$target_file"
                else
                    # Reconstruct full URL
                    full_url="${model_source}:${model_identifier}"
                    download_direct_url "$full_url" "$target_file"
                fi
                ;;
            *)
                log_warn "Unknown model source: $model_source, skipping..."
                continue
                ;;
        esac
    done <<< "$MODELS"
}

# Function to run custom tasks
run_custom_tasks() {
    if [ -z "${CUSTOM_TASKS:-}" ]; then
        return
    fi
    
    log_info "Running custom tasks..."
    
    IFS='|' read -ra TASKS <<< "$CUSTOM_TASKS"
    for task in "${TASKS[@]}"; do
        log_info "Executing: $task"
        eval "$task" || log_error "Failed to execute: $task"
    done
}

# Function to start ComfyUI if not running
start_comfyui() {
    if [ "${START_COMFYUI:-true}" = "true" ]; then
        log_info "Starting ComfyUI..."
        cd "$COMFYUI_DIR"
        python main.py --listen 0.0.0.0 --port 8188
    else
        log_info "Sync complete! Start ComfyUI manually when ready."
    fi
}

# Function to load configuration from file
load_config() {
    if [ $# -gt 0 ] && [ -f "$1" ]; then
        log_info "Loading configuration from $1..."
        source "$1"
    fi
}

# Main execution
main() {
    echo "=================================="
    log_info "ComfyUI Model & Node Sync Script"
    echo "=================================="
    
    # Load configuration file if provided
    load_config "$@"
    
    check_comfyui
    install_dependencies
    configure_api_keys
    sync_custom_nodes
    sync_models
    run_custom_tasks
    
    log_info "Sync completed successfully!"
    echo "=================================="
    
    # Start ComfyUI if configured to do so
    start_comfyui
}

# Run main function
main "$@"