#!/bin/bash

#### Init Stream library

#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -e

## Start Stream Service
# sleep to prevent cpu cycle spikes
function construct_streamer {
    local cams sleep_pid
    # See configparser.sh L#53
    log_msg "Try to start configured Cams / Services..."
    for cams in $(configured_cams); do
        mode="$(get_param "cam ${cams}" mode)"
        check_section "${cams}"
        case ${mode} in
            mjpg)
                MJPG_INSTANCES+=( "${cams}" )
            ;;
            rtsp)
                RTSP_INSTANCES+=( "${cams}" )
            ;;
            webrtc)
                RTSP_INSTANCES+=( "${cams}" )
                RUN_WEBRTC=1
            ;;
            ?|*)
                unknown_mode_msg
                MJPG_INSTANCES+=( "${cams}" )

            ;;
        esac
    done
    if [ "${#MJPG_INSTANCES[@]}" != "0" ]; then
        run_mjpg "${MJPG_INSTANCES[*]}"
    fi
    if [ "${#RTSP_INSTANCES[@]}" != "0" ]; then
        run_rtsp "${RTSP_INSTANCES[*]}"
    fi
    if [ "${RUN_WEBRTC}" == "1" ]; then
        while true; do
            if [ "$(pidof ffmpeg | wc -w)" != "${#RTSP_INSTANCES[@]}" ]; then
                sleep 1
            else
                run_webrtc "${RTSP_INSTANCES[*]}"
                break;
            fi
        done
    fi
    sleep 8 & sleep_pid="$!" ; wait "${sleep_pid}"
    log_msg " ... Done!"
}
