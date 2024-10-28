#! /bin/bash

#----------------------------------------------------------------------------------
# 参数介绍:
#       -l: (list) 指定批量list文件. 
#       -o: (output) 指定当前脚本日志输出路径（统计结果保存路径）
#           默认${HOME}/rpmbuild/result/result
#       -r: (result) 指定rpmbuild构建日志输出的路径，指定到/srv/result/rpmbuild-fedora40-aarch64类似层级即可
#       -j: (job) 开始的job id 
#       -J: (job) 结束的job id
#       -d: (date) 开始日期
#       -D: (date) 结束日期
# 
#
# 自定义参数：
#----------------------------------------------------------------------------------

# 参数说明，请见以上 “自定义参数” 说明部分
LIST_PATH=""
RESULT_PATH="${HOME}/rpmbuild/result"
RPM_BUILD_RES_PATH=""
JOB_ID_START=""
JOB_ID_END=""
DATE_START=""
DATE_END=""

# 参数说明，请见以上 “自定义参数” 说明部分
RPMBUILD_SUCC_FLAG="All test cases are passed."
RPMBUILD_INSTALL_FLAG="[log] success, rpm already installed"

# source_list
LIST_PATH=""

while getopts ":l:o:r:j:J:d:D" opt;
do
    case $opt in
        l)
            LIST_PATH=$OPTARG
            ;;
        o)
            RESULT_PATH=$OPTARG
            ;;
        r)
            RPM_BUILD_RES_PATH=$OPTARG
            ;;
        j)
            JOB_ID_START=$OPTARG
            ;;
        J)
            JOB_ID_END=$OPTARG
            ;;
        d)
            DATE_START=$OPTARG
            ;;
        D)
            DATE_END=$OPTARG
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

check_argument_date()
{
    date_tmp=$1

    [ -z "${date_tmp}" ] && return 0

    # 日期格式yyyy-mm-dd
    if [[ $date_tmp =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        if ! date -d "$date_tmp" >/dev/null 2>&1; then
            log_msg "[error] 日期格式正确, 但日期无效: [${date_tmp}]"
            return 1
        fi
    else
        log_msg "[error] 日期格式错误: [${date_tmp}]"
        return 1
    fi
}

check_argument_job_id()
{
    job_id_tmp=$1

    [ -z "${job_id_tmp}" ] && return 0

    # 日期格式yyyy-mm-dd
    if ! find "${RPM_BUILD_RES_PATH}"  -type d -name "${job_id_tmp}" -quit; then
        log_msg "[error] job id is not exist: ${job_id_tmp}"
        return 1
    fi
}

init()
{
    [ -z "${RESULT_PATH}" ] && log_msg "[error] RESULT_PATH is empty: [${RESULT_PATH}]" && exit 1
    [ -z "${RPM_BUILD_RES_PATH}" ] && log_msg "[error] Rpmbuild log file path is empty: [${RPM_BUILD_RES_PATH}]" && exit 1

    # 结果输出
    RESULT_PATH="${RESULT_PATH}/result"
    log_msg "[log] result path: [${RESULT_PATH}]"

    # 备份上次统计的结果文件
    if [ -d "${RESULT_PATH}" ]; then 
        file_date=$(date +"%Y%m%d-%H%M%S")
        old_dir="${RESULT_PATH}/../result_${file_date}"
        mv "${RESULT_PATH}" "${old_dir}"
    fi

    log_msg "[log] source list file: ${LIST_PATH}"
    log_msg "[log] refine batch log path: ${RESULT_PATH}"
    log_msg "[log] rpmbuild log path: ${RPM_BUILD_RES_PATH}"
    log_msg "[log] othen arguments: job id start[${JOB_ID_START}], job id end[${JOB_ID_END}], date start[${DATE_START}], date end[${DATE_END}]"

    # 入参日期检查
    ! check_argument_date "${DATE_START}" && exit 1
    ! check_argument_date "${DATE_END}" && exit 1
    timestamp1=$(date -d "${DATE_START}" +%s)
    timestamp2=$(date -d "${DATE_END}" +%s)
    if [ -n "${DATE_START}" ] && [ -n "${DATE_END}" ] && [ "$timestamp1" -gt "$timestamp2" ]; then
        log_msg "[error] DATE_START great than DATE_END:  [${DATE_START}]-[${DATE_END}]"
        exit 1
    fi

    # 入参job_id检查
    ! check_argument_job_id "${JOB_ID_START}" && exit 1
    ! check_argument_job_id "${JOB_ID_END}" && exit 1
    JOB_ID_START=${JOB_ID_START//z9./}
    JOB_ID_END=${JOB_ID_END//z9./}
    if [ -n "${JOB_ID_START}" ] && [ -n "${JOB_ID_END}" ] && [ "$JOB_ID_START" -gt "$JOB_ID_END" ]; then
        log_msg "[error] JOB_ID_START great than JOB_ID_END:  [${JOB_ID_START}]-[${JOB_ID_END}]"
        exit 1
    fi

    # 检查批量提交时的list是否传入，并存在
    if [ -z "${LIST_PATH}" ] || [ ! -f "${LIST_PATH}" ]; then
        log_msg "[error] need option -l to appoint src list file."
        exit 1
    fi


    # 统计结果文件
    res_job_rpm="${RESULT_PATH}/res_job_rpm"                                    # 已处理文件（格式：job_id ## rpm_name ## 日志目录）
    tmp_file="${RESULT_PATH}/res_job_rpm_tmp"
    log_file="${RESULT_PATH}/execute_log"

    dir_fail_spec="${RESULT_PATH}/specs_fail"                                   # 失败rpm的spec文件目录
    dir_fail_log="${RESULT_PATH}/logs_fail"                                     # 失败rpm的log文件目录
    rpm_build_succ_file="${RESULT_PATH}/rpm_succ_list"                          # 成功清单
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

# 检查和初始化
init

log_msg ""

log_msg "[log] get current rpm list ..."
for file_path in $(find "${RPM_BUILD_RES_PATH}" -mindepth 1 -maxdepth 1 -type d | sort )
do
    current_dir_1=$(echo "${file_path}" | awk -F'/' '{print $NF}')
    if ! check_argument_date "${current_dir_1}"; then 
        log_msg "[warn] this dir is not date format: [${current_dir_1}]"
        continue
    fi
    
    timestamp1=$(date -d "${current_dir_1}" +%s)
    if [ -n "${DATE_START}" ]; then 
        timestamp2=$(date -d "${DATE_START}" +%s)
        if [ "$timestamp1" -lt "$timestamp2" ]; then
            log_msg "[log] this dir is less than DATE_START: [${current_dir_1}], [${DATE_START}]-[${DATE_END}]"
            continue
        fi
    fi

    if [ -n "${DATE_END}" ]; then 
        timestamp2=$(date -d "${DATE_END}" +%s)
        if [ "$timestamp1" -gt "$timestamp2" ]; then
            log_msg "[log] this dir is not between DATE_START and DATE_END: [${current_dir_1}], [${DATE_START}]-[${DATE_END}]"
            continue
        fi
    fi
    log_msg "[log] dir proc: [${file_path}]"

    for job_dir in $(find "${file_path}/" -type d -name "z9.*" | sort )
    do
        job_id=$(echo "${job_dir}" | awk -F'/' '{print $NF}')
        job_id_num=${job_id//z9./}

        # 检查job id
        if [ -n "${JOB_ID_START}" ] && [ "$JOB_ID_START" -gt "$job_id_num" ]; then
            continue
        fi

        if [ -n "${JOB_ID_END}" ] && [ "$JOB_ID_END" -lt "$job_id_num" ]; then
            continue
        fi

        # 获取repo_addr，以获取rpm包名
        rpm_repo_addr=$(grep "^repo_addr:"  "${job_dir}/job.yaml" | awk -F'repo_addr:' '{print $NF}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [ -z "${rpm_repo_addr}" ]; then
            log_msg "[warn] proc error: rpm name is null [${job_dir}]"
            continue
        fi
        rpm_name=$(echo "${rpm_repo_addr}" | awk -F'/' '{print $NF}')

        # 检查是否属于本list
        if ! grep -q "/${rpm_name}" "${LIST_PATH}"; then
            log_msg "[warn] not belong to this batch: [${rpm_name}]-[${job_dir}]"
            continue
        fi

        # 保存记录到已处理文件
        record="${rpm_repo_addr} ${job_id} ${rpm_name} ${job_dir}"
        if grep -q "${record}" "${res_job_rpm}"; then
            # 如果已经存在rpm的记录，则可能是重复提交，删除最开始的记录
            sed "/${record}/d" "${res_job_rpm}" > "${tmp_file}" && mv -f "${tmp_file}" "${res_job_rpm}"
        fi
        echo "${record}" >> "${res_job_rpm}";
    done

done

while read -r line
do
    [ -z "${line}" ] && continue

    line_arr=()
    read -ra line_arr <<< "${line}"
    job_id=${line_arr[1]}
    rpm_name=${line_arr[2]}
    job_log_path=${line_arr[3]}


    # 检查rpm是否成功
    if [ -f "${job_log_path}/output" ] && grep -q -F "${RPMBUILD_SUCC_FLAG}" "${job_log_path}/output"; then 
        echo "${rpm_name}" >> "${rpm_build_succ_file}"
    elif [ -f "${job_log_path}/dmesg" ] && grep -q -F "${RPMBUILD_INSTALL_FLAG}" "${job_log_path}/dmesg"; then
        echo "${rpm_name}" >> "${rpm_build_installed_file}"
    else 
        echo "${rpm_repo_addr} ${rpm_name}" >> "${rpm_build_fail_file}"
    fi
done < "${res_job_rpm}"

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
done < "${LIST_PATH}"

total_num=$(sed -n '$=' "${SRC_LIST}")
proc_ed_num=$(sed -n '$=' "${res_job_rpm}")
proc_succ_num_current=$(sed -n '$=' "${rpm_build_succ_file}")
proc_install_num=$(sed -n '$=' "${rpm_build_installed_file}")
proc_fail_num=$(wc -l "$rpm_build_fail_file")

log_msg ""
log_msg ""
log_msg "------------------------------"
log_msg "total_num: ${total_num}"
log_msg ""
log_msg "processed package: ${proc_ed_num}"
log_msg "current iterate success package: ${proc_succ_num_current}"
log_msg "processed installed package: ${proc_install_num}"
log_msg "processed fail package: ${proc_fail_num}"

log_msg "------------------------------"
log_msg ""
log_msg ""
