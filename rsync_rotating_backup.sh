#!/bin/bash

#
# rsync_rotating_backup.sh
#
# This script will create a rotaring backup using rsync and store
# up to 5 copies.  We are using --link-dest option for rsync to
# create hard links to previous rotation so we preserve space and
# improve perfomance when making new rotation as only difference
# between them will be stored.  Designed to run as a cron job ...
#

BACKUP_SOURCE=''
BACKUP_DESTINATION=''

LOCK_FILE="/var/lock/$(basename -- "$0").lock"

function die {
    logger "$(basename -- "$0") [$$]: $(date -R) ERROR: $@"
    exit 1
}

[ -e "/proc/$(cat "$LOCK_FILE" 2> /dev/null)" ] || rm -f "$LOCK_FILE"

if (set -o noclobber ; echo $$ > "$LOCK_FILE") &> /dev/null ; then

    trap 'rm -f "$LOCK_FILE"' INT TERM EXIT

    if [ "$(ls -A "$BACKUP_SOURCE")" ] ; then

        mkdir -p "$BACKUP_DESTINATION" &> /dev/null

        pushd "$BACKUP_DESTINATION" &> /dev/null

        mkdir -p backup.{0..5} &> /dev/null

        rm -r -f 'backup.5'

        for i in {5..1} ; do

            mv -f "backup.$[$i - 1]" "backup.${i}" &> /dev/null ||
            {
                die 'Unable to successfully rotate backup ...'
            }
        done

        rsync -a -r -q --delete --link-dest='../backup.1' \
            "$BACKUP_SOURCE" 'backup.0/' &> /dev/null ||
        {
            die 'Unable to make backup files successfully ...'
        }

        popd &> /dev/null
    fi

    rm -f "$LOCK_FILE"

    trap - INT TERM EXIT
fi

exit 0
