#!/bin/bash

# shellcheck disable=SC1091
source ./lib_rpm.sh


base_path="/home/lxb/rpmbuild/work/autospec_rpm_mv"
src_list="${base_path}/data/autospec_rpm_src_list_aarch64"
iterarte_list="${src_list}_iterate"
arch_type="aarch64"

#log_dir_name=$(basename ${src_list})
#project_log_file="${base_path}/log/log-${log_dir_name}"

src_rpm_path_dest="/srv/result/rpmbuild-test-lxb/tmp/"


proc_num=0
iterate_num=1
submit_jobs_flag=1
list_file=""
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

    submit_jobs_flag=0
}

log_msg "autospec rpm transfer begin ..."
log_msg ""
log_msg "[log] iterater start ${iterate_num} ..."
while read -r line 
do
    [ -z "$line" ] && continue

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

    # 拆分批次（一次4000个）
    if [[ ${proc_num} != 0 && $((proc_num % 4000)) == 0 ]]; then 
        # 提交任务
        submit_jobs

        log_msg "[log] iterarte end ${iterate_num} ..."

        ((iterate_num++))
        while true
        do
            src_rpm_num_tmp=$(find "${src_rpm_path_dest}" -maxdepth 1 -type f | wc -l)
            if [ "${src_rpm_num_tmp}" -eq 0 ]; then
                log_msg ""
                log_msg "[log] iterarte start ${iterate_num} ..."
                break
            fi

            # 睡眠10分钟，防止当前提交任务抢占机器
            log_msg "sleep 600 seconds ..."
            sleep 600
        done
    fi
done < "${src_list}"

# 最后一次提交，防止没有满足4000个
submit_jobs

log_msg "[log] iterarte end ${iterate_num} ..."
log_msg ""
log_msg "autospec rpm transfer success"