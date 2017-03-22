#!/bin/bash
#remove existing Cmake cache and directories
# remove existing Cmake cache and directories
rm -fr CMake*
rm -rf Testing
rm -rf src
rm -rf tests
rm -f CPack*
rm -f *.txt

# set CMAKE-related and build-related variables
export COMPILER_VERSION=5.4.0
export COMPILER_MAJ_VERSION=5
export GCCBINDIR=$(locate bin/gcc-5 | grep "$COMPILER_VERSION")
export LIBGFORTRANDIR=$(locate 5/libgfortran.a | grep "$COMPILER_VERSION")
export LIBGCCDIR=$(locate "$COMPILER_VERSION/libgcc.a" | sed -e 's/\/libgcc.a//')
export GCCDIR=$(locate bin/gfortran-5 | grep "$COMPILER_VERSION")
export CMAKEROOT=/usr/bin/cmake
export COMPILER_TRIPLET=x86_64-apple-darwin15.4.0
export COMPILER_DIR=/usr/local
export LIB_PATH1=$(locate "$COMPILER_VERSION/libgcc.a" | sed -e 's/\/libgcc.a//')
export LIB_PATH2=/opt/X11/lib
export LIB_PATH3=$(locate 5/libgfortran.a | grep "$COMPILER_VERSION")
export LIB_PATH4="/usr/local/lib/gcc/$COMPILER_MAJ_VERSION"
export Fortran_COMPILER_NAME=gfortran
export R_HOME=/usr/bin/R

export PATH=/usr/bin:/usr/local/bin:/usr/local/lib:/usr/bin/cmake:$GCCBINDIR

# define where 'make copy' will place executables
export INSTALL_PREFIX=/usr/local/bin

# define other variables for use in the CMakeList.txt file
# options are "Release" or "Debug"
export BUILD_TYPE="RELEASE"
export OS="mac_osx"

# define platform and compiler specific compilation flags
export CMAKE_Fortran_FLAGS_DEBUG="-O0 -g -ggdb -Wuninitialized -fbacktrace -fcheck=all -fexceptions -fsanitize=null -fsanitize=leak -fmax-errors=6 -fbackslash -ffree-line-length-none"
#set CMAKE_Fortran_FLAGS_RELEASE="-O2 -mtune=native -floop-parallelize-all -flto -ffree-line-length-none -static-libgcc -static-libgfortran"
#export CMAKE_Fortran_FLAGS_RELEASE="-O3 -mtune=native -ffree-line-length-none -ffpe-summary='none' -fopenmp"

export CMAKE_Fortran_FLAGS_RELEASE="-O2 -mtune=native -ffree-line-length-512 -fbackslash -ffpe-summary='none'"


# set important environment variables
export FC=/usr/local/bin/gfortran-"$COMPILER_MAJ_VERSION"
export CC=/usr/local/bin/gcc-"$COMPILER_MAJ_VERSION"
export CXX=/usr/local/bin/g++-"$COMPILER_MAJ_VERSION"
export AR=gcc-ar-$COMPILER_MAJ_VERSION
export NM=gcc-nm-$COMPILER_MAJ_VERSION
export LD=/usr/bin/ld
export STRIP=/usr/bin/strip
export CMAKE_RANLIB=gcc-ranlib-$COMPILER_MAJ_VERSION

cmake ../../.. -G "Unix Makefiles"                           \
-DCOMPILER_DIR="$COMPILER_DIR "                              \
-DCOMPILER_TRIPLET="$COMPILER_TRIPLET "                      \
-DCMAKE_Fortran_COMPILER="$FC"                               \
-DLIB_PATH1="$LIB_PATH1 "                                    \
-DLIB_PATH2="$LIB_PATH2 "                                    \
-DLIB_PATH3="$LIB_PATH3 "                                    \
-DLIB_PATH4="$LIB_PATH4 "                                    \
-DLIBGCC_PATH="$LIBGCCDIR "                                  \
-DLIBGFORTRAN_PATH="$LIBGFORTRANDIR"                         \
-DCMAKE_EXE_LINKER_FLAGS="$LINKER_FLAGS "                    \
-DOS="$OS "                                                  \
-DCMAKE_BUILD_TYPE="$BUILD_TYPE "                            \
-DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_PREFIX "               \
-DCMAKE_Fortran_FLAGS_DEBUG="$CMAKE_Fortran_FLAGS_DEBUG "    \
-DCMAKE_Fortran_FLAGS_RELEASE="$CMAKE_Fortran_FLAGS_RELEASE"
