#!/bin/bash
# desc
#根据不同场景，传入目录，统计出二进制rpm包，发布的二进制包，源码包，发布的源码包情况
# create time: 20241216
# args: RPM_PATH (待统计RPM包目录,如:/srv/rpm/testing/openeuler-24.03-LTS/centos9)

RPM_PATH=$1
PUB_RPM_PATH=$2
SRC_RPM_PATH=$RPM_PATH
PUB_SRC_RPM_PATH=$PUB_RPM_PATH


check_params(){
    if [ -z "$RPM_PATH" ] || [ -z "$PUB_RPM_PATH" ];then
        echo "[error] ONE OR MORE PARAM PATH ARE EMPTY!"
        echo "USAGE: sh count_compare_rpm.sh <构建成功RPM包路径> <发布成功RPM包路径>"
        exit 1
    fi
}

get_src_num(){
    # 输出包的信息，不带包版本
    local rpm_tmp_file=$1
    while read -r rpm_file; do
        rpm -qp --queryformat "%{NAME}\n" "${rpm_file}"
    done < "$rpm_tmp_file"
}

lookup_count_rpm(){
    # 查找统计rpm包情况
    system_type=$(basename "$RPM_PATH")  
    rpm_info_tmp_file=$system_type"_rpm_1103.txt"
    rpm_pkg_tmp_file=$system_type"_rpm_package_name_1103.txt"
    rpm_uniq_tmp_file=$system_type"_uniq_rpm_1103.txt"

    pub_rpm_info_tmp_file=$system_type"_pub_rpm_1103.txt"
    pub_rpm_pkg_tmp_file=$system_type"_pub_rpm_package_name_1103.txt"
    pub_rpm_uniq_tmp_file=$system_type"_uniq_pub_rpm_1103.txt"

    src_rpm_info_tmp_file=$system_type"_src_rpm_1103.txt"
    src_rpm_pkg_tmp_file=$system_type"_src_rpm_package_name_1103.txt"
    src_rpm_uniq_tmp_file=$system_type"_uniq_src_rpm_1103.txt"

    src_pub_rpm_info_tmp_file=$system_type"_src_pub_rpm_1103.txt"
    src_pub_rpm_pkg_tmp_file=$system_type"_src_pub_rpm_package_name_1103.txt"
    src_pub_rpm_uniq_tmp_file=$system_type"_uniq_src_pub_rpm_1103.txt"
    # 二进制rpm包情况
    find_process_rpm "$rpm_info_tmp_file" "$rpm_pkg_tmp_file" "$rpm_uniq_tmp_file" "$RPM_PATH" "N"
    # 发布二进制包情况
    find_process_rpm "$pub_rpm_info_tmp_file" "$pub_rpm_pkg_tmp_file" "$pub_rpm_uniq_tmp_file" "$PUB_RPM_PATH" "N"
    # 源码包情况
    find_process_rpm "$src_rpm_info_tmp_file" "$src_rpm_pkg_tmp_file" "$src_rpm_uniq_tmp_file" "$SRC_RPM_PATH" "Y"
    # 发布源码包情况
    find_process_rpm "$src_pub_rpm_info_tmp_file" "$src_pub_rpm_pkg_tmp_file" "$src_pub_rpm_uniq_tmp_file" "$PUB_SRC_RPM_PATH" "Y"

    # 统计结果
    count_result "$system_type"
}

find_process_rpm(){   
    local rpm_info_tmp_file=$1
    local rpm_pkg_tmp_file=$2
    local rpm_uniq_tmp_file=$3
    local rpm_path=$4
    local src_flag=$5
    if [[ $src_flag == "N" ]];then
        find "$rpm_path" -name "*rpm" | grep -v "src" > "$rpm_info_tmp_file"
    else
        find "$rpm_path" -name "*rpm" | grep "src" > "$rpm_info_tmp_file"
    fi
    get_src_num "$rpm_info_tmp_file" > "$rpm_pkg_tmp_file"
    cat "$rpm_pkg_tmp_file"| sort|uniq -c|sort -nr|more > "$rpm_uniq_tmp_file"
}

count_result(){
    # 统计结果
    system_type=$1
    
    # 源码包构建成功个数
    src_rpm_build_total=$(wc -l "$src_rpm_info_tmp_file"|awk -F ' ' '{print $1}')
    # 源码包构建成功包名称个数
    src_rpm_build_package_total=$(wc -l "$src_rpm_uniq_tmp_file"|awk -F ' ' '{print $1}')
    # 二进制包构建成功个数
    rpm_build_total=$(wc -l "$rpm_info_tmp_file"|awk -F ' ' '{print $1}')
    # 二进制包构建成功包名称个数
    rpm_build_package_total=$(wc -l "$rpm_uniq_tmp_file"|awk -F ' ' '{print $1}')
    # 发布成功源码包个数
    pub_src_rpm_total=$(wc -l "$src_pub_rpm_info_tmp_file"|awk -F ' ' '{print $1}')
    # 发布成功源码包名称个数
    pub_src_rpm_package_total=$(wc -l "$src_pub_rpm_uniq_tmp_file"|awk -F ' ' '{print $1}')
    # 发布成功二进制包个数
    pub_rpm_build_total=$(wc -l "$pub_rpm_info_tmp_file"|awk -F ' ' '{print $1}')
    # 发布成功二进制包名称个数
    pub_rpm_build_package_total=$(wc -l "$pub_rpm_uniq_tmp_file"|awk -F ' ' '{print $1}')


    cat > "$system_type""_count_result_info.txt" <<EOF
        -----------------------------------统计清单---------------------------------------------
                    构建成功                                     发布成功
        src.rpm源码包      二进制RPM软件包         src.rpm源码包          二进制RPM软件包
        包个数   软件个数   包个数  软件个数        包个数  软件个数        包个数  软件个数
        $src_rpm_build_total    $src_rpm_build_package_total      $rpm_build_total   $rpm_build_package_total \
            $pub_src_rpm_total   $pub_src_rpm_package_total         $pub_rpm_build_total\
    $pub_rpm_build_package_total
EOF
}

clear_tmp_file(){
    #清理临时文件
    rm "$system_type"*1103.txt
}

check_params
lookup_count_rpm
clear_tmp_file
