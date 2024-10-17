#!/bin/bash

# 检查是否输入了参数
if [ "$#" -ne 1 ]; then
    echo "用法: $0 <src-rpm>"
    exit 1
fi

# 定义变量
SRC_RPM="$1"
package=$SRC_RPM
WORKDIR="$HOME/rpmbuild"

if rpm -i --noplugins "$package"; then
    echo "$(basename "$package") rpm -i 成功"
else
    echo "$(basename "$package") rpm -i 失败"
    exit 1
fi
echo "------------------------"
pkg_name=$(rpm -qp --queryformat "%{NAME}\n" "$package")

# 安装 .src.rpm 文件中的构建依赖项
if dnf builddep -y "${WORKDIR}/SPECS/$pkg_name.spec"; then
    echo "$(basename "$package") builddep 成功"
else
    echo "$(basename "$package") builddep 失败"
    exit 1
fi

# 编译构建软件包
if rpmbuild -ba "${WORKDIR}/SPECS/$pkg_name.spec"; then
    echo "$(basename "$package") 编译构建软件包成功"
else
    echo "$(basename "$package") 编译构建软件包失败"
    exit 1
fi
# 兼容性测试
# 安装构建的软件包
# sudo yum localinstall -y ${WORKDIR}/RPMS/aarch64/$pkg_name*.rpm

# # 测试软件包的安装、卸载
# sudo yum remove -y $pkg_name
