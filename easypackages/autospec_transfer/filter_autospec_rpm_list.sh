#!/bin/bash

# aarch64 x86_64
arch_type="x86_64"
rpm_list_file_src="data/autospec_rpm_binary_list_${arch_type}"
rpm_list_file_des="data/autospec_rpm_src_list_${arch_type}"

echo -n > "${rpm_list_file_des}"
while read -r line 
do
    [ -z "$line" ] && continue

    line_arr=()
    read -ra line_arr <<< "$line"

    src_rpm="${line_arr[1]}"
    src_rpm_name=${src_rpm##*/}

    if ! grep -q "${src_rpm}" "${rpm_list_file_des}"; then 
        echo "${src_rpm_name} ${src_rpm}" >> "${rpm_list_file_des}"
    fi
done < "${rpm_list_file_src}"