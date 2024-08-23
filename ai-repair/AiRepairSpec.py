from specrepair import SpecBot
import sys
import os
import shutil

# 参数说明：specFile
#   specFilePath：.spec源文件路径，必输
#   logFilePath：日志文件路径，必输
#   repairSpecFIlePath: .spec文件修复后的路径，必输
#   suggestionPath：ai建议保存路径，必输

# 设置环境变量
os.environ['OPENAI_API_KEY'] = 'xxxxxxx'
os.environ['OPENAI_BASE_URL'] = 'xxxxx'

print("Ai repair spec begin ...")

if len(sys.argv) != 5 :
    print('error argumengs num [{}]'.format(len(sys.argv)))
    for i in sys.argv:
        print (i)
    sys.exit(1)

if not sys.argv[1].endswith(".spec"):
    print("error: spec src file not end with .spec[{}]".format(sys.argv[1]))
    sys.exit(1)

specFile = sys.argv[1]
specFileName = os.path.basename(specFile)
specFilePath = os.path.dirname(specFile)

# 源：spec脚本文件
spec_src_file = sys.argv[1]
spec_src_path = os.path.dirname(spec_src_file)

# 源：报错日志文件
log_src_file = sys.argv[2]
log_src_path = os.path.dirname(log_src_file)

# 修改后的spec脚本保存地址
spec_repair_file = sys.argv[3]
spec_repair_path = os.path.dirname(spec_repair_file)
 
# 修改建议
suggestion_file = sys.argv[4]
suggestion_path = os.path.dirname(suggestion_file)
 

arr_path = [spec_src_path, spec_repair_path, log_src_path, suggestion_path]
for path in arr_path:
    if not os.path.exists(path):
        os.makedirs(path)

specbot = SpecBot()
suggestion, flag = specbot.repair(spec_src_file, log_src_file, spec_repair_file)
 
# 打开文件用于写入，如果文件不存在则创建
with open(suggestion_file, 'w') as file:
    # 将字符串写入文件
    file.write(suggestion)

print("AiRepairSpecResult:[{}]".format(flag))
