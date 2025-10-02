Models to download
Format: source:identifier:filename (one per line)
Sources: hf (HuggingFace), civitai, url
`export MODELS="
hf:runwayml/stable-diffusion-v1-5/v1-5-pruned-emaonly.safetensors:sd15.safetensors

<!-- https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors -->

hf:stabilityai/sdxl-vae/sdxl_vae.safetensors:sdxl_vae.safetensors

civitai:123456:my_lora.safetensors
url:https://example.com/model.safetensors:custom_model.safetensors
"`
