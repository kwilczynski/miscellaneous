RUBY_GEM_BINARY=$(which gem)

GEM_BINARIES_PATH=$($RUBY_GEM_BINARY environment |    \
                    grep -A2 -i PATHS | grep -v GEM | \
                    awk '{ print $2 }' |              \
                    while read path ; do echo -ne ":${path}/bin" ; done)

PATH="${PATH}${GEM_BINARIES_PATH}"
