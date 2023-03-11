#!/usr/bin/env bash

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