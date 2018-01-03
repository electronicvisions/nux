#!/bin/bash

set -e

TARGET=powerpc-eabi
PREFIX=${PWD}/install


# Fetch binutils and gcc
git clone --depth 1 https://github.com/electronicvisions/binutils-gdb.git
git clone --depth 1 https://github.com/electronicvisions/gcc.git


# Download gcc prerequisites
cd gcc
contrib/download_prerequisites
cd ..


# Configure and build binutils
CONFIGURE_OPTIONS_BINUTILS="--disable-multilib --disable-nls"

mkdir -p build-binutils-gdb
cd build-binutils-gdb
../binutils-gdb/configure --prefix=${PREFIX} --target=${TARGET} ${CONFIGURE_OPTIONS_BINUTILS}
make -j
make install
cd ..


# Configure and build gcc
CONFIGURE_OPTIONS_GCC="--enable-languages=c,c++ --disable-threads --disable-multilib --disable-nls"

mkdir -p build-gcc
cd build-gcc
../gcc/configure --prefix=${PREFIX} --target=${TARGET} ${CONFIGURE_OPTIONS_GCC}
make -j all-gcc
make install-gcc
cd ..
