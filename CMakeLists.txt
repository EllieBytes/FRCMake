cmake_minimum_required(VERSION 3.21)

project(FRCMake
    VERSION 1.0.0
    DESCRIPTION "CMake modules for FIRST Robotics Competition robots."
    HOMEPAGE_URL "https://github.com/EllieBytes/FRCMake"
    LANGUAGES NONE)

include(GNUInstallDirs)

set(FRCMAKE_INSTALL_CMAKEDIR
    "${CMAKE_INSTALL_DATAROOTDIR}/cmake/FRCMake"
    CACHE STRING "Install directory for FRCMake modules.")

set(FRCMAKE_MODULE_FILES
    cmake/FindWPILib.cmake
    cmake/FRC.cmake
    cmake/SystemcoreToolchain.cmake
    cmake/WPILibConfig.cmake)

install(
    FILES ${FRCMAKE_MODULE_FILES}
    DESTINATION "${FRCMAKE_INSTALL_CMAKEDIR}"
    COMPONENT cmake_modules
)

include(CmakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/FRCMakeConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/FRCMakeConfig.cmake"
    INSTALL_DESTINATION "${FRCMAKE_INSTALL_CMAKEDIR}"
    NO_SET_AND_CHECK_MACRO
    NO_CHECK_REQUIRED_COMPONENTS_MACRO)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/FRCMakeConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion)

install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/FRCMakeConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/FRCMakeConfigVersion.cmake"
    DESTINATION "${FRCMAKE_INSTALL_CMAKEDIR}"
    COMPONENT cmake_modules)
