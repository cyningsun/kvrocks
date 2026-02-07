# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

include_guard()

include(cmake/utils.cmake)

# fbthrift - Facebook's Thrift RPC framework
# Dependencies: folly, fizz, wangle, mvfst, xxhash, zstd, fmt
FetchContent_DeclareGitHubWithMirror(fbthrift
  facebook/fbthrift v2024.06.24.00
  MD5=46d3442711de92d6e7fc06a3f47e5c7a
)

# Set CONFIG-mode bridge dirs
set(folly_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/folly" CACHE PATH "" FORCE)
set(fizz_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fizz" CACHE PATH "" FORCE)
set(wangle_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/wangle" CACHE PATH "" FORCE)
set(mvfst_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/mvfst" CACHE PATH "" FORCE)
set(fmt_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fmt" CACHE PATH "" FORCE)

# Xxhash - fbthrift uses find_package(Xxhash REQUIRED) via MODULE mode
# Pre-set cache variables so FindXxhash.cmake finds our target
FetchContent_GetProperties(xxhash)
set(Xxhash_INCLUDE_DIR "${xxhash_SOURCE_DIR}" CACHE PATH "" FORCE)
set(Xxhash_LIBRARY "xxhash" CACHE STRING "" FORCE)
set(Xxhash_LIBRARY_RELEASE "xxhash" CACHE STRING "" FORCE)

# Zstd - fbthrift's own FindZstd.cmake uses ZSTD_INCLUDE_DIRS (plural) and ZSTD_LIBRARIES (plural)
# as find_path/find_library result variables (different from folly's singular names)
FetchContent_GetProperties(zstd)
set(ZSTD_INCLUDE_DIRS "${zstd_SOURCE_DIR}/lib" CACHE PATH "" FORCE)
set(ZSTD_LIBRARIES "libzstd_static" CACHE STRING "" FORCE)

# gflags bridge to avoid export() CMP0024 error
set(gflags_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/gflags" CACHE PATH "" FORCE)

# MODULE-mode dependencies: cache variables already set by folly.cmake
# (GLOG_*, LIBGFLAGS_*, Boost via FindBoost bridge, etc.)

# fbthrift's CMakeLists.txt is at the root of the source tree.
# NOTE: We use manual FetchContent_Populate + add_subdirectory instead of
# FetchContent_MakeAvailableWithArgs because the latter leaks ARGN into
# subdirectory scope, and fbthrift's FindOpenSSL.cmake uses ${ARGN}.
FetchContent_GetProperties(fbthrift)
if(NOT fbthrift_POPULATED)
  FetchContent_Populate(fbthrift)

  set(BUILD_TESTS_OLD ${BUILD_TESTS})
  set(BUILD_SHARED_LIBS_OLD ${BUILD_SHARED_LIBS})
  set(BUILD_EXAMPLES_OLD ${BUILD_EXAMPLES})
  set(enable_tests_OLD ${enable_tests})

  set(BUILD_TESTS OFF CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
  set(BUILD_EXAMPLES OFF CACHE INTERNAL "")
  set(enable_tests OFF CACHE INTERNAL "")
  set(CMAKE_SKIP_INSTALL_RULES_OLD ${CMAKE_SKIP_INSTALL_RULES})
  set(CMAKE_SKIP_INSTALL_RULES ON)

  add_subdirectory(${fbthrift_SOURCE_DIR} ${fbthrift_BINARY_DIR} EXCLUDE_FROM_ALL)

  set(CMAKE_SKIP_INSTALL_RULES ${CMAKE_SKIP_INSTALL_RULES_OLD})
  set(BUILD_TESTS ${BUILD_TESTS_OLD} CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_OLD} CACHE INTERNAL "")
  set(BUILD_EXAMPLES ${BUILD_EXAMPLES_OLD} CACHE INTERNAL "")
  set(enable_tests ${enable_tests_OLD} CACHE INTERNAL "")

  # Fix: fbthrift uses include_directories(.) (directory-level) instead of
  # target_include_directories(PUBLIC ...). This means include paths don't
  # propagate to downstream consumers (like cachelib). Manually add them.
  cmake_policy(SET CMP0079 NEW)
  foreach(_tgt thriftcpp2 thriftprotocol thrift-core thriftannotation transport concurrency rpcmetadata)
    if(TARGET ${_tgt})
      target_include_directories(${_tgt} PUBLIC
        $<BUILD_INTERFACE:${fbthrift_SOURCE_DIR}>
        $<BUILD_INTERFACE:${fbthrift_BINARY_DIR}>
      )
    endif()
  endforeach()
endif()

# Create namespace aliases (fbthrift exports with NAMESPACE FBThrift:: at install time)
if(TARGET thriftcpp2 AND NOT TARGET FBThrift::thriftcpp2)
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
