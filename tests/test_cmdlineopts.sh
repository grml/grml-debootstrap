#!/bin/bash


test_cmdlineopts() {
    . ../cmdlineopts.clp
    CMDLINE=
    typeset -a VALUES
    count=0
    i=0

    OLDIFS="$IFS"
    IFS=,
    for CMD in $CMDLINE_OPTS ; do
        PARAM=""
        if [[ $CMD == *: ]] ; then
            PARAM=$RANDOM
        fi
        VALUES[$count]="${CMD%%:*} $PARAM"
        ((count++))
    done
    IFS=$OLDIFS

    while [ "$i" -lt "$count" ] ; do
        CMDLINE+="--${VALUES[$i]} "
        ((i++))
    done

    . ../cmdlineopts.clp $CMDLINE


    i=0
    while [ "$i" -lt "$count" ] ; do
        ENTRY="${VALUES[$i]}"
        VARNAME=${ENTRY% *}
        RESULT=${ENTRY/* /}
        VARNAME='$_opt_'${VARNAME/-/_}
        VALUE="$(eval echo $VARNAME)"
        if [ -z "$RESULT" ] ; then
            assertNotNull "$VARNAME should be not null" "$VALUE"
        else
            assertEquals "$VARNAME" "$RESULT" "$VALUE"
        fi
        ((i++))
    done
}

SHUNIT_PARENT=$0
. /usr/share/shunit2/shunit2
