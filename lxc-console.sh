#!/bin/bash

#
# lxc-console.sh
#
# This script is just a wrapper for "lxc-console" binary which is by default
# provided as a part of the Linux Containers package (and "liblxc" in general)
# that allows for better work-flow by removing the need to supply --name all
# the time (extremely annoying), plus it will set default escape prefix to be
# a letter "q" resulting in "CTRL + q q" combination and in turn re-claiming
# "CTRL + a" for use in the Bash shell, emacs editor, etc ...
#

# This gives us support for "CTRL + q q" in order to escape from the attached console ...
ESCAPE_PREFIX='q'

# Default location on Debian via the "lxc" package ...
LXC_CONSOLE_BINARY='/usr/bin/lxc-console'

[ -z "$1" ] &&
{
    echo "You must provide name of the container to attach the console to." >&2
    exit 1
}

$LXC_CONSOLE_BINARY --escape $ESCAPE_PREFIX --name "$@"

exit 0
