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
https://github.com/comfyanonymous/ComfyUI_experiments.git
https://github.com/Fannovel16/comfyui_controlnet_aux.git
https://github.com/rgthree/rgthree-comfy.git
https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git
https://github.com/cubiq/ComfyUI_essentials.git
https://github.com/ZHO-ZHO-ZHO/ComfyUI-BRIA_AI-RMBG.git
https://github.com/spacepxl/ComfyUI-Image-Filters.git
"

export MODELS="
hf:stabilityai/sdxl-vae/sdxl_vae.safetensors:sdxl_vae.safetensors
civitai:1413921:Uncanny_Valley.safetensors
civitai:652659:pony_lcm.safetensors
"

# Custom tasks to run (optional, separated by |)
export CUSTOM_TASKS=""