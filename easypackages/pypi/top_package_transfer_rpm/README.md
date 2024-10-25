# 批量提交pipy任务

eg: sh submit-repair.sh -l project_names_10w.txt -h aarch64 -t vm-2p8g -y job-pipy.yaml -g
/home/fuxinjji/pipy_job_result/submit-log-$(date +"%Y%m%d-%H%M%S")

输出：在指定的目录生成的日志文件中生成日志文件（/home/fuxinjji/pipy_job_result/submit-log-$(date +"%Y%m%d-%H%M%S")）
submit-log ： 提交的job的日志记录
submit-succ-list ：提交job成功列表
submit-fail-list ：提交失败job列表
result_root_list ：提交成功的job结果路径（便于后续执行日志分析脚本，分析执行结果）