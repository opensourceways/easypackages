# epkg工具使用说明
## 说明
该文档介绍epkg下载以及使用基本功能
# 安装
  下面说明如何安装使用epkg工具
```bash
# 使用通用安装方式
curl -sSL https://gitee.com/openeuler/epkg/raw/master/epkg-installer.sh -o epkg-install.sh
# 执行安装脚本
bash epkg-install.sh

# 完成之后进行初始化
epkg init
# 接下来重新执行.bashrc/bash获取新的PATH
bash

# 创建虚拟环境t1
epkg env create t1

# 创建完成之后可以使用epkg env list查看当前有哪些环境, 对应后面的Y，说明正在使用当前环境
epkg env list
[root@3d09ed686202 ~]# epkg env list
EPKG_ENV_NAME: t1
Available environments(sort by time):
Environment          Status
---------------------
t2    
t1    Y
main

# 使用epkg env activate t1 切换到t1环境
epkg env activate t1
[root@3d09ed686202 /]# epkg activate t1
Add common to path
Add t1 to path
Environment 't1' activated.

# 安装包示例
epkg install xxx
[root@3d09ed686202 /]# epkg install tree
EPKG_ENV_NAME: t1
Caching repodata for: "OS"
Cache for "OS" already exists. Skipping...
Caching repodata for: "everything"
Cache for "everything" already exists. Skipping...
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/FF/FFCRTKRFGFQ6S2YVLOSUF6PHSMRP7A2N__ncurses-libs__6.4__8.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/D5/D5BOEFTRBNV3E4EXBVXDSRNTIGLGWVB7__glibc-all-langpacks__2.38__34.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/VX/VX6SUOPGEVDWF6E5M2XBV53VS7IXSFM5__openEuler-repos__1.0__3.3.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/LO/LO6RYZTBB2Q7ZLG6SWSICKGTEHUTBWUA__libselinux__3.5__3.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/EP/EPIEEK2P5IUPO4PIOJ2BXM3QPEFTZUCT__basesystem__12__3.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/2G/2GYDDYVWYYIDGOLGTVUACSBHYVRCRJH3__setup__2.14.5__2.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/HC/HCOKXTWQQUPCFPNI7DMDC6FGSDOWNACC__glibc__2.38__34.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/OJ/OJQAHJTY3Y7MZAXETYMTYRYSFRVVLPDC__glibc-common__2.38__34.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/FJ/FJXG3K2TSUYXNU4SES2K3YSTA3AHHUMB__tree__2.1.1__1.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/KD/KDYRBN74LHKSZISTLMYOMTTFVLV4GPYX__readline__8.2__2.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/MN/MNJPSSBS4OZJL5EB6YKVFLMV4TGVBUBA__tzdata__2024a__2.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/S4/S4FBO2SOMG3GKP5OMDWP4XN5V4FY7OY5__bash__5.2.21__1.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/EJ/EJGRNRY5I6XIDBWL7H5BNYJKJLKANVF6__libsepol__3.5__3.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/TZ/TZRQZRU2PNXQXHRE32VCADWGLQG6UL36__bc__1.07.1__12.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/WY/WYMBYMCARHXD62ZNUMN3GQ34DIWMIQ4P__filesystem__3.16__6.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/KQ/KQ2UE3U5VFVAQORZS4ZTYCUM4QNHBYZ7__openEuler-release__24.09__55.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/HD/HDTOK5OTTFFKSTZBBH6AIAGV4BTLC7VT__openEuler-gpg-keys__1.0__3.3.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/EB/EBLBURHOKKIUEEFHZHMS2WYF5OOKB4L3__pcre2__10.42__8.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/YW/YW5WTOMKY2E5DLYYMTIDIWY3XIGHNILT__info__7.0.3__3.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%
start download https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64//store/E4/E4KCO6VAAQV5AJGNPW4HIXDHFXMR4EJV__ncurses-base__6.4__8.oe2409.epkg
######################################################################################################################################################################################################################################################### 100.0%

# 查看安装包版本
tree --version
which tree

# 查看repo
[root@3d09ed686202 ~]# epkg repo list
EPKG_ENV_NAME: t1
------------------------------------------------------------------------------------------------------------------------------------------------------
channel                        | repo            | url
------------------------------------------------------------------------------------------------------------------------------------------------------
openEuler-22.03-LTS-SP3        | OS              | https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-22.03-LTS-SP3/OS/aarch64/
openEuler-24.09                | OS              | https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/OS/aarch64/
openEuler-24.09                | everything      | https://repo.oepkgs.net/openeuler/epkg/channel/openEuler-24.09/everything/aarch64/
------------------------------------------------------------------------------------------------------------------------------------------------------

# 指定repo创建环境
epkg env create t2 --repo openEuler-22.03-LTS-SP3

# 安装包过程和上述一致
epkg install ${package_name} 

# 退出当前环境
epkg env deactivate ${env_name}
[root@3d09ed686202 ~]# epkg deactivate t1
Add common to path
Add main to path
Environment 't1' deactivated.

# 指定环境，持久化刷新PATH,并将指定环境设为第一优先级
epkg env enable ${env_name}
[root@3d09ed686202 ~]# epkg env enable t1   
EPKG_ENV_NAME: main
Add common to path
Add main to path
Add t1 to path
Environment 't1' added to PATH.

# 取消持久化刷新
epkg env disable t1
[root@3d09ed686202 ~]# epkg env disable t1
EPKG_ENV_NAME: main
Add common to path
Add main to path
Environment 't1' removed from PATH.

# 编译epkg软件包
# 根据autopkg提供的yaml编译软件包
epkg build ${yaml_path}
```
# 注意
    在实际使用中发现，如果使用docker exec -it 容器名 bash 进入容器操作，进入容器之后不要再次执行bash。
# 命令使用说明
    Usage:
    epkg install PACKAGE 
    epkg install [--env ENV] PACKAGE （开发中...）
    epkg remove [--env ENV] PACKAGE （开发中...）
    epkg upgrade [PACKAGE] （开发中...）

    epkg search PACKAGE （开发中...）
    epkg list （开发中...）
    
    epkg env list
    epkg env create|remove ENV
    epkg env activate ENV
    epkg env deactivate ENV
    epkg env enable|disable ENV
    epkg env history ENV （开发中...）
    epkg env rollback ENV （开发中...）

软件包安装：

    epkg env create $env // 创建环境
    epkg install $package // 在环境中安装软件包
    epkg env create $env2 --repo $repo // 创建环境2，指定repo
    epkg install $package // 在环境2中安装软件包