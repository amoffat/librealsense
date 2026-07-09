#!/usr/bin/env bash

set -euo pipefail

# By using --device-cgroup-rule flag we grant the docker continer permissions -
# to the camera and usb endpoints of the machine.
# It also mounts the /dev directory of the host platform on the contianer.
# If the host is running Wayland, we still forward X11 so GUI apps can use
# XWayland on the host.
docker_args=(
    -it
    --rm
    -v /dev:/dev
    --device-cgroup-rule "c 81:* rmw"
    --device-cgroup-rule "c 189:* rmw"
)

if [[ -n "${DISPLAY:-}" ]]; then
    docker_args+=(
        -e "DISPLAY=${DISPLAY}"
        -e QT_QPA_PLATFORM=xcb
        -e GDK_BACKEND=x11
    )
fi

xauthority_file="${XAUTHORITY:-${HOME}/.Xauthority}"
if [[ -f "${xauthority_file}" ]]; then
    docker_args+=(
        -e XAUTHORITY=/tmp/.docker.xauth
        -v "${xauthority_file}:/tmp/.docker.xauth:ro"
    )
fi

if [[ -d /tmp/.X11-unix ]]; then
    docker_args+=(
        -v /tmp/.X11-unix:/tmp/.X11-unix:ro
    )
elif [[ -n "${XDG_RUNTIME_DIR:-}" && -d "${XDG_RUNTIME_DIR}/X11-unix" ]]; then
    docker_args+=(
        -v "${XDG_RUNTIME_DIR}/X11-unix:/tmp/.X11-unix:ro"
    )
fi

docker run "${docker_args[@]}" librealsense "$@"
