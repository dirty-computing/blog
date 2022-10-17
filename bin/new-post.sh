#!/bin/bash

if [ $# != 1 ]; then
    echo "Forneça um (e apenas um) draft para criar" >&2
    exit 1
fi

OUTFILE="$1"

# normalizar OUTFILE
if [ "${OUTFILE}" = "${OUTFILE#_drafts/}" ]; then
    OUTFILE="_drafts/$OUTFILE"
fi

read -p "Qual o título? " TITLE
read -p "Tags? " TAGS

RADIX=`echo ${OUTFILE%.md} | cut -d '/' -f 2`

cat > "$OUTFILE" << EOL
---
layout: post
title: "$TITLE"
author: "Jefferson Quesado"
tags: $TAGS
base-assets: "/assets/${RADIX}/"
---
EOL