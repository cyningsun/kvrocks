# Bridge: mvfst is available via add_subdirectory
# This file satisfies find_package(mvfst CONFIG REQUIRED) for downstream FB libs

# mvfst creates multiple library targets; check for the main one
if(NOT TARGET mvfst_transport)
  message(FATAL_ERROR "Bridge error: mvfst_transport target not available (expected from add_subdirectory)")
endif()

set(mvfst_FOUND TRUE)
set(MVFST_FOUND TRUE)

# Include directories are propagated automatically via mvfst targets
# (mvfst has PUBLIC target_include_directories). No need to set MVFST_INCLUDE_DIR.

# Create namespace aliases for targets used by downstream FB libraries
# (fbthrift's FBThriftCppLibrary.cmake references mvfst::mvfst_server_async_tran
#  and mvfst::mvfst_server)
if(TARGET mvfst_server AND NOT TARGET mvfst::mvfst_server)
  add_library(mvfst::mvfst_server ALIAS mvfst_server)
endif()
if(TARGET mvfst_server_async_tran AND NOT TARGET mvfst::mvfst_server_async_tran)
  add_library(mvfst::mvfst_server_async_tran ALIAS mvfst_server_async_tran)
endif()
