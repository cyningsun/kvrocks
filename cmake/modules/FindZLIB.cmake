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

# used for `find_package(ZLIB)` mechanism in rocksdb

if(zlib_SOURCE_DIR)
  message(STATUS "Found zlib in ${zlib_SOURCE_DIR}")

  if(NOT TARGET zlib_with_headers)
    add_library(zlib_with_headers INTERFACE) # rocksdb use it
    target_include_directories(zlib_with_headers INTERFACE $<BUILD_INTERFACE:${zlib_SOURCE_DIR}> $<BUILD_INTERFACE:${zlib_BINARY_DIR}>)
    target_link_libraries(zlib_with_headers INTERFACE zlib-ng)
    install(TARGETS zlib-ng zlib_with_headers EXPORT RocksDBTargets) # export for install(...)
  endif()
  if(NOT TARGET ZLIB::ZLIB)
    add_library(ZLIB::ZLIB ALIAS zlib_with_headers)
  endif()

  set(ZLIB_FOUND TRUE)
  set(ZLIB_INCLUDE_DIRS "${zlib_SOURCE_DIR}" "${zlib_BINARY_DIR}")
  set(ZLIB_LIBRARIES zlib_with_headers)
endif()
