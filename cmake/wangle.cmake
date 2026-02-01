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

# wangle - Facebook 的 C++ 网络库
# 依赖：folly, fizz, googletest
# 注意：wangle 的 CMakeLists.txt 在 wangle/wangle 子目录中
FetchContent_DeclareGitHubWithMirror(wangle
  facebook/wangle v2024.01.01.00
  MD5=6fac5569b0e71a5b3339479bdd384cc1
)

# 设置 wangle 的安装目录
set(WANGLE_INSTALL_DIR ${CMAKE_BINARY_DIR}/wangle-install)

if(NOT EXISTS ${WANGLE_INSTALL_DIR}/lib/libwangle.a)
  message(STATUS "Building and installing wangle (this may take a while)...")
  
  # 获取 wangle 源码
  FetchContent_GetProperties(wangle)
  if(NOT wangle_POPULATED)
    FetchContent_Populate(wangle)
  endif()
  
  # 配置 wangle（CMakeLists.txt 在 wangle/wangle 子目录）
  set(wangle_BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/wangle-build)
  
  # 构建 CMAKE_PREFIX_PATH（包括所有依赖）
  set(WANGLE_PREFIX_PATH "${FOLLY_INSTALL_DIR};${FIZZ_INSTALL_DIR};${FOLLY_FMT_INSTALL_DIR};${BOOST_INSTALL_DIR};${GFLAGS_INSTALL_DIR};${GLOG_INSTALL_DIR};${DOUBLE_CONVERSION_INSTALL_DIR}")
  
  # 设置 libevent 和 zstd 的路径
  set(LIBEVENT_INCLUDE_DIR "${libevent_SOURCE_DIR}/include;${libevent_BINARY_DIR}/include")
  set(LIBEVENT_LIB_DIR "${libevent_BINARY_DIR}/lib")
  set(ZSTD_INCLUDE_DIR "${zstd_SOURCE_DIR}/lib")
  set(ZSTD_LIBRARY "${zstd_SOURCE_DIR}/lib/libzstd.a")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${wangle_SOURCE_DIR}/wangle
      -B ${wangle_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${WANGLE_INSTALL_DIR}
      "-DCMAKE_PREFIX_PATH=${WANGLE_PREFIX_PATH}"
      "-DCMAKE_LIBRARY_PATH=${zstd_SOURCE_DIR}/lib"
      "-DCMAKE_INCLUDE_PATH=${ZSTD_INCLUDE_DIR}"
      "-DLIBEVENT_INCLUDE_DIR=${LIBEVENT_INCLUDE_DIR}"
      "-DLIBEVENT_LIB=${LIBEVENT_LIB_DIR}/libevent.a"
      "-DZSTD_INCLUDE_DIR=${ZSTD_INCLUDE_DIR}"
      "-DZSTD_LIBRARY_RELEASE=${ZSTD_LIBRARY}"
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
    RESULT_VARIABLE WANGLE_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/wangle_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/wangle_config_error.log
  )
  
  if(NOT WANGLE_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure wangle. Check ${CMAKE_BINARY_DIR}/wangle_config_error.log")
  endif()
  
  # 编译 wangle
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${wangle_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE WANGLE_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/wangle_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/wangle_build_error.log
  )
  
  if(NOT WANGLE_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build wangle. Check ${CMAKE_BINARY_DIR}/wangle_build_error.log")
  endif()
  
  # 安装 wangle
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${wangle_BINARY_DIR} --prefix ${WANGLE_INSTALL_DIR}
    RESULT_VARIABLE WANGLE_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/wangle_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/wangle_install_error.log
  )
  
  if(NOT WANGLE_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install wangle. Check ${CMAKE_BINARY_DIR}/wangle_install_error.log")
  endif()
  
  message(STATUS "wangle built and installed successfully")
else()
  message(STATUS "wangle already installed at ${WANGLE_INSTALL_DIR}")
endif()

# 将 wangle 的安装目录添加到 CMAKE_PREFIX_PATH
list(APPEND CMAKE_PREFIX_PATH ${WANGLE_INSTALL_DIR})
