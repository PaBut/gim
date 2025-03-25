#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <scene_list.txt> <version>"
    exit 1
fi

scene_list=$1
version=$2

while IFS= read -r scene_name; do
    if [ -n "$scene_name" ]; then
        echo "Processing scene: $scene_name"
        ./reconstruction.sh "$scene_name" "$version"
    fi
done < "$scene_list"