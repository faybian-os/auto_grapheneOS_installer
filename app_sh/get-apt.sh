#!/bin/bash
# File_Rel_Path: 'app_sh/get-apt.sh'

./app_sh/echo_header.sh --no_leading_whitespace "Installing needed apt packages."
sudo apt install libarchive-tools android-sdk-platform-tools-common openssh-client signify-openbsd jq

