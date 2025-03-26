#!/bin/bash

# Usage: ./gen_sha256sum.sh <filename>
# This script generates a SHA256 checksum of the provided filename
# and appends the result to <filename>.sha256sum (in the same directory).

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

input_file="$1"
sha256_output="${input_file}.sha256sum"

# Create the directory for the output file if it doesn’t exist
mkdir -p "$(dirname "$sha256_output")"

if [ ! -f "$input_file" ]; then
  echo "Error: File '$input_file' not found."
  exit 1
fi

sha256sum "$input_file" >> "$sha256_output"
echo "Appended SHA256 checksum to '$sha256_output'."

