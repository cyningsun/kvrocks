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

# Bridge FindLibEvent: maps libevent add_subdirectory targets to expected variables.
# This intercepts find_package(LibEvent MODULE REQUIRED) from FB libraries.

if(TARGET event_core_static)
  set(LibEvent_FOUND TRUE)
  set(LIBEVENT_FOUND TRUE)

  # Use target name directly - works in target_link_libraries.
  # Include directories are propagated automatically via the event_core_static target
  # (libevent's AddEventLibrary.cmake sets PUBLIC target_include_directories).
  set(LIBEVENT_LIB event_core_static)
  set(LIBEVENT_LIBRARIES event_core_static)

  if(NOT LibEvent_FIND_QUIETLY)
    message(STATUS "Found libevent (bridge): event_core_static target")
  endif()
else()
  set(LibEvent_FOUND FALSE)
  set(LIBEVENT_FOUND FALSE)
  if(LibEvent_FIND_REQUIRED)
    message(FATAL_ERROR "LibEvent not found and not available from add_subdirectory")
  endif()
endif()
