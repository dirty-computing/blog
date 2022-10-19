#!/bin/bash

FILE_NAME="${1#assets/*/}"

# normaliza fim de arquivo para png

if [ "$FILE_NAME" = "${FILE_NAME%.*}" ]; then
    FILE_NAME+=.png
fi

echo "{{ page.base-assets | append: \"$FILE_NAME\" | relative_url }}"