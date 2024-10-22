#!/bin/bash
# aarch64
arch_type="x86_64"
rpm_list_file="autospec_rpm_binary_list_${arch_type}"

os_version_dir="openeuler-22.03-LTS-${arch_type}"
rpm_binary_path="/srv/autopkg-rpms/${os_version_dir}"
rpm_src_path="/srv/autopkg-src-rpms/${os_version_dir}"

dir_paths=("${rpm_binary_path}" "${rpm_src_path}")
for path in "${dir_paths[@]}"
do
    [ ! -d "${path}" ] && echo "[error] dir not exist: ${path}" && exit 1
done

echo -n > "${rpm_list_file}"
find "${rpm_binary_path}" -type f -name "*.${arch_type}.rpm" -follow | while read -r file
do
    rpm_info=$(rpm -qi "$file")
    rpm_base_name=$(echo "$rpm_info" | grep -o -E "^Name.*:.*" | awk -F':' '{print $NF}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    rpm_version=$(echo "$rpm_info" | grep -o -E "^Version.*:.*" | awk -F':' '{print $NF}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    rpm_arch=$(echo "$rpm_info" | grep -o -E "^Architecture.*:.*" | awk -F':' '{print $NF}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    rpm_src_rpm=$(echo "$rpm_info" | grep -o -E "^Source RPM.*:.*" | awk -F':' '{print $NF}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    rpm_relative_file=$(echo "${file}" | awk -F"/${os_version_dir}/" '{print $NF}')
    rpm_name=${file##*/}
    rpm_relative_path=${rpm_relative_file%/*}
    rpm_src_rpm_path="${rpm_src_path}/${rpm_relative_path}/${rpm_src_rpm}"

    if [ -z "${rpm_src_rpm_path}" ] || [ ! -f "${rpm_src_rpm_path}" ]; then
        rpm_src_rpm_path_tmp="${rpm_src_rpm_path}"
        rpm_src_rpm_path=$(find "${rpm_src_path}" -name "${rpm_src_rpm}" -follow)
        if [ -z "${rpm_src_rpm_path}" ] || [ ! -f "${rpm_src_rpm_path}" ]; then
            echo "[error] .src.rpm file not exist: ${file}  ${rpm_src_rpm_path_tmp}" && continue
        fi
    fi

    echo "${rpm_name} ${rpm_src_rpm_path} ${rpm_base_name} ${rpm_version} ${rpm_arch}" >> "${rpm_list_file}"
done

# 需要过滤掉重复的源码包用于构建