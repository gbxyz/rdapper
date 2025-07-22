#!/bin/sh
# compile all .po files

find locale -name '*.po' | while read po ; do
    echo "$po"
    msgfmt -o "$(dirname "$po")/$(basename "$po" .po).mo" "$po" || exit 1
done
