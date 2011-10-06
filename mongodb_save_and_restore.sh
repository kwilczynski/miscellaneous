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
#  '<HOST>:<PORT>' '<USER NAME>' '<PASSWORD>' '<DATABASE NAME>'
#
# There are NO COMMAS in-between the fields ...
#
# Note that both host and port HAVE TO be given as: '<HOST>:<PORT>'.
#
DATABASE_SOURCE=('127.0.0.1:27017' 'user name' 'password' 'database name')
DATABASE_DESTINATION=('127.0.1.1:27017' 'user name' 'password' 'database name')

# This will be the temporary work space ...
WORK_DIRECTORY='/tmp'

# We delay restoration on a busy systems to minimise I/O wait times etc ...
DELAY_RESTORE=60

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

    RESTORE_DIRECTORY="${SAVE_DIRECTORY}/${DATABASE_SOURCE[3]}"

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

    notice "Saving the database from: ${DATABASE_SOURCE[0]%%:*}"

    $MONGODUMP_BINARY --directoryperdb --journal         \
                      --host "${DATABASE_SOURCE[0]%%:*}" \
                      --port "${DATABASE_SOURCE[0]##*:}" \
                      --username "${DATABASE_SOURCE[1]}" \
                      --password "${DATABASE_SOURCE[2]}" \
                      --db "${DATABASE_SOURCE[3]}"       \
                      --out "$SAVE_DIRECTORY" &> /dev/null ||
    {
        die "Unable to save the database dump from: ${DATABASE_SOURCE[0]%%:*}"
    }

    size=$(du -sh "$SAVE_DIRECTORY" | cut -f 1)

    notice "Successfully saved the database (current size: $size).  Saving took $[$(date +%s) - $start] seconds."

    notice "Sleeping for $DELAY_RESTORE seconds."

    sleep $DELAY_RESTORE

    start=$(date +%s)

    notice "Restoring the database to: ${DATABASE_DESTINATION[0]%%:*}"

    $MONGORESTORE_BINARY --directoryperdb --journal --drop       \
                         --host "${DATABASE_DESTINATION[0]%%:*}" \
                         --port "${DATABASE_DESTINATION[0]##*:}" \
                         --username "${DATABASE_DESTINATION[1]}" \
                         --password "${DATABASE_DESTINATION[2]}" \
                         --db "${DATABASE_DESTINATION[3]}"       \
                         "$RESTORE_DIRECTORY" &> /dev/null ||
    {
        die "Unable to restore the database to: ${DATABASE_DESTINATION[0]%%:*}"
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
