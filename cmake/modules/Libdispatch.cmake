
function(add_libdispatch_build out_dispatch_name out_blocks_runtime_name)
  set(options)
  set(single_parameter_options SDK ARCHITECTURE)
  set(multiple_parameter_options)

  cmake_parse_arguments(LIBDISPATCH
    "${options}"
    "${single_parameter_options}"
    "${multiple_parameter_options}"
    ${ARGN})

  if(CMAKE_C_COMPILER_ID STREQUAL Clang AND
    CMAKE_C_COMPILER_VERSION VERSION_GREATER 3.8
    OR LLVM_USE_SANITIZER)
    set(SWIFT_LIBDISPATCH_C_COMPILER ${CMAKE_C_COMPILER})
    set(SWIFT_LIBDISPATCH_CXX_COMPILER ${CMAKE_CXX_COMPILER})
  elseif(${CMAKE_SYSTEM_NAME} STREQUAL ${CMAKE_HOST_SYSTEM_NAME})
    if(CMAKE_SYSTEM_NAME STREQUAL Windows)
      if(CMAKE_SYSTEM_PROCESSOR STREQUAL CMAKE_HOST_SYSTEM_PROCESSOR AND
        TARGET clang)
        set(SWIFT_LIBDISPATCH_C_COMPILER
          $<TARGET_FILE_DIR:clang>/clang-cl${CMAKE_EXECUTABLE_SUFFIX})
        set(SWIFT_LIBDISPATCH_CXX_COMPILER
          $<TARGET_FILE_DIR:clang>/clang-cl${CMAKE_EXECUTABLE_SUFFIX})
      else()
        set(SWIFT_LIBDISPATCH_C_COMPILER clang-cl${CMAKE_EXECUTABLE_SUFFIX})
        set(SWIFT_LIBDISPATCH_CXX_COMPILER clang-cl${CMAKE_EXECUTABLE_SUFFIX})
      endif()
    else()
      set(SWIFT_LIBDISPATCH_C_COMPILER $<TARGET_FILE_DIR:clang>/clang)
      set(SWIFT_LIBDISPATCH_CXX_COMPILER $<TARGET_FILE_DIR:clang>/clang++)
    endif()
  else()
    message(SEND_ERROR "libdispatch requires a newer clang compiler (${CMAKE_C_COMPILER_VERSION} < 3.9)")
  endif()

  if(SDK STREQUAL WINDOWS)
    set(LIBDISPATCH_RUNTIME_DIR bin)
  else()
    set(LIBDISPATCH_RUNTIME_DIR lib)
  endif()

  set(TARGET_VARIANT libdispatch-${SWIFT_SDK_${LIBDISPATCH_SDK}_LIB_SUBDIR}-${LIBDISPATCH_ARCHITECTURE})

  include(ExternalProject)
  ExternalProject_Add("${TARGET_VARIANT}"
    SOURCE_DIR
    "${SWIFT_PATH_TO_LIBDISPATCH_SOURCE}"
    CMAKE_ARGS
    -DCMAKE_AR=${CMAKE_AR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_C_COMPILER=${SWIFT_LIBDISPATCH_C_COMPILER}
    -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
    -DCMAKE_CXX_COMPILER=${SWIFT_LIBDISPATCH_CXX_COMPILER}
    -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
    -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_LINKER=${CMAKE_LINKER}
    -DCMAKE_RANLIB=${CMAKE_RANLIB}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=YES
    -DENABLE_SWIFT=NO
    -DENABLE_TESTING=NO
    INSTALL_COMMAND
    # NOTE(compnerd) provide a custom install command to
    # ensure that we strip out the DESTDIR environment
    # from the sub-build
    ${CMAKE_COMMAND} -E env --unset=DESTDIR ${CMAKE_COMMAND} --build . --target install
    STEP_TARGETS
    install
    BUILD_BYPRODUCTS
    <INSTALL_DIR>/${LIBDISPATCH_RUNTIME_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}dispatch${CMAKE_SHARED_LIBRARY_SUFFIX}
    <INSTALL_DIR>/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}dispatch${CMAKE_IMPORT_LIBRARY_SUFFIX}
    <INSTALL_DIR>/${LIBDISPATCH_RUNTIME_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}BlocksRuntime${CMAKE_SHARED_LIBRARY_SUFFIX}
    <INSTALL_DIR>/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}BlocksRuntime${CMAKE_IMPORT_LIBRARY_SUFFIX}
    BUILD_ALWAYS
    1)

  ExternalProject_Get_Property("${TARGET_VARIANT}" install_dir)

  # CMake does not like the addition of INTERFACE_INCLUDE_DIRECTORIES without
  # the directory existing.  Just create the location which will be populated
  # during the installation.
  file(MAKE_DIRECTORY ${install_dir}/include)

  set(DISPATCH_TARGET_VARIANT dispatch-${SWIFT_SDK_${SDK}_LIB_SUBDIR}-${arch})
  add_library("${DISPATCH_TARGET_VARIANT}" SHARED IMPORTED)
  set_target_properties("${DISPATCH_TARGET_VARIANT}"
    PROPERTIES
    IMPORTED_LOCATION
    ${install_dir}/${LIBDISPATCH_RUNTIME_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}dispatch${CMAKE_SHARED_LIBRARY_SUFFIX}
    IMPORTED_IMPLIB
    ${install_dir}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}dispatch${CMAKE_IMPORT_LIBRARY_SUFFIX}
    INTERFACE_INCLUDE_DIRECTORIES
    ${install_dir}/include)

  set(BLOCKS_RUNTIME_TARGET_VARIANT BlocksRuntime-${SWIFT_SDK_${SDK}_LIB_SUBDIR}-${arch})
  add_library("${BLOCKS_RUNTIME_TARGET_VARIANT}" SHARED IMPORTED)
  set_target_properties("${BLOCKS_RUNTIME_TARGET_VARIANT}"
    PROPERTIES
    IMPORTED_LOCATION
    ${install_dir}/${LIBDISPATCH_RUNTIME_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}BlocksRuntime${CMAKE_SHARED_LIBRARY_SUFFIX}
    IMPORTED_IMPLIB
    ${install_dir}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}BlocksRuntime${CMAKE_IMPORT_LIBRARY_SUFFIX}
    INTERFACE_INCLUDE_DIRECTORIES
    ${SWIFT_PATH_TO_LIBDISPATCH_SOURCE}/src/BlocksRuntime)

  add_dependencies("${DISPATCH_TARGET_VARIANT}" ${TARGET_VARIANT}-install)
  add_dependencies("${BLOCKS_RUNTIME_TARGET_VARIANT}" ${TARGET_VARIANT}-install)

  # FIXME(compnerd) this should be taken care of by the
  # INTERFACE_INCLUDE_DIRECTORIES above
  include_directories(AFTER
    ${SWIFT_PATH_TO_LIBDISPATCH_SOURCE}/src/BlocksRuntime
    ${SWIFT_PATH_TO_LIBDISPATCH_SOURCE})

  set(${out_dispatch_name} "${DISPATCH_TARGET_VARIANT}" PARENT_SCOPE)
  set(${out_blocks_runtime_name} "${BLOCKS_RUNTIME_TARGET_VARIANT}" PARENT_SCOPE)
endfunction()