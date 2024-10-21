#!/bin/bash

src_list="/home/lxb/rpmbuild/work/autospec_rpm_mv/data/autospec_rpm_src_list_aarch64_iterate_1"

while read -r line
do
    src_rpm_name=$(echo "${line}" | awk -F' ' '{printf $1}')
    src_rpm_num=$(grep -c "${src_rpm_name}" "${src_list}")

    if [ 1 -lt "${src_rpm_num}" ]; then 
        grep "${src_rpm_name}" "${src_list}"
        echo ""
    fi
done < "${src_list}"