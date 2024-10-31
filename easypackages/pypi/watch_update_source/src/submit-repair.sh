#! /bin/bash

#source ./../lib/lib_rpm.sh

#----------------------------------------------------------------------------------
# 参数介绍:
#     -a: (ai) 使用AI修复spec文件
#         可选value: before/build/all
#           before: 在rpmbuild之前使用ai修复（必须上送log文件）
#           build：如果rpmbuild构建失败，使用ai修复spec文件（可以不上送log文件）
#           all: 在rpmbuild之前、构建失败时，都会使用ai修复spec文件（必须上送log文件）
#
#     -s: (src) 是否使用本地文件替换构建过程的文件
#         value可以包含spec、log
#           例如：spec、spec_log
#
#     -d: (dir) 如果指定-s，则需要指定存放本地源文件的目录 (inlcude specs/logs/sources). 
#          spec文件和log文件是对应的
#
#     -l: (list) 指定批量list文件. (default file ./list)
#           文件格式要求：spec_name repo_addr source_name other_param
#
#     -m: (mapping) 指定rpm特征文件修复spec文件（feature mapping file）
#
#     -o：(other) 其他参数，多个参数以 “+” 分割
#           例如:param_1+param_2+param_3
#
#     -h: 指定架构（aarch64 x86_64）
#     -t: 指定执行机规格 （vm-2p16g  vm-2p8g  vm-4p32g  2288hv3-2s24p-768g--b26）
#     -p：指定其他自定义参数 （check_rpm_install=yes res_file_exten=.fc40）
#     -y: 指定job-yaml文件
#     -r: 指定repo_base_addr
#     -g: 指定日志路径
#
# 说明：
#   submit_arch 指定执行机架构： aarch64  x86_64
#     eg: submit_arch="aarch64"
#
#   submit_testbox 指定虚拟机规格：vm-2p16g  vm-2p8g  vm-4p32g  2288hv3-2s24p-768g--b26
#     eg: submit_testbox="vm-2p16g"
#
#   submit_other_app_param 提交job其他参数: 
#       check_rpm_install：(yes/no) 是否检查rpm已经安装
#       res_file_exten：构建成功后，源文件添加.fc40后缀
#     eg:submit_other_app_param="check_rpm_install=yes res_file_exten=.fc40"
#       
#   submit_job_inf 指定job参数： job-openSUSE15.6-aarch64.yaml  ob-centos9-aarch64.yaml
#       进入执行机："-m -c job.yaml -i ssh.yaml" 
#     eg: submit_job_inf="./job-yaml/job-fedora40-aarch64.yaml"
#
#   repo_base_addr 软件包源码仓库基地址: "https://mirrors.huaweicloud.com/fedora/releases/40/Everything/source/tree/"
#     eg: repo_base_addr="https://mirrors.huaweicloud.com/fedora/releases/40/Everything/source/tree/"
#
#----------------------------------------------------------------------------------

# 提交job时参数（详细介绍请见上述...（自定义参数））
submit_arch=""
submit_testbox=""
submit_other_app_param=""
submit_job_inf=""
repo_base_addr=""
submit_log_dir=""
sleep_time=86400

# submit最大提交次数
submit_max_times=5

# 输入参数解析
param_ai=""
param_src=""
param_dir=""
param_list=""
param_mapping_file=""
param_other=""
param_other_arr=()

project_log_file=""

while getopts ":a:s:d:l:o:m:h:t:p:y:r:g:" opt; 
do
    case $opt in
        a)
            param_ai=$OPTARG
            ;;
        s)
            param_src=$OPTARG
            ;;
        d)
            param_dir=$OPTARG
            ;;
        l)
            param_list=$OPTARG
            ;;
        o)
            param_other=$OPTARG
            ;;
        m)
            param_mapping_file=$OPTARG
            ;;
        h)
            submit_arch=$OPTARG
            ;;
        t)
            submit_testbox=$OPTARG
            ;;
        p)
            submit_other_app_param=$OPTARG
            ;;
        y)
            submit_job_inf=$OPTARG
            ;;
        r)
            repo_base_addr=$OPTARG
            ;;
        g)
            submit_log_dir=$OPTARG
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

echo "param: -a[${param_ai}] -s[${param_src}] -d[${param_dir}] -l[${param_list}] -o[${param_other}]"


param_reference_value_ai=("before" "build" "all")
param_reference_value_src=("spec" "spec_log")
param_reference_value_arch=("aarch64" "x86_64")
param_reference_value_testbox=("vm-2p16g" "vm-2p8g")


# lkp代码路径
lkp_repair_dir="${HOME}/lkp-tests/repair-dir/src"
lkp_repair_spec="${lkp_repair_dir}/SPECS"
lkp_repair_log="${lkp_repair_dir}/LOGS"
lkp_repair_mapping_dir="${lkp_repair_dir}/rpm-mapping"


log_msg()
{
    if [ -z "${project_log_file}" ]; then 
        echo "$@"
    else
        if [ ! -f "${project_log_file}" ]; then
            log_file_path=$(dirname "${project_log_file}")
            if [ ! -d "${log_file_path}" ]; then
                mkdir -p "${log_file_path}"
                chmod 775 "${log_file_path}"
            fi
        fi

        echo "$@" | tee -a "${project_log_file}"
    fi
}

# ai参数检查
param_check_ai()
{
    [ -z "${param_ai}" ] && return 0

    # 检查参数值
    found=false
    for item in "${param_reference_value_ai[@]}"; do
        if [ "${param_ai}" = "${item}" ]; then 
            found=true
            break;
        fi
    done

    if ! $found; then 
        echo "-a 参数值错误[${param_ai}], 参考值: ${param_reference_value_ai[*]}"
        exit 1
    fi

    # 如果需要先ai修复spec，再rpmbuild （before/all）
    # 则需要指定spec和log
    if [ "before" = "${param_ai}" ] || [ "all" = "${param_ai}" ]; then 
        if [ "spec_log" != "${param_src}" ]; then 
            echo "rpmbuild之前修复，需要指定spec、log：请使用 -s spec_log"
            exit 1
        fi
    fi
}

# 源文件（spec、log）检查
param_check_src()
{
    [ -z "${param_src}" ] && return 0

    # 检查参数值
    found=false
    for item in "${param_reference_value_src[@]}"; do
        if [ "${param_src}" = "${item}" ]; then 
            found=true
            break;
        fi
    done

    if ! $found; then 
        echo "-s 参数值错误[${param_src}], 参考值: ${param_reference_value_src[*]}"
        exit 1
    fi

    # 如果-s，则需要-d
    if [ -z "${param_dir}" ] || [ ! -d "${param_dir}" ]; then
        echo "[error] option -s, required matching option -d: [${param_dir}] is empty or not exist"
        exit 1
    fi
}

# 源list文件检查
param_check_list()
{
    # 需要指定list
    if [ -z "$param_list" ]; then 
        echo "[error] no option -l"
        exit 1
    fi
}

# rpm包映射文件检查
param_check_mapping_file()
{
    [ -z "$param_mapping_file" ] && return 0
    
    if [ ! -f "$param_mapping_file" ]; then 
        echo "[error] option -m, file not exist: [${param_mapping_file}]"
    fi

    rm -rf "${lkp_repair_mapping_dir}"
    mkdir -p "${lkp_repair_mapping_dir}"
    cp -f "${param_mapping_file}" "${lkp_repair_mapping_dir}/"
}

# 其他参数检查
param_check_other()
{
    [ -z "${param_other}" ] && return 0

    # 解析其他参数字段
    param_other_arr=()
    read -ra param_other_arr <<< "${param_other//+/ }"

    echo "拆分其他参数为：${param_other_arr[*]}"
}

param_check_arch()
{
    if [ -z "${submit_arch}" ]; then 
        log_msg "[error] not appoint arch type by option -h"
        exit 1
    fi

    # 检查参数值
    found=false
    for item in "${param_reference_value_arch[@]}"; do
        if [ "${submit_arch}" = "${item}" ]; then 
            found=true
            break;
        fi
    done

    if ! $found; then 
        echo "-h 参数值错误[${submit_arch}], 参考值: ${param_reference_value_arch[*]}"
        exit 1
    fi
}

param_check_testbox()
{
    if [ -z "${submit_testbox}" ]; then 
        log_msg "[error] not appoint arch type by option -h"
        exit 1
    fi

    # 检查参数值
    found=false
    for item in "${param_reference_value_testbox[@]}"; do
        if [ "${submit_testbox}" = "${item}" ]; then 
            found=true
            break;
        fi
    done

    if ! $found; then 
        echo "-t 参数值错误[${submit_testbox}], 参考值: ${param_reference_value_testbox[*]}"
        exit 1
    fi
}

param_check_jobyaml()
{
    if [ -z "${submit_job_inf}" ]; then 
        log_msg "[error] not appoint arch type by option -y"
        exit 1
    fi

    # 检查参数值
    if [ ! -f "${submit_job_inf}" ]; then 
        log_msg "[error] job yaml file is not exist: $submit_job_inf"
        exit 1
    fi
}

param_check_logfile()
{
    if [ -z "${submit_log_dir}" ]; then 
        log_msg "[error] not appoint log path by option -g"
        exit 1
    fi

    # 检查参数值
    if [ ! -d "${submit_log_dir}" ]; then 
        mkdir -p "${submit_log_dir}"
    fi
}

param_check()
{
    param_check_ai
    param_check_src
    param_check_list
    param_check_mapping_file
    param_check_other
    param_check_arch
    param_check_testbox
    param_check_jobyaml
}

upload_file() 
{
    spec_name=$1

    # 初始化lkp目录
    rm -rf "${lkp_repair_spec}"
    rm -rf "${lkp_repair_log}"

    if [[ $param_src == *"spec"* ]]; then
        # spec文件必须以.spec结尾
        if [[ $spec_name != *.spec ]]; then
            echo "[error] spec file name error: ${spec_name}"
            return 
        fi

        [ -d "${lkp_repair_spec}" ] || mkdir -p "${lkp_repair_spec}"
        spec_num=$(find "${param_dir}" -type f -name "${spec_name}" | wc -l)
        if [ "$spec_num" -ne 1 ]; then
            echo "[error] .spec file num not equals 1: ${spec_num} - ${spec_name}"
            return
        fi

        # 同步spec文件
        find "${param_dir}" -type f -name "${spec_name}" -exec cp {} "${lkp_repair_spec}/"  \;

        submit_repair_spec="repair_spec=${spec_name}"
    fi

    if [[ $param_src == *"log"* ]]; then 
        [ -d "${lkp_repair_log}" ] || mkdir -p "${lkp_repair_log}"

        spec_basename=$(basename "$spec_name" .spec)
        log_file_name="${spec_basename}.log"
        log_num=$(find "${param_dir}" -type f -name "$log_file_name" | wc -l)
        if [ "${log_num}" -ne 1 ]; then 
            echo "[error] log file num not equals 1: ${log_num} - ${log_file_name}"
            return 
        fi

        find "${param_dir}" -type f -name "${log_file_name}" -exec cp {} "${lkp_repair_log}/"  \;

        submit_repair_log="repair_log=${log_file_name}"
    fi
}

init()
{
    param_check_logfile

    # 日志文件
    project_log_file="${submit_log_dir}/submit-log"
    submit_succ_list="${submit_log_dir}/submit-succ-list"
    submit_fail_list="${submit_log_dir}/submit-fail-list"
    result_root_list="${submit_log_dir}/result_root_list"
    
    log_msg "[log] log path: ${project_log_file}"
    log_msg ""
    
    # 清空lkp使用空间
    if [ -d "${lkp_repair_dir}" ]; then
        rm -rf "${lkp_repair_dir}"
    fi
    mkdir -p "${lkp_repair_dir}"
}

# 最开始的执行
init

# 参数检查
param_check

while read -r line; 
do
    if [ -z "${line}" ]; then 
        continue
    fi

    # 初始化
    line_array=()
    read -ra line_array <<< "${line}"
    [ ${#line_array[@]} -lt 1 ] && echo "[error] ${line}记录" && contine

    if [ 0 -ne ${#param_other_arr[@]} ] && [ $((${#line_array[@]} - 2)) -lt ${#param_other_arr[@]} ] ; then 
        echo "[error] 其他参数数量[${#param_other_arr[@]}] 小于实际参数数量 [${#line_array[@]}]: ${line}"
        continue
    fi

    # spec_name
    #spec_name=${line_array[0]}
    #repo=${line_array[1]}
    repo=${line_array[0]}

    # submit参数
    submit_repair_spec=""
    submit_repair_log=""
    submit_other=""
    submit_ai_repair=""
    submit_mapping_repair=""
    submit_repo_addr="${repo_base_addr}${repo}"

    # 需要同步源文件(spec或log文件)
    if [ -n "${param_src}" ]; then 
        upload_file "${spec_name}"
    fi

    # 设置其他参数
    index=0
    while [ $index -lt ${#param_other_arr[@]} ]; do
        submit_other="${submit_other} ${param_other_arr[${index}]}=${line_array[((${index} + 2))]} "
        ((index++))
    done

    [ -n "${param_ai}" ] && submit_ai_repair="ai_repair_spec=${param_ai}"
    if [ -n "${param_mapping_file}" ]; then
        mapping_file_basename=$(basename "${param_mapping_file}")
        submit_mapping_repair="repair_spec_by_mapping=${mapping_file_basename}"
    fi

    #echo "${spec_name}-${repo} proc ..."

    commond="submit ${submit_job_inf} repo_addr=${submit_repo_addr} os_arch=${submit_arch} testbox=${submit_testbox} ${submit_repair_spec} ${submit_repair_log} ${submit_ai_repair} ${submit_mapping_repair} ${submit_other} ${submit_other_app_param} | tee -a ${project_log_file}"
    log_msg "${commond}"

    repeat_flag="true"
    submit_times=1
    job_id=""
    while [ ${submit_times} -le ${submit_max_times} ] && [ "${repeat_flag}" = "true" ]; do
        log_msg "submit times [${submit_times}]"
        submit_res=$(bash -c "${commond}")
        echo "${submit_res}"
        job_id=$(echo "${submit_res[@]}" | grep -o "got job id=.*" | awk -F'=' '{print  $NF}' | awk -F',' '{print $1}')
        result_root=$(echo "${submit_res[@]}" | grep "result_root" | awk -F'result_root ' '{print $2}')
        log_msg "job id[${job_id}]"
        [ -n "${result_root}" ] && echo "${result_root}" >> "${result_root_list}"
        if [ -n "${job_id}" ] && [ "${job_id}" != "0" ]; then 
            log_msg "[${submit_repo_addr}] submit success.." 
            repeat_flag=false
            break
        fi

        # 如果提交失败，则休眠10秒
        log_msg "submit fail, will repeat submit. "
        log_msg "sleep 10 seconds ..."
        sleep 10
        
        ((submit_times++))
    done

    if [ ${submit_times} -gt ${submit_max_times} ]; then 
        log_msg "[${submit_repo_addr}] submit fail...[${submit_times}]" 
        src_name=$(echo "${repo}" | awk -F'/' '{print $NF}')
        echo "${src_name}  ${repo}" >> "${submit_fail_list}"
    else 
        echo "${repo}  ${job_id}" >> "${submit_succ_list}"
    fi

    log_msg "" 

    ((submit_num++))
    if [[ ${submit_num} != 0 && $((submit_num % 3000)) == 0 ]]; then 
        # 睡眠30分钟，防止当前提交任务抢占机器
        log_msg "sleep ${sleep_time} seconds ..."
        sleep ${sleep_time}
    fi

    
done < "${param_list}"


submit_succ_num=0
submit_fail_num=0

[ -f "${submit_succ_list}" ] && submit_succ_num=$(sed -n '$=' "${submit_succ_list}")
[ -f "${submit_fail_list}" ] && submit_fail_num=$(sed -n '$=' "${submit_fail_list}")

log_msg ""
log_msg "总共提交job数量：[${submit_num}]" 
log_msg "成功：[${submit_succ_num}]" 
log_msg "失败：[${submit_fail_num}]" 
