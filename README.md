# Faybian / Auto GrapheneOS Installer

A set of scripts to automate installation of GrapheneOS to hardware devices.

Full GrapheneOS CLI Install Documentation: https://grapheneos.org/install/cli

## How to Use

1. Clone or download this repository.  
   Example:  
   git clone ....  
   cd Auto-GrapheneOS-Installer

3. Run the main install script:
   • ./install_grapheneOS.sh  
     - This will download required components, prompt to download images, and guide you through unlocking the bootloader and flashing the firmware.

4. Verify checksums (optional, recommended):
   • ./verify_images_sha256sums.sh  
     - Checks integrity of downloaded image files using their .sha256sum files.

5. Generate checksums (developer use):
   • ./gen_images_sha256sums.sh  
     - Creates new .sha256sum files for each image if they are missing.

6. General notes:
   • You may pass device and version arguments to scripts, for example:  
     ./install_grapheneOS.sh --device_codename tangorpro --grapheneos_version 2025011500  
   • If no arguments are given, the scripts reference images.json for all available images.

7. Troubleshooting:
   • Ensure that your device is in fastboot mode (bootloader mode) before continuing with the installation steps.  
   • Confirm that the required dependencies (libarchive-tools, android-sdk-platform-tools, openssh-client, signify-openbsd, jq) are installed.  

For more details on GrapheneOS itself, visit the official documentation at:  
https://grapheneos.org

