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

FetchContent_DeclareGitHubWithMirror(lz4
  lz4/lz4 v1.10.0
  MD5=0ef5a1dfd7fe28c246275c043531165d
)

FetchContent_GetProperties(lz4)
if(NOT lz4_POPULATED)
  FetchContent_Populate(lz4)
  set(LZ4_BUILD_CLI OFF CACHE BOOL "" FORCE)
  add_subdirectory(${lz4_SOURCE_DIR}/build/cmake ${lz4_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# lz4's CMake creates unified 'lz4' INTERFACE target linking to lz4_static
# (when BUILD_SHARED_LIBS=OFF, which is our default)
