#!/bin/bash

#
# mongodb-connect.sh
#
# This script is mainly a wrapper around mongo command which is the so-called
# MongoDB Shell (an interactive command line interface) that allows anyone
# quickly connect to a database instance that does not listen on ANY but
# rather binds to a specific IP and/or port on a particular system ...
#

NETSTAT_BINARY='/bin/netstat'
MONGO_BINARY='/usr/bin/mongo'

# Attempt to determine host and port on which MongoDB instance listens ...
result=$(netstat -n -l -t 2> /dev/null | \
         grep -i '^tcp' |                \
         awk '{ print $4 }' |            \
         grep ':27017' |                 \
         grep -v '^127\.')

# Abort is no results are present.  Perhaps MongoDB is not running?
[ -z "$result" ] && exit 1

# Get the host and port number ...
host="${result%%:*}"
port="${result##*:}"

# Start the mongo shell and pass any additional command line arguments to it ...
${MONGO_BINARY} --host "$host" --port "$port" "$@"
