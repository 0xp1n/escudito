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

    sed -i '' -e "s/<PORT>/$SSH_PORT/" "$SSH_CONFIGURATION_FILE"
}

allowed_users_and_groups() {
    local ALLOWED_USERS=''
    local ALLOWED_GROUPS=''
    local DENY_USERS=''

    read -rp "$(ssh_message_prefix "Define the allowed users that are allowed to connect via ssh (Default $ALLOWED_USERS): ")" ALLOWED_USERS
    read -rp "$(ssh_message_prefix "Define the allowed groups that are allowed to connect via ssh (Default empty): ")" ALLOWED_GROUPS
    read -rp "$(ssh_message_prefix "Define the denied users that are not allowed to connect via ssh (Default $DENY_USERS): ")" DENY_USERS

    is_empty "$ALLOWED_USERS" && ALLOWED_USERS=$(id -un)
    is_empty "$DENY_USERS" && DENY_USERS='root admin'

    sed -i '' -e "s/<ALLOW_USERS>/$ALLOWED_USERS/" "$SSH_CONFIGURATION_FILE"
    sed -i '' -e "s/<ALLOW_GROUPS>/$ALLOWED_GROUPS/" "$SSH_CONFIGURATION_FILE"
    sed -i '' -e "s/<DENY_USERS>/$DENY_USERS/" "$SSH_CONFIGURATION_FILE"
}

generate_ssh_key() {
    local IDENTITY=''

    if command_exists "ssh-keygen"; then
        while is_empty "$IDENTITY"; do
            read -rp "$(ssh_message_prefix "Define an identity (phone,email..) value to generate the ssh key"): " IDENTITY
        done

        ssh_message_prefix "Generating key pair to connect via ssh..."
        ssh_message_prefix "$cyanColour Remember to move the content of$endColour $grayColour .pub file inside$endColour $cyanColour~/.ssh/authorized_keys$endColour"

        ssh-keygen -t ed25519 -C "$IDENTITY"
        eval "$(ssh-agent -s)"
    else 
        echo -e "$yellowColour [ SSH Hardening ]$endColour The command ssh-keygen does not exists, cannot create the ssh keys $redColour [FAILED]$endColour"   
    fi

}

copy_ssh_configuration_file() {
    local TARGET_DIR="/etc/sshd_config.d/"

    if directory_exists $TARGET_DIR; then
        ssh_message_prefix "Copied$cyanColour $SSH_CONFIGURATION_FILE$grayColour to$endColour $cyanColour$TARGET_DIR$endColour $greenColour [SUCCESS]$endColour"

    cp -f "$SSH_CONFIGURATION_FILE" "$TARGET_DIR"

    else
      echo -e "$yellowColour [ SSH Hardening ]$endColour The configuration folder$cyanColour /etc/sshd_config.d$endColour does not exists in this system$redColour [FAILED]$endColour"   
    fi

    #rm "$SSH_CONFIGURATION_FILE"

}

linux_main() {
    # Create a working copy to not disturb the original template
    cp -f "$(dirname "$SSH_CONFIGURATION_FILE")/template.conf" "$SSH_CONFIGURATION_FILE" 

    apply_sshd_configuration_file
    allowed_users_and_groups
    generate_ssh_key
    copy_ssh_configuration_file
}

export -f linux_main