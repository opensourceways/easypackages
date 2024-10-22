import schedule
import subprocess
import time
import os
import sh

def check_process_running(script_name):
    try:
        result = subprocess.run(['ps', '-ef'], capture_output=True, text=True)
        for line in result.stdout.splitlines():
            if script_name in line:
                return True
        return False
    except Exception as e:
        print(e)
        return False


def run_shell_script():
    task_job_path = os.path.join(os.path.dirname(__file__), 'task_crontab.sh')
    script_name = os.path.basename(task_job_path)
    if not check_process_running(script_name):
        try:
            subprocess.Popen(["sh", task_job_path])
            print("Script executed successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Script failed with error: {e}")
    else:
        print(f"Script {script_name} is still running, skipping this execution.")



schedule.every(5).seconds.do(run_shell_script)  # 每天上午0点执行

while True:
    schedule.run_pending()
    time.sleep(1)