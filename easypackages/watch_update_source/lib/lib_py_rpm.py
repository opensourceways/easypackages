import os
import xml.etree.ElementTree as ET

def get_src_rpm_list_by_primary_xml(xml_file: str, repo_base: str): 
    rpm_arr = []
    # 检查元数据文件
    if os.path.exists(xml_file):
        if not os.path.isfile(xml_file):
            print(f"[error] primary xml file is not file: {xml_file}")
            return None
    else:
        print(f"[error] primary xml file is not exist: {xml_file}")
        return None

    if not xml_file.endswith('-primary.xml') :
        print(f"[error] list file is not endswith -primary.xml: {xml_file}")
        return None
    
    # 解下xmL文件
    tree = ET.parse(xml_file)
    root = tree.getroot()
    for package in root.findall('{http://linux.duke.edu/metadata/common}package'):
         # 处理xml文件中单个package
        name = package.find('{http://linux.duke.edu/metadata/common}name').text.strip()
        version = package.find('{http://linux.duke.edu/metadata/common}version').get('ver').strip()
        location_href = package.find('{http://linux.duke.edu/metadata/common}location').get('href').strip()

        repo_addr = repo_base + '/' + location_href
        record_tmp = repo_addr + ' ' + name + ' ' + version
        if record_tmp not in rpm_arr:
            rpm_arr.append(record_tmp)
    return rpm_arr


def get_rpm_binary_List_by_primary_xml(xml_path: str, arch_type: str): 
    rpm_arr = []

    # 检查元数据文件
    if os.path.exists(xml_path):
        if not os.path.isdir(xml_path):
            print(f"[error] xml dir path is not dir: {xml_path}")
            return None
    else:
        print(f"[error] xml dir path is not exist: {xml_path}")
        return None
    
    for file_name in os.listdir(xml_path):
        if not file_name.endswith('-primary.xml') :
            continue
        
        # 解下xmL文件
        file_path = os.path.join(xml_path, file_name)
        tree = ET.parse(file_path)
        root = tree.getroot()
        for package in root.findall('{http://linux.duke.edu/metadata/common}package'):
             # 处理xml文件中单个package
            name = package.find('{http://linux.duke.edu/metadata/common}name').text.strip()
            version = package.find('{http://linux.duke.edu/metadata/common}version').get('ver').strip()
            arch = package.find('{http://linux.duke.edu/metadata/common}arch').text.strip()

            if arch in [arch_type, 'noarch']:
                record_tmp = name + ' ' + version + ' ' + arch
                if record_tmp not in rpm_arr:
                    rpm_arr.append(record_tmp)
    return rpm_arr