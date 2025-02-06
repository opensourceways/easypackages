# -*- encoding:UTF-8 -*-
# description: submit job
# created time: 20250116
import subprocess
from time import sleep
from data_statistics import DataStatistics


class SubmitJob(object):
    def __init__(self, repo_info, strategy):
        self.repo_info = repo_info
        self.strategy = strategy

    def run(self):
        """submit job"""
        submit_job_count = 0
        for repos_info in self.repo_info:
            baseurl = repos_info["baseurl"]
            channel = repos_info["channel"]
            count = 0
            if self.strategy == "all":
                # 全量转换
                command = "submit -m -c translate_job.yaml rpm_baseurl={0} \
                        repo_name={1} translate_strategy=all".format(baseurl,
                                                                     channel)
                subprocess.Popen(command, shell=True, 
                                 text=True, capture_output=True)
            else:
                #  增量转换
                if repos_info["repo_name"] == "update":
                    if repos_info["watch_update"]:
                        command = "submit -m -c translate_job.yaml \
                                 rpm_baseurl={0} repo_name={1} \
                                 translate_strategy=delta".format(baseurl, 
                                                                  channel)
                        subprocess.Popen(command, shell=True, 
                                         text=True, capture_output=True)
            count += 1
            submit_job_count += 1
            sleep(30)
            if count >= 5:
                count = 0
                print("submit job reached the upper limit, \
                      waiting for some time...")
                sleep(7200)
            ds = DataStatistics(submit_job_count)
            ds.statistics()
        return 0
