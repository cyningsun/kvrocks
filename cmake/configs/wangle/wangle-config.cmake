# Bridge: wangle is available via add_subdirectory
# This file satisfies find_package(wangle CONFIG REQUIRED) for downstream FB libs

if(NOT TARGET wangle)
  message(FATAL_ERROR "Bridge error: wangle target not available (expected from add_subdirectory)")
endif()

# Create wangle::wangle alias if not already present
if(NOT TARGET wangle::wangle)
  add_library(wangle::wangle ALIAS wangle)
endif()

set(wangle_FOUND TRUE)
set(WANGLE_FOUND TRUE)
set(WANGLE_LIBRARIES wangle)

# Include directories are propagated automatically via the wangle target
# (wangle has PUBLIC target_include_directories). No need to set WANGLE_INCLUDE_DIR.
