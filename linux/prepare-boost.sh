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

sudoers_message_prefix() {
        local content=$1
        echo -e "$blueColour [ SUDO Hardening ]$endColour $content"
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

    while is_empty "$ALLOWED_USERS"; do
        read -rp "$(ssh_message_prefix "Define the allowed users that are allowed to connect via ssh: ")" ALLOWED_USERS

        if ! is_empty "$ALLOWED_USERS"; then
            read -ra names <<< "$ALLOWED_USERS"

            for name in "${names[@]}"; do
                if ! id -u "$name" 1>/dev/null; then 
                ssh_message_prefix "$redColour The user$yellowColour $name $endColour$redColour does not exists in the system, please try again$endColour"
                    ALLOWED_USERS=''
                    break
                fi
            done
        fi
   
    done

    read -rp "$(ssh_message_prefix "Define the allowed groups that are allowed to connect via ssh (Default <blank>): ")" ALLOWED_GROUPS
    read -rp "$(ssh_message_prefix "Define the denied users that are not allowed to connect via ssh (Default root admin): ")" DENY_USERS

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
        ssh_message_prefix "Remember to move the content of$grayColour .pub$endColour file inside$cyanColour ~/.ssh/authorized_keys$endColour"

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

    rm "$SSH_CONFIGURATION_FILE"

}

sudoers_configuration() {
    local SUDOERS_PATH="/etc/sudoers"

    if file_exists "$SUDOERS_PATH"; then
        sudoers_message_prefix "Appending configuration to handle sudo logs in$cyanColour $SUDOERS_PATH$endColour"

        ! grep -i 'use_pty' "$SUDOERS_PATH" \
            && echo  "Defaults use_pty" >> "$SUDOERS_PATH" 

        sed -i '' '/use_pty/s/.*/&\nDefaults logfile="\/var\/log\/sudo.log"/' /etc/sudoers
    else 
        sudoers_message_prefix "the file$cyanColour $SUDOERS_PATH $endColour does not exists$redColour [FAILED]$endColour"
    fi
}

restrict_access_su_command() {
    local SU_PATH="/etc/pam.d/su"
    local SU_GROUP_NAME='sugroup'

    if file_exists $SU_PATH; then
        sudoers_message_prefix "Creating the group$cyanColour sugroup$endColour to restrict the execution of$cyanColour su$endColour command"
        
        if command_exists "groupadd"; then 
            groupadd $SU_GROUP_NAME
        elif command_exists "addgroup"; then
            addgroup $SU_GROUP_NAME
        else 
            sudoers_message_prefix "Cannot add new group$cyanColour $SU_GROUP_NAME$endColour because the commands$yellowColour grouppadd$endColour and$yellowColour addgroup$endColour are not installed$redColour [FAILED]$endColour"
        fi

        usermod -a -G sugroup "$(id -un)"

        echo -e "auth    required    pam_wheel.so use_uid group=sugroup\n" >> "$SU_PATH"

        sudoers_message_prefix "Creating the group$cyanColour sugroup$endColour to restrict the execution of su command$greenColour [SUCCESS]$endColour"

    else 
        sudoers_message_prefix "the file$cyanColour $SU_PATH $endColour does not exists$redColour [FAILED]$endColour"
    fi
}

linux_main() {
    # Create a working copy to not disturb the original template
    cp -f "$(dirname "$SSH_CONFIGURATION_FILE")/template.conf" "$SSH_CONFIGURATION_FILE" 

    # SSH
    apply_sshd_configuration_file
    allowed_users_and_groups
    generate_ssh_key
    copy_ssh_configuration_file

    #SUDO
    sudoers_configuration
    restrict_access_su_command


}

export -f linux_main