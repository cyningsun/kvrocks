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

# mvfst - Facebook's QUIC transport protocol implementation
# Dependencies: folly, fizz, Boost
FetchContent_DeclareGitHubWithMirror(mvfst
  facebook/mvfst v2024.06.24.00
  MD5=23a98ce6628fecfc9811590133cbfed2
)

# Set CONFIG-mode bridge dirs for mvfst's find_package calls
# Note: mvfst uses find_package(folly REQUIRED) and find_package(Fizz REQUIRED)
# without explicit CONFIG mode, so CMake tries MODULE first then CONFIG.
# We need bridges for both patterns.
set(folly_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/folly" CACHE PATH "" FORCE)
set(Fizz_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fizz" CACHE PATH "" FORCE)
set(fizz_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fizz" CACHE PATH "" FORCE)
set(fmt_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fmt" CACHE PATH "" FORCE)

# MODULE-mode dependencies: cache variables already set by folly.cmake
# (Boost via FindBoost bridge, Glog via GLOG_* cache vars, etc.)

# mvfst's CMakeLists.txt is at the root of the source tree.
# NOTE: We use manual FetchContent_Populate + add_subdirectory instead of
# FetchContent_MakeAvailableWithArgs to avoid ARGN leaking into subdirectory scope.
FetchContent_GetProperties(mvfst)
if(NOT mvfst_POPULATED)
  FetchContent_Populate(mvfst)

  set(BUILD_TESTS_OLD ${BUILD_TESTS})
  set(BUILD_SHARED_LIBS_OLD ${BUILD_SHARED_LIBS})
  set(BUILD_EXAMPLES_OLD ${BUILD_EXAMPLES})

  set(BUILD_TESTS OFF CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
  set(BUILD_EXAMPLES OFF CACHE INTERNAL "")
  set(CMAKE_SKIP_INSTALL_RULES_OLD ${CMAKE_SKIP_INSTALL_RULES})
  set(CMAKE_SKIP_INSTALL_RULES ON)

  add_subdirectory(${mvfst_SOURCE_DIR} ${mvfst_BINARY_DIR} EXCLUDE_FROM_ALL)

  set(CMAKE_SKIP_INSTALL_RULES ${CMAKE_SKIP_INSTALL_RULES_OLD})
  set(BUILD_TESTS ${BUILD_TESTS_OLD} CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_OLD} CACHE INTERNAL "")
  set(BUILD_EXAMPLES ${BUILD_EXAMPLES_OLD} CACHE INTERNAL "")
endif()

# Create namespace aliases (mvfst exports with NAMESPACE mvfst:: at install time)
# Only create aliases for targets referenced by downstream FB libraries
if(TARGET mvfst_server AND NOT TARGET mvfst::mvfst_server)
  add_library(mvfst::mvfst_server ALIAS mvfst_server)
endif()
if(TARGET mvfst_server_async_tran AND NOT TARGET mvfst::mvfst_server_async_tran)
  add_library(mvfst::mvfst_server_async_tran ALIAS mvfst_server_async_tran)
endif()
