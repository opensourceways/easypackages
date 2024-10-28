#!/bin/bash

CCI_SRC=/c/compass-ci

# shellcheck disable=SC1091
source $CCI_SRC/container/defconfig.sh

docker_rm openeuler-package-update
load_cci_defaults

load_service_authentication

cmd=(
        docker run
        --name openeuler-package-update
        -it
        -d
        -v /srv:/srv:ro #（挂载的submit执行job结果父目录，便于容器内查看执行结果）
        -v "$HOME/.config:/root/.config:ro" #（挂载的当前账号的compassci账密信息，用于容器内submit提交job）
        -v /etc/compass-ci:/etc/compass-ci:ro #固定不变
        -v /etc/localtime:/etc/localtime:ro #固定不变
        openeuler-package-migration-update:latest
)

"${cmd[@]}"