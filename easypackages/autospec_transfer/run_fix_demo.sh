#!/bin/bash

#------------------------------------------------------------------
#   说明：
#       在autospec迁移过程中，用于解决%files阶段路径错误问题
#------------------------------------------------------------------

repair_spec_in_autospec()
{
    spec_dir=$1

    # 检查是否为python问题
    fail_num=0
    # shellcheck disable=SC2154
    log_file_path="${rpmbuild_result_path}/build.log"
    # shellcheck disable=SC2086
    if grep -q -E "File not found: /root/rpmbuild/BUILDROOT.*usr.*/python3.9/" ${log_file_path}; then
        ((fail_num++))
        echo "[log] need replace python3.9"
    else 
        echo "[log] don't need replace python3.9"
        return 1
    fi

    python_version=$(rpm --eval %python3_version)
    python_main_version=${python_version%%.*}
    python_minor_version=${python_version##*.}

    echo "[log] python main version [${python_main_version}], minor_version[${python_minor_version}]"

    replace_content=(
            "python3\\.9 python${python_main_version}\\.${python_minor_version}" 
            "py3\\.9 py${python_main_version}\\.${python_minor_version}" 
            "python-39 python-${python_main_version}${python_minor_version}"
            "py-39 py-${python_main_version}${python_minor_version}" 
            #"-3\\.9 -${python_main_version}\\.${python_minor_version}"
    )

    # shellcheck disable=SC2086
    find "${spec_dir}" -type f -name "*.spec" |while read -r spec_file
    do
        for item in "${replace_content[@]}"
        do
            ori_content=${item%% *}
            des_content=${item##* }
            sed -i "s/${ori_content}/${des_content}/g" "${spec_file}"
        done
    done
}

autospec_build_rpm()
{
    # ... build_rpm其他代码
    
    # shellcheck disable=SC2154
    su - lkp -c "rpmbuild -ba ${spec_dir}/*.spec ${res_rpm_file_exten} 2>&1 | tee ${rpmbuild_result_path}/build.log;exit \${PIPESTATUS[0]}"
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        repair_require || root_attempt
        # shellcheck disable=SC2181
        if [ $? -ne 0 ]; then 
            # 修复spec文件
            # shellcheck disable=SC2154
            if ! repair_spec_in_autospec "${rpmdev_dir}/SPECS"; then 
                echo "[error] repair_spec_in_autospec error"
                return 1
            fi

            su - lkp -c "rpmbuild -ba ${spec_dir}/*.spec ${res_rpm_file_exten} 2>&1 | tee ${rpmbuild_result_path}/build.log;exit \${PIPESTATUS[0]}"
            if [ "${PIPESTATUS[0]}" -ne 0 ]; then
	            repair_require || root_attempt
                # shellcheck disable=SC2181
                [ $? -ne 0 ] && return 1
            fi
        fi
    fi

    # ... build_rpm其他代码
}