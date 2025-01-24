# -*- encoding:UTF-8 -*-
import argparse
import os
from schedule_repos import parse_toml
from schedule_job import SubmitJob

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="全量转换策略")
    parser.add_argument("-f",required=False, help="指定repo文件更新,逗号分隔", default="")
    args = parser.parse_args()

    repo_toml_path = "../rpm-repos/"
    if args.f is not None and args.f != "":
        # 指定repo文件转换
        repo_toml = args.f.split(",")
    else:
        # rpm_repos文件夹下所有toml文件转换
        repo_toml = [f for f in os.listdir(repo_toml_path) if os.path.isfile(os.path.join(repo_toml_path, f))]

    toml_info = parse_toml(repo_toml)
    if toml_info:
        sj = SubmitJob(toml_info, strategy="all")
        sj.run()
