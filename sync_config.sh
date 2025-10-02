#!/bin/bash

################################################################################
# ComfyUI Sync Configuration
################################################################################

# ComfyUI Installation Directory
export COMFYUI_DIR="/workspace/ComfyUI"

# Models Directory (flat structure)
export MODELS_DIR="/workspace/ComfyUI/models"

# Whether to update existing custom nodes (true/false)
export UPDATE_NODES="false"

# Whether to start ComfyUI after sync (true/false)
export START_COMFYUI="true"

# API Keys (automatically loaded from RunPod secrets)
export HUGGINGFACE_TOKEN="${hf}"
export CIVITAI_API_KEY="${civitai_usenet}"

# Custom nodes to install (comma-separated)
export CUSTOM_NODES="
https://github.com/ltdrdata/ComfyUI-Manager.git
https://github.com/Fannovel16/comfyui_controlnet_aux.git
"

# Models to download
# Format: source:identifier:filename (one per line)
# Sources: hf (HuggingFace), civitai, url
export MODELS="
hf:runwayml/stable-diffusion-v1-5/v1-5-pruned-emaonly.safetensors:sd15.safetensors
hf:stabilityai/sdxl-vae/sdxl_vae.safetensors:sdxl_vae.safetensors
civitai:123456:my_lora.safetensors
url:https://example.com/model.safetensors:custom_model.safetensors
"

# Custom tasks to run (optional, separated by |)
export CUSTOM_TASKS=""