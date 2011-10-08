#!/bin/bash

#
# rsync_rotating_restore.sh
#
# This script will restore backup created by rsync rotating
# backup script.  Designed to run as a cron job at @reboot ...
#

RESTORE_SOURCE=''
RESTORE_DESTINATION=''

LOCK_FILE="/var/lock/$(basename -- "$0").lock"

function die {
    logger "$(basename -- "$0") [$$]: $(date -R) ERROR: $@"
    exit 1
}

# Remove stale lock file ...
[ -e "/proc/$(cat "$LOCK_FILE" 2> /dev/null)" ] || rm -f "$LOCK_FILE"

if (set -o noclobber ; echo $$ > "$LOCK_FILE") &> /dev/null ; then

    trap 'rm -f "$LOCK_FILE"' INT TERM EXIT

    if [ "$(ls -A "$RESTORE_SOURCE")" ] ; then

        mkdir -p "$RESTORE_DESTINATION" &> /dev/null

        pushd "$RESTORE_SOURCE" &> /dev/null

        rsync -a -r -q 'backup.0/' "$RESTORE_DESTINATION" &> /dev/null ||
        {
            die 'Unable to restore files from backup successfully ...'
        }

        popd &> /dev/null

    else
        die 'Backup directory is empty. Unable to restore backup ...'
    fi

    rm -f "$LOCK_FILE"

    # Restore default signal handling mechanism ...
    trap - INT TERM EXIT
fi

