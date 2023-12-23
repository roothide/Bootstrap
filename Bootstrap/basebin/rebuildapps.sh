#!/bin/sh

ls /Applications/  | while read app; do
    echo "--$app--";
    
    uicache -p "/Applications/$app"

done

ls -d /var/containers/Bundle/Application/*/*.app/.jbroot | while read file; do
    bundle=$(dirname "$file")
    echo "--$bundle--"

    unlink "$bundle"/.jbroot
    ln -s /  "$bundle"/.jbroot

    uicache -u "$bundle"
    uicache -s -p "$bundle"
done
