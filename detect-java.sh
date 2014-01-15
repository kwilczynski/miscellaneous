#!/bin/bash

java_binary_link="/usr/bin/java"
java_library="libjvm.so"

library_paths=(
  /jre/lib/amd64/server
  /jre/lib/amd64/client
  /usr/lib
  /lib
)

if [ -z "$java_home" ] || [ ! -d "$java_home" ]; then
  JAVA_HOME=$(dirname $(dirname $(dirname $(readlink -f $java_binary_link))))
  if [ ! -d $java_home ]; then
    JAVA_HOME="/usr/lib/jvm/default-java"
  fi
fi

if ! /sbin/ldconfig -p | /bin/grep $java_library > /dev/null 2>&1 ; then
  for path in ${library_paths[@]}; do
    library_path=$(echo $"${JAVA_HOME}/${path}" | tr -s '/')
    if [ -f "${library_path}/${java_library}" ]; then
      LD_LIBRARY_PATH="${library_path}:${LD_LIBRARY_PATH}"
      break
    fi
  done
fi

export JAVA_HOME LD_LIBRARY_PATH

if [ -d "${JAVA_HOME}\bin" ]; then
    export PATH="${JAVA_HOME}\bin:${PATH}"
fi
