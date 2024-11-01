#!/bin/bash

BASE_URL=https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets

for img in girassol-girl1.png girassol-girl2.png girassol-kisses.png girassol-steampunk.png girassol.png; do
	echo $img
	curl -o $img $BASE_URL/$img
done
