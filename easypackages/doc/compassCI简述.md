# compassCI简述
## 说明
该文档记录使用compassCI的部分流程以及日志查看
## 首先安装compassCI客户端
这里把lkp-tests作为compassCI的客户端，通过本地安装lkp-tests 实现手动提交测试任务.
查看文档注意到lkp-tests提交任务依赖ruby,建议安装ruby2.5及以上版本
```bash
#将lkp-tests克隆到本地
git clone https://gitee.com/compass-ci/lkp-tests.git

# 进入安装目录
cd lkp-tests
make install
source $HOME/.${SHELL##*/}rc
```
## 测试提交任务
使用submit命令提交任务到compassCI。
我的理解是compassCI类似于调度系统，lkp-tests作为客户端，将任务推送到compassCI，compassCI再根据资源情况，将任务分发至节点执行
当然，提交任务时可指定资源情况即指定机器。
```bash
#如下命令
submit -m -c job-pypi.yaml repo_addr=newsworthycharts os_arch=aarch64 testbox=vm-2p8g

xiongkaiqi@z9 ~$ submit -m -c job-pypi.yaml repo_addr=newsworthycharts os_arch=aarch64 testbox=vm-2p8g
Ignoring openssl-2.2.0 because its extensions are not built. Try: gem pristine openssl --version 2.2.0
submit_id=241217100434171930
2024-12-17 10:04:35 +0800 WARN -- skip non-executable /home/xiongkaiqi/lkp-tests/daemon/netserver-sequence
submit job-pypi.yaml, got job id=z9.31481844
result_root /srv/result/rpmbuild-python/2024-12-17/vm-2p8g/openeuler-24.03-LTS-aarch64/aarch64-1/z9.31481844
Ignoring openssl-2.2.0 because its extensions are not built. Try: gem pristine openssl --version 2.2.0
query=>{"job_id":["z9.31481844"]}
connect to ws://api.compass-ci.openeuler.org:20001/filter
{"level_num":2,"level":"INFO","time":"2024-12-17T10:04:39.995+0800","job_id":"z9.31481844","message":"","job_state":"submit","result_root":"/srv/result/rpmbuild-python/2024-12-17/vm-2p8g/openeuler-24.03-LTS-aarch64/aarch64-1/z9.31481844","status_code":200,"method":"POST","resource":"/submit_job","api":"submit_job","elapsed_time":681.059793,"elapsed":"681.06ms"}
{"level_num":2,"level":"INFO","time":"2024-12-17T10:04:40.279+0800","job_id":"z9.31481844","result_root":"/srv/result/rpmbuild-python/2024-12-17/vm-2p8g/openeuler-24.03-LTS-aarch64/aarch64-1/z9.31481844","job_state":"set result root","status_code":101,"method":"GET","resource":"/ws/boot.ipxe/mac/0a-f9-1b-5f-70-49","testbox":"vm-2p8g.taishan200-2280-2s48p-256g--a35-2"}
{"level_num":2,"level":"INFO","time":"2024-12-17T10:04:40.638+0800","from":"172.17.0.1:50658","message":"access_record","status_code":101,"method":"GET","resource":"/ws/boot.ipxe/mac/0a-f9-1b-5f-70-49","testbox":"vm-2p8g.taishan200-2280-2s48p-256g--a35-2","job_id":"z9.31481844"}
{"level_num":2,"level":"INFO","time":"2024-12-17T10:04:40.668+0800","from":"172.17.0.1:33808","message":"access_record","status_code":200,"method":"GET","resource":"/job_initrd_tmpfs/z9.31481844/job.cgz","job_id":"z9.31481844","job_state":"download","api":"job_initrd_tmpfs","elapsed_time":0.535913,"elapsed":"535.91µs"}

The vm-2p8g testbox is starting. Please wait about 3 minutes
```
## 上述命令说明
submit命令作用是提交任务

-m 参数可以启动任务监控功能，并将执行任务过程中的状态信息打印到控制台，方便监控

-c 参数需要搭配-m参数使用，可以使申请的设备实现自动登录功能 (查看文档发现需提前执行ssh-keygen -t rsa 生成密钥文件和私钥文件)
```bash
The vm-2p8g testbox is starting. Please wait about 3 minutes
{"level_num":2,"level":"INFO","time":"2024-12-17T10:06:54+0800","mac":"0a-f9-1b-5f-70-49","ip":"172.18.188.51","job_id":"z9.31481844","state":"running","testbox":"vm-2p8g.taishan200-2280-2s48p-256g--a35-2","status_code":200,"method":"GET","resource":"/~lkp/cgi-bin/lkp-wtmp?tbox_name=vm-2p8g.taishan200-2280-2s48p-256g--a35-2&tbox_state=running&mac=0a-f9-1b-5f-70-49&ip=172.18.188.51&job_id=z9.31481844","api":"lkp-wtmp","elapsed_time":124.575754,"elapsed":"124.58ms"}
{"level_num":2,"level":"INFO","time":"2024-12-17T10:08:18.525+0800","from":"172.17.0.1:51296","message":"access_record","status_code":200,"method":"GET","resource":"/~lkp/cgi-bin/lkp-jobfile-append-var?job_file=/lkp/scheduled/job.yaml&job_id=z9.31481844&job_state=running","job_id":"z9.31481844","api":"lkp-jobfile-append-var","elapsed_time":254.047003,"elapsed":"254.05ms","job_state":"running","job_stage":"running"}
{"level_num":2,"level":"INFO","time":"2024-12-17T10:08:18.789+0800","tbox_name":"vm-2p8g.taishan200-2280-2s48p-256g--a35-2","job_id":"z9.31481844","ssh_port":"22380","message":"","state":"set ssh port","status_code":200,"method":"POST","resource":"/~lkp/cgi-bin/report_ssh_info","api":"report_ssh_info","elapsed_time":0.566163,"elapsed":"566.16µs"}
ssh root@api.compass-ci.openeuler.org -p 22380 -o StrictHostKeyChecking=no -o LogLevel=error

Authorized users only. All activities may be monitored and reported.


Welcome to 6.6.0-28.0.0.34.oe2403.aarch64

System information as of time: 	Tue Dec 17 10:08:21 AM UTC 2024

System load: 	0.86
Memory used: 	10.0%
Swap used: 	0.0%
Usage On: 	32%
IP address: 	172.18.188.51
Users online: 	1
```
testbox 参数是指定需要的测试机 上述vm-2p8g意思是会申请一台2核8G内存的虚拟机用于测试。

## 日志追踪以及查看
在提交任务进入到分配的虚拟机后，在/home/lkp下会生成rpmbuild目录，该目录下的SOURCEES目录和SPECS目录会自动下载源码和spec文件
构建RPM包的相关日志存放在/tmp/lkp/result/目录下
```bash
[root@localhost result]# ls
boot-time  executed_programs  lkp-stderr  lkp-stdout  output  rpmbuild  sleep  stderr  stdout  umesg
```
其中完整日志存放于output中，下面是部分日志,其调试过程中的日志也可在此追踪
```bash
[log] don't need repair spec by rpm mpaping
Last metadata expiration check: 0:01:27 ago on Tue 17 Dec 2024 10:14:15 AM UTC.
Package python3-devel-3.11.6-8.oe2403.aarch64 is already installed.
Package python3-pip-23.3.1-2.oe2403.noarch is already installed.
Package python3-setuptools-68.0.0-2.oe2403.noarch is already installed.
Package python3-wheel-1:0.40.0-1.oe2403.noarch is already installed.
Error:  
 Problem 1: conflicting requests
  - nothing provides python3.11dist(opencv-python-headless) needed by python3-numpyimage-2.1.0-1.noarch from python
 Problem 2: cannot install the best candidate for the job
  - nothing provides python3.11dist(jaxlib) >= 0.4.25 needed by python3-numpyro-0.16.1-1.noarch from python
 Problem 3: package python3-numpy-sugar-1.5.4-1.noarch from python requires python3.11dist(pytest) < 7, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pluggy) >= 1.5 needed by python3-pytest-8.3.3-1.noarch from python
  - nothing provides python3.11dist(pluggy) >= 1.5 needed by python3-pytest-8.3.4-1.noarch from python
 Problem 4: package python3-numpydantic-1.6.4-1.noarch from python requires python3.11dist(pydantic) >= 2.3, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pydantic-core) = 2.27 needed by python3-pydantic-2.10.0-1.noarch from python
  - nothing provides python3.11dist(pydantic-core) = 2.23.4 needed by python3-pydantic-2.9.2-1.noarch from python
 Problem 5: package python3-numpy-pydantic-types-0.1.0a0-1.noarch from python requires python3.11dist(pydantic) >= 2, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pydantic-core) = 2.27 needed by python3-pydantic-2.10.0-1.noarch from python
  - nothing provides python3.11dist(pydantic-core) = 2.23.4 needed by python3-pydantic-2.9.2-1.noarch from python
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
failed to solve dependencies
do repair_build_module_not_found count:2
Looking in indexes: http://172.168.131.2:5032/lowinli/devpi/+simple/
Requirement already satisfied: specfile in /usr/local/lib/python3.11/site-packages (0.33.0)
Requirement already satisfied: packaging in /usr/local/lib/python3.11/site-packages (24.2)
Requirement already satisfied: rpm in /usr/lib64/python3.11/site-packages (from specfile) (4.18.2)
        
==> /tmp/stderr <==
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
        
==> /tmp/stdout <==
python3 /lkp/lkp/src/programs/rpmbuild/utils/repair_build_module_not_found.py newsworthycharts /home/lkp/rpmbuild/SPECS/python-newsworthycharts.spec /tmp//build.log
No suitable module found to add as a build dependency.
repair_build_module_not_found fail
[log] ai_repair_spec: [], rpmbuild_result: [1]
[log] no need to repair by ai [1]
        
==> /tmp/stderr <==
basename: missing operand
Try 'basename --help' for more information.
basename: missing operand
Try 'basename --help' for more information.
        
==> /tmp/stdout <==
doneexit...........................
sleep started
```
其中rpmbuild文件中存放的是构建过程中的部分日志如下，可以看到构建失败的原因，便于进一步排查处理
```bash
Last metadata expiration check: 0:01:24 ago on Tue 17 Dec 2024 10:14:15 AM UTC.
Package python3-devel-3.11.6-8.oe2403.aarch64 is already installed.
Package python3-pip-23.3.1-2.oe2403.noarch is already installed.
Package python3-setuptools-68.0.0-2.oe2403.noarch is already installed.
Package python3-wheel-1:0.40.0-1.oe2403.noarch is already installed.
Error: 
 Problem 1: conflicting requests
  - nothing provides python3.11dist(opencv-python-headless) needed by python3-numpyimage-2.1.0-1.noarch from python
 Problem 2: cannot install the best candidate for the job
  - nothing provides python3.11dist(jaxlib) >= 0.4.25 needed by python3-numpyro-0.16.1-1.noarch from python
 Problem 3: package python3-numpy-sugar-1.5.4-1.noarch from python requires python3.11dist(pytest) < 7, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pluggy) >= 1.5 needed by python3-pytest-8.3.3-1.noarch from python
  - nothing provides python3.11dist(pluggy) >= 1.5 needed by python3-pytest-8.3.4-1.noarch from python
 Problem 4: package python3-numpydantic-1.6.4-1.noarch from python requires python3.11dist(pydantic) >= 2.3, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pydantic-core) = 2.27 needed by python3-pydantic-2.10.0-1.noarch from python
  - nothing provides python3.11dist(pydantic-core) = 2.23.4 needed by python3-pydantic-2.9.2-1.noarch from python
 Problem 5: package python3-numpy-pydantic-types-0.1.0a0-1.noarch from python requires python3.11dist(pydantic) >= 2, but none of the providers can be installed
  - conflicting requests   
  - nothing provides python3.11dist(pydantic-core) = 2.27 needed by python3-pydantic-2.10.0-1.noarch from python
  - nothing provides python3.11dist(pydantic-core) = 2.23.4 needed by python3-pydantic-2.9.2-1.noarch from python
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
[log] don't need repair spec by rpm mpaping
Last metadata expiration check: 0:01:27 ago on Tue 17 Dec 2024 10:14:15 AM UTC.
Package python3-devel-3.11.6-8.oe2403.aarch64 is already installed.       
Package python3-pip-23.3.1-2.oe2403.noarch is already installed.
Package python3-setuptools-68.0.0-2.oe2403.noarch is already installed.   
Package python3-wheel-1:0.40.0-1.oe2403.noarch is already installed.      
Error: 
 Problem 1: conflicting requests
  - nothing provides python3.11dist(opencv-python-headless) needed by python3-numpyimage-2.1.0-1.noarch from python
 Problem 2: cannot install the best candidate for the job
  - nothing provides python3.11dist(jaxlib) >= 0.4.25 needed by python3-numpyro-0.16.1-1.noarch from python
 Problem 3: package python3-numpy-sugar-1.5.4-1.noarch from python requires python3.11dist(pytest) < 7, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pluggy) >= 1.5 needed by python3-pytest-8.3.3-1.noarch from python
  - nothing provides python3.11dist(pluggy) >= 1.5 needed by python3-pytest-8.3.4-1.noarch from python
 Problem 4: package python3-numpydantic-1.6.4-1.noarch from python requires python3.11dist(pydantic) >= 2.3, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pydantic-core) = 2.27 needed by python3-pydantic-2.10.0-1.noarch from python
  - nothing provides python3.11dist(pydantic-core) = 2.23.4 needed by python3-pydantic-2.9.2-1.noarch from python
 Problem 5: package python3-numpy-pydantic-types-0.1.0a0-1.noarch from python requires python3.11dist(pydantic) >= 2, but none of the providers can be installed
  - conflicting requests
  - nothing provides python3.11dist(pydantic-core) = 2.27 needed by python3-pydantic-2.10.0-1.noarch from python
  - nothing provides python3.11dist(pydantic-core) = 2.23.4 needed by python3-pydantic-2.9.2-1.noarch from python
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
failed to solve dependencies                     
do repair_build_module_not_found count:2
```
## 退出虚拟机
退出虚拟机命令
```bash
# root用户下执行以下命令退出虚拟机
cci return
```
