cmake_minimum_required(VERSION 3.21)

if(_FindWPILib_included)
    return()
endif()
set(_FindWPILib_included TRUE)

include(FindPackageHandleStandardArgs)

if(NOT DEFINED WPILIB_TARGET_PLATFORM)
    set(WPILIB_TARGET_PLATFORM "linuxarm64")
endif()

set(_WPILib_ALL_COMPONENTS
    wpiutil
    wpinet
    wpimath
    ntcore
    hal
    cscore
    cameraserver
    wpilibc
    commandsv3
    apriltag
)

set(_WPILib_MAVEN_GROUP_wpiutil      "edu.wpi.first.wpiutil")
set(_WPILib_MAVEN_GROUP_wpinet       "edu.wpi.first.wpinet")
set(_WPILib_MAVEN_GROUP_wpimath      "edu.wpi.first.wpimath")
set(_WPILib_MAVEN_GROUP_ntcore       "edu.wpi.first.ntcore")
set(_WPILib_MAVEN_GROUP_hal          "edu.wpi.first.hal")
set(_WPILib_MAVEN_GROUP_cscore       "edu.wpi.first.cscore")
set(_WPILib_MAVEN_GROUP_cameraserver "edu.wpi.first.cameraserver")
set(_WPILib_MAVEN_GROUP_wpilibc      "edu.wpi.first.wpilibc")
set(_WPILib_MAVEN_GROUP_commandsv3   "edu.wpi.first.wpilibc")
set(_WPILib_MAVEN_GROUP_apriltag     "edu.wpi.first.apriltag")

set(_WPILib_MAVEN_ARTIFACT_wpiutil      "wpiutil-cpp")
set(_WPILib_MAVEN_ARTIFACT_wpinet       "wpinet-cpp")
set(_WPILib_MAVEN_ARTIFACT_wpimath      "wpimath-cpp")
set(_WPILib_MAVEN_ARTIFACT_ntcore       "ntcore-cpp")
set(_WPILib_MAVEN_ARTIFACT_hal          "hal-cpp")
set(_WPILib_MAVEN_ARTIFACT_cscore       "cscore-cpp")
set(_WPILib_MAVEN_ARTIFACT_cameraserver "cameraserver-cpp")
set(_WPILib_MAVEN_ARTIFACT_wpilibc      "wpilibc-cpp")
set(_WPILib_MAVEN_ARTIFACT_commandsv3   "commandsv3-cpp")
set(_WPILib_MAVEN_ARTIFACT_apriltag     "apriltag-cpp")

function(_wpilib_maven_path out gid aid version classifier ext)
    string(REPLACE "." "/" _gpath "${gid}")
    if(classifier STREQUAL "")
        set(${out} "${_gpath}/${aid}/${version}/${aid}-${version}.${ext}" PARENT_SCOPE)
    else()
        set(${OUT} "${_gpath}/${aid}/${version}/${aid}-${version}-${classifier}.${ext}" PARENT_SCOPE)
    endif()
endfunction()

function(_wpilib_try_download url dest ok)
    get_filename_component(_d "${dest}" DIRECTORY)
    file(MAKE_DIRECTORY "${_d}")
    file(DOWNLOAD "${url}" "${dest}"
        status _status
        TIMEOUT 60
        TLS_VERIFY ON)
    list(GET _status 0 _code)
    if(_code EQUAL 0)
        set(${ok} TRUE PARENT_SCOPE)
    else()
        list(GET _status 1 _msg)
        message(VERBOSE "FindWPILib: download failed (${_code}: ${_msg}) ${url}")
        file(REMOVE ${dest})
        set(${ok} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(_wpilib_resolve_artifact out group artifact version classifier ext)
    set(_repos ${ARGN})

    _wpilib_maven_path(_rel "${group}" "${artifact}" "${version}" "${classifier}" "${ext}")
    set(_local "${WPILib_MAVEN_LOCAL}/${_rel}")

    if(EXISTS "${_local}")
        message(VERBOSE "FindWPILib: [cache] ${artifact}:${classifier}")
        set(${out} "${_local}" PARENT_SCOPE)
        return()
    endif()

    foreach(_repo IN LISTS _repos)
        string(REGEX REPLACE "/$" "" _repo "${_repo}")
        _wpilib_try_download("${_repo}/${_rel}" "${_local}" _ok)
        if(_ok)
            if(NOT WPILib_FIND_QUIETLY)
                message(STATUS "FindWPILib: fetched ${artifact}-${version}-${classifier}.${ext}")
            endif()
            set(${out} "${_local}" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    set(${out} "" PARENT_SCOPE)
endfunction()

function(_wpilib_extract_zip zip dest_dir)
    if(EXISTS "${dest_dir}/.extracted")
        return()
    endif()
    file(MAKE_DIRECTORY "${dest_dir}")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E tar xf "${zip}"
        WORKING_DIRECTORY "${dest_dir}"
        RESULT_VARIABLE _rc
        OUTPUT_QUIET
        ERROR_QUIET
    )
    if(NOT _rc EQUAL 0)
        message(WARNING "FindWPILib: failed to extract ${zip}")
        return()
    endif()
    file(TOUCH "${dest_dir}/.extracted")
endfunction()

if(DEFINED WPILib_YEAR)
    set(_wpilib_year "${WPILib_YEAR}")
elseif(DEFINED WPILib_FIND_VERSION_MAJOR AND WPILib_FIND_VERSION_MAJOR GREATER_EQUAL 2020)
    set(_wpilib_year "${WPILib_FIND_VERSION_MAJOR}")
else()
    set(_wpilib_year "2027")
endif()

if(DEFINED WPILib_ROOT)
    set(_wpilib_home "${WPILib_ROOT}")
elseif(DEFINED ENV{WPILib_ROOT})
    set(_wpilib_home "$ENV{WPILib_ROOT}")
elseif(WIN32)
    set(_wpilib_home "C:/Users/Public/wpilib/${_wpilib_year}")
else()
    file(TO_CMAKE_PATH "$ENV{HOME}/wpilib/${_wpilib_year}" _wpilib_home)
endif()

if(DEFINED WPILib_MAVEN_LOCAL)
    set(_local_maven "${WPILib_MAVEN_LOCAL}")
else()
    set(_local_maven "${_wpilib_home}/maven")
endif()

set(WPILib_MAVEN_RELEASE "https://frcmaven.wpi.edu/artifactory/release"    CACHE STRING "WPILib release Maven URL")
set(WPILib_MAVEN_DEV     "https://frcmaven.wpi.edu/artifactory/development" CACHE STRING "WPILib development Maven URL")
mark_as_advanced(WPILib_MAVEN_RELEASE WPILib_MAVEN_DEV)
set(_wpilib_repos "${WPILib_MAVEN_RELEASE}" "${WPILib_MAVEN_DEV}")

if(NOT EXISTS "${_local_maven}")
    if(NOT WPILib_FIND_QUIETLY)
        message(STATUS "FindWPILib: local Maven cache not found at '${_local_maven}'")
    endif()
    set(_local_maven_exists FALSE)
else()
    set(_local_maven_exists TRUE)
    set(WPILib_MAVEN_LOCAL "${_local_maven}" CACHE PATH "WPILib local Maven cache" FORCE)
endif()

if(_local_maven_exists)
    if(DEFINED WPILib_FIND_VERSION AND NOT WPILib_FIND_VERSION STREQUAL "")
        set(_probe_version "${WPILib_FIND_VERSION}")
    else()
        file(GLOB _ver_dirs
            LIST_DIRECTORIES TRUE
            "${_local_maven}/edu/wpi/first/wpilibc/wpilibc-cpp/*"
        )
        if(_ver_dirs)
            list(SORT _ver_dirs COMPARE NATURAL ORDER DESCENDING)
            list(GET _ver_dirs 0 _newest_dir)
            get_filename_component(_probe_version "${_newest_dir}" NAME)
        else()
            set(_probe_version "")
        endif()
    endif()

    if(_probe_version)
        set(WPILib_VERSION "${_probe_version}" CACHE STRING "Detected WPILib version" FORCE)
        set(WPILib_YEAR    "${_wpilib_year}"   CACHE STRING "WPILib install year"     FORCE)
        if(NOT WPILib_FIND_QUIETLY)
            message(STATUS "FindWPILib: version ${WPILib_VERSION} at ${_local_maven}")
        endif()
    endif()
endif()

if(WPILib_FIND_COMPONENTS)
    set(_requested_components ${WPILib_FIND_COMPONENTS})
else()
    set(_requested_components ${_WPILib_ALL_COMPONENTS})
endif()

if(NOT TARGET WPILib::WPILib)
    add_library(WPILib::WPILib INTERFACE IMPORTED GLOBAL)
endif()

foreach(_comp IN LISTS _requested_components)
    list(FIND _WPILib_ALL_COMPONENTS "${_comp}" _comp_idx)
    if(_comp_idx EQUAL -1)
        message(WARNING "FindWPILib: unknown component '${_comp}' — ignoring")
        set(WPILib_${_comp}_FOUND FALSE)
        continue()
    endif()

    if(TARGET "WPILib::${_comp}")
        set(WPILib_${_comp}_FOUND TRUE)
        continue()
    endif()

    if(NOT _local_maven_exists OR NOT DEFINED WPILib_VERSION)
        set(WPILib_${_comp}_FOUND FALSE)
        continue()
    endif()

    set(_group    "${_WPILib_MAVEN_GROUP_${_comp}}")
    set(_artifact "${_WPILib_MAVEN_ARTIFACT_${_comp}}")
    set(_version  "${WPILib_VERSION}")
    set(_extract_base "${_local_maven}/_extracted/wpilib/${_comp}-${_version}")

    _wpilib_resolve_artifact(_headers_zip
        "${_group}" "${_artifact}" "${_version}" "headers" "zip"
        ${_wpilib_repos}
    )
    set(_headers_dir "")
    if(_headers_zip)
        set(_headers_dir "${_extract_base}/headers")
        _wpilib_extract_zip("${_headers_zip}" "${_headers_dir}")
        if(NOT EXISTS "${_headers_dir}/.extracted")
            set(_headers_dir "")
        endif()
    endif()

    _wpilib_resolve_artifact(_native_zip
        "${_group}" "${_artifact}" "${_version}" "${WPILIB_TARGET_PLATFORM}" "zip"
        ${_wpilib_repos}
    )
    set(_native_dir "")
    set(_so_files "")
    if(_native_zip)
        set(_native_dir "${_extract_base}/native")
        _wpilib_extract_zip("${_native_zip}" "${_native_dir}")
        if(EXISTS "${_native_dir}/.extracted")
            file(GLOB_RECURSE _so_files
                "${_native_dir}/*.so"
                "${_native_dir}/*.so.*"
            )
        endif()
    endif()

    if(_headers_dir OR _so_files)
        add_library("WPILib::${_comp}" INTERFACE IMPORTED GLOBAL)

        if(_headers_dir AND IS_DIRECTORY "${_headers_dir}")
            set_property(TARGET "WPILib::${_comp}" APPEND PROPERTY
                INTERFACE_INCLUDE_DIRECTORIES "${_headers_dir}")
        endif()

        if(_so_files)
            set_property(TARGET "WPILib::${_comp}" APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES ${_so_files})
        endif()

        # Wire into aggregate
        set_property(TARGET WPILib::WPILib APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES "WPILib::${_comp}")

        set(WPILib_${_comp}_FOUND TRUE)
        message(VERBOSE "FindWPILib: component '${_comp}' OK")
    else()
        set(WPILib_${_comp}_FOUND FALSE)
        message(VERBOSE "FindWPILib: component '${_comp}' NOT FOUND (no headers or binaries)")
    endif()
endforeach()

set(_required_found_vars WPILib_VERSION WPILib_MAVEN_LOCAL)
foreach(_comp IN LISTS _requested_components)
    list(FIND WPILib_FIND_COMPONENTS "${_comp}" _in_required)
    if(_in_required GREATER -1 AND WPILib_FIND_REQUIRED_${_comp})
        list(APPEND _required_found_vars "WPILib_${_comp}_FOUND")
    endif()
endforeach()
if(NOT WPILib_FIND_COMPONENTS)
    list(APPEND _required_found_vars "WPILib_wpilibc_FOUND")
endif()

find_package_handle_standard_args(WPILib
    REQUIRED_VARS   ${_required_found_vars}
    VERSION_VAR     WPILib_VERSION
    HANDLE_COMPONENTS
    REASON_FAILURE_MESSAGE
        "WPILib ${_wpilib_year} was not found in '${_local_maven}'.\n"
        "Install WPILib from https://github.com/wpilibsuite/allwpilib/releases "
        "or set WPILib_ROOT / WPILib_MAVEN_LOCAL."
)
