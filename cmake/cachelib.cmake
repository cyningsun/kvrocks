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

# CacheLib - Facebook 的缓存库
# 依赖：folly, fizz, wangle, mvfst, fbthrift, boost, gflags, glog, fmt, zstd, googletest, sparsemap
FetchContent_Declare(cachelib
  URL https://github.com/facebook/CacheLib/archive/refs/tags/v2024.02.26.00.tar.gz
)

# ============================================================================
# 步骤 1: 获取 sparsemap（CacheLib 需要的 header-only 库）
# ============================================================================
# 注意：zstd 已在 folly.cmake 中编译和安装，使用 ${ZSTD_INSTALL_DIR}
set(ZSTD_INSTALL_DIR ${CMAKE_BINARY_DIR}/zstd-install)

FetchContent_Declare(sparsemap
  URL https://github.com/Tessil/sparse-map/archive/refs/tags/v0.7.0.tar.gz
  URL_HASH MD5=a361fa30bde607a09e3422670be9c82e
)

FetchContent_GetProperties(sparsemap)
if(NOT sparsemap_POPULATED)
  FetchContent_Populate(sparsemap)
  message(STATUS "sparsemap downloaded to: ${sparsemap_SOURCE_DIR}")
endif()

# 导出 sparsemap 路径供主项目使用
set(SPARSEMAP_INCLUDE_DIR ${sparsemap_SOURCE_DIR}/include CACHE PATH "Sparsemap include directory")

# ============================================================================
# 步骤 2: 编译和安装 GoogleTest（CacheLib 需要）
# ============================================================================
# 注意：gtest.cmake 已经声明了 googletest，但没有安装
# 这里为 CacheLib 单独编译并安装一份到独立目录（参考 folly.cmake 对 glog 的处理）

set(GOOGLETEST_INSTALL_DIR ${CMAKE_BINARY_DIR}/googletest-install CACHE PATH "GoogleTest install directory")

if(NOT EXISTS ${GOOGLETEST_INSTALL_DIR}/lib/libgtest.a)
  message(STATUS "Building and installing GoogleTest for CacheLib...")
  
  # 获取 GoogleTest 源码（复用 gtest.cmake 的声明）
  FetchContent_GetProperties(gtest)
  if(NOT gtest_POPULATED)
    FetchContent_Populate(gtest)
  endif()
  
  # 设置 GoogleTest 的二进制目录
  set(googletest_INSTALL_BINARY_DIR ${CMAKE_BINARY_DIR}/googletest-install-build)
  
  # 配置 GoogleTest
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${gtest_SOURCE_DIR}
      -B ${googletest_INSTALL_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${GOOGLETEST_INSTALL_DIR}
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_GMOCK=ON
      -DINSTALL_GTEST=ON
    RESULT_VARIABLE GOOGLETEST_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/googletest_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/googletest_config_error.log
  )
  
  if(NOT GOOGLETEST_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure GoogleTest. Check ${CMAKE_BINARY_DIR}/googletest_config_error.log")
  endif()
  
  # 编译 GoogleTest
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${googletest_INSTALL_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE GOOGLETEST_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/googletest_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/googletest_build_error.log
  )
  
  if(NOT GOOGLETEST_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build GoogleTest. Check ${CMAKE_BINARY_DIR}/googletest_build_error.log")
  endif()
  
  # 安装 GoogleTest
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${googletest_INSTALL_BINARY_DIR} --prefix ${GOOGLETEST_INSTALL_DIR}
    RESULT_VARIABLE GOOGLETEST_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/googletest_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/googletest_install_error.log
  )
  
  if(NOT GOOGLETEST_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install GoogleTest. Check ${CMAKE_BINARY_DIR}/googletest_install_error.log")
  endif()
  
  message(STATUS "GoogleTest built and installed successfully for CacheLib")
else()
  message(STATUS "GoogleTest already installed at ${GOOGLETEST_INSTALL_DIR}")
endif()

# ============================================================================
# 步骤 3: 配置和安装 CacheLib
# ============================================================================

# 设置 CacheLib 的安装目录
set(CACHELIB_INSTALL_DIR ${CMAKE_BINARY_DIR}/cachelib-install CACHE PATH "CacheLib install directory")

if(NOT EXISTS ${CACHELIB_INSTALL_DIR}/lib/libcachelib_allocator.a)
  message(STATUS "Building and installing CacheLib (this may take a while)...")
  
  # 获取 CacheLib 源码
  FetchContent_GetProperties(cachelib)
  if(NOT cachelib_POPULATED)
    FetchContent_Populate(cachelib)
    message(STATUS "CacheLib source downloaded to: ${cachelib_SOURCE_DIR}")
  endif()
  
  # 配置 CacheLib
  set(cachelib_BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/cachelib-build)
  
  # 构建 CMAKE_PREFIX_PATH（包括所有依赖）
  set(CACHELIB_PREFIX_PATH "${FOLLY_INSTALL_DIR};${FIZZ_INSTALL_DIR};${WANGLE_INSTALL_DIR};${MVFST_INSTALL_DIR};${FBTHRIFT_INSTALL_DIR};${FOLLY_FMT_INSTALL_DIR};${BOOST_INSTALL_DIR};${GFLAGS_INSTALL_DIR};${GLOG_INSTALL_DIR};${DOUBLE_CONVERSION_INSTALL_DIR};${GOOGLETEST_INSTALL_DIR};${ZSTD_INSTALL_DIR}")
  
  # 设置 libevent 和 zstd 的路径（它们已单独安装）
  set(LIBEVENT_INCLUDE_DIR "${LIBEVENT_INSTALL_DIR}/include")
  set(LIBEVENT_LIB_DIR "${LIBEVENT_INSTALL_DIR}/lib")
  set(ZSTD_INCLUDE_DIRS "${ZSTD_INSTALL_DIR}/include")
  set(ZSTD_LIBRARIES "${ZSTD_INSTALL_DIR}/lib/libzstd.a")
  
  message(STATUS "CacheLib dependencies status:")
  message(STATUS "  ✅ folly, fizz, wangle, mvfst, fbthrift - available")
  message(STATUS "  ✅ boost, gflags, glog, fmt, googletest - available")
  message(STATUS "  ✅ zstd, libevent, sparsemap - available")
  message(STATUS "  ⚠️  NUMA, libaio - optional, will check at runtime")
  
  execute_process(
    COMMAND ${CMAKE_COMMAND}
      -S ${cachelib_SOURCE_DIR}/cachelib
      -B ${cachelib_BINARY_DIR}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_PREFIX=${CACHELIB_INSTALL_DIR}
      "-DCMAKE_PREFIX_PATH=${CACHELIB_PREFIX_PATH}"
      "-DCMAKE_PROGRAM_PATH=${FBTHRIFT_INSTALL_DIR}/bin"
      "-DCMAKE_LIBRARY_PATH=${ZSTD_INSTALL_DIR}/lib"
      "-DCMAKE_INCLUDE_PATH=${ZSTD_INCLUDE_DIRS};${GOOGLETEST_INSTALL_DIR}/include;${sparsemap_SOURCE_DIR}/include"
      "-DCMAKE_CXX_FLAGS=-I${GOOGLETEST_INSTALL_DIR}/include -I${sparsemap_SOURCE_DIR}/include"
      "-DCMAKE_C_FLAGS=-I${GOOGLETEST_INSTALL_DIR}/include -I${sparsemap_SOURCE_DIR}/include"
      "-DLIBEVENT_INCLUDE_DIR=${LIBEVENT_INCLUDE_DIR}"
      "-DLIBEVENT_LIB=${LIBEVENT_LIB_DIR}/libevent.a"
      "-DZSTD_ROOT=${ZSTD_INSTALL_DIR}"
      "-DZSTD_INCLUDE_DIRS=${ZSTD_INCLUDE_DIRS}"
      "-DZSTD_LIBRARIES=${ZSTD_LIBRARIES}"
      -DBUILD_SHARED_LIBS=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
    RESULT_VARIABLE CACHELIB_CONFIG_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/cachelib_config.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/cachelib_config_error.log
  )
  
  if(NOT CACHELIB_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to configure CacheLib. Check ${CMAKE_BINARY_DIR}/cachelib_config_error.log")
  endif()
  
  # 编译 CacheLib
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${cachelib_BINARY_DIR} --config ${CMAKE_BUILD_TYPE} -j4
    RESULT_VARIABLE CACHELIB_BUILD_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/cachelib_build.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/cachelib_build_error.log
  )
  
  if(NOT CACHELIB_BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to build CacheLib. Check ${CMAKE_BINARY_DIR}/cachelib_build_error.log")
  endif()
  
  # 安装 CacheLib
  execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${cachelib_BINARY_DIR} --prefix ${CACHELIB_INSTALL_DIR}
    RESULT_VARIABLE CACHELIB_INSTALL_RESULT
    OUTPUT_FILE ${CMAKE_BINARY_DIR}/cachelib_install.log
    ERROR_FILE ${CMAKE_BINARY_DIR}/cachelib_install_error.log
  )
  
  if(NOT CACHELIB_INSTALL_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to install CacheLib. Check ${CMAKE_BINARY_DIR}/cachelib_install_error.log")
  endif()
  
  message(STATUS "CacheLib built and installed successfully")
else()
  message(STATUS "CacheLib already installed at ${CACHELIB_INSTALL_DIR}")
endif()

# 将 CacheLib 的安装目录添加到 CMAKE_PREFIX_PATH
list(APPEND CMAKE_PREFIX_PATH ${CACHELIB_INSTALL_DIR})

# 设置变量供其他模块使用
set(CACHELIB_FOUND TRUE CACHE BOOL "CacheLib found")
set(CACHELIB_SOURCE_DIR ${cachelib_SOURCE_DIR} CACHE PATH "CacheLib source directory")
set(CACHELIB_BINARY_DIR ${cachelib_BINARY_DIR} CACHE PATH "CacheLib binary directory")