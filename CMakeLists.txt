cmake_minimum_required(VERSION 3.28)
set (CMAKE_CXX_STANDARD 17)
#set(ICE_CPP11_MAPPING)
#add_definitions(-DICE_CPP11_MAPPING)

project(icemessanger)

include(cmake/iceGenerator.cmake)

set(COMMON_SRC 
${CMAKE_CURRENT_SOURCE_DIR}/ice/messanger/hello.ice
)

add_ice_library(
    TARGET messanger
    SRC ${COMMON_SRC} 
    INTERFACE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ice"
    )

set(SOURCE lib/test.cpp)

include_directories(include)
add_executable(iceclient bin/client/main.cpp ${SOURCE})
add_executable(iceserver bin/server/main.cpp ${SOURCE})

target_link_libraries(iceclient messanger)
target_link_libraries(iceserver messanger)
