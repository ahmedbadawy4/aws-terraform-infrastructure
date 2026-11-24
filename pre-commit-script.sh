#!/usr/bin/env bash
# Runs the pre-commit hooks one folder at a time for each file type, then once for the whole repo.
# A failing folder does not stop the loop, so every folder gets reported.
set -u

for pattern in '*.tf*' '*.yaml' '*.hcl'; do
  find . -type f -name "$pattern" -not -path '*/.*' -exec dirname {} \; | sort -u | while read -r dir; do
    echo "Processing directory: ${dir#./}"
    find "${dir#./}" -maxdepth 1 -type f -print0 | xargs -0 pre-commit run --files
  done
done

pre-commit run --all-files
