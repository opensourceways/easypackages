import os
import re
import sys
import argparse

sys.path.append('../')
from lib import lib_py_rpm

'''
 功能描述：
    根据指定的源码包元数据文件，并解析出源码包列表
 参数：
    lf: 结果清单文件（路径 + 文件名）
    xf: 元数据文件路径（primary.xml， 路径 + 文件名）
    repo: 仓库基地址
 输出：
    结果清单文件：
        文 件 名: （输入指定）
        文件内容: （源码包仓库地址 源码包名 源码包版本）
            repo_addr rpm_name rpm_version
        样    例: 
                https://dl.fedoraproject.org/pub/epel/testing/next/9/Everything/source/tree/repodata/Packages/r/rust-cargo-util-0.2.14-1.el9.next.src.rpm rust-cargo-util 0.2.14
                https://dl.fedoraproject.org/pub/epel/testing/next/9/Everything/source/tree/repodata/Packages/r/rust-crates-io-0.40.4-1.el9.next.src.rpm rust-crates-io 0.40.
'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(usage=""" 获取源码包列表 """)
    parser.add_argument('-lf', type=str, required=True, help="结果文件")
    parser.add_argument('-xf', type=str, required=True, help="元数据文件")
    parser.add_argument('-repo', type=str, required=True, help="源码包远端地址")
    args = parser.parse_args()
    list_file = str(args.lf)
    primary_xml = str(args.xf)
    repo_base = str(args.repo)

    # 检查list文件
    if os.path.exists(list_file):
        if not os.path.isfile(list_file):
            print(f"list file is not file: {list_file}")
            sys.exit(1)
            
    res = lib_py_rpm.get_src_rpm_list_by_primary_xml(primary_xml, repo_base)
    if res is None:
        print("FAIL NOW")
        sys.exit(1)

    with open(list_file, 'a') as file:
        for record in res:
            file.write(record + "\n")

    print("SUCCESS NOW")
