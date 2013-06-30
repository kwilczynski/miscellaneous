random_file_name() {
    local __return=$1
    eval $__return="'$(date +"$(basename -- "$0")_%s_${RANDOM}_$$")'"
}

random_file_name FILE_NAME
echo $FILE_NAME
