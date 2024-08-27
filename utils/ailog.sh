#!/bin/bash

# 检查是否提供了参数
if [ $# -eq 0 ]; then
    echo "请提供目录作为参数"
    exit 1
fi

[ -f "${HOME}/result.log" ] && rm "${HOME}/result.log"
# 获取第一个参数作为目录
directory="$1"
# 遍历指定目录下的所有子目录
running_num=0
success_num=0
fail_num=0
total=$(find "$directory" -type d -name "z9.*" | wc -l)
for sub_directory in "$directory"/*/; do
    # 进入每个子目录
    if ! cd "$sub_directory"; then
        echo "Failed to enter directory: $sub_directory" >> "${HOME}/result.log"
        continue
    fi

    output=$(find . -maxdepth 1 -name "output")
    if [ -n "$output" ]; then
        git_url=$(grep -oP "git clone \K(http[^\s]+)" dmesg)
        echo "source_code_path:$git_url" >> "${HOME}/result.log"

        num=$(grep -c "RPM build START TIME:" "$output")
        if [ "$num" -ne 0 ]; then
            ((success_num++))
            echo "rpmbuild:success" >> "${HOME}/result.log"
        else
            ((fail_num++))
            echo "rpmbuild:fail" >> "${HOME}/result.log"
        fi

        echo "result:${sub_directory}" >> "${HOME}/result.log"

        result=$(find . -maxdepth 1 -name "ai.log")
        if [ -n "$result" ]; then
            cat "$result" >> "${HOME}/result.log"
            echo >> "${HOME}/result.log"
        else
            echo "=====not ailog=====" >> "${HOME}/result.log"
        fi
    else
        ((running_num++))
    fi

    # 返回上一级目录
    cd .. || exit
done

not_repair_num=$(grep -c "Not Repaired" "${HOME}/result.log")

{
    echo "---------------------total:${total}-----------------------"
    echo ""
    echo "---------------------success:${success_num}-----------------------"
    echo ""
    echo "---------------------fail:${fail_num}-----------------------"
    echo ""
    echo "---------------------not_repair:${not_repair_num}-----------------------"
} >> "${HOME}/tempfile.log"

cat "${HOME}/result.log" >> "${HOME}/tempfile.log"
mv "${HOME}/tempfile.log" "${HOME}/result.log"
