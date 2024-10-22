#!/bin/bash

#-------------------------------------------------------------------------------
# 功能描述：
#       打印日志
#       
# 说明：
#       如果定义project_log_file环境变量，则会将日志打印到控制台，并输出到对应文件中；
#       否则只会将日志打印到控制台
#-------------------------------------------------------------------------------
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

#-------------------------------------------------------------------------------
# 功能描述：
#       解压压缩包
#
# 参    数：
#       1、$1：文件路径
#       2、$2：解压后保存路径
#-------------------------------------------------------------------------------
file_uncompress()
{

    if [ $# -ne 2 ]; then 
        echo "[error] file_uncompress args num error: [$#]"
        exit 1
    fi

    file=$1
    unzip_des_dir_tmp=$2

    if [ ! -f "${file}" ]; then
        echo "[error] file_uncompress, src file is not exist: ${file}"
        exit 1
    fi

    des_path=$(dirname "${unzip_des_dir_tmp}")
    if [ ! -d "${des_path}" ]; then
        echo "[error] file_uncompress, des dir is not exist: ${des_path}"
        exit 1
    fi

    # 解压压缩文件到目标文件夹中
    local ori_path_file_uncompress
    case "${file}" in
        "*.tar" | "*.txz" | "*.tar.zst" | "*.tar.lzma")
            tar -xf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        *.tar.gz)
            tar -xzf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        "*.tar.bz2" | "*.tbz")
            tar -xjf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        *.tar.xz)
            tar -xJf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        *.tar.zstd)
            tar -I zstd -xf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        "*.tar.tgz" | "*.tgz")
            tar -zxf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        *.tar.lz)
            tar -I lzip -xf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        *.tar.Z)
            tar -xZf "${file}" -C "${unzip_des_dir_tmp}"
            ;;
        "*.zip" | "*.xpi" | "*.oxt")
            unzip "${file}" -d "${unzip_des_dir_tmp}"
            ;;
        *.7z)
            7za x "${file}" -o "${unzip_des_dir_tmp}"
            ;;
        *.zst)
            ori_path_file_uncompress=$(pwd)
            cd "${unzip_des_dir_tmp}" || return 0
            unzstd "${ori_path_file_uncompress}/${file}"
            cd "${ori_path_file_uncompress}" || return 0
            #unzstd "${file}" -o "${unzip_des_dir_tmp}"
            ;;
        *.gz)
            ori_path_file_uncompress=$(pwd)
            cd "${unzip_des_dir_tmp}" || return 0
            gunzip "${ori_path_file_uncompress}/${file}"
            cd "${ori_path_file_uncompress}" || return 0
            ;;
        *)
            echo "[error] Unsupported file format: [${file}]"
            ;;
    esac
}

#----------------------------------------------
# 功能描述：
#       通过repomd.xml链接下载primary_xml
# 参数：（3个）
#       $1：repomd.xml的url地址
#       $2：xml文件保存路径
#----------------------------------------------
download_primary_xml_by_repomdxml()
{
    if [ $# -ne 2 ]; then 
        echo "[error] download_primary_xml_by_repomdxml args num error: [$#]"
        exit
    fi

    local repo_url="$1"
    local work_path="$2"
    local ori_work_path
    ori_work_path=$(pwd)

    if [ -z "${repo_url}" ]; then 
        echo "[warn] repomd.xml url is empty: [${repo_url}]"
        return 0
    fi

    if [ ! -d "${work_path}" ]; then 
        mkdir -p "${work_path}"
        chmod 775 "${work_path}"
    fi
    #log_msg "[log] file save path: [${work_path}]"

    cd "${work_path}" || exit 1

    rm -f ./repomd.xml

    # 下载repomd.xml文件
    wget -q "${repo_url}"
    if [ ! -f "./repomd.xml" ]; then 
        log_msg "[error] wget repomd.xml error[${repo_url}] ..."
        return 1 
    fi

     # 过滤出软件信息文件
    primary_xml_gz_file_name=$(grep "primary.xml.gz" ./repomd.xml)
    if [ -z "${primary_xml_gz_file_name}" ]; then 
        primary_xml_gz_file_name=$(grep "primary.xml" ./repomd.xml | head -n 1)
    fi
    primary_xml_gz_file_name=$(echo "${primary_xml_gz_file_name}" | awk -F'/' '{print $2}' | awk -F'"' '{print $1}')
    
    # shellcheck disable=SC2001
    primary_xml_file_name=$(echo "${primary_xml_gz_file_name}" | sed 's/\.[^.]*$//')

    if [ -f "${primary_xml_file_name}" ]; then
        log_msg "[warn] primary.xml exist: ${work_path}/${primary_xml_file_name}"
        return 0
    fi
    rm -f "${primary_xml_gz_file_name}"

    # 下载软件信息文件
    url_base_primary=$(echo "${repo_url}" | awk -F'/repomd.xml' '{print $1}')
    url_primary_xml_file="${url_base_primary}/${primary_xml_gz_file_name}"
    wget -q "${url_primary_xml_file}"
    if [ ! -f "${primary_xml_gz_file_name}" ]; then 
        log_msg "[error] wget primary.xml error: [${url_primary_xml_file}] ..."
        return 1
    fi
    file_uncompress "${primary_xml_gz_file_name}" "./"
    #/usr/lib/rpm/rpmuncompress -x "${primary_xml_gz_file_name}"

    if [ ! -f "${primary_xml_file_name}" ]; then 
        log_msg "[error] unzip primary.xml error: [${primary_xml_file_name}] ..."
        return 1
    fi

    rm -f repomd.xml

    cd "$ori_work_path" || exit 1
}


#-------------------------------------------------------------------------------
# 功能描述：
#       1、遍历argu_urls_arr（rpm二进制包仓库地址数组）；
#       2、根据仓库地址生成二进制包列表（格式：rpm_name rpm_version）
#
# 参    数：
#       1、$1：文件保存路径
#       2、$2：list文件名
#       3、$3: 架构类型
#       4、$4: 仓库地址("url1 url2 ...")
#
# 说    明：
#       1、下载的元素数据文件会保存到 $1/work中
#-------------------------------------------------------------------------------
download_binary_primary_xml()
{
    file_save_path="$1"
    list_file_name="$2"
    arch_type="$3"
    src_xlm_urls=()
    read -ra src_xlm_urls <<< "$4"

    log_msg "${src_xlm_urls[@]}"
    if [ 0 -eq "${#src_xlm_urls[@]}" ]; then
        log_msg "[error] src_xlm_urls is empty"
    fi

    list_file="${file_save_path}/${list_file_name}"
    true > "${list_file}"

    local ori_work_path
    ori_work_path=$(pwd)

    xml_save_path="${file_save_path}/work"
    if [ ! -d "${xml_save_path}" ]; then
        mkdir -p "${xml_save_path}/"
        chmod 775 "${xml_save_path}/"
    else 
        rm -rf "${xml_save_path}"/*-primary.xml*
    fi

    for url in "${src_xlm_urls[@]}"
    do
        if [ -z "${url}" ]; then 
            continue
        fi

        download_primary_xml_by_repomdxml "${url}" "${xml_save_path}"
        
    done

    cd "${ori_work_path}" || exit 1
    log_msg ""
    res_msg=$(python3 ./../utils/getRpmBinaryList.py -lf "${list_file}" -xp "${xml_save_path}" -arch "${arch_type}")
    #echo "${res_msg[@]}"
    res_stat=$(echo "${res_msg[@]}" | grep -o "SUCCESS NOW")
    if [ -z "${res_stat}" ]; then
        log_msg "[error] getRpmBinaryList.py fail: ${res_msg[*]}"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# 功能描述：
#       1、遍历arpm源码仓库地址；
#       2、根据仓库地址生成源码包列表（格式：repo_addr rpm_name rpm_version）
#
# 参    数：
#       1、$1：文件保存路径
#       2、$2：list文件名
#       3、$3: 仓库地址("url1 url2 ...")
#
# 说    明：
#       1、下载的元素数据文件会保存到 $1/work中
#-------------------------------------------------------------------------------
download_source_primary_xml()
{
    file_save_path="$1"
    list_file_name="$2"
    src_xlm_urls=()
    read -ra src_xlm_urls <<< "$3"

    log_msg "${src_xlm_urls[@]}"
    if [ 0 -eq "${#src_xlm_urls[@]}" ]; then
        log_msg "[warn] src_xlm_urls is empty: ${src_xlm_urls[*]}"
    fi

    list_file="${file_save_path}/${list_file_name}"
    if [ -f "${list_file}" ]; then 
        rm -f "${list_file}"
    fi

    local ori_work_path
    ori_work_path=$(pwd)

    xml_save_path="${file_save_path}/work"
    if [ ! -d "${xml_save_path}" ]; then
        mkdir -p "${xml_save_path}/"
        chmod 775 "${xml_save_path}/"
    else
        rm -rf "${xml_save_path}"/*-primary.xml*
    fi

    declare -A repo_to_primary_xml_arr
    for url in "${src_xlm_urls[@]}"
    do
        if [ -z "${url}" ]; then 
            continue
        fi

        if ! download_primary_xml_by_repomdxml "${url}" "${xml_save_path}"; then 
            log_msg "[error] primary download fail: ${url}"
            continue
        fi

        repo_to_primary_xml_arr["${url}"]="${primary_xml_file_name}"
    done

    cd "${ori_work_path}" || exit 1
    
    for key in "${!repo_to_primary_xml_arr[@]}"; do
        repo_base=$(echo "${key}" | awk -F'/repomd.xml' '{print $1}')
        res_msg=$(python3 ./../utils/getRpmSourceList.py -lf "${list_file}" -xf "${xml_save_path}/${repo_to_primary_xml_arr[$key]}" -repo "${repo_base}")
        #echo "${res_msg[@]}"
        res_stat=$(echo "${res_msg[@]}" | grep -o "SUCCESS NOW")
        if [ -z "${res_stat}" ]; then
            log_msg "[error] getRpmBinaryList.py fail: xml[${xml_save_path}/${repo_to_primary_xml_arr[$key]}] repo[${repo_base}] msg[${res_msg[*]}]"
        fi
    done
}

#-------------------------------------------------------------------------------
# 功能描述：
#       对文件中的记录进行过滤；
#
# 参    数：
#       1、$1：源文件（包含路径）
#       2、$2：过滤文件（含路径）
#
#-------------------------------------------------------------------------------
filter_src_rpm_by_file()
{
    src_list=$1
    filter_file=$2

    if [ ! -f "${src_list}" ]; then 
        log_msg "[error] src list path is not exist: ${src_list}"
        return 1
    fi

    if [ ! -f "${filter_file}" ]; then 
        log_msg "[warn] filter list file is not exist: ${filter_file}"
        return 0
    fi

    list_tmp="${src_list}-tmp"

    true > "${list_tmp}"
    while read -r line; do
        if ! grep -q -F "${line}" "${filter_file}"; then 
            echo "$line" >> "${list_tmp}"
        fi
    done < "${src_list}"

    mv -f "${list_tmp}" "${src_list}"
}