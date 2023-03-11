#!/usr/bin/env bash

directory_exists() {
    local directory=$1

    if [ -d "$directory" ]; then
        return 1;
    else
        return 0;
    fi
}

file_exists() {
    local file=$1

    if [ -f "$file" ]; then
        return 1;
    else
        return 0;
    fi
}

port_in_valid_range() {
    declare -i PORT=$1

    if [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; then
        return 1;
    else 
        return 0;
    fi

}

export -f directory_exists
export -f file_exists