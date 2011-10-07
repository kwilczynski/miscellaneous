#!/bin/bash

#
# mongodb_save_and_restore.sh
#
# This script allows for run-time save (dump) and restore (load) of a particular
# database (not a "full dump") from one running MongoDB instance into another
# which is either local or remote.  Authentication available using "user name"
# and "password" model available in MongoDB at this point in time.
#

#
# Format is as follows:
#
# Override default options at runtime by preceeding the script with your
# settings.
#
# SRC_HOST='1.2.3.4' SRC_USERNAME='test' /path/to/mongodb_save_and_restore.sh
#
SRC_HOST=${SRC_HOST:-'127.0.0.1'}
SRC_PORT=${SRC_PORT:-'27017'}
SRC_USERNAME=${SRC_USERNAME:-''}
SRC_PASSWORD=${SRC_PASSWORD:-''}
SRC_DATABASE=${SRC_DATABASE:-'database name'}
DST_HOST=${DST_HOST:-'127.0.1.1'}
DST_PORT=${DST_PORT:-'27017'}
DST_USERNAME=${DST_USERNAME:-''}
DST_PASSWORD=${DST_PASSWORD:-''}
DST_DATABASE=${DST_DATABASE:-'database name'}

# This will be the temporary work space ...
WORK_DIRECTORY=${WORK_DIRECTORY:-'/tmp'}

# We delay restoration on a busy systems to minimise I/O wait times etc ...
DELAY_RESTORE=${DELAY_RESTORE:-60}

#
# Location of "mongodump" and "mongorestore" binaries as per what Debian
# package from 10gen (a company that support MongoDB commercially) offers.
#
MONGODUMP_BINARY='/usr/bin/mongodump'
MONGORESTORE_BINARY='/usr/bin/mongorestore'

# We can use "/tmp" here as well in case where "/var/lock" is not accessible ...
LOCK_FILE="/var/lock/$(basename -- "$0").lock"

function notice {
    local __message="$(basename -- "$0") [$$]: $( date -R ) $@"
    echo "$__message"
    logger "$__message"
}

function error {
    local __message="$(basename -- "$0") [$$]: $(date -R) ERROR: $@"
    echo "$__message" >&2
    logger "$__message"
}

function die {
    error "$@"
    exit 1
}

function random_name {
    local __return=$1
    eval $__return="'$(date +"$(basename -- "$0")_%s_${RANDOM}_$$")'"
}

[ -e "/proc/$(cat "$LOCK_FILE" 2> /dev/null)" ] || rm -f "$LOCK_FILE"

notice 'Starting the database save and restore ...'

if (set -o noclobber ; echo $$ > "$LOCK_FILE") &> /dev/null ; then

    random_name SAVE_DIRECTORY

    RESTORE_DIRECTORY="${SAVE_DIRECTORY}/${SRC_DATABASE}"

    [ -d "$WORK_DIRECTORY" ] || mkdir -p "$WORK_DIRECTORY" &> /dev/null

    pushd "$WORK_DIRECTORY" &> /dev/null

    trap 'rm -r -f "$LOCK_FILE" "$SAVE_DIRECTORY"' EXIT

    trap '{
            error "*** Aborting execution ***"
            rm -r -f "$LOCK_FILE" "$SAVE_DIRECTORY"
            exit 1
          }' HUP INT QUIT KILL TERM

    mkdir -p "$SAVE_DIRECTORY" &> /dev/null

    start=$(date +%s)

    notice "Saving the database from: ${SRC_HOST}"

    $MONGODUMP_BINARY --directoryperdb --journal         \
                      --host "${SRC_HOST}"         \
                      --port "${SRC_PORT}"         \
                      --username "${SRC_USERNAME}" \
                      --password "${SRC_PASSWORD}" \
                      --db "${SRC_DATABASE}"       \
                      --out "$SAVE_DIRECTORY" &> /dev/null ||
    {
        die "Unable to save the database dump from: ${SRC_HOST}"
    }

    size=$(du -sh "$SAVE_DIRECTORY" | cut -f 1)

    notice "Successfully saved the database (current size: $size).  Saving took $[$(date +%s) - $start] seconds."

    notice "Sleeping for $DELAY_RESTORE seconds."

    sleep $DELAY_RESTORE

    start=$(date +%s)

    notice "Restoring the database to: ${DST_HOST}"

    $MONGORESTORE_BINARY --directoryperdb --journal --drop       \
                         --host "${DST_HOST}"         \
                         --port "${DST_PORT}"         \
                         --username "${DST_USERNAME}" \
                         --password "${DST_PASSWORD}" \
                         --db "${DST_DATABASE}"       \
                         "$RESTORE_DIRECTORY" &> /dev/null ||
    {
        die "Unable to restore the database to: ${DST_HOST}"
    }

    notice "Successfully restored the database.  Restoration took $[$(date +%s) - $start] seconds."

    [ -d "$SAVE_DIRECTORY" ] && rm -r -f "$SAVE_DIRECTORY"

    popd &> /dev/null

    rm -r -f "$LOCK_FILE"

    trap - INT TERM EXIT

    notice 'Completed the database save and restore.'
else
    die "Unable to create lock file (current owner: "$(cat "$LOCK_FILE" 2> /dev/null)")."
fi

exit 0
