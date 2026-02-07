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

FetchContent_DeclareGitHubWithMirror(cpptrace
  jeremy-rifkin/cpptrace v1.0.3
  MD5=b23b986fb2b4398adf0bba2e1e894b8d
)

if (SYMBOLIZE_BACKEND STREQUAL "libbacktrace")
  set(CPPTRACE_BACKEND_OPTION "CPPTRACE_GET_SYMBOLS_WITH_LIBBACKTRACE=ON")
elseif (SYMBOLIZE_BACKEND STREQUAL "libdwarf")
  set(CPPTRACE_BACKEND_OPTION "CPPTRACE_GET_SYMBOLS_WITH_LIBDWARF=ON")
else ()
  set(CPPTRACE_BACKEND_OPTION "CPPTRACE_GET_SYMBOLS_WITH_ADDR2LINE=ON")
endif ()

FetchContent_MakeAvailableWithArgs(cpptrace
  ${CPPTRACE_BACKEND_OPTION}
  CPPTRACE_DISABLE_CXX_20_MODULES=ON
)

# Wrap Backtrace find results as an IMPORTED target for modern CMake usage.
# Backtrace_LIBRARY and Backtrace_INCLUDE_DIR are set by CMake's built-in
# FindBacktrace module; wrap them so consumers use a target, not variables.
if(NOT TARGET Backtrace::backtrace)
  add_library(Backtrace::backtrace INTERFACE IMPORTED GLOBAL)
  if(Backtrace_LIBRARY)
    set_target_properties(Backtrace::backtrace PROPERTIES
      INTERFACE_LINK_LIBRARIES "${Backtrace_LIBRARY}"
    )
  endif()
  if(Backtrace_INCLUDE_DIR)
    set_target_properties(Backtrace::backtrace PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${Backtrace_INCLUDE_DIR}"
    )
  endif()
endif()
