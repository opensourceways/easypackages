#! /bin/bash

#----------------------------------------------------------------------------------
# 参数介绍:
#       -l: (list) 指定批量list文件. 
#       -j: (job) 指定job id的list文件
#       -o: (output) 指定当前脚本输出路径
#           默认${HOME}/rpmbuild/result/result
#       -r: (result) 指定rpmbuild构建输出的路径，指定到/srv/result/rpmbuild-fedora40-aarch64类似层级即可
# 
#
# 自定义参数：
#   RPMBUILD_SUCC_FLAG: rpmbuild构建成功标志（output文件中）
#   RPMBUILD_INSTALL_FAIL_FLAG: rpm构建-安装失败标志
#   RPMBUILD_INSTALL_FLAGED: rpm包已安装标志
#----------------------------------------------------------------------------------

SRC_LIST=""
JOB_ID_LIST=""
RESULT_PATH="${HOME}/rpmbuild/result"
RPM_BUILD_RES_PATH=""

# 参数说明，请见以上 “自定义参数” 说明部分
RPMBUILD_SUCC_FLAG="rpmbuild success"
RPMBUILD_INSTALLED_FLAG="[log] success, rpm already installed"
RPMBUILD_INSTALL_FAIL_FLAG="fail to local install rpms"
    

while getopts ":l:j:o:r:" opt;
do
    case $opt in
        l)
            SRC_LIST=$OPTARG
            ;;
        j)
            JOB_ID_LIST=$OPTARG
            ;;
        o)
            RESULT_PATH=$OPTARG
            ;;
        r)
            RPM_BUILD_RES_PATH=$OPTARG
            ;;
        \?)
            echo "[error] invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "[error] option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

#-------------------------------


log_msg()
{
    if [ -z "${log_file}" ]; then 
        echo "$@"
    else
        if [ ! -f "${log_file}" ]; then
            log_file_path=$(dirname "${log_file}")
            if [ ! -d "${log_file_path}" ]; then
                mkdir -p "${log_file_path}"
                chmod 775 "${log_file_path}"
            fi
        fi

        echo "$@" | tee -a "${log_file}"
    fi
}

init()
{
    RESULT_PATH="${RESULT_PATH}/result"
    log_msg "[log] result path: [${RESULT_PATH}]"

    # 备份上次统计的结果文件
    if [ -d "${RESULT_PATH}" ]; then 
        file_date=$(date +"%Y%m%d-%H%M%S")
        old_dir="${RESULT_PATH}/../result_${file_date}"
        mv "${RESULT_PATH}" "${old_dir}"
    fi

    # 统计结果文件
    res_job_rpm="${RESULT_PATH}/res_job_rpm"                                    # 已处理文件（格式：job_id ## rpm_name ## 日志目录）
    log_file="${RESULT_PATH}/execute_log"

    dir_fail_spec="${RESULT_PATH}/specs_fail"                                   # 失败rpm的spec文件目录
    dir_fail_log="${RESULT_PATH}/logs_fail"                                     # 失败rpm的log文件目录
    rpm_build_succ_file="${RESULT_PATH}/rpm_succ_list"                          # 构建成功清单
    rpm_build_install_succ_file="${RESULT_PATH}/rpm_install_succ_list"          # 安装成功清单
    rpm_build_s_install_f_file="${RESULT_PATH}/rpm_install_fail_list"           # 安装失败清单
    rpm_build_fail_file="${RESULT_PATH}/rpm_fail_list"                          # 失败清单
    rpm_build_installed_file="${RESULT_PATH}/rpm_installed_list"                # 已经存在的rpm包（无需安装）清单
    rpm_build_next_iteate="${RESULT_PATH}/rpm_next_iterate_list"                # 下一轮迭代清单

    mkdir -p "${dir_fail_spec}"
    mkdir -p "${dir_fail_log}"

    # 新建文件
    files=("${res_job_rpm}" "${rpm_build_succ_file}" "${rpm_build_installed_file}" "${log_file}")
    for file in "${files[@]}"
    do
        touch "${file}"
    done
}

check()
{
    log_msg "source list file: ${SRC_LIST}"
    log_msg "job list file: ${JOB_ID_LIST}"
    log_msg "refine batch log path: ${RESULT_PATH}"
    log_msg "rpmbuild log path: ${RPM_BUILD_RES_PATH}"
    log_msg ""

    [ -z "${RESULT_PATH}" ] && echo "[error] RESULT_PATH is empty: [${RESULT_PATH}]" && exit 1
    #[ -z "${RPM_BUILD_RES_PATH}" ] && echo "[error] Rpmbuild log file path is empty: [${RPM_BUILD_RES_PATH}]" && exit 1

    # 检查批量提交时的list是否传入，并存在
    if [ -z "${SRC_LIST}" ] || [ ! -f "${SRC_LIST}" ]; then
        log_msg "[error] need option -l to appoint src list file."
        exit 1
    fi

    # 检查job id列表文件是否传入，并存在
    if [ -z "${JOB_ID_LIST}" ]; then 
        log_msg "[error] need option -j to appoint job id list file."
        exit 1
    elif [ ! -f "${JOB_ID_LIST}" ]; then
        log_msg "[error] job id list file is not exist."
        exit 1
    fi
}

# 检查和初始化
check
init

log_msg ""
log_msg "check current iterate..."
while read -r line
do
    line_arr=()
    read -ra line_arr <<< "${line}"
    repo_addr=${line_arr[0]}
    job_id=${line_arr[1]}
    job_log_path=${line_arr[2]}

    [ ! -d "${job_log_path}" ] && log_msg "[error] job log path not exist: ${line}" && continue

    # 获取job路径 (如果上一次的路径存在，则获取父目录检查job_id是否存在)
    #if [ -n "${job_log_path}" ] && [ -d "${job_log_path}/../${job_id}" ]; then
    #    job_log_path=$(realpath "${job_log_path}/../${job_id}")
    #else 
    #    job_log_path=$(find "${RPM_BUILD_RES_PATH}" -type d -name "${job_id}"  -print -quit)
    #fi

    #获取job路径 (保存本次日期，供下次使用，加快查询效率；-print -quit也是一样的作用)
    #job_log_path=$(find "${RPM_BUILD_RES_PATH}/${tmp_date}" -type d -name "${job_id}" -print -quit)
    #if [ ! -d "${job_log_path}" ]; then 
    #    job_log_path=$(find "${RPM_BUILD_RES_PATH}" -type d -name "${job_id}"  -print -quit)
    #    tmp_date=$(echo "${job_log_path}" | sed 's/.*\/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)\/.*/\1/')
    #elif [ -z "${tmp_date}" ]; then 
    #    tmp_date=$(echo "${job_log_path}" | sed 's/.*\/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)\/.*/\1/')
    #fi

    # 获取repo_addr，以获取rpm包名
    rpm_repo_addr=""
    if [ -f "${job_log_path}/job.yaml" ]; then 
        rpm_repo_addr=$(grep "^repo_addr:"  "${job_log_path}/job.yaml" | awk -F'repo_addr:' '{print $NF}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    fi
    if [ -z "${rpm_repo_addr}" ]; then
        log_msg "[warn] proc error: rpm name is null [${line}]-[${job_log_path}]"
        continue
    fi

    # 检查是否属于本list
    if ! grep -q "${rpm_repo_addr}" "${SRC_LIST}"; then
        log_msg "[warn] not belong to this batch: [${rpm_repo_addr}]"
        continue
    fi
    rpm_name=$(echo "${rpm_repo_addr}" | awk -F'/' '{print $NF}')
    rpm_name=${rpm_name//wget:/}
    rpm_name_no_exten=$(echo "$rpm_name" | awk -F '-' '{for(i=1;i<NF;i++){printf("%s-",$i)};print ""}' | sed 's/-$//')

    # 检查rpm是否成功
    if [ -f "${job_log_path}/output" ] && grep -q -F "${RPMBUILD_SUCC_FLAG}" "${job_log_path}/output"; then 
        #if ! grep -q "${rpm_name_no_exten}" "${rpm_build_succ_file}"; then 
        #    echo "${rpm_name}" >> "${rpm_build_succ_file}"
        #fi
        echo "${rpm_name}" >> "${rpm_build_succ_file}"
        
        if grep -q "${RPMBUILD_INSTALL_FAIL_FLAG}" "${job_log_path}/output"; then
            # 安装失败
            echo "${rpm_name}" >> "${rpm_build_s_install_f_file}"
        else
            # 安装成功
            echo "${rpm_name}" >> "${rpm_build_install_succ_file}"
        fi
    elif [ -f "${job_log_path}/dmesg" ] && grep -q -F "${RPMBUILD_INSTALLED_FLAG}" "${job_log_path}/dmesg"; then
        #if ! grep -q "${rpm_name_no_exten}" "${rpm_build_installed_file}"; then 
        #    echo "${rpm_name}" >> "${rpm_build_installed_file}"
        #fi
        echo "${rpm_repo_addr} ${rpm_name}" >> "${rpm_build_installed_file}"
    else 
        echo "${rpm_repo_addr} ${rpm_name}" >> "${rpm_build_fail_file}"

        # 保存output日志和spec文件
        if [ -f "${job_log_path}/output" ]; then 
            cp "${job_log_path}/output" "${dir_fail_log}/${rpm_name_no_exten}.log"
        fi
    fi

    # 保存记录到已处理文件
    record="${job_id} ${rpm_name} ${rpm_repo_addr} ${job_log_path}"
    echo "${record}" >> "${res_job_rpm}";

done < "${JOB_ID_LIST}"

# 生成下轮迭代清单
log_msg "creat next iterte list file ..."
while read -r line; do
    repo_addr=$(echo "$line" | awk -F' ' '{print $1}')
    rpm_name=$(echo "$line" | awk -F'/' '{print $NF}')

    if grep -q "^${rpm_name}" "${rpm_build_succ_file}"; then
        # 在成功列表中
        continue
    elif grep -q "^${rpm_name}" "${rpm_build_installed_file}"; then 
        # 在已安装列表中
        continue
    else
        echo "${repo_addr} ${rpm_name}" >> "${rpm_build_next_iteate}"
    fi
done < "${SRC_LIST}"

total_num=$(sed -n '$=' "${SRC_LIST}")
proc_ed_num=$(sed -n '$=' "${res_job_rpm}")
proc_succ_num_current=$(sed -n '$=' "${rpm_build_succ_file}")
proc_install_succ_num=$(sed -n '$=' "${rpm_build_install_succ_file}")
proc_install_fail_num=$(sed -n '$=' "${rpm_build_s_install_f_file}")
proc_installed_num=$(sed -n '$=' "${rpm_build_installed_file}")
proc_fail_num=$(sed -n '$=' "$rpm_build_fail_file")

log_msg ""
log_msg ""
log_msg "------------------------------"
log_msg "total_num: ${total_num}"
log_msg "   processed package: ${proc_ed_num}"
log_msg "   current iterate success package: ${proc_succ_num_current}"
log_msg "      install success: ${proc_install_succ_num}, install fail: ${proc_install_fail_num}"
log_msg "   processed installed package: ${proc_installed_num}"
log_msg "   processed fail package: ${proc_fail_num}"
log_msg "------------------------------"
log_msg ""
log_msg ""
