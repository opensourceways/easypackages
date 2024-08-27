#!/bin/bash

#dir="/result/autospec/2024-04-23/vm-2p16g/openeuler-22.03-LTS-x86_64/x86_64-stderr"
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)

decomposition_parameters()
{
	[ ${#1} -eq 2 ] && day=$1 && return 0
	[ ${#1} -eq 4 ] && month=${1:0:2} && day=${1:2:2} && return 0
	[ ${#1} -eq 8 ] && year=${1:0:4} && month=${1:4:2} && day=${1:6:2} && return 0
	echo "input error"
	return 1
}

[ $# != 0 ] && {
	decomposition_parameters "$1" || exit 1
}

date="${year}-${month}-${day}"
group_id="epkg.${year}${month}${day}"

declare -A language_fr
language_fr=([C_C++_Header]="c_c++" [C]="c_c++" [C++]="c_c++" 
	[Python]="python" 
	[Java]="java" 
	[Go]="Go"
	[Ruby]="Ruby"
	[JavaScript]="JavaScript" 
	[TypeScript]="TypeScript")

check_file()
{
  echo ""
	cd "$failed_dir" || exit 1
	find . -name "*.spec" -o -name "build.log" | grep -v "\./build\.log"
	echo
}

get_language()
{
	language_l=$(grep "main programming language:" "${failed_dir}"/output | head -n 1 | cut -c 28-)

   #去掉变量 language_l 末尾的空格
	read -r language_l <<< "$language_l"

	[[ $language_l =~ [[:space:]] ]] && language_l=${language_l// /_}

	[[ $language_l == */* ]] && language_l=$(echo "${language_l}" | sed 's/\//_/g')

	language_l=${language_fr[$language_l]}

	echo "$language_l"
}

get_dir()
{

	git_url_f=$(grep "try clone git_url" "${failed_dir}"/output | awk -F ":" '{print $2 ":" $3}'| sort -u)
	git_url=${git_url_f:1}

	git_dir=$(echo "$git_url" | awk -F "/" '{print $5}')
	name=${git_dir%????}
}

time_file()
{
	cd "$failed_dir" || exit 1
	echo "failed_dir:$failed_dir"
	os_arch=$(echo "$failed_dir" | awk -F "/" '{print $6}')
	mapfile -t spec_files < <(find . -type f -name '*.spec')
	[ ${#spec_files[@]} -gt 0 ] && mapfile -t sorted_file < <(ls -t -r "${spec_files[@]}")
	spec_file=${sorted_file[0]}

	new_version=$(echo "$spec_file" | awk -F '/' '{print $2}')

	echo "version:${new_version}"
	log_file=$(find "$new_version" -type f -name 'build.log' | grep "$new_version")

}

# main

home_dir=$PWD
co_name="count_spec_buildlog_${date}"
dir_path="${home_dir}/${co_name}"
[ -d "${dir_path}" ] && rm -rf "${dir_path}"
mapfile -t failed_dir_arr < <(cci jobs group_id="${group_id}" job_health=failed -f result_root)
for failed_dir in "${failed_dir_arr[@]}" ; do
	echo "************************"

	[ "$failed_dir" == "result_root" ] && continue

	mapfile -t arr < <(check_file "$failed_dir")
	[ ${#arr[@]} -eq 0 ] && continue 

	time_file "$failed_dir"
	[ -z "$log_file" ] && continue

	echo "spec_file: $spec_file"
	echo "log_file: $log_file"


	language=$(get_language "$failed_dir")

	get_dir "$failed_dir"
	[ -z "$name" ] && continue

	echo "$language"
	cd "$failed_dir" || exit 1
	obj_specs_dir="${home_dir}/${co_name}/${language}/specs"
	all_obj_dir="${home_dir}/${co_name}"
	obj_log_dir="${home_dir}/${co_name}/${language}/log"
	mkdir -p "${obj_specs_dir}"
	mkdir -p "${obj_log_dir}"
	mkdir -p "${all_obj_dir}/${os_arch}/specs"
	mkdir -p "${all_obj_dir}/${os_arch}/log"

	echo "$name"

	echo "${name}.spec $git_url $new_version" >> "${home_dir}/${co_name}/spec_map_url.txt"
	cp "${log_file}" "${obj_log_dir}/${name}.log"
	cp "${spec_file}" "${obj_specs_dir}/${name}.spec"
	cp "${spec_file}" "${all_obj_dir}/${os_arch}/specs/${name}.spec"
	cp "${log_file}" "${all_obj_dir}/${os_arch}/log/${name}.log"
	echo "failed_dir is ${failed_dir}"
done

