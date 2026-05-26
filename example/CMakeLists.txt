cmake_minimum_required(VERSION 3.21)

project(ExampleRobot
    VERSION 0.1.0
    LANGUAGES CXX)

find_package(FRCMake 1.0.0 REQUIRED)

include(FRC)
find_package(WPILib 2027 REQUIRED COMPONENTS wpilibc hal ntcore wpimath wpiutil)

set(FRC_TEAM_NUMBER "7674" CACHE STRING "Team number.")

file(GLOB_RECURSE ${SRCS} src/main/*.cpp src/main/*.cc src/main/*.cxx)

add_executable(Robot ${SRCS})

frc_add_deploy_target(Robot
    DEPLOY_DIR "${CMAKE_SOURCE_DIR}/src/deploy"
    DELETE_OLD TRUE)
