#!/bin/bash
# File_Rel_Path: 'verify_images_sha256sums.sh'
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

./app_sh/get-apt.sh

# Check if images.json exists
if [ ! -f images.json ]; then
    echo "Error: images.json not found."
    exit 1
fi

# Initialize arrays
device_codenames=()
grapheneos_versions=()

if [[ -n "$DEVICE_CODENAME" && -n "$GRAPHENEOS_VERSION" ]]; then
    # Only process the specified image
    images_count=1
    device_codenames+=("$DEVICE_CODENAME")
    grapheneos_versions+=("$GRAPHENEOS_VERSION")
elif [[ -z "$DEVICE_CODENAME" && -z "$GRAPHENEOS_VERSION" ]]; then
    echo "Reading images.json..."

    # Read images count
    images_count=$(jq '.images | length' images.json)
    echo "Found $images_count images in images.json."

    # Read images into arrays, skipping entries with null device_codename or version
    for ((i=0; i<images_count; i++)); do
        dc="$(jq -r ".images[$i].device_codename" images.json)"
        gv="$(jq -r ".images[$i].grapheneos_version" images.json)"

        # Skip if device_codename or grapheneos_version is "null"
        if [[ "$dc" == "null" || "$gv" == "null" ]]; then
            continue
        fi

        device_codenames+=("$dc")
        grapheneos_versions+=("$gv")
    done
else
    echo "Error: Both device codename and GrapheneOS version must be specified together."
    exit 1
fi

echo "Found ${#device_codenames[@]} image(s) to verify."

# List images
for ((i=0; i<${#device_codenames[@]}; i++)); do
    device_codename="${device_codenames[$i]}"
    grapheneos_version="${grapheneos_versions[$i]}"
    echo "Image: ${device_codename}-install-${grapheneos_version}.zip"
done

# Ensure we have allowed_signers for SSH-based verification
if [ ! -f allowed_signers ]; then
    echo "Error: allowed_signers file not found. Exiting."
    exit 1
fi

# Verify checksums and signatures
for ((i=0; i<${#device_codenames[@]}; i++)); do
    device_codename="${device_codenames[$i]}"
    grapheneos_version="${grapheneos_versions[$i]}"
    image_filename="imgs/${device_codename}-install-${grapheneos_version}.zip"
    sha256sum_filename="imgs/${device_codename}-install-${grapheneos_version}.zip.sha256sum"
    signature_filename="imgs/${device_codename}-install-${grapheneos_version}.zip.sig"

    echo ""
    echo "Processing $image_filename..."

    if [ ! -f "$image_filename" ]; then
        echo "Error: $image_filename not found. Exiting."
        exit 1
    fi

    if [ ! -f "$sha256sum_filename" ]; then
        echo "Error: $sha256sum_filename not found. Exiting."
        exit 1
    fi

    echo "Verifying SHA256 checksum for $image_filename..."
    sha256sum -c "$sha256sum_filename"
    if [ $? -ne 0 ]; then
        echo "Error: Checksum verification failed for $image_filename."
        exit 1
    else
        echo "Checksum verification passed for $image_filename."
    fi

    if [ ! -f "$signature_filename" ]; then
        echo "Error: $signature_filename not found. Exiting."
        exit 1
    fi

    echo "Verifying signature using $signature_filename for $image_filename..."

    if grep -Fq -- "-----BEGIN SSH SIGNATURE-----" "$signature_filename"; then
        # Use ssh-keygen for SSH signature
        sig_output=$(ssh-keygen -Y verify \
                     -f allowed_signers \
                     -I contact@grapheneos.org \
                     -n "factory images" \
                     -s "$signature_filename" \
                     < "$image_filename" 2>&1)
        if echo "$sig_output" | grep -q "Good \"factory images\" signature for contact@grapheneos.org"; then
            echo "SSH signature verification passed for $image_filename."
        else
            echo "Error: Signature verification failed for $image_filename."
            echo "ssh-keygen output: $sig_output"
            exit 1
        fi
    else
        # Use signify-openbsd for signify format
        if [ ! -f factory.pub ]; then
            echo "Error: factory.pub not found for signify-openbsd verification. Exiting."
            exit 1
        fi
        sig_output=$(signify-openbsd -V -m "$image_filename" -x "$signature_filename" -p factory.pub 2>&1)
        if echo "$sig_output" | grep -q "Signature Verified"; then
            echo "Signature verification passed for $image_filename."
        else
            echo "Error: Signature verification failed for $image_filename."
            echo "Signify output: $sig_output"
            exit 1
        fi
    fi
done

echo ""
echo "All image checksums and signatures verified successfully."
