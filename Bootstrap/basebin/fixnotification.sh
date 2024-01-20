#!/bin/sh

ls -d /var/containers/Bundle/Application/*/*.app/.jbroot | while read file; do
    bundle=$(dirname "$file")
    if [ -d "$bundle"/SC_Info ]; then
        echo "--$bundle--"
        uicache -u "$bundle"
        uicache --fix-notification -p "$bundle"
    fi
done

sleep 2

ls -d /var/containers/Bundle/Application/*/*.app/.jbroot | while read file; do
    bundle=$(dirname "$file")
    if [ -d "$bundle"/SC_Info ]; then
        echo "--$bundle--"
        uicache --fix-notification -s -p "$bundle"
    fi
done
