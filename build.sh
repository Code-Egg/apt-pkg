#!/bin/bash

source ./functions.sh #2>/dev/null

echo " Check if the user is root "
if [ $(id -u) != "0" ]; then
    echo "Error: The user is not root "
    echo "Please run this script as root"
    exit 1
fi

product=$1
version=$2
revision=$3
dists=$4
input_archs=$5
build_flag=$6
push_flag=$7
sync_flag=$8
edge_flag=$9

lsapi_version=8.1

dists=noble
set_archs=amd64

check_input
set_paras

if [ $build_flag == build ]; then
        set_build_dir
        prepare_source
        pbuild_packages
        echo " ################# End of Result #################"
        echo $(date)
fi



