#!/bin/bash

normaliza_draft() {
	local DRAFT="$1"
	if [ "${DRAFT%/*}" = "$DRAFT" ]; then
		DRAFT="_drafts/$DRAFT"
		if [ "${DRAFT##*.}" = "$DRAFT" ]; then
			DRAFT+=.md
		fi
	elif [ "${DRAFT%/*}" != "_drafts" ]; then
		echo "Deu ruim, não começa com '_drafts' ou tem mais de uma barra" >&2
		exit 1
	fi
	echo "$DRAFT"
}

if [ $# != 1 ]; then
	echo "Forneça um (e apenas um) draft para publicar" >&2
	exit 1
fi

DRAFT="`normaliza_draft "$1"`"

if [ ! -f "$DRAFT" ]; then
	echo "Não existe '$DRAFT'" >&2
	exit 1
fi

get-today() {
	local MAC=false
	case `uname` in
		[Dd]arwin)
			MAC=true
			;;
	esac
	if [ $MAC ]; then
		date -I
	else
		date --iso
	fi
}

git add "$DRAFT"

POST="_posts/`get-today`-${DRAFT#_drafts/}"

git mv -v "$DRAFT" "$POST"
