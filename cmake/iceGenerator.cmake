# set option `ICE_CPP11` for c++11 mapping on

if (NOT ${CMAKE_SYSROOT} )
  set(Ice_HOME ${CMAKE_SYSROOT}/opt/Ice)
endif()

if(WIN32)
  if(Ice_HOME)
    set(Ice_NUGET_DIR ${Ice_HOME})
    unset(Ice_HOME)
  endif(Ice_HOME)
  
endif(WIN32)

# set (Ice_DEBUG ON)
if(Ice_HOME)
  message(ICEHOME = ${Ice_HOME})

  # ONLY FOR LINUX 
  set(Ice_SLICE2CPP_EXECUTABLE ${Ice_HOME}/bin/slice2cpp)
  if(ICE_CPP11)
    set(Ice_LIBRARIES ${Ice_HOME}/lib/libIce++11.a -lbz2)
  else()
    set(Ice_LIBRARIES ${Ice_HOME}/lib/libIce.a -lbz2)
  endif()
  
  set(Ice_INCLUDE_DIR ${Ice_HOME}/include)
  set(Ice_SLICE_DIR ${Ice_HOME}/slice)

  execute_process(COMMAND ${Ice_SLICE2CPP_EXECUTABLE} --version
  ERROR_VARIABLE Ice_VERSION_SLICE2CPP_FULL
  ERROR_STRIP_TRAILING_WHITESPACE)

  message(STATUS "Ice version: ${Ice_VERSION_SLICE2CPP_FULL}")
  message(STATUS "Ice_LIBRARIES ${Ice_LIBRARIES}")
else()

  if(WIN32)
    
    if(ICE_CPP11)
      find_package(Ice COMPONENTS Ice++11 IceDiscovery++11 IceLocatorDiscovery++11 IceSSL++11)
    else()
      find_package(Ice COMPONENTS Ice IceDiscovery IceLocatorDiscovery IceSSL)
    endif(ICE_CPP11)

  elseif(UNIX)

    if(ICE_CPP11)
      find_package(Ice COMPONENTS Ice++11)
    else()
      find_package(Ice COMPONENTS Ice)
    endif(ICE_CPP11)
  
  endif()

endif(Ice_HOME)


function(normalize_path in_path out_path)
  string(REPLACE "\\" "/" out_var ${in_path})
  set (${out_path} ${out_var} PARENT_SCOPE)
endfunction()


function(get_file_name in_filename out)
  string(LENGTH ${in_filename} str_size)
  string(FIND ${in_filename} "/" pos REVERSE)
  math(EXPR pos "${pos} + 1")
  math(EXPR usefull_size "${str_size}-${pos}" )
  string(SUBSTRING ${in_filename} ${pos} ${usefull_size} out_var)
  set (${out} ${out_var} PARENT_SCOPE)
endfunction()


function(add_ice_deppend ice_src ice_dst ice_depend_string)
  string(REGEX MATCH "^(.+)\.h: \\\\" src ${ice_depend_string})

  string(LENGTH ${CMAKE_MATCH_1} start_pos)

  set(first_step 7)
  math(EXPR start_pos "${start_pos} + ${first_step}")
  
  string(SUBSTRING ${ice_depend_string} ${start_pos} -1 ice_depend_string)
  
  set(pos 0)
  while(${pos}  GREATER -1)
    # cut src dep string
    string(FIND ${ice_depend_string} " \\" pos)     
    string(SUBSTRING ${ice_depend_string} 0 ${pos} out_var)
    list(APPEND ice_depends ${out_var})
    if(${pos} EQUAL -1)
      break()
    endif()

    math(EXPR pos "${pos} + 3")
    string(SUBSTRING ${ice_depend_string} ${pos} -1 ice_depend_string)
      
  endwhile()

  string( REPLACE "; " ";" ice_depends "${ice_depends}" )

  foreach(dep ${ice_depends})
      get_filename_component(dep_name ${dep} NAME )
      list(APPEND ice_depends_names ${dep_name})
  endforeach()
  string(JOIN "; " ice_str_depends ${ice_depends_names})

  add_custom_command(
    OUTPUT "${ice_dst}/${CMAKE_MATCH_1}.cpp" "${ice_dst}/${CMAKE_MATCH_1}.h"
    DEPENDS ${ice_depends}
    COMMAND ${Ice_SLICE2CPP_EXECUTABLE} ${ice_src} --output-dir ${ice_build_dir} 
    -I . -I ${ice_interface_dir} -I ${Ice_SLICE_DIR}
    # --include-dir ${ice_build_dir}
    COMMENT "Ice generate sources from: [ ${ice_str_depends} ]"
  )
  
  # message("${CMAKE_MATCH_1} deps from = ${ice_depends}")

endfunction()

#[=====================================[
  add_ice_library
  ---------
  generate cpp files from ice src `ice_interface_dir` 
  create custom target `TARGET` for regenerating cpp
  
  example:
  add_ice_library(
    TARGET common-ice
    SRC ${COMMON_SRC} 
    INTERFACE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src"
    DEPS depend-lib
    )
#]=====================================]
function(add_ice_library)

    set(options NONE)
    set(oneValueArgs TARGET NAME)

    set(multiValueArgs SRC INTERFACE_DIR INCLUDES DEPS)
    cmake_parse_arguments(IceGen "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED IceGen_TARGET)
    return()
  endif()

  if(DEFINED IceGen_INCLUDES)

    foreach(inc ${IceGen_INCLUDES})
      list(APPEND slice_includes "-I")
      list(APPEND slice_includes ${inc})
    endforeach()
    string( REPLACE ";" " " slice_includes "${slice_includes}" )
  endif()

  set(ice_interface_dir ${IceGen_INTERFACE_DIR})

  set (ice_build_dir ${CMAKE_CURRENT_BINARY_DIR}/ice_generated/${IceGen_TARGET})

  file(MAKE_DIRECTORY  ${ice_build_dir})
  foreach(ice_file ${IceGen_SRC})
    normalize_path(${ice_file} ice_file_normal_path)
    string(REGEX REPLACE "(ice)$" "h" ice_header ${ice_file_normal_path})
    string(REGEX REPLACE "(ice)$" "cpp" ice_source ${ice_file_normal_path})
    
    get_file_name(${ice_source} ice_src)
    get_file_name(${ice_header} ice_hdr)
    get_file_name(${ice_file_normal_path} ice_name)

    # message( "${ice_file} => ${ice_src} ${ice_hdr}")
    list(APPEND ice_cpp "${ice_build_dir}/${ice_src}")
    list(APPEND ice_head "${ice_build_dir}/${ice_hdr}")
    list(APPEND ice_files ${ice_name})

    execute_process(
    COMMAND ${Ice_SLICE2CPP_EXECUTABLE} ${ice_file} --depend
     -I ${ice_interface_dir}
     -I ${Ice_SLICE_DIR} 
    #  --include-dir .
    #  -I common
      # "${slice_includes}" 
    WORKING_DIRECTORY ${ice_interface_dir}
    OUTPUT_VARIABLE ice_deps
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE rev_parse_exit_code
    # COMMAND_ECHO STDOUT
    )
    add_ice_deppend(${ice_file} ${ice_build_dir} ${ice_deps} )

    endforeach()

  add_library(${IceGen_TARGET} ${shared_or_static} ${ice_cpp} )  

  #c++11 SUPPORT
  if(ICE_CPP11)
    target_compile_definitions(${IceGen_TARGET} PUBLIC ICE_CPP11_MAPPING)
  endif(ICE_CPP11)

  if(WIN32)
    target_compile_definitions(${IceGen_TARGET} PUBLIC _HAS_AUTO_PTR_ETC=1)
  endif()

  target_link_libraries(${IceGen_TARGET} PUBLIC ${Ice_LIBRARIES})
  
  if(DEFINED IceGen_DEPS)
    target_link_libraries(${IceGen_TARGET} PUBLIC ${IceGen_DEPS})
  endif()
  target_include_directories(${IceGen_TARGET} PUBLIC ${Ice_INCLUDE_DIR})
  target_include_directories(${IceGen_TARGET} PUBLIC ${ice_build_dir})
  target_include_directories(${IceGen_TARGET} PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/ice_generated)
  target_include_directories(${IceGen_TARGET} PUBLIC ${ice_interface_dir})
endfunction()
