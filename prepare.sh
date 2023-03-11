#!/usr/bin/env bash

CURRENT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

source "$CURRENT_DIR/linux/prepare-boost.sh"

display_banner() {
cat << EOF


    (  ____ \(  ____ \(  ____ \|\     /|(  __  \ \__   __/\__   __/(  ___  )
    | (    \/| (    \/| (    \/| )   ( || (  \  )   ) (      ) (   | (   ) |
    | (__    | (_____ | |      | |   | || |   ) |   | |      | |   | |   | |
    |  __)   (_____  )| |      | |   | || |   | |   | |      | |   | |   | |
    | (            ) || |      | |   | || |   ) |   | |      | |   | |   | |
    | (____/\/\____) || (____/\| (___) || (__/  )___) (___   | |   | (___) |
    (_______/\_______)(_______/(_______)(______/ \_______/   )_(   (_______)


EOF
}

main() {
    display_banner
    linux_main
}

main