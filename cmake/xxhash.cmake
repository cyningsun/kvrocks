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

FetchContent_DeclareGitHubWithMirror(xxhash
  Cyan4973/xxHash v0.8.3
  MD5=19b919a066c28a9121dd9767e01d0c71
)

# 获取 xxhash 源码
FetchContent_GetProperties(xxhash)
if(NOT xxhash_POPULATED)
  FetchContent_Populate(xxhash)
endif()

# 设置 xxhash 的安装目录
set(XXHASH_INSTALL_DIR ${CMAKE_BINARY_DIR}/xxhash-install)

if(NOT EXISTS ${XXHASH_INSTALL_DIR}/lib/libxxhash.a)
  message(STATUS "Building and installing xxhash...")
  
  # 配置 xxhash
  set(xxhash_BUILD_DIR ${CMAKE_BINARY_DIR}/_deps/xxhash-build)
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${xxhash_SOURCE_DIR}/cmake_unofficial
      -B ${xxhash_BUILD_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${XXHASH_INSTALL_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DXXHASH_BUILD_XXHSUM=OFF
    RESULT_VARIABLE XXHASH_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/xxhash_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/xxhash_config_error.log
  )
  
  if(NOT XXHASH_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure xxhash. Check ${CMAKE_BINARY_DIR}/xxhash_config_error.log")
  endif()
  
  # 编译 xxhash
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${xxhash_BUILD_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE XXHASH_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/xxhash_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/xxhash_build_error.log
  )
  
  if(NOT XXHASH_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build xxhash. Check ${CMAKE_BINARY_DIR}/xxhash_build_error.log")
  endif()
  
  # 安装 xxhash
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${xxhash_BUILD_DIR} --prefix ${XXHASH_INSTALL_DIR}
    RESULT_VARIABLE XXHASH_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/xxhash_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/xxhash_install_error.log
  )
  
  if(NOT XXHASH_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install xxhash. Check ${CMAKE_BINARY_DIR}/xxhash_install_error.log")
  endif()
  
  message(STATUS "xxhash built and installed successfully")
else()
  message(STATUS "xxhash already installed at ${XXHASH_INSTALL_DIR}")
endif()

# 将 xxhash 的安装目录添加到 CMAKE_PREFIX_PATH
# 这样 fbthrift 和 cachelib 可以通过 find_package(Xxhash) 找到它
list(APPEND CMAKE_PREFIX_PATH ${XXHASH_INSTALL_DIR})

# ============================================================================
# 为主项目创建 IMPORTED target
# ============================================================================
# 主项目需要 xxhash target，所以我们创建一个 IMPORTED 库
if(NOT TARGET xxhash)
  add_library(xxhash STATIC IMPORTED GLOBAL)
  set_target_properties(xxhash PROPERTIES
    IMPORTED_LOCATION "${XXHASH_INSTALL_DIR}/lib/libxxhash.a"
    INTERFACE_INCLUDE_DIRECTORIES "${XXHASH_INSTALL_DIR}/include"
  )
endif()
