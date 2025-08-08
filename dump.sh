#!/usr/bin/env bash
#
# repo-to-codedump.sh – Flatten a source-code repository into a single
#                       Markdown file (`codedump.md`) whose contents
#                       are grouped in language-tagged code blocks.
#
# Usage:   repo-to-codedump.sh [REPO_DIR]
# Options: -h | --help   Show this help message and exit.
#
# If REPO_DIR is omitted, “.” (the current directory) is assumed.
# The script writes/overwrites `codedump.md` in the current working
# directory.

set -euo pipefail

##############################################################################
# 1. Handle -h / --help and positional argument
##############################################################################
usage() {
  sed -n '2,15p' "$0"   # prints the commented block at the top
  exit 0
}

# Parse flags
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      ;;
  esac
done

# First non-flag argument = repo root (defaults to ".")
REPO_DIR="${1:-.}"
OUTPUT_FILE="codedump.md"

##############################################################################
# 2. Reset / create output file
##############################################################################
> "$OUTPUT_FILE"

##############################################################################
# 3. Find relevant files, skip binaries, emit to Markdown
##############################################################################
find "$REPO_DIR" \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -path "*/venv/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.next/*" \
  -not -path "*/.turbo/*" \
  -not -path "*/.cache/*" \
  -not -name "$OUTPUT_FILE" \
  \( \
    -iname "*.py"    -o -iname "*.js"   -o -iname "*.ts"   -o -iname "*.tsx" \
    -o -iname "*.jsx" -o -iname "*.html" -o -iname "*.css" -o -iname "*.json" \
    -o -iname "*.yml" -o -iname "*.yaml" -o -iname "*.sh"  -o -iname "*.md" \
    -o -iname "*.txt" -o -iname "*.env"  -o -iname "*.go"  -o -iname "*.rs"  \
    -o -iname "*.java" -o -iname "*.c"   -o -iname "*.cpp" -o -iname "*.h"   \
    -o -iname "*.cs"  -o -iname "*.toml" -o -iname "*.ini" -o -iname "*.prisma" \
    -o -iname "Dockerfile*" -o -iname ".gitignore" -o -iname "LICENSE" \
  \) \
  -type f -print | sort | while IFS= read -r file; do

  # Skip binary files (heuristic)
  mimetype=$(file --mime-type -b "$file")
  if [[ "$mimetype" == "application/octet-stream" ]]; then
    echo "Skipping binary: $file" >&2
    continue
  fi

  # Map extension / filename to a Markdown code-block language hint
  ext="${file##*.}"
  lang=""
  case "$ext" in
    py)    lang=python ;;
    js)    lang=javascript ;;
    ts)    lang=typescript ;;
    tsx|jsx) lang=tsx ;;
    html)  lang=html ;;
    css)   lang=css ;;
    json)  lang=json ;;
    yml|yaml) lang=yaml ;;
    sh)    lang=bash ;;
    md)    lang=markdown ;;
    txt)   lang=plaintext ;;
    env|ini) lang=ini ;;
    go)    lang=go ;;
    rs)    lang=rust ;;
    java)  lang=java ;;
    c)     lang=c ;;
    cpp)   lang=cpp ;;
    h)     lang=c ;;
    cs)    lang=csharp ;;
    toml)  lang=toml ;;
    prisma) lang=prisma ;;
  esac

  # Overrides for special basenames
  base=$(basename "$file")
  if [[ "$base" == Dockerfile* ]];   then lang=dockerfile
  elif [[ "$base" == ".gitignore" ]]; then lang=ini
  elif [[ "$base" == "LICENSE" ]];    then lang=plaintext
  fi

  # Append to output file
  {
    echo '```'"$lang"
    echo "// $file"
    cat "$file"
    echo '```'
    echo
  } >> "$OUTPUT_FILE"
done
