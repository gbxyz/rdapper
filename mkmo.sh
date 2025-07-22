#!/bin/sh
# compile all .po files

find locale -name '*.po' | while read po ; do
    msgfmt -o "$(dirname "$po")/$(basename "$po" .po).mo" "$po"
done
