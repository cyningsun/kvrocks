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

# 使用项目自定义函数声明 liburing 依赖
# 参数说明：
#   liburing - 依赖名称
#   axboe/liburing - GitHub 仓库路径
#   liburing-2.5 - 版本标签
#   MD5=... - 下载文件的 MD5 校验和
FetchContent_DeclareGitHubWithMirror(liburing
  axboe/liburing liburing-2.5
  MD5=4abbad551ae6b9857a2b0757d73cd7a1
)

# 获取 liburing 源码
FetchContent_GetProperties(liburing)
if(NOT liburing_POPULATED)
  FetchContent_Populate(liburing)
endif()

# ============================================================================
# 编译和安装 liburing
# ============================================================================
# liburing 使用 configure + make 构建系统，不是 CMake
# 我们需要单独编译并安装到指定目录

set(LIBURING_INSTALL_DIR ${CMAKE_BINARY_DIR}/liburing-install)

if(NOT EXISTS ${LIBURING_INSTALL_DIR}/lib/liburing.a)
  message(STATUS "Building and installing liburing 2.5...")
  
  # liburing 使用 ./configure && make && make install
  # 配置 liburing
  execute_process(
    COMMAND ${liburing_SOURCE_DIR}/configure
      --prefix=${LIBURING_INSTALL_DIR}
      --libdir=${LIBURING_INSTALL_DIR}/lib
      --includedir=${LIBURING_INSTALL_DIR}/include
    WORKING_DIRECTORY ${liburing_SOURCE_DIR}
    RESULT_VARIABLE LIBURING_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/liburing_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/liburing_config_error.log
  )
  
  if(NOT LIBURING_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure liburing. Check ${CMAKE_BINARY_DIR}/liburing_config_error.log")
  endif()
  
  # 编译 liburing
  execute_process(
    COMMAND make -j4
    WORKING_DIRECTORY ${liburing_SOURCE_DIR}
    RESULT_VARIABLE LIBURING_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/liburing_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/liburing_build_error.log
  )
  
  if(NOT LIBURING_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build liburing. Check ${CMAKE_BINARY_DIR}/liburing_build_error.log")
  endif()
  
  # 安装 liburing
  execute_process(
    COMMAND make install
    WORKING_DIRECTORY ${liburing_SOURCE_DIR}
    RESULT_VARIABLE LIBURING_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/liburing_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/liburing_install_error.log
  )
  
  if(NOT LIBURING_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install liburing. Check ${CMAKE_BINARY_DIR}/liburing_install_error.log")
  endif()
  
  message(STATUS "liburing 2.5 built and installed successfully to ${LIBURING_INSTALL_DIR}")
else()
  message(STATUS "liburing already installed at ${LIBURING_INSTALL_DIR}")
endif()

# ============================================================================
# 重要：不要将 LIBURING_INSTALL_DIR 添加到全局 CMAKE_PREFIX_PATH
# ============================================================================
# 这样可以防止 Folly 在配置时找到 liburing
# 只有显式需要 liburing 的库（如 RocksDB）才能通过手动设置路径来使用它
#
# 不要取消下面这行的注释：
# list(APPEND CMAKE_PREFIX_PATH ${LIBURING_INSTALL_DIR})

message(STATUS "liburing installed to ${LIBURING_INSTALL_DIR} (not added to CMAKE_PREFIX_PATH)")

# Create IMPORTED target for liburing
if(NOT TARGET liburing::liburing)
  add_library(liburing::liburing STATIC IMPORTED GLOBAL)
  set_target_properties(liburing::liburing PROPERTIES
    IMPORTED_LOCATION "${LIBURING_INSTALL_DIR}/lib/liburing.a"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBURING_INSTALL_DIR}/include"
  )
endif()
