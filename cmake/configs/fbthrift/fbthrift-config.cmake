# Bridge: fbthrift is available via add_subdirectory
# This file satisfies find_package(FBThrift REQUIRED) and
# find_package(fbthrift CONFIG REQUIRED) for downstream FB libs

if(NOT TARGET thriftcpp2)
  message(FATAL_ERROR "Bridge error: thriftcpp2 target not available (expected from add_subdirectory)")
endif()

# Create namespaced aliases if not already present
# (cachelib links FBThrift::thriftcpp2 and FBThrift::thriftprotocol)
if(NOT TARGET FBThrift::thriftcpp2)
  add_library(FBThrift::thriftcpp2 ALIAS thriftcpp2)
endif()
if(TARGET thriftprotocol AND NOT TARGET FBThrift::thriftprotocol)
  add_library(FBThrift::thriftprotocol ALIAS thriftprotocol)
endif()
if(TARGET thrift-core AND NOT TARGET FBThrift::thrift-core)
  add_library(FBThrift::thrift-core ALIAS thrift-core)
endif()
if(TARGET thriftannotation AND NOT TARGET FBThrift::thriftannotation)
  add_library(FBThrift::thriftannotation ALIAS thriftannotation)
endif()

set(FBThrift_FOUND TRUE)
set(fbthrift_FOUND TRUE)
set(FBTHRIFT_FOUND TRUE)

FetchContent_GetProperties(fbthrift)
set(FBTHRIFT_INCLUDE_DIR "${fbthrift_SOURCE_DIR}")
set(FBTHRIFT_INCLUDE_DIRS "${fbthrift_SOURCE_DIR}")
set(FBTHRIFT_LIBRARIES thriftcpp2)

# thrift1 compiler is a build target from fbthrift's add_subdirectory
if(TARGET thrift1)
  set(FBTHRIFT1 "$<TARGET_FILE:thrift1>")
endif()
