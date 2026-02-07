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

FetchContent_DeclareGitHubWithMirror(folly
  facebook/folly v2024.06.24.00
  MD5=26da193288396781492b84cce93a8756
)

# ============================================================================
# Ensure our bridge modules are in CMAKE_MODULE_PATH
# ============================================================================
# This must be done BEFORE add_subdirectory(folly) so that:
# 1. Our FindBoost.cmake bridge is found before CMake's built-in FindBoost
# 2. Our bridge modules are available to folly's Find modules
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/modules")

# ============================================================================
# Get source/binary dirs of already-available dependencies
# ============================================================================
FetchContent_GetProperties(double-conversion)
FetchContent_GetProperties(fast_float)
FetchContent_GetProperties(gflags)
FetchContent_GetProperties(glog)
FetchContent_GetProperties(libevent)
FetchContent_GetProperties(boost)
FetchContent_GetProperties(lz4)
FetchContent_GetProperties(zstd)
FetchContent_GetProperties(snappy)
FetchContent_GetProperties(fmt)

# ============================================================================
# Pre-set cache variables: let folly's Find modules use our targets
# ============================================================================
# When folly's Find modules call find_path() / find_library(), CMake checks
# if the result variable is already set as a CACHE variable. If so, it skips
# the search and uses the cached value. We exploit this to point folly at
# our add_subdirectory targets.

# DoubleConversion (fbcode_builder/CMake/FindDoubleConversion.cmake)
set(DOUBLE_CONVERSION_INCLUDE_DIR "${double-conversion_SOURCE_DIR}" CACHE PATH "" FORCE)
set(DOUBLE_CONVERSION_LIBRARY "double-conversion" CACHE STRING "" FORCE)

# FastFloat (folly/CMake/FindFastFloat.cmake)
set(FASTFLOAT_INCLUDE_DIR "${fast_float_SOURCE_DIR}/include" CACHE PATH "" FORCE)

# Gflags (fbcode_builder/CMake/FindGflags.cmake)
# FindGflags first tries find_package(gflags CONFIG), then falls back to find_path/find_library.
# Pre-set gflags_DIR to our bridge to avoid the export() CMP0024 error from gflags' own config.
set(gflags_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/gflags" CACHE PATH "" FORCE)
# Also pre-set the cache variables so the MODULE fallback path uses our target.
set(LIBGFLAGS_INCLUDE_DIR "${gflags_BINARY_DIR}/include" CACHE PATH "" FORCE)
set(LIBGFLAGS_LIBRARY "gflags" CACHE STRING "" FORCE)
set(LIBGFLAGS_LIBRARY_RELEASE "gflags" CACHE STRING "" FORCE)
set(LIBGFLAGS_FOUND TRUE CACHE BOOL "" FORCE)
set(GFLAGS_FOUND TRUE CACHE BOOL "" FORCE)
set(Gflags_FOUND TRUE CACHE BOOL "" FORCE)
set(gflags_FOUND TRUE CACHE BOOL "" FORCE)

# Glog (fbcode_builder/CMake/FindGlog.cmake)
set(GLOG_INCLUDE_DIR "${glog_BINARY_DIR}" CACHE PATH "" FORCE)
set(GLOG_LIBRARY "glog" CACHE STRING "" FORCE)
set(GLOG_LIBRARY_RELEASE "glog" CACHE STRING "" FORCE)

# LibEvent (fbcode_builder/CMake/FindLibEvent.cmake)
# FindLibEvent first tries find_package(Libevent CONFIG), then checks TARGET event.
# The 'event' target exists from our add_subdirectory, so CONFIG mode should work.
# Pre-set as fallback.
set(LIBEVENT_INCLUDE_DIR "${libevent_SOURCE_DIR}/include;${libevent_BINARY_DIR}/include" CACHE STRING "" FORCE)
set(LIBEVENT_LIB "event" CACHE STRING "" FORCE)

# LZ4 (folly/CMake/FindLZ4.cmake)
set(LZ4_INCLUDE_DIR "${lz4_SOURCE_DIR}/lib" CACHE PATH "" FORCE)
set(LZ4_LIBRARY "lz4_static" CACHE STRING "" FORCE)
set(LZ4_LIBRARY_RELEASE "lz4_static" CACHE STRING "" FORCE)

# Zstd (folly/CMake/FindZstd.cmake)
set(ZSTD_INCLUDE_DIR "${zstd_SOURCE_DIR}/lib" CACHE PATH "" FORCE)
set(ZSTD_LIBRARY "libzstd_static" CACHE STRING "" FORCE)
set(ZSTD_LIBRARY_RELEASE "libzstd_static" CACHE STRING "" FORCE)

# Snappy (folly/CMake/FindSnappy.cmake)
set(SNAPPY_INCLUDE_DIR "${snappy_SOURCE_DIR}" CACHE PATH "" FORCE)
set(SNAPPY_LIBRARY "snappy" CACHE STRING "" FORCE)
set(SNAPPY_LIBRARY_RELEASE "snappy" CACHE STRING "" FORCE)

# Boost - handled by our custom cmake/modules/FindBoost.cmake bridge
# (see cmake/modules/FindBoost.cmake)

# fmt - folly uses find_package(fmt CONFIG), we provide a bridge config
set(fmt_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fmt" CACHE PATH "" FORCE)

# LibUring - we intentionally do NOT bridge this for folly
# (folly's optional liburing support is separate from kvrocks's direct usage)

# ============================================================================
# Add folly via add_subdirectory
# ============================================================================
# NOTE: We use manual FetchContent_Populate + add_subdirectory instead of
# FetchContent_MakeAvailableWithArgs to avoid ARGN leaking into subdirectory scope.
FetchContent_GetProperties(folly)
if(NOT folly_POPULATED)
  FetchContent_Populate(folly)

  set(BUILD_TESTS_OLD ${BUILD_TESTS})
  set(BUILD_SHARED_LIBS_OLD ${BUILD_SHARED_LIBS})
  set(BUILD_BENCHMARKS_OLD ${BUILD_BENCHMARKS})
  set(PYTHON_EXTENSIONS_OLD ${PYTHON_EXTENSIONS})

  set(BUILD_TESTS OFF CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
  set(BUILD_BENCHMARKS OFF CACHE INTERNAL "")
  set(PYTHON_EXTENSIONS OFF CACHE INTERNAL "")
  # Skip install rules to avoid export validation errors (CMP0022, etc.)
  # We only use folly as a build dependency, not for installation.
  set(CMAKE_SKIP_INSTALL_RULES_OLD ${CMAKE_SKIP_INSTALL_RULES})
  set(CMAKE_SKIP_INSTALL_RULES ON)

  # Inject our FindLibEvent bridge into folly's CMake/ directory so it's found
  # before folly's build/fbcode_builder/CMake/FindLibEvent.cmake.
  # The original FindLibEvent uses get_target_property(... event LOCATION) which
  # returns NOTFOUND for the INTERFACE target 'event' from libevent's add_subdirectory.
  file(COPY "${PROJECT_SOURCE_DIR}/cmake/modules/FindLibEvent.cmake"
       DESTINATION "${folly_SOURCE_DIR}/CMake/")

  # Add liburing include directory so folly's __has_include(<liburing.h>) can find it.
  # This enables FOLLY_HAS_LIBURING=1, allowing folly::IoUring to be compiled.
  # CacheLib needs folly::IoUring, so we must enable it in folly.
  # Using -isystem in CMAKE_CXX/C_FLAGS instead of global include_directories()
  # to avoid polluting the parent project's include search paths.
  set(CMAKE_CXX_FLAGS_OLD "${CMAKE_CXX_FLAGS}")
  set(CMAKE_C_FLAGS_OLD "${CMAKE_C_FLAGS}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -isystem ${LIBURING_INSTALL_DIR}/include")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -isystem ${LIBURING_INSTALL_DIR}/include")

  add_subdirectory(${folly_SOURCE_DIR} ${folly_BINARY_DIR} EXCLUDE_FROM_ALL)

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS_OLD}")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS_OLD}")
  set(CMAKE_SKIP_INSTALL_RULES ${CMAKE_SKIP_INSTALL_RULES_OLD})
  set(BUILD_TESTS ${BUILD_TESTS_OLD} CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_OLD} CACHE INTERNAL "")
  set(BUILD_BENCHMARKS ${BUILD_BENCHMARKS_OLD} CACHE INTERNAL "")
  set(PYTHON_EXTENSIONS ${PYTHON_EXTENSIONS_OLD} CACHE INTERNAL "")
endif()

# ============================================================================
# Create namespace aliases for downstream FB libraries
# ============================================================================
# folly exports targets with NAMESPACE Folly:: at install time, but
# add_subdirectory creates them without namespace. Downstream FB libs
# reference Folly::folly, so we create aliases.
if(NOT TARGET Folly::folly)
  add_library(Folly::folly ALIAS folly)
endif()
if(TARGET follybenchmark AND NOT TARGET Folly::follybenchmark)
  add_library(Folly::follybenchmark ALIAS follybenchmark)
endif()
if(TARGET folly_exception_tracer_base AND NOT TARGET Folly::folly_exception_tracer_base)
  add_library(Folly::folly_exception_tracer_base ALIAS folly_exception_tracer_base)
endif()
if(TARGET folly_exception_tracer AND NOT TARGET Folly::folly_exception_tracer)
  add_library(Folly::folly_exception_tracer ALIAS folly_exception_tracer)
endif()
if(TARGET folly_exception_counter AND NOT TARGET Folly::folly_exception_counter)
  add_library(Folly::folly_exception_counter ALIAS folly_exception_counter)
endif()
if(TARGET folly_test_util AND NOT TARGET Folly::folly_test_util)
  add_library(Folly::folly_test_util ALIAS folly_test_util)
endif()
