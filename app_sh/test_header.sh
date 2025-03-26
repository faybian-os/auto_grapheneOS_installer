#!/bin/bash

# Define an array of JSON strings
header_lines=(
'{"message": " Call Stack:", "level": 0, "color": "blue"}'
'{"message": "├─ run_full_copy.sh", "level": 1, "color": "green"}'
'{"message": "  ├─ git f", "level": 2, "color": "yellow"}'
)

# Call echo_header.sh
./echo_header.sh --no_leading_whitespace "${header_lines[@]}"

