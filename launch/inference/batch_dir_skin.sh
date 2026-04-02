#!/usr/bin/env bash
# Batch generate skins for all FBX files in a directory.
# Usage: bash launch/inference/batch_dir_skin.sh --input_dir results/skeletons --output_dir results/skins
#
# Output naming: {output_dir}/{original_name}_skin.fbx

set -e

input_dir=""
output_dir="results/skins"
extra_args=()

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --input_dir)  input_dir="$2"; shift ;;
        --output_dir) output_dir="$2"; shift ;;
        *)            extra_args+=("$1") ;;
    esac
    shift
done

if [ -z "$input_dir" ]; then
    echo "Usage: $0 --input_dir <dir> [--output_dir <dir>]"
    exit 1
fi

shopt -s nullglob
fbx_files=("$input_dir"/*.fbx "$input_dir"/*.FBX)
shopt -u nullglob

if [ ${#fbx_files[@]} -eq 0 ]; then
    echo "No .fbx files found in $input_dir"
    exit 1
fi

echo "Found ${#fbx_files[@]} FBX file(s)"
mkdir -p "$output_dir"

for fbx in "${fbx_files[@]}"; do
    name=$(basename "$fbx")
    name="${name%.*}"
    output="${output_dir}/${name}_skin.fbx"
    echo "=== ${name}  output=${output} ==="
    bash launch/inference/generate_skin.sh \
        --input "$fbx" \
        --output "$output" \
        "${extra_args[@]}"
done

echo "Done. Results in $output_dir/"
