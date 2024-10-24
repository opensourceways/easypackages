import toml
import sys


def update_pyproject_toml(file_path):
    """
        更新指定路径下的 'pyproject.toml' 文件。

        此函数执行以下修改：
        - 将 'build-system' 部分下的 'requires' 列表中任何出现的
          'poetry>=0.12' 替换为 'poetry-core>=1.0.0'。
        - 如果 'build-backend' 为 'poetry.masonry.api'，则更改为
          'poetry.core.masonry.api'。

        参数:
            file_path (str): 要更新的 'pyproject.toml' 文件的路径。

        异常:
            Exception: 如果在读取或写入文件时发生错误。
        """
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            data = toml.load(file)

        # 修改requires
        requires = data.get('build-system', {}).get('requires', [])
        if any('poetry>=' in req for req in requires):
            data['build-system']['requires'] = [
                req.replace('poetry>=0.12',
                            'poetry-core>=1.0.0') for req in requires
            ]

        # 修改build-backend
        build_backend = data.get('build-system', {}).get('build-backend', '')
        if build_backend == 'poetry.masonry.api':
            data['build-system']['build-backend'] = 'poetry.core.masonry.api'

        with open(file_path, 'w', encoding='utf-8') as file:
            toml.dump(data, file)

        print("File updated successfully.")

    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <path_to_pyproject.toml>")
    else:
        update_pyproject_toml(sys.argv[1])
