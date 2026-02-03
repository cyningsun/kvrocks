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

# 防止重复包含此文件
include_guard()

# 引入项目的工具函数库
include(cmake/utils.cmake)

# fbthrift - Facebook 的 Thrift RPC 框架
# 依赖：folly, fizz, wangle, mvfst, xxhash, zstd, fmt, libsodium
FetchContent_DeclareGitHubWithMirror(fbthrift
  facebook/fbthrift v2024.02.19.00
  MD5=8212308c85fde7a2fff109f32a9b3f69
)

# 设置 fbthrift 的安装目录
set(FBTHRIFT_INSTALL_DIR ${CMAKE_BINARY_DIR}/fbthrift-install)

if(NOT EXISTS ${FBTHRIFT_INSTALL_DIR}/lib/libthriftcpp2.a)
  message(STATUS "Building and installing fbthrift (this may take a while)...")
  
  # 获取 fbthrift 源码
  FetchContent_GetProperties(fbthrift)
  if(NOT fbthrift_POPULATED)
    FetchContent_Populate(fbthrift)
  endif()
  
  # 配置 fbthrift
  set(fbthrift_BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/fbthrift-build)
  
  # 构建 CMAKE_PREFIX_PATH（包括所有依赖）
  set(FBTHRIFT_PREFIX_PATH "${FOLLY_INSTALL_DIR};${FIZZ_INSTALL_DIR};${WANGLE_INSTALL_DIR};${MVFST_INSTALL_DIR};${FOLLY_FMT_INSTALL_DIR};${BOOST_INSTALL_DIR};${GFLAGS_INSTALL_DIR};${GLOG_INSTALL_DIR};${DOUBLE_CONVERSION_INSTALL_DIR};${LIBEVENT_INSTALL_DIR}")
  
  # 设置 libevent 和 zstd 的路径
  # libevent 使用已安装的版本（由 folly.cmake 编译和安装）
  set(LIBEVENT_INCLUDE_DIR "${LIBEVENT_INSTALL_DIR}/include")
  set(LIBEVENT_LIB_DIR "${LIBEVENT_INSTALL_DIR}/lib")
  # zstd 使用已安装的版本（由 cachelib.cmake 编译和安装）
  set(ZSTD_INSTALL_DIR ${CMAKE_BINARY_DIR}/zstd-install)
  set(ZSTD_INCLUDE_DIRS "${ZSTD_INSTALL_DIR}/include")
  set(ZSTD_LIBRARIES "${ZSTD_INSTALL_DIR}/lib/libzstd.a")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${fbthrift_SOURCE_DIR}
      -B ${fbthrift_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${FBTHRIFT_INSTALL_DIR}
      "-DCMAKE_PREFIX_PATH=${FBTHRIFT_PREFIX_PATH}"
      "-DCMAKE_LIBRARY_PATH=${ZSTD_INSTALL_DIR}/lib"
      "-DLIBEVENT_INCLUDE_DIR=${LIBEVENT_INCLUDE_DIR}"
      "-DLIBEVENT_LIB=${LIBEVENT_LIB_DIR}/libevent.a"
      "-DZSTD_ROOT=${ZSTD_INSTALL_DIR}"
      "-DZSTD_INCLUDE_DIRS=${ZSTD_INCLUDE_DIRS}"
      "-DZSTD_LIBRARIES=${ZSTD_LIBRARIES}"
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
    RESULT_VARIABLE FBTHRIFT_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fbthrift_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fbthrift_config_error.log
  )
  
  if(NOT FBTHRIFT_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure fbthrift. Check ${CMAKE_BINARY_DIR}/fbthrift_config_error.log")
  endif()
  
  # 编译 fbthrift
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${fbthrift_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE FBTHRIFT_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fbthrift_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fbthrift_build_error.log
  )
  
  if(NOT FBTHRIFT_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build fbthrift. Check ${CMAKE_BINARY_DIR}/fbthrift_build_error.log")
  endif()
  
  # 安装 fbthrift
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${fbthrift_BINARY_DIR} --prefix ${FBTHRIFT_INSTALL_DIR}
    RESULT_VARIABLE FBTHRIFT_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fbthrift_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fbthrift_install_error.log
  )
  
  if(NOT FBTHRIFT_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install fbthrift. Check ${CMAKE_BINARY_DIR}/fbthrift_install_error.log")
  endif()
  
  message(STATUS "fbthrift built and installed successfully")
else()
  message(STATUS "fbthrift already installed at ${FBTHRIFT_INSTALL_DIR}")
endif()

# 将 fbthrift 的安装目录添加到 CMAKE_PREFIX_PATH
list(APPEND CMAKE_PREFIX_PATH ${FBTHRIFT_INSTALL_DIR})
