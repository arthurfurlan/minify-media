#!/bin/bash
#
# written by Osvaldo Santana <osantana@triveos.com>
#         by Arthur Furlan <afurlan@valvim.com>

YUICOMPRESS="yuicompressor-2.4.6.jar"

if [ $# -lt 1 ]; then
    echo "Usage: $0 BASEDIR"
    exit 1
fi

BASEDIR=$(cd $(dirname $1) && echo $PWD)
find "$BASEDIR" -type f | egrep -v '\.min\.' | while read FILE; do

    TYPE=$(echo $FILE | rev | cut -d '.' -f 1 | rev)
    NAME=$(echo $FILE | rev | cut -d '.' -f 2- | rev)

    case "$TYPE" in

        css|js)
            DEST="${NAME}.min.${TYPE}"

            echo "Compressing: ${DEST}"
            java -jar "${YUICOMPRESS}" "${FILE}" > "${DEST}"
        ;;

        xml)
            DEST="${FILE}.gz"

            echo "Compressing: ${DEST}"
            gzip -c "${FILE}" > "${DEST}"
        ;;

    esac
done
