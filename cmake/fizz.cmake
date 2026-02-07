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

# fizz - Facebook 的 TLS 1.3 实现
# 依赖：folly, libsodium, liboqs, zstd
FetchContent_DeclareGitHubWithMirror(fizz
  facebookincubator/fizz v2025.07.28.00
  MD5=e1ad09d50585ff9dec4b87ed3549a95c
)

# 设置 fizz 的安装目录
set(FIZZ_INSTALL_DIR ${CMAKE_BINARY_DIR}/fizz-install)

if(NOT EXISTS ${FIZZ_INSTALL_DIR}/lib/libfizz.a)
  message(STATUS "Building and installing fizz (this may take a while)...")
  
  # 获取 fizz 源码
  FetchContent_GetProperties(fizz)
  if(NOT fizz_POPULATED)
    FetchContent_Populate(fizz)
  endif()
  
  # 配置 fizz（CMakeLists.txt 在 fizz/fizz 子目录）
  set(fizz_BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/fizz-build)
  
  # 构建 CMAKE_PREFIX_PATH（包括所有依赖）
  set(FIZZ_PREFIX_PATH "${FOLLY_INSTALL_DIR};${FMT_INSTALL_DIR};${BOOST_INSTALL_DIR};${GFLAGS_INSTALL_DIR};${GLOG_INSTALL_DIR};${DOUBLE_CONVERSION_INSTALL_DIR};${LIBEVENT_INSTALL_DIR}")
  
  # 设置 libevent 和 zstd 的路径
  # libevent 使用已安装的版本（由 folly.cmake 编译和安装）
  set(LIBEVENT_INCLUDE_DIR "${LIBEVENT_INSTALL_DIR}/include")
  set(LIBEVENT_LIB_DIR "${LIBEVENT_INSTALL_DIR}/lib")
  # zstd 使用已安装的版本（由 cachelib.cmake 编译和安装）
  set(ZSTD_INSTALL_DIR ${CMAKE_BINARY_DIR}/zstd-install)
  set(ZSTD_INCLUDE_DIR "${ZSTD_INSTALL_DIR}/include")
  set(ZSTD_LIBRARY "${ZSTD_INSTALL_DIR}/lib/libzstd.a")
  
  # 设置环境变量以帮助 find_library 找到 zstd
  set(ENV{CMAKE_PREFIX_PATH} "${ZSTD_INSTALL_DIR}/lib")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${fizz_SOURCE_DIR}/fizz
      -B ${fizz_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${FIZZ_INSTALL_DIR}
      "-DCMAKE_PREFIX_PATH=${FIZZ_PREFIX_PATH}"
      "-DCMAKE_LIBRARY_PATH=${ZSTD_INSTALL_DIR}/lib"
      "-DCMAKE_INCLUDE_PATH=${ZSTD_INCLUDE_DIR}"
      "-DLIBEVENT_INCLUDE_DIR=${LIBEVENT_INCLUDE_DIR}"
      "-DLIBEVENT_LIB=${LIBEVENT_LIB_DIR}/libevent.a"
      "-DLIBEVENT_CORE_LIB=${LIBEVENT_LIB_DIR}/libevent_core.a"
      "-DZSTD_INCLUDE_DIR=${ZSTD_INCLUDE_DIR}"
      "-DZSTD_LIBRARY=${ZSTD_LIBRARY}"
      "-DZSTD_LIBRARY_RELEASE=${ZSTD_LIBRARY}"
      # 使用统一的编译标志并添加 AEGIS include 路径
      "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} -I${fizz_SOURCE_DIR}/fizz/third-party/libsodium-aegis"
      "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -I${fizz_SOURCE_DIR}/fizz/third-party/libsodium-aegis"
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
      -DFIZZ_BUILD_AEGIS=OFF
    RESULT_VARIABLE FIZZ_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fizz_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fizz_config_error.log
  )
  
  if(NOT FIZZ_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure fizz. Check ${CMAKE_BINARY_DIR}/fizz_config_error.log")
  endif()
  
  # 编译 fizz
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${fizz_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE FIZZ_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fizz_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fizz_build_error.log
  )
  
  if(NOT FIZZ_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build fizz. Check ${CMAKE_BINARY_DIR}/fizz_build_error.log")
  endif()
  
  # 安装 fizz
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${fizz_BINARY_DIR} --prefix ${FIZZ_INSTALL_DIR}
    RESULT_VARIABLE FIZZ_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/fizz_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/fizz_install_error.log
  )
  
  if(NOT FIZZ_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install fizz. Check ${CMAKE_BINARY_DIR}/fizz_install_error.log")
  endif()
  
  message(STATUS "fizz built and installed successfully")
else()
  message(STATUS "fizz already installed at ${FIZZ_INSTALL_DIR}")
endif()

# 将 fizz 的安装目录添加到 CMAKE_PREFIX_PATH
list(APPEND CMAKE_PREFIX_PATH ${FIZZ_INSTALL_DIR})

