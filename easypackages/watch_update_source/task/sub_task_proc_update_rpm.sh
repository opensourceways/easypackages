#!/bin/bash

#----------------------------------------------------------------------------
#   功能描述：
#       1、根据src_xlm_urls，生成源码包列表
#           （格式：repo_addr rpm_name rpm_version）
#       2、从openeuler中过滤掉已安装包，以及history列表中的包
#       3、生成当前需要迁移的更新包，并提交批量迁移任务
#
#   参数说明：
#       $1: 源系统名称.  例如：centos
#       $2: 源系统版本.  例如：9-stream
#       $3: 目标系统名称.  例如：openeuler
#       $4: 目标系统版本.  例如：24.03-LTS
#       $5: rpm源码包仓库地址.  例如："https://xx https://yy"
#----------------------------------------------------------------------------

# shellcheck disable=SC1091
source ./../lib/lib_rpm.sh

if [ 5 -ne $# ]; then 
    echo "[error] argument num error: $*"
    exit 1
fi

if [ -z "${RPM_WATCH_PROJECT_LOG_PATH}" ]; then 
    echo "[error] not define RPM_WATCH_PROJECT_LOG_PATH"
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

src_os_name="$1"
src_os_version="$2"
des_os_name="$3"
des_os_version="$4"
src_xlm_urls="$5"

base_path="${RPM_WATCH_PROJECT_DATA_OS_PATH}/${src_os_name}/${src_os_version}"
bak_path="${base_path}/bak"
rpm_src_list="${base_path}/rpm_src_list"
rpm_install_list="${RPM_WATCH_PROJECT_DATA_DATA_PATH}/exist_list_${des_os_name}_${des_os_version}"
rpm_src_history_list="${RPM_WATCH_PROJECT_DATA_DATA_PATH}/rpm_src_history_list_${src_os_name}_${src_os_version}"
arch_type_arr=("aarch64" "x86_64")

log_msg ""
log_msg "src_os [${src_os_name}]-[${src_os_version}], des_os [${des_os_name}]-[${des_os_version}] proc ..."

# 备份历史文件
rpm_src_list_name=$(basename "${rpm_src_list}")
current_date=$(date +"%Y%m%d-%H%M%S")
if [ -d "${base_path}" ]; then 
    find "${base_path}" -maxdepth 1 -type f -name "${rpm_src_list_name}*" | while read -r file
    do
        if [ ! -d "${bak_path}" ]; then 
            mkdir -p "${bak_path}"
        fi
        file_name=$(basename "${file}")
        mv "${file}" "${bak_path}/${file_name}-${current_date}"
    done
else 
    mkdir -p "${base_path}"
fi

# 下载源码包信息
download_source_primary_xml "${base_path}" "${rpm_src_list_name}" "${src_xlm_urls}"

# 过滤历史包
filter_src_rpm_by_file "${rpm_src_list}" "${rpm_src_history_list}"

# 过滤已安装rpm包
while read -r line; do
    line_arr=()
    read -ra line_arr <<< "${line}"
    #echo "${line_arr[1]} ${line_arr[2]}"

    # 过滤出需要构建的aarch64、x86_64的包
    for aarch_type in "${arch_type_arr[@]}"; do
        if [ -f "${rpm_install_list}_${aarch_type}" ] && grep -q -F "${line_arr[1]} ${line_arr[2]}" "${rpm_install_list}_${aarch_type}"; then 
            continue
        fi

        echo "$line" >> "${rpm_src_list}_${aarch_type}"
    done
done < "${rpm_src_list}"

# 日志文件
time=$(date +"%Y%m%d-%H%M%S")

# 如果历史文件不存在，则第一次作为铺数据（避免大批量提交）
if [ ! -f "${rpm_src_history_list}" ]; then
    # 提交任务
    #arch_type_arr=("aarch64")
    for aarch_type in "${arch_type_arr[@]}"; do
        if [ -f "${rpm_src_list}_${aarch_type}" ]; then 
            submit_log_dir="${RPM_WATCH_PROJECT_LOG_PATH}/submit-log-${src_os_name}_${src_os_version}_${aarch_type}-${time}"
            log_msg "[log] submit log path : ${submit_log_dir}"

            command="sh ../utils/submit-repair.sh \
                    -l ${rpm_src_list}_${aarch_type} \
                    -h ${aarch_type} \
                    -t vm-2p8g \
                    -p check_rpm_install=yes \
                    -y ../job_yaml/${src_os_name}_${src_os_version}.yaml \
                    -g ${submit_log_dir}"

            log_msg "[log] submit content: ${command}"
            bash -c "${command}" > /dev/null
        fi
    done
fi

# 保存到历史列表
cat "${rpm_src_list}" >> "${rpm_src_history_list}"
