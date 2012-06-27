#!/bin/bash
#
# written by Arthur Furlan <afurlan@mecasar.com>

if [ $# -lt 3 ]; then
    echo "Usage: $0 BASEDIR PACKAGE FILE1 FILE2 FILE3 ..."
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

## pack all modified files under $BASEDIR in the file $PACKAGE
BASEDIR=$1
PACKAGE=$2
shift 2

## check if there is a modified file, if so package needs to be rebuilt
MODIFIED=0
cd $BASEDIR
for FILE in $*; do

    ## check if the file was modified after $PACKAGE creation
    is_file_modified "$BASEDIR/$FILE" "$BASEDIR/$PACKAGE"
    if [ "$?" = "1" ]; then
        MODIFIED=1
        break
    fi
done

## if there is a modified file, rebuild the $PACKAGE file
if [ "$MODIFIED" = "1" ]; then
    cat $* > $PACKAGE
fi
