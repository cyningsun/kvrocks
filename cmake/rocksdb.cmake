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

# Set CONFIG-mode bridge dirs so RocksDB's find_package(folly) finds
# our add_subdirectory targets via bridge config files
set(folly_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/folly" CACHE PATH "" FORCE)
set(fmt_DIR "${PROJECT_SOURCE_DIR}/cmake/configs/fmt" CACHE PATH "" FORCE)

# LIBURING_INSTALL_DIR is already defined by cmake/liburing.cmake (included before us)
# Add it to CMAKE_PREFIX_PATH so RocksDB can find liburing
list(APPEND CMAKE_PREFIX_PATH ${LIBURING_INSTALL_DIR})

# Skip install rules to avoid export validation errors
# (RocksDB's install(EXPORT) includes zstd more than once)
set(CMAKE_SKIP_INSTALL_RULES ON)

FetchContent_MakeAvailableWithArgs(rocksdb
  CMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
  CMAKE_C_FLAGS=${CMAKE_C_FLAGS}
  CMAKE_MODULE_PATH=${PROJECT_SOURCE_DIR}/cmake/modules # to locate FindJeMalloc.cmake
  Snappy_DIR=${PROJECT_SOURCE_DIR}/cmake/configs/snappy
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

set(CMAKE_SKIP_INSTALL_RULES OFF)

add_library(rocksdb_with_headers INTERFACE)
target_include_directories(rocksdb_with_headers INTERFACE ${rocksdb_SOURCE_DIR}/include)
target_link_libraries(rocksdb_with_headers INTERFACE
  rocksdb
  # RocksDB declares these as PRIVATE (CMakeLists.txt line 1108);
  # static linking requires consumers to also link them.
  # Encapsulate here so the top-level CMakeLists.txt doesn't need to repeat them.
  snappy lz4 zstd zlib_with_headers
)

