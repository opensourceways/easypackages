repair目录下脚本代码是针对pypi场景的rpm构建失败的修复脚本（已在lkp-tests代码仓上库）

# python_requires.py

通过免费AI大模型，指定修复因包依赖包含*，~等字符的替换同义的<,>,=，解决构建失败问题

ex: 输入：python3 python_requires.py setup.py build.log base_url api_key
输出：替换对应依赖文件包依赖为< ,>,=符号

# repair_build_module_not_found.py

通过specfile工具操作spec文件，修改添加对应模块找不到的报错问题

ex: 输入：python3 repair_build_module_not_found.py ${repo_addr} python-${repo_addr}.spec build.log
输出： 修改spec文件，添加对应不存在的module

# repair_poetry_masonry.py

通过替换源码toml文件内容，修复poetry.core.masonry问题

ex：输入：python3 repair_poetry_masonry.py pyproject.toml
输出：修改pyproject.toml内容，修复poetry.masonry缺失的错误
