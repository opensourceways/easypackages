#!/bin/bash

#----------------------------------------------------------------------------
# 功能描述：
#       1、根据src_xlm_urls, 生成二进制包列表
#           （格式：rpm_name rpm_version）
#
#   参数说明：
#       $1: 系统名称.  例如：openeuler
#       $2: 源系统版本.  例如：24.03-LTS
#       $3: rpm源码仓库地址.  例如："https://xx https://yy"
#----------------------------------------------------------------------------

# shellcheck disable=SC1091
source ./../lib/lib_rpm.sh

if [ 3 -ne $# ]; then 
    echo "[error] argument num error: $*"
    exit 1
fi

if [ -z "${RPM_WATCH_PROJECT_DATA_OS_PATH}" ]; then 
    echo "[error] not define RPM_WATCH_PROJECT_DATA_OS_PATH"
    exit 1
fi

if [ -z "${RPM_WATCH_PROJECT_DATA_DATA_PATH}" ]; then 
    echo "[error] not define RPM_WATCH_PROJECT_DATA_DATA_PATH"
    exit 1
fi

os_name="$1"
os_version="$2"
src_xlm_urls="$3"

base_path="${RPM_WATCH_PROJECT_DATA_OS_PATH}/${os_name}/${os_version}"
rpm_install_list_name="install_list_${os_name}_${os_version}"
rpm_install_list="${RPM_WATCH_PROJECT_DATA_DATA_PATH}/${rpm_install_list_name}"

log_msg "os [${os_name}]-[${os_version}] proc ..."

# 下载源码包信息
download_source_primary_xml "${base_path}" "${rpm_install_list_name}" "${src_xlm_urls}"
cp -f "${base_path}/${rpm_install_list_name}"  "${rpm_install_list}"
