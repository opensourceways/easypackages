# -*- coding: utf-8 -*-

import os
import re
import sys


def remove_extra_blank_lines(text):
    # 替换连续的空白行为单个空白行
    return re.sub(r"\n\s*\n", "\n", text)


def remove_comments(text):
    # 删除以#开头的注释行
    cleaned_content = "\n".join(
        line for line in text.splitlines() if not line.strip().startswith("#")
    )
    return cleaned_content


def extract_before_changelog(content):
    # 查找%changelog的位置
    changelog_index = content.find("%changelog")

    if changelog_index == -1:
        print("没有找到%changelog标记。")
        return content  # Return original content if %changelog is not found

    # 截取%changelog之前的文本
    content_before_changelog = content[:changelog_index].strip()

    # 删除多余的空行
    cleaned_content = remove_extra_blank_lines(content_before_changelog)

    # 删除以#开头的注释行
    cleaned_content = remove_comments(cleaned_content)

    return cleaned_content


def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <file_path>")
        sys.exit(1)  # Correct placement of sys.exit(1)

    file_path = sys.argv[1]

    # 读取文件内容
    try:
        print("file_path", file_path)
        with open(
            file_path, "r", encoding="utf-8"
        ) as file:  # Ensure file is read with utf-8 encoding
            content = file.read()
    except FileNotFoundError:
        print(f"Error: The file '{file_path}' does not exist.")
        sys.exit(1)

    # 执行函数
    result = extract_before_changelog(content)
    filename = os.path.basename(file_path)
    number_of_lines = result.count("\n") + (1 if result else 0)

    # 打印结果
    print(result)
    print(f"Number of lines: {number_of_lines}")  # More informative output

    # directory = './remove_changelog/'

    # 创建目录
    # os.makedirs(directory, exist_ok=True)
    with open(
        file_path, "w", encoding="utf-8"
    ) as file:  # Use os.path.join for better path handling
        file.write(result)


if __name__ == "__main__":
    main()
