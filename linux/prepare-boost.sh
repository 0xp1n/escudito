#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
SSH_CONFIGURATION_FILE="$CURRENT_DIR/sshd_config/hardening-init.conf"    

source "$CURRENT_DIR/../helpers/utils.sh"

###
#  [SSH HARDENING] 
# Be careful to define this security rules because once the configuration is applied, you cannot login with root anymore
# Make sure you generated the ssh keys and has a privilege user
###

ssh_message_prefix() {
    local content=$1

    echo -e "$yellowColour [ SSH Hardening ]$endColour $content"
}

apply_sshd_configuration_file() {
    declare -i SSH_PORT=0
  
    while ! port_in_valid_range $SSH_PORT; do 
        read -rp "$(ssh_message_prefix "Select a port for OpenSSH service (Default 22): ")" SSH_PORT
            is_empty $SSH_PORT \
                && SSH_PORT=22
    done

    sed "s/<PORT>/$SSH_PORT/" "$SSH_CONFIGURATION_FILE" &>/dev/null
}

allowed_users_and_groups() {
    local ALLOWED_USERS
    ALLOWED_USERS=$(id -un)

    local ALLOWED_GROUPS=''
    local DENY_USERS='root admin'

    read -rp "$(ssh_message_prefix "Define the allowed users that are allowed to connect via ssh (Default $ALLOWED_USERS): ")" ALLOWED_USERS
    read -rp "$(ssh_message_prefix "Define the allowed groups that are allowed to connect via ssh (Default empty): ")" ALLOWED_GROUPS
    read -rp "$(ssh_message_prefix "Define the denied users that are not allowed to connect via ssh (Default $DENY_USERS): ")" DENY_USERS

    sed -i "s/<ALLOW_USERS>/$ALLOWED_USERS/" "$SSH_CONFIGURATION_FILE"
    sed -i "s/<ALLOW_GROUPS>/$ALLOWED_GROUPS/" "$SSH_CONFIGURATION_FILE" 
    sed -i "s/<DENY_USERS>/DenyUsers $DENY_USERS/" "$SSH_CONFIGURATION_FILE"

}

copy_ssh_configuration_file() {
    local TARGET_DIR="/etc/sshd_config.d/"

    if directory_exists $TARGET_DIR; then
        ssh_message_prefix "Copied$cyanColour $SSH_CONFIGURATION_FILE$grayColour to$endColour $cyanColour$TARGET_DIR$endColour $greenColour [SUCCESS]$endColour"

    cp "$SSH_CONFIGURATION_FILE" "$TARGET_DIR"
    else
      echo -e "$yellowColour [ SSH Hardening ]$endColour The configuration folder$cyanColour /etc/sshd_config.d$endColour does not exists in this system$redColour [FAILED]$endColour"   
    fi
}

linux_main() {
    apply_sshd_configuration_file
    allowed_users_and_groups
    copy_ssh_configuration_file
}

export -f linux_main