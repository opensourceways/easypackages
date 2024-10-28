#!/bin/bash
# 这个脚本最好在 tmux 上执行，防止中断
rpm_src_list=rpm_next_iterate_list.txt
aarch_type=aarch64
job_config=job-centos9.yaml
# 需要创建一个本地执行文件的目录
submit_log_dir=submit-log-"$(date +"%Y%m%d-%H%M%S")"

sh -x submit_batch_rpm.sh -l ${rpm_src_list} \
                    -h ${aarch_type} \
                    -t vm-2p8g \
                    -p check_rpm_install=yes \
                    -y ${job_config} \
                    -g "$submit_log_dir"
