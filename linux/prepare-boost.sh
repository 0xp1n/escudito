#!/usr/bin/env bash

set -euo pipefail

greenColour='\033[0;32m'
redColour='\033[0;31m'
blueColour='\033[0;34m'
yellowColour='\033[1;33m'
purpleColour='\033[0;35m'
cyanColour='\033[0;36m'
grayColour='\033[0;37m'

endColour='\033[0m'

CURRENT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

source "$CURRENT_DIR/../helpers/utils.sh"

linux_main() {
    apply_sshd_configuration_file
}

###
#  [SSH HARDENING] 
# Be careful to define this security rules because once the configuration is applied, you cannot login with root anymore
# Make sure you generated the ssh keys and has a privilege user
###

apply_sshd_configuration_file() {
    local TARGET_DIR="/etc/sshd_config.d/"
    local SSH_CONFIGURATION_FILE="$CURRENT_DIR/sshd_config/hardening-init.conf"    
    declare -i SSH_PORT=0
  
    if directory_exists "/etc/sshd_config.d"; then
        while ! port_in_valid_range $SSH_PORT; do 
            read -rp "$(echo -e "$yellowColour [ SSH Hardening ]$endColour Select a port for OpenSSH service (Default 22) ")" SSH_PORT
             is_empty $SSH_PORT \
                && SSH_PORT=22
        done

        cp "$SSH_CONFIGURATION_FILE" "$TARGET_DIR"
    else
      echo -e "$yellowColour [ SSH Hardening ]$endColour The configuration folder /etc/sshd_config.d does not exists in this system$redColour [FAILED] $endColour"   
    fi
}
