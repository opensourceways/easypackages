#!/bin/bash

# shellcheck disable=SC1091
source ./rpm_transfer/repo_cfg.sh
source ./rpm_transfer/lib/lib_rpm.sh

#-----------------------------------------------------------------
# 功能介绍：
#       根据rpm源仓元素据文件列表，获取rpm源码迁移清单
#
# 参数说明:
#       src_xlm_urls: rpm源仓元素据文件列表 (参考repo_cfg)
#
# 输出：
#       rpm_src_list_${src_os_name}_${src_os_version}: rpm源码迁移清单
#           文件格式: repo_addr（rpm源码包下载链接）
#-----------------------------------------------------------------

# rpm_src_xlm_urls可设置的值在./rpm_transfer/repo_cfg.sh文件中配置
# shellcheck disable=SC2154
rpm_src_xlm_urls="${src_xlm_url_centos_9[*]}"

# 源系统名称、版本，用于区分迁移清单
src_os_name="centos"
src_os_version="9-stream"

base_path="./"

rpm_src_list_name="rpm_src_list_${src_os_name}_${src_os_version}"

# 下载源码包信息
download_source_primary_xml "${base_path}" "${rpm_src_list_name}" "${rpm_src_xlm_urls}"

# 处理文件 (只保留源码包下载链接)
rpm_src_list="${base_path}/${rpm_src_list_name}"
rpm_src_list_tmp="${rpm_src_list}_tmp"
echo -n "" > "${rpm_src_list_tmp}"
while read -r line
do
    [ -z "${line}" ] && continue
    echo "${line}" | awk -F' ' '{print $1}' >> "${rpm_src_list_tmp}"
done < "${rpm_src_list}"

mv -f "${rpm_src_list_tmp}" "${rpm_src_list}"
