#!/bin/bash
# File_Rel_Path: 'gen_images_sha256sums.sh'

./app_sh/get-apt.sh

echo ""
echo ""
echo "------"
echo "Running sha256sums Generation."
echo "------"
# Check if images.json exists
if [ ! -f images.json ]; then
  echo "Error: images.json not found."
  exit 1
fi

echo "Reading images.json..."

# Loop over images in images.json
images_count=$(jq '.images | length' images.json)

echo "Found $images_count images in images.json."

# New loop to list the images
for ((i=0; i<images_count; i++)); do
    active="$(jq -r ".images[$i].active" images.json)"
    if [ "$active" == "false" ]; then
        continue
    fi

    filename=$(jq -r ".images[$i].filename" images.json)
    if [ "$filename" != "null" ] && [ -n "$filename" ]; then
        echo "$filename"
    else
        device_codename=$(jq -r ".images[$i].device_codename" images.json)
        grapheneos_version=$(jq -r ".images[$i].grapheneos_version" images.json)
        echo "${device_codename}-install-${grapheneos_version}"
    fi
done

# Existing loop to generate SHA256 sums
for ((i=0; i<images_count; i++)); do
    active="$(jq -r ".images[$i].active" images.json)"
    if [ "$active" == "false" ]; then
        continue
    fi

    filename=$(jq -r ".images[$i].filename" images.json)

    if [ "$filename" != "null" ] && [ -n "$filename" ]; then
        image_filename="$filename"
        sha256sum_filename="${image_filename}.sha256sum"
    else
        device_codename=$(jq -r ".images[$i].device_codename" images.json)
        grapheneos_version=$(jq -r ".images[$i].grapheneos_version" images.json)
        image_filename="imgs/${device_codename}-install-${grapheneos_version}.zip"
        sha256sum_filename="imgs/${device_codename}-install-${grapheneos_version}.zip.sha256sum"
    fi

    echo ""
    echo "Processing $image_filename..."

    if [ ! -f "$image_filename" ]; then
        echo "Error: $image_filename not found. Exiting."
        exit 1
    fi

    if [ -f "$sha256sum_filename" ]; then
        echo "Skipped: $sha256sum_filename already exists."
        continue
    fi

    echo "Generating sha256sum for $image_filename..."
    sha256sum "$image_filename" > "$sha256sum_filename"
    echo "Generated $sha256sum_filename."
done
