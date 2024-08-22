#! /bin/zsh

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
#     -o：(other) 其他参数，多个参数以 “+” 分割
#           例如:param_1+param_2+param_3
#----------------------------------------------------------------------------------

# 提交job时, 参数
# 架构：aarch64   x86_64
submit_arch="aarch64"
# 虚拟机规格：vm-2p16g  vm-2p8g  2288hv3-2s24p-768g--b26
submit_testbox=vm-2p8g
# 提交job其他参数: 
#   check_rpm_install：(yes/no) 是否检查rpm已经安装
#   res_file_exten：构建成功后，源文件添加.fc40后缀
submit_other_app_param="check_rpm_install=yes res_file_exten=.fc40"
# job参数
submit_job_inf="-m -c job.yaml -i ssh.yaml"
# 软件包源码仓库基地址
repo_base_addr="https://mirrors.huaweicloud.com/fedora/releases/40/Everything/source/tree/"

time=$(date +"%Y-%m-%d")

# 输入参数解析
param_ai=""
param_src=""
param_dir=""
param_list=""
param_other=""
param_other_arr=()

while getopts ":a:s:d:l:o:" opt; 
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

echo "param: -a[${param_ai}] -s[${param_src} -d[${param_dir}] -l[${param_list}] -o[${param_other}]"


param_reference_value_ai=("before" "build" "all")
param_reference_value_src=("spec" "spec_log")

# lkp代码路径
lkp_repair_dir="${HOME}/lkp-tests/repair-dir/src"
lkp_repair_spec="${lkp_repair_dir}/SPECS"
lkp_repair_log="${lkp_repair_dir}/LOGS"

param_check_ai()
{
    [ ! -n "${param_ai}" ] && return 0

    # 检查参数值
    found=false
    for item in "${param_reference_value_ai[@]}"; do
        if [ "${param_ai}" = "${item}" ]; then 
            found=true
            break;
        fi
    done

    if ! $found; then 
        echo "-a 参数值错误[${param_ai}], 参考值: ${param_reference_value_ai[@]}"
        exit 1
    fi

    # 如果需要先ai修复spec，再rpmbuild （before/all）
    # 则需要指定spec和log
    if [ "before" = ${param_ai} ] || [ "all" = ${param_ai} ]; then 
        if [ "spec_log" != "${param_src}" ]; then 
            echo "rpmbuild之前修复，需要指定spec、log：请使用 -s spec_log"
            exit 1
        fi
    fi
}

param_check_src()
{
    [ ! -n "${param_src}" ] && return 0

    # 检查参数值
    found=false
    for item in "${param_reference_value_src[@]}"; do
        if [ "${param_src}" = "${item}" ]; then 
            found=true
            break;
        fi
    done

    if ! $found; then 
        echo "-s 参数值错误[${param_src}], 参考值: ${param_reference_value_src[@]}"
        exit 1
    fi

    # 如果-s，则需要-d
    if [ -z ${param_dir} ] || [ ! -d ${param_dir} ]; then
        echo "[error] option -s, required matching option -d: [${param_dir}] is empty or not exist"
        exit 1
    fi
}

param_check_list()
{
    # 需要指定list
    if [ ! -n "$param_list" ]; then 
        echo "[error] no option -l"
        exit 1
    fi
}

param_check_other()
{
    [ ! -n "${param_other}" ] && return 0

    # 解析其他参数字段
    param_other_arr=($(awk -F '+' '{for (i=1; i<=NF; i++) print $i}' <<< "${param_other}"))

    echo "拆分其他参数为：${param_other_arr[@]}"
}

param_check()
{
    param_check_ai
    param_check_src
    param_check_list
    param_check_other
}

upload_file() 
{
    spec_name=$1

    # 初始化lkp目录
    rm -rf ${lkp_repair_dir}/   
    mkdir -p ${lkp_repair_dir}/

    if [[ $param_src == *"spec"* ]]; then
        # spec文件必须以.spec结尾
        if [[ $spec_name != *.spec ]]; then
            echo "[error] spec file name error: ${spec_name}"
	        continue
	    fi

        [ -d ${lkp_repair_spec} ] || mkdir -p ${lkp_repair_spec}
        spec_num=$(find ${param_dir} -type f -name "${spec_name}" | wc -l)
        if [ $spec_num -ne 1 ]; then
            echo "[error] .spec file num not equals 1: ${spec_num} - ${spec_name}"
            continue
        fi

        # 同步spec文件
        $(rm -rf ${lkp_repair_spec}/*)
        $(find ${param_dir} -type f -name "${spec_name}" -exec cp {} ${lkp_repair_spec}/  \;)

        submit_repair_spec="repair_spec=${spec_name}"
    fi

    if [[ $param_src == *"log"* ]]; then 
        [ -d ${lkp_repair_log} ] || mkdir -p ${lkp_repair_log}

        spec_basename=$(basename $spec_name .spec)
        log_file_name="${spec_basename}.log"
        log_num=$(find ${param_dir} -type f -name $log_file_name | wc -l)
        if [ ${log_num} -ne 1 ]; then 
            echo "[error] log file num not equals 1: ${log_num} - ${log_file_name}"
            continue
        fi

        $(rm -rf ${lkp_repair_log}/*)
        $(find ${param_dir} -type f -name "${log_file_name}" -exec cp {} ${lkp_repair_log}/  \;)

        submit_repair_log="repair_log=${log_file_name}"
    fi
}

# 参数检查
param_check

# 清空lkp使用空间
if [ -d ${lkp_repair_dir} ]; then
    $(rm -rf ${lkp_repair_dir}/*)
fi

while read line; 
do
    # 初始化
    line_array=(${line})
    [ ${#line_array[@]} -lt 2 ] && echo "[error] ${line}记录" 

    if [ $((${#line_array[@]} - 2)) -lt ${#param_other_arr[@]} ] ; then 
        echo "[error] 其他参数数量[${#param_other_arr[@]}] 大于实际参数数量 [${#line_array[@]}]: ${line}"
        continue
    fi

    # spec_name
    spec_name=${line_array[0]}
    repo=${line_array[1]}

    # submit参数
    submit_repair_spec=""
    submit_repair_log=""
    submit_other=""
    submit_ai_repair=""
    submit_repo_addr="${repo_base_addr}${repo}"

    # 需要同步源文件(spec或log文件)
    if [ -n "${param_src}" ]; then 
        upload_file ${spec_name}
    fi

    # 设置其他参数
    index=0
    while [ $index -lt ${#param_other_arr[@]} ]; do
        submit_other="${submit_other} ${param_other_arr[${index}]}=${line_array[((${index} + 2))]} "
        ((index++))
    done

    [ -n "${param_ai}" ] && submit_ai_repair="ai_repair_spec=${param_ai}"

    #echo "${spec_name}-${repo} proc ..."

    commond="submit ${submit_job_inf} repo_addr=${submit_repo_addr} os_arch=${submit_arch} testbox=${submit_testbox} ${submit_repair_spec} ${submit_repair_log} ${submit_ai_repair} ${submit_other} ${submit_other_app_param} | tee -a log/submit-log-${arch}-${time}"
    echo "${commond}"
    #${commond}

    
done < ${param_list}
