# Bridge: fizz is available via add_subdirectory
# This file satisfies find_package(fizz CONFIG REQUIRED) and
# find_package(Fizz CONFIG REQUIRED) for downstream FB libs

# fizz's add_subdirectory creates a 'fizz' target
if(NOT TARGET fizz)
  message(FATAL_ERROR "Bridge error: fizz target not available (expected from add_subdirectory)")
endif()

# Create fizz::fizz alias if not already present
if(NOT TARGET fizz::fizz)
  add_library(fizz::fizz ALIAS fizz)
endif()

set(fizz_FOUND TRUE)
set(Fizz_FOUND TRUE)
set(FIZZ_FOUND TRUE)
set(FIZZ_LIBRARIES fizz)

# Include directories are propagated automatically via the fizz target
# (fizz has PUBLIC target_include_directories). No need to set FIZZ_INCLUDE_DIR.
