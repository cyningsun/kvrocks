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

# wangle - Facebook's C++ networking library
# Dependencies: folly, fizz, OpenSSL, libevent
FetchContent_DeclareGitHubWithMirror(wangle
  facebook/wangle v2024.06.24.00
  MD5=4daadda53a1698ab024f9d4b55e1edbe
)

# Set CONFIG-mode bridge dirs for wangle's find_package calls
set(folly_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/folly" CACHE PATH "" FORCE)
set(fizz_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fizz" CACHE PATH "" FORCE)
set(fmt_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fmt" CACHE PATH "" FORCE)
set(gflags_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/gflags" CACHE PATH "" FORCE)
# Libevent bridge to avoid get_target_property(... LOCATION) NOTFOUND issue
set(Libevent_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/libevent" CACHE PATH "" FORCE)

# MODULE-mode dependencies: cache variables already set by folly.cmake

# wangle's CMakeLists.txt is in wangle/wangle/ subdirectory
FetchContent_GetProperties(wangle)
if(NOT wangle_POPULATED)
  FetchContent_Populate(wangle)

  set(BUILD_TESTS_OLD ${BUILD_TESTS})
  set(BUILD_SHARED_LIBS_OLD ${BUILD_SHARED_LIBS})
  set(BUILD_EXAMPLES_OLD ${BUILD_EXAMPLES})

  set(BUILD_TESTS OFF CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
  set(BUILD_EXAMPLES OFF CACHE INTERNAL "")
  set(CMAKE_SKIP_INSTALL_RULES_OLD ${CMAKE_SKIP_INSTALL_RULES})
  set(CMAKE_SKIP_INSTALL_RULES ON)

  # Fix: wangle's FindLibEvent.cmake does get_target_property(LIBEVENT_LIB event LOCATION)
  # which returns NOTFOUND because 'event' is an INTERFACE target (no LOCATION property).
  # Solution: inject our bridge FindLibEvent.cmake into wangle's cmake/ directory
  # (highest priority in wangle's CMAKE_MODULE_PATH) so it's found before the broken one.
  file(COPY "${PROJECT_SOURCE_DIR}/cmake/modules/FindLibEvent.cmake"
       DESTINATION "${wangle_SOURCE_DIR}/wangle/cmake/")

  add_subdirectory(${wangle_SOURCE_DIR}/wangle ${wangle_BINARY_DIR} EXCLUDE_FROM_ALL)

  # Fix: wangle uses $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/..> which resolves to
  # the wrong path in add_subdirectory mode. Add the correct include base directory.
  if(TARGET wangle)
    cmake_policy(SET CMP0079 NEW)
    target_include_directories(wangle PUBLIC $<BUILD_INTERFACE:${wangle_SOURCE_DIR}>)
  endif()

  set(CMAKE_SKIP_INSTALL_RULES ${CMAKE_SKIP_INSTALL_RULES_OLD})
  set(BUILD_TESTS ${BUILD_TESTS_OLD} CACHE INTERNAL "")
  set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_OLD} CACHE INTERNAL "")
  set(BUILD_EXAMPLES ${BUILD_EXAMPLES_OLD} CACHE INTERNAL "")
endif()

# Create namespace aliases (wangle exports with NAMESPACE wangle:: at install time)
if(TARGET wangle AND NOT TARGET wangle::wangle)
  add_library(wangle::wangle ALIAS wangle)
endif()
