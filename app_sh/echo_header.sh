#!/bin/bash
# File_Rel_Path: 'app_sh/echo_header.sh'
# File_Type: '.sh'

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] HEADER_MESSAGE"
    echo "Displays the HEADER_MESSAGE with optional colors."
    echo "------"
    echo "Options:"
    echo "  --leading_whitespace=[true/false]  Specify whether to display leading blank lines (default: true)"
    echo "  --colored_datetime=[color]  Display the current date and time in the specified color before the header message"
    echo "  --no_leading_whitespace   Do not display leading blank lines (equivalent to --leading_whitespace=false)"
    echo "  --no_trailing_div"
    echo "  --help     Show this help message."
    exit 0
}

LEADING_WHITESPACE="true"
TRAILING_DIV="true"
COLORED_DATETIME=""

# Parse arguments
ARGS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --leading_whitespace=*)
            LEADING_WHITESPACE="${1#*=}"
            shift
            ;;
        --colored_datetime=*)
            COLORED_DATETIME="${1#*=}"
            shift
            ;;
        --no_leading_whitespace)
            LEADING_WHITESPACE="false"
            shift
            ;;
        --no_trailing_div)
            TRAILING_DIV="false"
            shift
            ;;
        --help)
            show_usage
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ${#ARGS[@]} -eq 0 ]; then
    show_usage
fi

INPUT_LINES=("${ARGS[@]}")

# Use local script directory
SCRIPT_DIR="$(dirname "$0")"

print_message() {
    local message="$1"
    local color="$2"
    message=$(echo -e "$message")
    if [ -n "$color" ]; then
        "$SCRIPT_DIR/echoc.sh" --color "$color" --message "$message"
    else
        echo "$message"
    fi
}

parse_json_line() {
    local json="$1"
    json=$(echo "$json" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    json=${json#\{}
    json=${json%\}}
    IFS=',' read -ra fields <<< "$json"
    for field in "${fields[@]}"; do
        field=$(echo "$field" | sed 's/^[ \t]*//;s/[ \t]*$//')
        key=$(echo "$field" | awk -F': *' '{print $1}' | tr -d '"')
        value=$(echo "$field" | awk -F': *' '{print $2}' | tr -d '"')
        eval "$key='$value'"
    done
}

is_json_line() {
    local line="$1"
    if [[ "$line" =~ ^\{.*\}$ ]]; then
        return 0
    else
        return 1
    fi
}

if [ "$LEADING_WHITESPACE" = "true" ]; then
    echo ""
    echo ""
fi

if [ -n "$COLORED_DATETIME" ]; then
    current_datetime=$(date '+%Y-%m-%d %H:%M:%S')
    print_message "$current_datetime" "$COLORED_DATETIME"
fi

for json_line in "${INPUT_LINES[@]}"; do
    unset message level color
    if is_json_line "$json_line"; then
        parse_json_line "$json_line"
        print_message "$message" "$color"
    else
        print_message "$json_line"
    fi
done

if [ "$TRAILING_DIV" = "true" ]; then
    print_message "------"
fi

