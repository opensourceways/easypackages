#!/bin/bash

#-------------------------------------------------------------------------
#   功能描述：
#       监控rpm仓库源更新，并针对更新的rpm进行迁移
#
#   参数介绍：
#       RPM_WATCH_PROJECT_PATH: 项目路径
#       RPM_WATCH_PROJECT_DATA_OS_PATH: 各系统的临时数据
#       RPM_WATCH_PROJECT_DATA_DATA_PATH: 项目执行历史数据
#       RPM_WATCH_PROJECT_LOG_PATH: 项目日志路径
#       
#       project_log_file: 项目日志文件
#-------------------------------------------------------------------------

# shellcheck disable=SC1091
source ./../lib/lib_rpm.sh
source ./../config/repo_cfg.sh

export RPM_WATCH_PROJECT_PATH="${HOME}/rpmbuild/watch_update_source"

export RPM_WATCH_PROJECT_DATA_OS_PATH="${RPM_WATCH_PROJECT_PATH}/data/os"
export RPM_WATCH_PROJECT_DATA_DATA_PATH="${RPM_WATCH_PROJECT_PATH}/data/data"
export RPM_WATCH_PROJECT_LOG_PATH="${RPM_WATCH_PROJECT_PATH}/log"
export project_log_file="${RPM_WATCH_PROJECT_LOG_PATH}/log_crontab_task"

# 检查
project_check()
{
    if [ -z "${RPM_WATCH_PROJECT_PATH}" ]; then 
        echo "[error] not define RPM_WATCH_PROJECT_PATH"
        exit 1
    fi
}

# 初始化
project_init()
{
    paths=("${RPM_WATCH_PROJECT_DATA_OS_PATH}" "${RPM_WATCH_PROJECT_DATA_DATA_PATH}" "${RPM_WATCH_PROJECT_LOG_PATH}")
    for path in "${paths[@]}"; do 
        if [ ! -d "${path}" ]; then 
            mkdir -p "${path}"
        fi
    done
}

project_check
project_init

# 当前任务日志分割
time=$(date +"%Y%m%d-%H%M%S")
log_msg ""
log_msg "-------------------------------------------------------"
log_msg "rpm watch task start: ${time}"
log_msg ""

# 生成openeuler的清单
src_xml_urls=$(printf "%s " "${binary_xml_url_openeuler_24_03_LTS[@]}")
sh sub_task_proc_des_os_rpm_list.sh "openeuler" "24_03_LTS" "${src_xml_urls}"


# centos9的源监控
src_xml_urls=$(printf "%s " "${src_xlm_url_centos_9[@]}")
sh sub_task_proc_update_rpm.sh "centos" "9-stream" "openeuler" "24_03_LTS" "${src_xml_urls}"

# fedora40的源监控
src_xml_urls=$(printf "%s " "${src_xlm_url_fedora_40[@]}")
sh sub_task_proc_update_rpm.sh "fedora" "40" "openeuler" "24_03_LTS" "${src_xml_urls}"
