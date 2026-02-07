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

# Bridge FindBoost: maps Boost add_subdirectory targets to FindBoost output variables.
# This replaces CMake's built-in FindBoost.cmake when Boost is available as
# add_subdirectory targets (Boost::headers, Boost::context, etc.)

if(NOT TARGET Boost::headers)
  # Boost targets not available via add_subdirectory, cannot bridge.
  # Fall back to CMake's built-in FindBoost by temporarily removing our
  # modules directory from CMAKE_MODULE_PATH.
  set(_kvrocks_modules_dir "${CMAKE_CURRENT_LIST_DIR}")
  list(REMOVE_ITEM CMAKE_MODULE_PATH "${_kvrocks_modules_dir}")
  find_package(Boost ${Boost_FIND_VERSION} MODULE
    COMPONENTS ${Boost_FIND_COMPONENTS}
  )
  list(APPEND CMAKE_MODULE_PATH "${_kvrocks_modules_dir}")
  unset(_kvrocks_modules_dir)
  return()
endif()

set(Boost_FOUND TRUE)
set(BOOST_FOUND TRUE)
# NOTE: Keep these version numbers in sync with cmake/boost.cmake's FetchContent version.
set(Boost_VERSION_STRING "1.83.0")
set(Boost_VERSION_MACRO 108300)
set(Boost_LIB_VERSION "1_83")
set(Boost_MAJOR_VERSION 1)
set(Boost_MINOR_VERSION 83)
set(Boost_SUBMINOR_VERSION 0)
set(Boost_VERSION "${Boost_VERSION_STRING}")

# Include dirs will be propagated by target linkage.
# Set to empty - folly_deps gets includes from target_link_libraries.
set(Boost_INCLUDE_DIRS "")
set(Boost_INCLUDE_DIR "")

# Map requested components to targets
set(Boost_LIBRARIES "")

# Always include Boost::boost (our aggregate target) so that ALL Boost headers
# are available. In modular Boost (add_subdirectory), each library's headers are
# in libs/*/include/ and only available through their individual targets.
# Boost::boost aggregates all of them, matching the behavior of installed Boost.
if(TARGET Boost::boost)
  list(APPEND Boost_LIBRARIES Boost::boost)
endif()

if(DEFINED Boost_FIND_COMPONENTS)
  foreach(_comp IN LISTS Boost_FIND_COMPONENTS)
    string(TOUPPER "${_comp}" _COMP)
    if(TARGET Boost::${_comp})
      set(Boost_${_COMP}_FOUND TRUE)
      set(Boost_${_comp}_FOUND TRUE)
      list(APPEND Boost_LIBRARIES Boost::${_comp})
    elseif(TARGET Boost::headers)
      # Header-only component (e.g. system, regex in modern Boost)
      set(Boost_${_COMP}_FOUND TRUE)
      set(Boost_${_comp}_FOUND TRUE)
      list(APPEND Boost_LIBRARIES Boost::headers)
    else()
      set(Boost_${_COMP}_FOUND FALSE)
      set(Boost_${_comp}_FOUND FALSE)
      if(Boost_FIND_REQUIRED_${_comp})
        set(Boost_FOUND FALSE)
        message(FATAL_ERROR "Required Boost component '${_comp}' not found as target")
      endif()
    endif()
  endforeach()
  list(REMOVE_DUPLICATES Boost_LIBRARIES)
endif()

if(NOT Boost_FIND_QUIETLY)
  message(STATUS "Found Boost (bridge): version ${Boost_VERSION_STRING}, components: ${Boost_FIND_COMPONENTS}")
endif()
