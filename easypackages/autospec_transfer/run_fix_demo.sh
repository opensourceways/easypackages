#!/bin/bash

wget_srpm()
{
    add_user_mock
    # shellcheck disable=SC2154
    local src_rpm_name=${repo_addr//wget:/}
    echo "[log] src rpm from wget: ${src_rpm_name}  ${repo_addr}"
    wget -P /tmp/ https://api.compass-ci.openeuler.org:20007/result/rpmbuild-test-lxb/tmp/"${src_rpm_name}"
    ls /tmp/
    echo "[log] src rpm from wget succ."

    # 此处超长，记得取消换行 --开始
    su lkp -c "rpm -i --noplugins --nosignature /tmp/${src_rpm_name} >/dev/null" || \
    su lkp -c "rpm -i --noplugins --nosignature /tmp/${src_rpm_name}>/dev/null" || \
    die "failed to install source rpm: ${repo_addr}"
    # --结束

    get_srpm_readme
}

#原有接口，增加了从z9服务器wget场景
from_srpm()
{
    [ -n "$repo_addr" ] || die "repo_addr is empty"

    if [[ "${repo_addr##*.}" = "rpm" && "${repo_addr}" =~ ^http ]]; then
        # 源码仓获取
        install_srpm
        rpmbuild_type="srpm"
    elif [[ "${repo_addr}" =~ ^wget: ]]; then
        # 从z9获取
        wget_srpm
    elif [[ "${repo_addr##*.}" = "git" ]]; then
        # git仓库获取
        clone_srpm
    else
        #pyp2rpm_spec
        pyporter_spec
        # shellcheck disable=SC2034
        rpmbuild_type="pyporter_spec"
        #rpmbuild_type="pyp2rpm_spec"
    fi
}


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