#!/bin/bash

# Load environment variables if .env exists
if [ -f .env ]; then
    source ./.env
fi

./app_sh/args_graphene.sh

./app_sh/get-apt.sh

echo ""
echo ""
echo "------"
echo "Obtaining platform-tools and (GrapheneOS PGP Pubkey) allowed_signers/signature"
echo "------"
echo "Obtaining platform-tools..."

platform_tools_filename="platform-tools_r35.0.2-linux.zip"
sha256sum_filename="imgs/platform-tools_r35.0.2-linux.zip.sha256sum"

if [ ! -f "$sha256sum_filename" ]; then
  echo "Error: $sha256sum_filename not found. Please ensure it exists with the correct checksum."
  exit 1
fi

expected_checksum="$(awk '{print $1}' "$sha256sum_filename")"

if [ -f "$platform_tools_filename" ]; then
  echo "platform-tools zip already exists, verifying SHA256..."
  existing_checksum="$(sha256sum "$platform_tools_filename" | awk '{ print $1 }')"
  if [ "$existing_checksum" = "$expected_checksum" ]; then
    echo "Existing zip checksum verified. Skipping re-download."
  else
    echo "Checksum mismatch on existing file. Removing and re-downloading..."
    rm -f "$platform_tools_filename"
    curl -O "https://dl.google.com/android/repository/$platform_tools_filename"
  fi
else
  curl -O "https://dl.google.com/android/repository/$platform_tools_filename"
fi

sleep 1

actual_checksum="$(sha256sum "$platform_tools_filename" | awk '{ print $1 }')"
if [ "$actual_checksum" != "$expected_checksum" ]; then
  echo -e "\e[31m❌❌❌ CHECKSUM VERIFICATION FAILED! EXITING SCRIPT. ❌❌❌\e[0m"
  echo "Expected checksum: $expected_checksum"
  echo "Actual checksum:   $actual_checksum"
  exit 1
fi

echo ""
echo "sha256sum VERIFICATION PASSED for '$platform_tools_filename'"

echo ""
rm -rf platform-tools
bsdtar xvf "$platform_tools_filename"

echo ""
echo "Extraction to 'platform-tools' complete."

# Function to download a file if necessary and verify with associated .sha256sum
download_and_verify() {
  local file_url="$1"
  local file_name="$2"
  local sha_file="imgs/${file_name}.sha256sum"

  if [ ! -f "$sha_file" ]; then
    echo "Error: $sha_file not found. Please ensure it exists with the correct checksum."
    exit 1
  fi

  local expected_sum
  expected_sum="$(awk '{ print $1 }' "$sha_file")"

  if [ -f "$file_name" ]; then
    echo ""
    echo "$file_name already exists, verifying SHA256..."
    local existing_sum
    existing_sum="$(sha256sum "$file_name" | awk '{ print $1 }')"
    if [ "$existing_sum" = "$expected_sum" ]; then
      echo "Existing $file_name checksum verified, skipping re-download."
    else
      echo "Checksum mismatch for $file_name, removing and re-downloading..."
      rm -f "$file_name"
      curl -O "$file_url"
    fi
  else
    echo ""
    echo "$file_name not found, downloading..."
    curl -O "$file_url"
  fi

  local actual_sum
  actual_sum="$(sha256sum "$file_name" | awk '{ print $1 }')"
  if [ "$actual_sum" != "$expected_sum" ]; then
    echo -e "\e[31m❌❌❌ CHECKSUM VERIFICATION FAILED for $file_name! EXITING SCRIPT. ❌❌❌\e[0m"
    echo "Expected checksum: $expected_sum"
    echo "Actual checksum:   $actual_sum"
    exit 1
  fi
  echo "sha256sum VERIFICATION PASSED for $file_name"
}

echo ""
echo "Obtaining allowed_signers, allowed_signers.sig, factory.pub..."

download_and_verify "https://releases.grapheneos.org/allowed_signers" "allowed_signers"
download_and_verify "https://releases.grapheneos.org/allowed_signers.sig" "allowed_signers.sig"
download_and_verify "https://releases.grapheneos.org/factory.pub" "factory.pub"

echo ""
echo "Verifying allowed_signers pubkey / allowed_signers.sig"
echo "Executing 'signify-openbsd -V -m allowed_signers -x allowed_signers.sig -p factory.pub'"

expected_output="Signature Verified"
output=$(signify-openbsd -V -m allowed_signers -x allowed_signers.sig -p factory.pub 2>&1)

if [ "$output" != "$expected_output" ]; then
  echo -e "\e[31m❌❌❌ SIGNATURE VERIFICATION FAILED! EXITING SCRIPT. ❌❌❌\e[0m"
  echo "Signify output: $output"
  exit 1
fi

echo "$output"

# Initialize arrays
device_codenames=()
device_brands=()
device_model_names=()
grapheneos_versions=()

if [[ -n "$DEVICE_CODENAME" && -n "$GRAPHENEOS_VERSION" ]]; then
    # Only process the specified image
    if [ ! -f images.json ]; then
      echo "images.json not found in the current directory. Exiting."
      exit 1
    fi
    image_index=$(jq ".images | map(.device_codename == \"$DEVICE_CODENAME\" and .grapheneos_version == \"$GRAPHENEOS_VERSION\") | index(true)" images.json)
    if [[ "$image_index" == "null" ]]; then
        echo "Error: Specified device_codename and grapheneos_version not found in images.json"
        exit 1
    fi

    images_count=1
    device_codenames+=("$DEVICE_CODENAME")
    grapheneos_versions+=("$GRAPHENEOS_VERSION")
    device_brands+=("$(jq -r ".images[$image_index].device_brand" images.json)")
    device_model_names+=("$(jq -r ".images[$image_index].device_model_name" images.json)")
else
    if [[ -z "$DEVICE_CODENAME" && -z "$GRAPHENEOS_VERSION" ]]; then
        echo ""
        echo "Reading image information from images.json..."

        if [ ! -f images.json ]; then
          echo "images.json not found in the current directory. Exiting."
          exit 1
        fi
        releases_url_root=$(jq -r '.releases_url_root' images.json)
        images_count=$(jq '.images | length' images.json)

        for ((i=0; i<$images_count; i++)); do
            dc="$(jq -r ".images[$i].device_codename" images.json)"
            db="$(jq -r ".images[$i].device_brand" images.json)"
            dm="$(jq -r ".images[$i].device_model_name" images.json)"
            gv="$(jq -r ".images[$i].grapheneos_version" images.json)"

            if [[ "$dc" == "null" || "$gv" == "null" ]]; then
                continue
            fi

            device_codenames+=("$dc")
            device_brands+=("$db")
            device_model_names+=("$dm")
            grapheneos_versions+=("$gv")
        done
    else
        echo "Error: Both device_codename and grapheneos_version must be specified together."
        exit 1
    fi
fi

echo ""
echo ""
echo "------"
echo "Downloading GrapheneOS Image(s)..."
if [ ${#device_codenames[@]} -eq 1 ]; then
    echo "Device Codename...: ${device_codenames[0]}"
    echo "GrapheneOS Version: ${grapheneos_versions[0]}"
fi
echo "------"

read -p "Do you want to proceed to download GrapheneOS images? [Y/n] " response
case $response in
    [nN])
        echo ""
        echo ""
        echo "User specified to exit script instead of downloading GrapheneOS images."
        echo "Script cancelled. Exiting."
        exit 1
        ;;
    *)
        echo ""
        echo ""
        echo "Continuing to download GrapheneOS Images..."
        ;;
esac

echo "Checking for 'imgs' directory and creating it if it doesn't exist..."
mkdir -p imgs

releases_url_root=$(jq -r '.releases_url_root' images.json)

echo ""
echo "Found ${#device_codenames[@]} image(s) to download."

for ((i=0; i<${#device_codenames[@]}; i++)); do
    echo ""
    echo "---"
    echo ""

    device_codename="${device_codenames[$i]}"
    device_brand="${device_brands[$i]}"
    device_model_name="${device_model_names[$i]}"
    grapheneos_version="${grapheneos_versions[$i]}"

    echo "Verifying if image exists and checksum is valid..."
    verification_output=$(./verify_images_sha256sums.sh "$device_codename" "$grapheneos_version" 2>&1)
    if echo "$verification_output" | grep -q "All image checksums and signatures verified successfully."; then
        echo "$verification_output"
        echo "Image for $device_codename $grapheneos_version is verified. Skipping download."
        continue
    else
        echo "$verification_output"
        echo "Image missing or verification failed. Proceeding to download."
    fi

    echo ""
    echo "Download image for:"
    echo "Device: $device_codename ($device_brand $device_model_name)"
    echo "GrapheneOS Version: $grapheneos_version"

    image_filename="imgs/$device_codename-install-$grapheneos_version.zip"
    image_sig_filename="$image_filename.sig"

    # Download .sig first
    curl -o "$image_sig_filename" "$releases_url_root$device_codename-install-$grapheneos_version.zip.sig"

    # Prompt user to confirm .zip download
    read -p "Do you want to download $device_codename-install-$grapheneos_version.zip? [Y/n] " zip_confirm
    case $zip_confirm in
        [nN])
            echo ""
            echo "Skipping download of $device_codename-install-$grapheneos_version.zip."
            continue
            ;;
        *)
            echo ""
            echo "Downloading $device_codename-install-$grapheneos_version.zip..."
            ;;
    esac

    curl -o "$image_filename" "$releases_url_root$device_codename-install-$grapheneos_version.zip"
done

echo ""
echo ""
echo "------"
echo "git status"
echo "------"
git status

echo ""
echo ""
echo "------"
echo "Checking fastboot and stopping fwupd.service"
echo "------"
export PATH="$PWD/platform-tools:$PATH"
fastboot --version

apt-cache policy fwupd
sudo systemctl --no-pager status fwupd.service

echo ""
echo ""
echo "------"
echo "STOPPING fwupd.service"
echo "------"
sudo systemctl stop fwupd.service
sudo systemctl --no-pager status fwupd.service

echo ""
echo ""
echo "------"
echo "Enabling OEM unlocking"
echo "------"
echo "OEM unlocking needs to be enabled from within the operating system."
echo ""
echo "Enable the developer options menu by going to Settings > About phone/tablet and repeatedly pressing the Build number menu entry until developer mode is enabled."
echo ""
echo "Next, go to Settings > System > Developer options and toggle on the OEM unlocking setting. On device model variants (SKUs) which support being sold as locked devices by carriers, enabling OEM unlocking requires internet access so that the stock OS can check if the device was sold as locked by a carrier."
echo ""
echo "For the Pixel 6a, OEM unlocking won't work with the version of the stock OS from the factory. You need to update it to the June 2022 release or later via an over-the-air update. After you've updated it you'll also need to factory reset the device to fix OEM unlocking."
echo ""

echo "------"
echo "BOOT INTO DEVICE BOOTLOADER FASTBOOT MODE, THEN CONNECT YOUR DEVICE"
echo "------"

echo "To boot your device into the bootloader interface, follow these steps:"
echo "1. Power off your device completely."
echo "2. Press and hold the volume down button."
echo "3. While holding the volume down button, turn on your device by either:"
echo "   - Pressing the power button, or"
echo "   - Plugging the device into a power source."
echo "4. Continue holding the volume down button until you see a red warning triangle and the words 'Fastboot Mode' on the screen."
echo ""
echo "Important Notes:"
echo "- Do not release the volume down button until you see 'Fastboot Mode'."
echo "- Once in Fastboot Mode, do not press the power button to activate the 'Start' menu item."
echo "- Your device must remain in Fastboot Mode for the fastboot command to connect successfully."
echo ""

echo ""
echo "git status for reference:"
git status

echo "Once your device is in Fastboot Mode, please enter Y to continue."
read -p "Do you want to proceed? [y/N] " response

case $response in
    [yY])
        echo "Proceeding..."
        echo ""
        echo ""
        echo "------"
        echo "Unlocking the bootloader"
        echo "------"
        echo "Unlock the bootloader to allow flashing the OS and firmware"
        fastboot flashing unlock

        echo ""
        echo "Bootloader unlocking step complete."
        echo ""

        # Prompt to continue to flashing
        read -p "Do you want to flash the GrapheneOS image(s) now? [y/N] " flash_confirm
        case $flash_confirm in
            [yY])
                echo ""
                echo "Proceeding to flash each verified GrapheneOS image..."

                for ((i=0; i<${#device_codenames[@]}; i++)); do
                    dc="${device_codenames[$i]}"
                    gv="${grapheneos_versions[$i]}"
                    zip_path="imgs/${dc}-install-${gv}.zip"

                    if [ -f "$zip_path" ]; then
                        # Determine extraction directory (remove extra subdirectory)
                        extraction_dir="${EXTRACTED_IMAGES_DIR:-${dc}-install-${gv}}"

                        echo "Extracting factory images from $zip_path to $extraction_dir..."
                        rm -rf "$extraction_dir"
                        mkdir -p "$extraction_dir"
                        bsdtar xvf "$zip_path" -C "$extraction_dir" --strip-components 1

                        echo "Moving into extracted directory and running flash-all script..."
                        if [ -d "$extraction_dir" ]; then
                            pushd "$extraction_dir" >/dev/null 2>&1

                            if [ -f flash-all.sh ]; then
                                bash flash-all.sh
                            else
                                echo "No flash-all.sh found. Skipping automated flash."
                            fi

                            popd >/dev/null 2>&1
                        else
                            echo "Extraction directory not found. Skipping automated flash."
                        fi

                        echo "Flash completed for $zip_path"
                        echo ""
                    else
                        echo "Cannot find $zip_path. Skipping."
                    fi
                done

                echo ""
                echo "All specified images have been flashed."
                echo "Verified Boot Key Hashes:"
                cat boot_key_hashes.txt
                echo ""
                read -p "Would you like to re-lock the bootloader now? (Recommended after verifying a successful boot) [y/N] " lock_confirm
                case $lock_confirm in
                    [yY])
                        echo "Locking the bootloader..."
                        fastboot flashing lock
                        echo "Bootloader has been locked."
                        ;;
                    *)
                        echo "Skipping bootloader re-lock. You may lock it later if needed."
                        ;;
                esac
                ;;
            *)
                echo "Skipping flashing step."
                ;;
        esac
        ;;
    *)
        echo ""
        echo ""
        echo "Script cancelled. Exiting."
        exit 1
        ;;
esac

