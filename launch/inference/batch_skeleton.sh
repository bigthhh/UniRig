#!/usr/bin/env bash
# Batch generate skeletons with different seeds.
# Usage: bash launch/inference/batch_skeleton.sh --input examples/giraffe.glb --runs 5 [--output_dir results] [--seed_start 1]

set -e

input=""
runs=5
output_dir="results"
seed_start=1
extra_args=()

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --input)      input="$2"; shift ;;
        --runs)       runs="$2"; shift ;;
        --output_dir) output_dir="$2"; shift ;;
        --seed_start) seed_start="$2"; shift ;;
        *)            extra_args+=("$1") ;;
    esac
    shift
done

if [ -z "$input" ]; then
    echo "Usage: $0 --input <file> --runs <N> [--output_dir <dir>] [--seed_start <N>]"
    exit 1
fi

basename=$(basename "$input")
name="${basename%.*}"
ext="${basename##*.}"
mkdir -p "$output_dir"

for ((i = 0; i < runs; i++)); do
    seed=$((seed_start + i))
    output="${output_dir}/${name}_seed${seed}.fbx"
    echo "=== Run $((i+1))/$runs  seed=$seed  output=$output ==="
    bash launch/inference/generate_skeleton.sh \
        --input "$input" \
        --output "$output" \
        --seed "$seed" \
        "${extra_args[@]}"
done

echo "All $runs runs complete. Results in $output_dir/"
