# Faybian / Auto GrapheneOS Installer

A set of scripts to automate installation of GrapheneOS to hardware devices.

Full GrapheneOS CLI Install Documentation: https://grapheneos.org/install/cli

## How to Use

1. Clone or download this repository.  
   Example:  
   ```
   git clone git@github.com:alfe-ai/faybian-auto_grapheneOS_installer.git
   cd faybian-auto_grapheneOS_installer
   ```
   
2. Edit the `images.json` file to have your `device_codename` and `grapheneos_version` specified, in an entry with `"active": true`.

3. Run the main install script:  
   `./install_grapheneOS.sh`
   This downloads required components, prompts you to download images, and guides you through unlocking the bootloader and flashing the firmware.

4. Verify checksums (optional, recommended):  
   `./verify_images_sha256sums.sh`
   Checks integrity of downloaded image files using their `.sha256sum` files and SSH signatures.

5. Generate checksums (developer use):  
   `./gen_images_sha256sums.sh`
   Creates new `.sha256sum` files for each image if they are missing.

6. General notes:  
   You may pass device and version arguments to scripts, for example:  
   `./install_grapheneOS.sh --device_codename tangorpro --grapheneos_version 2025011500`
   If no arguments are given, the scripts reference images.json for all available images.

7. Troubleshooting:  
   Ensure that your device is in fastboot (bootloader) mode before continuing.  
   Confirm that dependencies like `libarchive-tools`, `android-sdk-platform-tools`, `openssh-client`, `signify-openbsd`, `jq`, and `curl` are installed.

For more details on GrapheneOS itself, visit:  
https://grapheneos.org
