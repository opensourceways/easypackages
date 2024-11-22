import os
import subprocess
import time

import get_update_pypi
import remove_submit_logs
import schedule

# 全局标志位
task_running = False
update_cache = []


def check_process_running():
    global task_running
    return task_running


def clear_update_cache(cache):
    max_len = 10000
    if len(cache) > max_len:
        cache.clear()


def get_update_list(cache):
    update = get_update_pypi.get_top_100_update_packages()
    real_update = []
    for pkg_name in update:
        if pkg_name not in cache:
            real_update.append(pkg_name)
            cache.append(pkg_name)
    return real_update


# 保存文件内容
def get_update_content(cache):
    prefix = "pypi_update"
    save_max_file_num = 10
    output_dir = "update_list"
    # 获取当前时间戳
    timestamp = time.strftime("%Y%m%d%H%M%S")
    # 生成文件名
    filename = f"{prefix}_{timestamp}.txt"

    if not os.path.exists(output_dir):
        # 如果目录不存在，则创建目录
        os.makedirs(output_dir)

    # 保存文件
    content = get_update_list(cache)
    if not content:
        print("no update content.")
        return None
    with open(os.path.join(output_dir, filename), "w") as f:
        f.writelines("%s\n" % item for item in content)
    # 清理旧文件，最多保留10个
    files = sorted(os.listdir(output_dir))
    if len(files) > save_max_file_num:
        for file in files[:-save_max_file_num]:
            os.remove(os.path.join(output_dir, file))

    return output_dir + "/" + filename


def exec_submit_build_job(list_file):
    pypi_name_list = list_file
    aarch_type = "aarch64"
    job_config = "update-pypi.yaml"
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    submit_log_dir = f'submit-log-{time.strftime("%Y%m%d-%H%M%S")}'

    # 构建命令
    command = [
        "sh",
        "-x",
        "submit-repair.sh",
        "-l",
        pypi_name_list,
        "-h",
        aarch_type,
        "-t",
        "vm-2p8g",
        "-p",
        "check_rpm_install=yes",
        "-y",
        job_config,
        "-g",
        submit_log_dir,
    ]

    # 执行命令
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred: {e}")


def run_update_task():
    global task_running
    global update_cache
    task_running = True

    clear_update_cache(update_cache)
    list_file = get_update_content(update_cache)
    if list_file:
        exec_submit_build_job(list_file)

    remove_submit_logs.remove_logs_dirs()

    task_running = False


def main():
    # 从环境变量中获取 API_KEY 和 URL, 并修改 update-pypi.yaml
    # 每10分钟获取增量更新进行构建执行
    schedule.every(30).minutes.do(run_update_task)

    while True:
        if not check_process_running():
            schedule.run_pending()
        time.sleep(3)


if __name__ == "__main__":
    main()
