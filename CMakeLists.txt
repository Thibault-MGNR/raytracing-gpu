cmake_minimum_required(VERSION 3.22.1)

# set (CMAKE_GENERATOR "MinGW Makefiles" CACHE INTERNAL "" FORCE)

# set(CMAKE_CXX_COMPILER "C:/msys64/mingw64/bin/g++.exe" )
# set(CMAKE_C_COMPILER "C:/msys64/mingw64/bin/gcc.exe" )


project(Raytracing)

add_subdirectory(lib)


file(GLOB_RECURSE SOURCES src/*.cpp src/*.c)
add_executable(raytracing ${SOURCES})

target_link_libraries(raytracing PUBLIC GPGPU)

target_include_directories(raytracing PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include/"
)