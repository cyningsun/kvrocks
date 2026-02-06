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

set(COMPILE_WITH_JEMALLOC ON)

if (DISABLE_JEMALLOC)
  set(COMPILE_WITH_JEMALLOC OFF)
endif()

include(cmake/utils.cmake)

FetchContent_DeclareGitHubWithMirror(rocksdb
  facebook/rocksdb v8.8.1
  MD5=15cd02d457b35da07947113de5304270
)

FetchContent_GetProperties(jemalloc)
FetchContent_GetProperties(snappy)
FetchContent_GetProperties(tbb)

# Get folly and its dependencies installation directories
# Note: folly must be built before rocksdb when USE_COROUTINES is enabled
set(FOLLY_INSTALL_DIR ${CMAKE_BINARY_DIR}/folly-install)
set(FMT_INSTALL_DIR ${CMAKE_BINARY_DIR}/fmt-install)
set(GLOG_INSTALL_DIR ${CMAKE_BINARY_DIR}/glog-install)
set(GFLAGS_INSTALL_DIR ${CMAKE_BINARY_DIR}/gflags-install)
set(BOOST_INSTALL_DIR ${CMAKE_BINARY_DIR}/boost-install)

# Add folly and its dependencies to CMAKE_PREFIX_PATH
# so RocksDB can find them when USE_COROUTINES is enabled
list(APPEND CMAKE_PREFIX_PATH ${FOLLY_INSTALL_DIR})
list(APPEND CMAKE_PREFIX_PATH ${FMT_INSTALL_DIR})
list(APPEND CMAKE_PREFIX_PATH ${GLOG_INSTALL_DIR})
list(APPEND CMAKE_PREFIX_PATH ${GFLAGS_INSTALL_DIR})
list(APPEND CMAKE_PREFIX_PATH ${BOOST_INSTALL_DIR})

FetchContent_MakeAvailableWithArgs(rocksdb
  CMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
  CMAKE_C_FLAGS=${CMAKE_C_FLAGS}
  CMAKE_MODULE_PATH=${PROJECT_SOURCE_DIR}/cmake/modules # to locate FindJeMalloc.cmake
  Snappy_DIR=${PROJECT_SOURCE_DIR}/cmake/modules # to locate SnappyConfig.cmake
  FAIL_ON_WARNINGS=OFF
  WITH_TESTS=OFF
  WITH_BENCHMARK_TOOLS=OFF
  WITH_CORE_TOOLS=OFF
  WITH_TOOLS=OFF
  WITH_SNAPPY=ON
  WITH_LZ4=ON
  WITH_ZLIB=ON
  WITH_ZSTD=ON
  WITH_GFLAGS=OFF
  WITH_TBB=ON
  WITH_LIBURING=ON
  USE_FOLLY=ON
  USE_RTTI=ON
  ROCKSDB_BUILD_SHARED=OFF
  WITH_JEMALLOC=${COMPILE_WITH_JEMALLOC}
  PORTABLE=1
)

add_library(rocksdb_with_headers INTERFACE)
target_include_directories(rocksdb_with_headers INTERFACE ${rocksdb_SOURCE_DIR}/include)
target_link_libraries(rocksdb_with_headers INTERFACE rocksdb)

