
set(CMAKE_FIND_LIBRARY_PREFIXES "lib")

set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" ".so" ".a" )

find_program( R_SCRIPT Rscript.exe Rscript
    PATHS
    ${PATH_TO_R}
    "c:/Program Files/R"
    "c:/Program Files/R/R-3.0.1/bin"
    "/usr/bin"
)

include_directories( ${INC_PATH} "${PROJECT_SOURCE_DIR}/src/proj4")

if ("${OS}" STREQUAL "win_x64" OR "${OS}" STREQUAL "win_x86")

  set( SWB_EXECUTABLE ${CMAKE_INSTALL_PREFIX}/swb2.exe )

else()

  set( SWB_EXECUTABLE ${CMAKE_INSTALL_PREFIX}/swb2 )

endif()


################################################################
## NOTE: CMAKE_FIND_LIBRARY_SUFFIXES works...
##       CMAKE_FILE_LIBRARY_SUFFIX does not
##       PATH does not work
##       PATHS works
##
##  in main CMakeLists.txt the following works:
##
##    set(LIB_PATH ${COMPILER_DIR}/lib/gcc/${COMPILER_TRIPLET}/${COMPILER_VERSION} )
##
##  the following does not (note double quotes):
##
##    set(LIB_PATH "${COMPILER_DIR}/lib/gcc/${COMPILER_TRIPLET}/${COMPILER_VERSION}" )
##
################################################################

message("MOD: LIB_PATH = ${LIB_PATH}")

find_library(LIBZ
        NAMES z libz libz.a libz.dylib
        PATHS
        ${LIBZ_PATH}
        ${LIB_PATH} )

find_library(LIBNETCDF
        NAMES netcdf libnetcdf libnetcdf.a
        PATHS
        ${LIBNETCDF_PATH}
        ${LIB_PATH}
        /usr/local/lib64
        /share/apps/gcc/${COMPILER_VERSION}/lib )

find_library(LIBHDF5
        NAMES hdf5 libhdf5 libhdf5.a
        PATHS
        /usr/local/lib64
        ${LIBHDF5_PATH}
        ${LIB_PATH} )

find_library(LIBHDF5_HL
        NAMES hdf5_hl libhdf5_hl libhdf5_hl.a
        PATHS /usr/local/lib64
        ${LIBHDF5_PATH}
        ${LIB_PATH} )

find_library(LIBCURL
        NAMES curl libcurl libcurl.a libcurl.dylib
        PATHS
        /usr/local/opt/curl/lib
        ${LIBCURL_PATH}
        ${LIB_PATH} )

find_library(LIBGCC
        NAMES gcc libgcc libgcc.a libgcc.dylib
        PATHS
        /usr/local/lib64
        ${LIBGCC_PATH}
        ${LIB_PATH} )

find_library(LIBGFORTRAN
        NAMES gfortran libgfortran libgfortran.a
        PATHS
        /usr/local/lib64
        ${LIBGCC_PATH}
        ${LIBGFORTRAN_PATH}
        ${LIB_PATH} )

set( EXTERNAL_LIBS ${LIBNETCDF} ${LIBHDF5_HL} ${LIBHDF5}
                   ${LIBCURL} ${LIBZ}
                   ${LIBGCC} ${LIBGFORTRAN} )

# Now, add platform-specific libraries as needed
#

if ("${OS}" STREQUAL "win_x64" OR "${OS}" STREQUAL "win_x86")

  find_library(LIBWINPTHREAD
          NAMES libwinpthread.a winpthread winpthread
          PATHS
          ${LIBWINPTHREAD_PATH}
          ${LIB_PATH} )

  find_library(LIBWS2_32
          NAMES ws2_32 libws2_32 libws2_32.a
          PATHS
          ${LIBWS2_32_PATH}
          ${LIB_PATH} )

  find_library(LIBCRYPT32
          NAMES crypt32 libcrypt32 libcrypt32.a
          PATHS
          ${LIB_PATH} )

  find_library(LIBCRYPTO
          NAMES crypto libcrypto libcrypto.a
          PATHS
          ${LIB_PATH}
          NO_CMAKE_SYSTEM_PATH )

  find_library(LIBCRYPT
          NAMES crypt libcrypt libcrypt.a
          PATHS
          ${LIB_PATH}
          NO_CMAKE_SYSTEM_PATH )

  find_library(LIBGCRYPT
          NAMES gcrypt libgcrypt libgcrypt.a
          PATHS
          ${LIB_PATH}
          NO_CMAKE_SYSTEM_PATH )

  find_library(LIBGPG_ERROR
          NAMES gpg-error libgpg-error libgpg-error.a
          PATHS
          ${LIB_PATH}
          NO_CMAKE_SYSTEM_PATH )

  find_library(LIBNETTLE
          NAMES nettle libnettle libnettle.a
          PATHS
          ${LIB_PATH}
          NO_CMAKE_SYSTEM_PATH )

  find_library(LIBGNUTLS
          NAMES gnutls libgnutls libgnutls.a
          PATHS
          ${LIB_PATH}
          NO_CMAKE_SYSTEM_PATH )

# the entries below are needed to link to DAP-enabled NetCDF
 find_library(LIBWLDAP32
         NAMES lwldap32 libwldap32 libwldap32.a
         PATHS
         ${LIB_PATH}
         NO_CMAKE_SYSTEM_PATH )

# find_library(LIBSASL2
#         NAMES gsasl libgsasl sasl2 libsasl2 libsasl2.dylib
#         PATHS /usr/local/opt/gsasl/lib
#          ${SWB_PATH}
#         NO_CMAKE_SYSTEM_PATH )

# find_library(LIBLBER
#         NAMES lber liblber liblber.dylib
#          PATHS ${SWB_PATH}
#         ${LIB_PATH}
#         NO_CMAKE_SYSTEM_PATH )

  find_library(LIBSSH2
          NAMES ssh2 libssh2 libssh2.dylib
          PATHS
          ${LIB_PATH})

  find_library(LIBIDN
          NAMES idn lidn libidn.a
          PATHS
          ${LIB_PATH})

  find_library(LIBGMP
          NAMES gmp lgmp libgmp.a
          PATHS
          ${LIB_PATH})

  find_library(LIBINTL
          NAMES intl lintl lintl.a
          PATHS
          ${LIB_PATH})

  find_library(LIBICONV
          NAMES iconv liconv libiconv.a
          PATHS
          ${LIB_PATH})

  find_library(LIBHOGWEED
          NAMES hogweed lhogweed lhogweed.a
          PATHS
          ${LIB_PATH})

  find_library(LIBSSL
          NAMES ssl libssl libssl.dylib
          PATHS
          ${LIB_PATH} )

  set( EXTERNAL_LIBS ${EXTERNAL_LIBS} ${LIBWINPTHREAD} ${LIBWS2_32} )
#
elseif ("${OS}" STREQUAL "mac_osx" )
#
  set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" "*.a")

  find_library(LIBXM
          NAMES Xm libXm libXm.dylib
          PATHS
          /usr/OpenMotif/lib
          ${LIBXM_PATH}
          ${LIB_PATH} )

  set(CMAKE_FIND_LIBRARY_SUFFIXES ".a" ".dylib")

#  set( EXTERNAL_LIBS ${EXTERNAL_LIBS} ${LIBXM} )
#

### NOTE: the libraries defined below will be needed for linking to libcurl.

#  find_library(LIBCRYPT32
#          NAMES crypt32 libcrypt32 libcrypt32.a
#          PATHS
#          ${LIB_PATH} )

  find_library(LIBSASL2
          NAMES gsasl libgsasl sasl2 libsasl2 libsasl2.dylib
          PATHS /usr/local/opt/gsasl/lib
#          ${SWB_PATH}
          NO_CMAKE_SYSTEM_PATH )

#  find_library(LIBLBER
#          NAMES lber liblber liblber.dylib
#          PATHS ${SWB_PATH}
#          ${LIB_PATH}
#          NO_CMAKE_SYSTEM_PATH )

  find_library(LIBSSH2
          NAMES ssh2 libssh2 libssh2.dylib
          PATHS
          /usr/local/opt/libssh2/lib
#          ${SWB_PATH}
          ${LIB_PATH})

  find_library(LIBSSL
          NAMES ssl libssl libssl.dylib
          PATHS
          /usr/local/opt/openssl/lib
#          ${SWB_PATH}
          ${LIB_PATH} )

  find_library(LIBXT
          NAMES Xt libXt.dylib
          PATHS
          /opt/X11/lib
          ${LIB_PATH})

else()

  find_library(LIBDL
          NAMES dl libdl
          PATHS
          /lib64
          ${LIB_PATH})

  find_library(LIBC
          NAMES c libc
          PATHS
          /lib64
          ${LIB_PATH})

endif()

set( EXTERNAL_LIBS ${EXTERNAL_LIBS} ${LIBIDN} ${LIBINTL} ${LIBICONV} ${LIBSSH2} ${LIBSSH2} ${LIBCRYPTO} ${LIBSSL} ${LIBLBER} ${LIBLDAP}
      ${LIBGCRYPT} ${LIBGPG_ERROR} ${LIBNETTLE} ${LIBGMP} ${LIBCRYPT32} ${LIBGNUTLS} ${LIBNETTLE} ${LIBHOGWEED} ${LIBCRYPT32} ${LIBWLDAP32}
      ${LIBWS2_32} ${LIBDL} ${LIBC} )

link_libraries( ${EXTERNAL_LIBS} )
