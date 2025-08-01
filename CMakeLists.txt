cmake_minimum_required (VERSION 3.10)
project (INCLUDE_GARDENER)

set (GARDENER_VERSION_MAJOR X)
set (GARDENER_VERSION_MINOR X)
set (GARDENER_VERSION_PATCH 0)
set (GARDENER_VERSION
  "${GARDENER_VERSION_MAJOR}. ${GARDENER_VERSION_MINOR}. ${GARDENER_VERSION_PATCH}")

set (CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package (Boost REQUIRED COMPONENTS log system filesystem program_options regex)
if (Boost_FOUND)
  include_directories(SYSTEM ${Boost_INCLUDE_DIRS})
else ()
  message (FATAL_ERROR "Boost not found.")
endif ()
include_directories (inc)
set (CMAKE_CXX_STANDARD 17)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
if (CMAKE_COMPILER_IS_GNUCXX)
  set (CMAKE_CXX_FLAGS "-O2 -fno-elide-constructors -pedantic-errors -ansi -Wextra -Wall -Winit-self -Wold-style-cast -Woverloaded-virtual -Wuninitialized -Winit-self -Werror")
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
  set (CMAKE_CXX_FLAGS "-O2 -fno-elide-constructors -pedantic-errors -Wextra -Wall -Winit-self -Wold-style-cast -Woverloaded-virtual -Wuninitialized -Winit-self -Werror")
endif ()

find_package (Threads REQUIRED)

#
# Doxygen Documentation Generation
#

find_package (Doxygen)
if(DOXYGEN_FOUND)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/doc/Doxyfile.in ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)
  add_custom_target (doc
     ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
     COMMENT "Generating API documentation with Doxygen" VERBATIM)
endif (DOXYGEN_FOUND)

##
## Main Target Generation
##

add_definitions (-DBOOST_LOG_DYN_LINK=1)
add_definitions (-D_GARDENER_VERSION_MAJOR=${GARDENER_VERSION_MAJOR})
add_definitions (-D_GARDENER_VERSION_MINOR=${GARDENER_VERSION_MINOR})
add_definitions (-D_GARDENER_VERSION_PATCH=${GARDENER_VERSION_PATCH})
add_definitions (-D_GARDENER_VERSION="${GARDENER_VERSION}")

set (SOURCE_FILES
     ${CMAKE_SOURCE_DIR}/src/helper.cpp
     ${CMAKE_SOURCE_DIR}/src/statement_detector.cpp
     ${CMAKE_SOURCE_DIR}/src/file_detector.cpp
     ${CMAKE_SOURCE_DIR}/src/input_files.cpp
     ${CMAKE_SOURCE_DIR}/src/vertex.cpp
     ${CMAKE_SOURCE_DIR}/src/solver.cpp
     ${CMAKE_SOURCE_DIR}/src/solver_c.cpp
     ${CMAKE_SOURCE_DIR}/src/solver_py.cpp
     ${CMAKE_SOURCE_DIR}/src/solver_rb.cpp
     ${CMAKE_SOURCE_DIR}/src/statement_py.cpp)

set (EXEC_SOURCE_FILES
     ${SOURCE_FILES}
     ${CMAKE_SOURCE_DIR}/src/main.cpp)

set (UNIT_TEST_SOURCE_FILES
     ${CMAKE_SOURCE_DIR}/test/unit_test/main.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_file_detector.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_statement_detector.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_helper.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_input_files.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_solver.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_solver_py.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_solver_rb.cpp
     ${CMAKE_SOURCE_DIR}/test/unit_test/test_statement_py.cpp)

add_executable ( include_gardener ${EXEC_SOURCE_FILES})

target_link_libraries (include_gardener ${CMAKE_THREAD_LIBS_INIT})
target_link_libraries (include_gardener ${Boost_LIBRARIES})

install (TARGETS include_gardener DESTINATION bin)

enable_testing ()

#########
#
# Use system GoogleTest
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTEST REQUIRED gtest>=1.10)
pkg_check_modules(GMOCK REQUIRED gmock>=1.10)

# Prevent Googletest from overriding our compiler/linker options
# when building with Visual Studio
set (gtest_force_shared_crt ON CACHE BOOL "" FORCE)
#
########

##
## Unit-Test Executable Generation
##

add_executable (unit_test
                ${SOURCE_FILES}
                ${UNIT_TEST_SOURCE_FILES})

target_link_libraries (unit_test  ${CMAKE_THREAD_LIBS_INIT})
target_link_libraries (unit_test  ${Boost_LIBRARIES})
target_link_libraries (unit_test  ${GTEST_LIBRARIES})
target_link_libraries (unit_test  ${GMOCK_LIBRARIES})

set (TEST_DIR ${CMAKE_SOURCE_DIR}/test)

##
## Unit-Test (gtest) execution
##
add_test (unit_test unit_test --gtest_output=xml:test-reports/unit_test_results.xml)

##
## cmdline test execution (via python)
##
add_test (basic_cmdline_test python3 ${TEST_DIR}/cmd_line/test_basic.py
          test-reports
          ${CMAKE_BINARY_DIR}/include_gardener ${TEST_DIR}/test_files/c)

add_test (c_cmdline_test python3 ${TEST_DIR}/cmd_line/test_c.py
          test-reports
          ${CMAKE_BINARY_DIR}/include_gardener ${TEST_DIR}/test_files/c)

add_test (ruby_cmdline_test python3 ${TEST_DIR}/cmd_line/test_rb.py
          test-reports 
          ${CMAKE_BINARY_DIR}/include_gardener
          ${TEST_DIR}/test_files/ruby)

add_test (py_cmdline_test python3 ${TEST_DIR}/cmd_line/test_py.py
          test-reports
          ${CMAKE_BINARY_DIR}/include_gardener ${TEST_DIR}/test_files/py/graph_test_files)

##
## CPPCHECK
##
find_program (CPPCHECK "cppcheck")

add_custom_target (cppcheck
                   COMMAND cppcheck
                   --enable=warning,performance,portability,missingInclude,style
                   --std=c++11
                   --suppress=missingIncludeSystem
                   --template="[{severity}][{id}][{file}:{line}] {message} {callstack}"
                   --project=compile_commands.json
                   --output-file=cpp_check.log)

##
## CLANG-TIDY
##
find_program (CLANG_TIDY "clang-tidy")

add_custom_target (clang-tidy
                   COMMAND clang-tidy
                   -p=./
                   -checks=*,-fuchsia-default-arguments,-llvm-header-guard
                   -format-style=google
                   -header-filter=.*
                   ${EXEC_SOURCE_FILES}
                   ${UNIT_TEST_SOURCE_FILES}
                   -extra-arg=-std=c++17 > clang-tidy.log)

