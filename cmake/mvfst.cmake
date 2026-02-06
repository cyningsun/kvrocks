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

# mvfst - Facebook 的 QUIC 传输协议实现
# 依赖：folly, fizz, googletest
FetchContent_DeclareGitHubWithMirror(mvfst
  facebook/mvfst v2024.02.19.00
  MD5=f62a8b28fa3febdd7dc498de10b39d87
)

# 设置 mvfst 的安装目录
set(MVFST_INSTALL_DIR ${CMAKE_BINARY_DIR}/mvfst-install)

if(NOT EXISTS ${MVFST_INSTALL_DIR}/lib/libmvfst_transport.a)
  message(STATUS "Building and installing mvfst (this may take a while)...")
  
  # 获取 mvfst 源码
  FetchContent_GetProperties(mvfst)
  if(NOT mvfst_POPULATED)
    FetchContent_Populate(mvfst)
  endif()
  
  # 配置 mvfst
  set(mvfst_BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/mvfst-build)
  
  # 构建 CMAKE_PREFIX_PATH（包括所有依赖）
  set(MVFST_PREFIX_PATH "${FOLLY_INSTALL_DIR};${FIZZ_INSTALL_DIR};${FMT_INSTALL_DIR};${BOOST_INSTALL_DIR};${GFLAGS_INSTALL_DIR};${GLOG_INSTALL_DIR};${DOUBLE_CONVERSION_INSTALL_DIR};${LIBEVENT_INSTALL_DIR}")
  
  # 设置 libevent 和 zstd 的路径
  # libevent 使用已安装的版本（由 folly.cmake 编译和安装）
  set(LIBEVENT_INCLUDE_DIR "${LIBEVENT_INSTALL_DIR}/include")
  set(LIBEVENT_LIB_DIR "${LIBEVENT_INSTALL_DIR}/lib")
  # zstd 使用已安装的版本（由 cachelib.cmake 编译和安装）
  set(ZSTD_INSTALL_DIR ${CMAKE_BINARY_DIR}/zstd-install)
  set(ZSTD_INCLUDE_DIR "${ZSTD_INSTALL_DIR}/include")
  set(ZSTD_LIBRARY "${ZSTD_INSTALL_DIR}/lib/libzstd.a")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${mvfst_SOURCE_DIR}
      -B ${mvfst_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${MVFST_INSTALL_DIR}
      "-DCMAKE_PREFIX_PATH=${MVFST_PREFIX_PATH}"
      "-DCMAKE_LIBRARY_PATH=${ZSTD_INSTALL_DIR}/lib"
      "-DCMAKE_INCLUDE_PATH=${ZSTD_INCLUDE_DIR}"
      "-DLIBEVENT_INCLUDE_DIR=${LIBEVENT_INCLUDE_DIR}"
      "-DLIBEVENT_LIB=${LIBEVENT_LIB_DIR}/libevent.a"
      "-DZSTD_INCLUDE_DIR=${ZSTD_INCLUDE_DIR}"
      "-DZSTD_LIBRARY_RELEASE=${ZSTD_LIBRARY}"
      # 使用统一的编译标志
      "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}"
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
    RESULT_VARIABLE MVFST_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/mvfst_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/mvfst_config_error.log
  )
  
  if(NOT MVFST_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure mvfst. Check ${CMAKE_BINARY_DIR}/mvfst_config_error.log")
  endif()
  
  # 编译 mvfst
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${mvfst_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE MVFST_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/mvfst_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/mvfst_build_error.log
  )
  
  if(NOT MVFST_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build mvfst. Check ${CMAKE_BINARY_DIR}/mvfst_build_error.log")
  endif()
  
  # 安装 mvfst
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${mvfst_BINARY_DIR} --prefix ${MVFST_INSTALL_DIR}
    RESULT_VARIABLE MVFST_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/mvfst_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/mvfst_install_error.log
  )
  
  if(NOT MVFST_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install mvfst. Check ${CMAKE_BINARY_DIR}/mvfst_install_error.log")
  endif()
  
  message(STATUS "mvfst built and installed successfully")
else()
  message(STATUS "mvfst already installed at ${MVFST_INSTALL_DIR}")
endif()

# 将 mvfst 的安装目录添加到 CMAKE_PREFIX_PATH
list(APPEND CMAKE_PREFIX_PATH ${MVFST_INSTALL_DIR})

