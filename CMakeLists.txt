cmake_minimum_required(VERSION 3.8)
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
project(project_name)

function(add_project_library TARGET)
  if(NOT TARGET)
    message(FATAL_ERROR "Expected the target name as first argument")
  endif()

  if(NOT ARGN)
    message(FATAL_ERROR "Expected source file list after target name")
  endif()

  add_library(${TARGET} ${ARGN})
  target_include_directories(${TARGET} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>)
  set_target_properties(${TARGET} PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
  target_compile_options(${TARGET} PRIVATE -Wall -Wextra)
  target_compile_options(${TARGET} PRIVATE $<$<CXX_COMPILER_ID:Clang>:-frelaxed-template-template-args>)
endfunction(add_project_library)

# ###############################################
# #          Find macros and libraries         ##
# ###############################################
find_package(cmake_modules REQUIRED)

if($ENV{ROS_VERSION} STREQUAL "1")
  find_package(catkin REQUIRED COMPONENTS
    roscpp
    roslib
    std_msgs
    genmsg
    message_generation
  )

# Install python scripts using distutils
# catkin_python_setup() # uncomment if you have to deploy python scripts
elseif($ENV{ROS_VERSION} STREQUAL "2")
  find_package(ament_cmake REQUIRED)
  find_package(rosidl_default_generators REQUIRED)
  find_package(rclcpp REQUIRED)
  find_package(ament_cmake_python REQUIRED)
  find_package(std_msgs REQUIRED)

  # ament_python_install_package(folder_name)
endif()

# ###############################################
# # Declare ROS messages, services and actions ##
# ###############################################
if($ENV{ROS_VERSION} STREQUAL "1")
# # Generate messages in the 'msg' folder
# add_message_files(
# FILES
# )

# # Generate services in the 'srv' folder
# add_service_files(
# FILES
# )

# # Generate added messages and services with any dependencies listed here
# generate_messages(
# DEPENDENCIES
# std_msgs
# )
elseif($ENV{ROS_VERSION} STREQUAL "2")
  # rosidl_generate_interfaces(project_name
  # "msg/MyMeesage.msg"
  # DEPENDENCIES builtin_interfaces std_msgs)
endif()

# ##################################
# #   ROS specific configuration  ##
# ##################################
if($ENV{ROS_VERSION} STREQUAL "1")
  catkin_package(
    INCLUDE_DIRS include

    # LIBRARIES project_name_lib
    CATKIN_DEPENDS roscpp std_msgs

    # DEPENDS TinyXML
  )
elseif($ENV{ROS_VERSION} STREQUAL "2")
  ament_export_dependencies(rosidl_default_runtime)

  # rosidl_get_typesupport_target(cpp_typesupport_target ${PROJECT_NAME} rosidl_typesupport_cpp) # uncomment if you have msgs or srvs
endif()

# ##########
# # Build ##
# ##########

# ##################################
# #   ROS independent libraries   ##
# ##################################
# add_project_library(project_name_lib
# src/file.cpp
# )
# target_link_libraries(project_name_lib
# PUBLIC
# project_name_sublib
# )

# ##################################
# #    ROS dependent libraries    ##
# ##################################
function(add_ros_library TARGET)
  if(NOT TARGET)
    message(FATAL_ERROR "Expected the target name as first argument")
  endif()

  if(NOT ARGN)
    message(FATAL_ERROR "Expected source file list after target name")
  endif()

  add_library(${TARGET} ${ARGN})

  if($ENV{ROS_VERSION} STREQUAL "1")
    add_dependencies(${TARGET} project_name_gencpp ${catkin_EXPORTED_TARGETS})
    target_include_directories(${TARGET} PUBLIC include ${catkin_INCLUDE_DIRS})
    target_link_libraries(${TARGET} PUBLIC ${catkin_LIBRARIES})
  elseif($ENV{ROS_VERSION} STREQUAL "2")
    ament_target_dependencies(${TARGET} PUBLIC rclcpp builtin_interfaces std_msgs)
    target_include_directories(${TARGET} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
      $<INSTALL_INTERFACE:include>)
    target_link_libraries(${TARGET} PUBLIC ${cpp_typesupport_target})
    ament_export_libraries(${TARGET})
  endif()

  set_target_properties(${TARGET} PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
  target_compile_options(${TARGET} PRIVATE $<$<CXX_COMPILER_ID:Clang>:-frelaxed-template-template-args>)
  target_compile_options(${TARGET} PUBLIC -DPROJECT_NAME_ROS_VERSION=$ENV{ROS_VERSION})
  target_compile_options(${TARGET} PRIVATE -Wall -Wextra)
endfunction(add_ros_library)

# Compatibility
add_ros_library(project_name_compat
  src/compat/ros.cpp
)

# ##################################
# #        C++ executables        ##
# ##################################
function(add_ros_executable TARGET)
  if(NOT TARGET)
    message(FATAL_ERROR "Expected the target name as first argument")
  endif()

  if(NOT ARGN)
    message(FATAL_ERROR "Expected source file list after target name")
  endif()

  add_executable(${TARGET} ${ARGN})

  if($ENV{ROS_VERSION} STREQUAL "1")
    target_include_directories(${TARGET} PUBLIC include PRIVATE ${catkin_INCLUDE_DIRS})
    target_link_libraries(${TARGET} PUBLIC ${catkin_LIBRARIES})
  elseif($ENV{ROS_VERSION} STREQUAL "2")
    ament_target_dependencies(${TARGET} PUBLIC rclcpp builtin_interfaces std_msgs)
    target_include_directories(${TARGET} PUBLIC include)
    target_link_libraries(${TARGET} PUBLIC ${cpp_typesupport_target})
  endif()

  set_target_properties(${TARGET} PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
  target_compile_options(${TARGET} PUBLIC -DPROJECT_NAME_ROS_VERSION=$ENV{ROS_VERSION})
  target_compile_options(${TARGET} PRIVATE -Wall -Wextra)
endfunction(add_ros_executable)

# NODES
add_ros_executable(my_node src/nodes/my_node.cpp)
target_link_libraries(my_node PRIVATE project_name_compat)

# ##################################
# #            Install            ##
# ##################################
if($ENV{ROS_VERSION} STREQUAL "1")
  install(TARGETS my_node RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})

  install(TARGETS
    project_name_compat
    ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
    LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
    RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )

  install(DIRECTORY include/${PROJECT_NAME}/
    DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
    FILES_MATCHING PATTERN "*.h"
    PATTERN ".svn" EXCLUDE
  )

  install(DIRECTORY launch/
    DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/launch
  )

  install(DIRECTORY files/
    DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/files
  )

elseif($ENV{ROS_VERSION} STREQUAL "2")
  install(TARGETS
    project_name_compat
    EXPORT project_name
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
    DESTINATION lib/${PROJECT_NAME})

  install(TARGETS
    my_node
    DESTINATION lib/${PROJECT_NAME})

  # install(DIRECTORY launch/ros2/launch DESTINATION share/${PROJECT_NAME}/) # uncomment if you have ROS2 launch files
  install(DIRECTORY include/ DESTINATION include)

  install(DIRECTORY docs DESTINATION share/${PROJECT_NAME}/)

  ament_export_targets(project_name)
endif()

# ##################################
# #            Tests              ##
# ##################################
if($ENV{ROS_VERSION} STREQUAL "1")
  if(CATKIN_ENABLE_TESTING)
    find_package(rostest REQUIRED)

    # add_rostest_gtest(project_name_tester test/project_name_tester.test src/tests/test.cpp)
    # target_include_directories(project_name_tester PRIVATE ${catkin_INCLUDE_DIRS})
    # target_link_libraries(project_name_tester project_name_lib ${catkin_LIBRARIES})
  endif()

elseif($ENV{ROS_VERSION} STREQUAL "2")
  if(BUILD_TESTING)
    find_package(ament_lint_auto REQUIRED)
    find_package(ament_cmake_gtest REQUIRED)

    # ament_add_gtest(project_name_tester src/tests/test.cpp TIMEOUT 10)
    # set_target_properties(project_name_tester PROPERTIES CXX_STANDARD 14 CXX_STANDARD_REQUIRED ON)
    # target_include_directories(project_name_tester PRIVATE ${catkin_INCLUDE_DIRS})
    # target_link_libraries(project_name_tester project_name_lib ${catkin_LIBRARIES})
  endif()
endif()

# ##################################
# #            ROS2               ##
# ##################################
if($ENV{ROS_VERSION} STREQUAL "2")
  # pluginlib_export_plugin_description_file(project_name reasoners_plugins_ros2.xml)
  ament_export_include_directories(include)
  ament_package()
endif()
