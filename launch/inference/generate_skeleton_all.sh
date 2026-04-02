#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXAMPLES_DIR="$REPO_ROOT/examples"
RESULTS_DIR="$REPO_ROOT/results"

mkdir -p "$RESULTS_DIR"

shopt -s nullglob
inputs=("$EXAMPLES_DIR"/*.glb)
shopt -u nullglob

if [ ${#inputs[@]} -eq 0 ]; then
  echo "[ERROR] 未在 $EXAMPLES_DIR 找到 .glb 文件"
  exit 1
fi

ok=0
fail=0

for input in "${inputs[@]}"; do
  base="$(basename "$input" .glb)"
  output="$RESULTS_DIR/${base}_skeleton.fbx"

  echo "[RUN] $input -> $output"
  rm -f "$output"

  if bash "$SCRIPT_DIR/generate_skeleton.sh" --input "$input" --output "$output" && [ -s "$output" ]; then
    echo "[OK] $output"
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
    echo "[FAIL] $input (未生成有效输出: $output)"
  fi
done

echo "[SUMMARY] success=$ok failed=$fail total=${#inputs[@]}"

if [ $fail -gt 0 ]; then
  exit 2
fi
