# -*- encoding:UTF-8 -*-

import os
import schedule
import subprocess
import time


def is_porcess_alive(script_name):
    """检查进程是否存活"""
    try:
        result = subprocess.run(["ps", "-ef"], capture_output=True, text=True)
        return script_name in result.stdout
    except Exception as e:
        print(e)
        return False


def run():
    """程序入口"""
    print("execute start")
    task_job = os.path.join(os.path.dirname(__file__), "schedule_repos.py")
    script_name = os.path.basename(task_job)
    if not is_porcess_alive(script_name):
        try:
            subprocess.Popen(["python3", task_job])
            print("Script executed successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Script failed with error: {e}")


# 每天凌晨两点执行任务
schedule.every(5).seconds.do(run)

while True:
    schedule.run_pending()
    time.sleep(1)  # 等待1s，避免CPU占用过高
