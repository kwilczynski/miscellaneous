#!/bin/bash

#
# This script will restore backup created by rsync rotating
# backup script.  Designed to run as a cron job at @reboot ...
#

RESTORE_SOURCE="/tmp/a/"
RESTORE_DESTINATION="/tmp/b/"

LOCK_FILE="/tmp/${0}.lock"

if [[ ! -e "/proc/$( cat "${LOCK_FILE}" 2> /dev/null )" ]] ; then
    rm -f "${LOCK_FILE}"
fi

if ( set -o noclobber ; echo ${$} > "${LOCK_FILE}" ) &> /dev/null ; then

    trap 'rm -f "${LOCK_FILE}"' INT TERM EXIT

    if [ "$( ls -A "${RESTORE_SOURCE}" )" ] ; then

        mkdir -p "${RESTORE_DESTINATION}" &> /dev/null

        pushd "${RESTORE_SOURCE}" &> /dev/null

        rsync -a -r -q "backup.0/" "${RESTORE_DESTINATION}" &> /dev/null ||
        {
            echo "Unable to restore files from backup successfully ..."
            exit 1
        }

        popd &> /dev/null

    else
        echo "Backup directory is empty. Unable to restore backup ..."
        exit 1
    fi

    rm -f "${LOCK_FILE}"

    trap - INT TERM EXIT
fi

exit 0
