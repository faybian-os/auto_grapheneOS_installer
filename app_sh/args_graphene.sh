#!/bin/bash
# File_Rel_Path: 'app_sh/args_graphene.sh'
# File_Type: '.sh'

# Initialize variables
DEVICE_CODENAME=""
GRAPHENEOS_VERSION=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [--device_codename DEVICE_CODENAME --grapheneos_version GRAPHENEOS_VERSION]"
    echo "       $0 [DEVICE_CODENAME GRAPHENEOS_VERSION]"
    echo "If no arguments are provided, all images in images.json will be processed."
    exit 0
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --device_codename)
            DEVICE_CODENAME="$2"
            shift
            ;;
        --grapheneos_version)
            GRAPHENEOS_VERSION="$2"
            shift
            ;;
        --help|-h)
            show_usage
            ;;
        -*)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
        *)
            if [[ -z "$DEVICE_CODENAME" ]]; then
                DEVICE_CODENAME="$1"
            elif [[ -z "$GRAPHENEOS_VERSION" ]]; then
                GRAPHENEOS_VERSION="$1"
            else
                echo "Unknown parameter passed: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

