#!/bin/bash

# select_secondary_member.sh
#
# Select first available Secondary member in the Replica Sets and show its
# host name and port.
#

function select_secondary_member {
  # We will use indirect-reference hack to return variable from this function.
  __return=$1

  secondary=''

  # Retrieve list of Replica Sets members from local MongoDB instance.
  members=( $(mongo --quiet --eval \
              'rs.isMaster().hosts.forEach(function(x) { print(x) })') )

  if [[ ! $? == 0 ]] ; then
    echo "ERROR: Unable to retrieve list of Replica Sets members from local MongoDB instance." >&2
    return 1
  else
    # Process list of Replica Sets members and look for any Secondary ...
    if [[ ${#members[@]} > 1 ]] ; then
      for member in "${members[@]}" ; do
        # Check if Seconday?  If so then break ...
        case "$(mongo --quiet --host $member --eval 'rs.isMaster().ismaster')" in
          'true')
            # Skip particular member if it is a Primary.
            continue
            ;;
          'false')
            # First secondary wins ...
            secondary=$member
            break
          ;;
          *)
            # Skip irrelevant entries.  Should not be any anyway ...
            continue
          ;;
        esac
      done
    fi

    # Nothing found?  Then abort ...
    if [[ -z "$secondary" ]] ; then
      echo "ERROR: No suitable Secondary found in the Replica Sets." >&2
      return 1
    else
      # Ugly hack to return value from a Bash function ...
      eval $__return="'$secondary'"
    fi
  fi
}

# Details of the Secondary member will be stored here ...
secondary=''

if [[ -z "$(which mongo)" ]] ; then
  echo "ERROR: Unable to locate Mongo Shell binary." >&2
  exit 1
fi

# Return value via indirect-reference hack ...
select_secondary_member seconday

if [[ -n "$secondary" ]] ; then
  echo "Available Replica Sets secondary: ${secondary}"
else
  exit $?
fi

exit 0
