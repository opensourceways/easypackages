#!/bin/bash

# shellcheck disable=SC1091
source ./lib_rpm.sh

#-----------------------------------------------------------------
# 功能描述：
#       将待迁移清单，拆分为多个小批量（方便下载、提交、监视），
#       每个小批量100个源码包，会使用scp将记录对应源码包从
#       autospec服务器下载到z9指定目录，并批量提交执行
#
# 参数说明：
#       src_list：待迁移的清单
#       iterarte_list：拆分为不同的迭代文件名（生成文件时，会在后面加上序号）
#       arch_type：当前架构类型
#       project_log_file：日志路径
#       src_rpm_path_dest：从autospec服务器下载的源码包存放路径
#-----------------------------------------------------------------

base_path="/home/lxb/rpmbuild/work/autospec_rpm_mv"
# autospec_rpm_src_list_aarch64 test_list
src_list="${base_path}/data/autospec_rpm_src_list_aarch64"
iterarte_list="${src_list}_iterate"
arch_type="aarch64"

# log日志位置
log_dir_name=$(basename ${src_list})
# shellcheck disable=SC2034
project_log_file="${base_path}/log/log-${log_dir_name}"

# 下载的源码包存放位置
src_rpm_path_dest="/srv/result/rpmbuild-test-lxb/tmp/"


# proc_num处理数量
proc_num=0
# iterate_num 迭代计数
iterate_num=1
# submit_jobs_flag 是批量提交标志
submit_jobs_flag=1
# 每个小批量的源清单
list_file=""

# 批量提交
submit_jobs()
{
    if [ 0 -eq "${submit_jobs_flag}" ]; then 
        return 0
    fi

    log_msg "[log] iterarte ${iterate_num} submit jobs"

    log_dir_name=$(basename ${src_list})
    submit_log_dir="${base_path}/log/submit-log-${log_dir_name}"
    log_msg "[log] submit log path : ${submit_log_dir}"

    command="sh ./submit-repair.sh \
            -l ${list_file} \
            -h ${arch_type} \
            -t vm-2p8g \
            -p check_rpm_install=yes \
            -y ./autospec-mv.yaml \
            -g ${submit_log_dir}"

    log_msg "[log] submit content: ${command}"
    bash -c "${command}" > /dev/null

    submit_bum=$(sed -n '$=' "${list_file}")
    tail -n "${submit_bum}" "${submit_log_dir}/submit-succ-list" >> "${base_path}/data/autospec_check_build_result_list"

    submit_jobs_flag=0
}

log_msg "autospec rpm transfer begin ..."
log_msg ""
log_msg "[log] iterater start ${iterate_num} ..."
while read -r line 
do
    [ -z "$line" ] && continue

    while true
    do
        src_rpm_num_tmp=$(find "${src_rpm_path_dest}" -maxdepth 1 -type f | wc -l)
        if [ "${src_rpm_num_tmp}" -le 4000 ]; then
            break
        fi

        # 睡眠10分钟
        log_msg "[log] num[${src_rpm_num_tmp}], sleep 600 seconds ..."
        sleep 600
    done

    line_arr=()
    read -ra line_arr <<< "$line"

    src_rpm_path_src="${line_arr[1]}"

    # 下载源码包
    list_file="${iterarte_list}_${iterate_num}"
    password="xx"
    scp_path="yy@xx.xx.xx.xx:${src_rpm_path_src}"
    sshpass -p ${password} scp "${scp_path}" "${src_rpm_path_dest}"

    src_rpm_name=$(basename "${src_rpm_path_src}")
    if [ ! -f "${src_rpm_path_dest}/${src_rpm_name}" ]; then 
        log_msg "[error] src_rpm scp fail: ${src_rpm_path_src} ${src_rpm_path_dest}/${src_rpm_name}"
        continue
    fi

    echo "wget:$line" >> "${list_file}"
    submit_jobs_flag=1
    ((proc_num++))

    # 拆分批次（一次100个）
    if [[ ${proc_num} != 0 && $((proc_num % 100)) == 0 ]]; then 
        # 提交任务
        submit_jobs

        log_msg "[log] iterarte end ${iterate_num} ..."
        log_msg ""

        log_msg "[log] sleep 600 seconds ..."
        sleep 600

        ((iterate_num++))
        log_msg "[log] iterarte start ${iterate_num} ..."
    fi
done < "${src_list}"

# 最后一次提交，防止没有满足4000个
submit_jobs

log_msg "[log] iterarte end ${iterate_num} ..."
log_msg ""
log_msg "autospec rpm transfer success"