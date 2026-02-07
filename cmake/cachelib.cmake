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

# CacheLib - Facebook's caching library
# Dependencies: folly, fizz, wangle, fbthrift, boost, gflags, glog, fmt, zstd, googletest, sparsemap
FetchContent_DeclareGitHubWithMirror(cachelib
  facebook/CacheLib v20240621
  MD5=70c378cb5a161efd7e735ec0ecf54fe1
)

# ============================================================================
# Sparsemap (header-only library required by CacheLib)
# ============================================================================
FetchContent_DeclareGitHubWithMirror(sparsemap
  Tessil/sparse-map v0.7.0
  MD5=5854aec510de6a8c020f25ef77896833
)

FetchContent_GetProperties(sparsemap)
if(NOT sparsemap_POPULATED)
  FetchContent_Populate(sparsemap)
  message(STATUS "sparsemap downloaded to: ${sparsemap_SOURCE_DIR}")
endif()

set(SPARSEMAP_INCLUDE_DIR ${sparsemap_SOURCE_DIR}/include CACHE PATH "Sparsemap include directory")

# Pre-set cache variable for CacheLib's FindSparsemap.cmake
# FindSparsemap uses: find_path(SPARSEMAP_INCLUDE_DIRS NAMES tsl/sparse_map.h)
set(SPARSEMAP_INCLUDE_DIRS "${sparsemap_SOURCE_DIR}/include" CACHE PATH "" FORCE)

# Sparsemap include will be added as target-specific after add_subdirectory below.
# (CacheLib's code uses #include <tsl/sparse_map.h> in production headers.)

# ============================================================================
# Set CONFIG-mode bridge dirs for CacheLib's find_package calls
# ============================================================================
set(folly_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/folly" CACHE PATH "" FORCE)
set(fizz_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fizz" CACHE PATH "" FORCE)
set(wangle_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/wangle" CACHE PATH "" FORCE)
set(fmt_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fmt" CACHE PATH "" FORCE)
set(FBThrift_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fbthrift" CACHE PATH "" FORCE)
set(fbthrift_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fbthrift" CACHE PATH "" FORCE)

# ============================================================================
# GTest bridge for CacheLib
# ============================================================================
# CacheLib v20240621 uses find_package(GTest CONFIG REQUIRED).
# Point GTest_DIR to our bridge config that creates GTest::* aliases.
set(GTest_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/gtest" CACHE PATH "" FORCE)

# CacheLib's production code (e.g. Handle.h) unconditionally includes <gtest/gtest.h>.
# Gtest/gmock includes will be added as target-specific after add_subdirectory below.
FetchContent_GetProperties(gtest)

# ============================================================================
# thrift1 compiler for CacheLib's thrift code generation
# ============================================================================
# CacheLib uses find_program(FBTHRIFT1 thrift1) to find the thrift compiler.
# Since fbthrift is built via add_subdirectory, thrift1 is a build target.
# We can't use $<TARGET_FILE:thrift1> in find_program, so we set it
# to the expected build output path.
FetchContent_GetProperties(fbthrift)
set(FBTHRIFT1 "${fbthrift_BINARY_DIR}/bin/thrift1" CACHE FILEPATH "" FORCE)

# ============================================================================
# LibUring bridge for CacheLib
# ============================================================================
# CacheLib uses liburing directly (not through folly::IoUring).
# Pre-set cache variables so CacheLib's Finduring.cmake finds our installed liburing.
set(uring_INCLUDE_DIR "${LIBURING_INSTALL_DIR}/include" CACHE PATH "" FORCE)
set(uring_LIBRARIES "liburing::liburing" CACHE STRING "" FORCE)

# Liburing include will be added as target-specific after add_subdirectory below.
# (Folly's FOLLY_HAS_LIBURING macro uses __has_include(<liburing.h>) at compile time.
# When CacheLib includes folly headers, liburing.h must be findable.)

# ============================================================================
# Add CacheLib via add_subdirectory
# ============================================================================
# CacheLib's CMakeLists.txt is in cachelib/cachelib/ subdirectory
FetchContent_GetProperties(cachelib)
if(NOT cachelib_POPULATED)
  FetchContent_Populate(cachelib)
  message(STATUS "CacheLib source downloaded to: ${cachelib_SOURCE_DIR}")

  set(BUILD_TESTS_OLD ${BUILD_TESTS})
  set(BUILD_SHARED_LIBS_OLD ${BUILD_SHARED_LIBS})

  set(BUILD_TESTS OFF CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
  set(CMAKE_SKIP_INSTALL_RULES_OLD ${CMAKE_SKIP_INSTALL_RULES})
  set(CMAKE_SKIP_INSTALL_RULES ON)

  # Patch CacheLib's add_thrift_file function:
  # CacheLib uses CMAKE_BINARY_DIR to compute thrift output paths, which only works
  # when CacheLib is the top-level project. When used as a subdirectory,
  # CMAKE_BINARY_DIR points to the parent project's build root, causing incorrect
  # thrift output paths. Fix: replace CMAKE_BINARY_DIR with CACHELIB_BUILD
  # (which is set to CMAKE_CURRENT_BINARY_DIR in CacheLib's CMakeLists.txt).
  set(_cachelib_cmakelists "${cachelib_SOURCE_DIR}/cachelib/CMakeLists.txt")
  file(READ "${_cachelib_cmakelists}" _cachelib_cmake_content)
  string(REPLACE
    "string(LENGTH \"\${CMAKE_BINARY_DIR}\" \"FOOJ\")"
    "string(LENGTH \"\${CACHELIB_BUILD}\" \"FOOJ\")"
    _cachelib_cmake_content "${_cachelib_cmake_content}")
  string(REPLACE
    "string(CONCAT FOOM \"\${CMAKE_BINARY_DIR}\""
    "string(CONCAT FOOM \"\${CACHELIB_BUILD}\""
    _cachelib_cmake_content "${_cachelib_cmake_content}")
  file(WRITE "${_cachelib_cmakelists}" "${_cachelib_cmake_content}")

  add_subdirectory(${cachelib_SOURCE_DIR}/cachelib ${cachelib_BINARY_DIR} EXCLUDE_FROM_ALL)

  # Add target-specific include directories to CacheLib targets.
  # These replace global include_directories() calls to avoid polluting
  # the parent project's include search paths.
  # CMP0079 allows target_include_directories on targets defined in other directories.
  cmake_policy(SET CMP0079 NEW)
  foreach(_tgt cachelib_common cachelib_allocator cachelib_navy cachelib_shm cachelib_datatype)
    if(TARGET ${_tgt})
      # sparsemap: CacheLib production headers include <tsl/sparse_map.h>
      target_include_directories(${_tgt} PUBLIC SYSTEM "${sparsemap_SOURCE_DIR}/include")
      # gtest: CacheLib production headers include <gtest/gtest.h> for FRIEND_TEST
      target_include_directories(${_tgt} PUBLIC SYSTEM "${gtest_SOURCE_DIR}/googletest/include")
      target_include_directories(${_tgt} PUBLIC SYSTEM "${gtest_SOURCE_DIR}/googlemock/include")
      # liburing: folly headers need liburing.h visible (FOLLY_HAS_LIBURING macro)
      target_include_directories(${_tgt} PUBLIC SYSTEM "${LIBURING_INSTALL_DIR}/include")
    endif()
  endforeach()

  set(CMAKE_SKIP_INSTALL_RULES ${CMAKE_SKIP_INSTALL_RULES_OLD})
  set(BUILD_TESTS ${BUILD_TESTS_OLD} CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_OLD} CACHE INTERNAL "")
endif()

# Export variables for the main project
set(CACHELIB_FOUND TRUE CACHE BOOL "CacheLib found")
set(CACHELIB_SOURCE_DIR ${cachelib_SOURCE_DIR} CACHE PATH "CacheLib source directory")

# ============================================================================
# Aggregate CacheLib target: self-contained INTERFACE target for consumers
# ============================================================================
# Encapsulates all CacheLib sub-targets and fixes missing upstream dependencies.
# Consumers only need: target_link_libraries(... cachelib_all)
add_library(cachelib_all INTERFACE)
target_link_libraries(cachelib_all INTERFACE
  cachelib_allocator    # PUBLIC links: cachelib_navy, cachelib_common, cachelib_shm
  cachelib_datatype     # separate target, not linked by cachelib_allocator
  # CacheLib upstream bug: production headers (Handle.h, CacheAllocator.h, Slab.h)
  # include <gtest/gtest.h> for FRIEND_TEST but don't declare the dependency.
  gtest
  gmock
)
# CacheLib source uses: #include "cachelib/allocator/CacheAllocator.h"
# so include the parent of cachelib/ source dir.
# Also add the build directory for thrift-generated headers.
# Note: thrift files are generated to ${cachelib_BINARY_DIR}/cachelib/xxx/gen-cpp2/,
# so include ${cachelib_BINARY_DIR} (not ${cachelib_BINARY_DIR}/cachelib) to resolve
# #include "cachelib/xxx/gen-cpp2/..." correctly.
target_include_directories(cachelib_all INTERFACE
  "${cachelib_SOURCE_DIR}"   # parent of cachelib subdir for source headers
  "${cachelib_BINARY_DIR}"   # for thrift-generated headers (cachelib/xxx/gen-cpp2/)
)
