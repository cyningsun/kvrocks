# Bridge: gflags is available via add_subdirectory
# This file intercepts find_package(gflags CONFIG) to avoid the export()
# generated file error (CMP0024) from gflags' own gflags-config.cmake.

if(NOT TARGET gflags)
  message(FATAL_ERROR "Bridge error: gflags target not available (expected from add_subdirectory)")
endif()

set(gflags_FOUND TRUE)
set(GFLAGS_FOUND TRUE)

# Set variables expected by consumers
include(FetchContent)
FetchContent_GetProperties(gflags)
set(gflags_INCLUDE_DIR "${gflags_BINARY_DIR}/include")
set(GFLAGS_INCLUDE_DIR "${gflags_BINARY_DIR}/include")
set(gflags_LIBRARIES gflags)
set(GFLAGS_LIBRARIES gflags)

# Create namespaced target if not present
if(NOT TARGET gflags::gflags)
  add_library(gflags::gflags ALIAS gflags)
endif()

# gflags-config.cmake normally sets GFLAGS_TARGET
set(GFLAGS_TARGET gflags)
