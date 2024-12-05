#!/bin/bash
#set -x
#set -v

#source ~/.bashrc

check_input(){

  echo " ###########   Check_input  ############# "
  echo " Product name is $product "
  echo " Version number is $version "
  echo " Build revision is $revision "
  echo " Required archs are $archs "
  echo " Required dists are $dists "

  if [ $build_flag == build ] ; then
    echo " The packages will be built "
  else
    echo " The packages will NOT be built "
  fi
}

set_paras(){

  PHP_EXTENSION=$(echo "${product}" | sed 's/^[^-]*-//g')
  if [[ "${PHP_EXTENSION}" =~ 'lsphp' ]]; then
    PHP_EXTENSION=''
  fi
  PHP_VERSION_NUMBER=$(echo "${product}" | sed 's/[^0-9]*//g')
  if [[ "$product" =~ 'lsphp' ]] && [[ "${PHP_EXTENSION}" != '' ]] && ! [[ "${PHP_EXTENSION}" =~ 'lsphp' ]] ; then
    if [[ "${PHP_VERSION_NUMBER}" -lt '56' ]]; then
      echo "PHP extensions are just for 5.6.0+"
      exit 1
    fi
    PRODUCT_DIR=/root/apt-pkg/build/"${PHP_EXTENSION}"
    BUILD_DIR=$PRODUCT_DIR/"lsphp${PHP_VERSION_NUMBER}-$version-$revision"
  else
    PRODUCT_DIR=/root/apt-pkg/build/$product
    BUILD_DIR=$PRODUCT_DIR/"$version-$revision"
  fi
  BUILD_RESULT_DIR=$BUILD_DIR/build-result
}

set_build_dir(){

  if [ ! -d "$BUILD_DIR" ]; then
    mkdir -p $BUILD_DIR
    mkdir -p $BUILD_DIR/build-result
  else
    echo " find build directory exists "
    clear_or_not=n
    read -p "do you want to clear it before continuing? y/n:  " -t 15 clear_or_not
    if [ x$clear_or_not == xy ]; then
      echo " now clean the build directory "
      rm -rf $BUILD_DIR/*
      echo " build directory cleared "
    else
      echo " the build directory will not be completely cleared "
      echo " the existing build-result folder will be kept "
      echo " only related files will be overwritten "
      echo " but the source will be downloaded again "

      cd $BUILD_DIR/
      rm -rf `ls $BUILD_DIR | grep -v build-result`
    fi
  fi

  for dist in $dists; do
    mkdir -p $BUILD_DIR/build-result/$dist
  done
}


prepare_source(){

  cd $BUILD_DIR

  case "$product" in
  lsphp83)
    source_url="http://us2.php.net/distributions/php-$version.tar.gz"
    wget $source_url
    tar xzf php-$version.tar.gz

    source_folder_name=php8.3-$version
    mv php-$version $source_folder_name

    SOURCE_DIR=$BUILD_DIR/$source_folder_name
    source_url=https://www.litespeedtech.com/packages/lsapi/php-litespeed-${lsapi_version}.tgz
    wget ${source_url}
    tar -xzf php-litespeed-${lsapi_version}.tgz
    cp -af litespeed-${lsapi_version}/*.c litespeed-${lsapi_version}/*.h  ${SOURCE_DIR}/sapi/litespeed/

    # add patches folder to the source
    cp -a ${PRODUCT_DIR}/patches ${SOURCE_DIR}/
    ls -la $SOURCE_DIR/patches

    # apply patches only once and then remove patches folder
    cd $SOURCE_DIR
    echo `pwd`
    echo "now applying the patches"
    quilt push -a --trace
    rm -rf patches .pc

    cd ..
    #prepare the patched source as orig.tar.xz file
    tar -cJf php8.3_${version}.orig.tar.xz ${source_folder_name}
    ;;
  *)
    echo "Currently this product is not supported"
    ;;
  esac
  echo " source folder name is $source_folder_name "
}

pbuild_packages(){

  echo " now building packages "

  cd $SOURCE_DIR

  for arch in `echo $archs`; do
    for dist in `echo $dists`; do
      TAIL_EDGE=''
      if [ -d ${SOURCE_DIR}/debian ] ; then
        rm -rf ${SOURCE_DIR}/debian
      fi
      cp -a ${PRODUCT_DIR}${TAIL_EDGE}/debian $SOURCE_DIR/

      #if [[ "${product}" =~ 'lsphp' ]] && [[ "${PHP_EXTENSION}" != '' ]]; then
      #  PHP_VERSION_DOT="${PHP_VERSION_NUMBER:0:1}.${PHP_VERSION_NUMBER:1:1}"
      #  sed -i -e "s/PHP_VERSION       := 72/PHP_VERSION       := ${PHP_VERSION_NUMBER}/g" "${SOURCE_DIR}/debian/rules"
      #  sed -i -e "s/PHP_DOT_VERSION   := 7.2/PHP_DOT_VERSION   := ${PHP_VERSION_DOT}/g" "${SOURCE_DIR}/debian/rules"
      #  PHP_VERSION_DATE='20230831'
      #  sed -i -e "s/PHP_DATE          := 20170718/PHP_DATE          := ${PHP_VERSION_DATE}/g" ${SOURCE_DIR}/debian/rules
      #  sed -i -e "s/lsphp72/lsphp${PHP_VERSION_NUMBER}/g" ${SOURCE_DIR}/debian/control
      #fi

      echo " copy changelog template to debian folder "
      cp -af ${PRODUCT_DIR}${TAIL_EDGE}/debian/changelog $SOURCE_DIR/debian/changelog
      echo " now substitute variables in changelog "
      sed -i -e "s/#VERSION#/${version}/g" $SOURCE_DIR/debian/changelog
      sed -i -e "s/#BUILD_REVISION#/${revision}/g" $SOURCE_DIR/debian/changelog
      sed -i -e "s/#DIST#/${dist}/g" $SOURCE_DIR/debian/changelog
      sed -i -e "s/#DATE#/`date +"%a, %d %b %Y %T"`/g" $SOURCE_DIR/debian/changelog
      sed -i -e "s/#PHP_VERSION#/${PHP_VERSION_NUMBER}/g" $SOURCE_DIR/debian/changelog

      echo " changelog preparation done "

      export DISTRO_TEST=${distro}

      DIST=${dist} ARCH=${arch} pbuilder --update

      pdebuild --debbuildopts -j8 --architecture ${arch} --buildresult ../build-result/${dist} --pbuilderroot "sudo DIST=${dist} ARCH=${arch}" \
        | tee  ../build-result/$dist/build-record-${dist}-${arch}.log

    done
  done
}


