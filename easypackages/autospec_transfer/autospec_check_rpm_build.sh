#!/bin/bash

# shellcheck disable=SC1091
source ./lib_rpm.sh

#-----------------------------------------------------------------
# 功能描述：
#       截取检查清单（autospec_check_build_result_list）最新的记录，
#       追加到检查处理清单（autospec_check_build_result_list_ing），
#       并循环处理清单，检查任务结果日志，如果使用完成，则删除源码包
#
# 参数说明：
#       src_list： 指定构建中输出的检查清单
#       wget_rpm_path：下载的源码包保存路径
#       wget_rpm_flag：run脚本中wget之后，打印的日志（如果日志文件中
#               存在，则表示已经加载了源码包，对应源码包则可以删除）
#       proc_file：当前程序会循环处理的文件（还未删除对应的源码包）
#-----------------------------------------------------------------

base_path="/home/lxb/rpmbuild/work/autospec_rpm_mv"
src_list="${base_path}/data/autospec_check_build_result_list"

# shellcheck disable=SC2034
project_log_file="${base_path}/log/log-delete_autospec_rpm"

# 下载的源码包保存的路径
wget_rpm_path="/srv/result/rpmbuild-test-lxb/tmp"
# 构建过程中，执行机中wget之后会打印的日志
wget_rpm_flag="[log] src rpm from wget succ."

# 检查处理清单
proc_file="${src_list}_ing"
proc_file_tmp="${src_list}_ing_tmp"

last_position=1
while true
do
    src_list_record_num=0
    if [ -f "${src_list}" ]; then 
        src_list_record_num=$(sed -n '$=' "${src_list}")
    fi

    proc_list_record_num=0
    if [ -f "${proc_file}" ]; then 
        proc_list_record_num=$(sed -n '$=' "${proc_file}")
    fi

    # 存在新的数据，或者存在未删除的老数据
    if [ "${src_list_record_num}" -gt "${last_position}" ] || [ "${proc_list_record_num}" -gt 0 ]; then
        log_msg "[log] check start: file position[${last_position}]"

        # 移动文件
        rm -f "${proc_file_tmp}"
        ((last_position++))
        sed -n "${last_position},\$p" "${src_list}" >> "${proc_file}"

        # 处理文件
        while read -r line
        do
            [ -z "${line}" ] && continue

            rpm_inf_arr=()
            read -ra rpm_inf_arr <<< "${line}"
            src_rpm_name="${rpm_inf_arr[0]}"
            src_rpm_name="${src_rpm_name##*wget:}"
            job_result_path="${rpm_inf_arr[2]}"
            if [ -n "${job_result_path}" ] && [ -f "${job_result_path}/output" ]; then
                # 已下载使用的标志
                if grep -q -F "${wget_rpm_flag}" "${job_result_path}/output"; then
                    [ -f "${wget_rpm_path}/${src_rpm_name}" ] && rm -f "${wget_rpm_path}/${src_rpm_name}"
                    log_msg "[log] src rpm: ${src_rpm_name}"
                    continue
                fi
            fi

            # 还未删除的记录
            echo "${line}" >> "${proc_file_tmp}"
        done < "${proc_file}"
        # 重命名文件
        mv -f "${proc_file_tmp}" "${proc_file}"
    fi

    last_position=${src_list_record_num}

    # 睡眠10分钟
    log_msg "[log] last_position[${last_position}] src_num[${src_list_record_num}] proc_num[${proc_list_record_num}]"
    log_msg "sleep 600 seconds ..."
    log_msg ""
    sleep 600
done
