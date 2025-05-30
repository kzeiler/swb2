cmake_minimum_required(VERSION 3.7)

project( swb2 LANGUAGES C Fortran )

message("Processing top-level CMakelists.txt for project swb2")

set(SWB_MAJOR_VERSION "2")
set(SWB_MINOR_VERSION "3")
set(SWB_PATCH_VERSION "1")
set(SWB_LATEST_VERSION_TAG "v2.3.1")

#------------------------------------------------------------------------------------#
#                           Force out-of-source build
#------------------------------------------------------------------------------------#
if(${CMAKE_SOURCE_DIR}/src STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "Cannot be built in the source directory. Use out-of-source build instead.")
  message(FATAL_ERROR "  cd /some/work/dir/build")
  message(FATAL_ERROR "  cmake -i /path/to/source")
endif()


SET(CPACK_GENERATOR "TGZ")
include(CPack)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

# try to have CMake find shared libraries if possible
#set(CMAKE_FIND_LIBRARY_SUFFIXES ".so" ${CMAKE_FIND_LIBRARY_SUFFIXES})

set(CMAKE_FIND_LIBRARY_SUFFIXES ".dll" ${CMAKE_FIND_LIBRARY_SUFFIXES})

if ( CMAKE_HOST_WIN32 )
  set( OUTPUT_BIN_TARGET_DIR win_x64 )
  if ( CMAKE_Fortran_COMPILER_ID STREQUAL "Intel" )
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".lib" )
    add_definitions(/D_CRT_SECURE_NO_DEPRECATE /DWIN32_LEAN_AND_MEAN)
    message("==> Set library suffixes to .lib")
  endif()
elseif( CMAKE_HOST_APPLE )
  set( OUTPUT_BIN_TARGET_DIR macOS )
  set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" ${CMAKE_FIND_LIBRARY_SUFFIXES})
elseif( CMAKE_HOST_UNIX AND (NOT CMAKE_HOST_APPLE) )
  set( OUTPUT_BIN_TARGET_DIR linux_x64 )
endif()

include( cmake/version_control.cmake )
include( cmake/FindHDF5.cmake )
include( cmake/FindHDF5_HL.cmake )
include( cmake/FindNetCDF.cmake )
include( cmake/FindZlib.cmake )
include( cmake/FindCurl.cmake )
include( cmake/FindSzip.cmake )

if ( HDF5_HL_LIBRARY )
  set( EXTERNAL_LIBRARIES ${EXTERNAL_LIBRARIES} ${HDF5_HL_LIBRARY} )
endif()  

if ( HDF5_LIBRARY )
  set( EXTERNAL_LIBRARIES ${EXTERNAL_LIBRARIES} ${HDF5_LIBRARY} )
endif()  

if ( NETCDF_LIBRARY )
  set( EXTERNAL_LIBRARIES ${EXTERNAL_LIBRARIES} ${NETCDF_LIBRARY} )
endif()  

if ( ZLIB_LIBRARY )
  set( EXTERNAL_LIBRARIES ${EXTERNAL_LIBRARIES} ${ZLIB_LIBRARY} )
endif()  

if ( SZIP_LIBRARY )
  set( EXTERNAL_LIBRARIES ${EXTERNAL_LIBRARIES} ${SZIP_LIBRARY} )
endif()  

if ( CURL_LIBRARY )
  set( EXTERNAL_LIBRARIES ${EXTERNAL_LIBRARIES} ${CURL_LIBRARY} )
endif()

#include( cmake/FindWinPthread.cmake )
#include( cmake/FindQuadMath.cmake )
#include( cmake/FindGfortran.cmake )

include_directories( ${CMAKE_BINARY_DIR}/src ${PROJECT_SOURCE_DIR}/src/proj4 )

include( cmake/print_summary.cmake )

add_subdirectory(src)
add_subdirectory(test/unit_tests)

# prepend location of project 'bin' directory
set( OUTPUT_BIN_TARGET_DIR ${PROJECT_SOURCE_DIR}/bin/${OUTPUT_BIN_TARGET_DIR} )

if ( WIN32 )
  add_custom_target(copy ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/src/swb2.exe ${OUTPUT_BIN_TARGET_DIR}/swb2.exe
                 COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/src/swbstats2.exe ${OUTPUT_BIN_TARGET_DIR}/swbstats2.exe
		             COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/test/unit_tests/swbtest.exe ${PROJECT_SOURCE_DIR}/test/unit_tests/swbtest.exe
  )
else()
  add_custom_target(copy ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/src/swb2 ${OUTPUT_BIN_TARGET_DIR}/swb2
                 COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/src/swbstats2 ${OUTPUT_BIN_TARGET_DIR}/swbstats2
                 COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/test/unit_tests/swbtest ${PROJECT_SOURCE_DIR}/test/unit_tests/swbtest
  )
endif()

file(WRITE VERSION "${SWB_MAJOR_VERSION}.${SWB_MINOR_VERSION}.${SWB_PATCH_VERSION}, build ${GIT_COMMITS_ON_BRANCH}")
