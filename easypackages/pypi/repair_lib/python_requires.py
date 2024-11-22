import argparse
import re

from openai import OpenAI


def extract_error_log_re(text):
    """
    从给定文本中提取 RPM 构建错误信息。

    参数:
        text (str): 包含错误日志的文本内容。

    返回:
        list or None: 提取的错误信息列表，如果没有找到错误则返回 None。

    此函数使用正则表达式查找'RPM build errors:'之后的所有内容，并解析出具体错误信息。
    """
    errors = re.findall(r"RPM build errors:(.*)", text, re.DOTALL)
    # print(errors)
    if not errors:
        return None
    # 打印前5条错误信息
    versions = []
    error_lines = errors[0].strip().split("\n")
    for line in error_lines:
        match = re.search(r":\s*(.*)", line.strip())
        if match:
            content_after_colon = match.group(1)
            versions.append(content_after_colon)
    print("error message:", versions)
    return versions


def find_old_line(context, old_version):
    """
    在给定上下文中查找包含旧版本号的行。

    参数:
        context (str): 包含多行文本的上下文。
        old_version (str): 要查找的旧版本号。

    返回:
        str or None: 如果找到包含旧版本号的行则返回该行，否则返回 None。

    此函数使用正则表达式查找包含指定旧版本号的行，并返回第一条匹配的行。
    """
    # 使用正则表达式查找包含 search_string 的行
    pattern = re.compile(r"^.*{}.*$".format(re.escape(old_version[0])),
                         re.MULTILINE)
    matches = pattern.findall(context)

    print(matches)
    old_version = old_version.replace(" ", "")
    print(old_version)
    # 输出匹配的行
    for match in matches:
        replace_match = match.replace(" ", "")
        print(f"match:{old_version}----{replace_match}")
        if old_version in replace_match:
            return match


def get_new_line(old_line):
    """
    使用 OpenAI API 生成包版本的新格式。

    参数:
        old_line (str): 包含旧版本号的行。

    返回:
        str: 转换后的新版本号行。

    此函数向 OpenAI 模型发送请求，以将旧版本号格式转换为只包含 >, >=, <, <= 的新格式。
    """
    client = OpenAI(base_url=base_url, api_key=api_key)
    SYSTEM_PROMPT = (
        "你是一位经验丰富python包管理专家，"
        "你的任务是将包版本只包含>,>=,<,<=的格式重新给出，输出不用额外的信息，"
        "并且替换掉包版本中的*字符，不能改动其他的原本的字符和空行缩进。"
    )

    message_content = "{old_line} 的另一种写法"
    completion = client.chat.completions.create(
        model=ai_model,
        temperature=0,
        messages=[
            {
                "role": "system",
                "content": SYSTEM_PROMPT,
            },
            {
                "role": "user",
                "content": message_content.format(old_line=old_line),
            },
        ],
    )
    return completion.choices[0].message.content


def fix_one_old_version(file_content, one_old_version):
    """
    修复文件内容中指定的旧版本号。

    参数:
        file_content (str): 文件的完整内容。
        one_old_version (str): 要修复的旧版本号。

    返回:
        str: 修复后的文件内容。

    此函数通过查找旧版本号并调用 `get_new_line` 函数进行转换，然后更新文件内容。
    """
    old_line = find_old_line(file_content, one_old_version)
    if not old_line:
        return file_content
    new_line = get_new_line(old_line)
    if not new_line:
        return file_content
    print(f"old_line:{old_line}")
    print(f"new_line:{new_line}")
    # 使用正则表达式查找并替换字符串
    new_content = re.sub(re.escape(old_line), new_line, file_content)
    return new_content


def fix_old_version(requires_path, build_log_path):
    """
    修复指定要求文件中的旧版本号。

    参数:
        requires_path (str): requirements 文件路径。
        build_log_path (str): 构建日志文件路径。

    返回:
        None: 无返回值，但会更新要求文件。

    此函数读取构建日志以提取旧版本号，然后在需求文件中进行替换。
    """
    with open(build_log_path, "r", encoding="utf-8") as file:
        content = file.read()

    old_version = extract_error_log_re(content)
    if not old_version:
        return None
    print(f"old version: {old_version}")

    with open(requires_path, "r", encoding="utf-8") as file:
        setup_cfg = file.read()

    new_content = setup_cfg
    for version in old_version:
        new_content = fix_one_old_version(new_content, version)

    with open(requires_path, "w", encoding="utf-8") as file:
        file.write(new_content)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fix version issues in cfg")
    parser.add_argument("requires_path", help="Path to requires_path file")
    parser.add_argument("build_log_path", help="Path to build err log file")
    parser.add_argument("base_url", help="ai api base url")
    parser.add_argument("api_key", help="ai api key")
    parser.add_argument("ai_model", help="ai model")
    args = parser.parse_args()
    global base_url, api_key, ai_model
    base_url = args.base_url
    api_key = args.api_key
    ai_model = args.ai_model
    fix_old_version(args.requires_path, args.build_log_path)
