#!/bin/bash

#
# This script will restore backup created by rsync rotating
# backup script.  Designed to run as a cron job at @reboot ...
#

RESTORE_SOURCE=""
RESTORE_DESTINATION=""

LOCK_FILE="/tmp/$0.lock"

function die {
    logger -i -t "$( basename "${0}" )" "$@"
    exit 1
}

if [[ ! -e "/proc/$( cat "${LOCK_FILE}" 2> /dev/null )" ]] ; then
    rm -f "${LOCK_FILE}"
fi

if ( set -o noclobber ; echo $$ > "${LOCK_FILE}" ) &> /dev/null ; then

    trap 'rm -f "${LOCK_FILE}"' INT TERM EXIT

    if [ "$( ls -A "${RESTORE_SOURCE}" )" ] ; then

        mkdir -p "${RESTORE_DESTINATION}" &> /dev/null

        pushd "${RESTORE_SOURCE}" &> /dev/null

        rsync -a -r -q "backup.0/" "${RESTORE_DESTINATION}" &> /dev/null ||
        {
            die "Unable to restore files from backup successfully ..."
        }

        popd &> /dev/null

    else
        die "Backup directory is empty. Unable to restore backup ..."
    fi

    rm -f "${LOCK_FILE}"

    trap - INT TERM EXIT
fi

exit 0
