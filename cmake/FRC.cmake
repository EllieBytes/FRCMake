cmake_minimum_required(VERSION 3.21)

if(NOT DEFINED SYSTEMCORE_DEPLOY_USER)
    set(SYSTEMCORE_DEPLOY_USER "systemcore"
        CACHE STRING "SSH user for deployment.")
endif()

if(NOT DEFINED SYSTEMCORE_DEPLOY_PASS)
    set(SYSTEMCORE_DEPLOY_PASS "systemcore"
        CACHE STRING "SSH password for deployment.")
endif()

if(NOT DEFINED SYSTEMCORE_DEPLOY_HOST)
    set(SYSTEMCORE_DEPLOY_HOST "172.30.0.1"
        CACHE STRING "Hostname/IP for deployment.")
endif()

if(NOT DEFINED SSH_EXE)
    find_program(SSH_EXE NAMES ssh REQUIRED)
endif()

if(NOT DEFINED SCP_EXE)
    find_program(SCP_EXE NAMES scp REQUIRED)
endif()

if(NOT DEFINED FRC_TEAM_NUMBER "7674" CACHE STRING "Team number.")

set(SYSTEMCORE_REMOTE_HOME "/home/systemcore"
    CACHE STRING "Remote home directory.")

set(SYSTEMCORE_REMOTE_BINARY "${SYSTEMCORE_REMOTE_HOME}/frcUserProgram"
    CACHE STRING "Remote path to install the robot code binary to")

set(SYSTEMCORE_REMOTE_DEPLOY_DIR "${SYSTEMCORE_REMOTE_HOME}/deploy"
    CACHE STRING "Remote deploy-asset target.")

mark_as_advanced(SYSTEMCORE_REMOTE_HOME SYSTEMCORE_REMOTE_BINARY SYSTEMCORE_REMOTE_DEPLOY_DIR)

set(_SC_SSH_OPTS
    "-o StrictHostKeyChecking=no"
    "-o BatchMode=yes"
    "-o ConnectTimeout=10")

list(JOIN _SC_SSH_OPTS " " _SC_SSH_OPTS_STR)

function(_sc_target_string out_var HOST)
    set(${out_var} "${SYSTEMCORE_DEPLOY_USER}@${HOST}" PARENT_SCOPE)
endfunction()

function(frc_add_deploy_target TARGET)
    cmake_parse_arguments(PARSE_ARGV 0 SC_DEPLOY
        ""
        "DEPLOY_DIR;DELETE_OLD;HOST"
        "")

    if(DEFINED SC_DEPLOY_DEPLOY_DIR)
        set(_local_deploy "${SC_DEPLOY_DEPLOY_DIR")
    elseif(DEFINED SYSTEMCORE_LOCAL_DEPLOY_DIR)
        set(_local_deploy "${SYSTEMCORE_LOCAL_DEPLOY_DIR}")
    else()
        set(_local_deploy "${CMAKE_SOURCE_DIR}/src/main/deploy")
    endif()

    if(DEFINED SC_DEPLOY_HOST)
        set(_host "${SC_DEPLOY_HOST}")
    else()
        set(_host "${SYSTEMCORE_DEPLOY_HOST}")
    endif()

    _sc_target_string(_ssh_target _host)

    set(_ssh "${SSH_EXE} ${_SC_SSH_OPTS_STR} ${_ssh_target}")
    set(_scp_opts "${_SC_SSH_OPTS_STR}")

    add_custom_target(frc_deploy_program
        DEPENDS "${TARGET}"
        COMMENT "Deploying ${TARGET} to ${_ssh_target}:${SYSTEMCORE_REMOTE_BINARY}"
        VERBATIM
        COMMAND ${_ssh}
            "sudo systemctl stop robot || true"

        COMMAND ${SCP_EXE} ${_scp_opts}
            "$<TARGET_FILE:${TARGET}>"
            "${_ssh_target}:${SYSTEMCORE_REMOTE_BINARY}"

        COMMAND ${_ssh}
            "chmod +x ${SYSTEMCORE_REMOTE_BINARY} && sudo systemctl start robot")

        if(EXISTS "${_local_deploy}" AND IS_DIRECTORY ${_local_deploy})
            set(_pre_asset_cmds "")
            if(SC_DEPLOY_DELETE_OLD)
                list(APPEND _pre_asset_cmds
                    COMMAND ${_ssh}
                        "rm -fr ${SYSTEMCORE_REMOTE_DEPLOY_DIR} && mkdir -p ${SYSTEMCORE_REMOTE_DEPLOY_DIR}")
            else()
                list(APPEND _pre_asset_cmds
                    COMMAND ${_ssh}
                        "mkdir -p ${SYSTEMCORE_REMOTE_DEPLOY_DIR}")
            endif()

            add_custom_target(frc_deploy_assets
                COMMENT "Deploying assets from ${_local_deploy} to ${_ssh_target}:${SYSTEMCORE_REMOTE_DEPLOY_DIR}"
                VERBATIM
                ${_pre_asset_cmds}

                COMMAND
                    ${SCP_EXE} ${_scp_opts} -r
                        "_local_deploy/*"
                        "${_ssh_target}:${SYSTEMCORE_REMOTE_DEPLOY_DIR}")
        else()
            add_custom_target(frc_deploy_assets
                COMMENT "Nothing to do for `systemcore_deploy_assets`")

            if(DEFINED SC_DEPLOY_DEPLOY_DIR)
                message(WARNING
                    "systemcore_add_deploy_target: DEPLOY_DIR `${SC_DEPLOY_DEPLOY_DIR}` does not exist."
                    "Asset deployment will be skipped.")
            endif()
        endif()

        add_custom_target(frc_deploy
            COMMENT "Deploying robot program... to `${_host}`"
            DEPENDS systemcore_deploy systemcore_deploy_assets)
endfunction()
