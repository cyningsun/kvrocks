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

FetchContent_DeclareGitHubWithMirror(zstd
  facebook/zstd v1.5.7
  MD5=2a98f5f27ec041e8b442382103229f44
)

FetchContent_GetProperties(zstd)
if(NOT zstd_POPULATED)
  FetchContent_Populate(zstd)
  set(ZSTD_BUILD_PROGRAMS OFF CACHE BOOL "" FORCE)
  set(ZSTD_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(ZSTD_BUILD_SHARED OFF CACHE BOOL "" FORCE)
  set(ZSTD_BUILD_STATIC ON CACHE BOOL "" FORCE)
  add_subdirectory(${zstd_SOURCE_DIR}/build/cmake ${zstd_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# zstd's CMake creates 'libzstd' INTERFACE target linking to libzstd_static.
# Create a 'zstd' wrapper target for backward compatibility with our code.
add_library(zstd INTERFACE)
target_link_libraries(zstd INTERFACE libzstd)
