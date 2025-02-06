# -*- encoding:UTF-8 -*-
import toml
import sys
import re
import os
from schedule_job import SubmitJob


def parse_toml(repo_toml=[]):
    """解析toml文件
    :return: 返回解析后的数据
    """
    repo_info = []
    repos_dir = "../rpm-repos/"

    if repo_toml:
        for root, dirs, files in os.walk(repos_dir):
            for file in files:
                if file in repo_toml:

                    repo_file = os.path.join(root, file)
                    with open(repo_file, "r", encoding="utf-8") as f:
                        config = toml.load(f)
                        # 全量转换
                        channel = config["channel"]
                        arch = config["arch"]
                        repo_os_baseurl = config["repos"]["OS"]["baseurl"]
                        repo_everything_baseurl = \
                            config["repos"]["everything"]["baseurl"]
                        repo_os = config["job"]["os"]
                        repo_os_version = config["job"]["os_version"]

                        os_repo_info_dic = {
                            "channel": channel,
                            "arch": arch,
                            "repo_name": "OS",
                            "baseurl": repo_os_baseurl,
                            "os": repo_os,
                            "os_version": repo_os_version
                        }
                        everything_repo_info_dic = {
                            "channel": channel,
                            "arch": arch,
                            "repo_name": "everything",
                            "baseurl": repo_everything_baseurl,
                            "os": repo_os,
                            "os_version": repo_os_version
                            }
                        repo_info.append(os_repo_info_dic)
                        repo_info.append(everything_repo_info_dic)
                        if "repos" in config and "update" in config["repos"] \
                            and "watch_update" in config["repos"]["update"]:
                                repo_update_baseurl = \
                                    config["repos"]["update"]["baseurl"]
                                watch_update = \
                                    config["repos"]["update"]["watch_update"]                                        
                                update_repo_info_dic = {
                                    "channel": channel,
                                    "arch": arch,
                                    "repo_name": "update",
                                    "baseurl": repo_update_baseurl,
                                    "watch_update": watch_update,
                                    "os": repo_os,
                                    "os_version": repo_os_version
                                }
                                repo_info.append(update_repo_info_dic)
    else:
        # 增量转换策略
        for root, dirs, files in os.walk(repos_dir):
            for f in files:
                if f.endswith(".toml"):
                    repo_file = os.path.join(root, f)
                    with open(repo_file, "r", encoding="utf-8") as f:
                        config = toml.load(f)
                        channel = config["channel"]
                        arch = config["arch"]
                        if "repos" in config and "update" in config["repos"] \
                            and "watch_update" in config["repos"]["update"]:
                                repo_update_baseurl = \
                                    config["repos"]["update"]["baseurl"]
                                watch_update = \
                                    config["repos"]["update"]["watch_update"]                                
                                update_repo_info_dic = {
                                    "channel": channel,
                                    "arch": arch,
                                    "repo_name": "update",
                                    "baseurl": repo_update_baseurl,
                                    "watch_update": watch_update,
                                    "os": repo_os,
                                    "os_version": repo_os_version
                                }
                                repo_info.append(update_repo_info_dic)     
    return repo_info


def main():
    """"函数入口"""
    rp_info = parse_toml()
    if rp_info:
            print("submit job...")
            submitjob = SubmitJob(rp_info, strategy="delta")
            ret = submitjob.run()
            if ret == 0:
                print("submit job success")
            else:
                print("submit job failed")
                sys.exit(1)
    else:
        print("parse yaml file failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
