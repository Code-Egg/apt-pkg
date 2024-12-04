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
input_archs=amd64
build_flag=build
lsapi_version=8.1
set_archs=amd64

check_input
set_paras
set_build_dir
prepare_source
pbuild_packages
echo " ################# End of Result #################"
echo $(date)



