#!/usr/bin/env bash

greenColour='\033[0;32m'
redColour='\033[0;31m'
blueColour='\033[0;34m'
yellowColour='\033[1;33m'
purpleColour='\033[0;35m'
cyanColour='\033[0;36m'
grayColour='\033[0;37m'

endColour='\033[0m'

directory_exists() {
    local directory=$1

    [[ -d "$directory" ]]
}

file_exists() {
    local file=$1

    [[ -f "$file" ]]
  
}

port_in_valid_range() {
    declare -i PORT=$1

    [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]
 
}

is_empty() {
    local var=$1

    [[ -z $var ]]
}


export -f directory_exists file_exists is_empty