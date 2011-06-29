#!/bin/bash
#
# written by Osvaldo Santana <osantana@triveos.com>
#         by Arthur Furlan <afurlan@valvim.com>

YUICOMPRESS="yuicompressor-2.4.6.jar"

if [ $# -lt 1 ]; then
    echo "Usage: $0 BASEDIR"
    exit 1
fi

## compare the modified date of two files
is_file_modified() {
    [ $# -lt 2 ] && return 0

    ## check if both files already exist
    [ -f "${1}" ] || return 0
    [ -f "${2}" ] || return 1

    MOD1=$(stat "${1}" | grep ^Modify: | cut -c 9-27)
    MOD2=$(stat "${2}" | grep ^Modify: | cut -c 9-27)

    if [ "$MOD1" \> "$MOD2" ]; then
        return 1
    else
        return 0
    fi
}

## minify all modified files under $BASEDIR
BASEDIR=$(cd $(dirname $1) && echo $PWD)
find "$BASEDIR" -type f | egrep -v '\.min\.' | while read FILE; do

    TYPE=$(echo $FILE | rev | cut -d '.' -f 1 | rev)
    NAME=$(echo $FILE | rev | cut -d '.' -f 2- | rev)

    case "$TYPE" in

        css|js)
            DEST="${NAME}.min.${TYPE}"

            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            echo "Compressing: ${DEST}"
            java -jar "${YUICOMPRESS}" "${FILE}" > "${DEST}"
        ;;

        png)
            DEST="${NAME}-nq8.${TYPE}"

            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            echo "Compressing: ${DEST}"
            pngnq "${FILE}"
        ;;

        xml)
            DEST="${FILE}.gz"

            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            echo "Compressing: ${DEST}"
            gzip -c "${FILE}" > "${DEST}"
        ;;

    esac
done
