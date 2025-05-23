find_library(GCC_LIBRARY
  NAMES gcc_s.a libgcc_s.a gcc libgcc libgcc.a 
  HINTS ${GCC_LIB_PATH} ${LIBRARY_PATH} /usr
  PATH_SUFFIXES lib lib/x86_64-linux-gnu/ local/lib/ local/lib64 x86_64-w64-mingw32/lib 
  DOC "gcc library"
  NO_DEFAULT_PATH
)

if(GCC_LIBRARY)
  message("-- adding GCC_LIBRARY to project")
  add_library(SZIP_LIBRARY UNKNOWN IMPORTED
              GLOBAL
  )
endif(GCC_LIBRARY)

