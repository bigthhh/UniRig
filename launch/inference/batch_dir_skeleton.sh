#!/usr/bin/env bash
# Batch generate skeletons for all GLB files in a directory, each file N times with different seeds.
# Usage: bash launch/inference/batch_dir_skeleton.sh --input_dir examples --runs 3 [--output_dir results] [--seed_start 1]
#
# Output naming: {output_dir}/{filename}_run{N}.fbx
# e.g. results/giraffe_run1.fbx, results/giraffe_run2.fbx, ...

set -e

input_dir=""
runs=3
output_dir="results"
seed_start=1
extra_args=()

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --input_dir)  input_dir="$2"; shift ;;
        --runs)       runs="$2"; shift ;;
        --output_dir) output_dir="$2"; shift ;;
        --seed_start) seed_start="$2"; shift ;;
        *)            extra_args+=("$1") ;;
    esac
    shift
done

if [ -z "$input_dir" ]; then
    echo "Usage: $0 --input_dir <dir> --runs <N> [--output_dir <dir>] [--seed_start <N>]"
    exit 1
fi

shopt -s nullglob
glb_files=("$input_dir"/*.glb)
shopt -u nullglob

if [ ${#glb_files[@]} -eq 0 ]; then
    echo "No .glb files found in $input_dir"
    exit 1
fi

echo "Found ${#glb_files[@]} GLB file(s), $runs run(s) each"
mkdir -p "$output_dir"

for glb in "${glb_files[@]}"; do
    name=$(basename "$glb" .glb)
    for ((i = 1; i <= runs; i++)); do
        seed=$((seed_start + RANDOM % 100000))
        output="${output_dir}/${name}_run${i}.fbx"
        echo "=== ${name}  run ${i}/${runs}  seed=${seed}  output=${output} ==="
        bash launch/inference/generate_skeleton.sh \
            --input "$glb" \
            --output "$output" \
            --seed "$seed" \
            "${extra_args[@]}"
    done
done

echo "Done. Results in $output_dir/"
