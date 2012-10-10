#!/bin/bash
#
# written by Arthur Furlan <afurlan@mecasar.com>
# written by Osvaldo Santana <osantana@triveos.com>

YUICOMPRESSOR="yuicompressor.jar"
GOOGLECLOSURE="googleclosure.jar"
GZIP="1"

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

    ## get the modified date of both files
    MOD1=$(stat "${1}" | grep ^Modify: | cut -c 9-27)
    MOD2=$(stat "${2}" | grep ^Modify: | cut -c 9-27)

    if [ "$MOD1" \> "$MOD2" ]; then
        return 1
    else
        return 0
    fi
}

## check if the minified file really is smaller
is_file_minified() {
    [ $# -lt 2 ] && return 0

    ## get the file size of both files
    SIZ1=$(du -b "${1}")
    SIZ2=$(du -b "${2}")

    if [ "$SIZ1" \> "$SIZ2" ]; then
        return 0
    else
        return 1
    fi
}

## check if the file should be statically gziped
gzip_compressor() {
    [ $# -lt 1 ] && return 0

    FILE="$1"
    DEST="${FILE}.gz"

    ## check if this feature is enabled
    if [ "$GZIP" = "1" ]; then
        gzip -c "${FILE}" > "${DEST}"
        touch "${DEST}" -r "${FILE}"
    fi
}

## minify all modified files under $BASEDIR
BASEDIR=$1
find "$BASEDIR" -type f | egrep -v '\.min\.' | while read FILE; do

    TYPE=$(echo $FILE | rev | cut -d '.' -f 1 | rev)
    NAME=$(echo $FILE | rev | cut -d '.' -f 2- | rev)

    case "$TYPE" in

        js)
            DEST="${NAME}.min.${TYPE}"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            java -jar "${GOOGLECLOSURE}" --js "${FILE}" --compilation_level SIMPLE_OPTIMIZATIONS > "${DEST}"

            ## check if the minified file really is smaller
            is_file_minified "$FILE" "$DEST"
            [ "$?" = "0" ] || cp "$FILE" "$DEST"

            ## check if the file should be also compressed using gzip
            gzip_compressor "$DEST"
        ;;

       css)
            DEST="${NAME}.min.${TYPE}"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            java -jar "${YUICOMPRESSOR}" "${FILE}" > "${DEST}"

            ## check if the minified file really is smaller
            is_file_minified "$FILE" "$DEST"
            [ "$?" = "0" ] || cp "$FILE" "$DEST"

            ## check if the file should be also compressed using gzip
            gzip_compressor "$DEST"
        ;;

        less)
            DEST="${NAME}.min.css"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            lessc "${FILE}" --yui-compress > "${DEST}"

            ## less files cannot use the same rule of copying
            ## the original file over the destination file if
            ## the minified version was bigger than the original
            ## because the less syntax could not be a valid css
            ## syntax

            ## check if the file should be also compressed using gzip
            gzip_compressor "$DEST"
        ;;

        sass|scss)
            DEST="${NAME}.min.css"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            sass --watch "${FILE}:${DEST}"

            ## sass files cannot use the same rule of copying
            ## the original file over the destination file if
            ## the minified version was bigger than the original
            ## because the sass syntax could not be a valid css
            ## syntax

            ## check if the file should be also compressed using gzip
            gzip_compressor "$DEST"
        ;;

        png)
            DEST="${NAME}.min.${TYPE}"
            TEMP="${NAME}-nq8.${TYPE}"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            pngnq "${FILE}"
            mv "${TEMP}" "${DEST}"

            ## check if the minified file really is smaller
            is_file_minified "$FILE" "$DEST"
            [ "$?" = "0" ] || cp "$FILE" "$DEST"

            ## check if the file should be also compressed using gzip
            gzip_compressor "$DEST"
        ;;

        jpg|jpeg)
            DEST="${NAME}.min.${TYPE}"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            cp "${FILE}" "${DEST}"
            jpegoptim "${DEST}"

            ## check if the minified file really is smaller
            is_file_minified "$FILE" "$DEST"
            [ "$?" = "0" ] || cp "$FILE" "$DEST"

            ## check if the file should be also compressed using gzip
            gzip_compressor "$DEST"
        ;;

        gif)
            DEST="${NAME}.min.${TYPE}"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            gifsicle --optimize -i "${FILE}" -o "${DEST}"

            ## check if the minified file really is smaller
            is_file_minified "$FILE" "$DEST"
            [ "$?" = "0" ] || cp "$FILE" "$DEST"

            ## check if the file should be also compressed using gzip
            gzip_compressor "$DEST"
        ;;

        xml)
            DEST="${FILE}.gz"

            ## check if the file needs to be minified
            is_file_modified "$FILE" "$DEST"
            [ "$?" = "1" ] || continue

            ## create the new (and minified) version
            echo "Compressing: ${DEST}"
            gzip -c "${FILE}" > "${DEST}"

            ## gziped files cannot use the same rule of copying
            ## the original file over the destination file if
            ## the minified version was bigger than the original
        ;;

    esac
done
