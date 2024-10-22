#!/bin/bash
# 检查是否传递了参数
if [ $# -ne 1 ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

# 将传入的参数赋值给file变量
file="$1"
# 获取文件的目录
dir_path=$(dirname "$file")
result_log_path="${dir_path}/result.log"
result_succ_list="${dir_path}/result_succ_list"
result_fail_list="${dir_path}/result_fail_list"
[ -f "$result_log_path" ] && rm "$result_log_path"
[ -f "$result_succ_list" ] && rm "$result_succ_list"
[ -f "$result_fail_list" ] && rm "$result_fail_list"
running_num=0
success_num=0
fail_num=0
not_repair_num=0
waitting_num=0
skip_ai_repair=0
need_repair_code=0
no_module_error=0
rpm_install_num=0
repo_503_num=0
total=$(grep -c "z9.*" "${file}")
while read -r line;
do
    job_result_path=${line}
    echo "${job_result_path}"
    if [ ! -d "${job_result_path}" ]; then
	      ((waitting_num++))
	      continue;
    fi
    read -r job_result_path <<< "$job_result_path"
    repo_name=$(grep "^repo_addr:" "${job_result_path}/job.yaml" | awk '{print $2}')
    output=$(find "${job_result_path}" -maxdepth 1 -name "output")
    if [ -n "$output" ]; then
	      mapfile -t found_files < <(find . -type f \( -iname '*readme*.md' -o -iname '*readme*.MD' \))
        if [ ${#found_files[@]} -gt 0 ]; then
            echo "HAS README" >> "${result_log_path}"
        else
            echo "NOT README" >> "${result_log_path}"
        fi
	      if grep -q "Errors during downloading metadata for repository 'OS'" "$output"; then
		        ((repo_503_num++))
		        continue;
	      fi
	      git_url=$(grep "git clone" "${job_result_path}/dmesg" | awk -F'git clone' '{print "git clone" $2}')
        echo "source_code_path:$git_url" >> "${result_log_path}"
        if grep -q "rpmbuild success" "$output"; then
	          if ! grep -q "fail to local install rpms" "$output"; then
                ((rpm_install_num++))
		        fi
            ((success_num++))
            echo "rpmbuild:success" >> "${result_log_path}"
		        echo "${repo_name}" >> "${result_succ_list}"
		        continue
        else
            ((fail_num++))
            echo "rpmbuild:fail" >> "${result_log_path}"
		        echo "${repo_name}" >> "${result_fail_list}"
        fi
	      spec_path=$(find "${job_result_path}" -name '*.spec')
	      spec_name=$(basename "$spec_path")
	      echo "====================spec_name:${spec_name}====================" >> "${result_log_path}"
        echo "result:${job_result_path}" >> "${result_log_path}"
	      if grep -q "rpmbuild success" "$output";then
	          continue
	      fi
	      skip_ai_num=$(grep -c  "skip ai repair" "${output}")
	      [ "${skip_ai_num}" -gt 0 ] && ((skip_ai_repair++))
	      build_log=$(find "${job_result_path}" -maxdepth 1 -name "build.log")
	      if [ -f "${build_log}" ]; then
		        echo "===================log=========================" >> "${result_log_path}"
	          cat "${build_log}" >> "${result_log_path}"
	      fi
	      if grep -q "ModuleNotFoundError: No module named"  "${build_log}"; then
		        ((no_module_error++))
	      fi
	      if grep -q "Illegal char '*'" "${build_log}" || grep -q "Dependency tokens must begin with alpha-numeric" "${build_log}"; then
            ((need_repair_code++))
        fi
        result=$(find "${job_result_path}" -maxdepth 1 -name "ai.log")
        if [ -n "$result" ]; then
            cat "${result}" >> "${result_log_path}"
            echo >> "${result_log_path}"
        else
            echo "=====not ailog=====" >> "${result_log_path}"
        fi
    else
	      echo "${job_result_path} is running"
        ((running_num++))
    fi
done < "${file}"

[ -f "${result_log_path}" ] && not_repair_num=$(grep -c "Not Repaired" "${result_log_path}")

{
    echo "====================total:${total}===================="
    echo
    echo "====================running:${running_num}===================="
    echo
    echo "====================success:${success_num}===================="
    echo
    echo "====================fail:${fail_num}===================="
    echo
    echo "====================not_repair:${not_repair_num}===================="
    echo
    echo "====================skip_ai_repair:${skip_ai_repair}===================="
    echo
    echo "====================need_repair_code:${need_repair_code}===================="
    echo
    echo "====================no_module_error:${no_module_error}===================="
    echo
    echo "====================waitting_num:${waitting_num}===================="
    echo
    echo "====================rpm_install_num:${rpm_install_num}===================="
    echo
    echo "====================repo_503_num:${repo_503_num}===================="
} >> "${dir_path}/tempfile.log"

[ -f "${result_log_path}" ] && cat "${result_log_path}" >> "${dir_path}/tempfile.log"
mv "${dir_path}"/tempfile.log "${result_log_path}"