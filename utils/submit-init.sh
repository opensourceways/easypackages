#! /bin/zsh

#----------------------------------------------------------------------------------
# 参数介绍:
#     -l: (list) 指定批量list文件. (default file ./list)
#           文件格式要求：spec_name repo_addr source_name other_param
#
#     -o：(other) 其他参数，多个参数以 “+” 分割
#           例如:param_1+param_2+param_3
#----------------------------------------------------------------------------------

# 提交job时, 参数
# 架构： aarch64   x86_64
submit_arch="x86_64"
# 虚拟机规格：vm-2p16g  vm-2p8g  vm-4p32g  2288hv3-2s24p-768g--b26
submit_testbox="vm-2p16g"
# 提交job其他参数: 
#   check_rpm_install：(yes/no) 是否检查rpm已经安装
#   res_file_exten：构建成功后，源文件添加.fc40后缀
submit_other_app_param="check_rpm_install=yes res_file_exten=.el9"
# job参数   "-m -c job.yaml -i ssh.yaml"
submit_job_inf="job-centos9.yaml"
# 软件包源码仓库基地址
#repo_base_addr="https://mirrors.huaweicloud.com/fedora/releases/40/Everything/source/tree/"
repo_base_addr=""

time=$(date +"%Y%m%d-%H%M%S")

# 输入参数解析
param_list=""
param_other=""
param_other_arr=()

while getopts ":l:o:" opt; 
do
    case $opt in
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

echo "param: -l[${param_list}] -o[${param_other}]"

param_check_list()
{
    # 需要指定list
    if [ -z "$param_list" ]; then 
        echo "[error] no option -l"
        exit 1
    fi
}

param_check_other()
{
    [ -z "${param_other}" ] && return 0

    # 解析其他参数字段
    param_other_arr=($(awk -F '+' '{for (i=1; i<=NF; i++) print $i}' <<< "${param_other}"))

    echo "其他参数为：${param_other_arr[@]}"
}

param_check()
{
    param_check_list
    param_check_other
}

log_msg()
{
    echo "$@" | tee -a log/submit-log-${submit_arch}-${time}
}

# 参数检查
param_check

submit_num=0
while read line; 
do
    [ -z "${line}" ] && continue

    # 初始化
    line_array=(${line})
    [ ${#line_array[@]} -lt 1 ] && echo "[error] ${line}记录" 

    if [ $((${#line_array[@]} - 1)) -lt ${#param_other_arr[@]} ] ; then 
        echo "[error] 其他参数数量[${#param_other_arr[@]}] > 实际参数数量 [${#line_array[@]}]: ${line}"
        continue
    fi

    repo=${line_array[0]}

    # submit参数
    submit_other=""
    submit_repo_addr="${repo_base_addr}${repo}"

    # 设置其他参数
    index=0
    while [ $index -lt ${#param_other_arr[@]} ]; do
        submit_other="${submit_other} ${param_other_arr[${index}]}=${line_array[((${index} + 1))]} "
        ((index++))
    done

    log_msg "${repo} proc ..."

    commond="submit ${submit_job_inf} repo_addr=${submit_repo_addr} os_arch=${submit_arch} testbox=${submit_testbox} ${submit_other} ${submit_other_app_param} | tee -a log/submit-log-${submit_arch}-${time}"
    log_msg "${commond}"
    submit ${submit_job_inf} repo_addr=${submit_repo_addr} os_arch=${submit_arch} testbox=${submit_testbox} ${submit_other} ${submit_other_app_param} | tee -a log/submit-log-${submit_arch}-${time}

    log_msg "" 

    ((submit_num++))
    if [[ ${submit_num} != 0 && $((${submit_num} % 500)) == 0 ]]; then 
        # 睡眠20分钟，防止当前提交任务抢占机器
        log_msg "sleep 1200 seconds ..."
        sleep 1200
    fi
done < ${param_list}

log_msg ""
log_msg "总共提交job数量：[${submit_num}]" 