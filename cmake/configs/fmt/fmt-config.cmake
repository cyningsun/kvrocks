# Bridge: fmt is available via add_subdirectory
# This file satisfies find_package(fmt CONFIG REQUIRED) for downstream FB libs

if(NOT TARGET fmt)
  message(FATAL_ERROR "Bridge error: fmt target not available (expected from add_subdirectory)")
endif()

# Create fmt::fmt alias if not already present
if(NOT TARGET fmt::fmt)
  add_library(fmt::fmt ALIAS fmt)
endif()

set(fmt_FOUND TRUE)
set(FMT_FOUND TRUE)
set(FMT_LIBRARIES fmt::fmt)
set(fmt_VERSION "9.1.0")

# Include directories are propagated automatically via the fmt::fmt target
# (fmt has PUBLIC target_include_directories). No need to set FMT_INCLUDE_DIR.
