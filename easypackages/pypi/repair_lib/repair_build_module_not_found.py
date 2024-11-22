import argparse
import re
import subprocess

import packaging.utils
import packaging.version
from specfile import Specfile


def insert_prep(specfile, contents):
    """
    在给定的 specfile 中的 'prep' 部分插入内容。

    参数:
        specfile: 要修改的 specfile 对象。
        contents (list): 要插入的内容列表。

    该函数在 'prep' 部分的末尾插入指定的内容，并保存更改。
    随后，调用 insert_changelog 函数更新变更日志。
    """
    with specfile.sections() as sections:
        for content in contents:
            sections.prep.insert(999, content)
    insert_changelog(specfile)
    specfile.save()


def insert_build_requires(specfile, spec_name, contents):
    """
    在与给定 spec_name 匹配的 'build' 部分中插入构建依赖项。

    参数:
        specfile: 要修改的 specfile 对象。
        spec_name (str): 需要匹配的规范名称。
        contents (list): 要插入的构建依赖内容列表。

    该函数在所有与 spec_name 匹配并且包含 'package' 的部分插入
    指定的构建依赖内容，并保存更改。随后，调用 insert_changelog 函数更新变更日志。
    """
    with specfile.sections() as sections:
        for section in sections:
            spec_name_processed = spec_name.lower() \
                .replace('_', '').replace('-', '')
            section_id_processed = section.id.lower() \
                .replace('_', '').replace('-', '')
            if spec_name_processed in section_id_processed and \
                    "package" in section_id_processed:
                for content in contents:
                    section.insert(999, content)
    insert_changelog(specfile)
    specfile.save()


def extract_module_name(content):
    """
    从给定的内容中提取模块名称。

    参数:
        content (str): 可能包含 ModuleNotFoundError 的文本内容。

    返回:
        str or None: 如果找到模块名称，则返回该名称；否则返回 None。

    此函数使用正则表达式查找 'ModuleNotFoundError' 异常信息并提取模块名称。
    """
    pattern = r"ModuleNotFoundError: No module named \'(.*?)\'"
    match = re.search(pattern, content)
    if match:
        return match.group(1)
    else:
        return None


def suggest_package_name(package_name):
    """
    根据给定名称建议一个有效的 Python 包名。

    参数:
        package_name (str): 要检查的包名。

    返回:
        str: 规范化后的包名，如果不合法则替换特殊字符为 '-'。

    此函数检查提供的包名是否是有效的 Python 包名，如果不是，则将
    包名中的非法字符（如 '-', '_', '.', 等）替换为 '-'。
    """
    # Check if the package name is a valid Python package name
    if packaging.utils.is_normalized_name(package_name):
        return package_name
    else:
        return re.sub(r"[-_.]+", "-", package_name)


def get_build_dep_package(error_log):
    result_list = []
    module_name = extract_module_name(error_log)
    if module_name and "mesonpy" == module_name:
        result_list.append("python3-meson-python")
        return result_list
    if module_name and "poetry" == module_name:
        result_list.append("python3-poetry-core")
        return result_list
    if "Unknown version source: vcs" in error_log:
        result_list.append("python3-hatch-vcs")
        return result_list
    if "Unknown metadata hook: fancy-pypi-readme" in error_log:
        result_list.append("python3-hatch-fancy-pypi-readme")
        return result_list
    if module_name:
        yum_output = run_yum_search(
            "python3-" + suggest_package_name(module_name))
        package_names = re.findall(r"(\S+?)(?=.(x86_64|aarch64|noarch))",
                                   yum_output)
        for package in package_names:
            if "debug" not in package[0]:
                result_list.append(package[0])
            if package[0] == module_name:
                return [module_name]
    return result_list


def run_yum_search(package_name):
    try:
        # 执行 yum search httpd 命令
        result = subprocess.run(
            ["yum", "search", package_name], capture_output=True,
            text=True, check=True
        )

        # 输出命令执行结果
        print("yum search httpd 命令执行成功！\n")
        print(result.stdout)
        return result.stdout
    except Exception as e:
        # 如果命令执行失败，输出错误信息
        print("yum search httpd 命令执行失败！\n")
        print(f"错误信息: {e}")
        return ""


def insert_changelog(specfile):
    """
    在给定的规范文件中插入变更日志条目。

    参数:
        specfile: 要修改的规范文件对象。

    此函数首先清空当前的变更日志部分，并添加一个自动生成的变更日志标题。
    然后，插入一条新的变更日志条目。
    """
    with specfile.sections() as sections:
        sections.changelog[:] = ["# autogen changelog"]
    specfile.add_changelog_entry(
        "- AI rebot change spec for openEuler OS.",
        author="ai rebot",
        email="airebot@huawei.com",
    )


def process_spec_and_file(spec_name, spec_path, error_log_path):
    """
    处理指定的规范文件并提取构建依赖项。

    参数:
        spec_name (str): 规范名称，用于生成包名。
        spec_path (str): 规范文件的路径。
        error_log_path (str): 错误日志文件的路径。

    此函数读取错误日志文件，提取构建依赖项，并将这些依赖项插入到规范文件中。
    """
    spec = Specfile(spec_path)
    try:
        with open(error_log_path, "r") as file:
            content = file.read()
            packages = get_build_dep_package(content)
            build_contents = []
            if packages:
                for package in packages:
                    build_content = f"BuildRequires:\t{package}"
                    build_contents.append(build_content)
                    print(f"spec build requires:{build_content} success")
                insert_build_requires(spec, "python3-" + spec_name,
                                      build_contents)
                print("specfile success")
            else:
                print("No suitable module found to add as a build dependency.")
    except FileNotFoundError:
        print(f"File {error_log_path} not found.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process spec file and another file path."
    )
    parser.add_argument("spec_name", help="name to the spec file.")
    parser.add_argument("spec_path", help="Path to the spec file.")
    parser.add_argument("error_log_path", help="Error file Path.")
    args = parser.parse_args()
    process_spec_and_file(args.spec_name, args.spec_path, args.error_log_path)
