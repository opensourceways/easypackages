import os
import re
import shutil
from datetime import datetime


def remove_logs_dirs(log_dir='.'):
    # 获取当前日期
    current_date = datetime.now()
    max_day = 2
    # print("remove_submit_logs start")
    # 遍历目录下的所有文件
    for filename in os.listdir(log_dir):
        if filename.startswith('submit-log'):  # 确保文件名长度正确
            print(filename)
            try:
                date_match = re.search(r'\d{8}', filename)
                if date_match:
                    date_str = date_match.group(0)
                else:
                    continue
                file_datetime = datetime.strptime(date_str, '%Y%m%d')
            except ValueError:
                print(f'Filename {filename} does not match, skipping.')
                continue

            # 计算文件日期与当前日期的差值
            delta = current_date - file_datetime
            print(delta.days)
            # 如果文件日期超过max_day天，则删除该文件
            if delta.days > max_day:
                file_path = os.path.join(log_dir, filename)
                # print(f'Deleting {filename} older than {max_day} days.')
                try:
                    shutil.rmtree(file_path)
                except Exception as e:
                    # 捕获其他异常
                    print(f"删除 {file_path} 时发生错误: {e}")
                    continue


if __name__ == "__main__":
    remove_submit_logs()
