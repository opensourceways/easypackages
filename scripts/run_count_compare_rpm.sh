#!/bin/bash
# desc: 调用统计脚本入口，实现同时支持多个场景的统计
# create time: 20241218
# 说明： 执行时依次传入<未发布包路径> <发布包路径>, 程序按位置获取参数
# 如: 
# sh run_count_compare_rpm.sh /srv/rpm/testing/openeuler-24.03-LTS/ai /srv/rpm/pub/openeuler-24.03-LTS/ai/ /srv/rpm/testing/openeuler-24.03-LTS/github /srv/rpm/pub/openeuler-24.03-LTS/github/ ...

# 转成数组便于后续处理
PARAM=("$@")

check_params(){
    # 检查参数输入是否合规
    param_count="${#PARAM[@]}"
    if ((  "$param_count" == 0 || "$param_count" % 2 != 0 ));then
        echo "参数输入有误或个数不正确"
        echo "Usage: sh run_count_compare_rpm.sh <未发布包路径> <已发布包路径> (多个场景依次按这个路径顺序填入)"
        exit 1
    fi
}

join_param(){
    # 遍历并拼接参数
    for (( i=0; i<${#PARAM[@]}; i+=2 )); do
        if (( i+1 < ${#PARAM[@]} )); then
            result="${PARAM[i]} ${PARAM[i+1]}"
            echo "sh count_compare_rpm.sh "$result" "
            sh count_compare_rpm.sh "${PARAM[i]}" "${PARAM[i+1]}" &
        fi
    done
    wait
    echo "all task completed!"
}

check_params
join_param