# Bridge: libevent is available via add_subdirectory.
# This intercepts find_package(Libevent CONFIG QUIET) from wangle's FindLibEvent.cmake.
# It ensures LIBEVENT_LIB is set to a valid target name rather than a file path.

if(NOT TARGET event_core_static)
  set(Libevent_FOUND FALSE)
  return()
endif()

set(Libevent_FOUND TRUE)
set(LIBEVENT_FOUND TRUE)
set(LibEvent_FOUND TRUE)

# Use target name for linking (works in target_link_libraries).
# Include directories are propagated automatically via the event_core_static target
# (libevent's AddEventLibrary.cmake sets PUBLIC target_include_directories).
set(LIBEVENT_LIB event_core_static)
set(LIBEVENT_LIBRARIES event_core_static)
