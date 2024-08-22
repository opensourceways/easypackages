#! /bin/bash

#----------------------------------------------------------------------------------
# 参数介绍:
#     -l: (list) 指定批量list文件. 
#----------------------------------------------------------------------------------

# source_list
LIST_PATH=""

while getopts ":l:" opt;
do
    case $opt in
        l)
            LIST_PATH=$OPTARG
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

# -------- 定制化参数 -----------
# 统计开始日期
start_date="2024-08-12"

# os_arch = 2p16g  2288hv3-2s24p-768g--b26
#os_arch=2288hv3-2s24p-768g--b26
os_arch=vm-2p16g

# testbox = x86_64  
testbox=x86_64

# job日志路径
RPM_BUILD_RES_PATH="/srv/result/rpmbuild-fedora40"
# 构建成功后，源码包路径
RPM_BUILD_SRC_PATH="/srv/rpm/testing/openeuler-24.03-LTS/fedora40/source/Packages"

#-------------------------------

# 存放本次统计结果的路径
RESULT_PATH="${HOME}/rpmbuild/result/result"

# 统计结果文件
res_job_rpm="${RESULT_PATH}/res_job_rpm"                                    # 已处理文件（格式：job_id ## rpm_name ## 日志目录）
res_proc_ed="${RESULT_PATH}/res_proc_ed"                                    # 已处理文件（格式：rpm_name）
res_proc_ing="${RESULT_PATH}/res_proc_ing"                                  # 处理中文件（格式：job_id ## rpm_name ## 日志目录）
res_repeat="${RESULT_PATH}/res_repeat"                                      # 存在重复的数据
res_err="${RESULT_PATH}/res_err"                                            # 其他错误信息
execute_log="${RESULT_PATH}/execute_log"

dir_fail_spec="${RESULT_PATH}/specs_fail"                                   # 失败rpm的spec文件目录
dir_fail_log="${RESULT_PATH}/logs_fail"                                     # 失败rpm的log文件目录
rpm_build_succ_file="${RESULT_PATH}/rpm_succ_list"                          # 成功清单
rpm_build_fail_file="${RESULT_PATH}/rpm_fail_list"                          # 失败清单
rpm_build_fail_no_spec_file="${RESULT_PATH}/rpm_fail_no_spec_list"          # 失败了，没有spec的清单
rpm_build_procing_file="${RESULT_PATH}/rpm_procing_list"                    # 处理中的rpm包（没有output文件或者spec文件）（格式：rpm_name ## 日志目录）
rpm_build_installed_file="${RESULT_PATH}/rpm_installed_list"                # 已经存在的rpm包（无需安装）清单
tmp_file="${RESULT_PATH}/tmp"

if [ -z "${LIST_PATH}" ]; then
    LIST_PATH="${HOME}/rpmbuild/list"
fi

#---------init file begin---------------

# 备份上次统计的结果文件
file_date=$(date +"%Y%m%d-%H%M%S")
old_dir="${RESULT_PATH}/../result_${file_date}"
mv ${RESULT_PATH} ${old_dir}

mkdir -p ${dir_fail_spec}
mkdir -p ${dir_fail_log}

# 新建文件
files=(${res_job_rpm} ${res_proc_ed} ${res_proc_ing} ${res_repeat} ${res_err}  ${rpm_build_succ_file} ${rpm_build_installed_file} ${execute_log})
for file in "${files[@]}"
do
    $(touch ${file}) 
done

#---------init file end---------

# 根据源list文件，获取成功的列表（如果源码生成，则表示构建成功）
while read file; do
    rpm_name=$(echo "$file" | awk -F'/' '{print "/" $NF }')
    if [ -f "${RPM_BUILD_SRC_PATH}${rpm_name}" ]; then
        echo "${rpm_name}" >> ${rpm_build_succ_file}
    fi
done < ${LIST_PATH}

end_date=$(date +"%Y-%m-%d")
end=$(date -d "${end_date}" +%s)
current=$(date -d "${start_date}" +%s)

log_msg()
{
    echo "$@" | tee -a ${execute_log}
}

log_msg ""
log_msg "begin [${start_date}] to [${end_date}] ..."
log_msg ""

while [ ${current} -le ${end} ]; do
    # 结果路径
    current_date=$(date -d "@${current}" +%Y-%m-%d)
    CURRENT_PATH="${RPM_BUILD_RES_PATH}/${current_date}/${os_arch}/openeuler-24.03-LTS-${testbox}/${testbox}"
    log_msg "[${CURRENT_PATH}] ..."

    # 分别对每个job的结果目录进行处理
    for file_path in $(ls -d ${CURRENT_PATH}/*/ | sort )
    do
        dir_name=$(basename "${file_path}")
        dir_path="${CURRENT_PATH}/${dir_name}"

        # 获取repo_addr，以获取rpm包名
        rpm_name=$(grep "^repo_addr:"  ${dir_path}/job.yaml | awk -F'/' '{print $NF}')
        if [ -z "${rpm_name}" ]; then
            echo "proc error: rpm name is null [${dir_path}]" >> ${res_err}
            continue
        fi

        # 检查是否属于本list
        grep -q "/${rpm_name}" ${LIST_PATH}
        if [ $? -ne 0 ]; then
            echo "[warn] not belong to this batch: [${rpm_name}}" >> ${res_err}
            continue
        fi

        # 检查rpm是否在成功清单中
        grep -q "/${rpm_name}" ${rpm_build_succ_file}
        if [ $? -ne 0 ]; then
            # 不在成功清单中

            # 检查包是否已经安装（build之前已经存在）
            if [ -f ${dir_path}/dmesg ] && grep -q -F '[---self-log---]: success, rpm already installed' ${dir_path}/dmesg; then 
                echo "/${rpm_name}" >> ${rpm_build_installed_file}
            else
                output_file="${dir_path}/output"
                if [ ! -f "${output_file}" ]; then
                    # 处理中的job， 则跳过
                    echo "${dir_name} ## ${rpm_name} ## ${dir_path}" >> ${res_proc_ing}

                    rpm_package_line=$(grep "/${rpm_name}" ${LIST_PATH})
                    rpm_package_name="Packages/${rpm_package_line##*Packages/}"
                    echo "${rpm_name}   ${rpm_package_name}" >> ${rpm_build_procing_file}
                    continue
                fi
            fi
        fi

        # 保存记录到已处理文件
        record=${dir_name}' ## '${rpm_name}' ## '${dir_path}
        if grep -q "## ${rpm_name} ##" ${res_job_rpm}; then
            # 如果已经存在rpm的记录，则可能是重复提交，删除最开始的记录
            $(grep "${rpm_name}" ${res_job_rpm} >> ${res_repeat})
            $(sed "/${rpm_name}/d" ${res_job_rpm} > ${tmp_file} && mv -f ${tmp_file} ${res_job_rpm})
        fi
    
        echo ${record} >> ${res_job_rpm};
    done

    # 当前日期下的目录处理完成，下一个日期
    current=$((current + 86400))
done

# 对已处理的job进行分析
while read line; do
    rpm_name=$(echo ${line} | awk -F' ## ' '{print $2}')
    echo ${rpm_name} >> ${res_proc_ed}

    if grep -q "/${rpm_name}" ${rpm_build_succ_file}; then
        # 在成功列表中
        continue
    elif grep -q "/${rpm_name}" ${rpm_build_installed_file}; then 
        # 在已安装列表中
        continue
    else
        job_id=$(echo ${line} | awk -F' ## ' '{print $1}')
        file_path=$(echo ${line} | awk -F' ## ' '{print $NF}')

        if [ -e "${file_path}/output" ]; then
            # output文件存在
            if ls ${file_path} | grep -q '\.spec$'; then 
                # spec文件存在
                # 保存log、spec文件
                spec_file_name=$(find ${file_path} -name "*.spec" | awk -F'/' '{print $NF}')
                spec_name=$(basename ${spec_file_name} .spec)

                rpm_package_line=$(grep "/${rpm_name}" ${LIST_PATH})
                rpm_package_name="Packages/${rpm_package_line##*Packages/}"
                echo "${spec_file_name}   ${rpm_package_name}" >> ${rpm_build_fail_file}

                $(cp ${file_path}/*.spec ${dir_fail_spec}/)
                $(cp ${file_path}/output ${dir_fail_log}/${spec_name}.log)
            else 
                echo "${spec_file_name}   ${rpm_package_name}" >> ${rpm_build_fail_no_spec_file}
                echo "file not exist: .spec file not exist [${rpm_name}]-[${file_path}]" >> ${res_err}
            fi
        fi
    fi
done < ${res_job_rpm}

total_num=$(sed -n '$=' ${LIST_PATH})
proc_ed_num=$(sed -n '$=' ${res_proc_ed})
proc_ing_num=$(sed -n '$=' ${res_proc_ing})
proc_succ_num=$(ls -lR ${RPM_BUILD_SRC_PATH} | grep "^-" | wc -l)
proc_succ_num_1=$(sed -n '$=' ${rpm_build_succ_file})
proc_install_num=$(sed -n '$=' ${rpm_build_installed_file})
proc_fail_num=$((${proc_ed_num} - ${proc_succ_num_1}))

log_msg ""
log_msg ""
log_msg "------------------------------"
log_msg "total_num: ${total_num}"
log_msg ""
log_msg "processed package: ${proc_ed_num}"

log_msg "processed success package: ${proc_succ_num_1} -- ${proc_succ_num}"
log_msg "processed installed package: ${proc_install_num}"

log_msg "processed fail package: ${proc_fail_num}"
log_msg ""
log_msg "processing package: ${proc_ing_num}"

log_msg "------------------------------"
log_msg ""
log_msg ""
