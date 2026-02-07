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

# fizz - Facebook's TLS 1.3 implementation
# Dependencies: folly, libsodium, liboqs, zstd, OpenSSL
FetchContent_DeclareGitHubWithMirror(fizz
  facebookincubator/fizz v2024.06.24.00
  MD5=3bebfb69e36f0849e66260499443d46c
)

# Set CONFIG-mode bridge dirs for fizz's find_package calls
set(folly_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/folly" CACHE PATH "" FORCE)
set(fmt_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fmt" CACHE PATH "" FORCE)

# MODULE-mode dependencies: cache variables already set by folly.cmake
# (GLOG_*, ZSTD_*, LIBGFLAGS_* etc. are globally cached)

# fizz's CMakeLists.txt is in fizz/fizz/ subdirectory, so we need manual
# FetchContent_Populate + add_subdirectory with the correct source subdir
FetchContent_GetProperties(fizz)
if(NOT fizz_POPULATED)
  FetchContent_Populate(fizz)

  # Temporarily set build options
  set(BUILD_TESTS_OLD ${BUILD_TESTS})
  set(BUILD_SHARED_LIBS_OLD ${BUILD_SHARED_LIBS})
  set(BUILD_EXAMPLES_OLD ${BUILD_EXAMPLES})
  set(FIZZ_BUILD_AEGIS_OLD ${FIZZ_BUILD_AEGIS})

  set(BUILD_TESTS OFF CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
  set(BUILD_EXAMPLES OFF CACHE INTERNAL "")
  set(FIZZ_BUILD_AEGIS OFF CACHE INTERNAL "")
  set(CMAKE_SKIP_INSTALL_RULES_OLD ${CMAKE_SKIP_INSTALL_RULES})
  set(CMAKE_SKIP_INSTALL_RULES ON)

  add_subdirectory(${fizz_SOURCE_DIR}/fizz ${fizz_BINARY_DIR} EXCLUDE_FROM_ALL)

  # Fix: fizz uses get_filename_component(FIZZ_BASE_DIR ${CMAKE_SOURCE_DIR}/.. ABSOLUTE)
  # which resolves to the wrong path in add_subdirectory mode (CMAKE_SOURCE_DIR is the
  # top-level project, not fizz). Manually add the correct include base directory.
  if(TARGET fizz)
    cmake_policy(SET CMP0079 NEW)
    target_include_directories(fizz PUBLIC $<BUILD_INTERFACE:${fizz_SOURCE_DIR}>)
  endif()

  set(CMAKE_SKIP_INSTALL_RULES ${CMAKE_SKIP_INSTALL_RULES_OLD})
  # Restore
  set(BUILD_TESTS ${BUILD_TESTS_OLD} CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_OLD} CACHE INTERNAL "")
  set(BUILD_EXAMPLES ${BUILD_EXAMPLES_OLD} CACHE INTERNAL "")
  set(FIZZ_BUILD_AEGIS ${FIZZ_BUILD_AEGIS_OLD} CACHE INTERNAL "")
endif()

# Create namespace aliases (fizz exports with NAMESPACE fizz:: at install time)
if(TARGET fizz AND NOT TARGET fizz::fizz)
  add_library(fizz::fizz ALIAS fizz)
endif()
