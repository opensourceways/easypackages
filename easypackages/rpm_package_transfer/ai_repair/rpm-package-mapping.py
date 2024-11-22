import argparse
import difflib

import Levenshtein  # type: ignore


# 通过difflib.SequenceMatcher计算相似度
def similarity(str1, str2):
    matcher = difflib.SequenceMatcher(None, str1, str2)
    return matcher.ratio()


# 通过python-Levenshtein库的计算相似度
def similarity_levenshtein(str1, str2):
    edit_distance = distance(str1, str2)  # type: ignore
    max_len = max(len(str1), len(str2))
    return 1 - edit_distance / max_len


def range_validator(min_value, max_value):
    def validator(value):
        fvalue = float(value)
        if not min_value <= fvalue <= max_value:
            raise argparse.ArgumentTypeError(
                f"值必须在 {min_value} 和 {max_value} 之间"
            )
        return fvalue

    return validator


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        usage="""
                包名映射
           """
    )
    parser.add_argument("-s", type=str, required=True, help="源包名")
    parser.add_argument(
        "-d",
        type=str,
        required=True,
        help='待匹配的包名字符串，例如："389-ds-base 389-ds-base-devel"',
    )
    parser.add_argument(
        "-b",
        type=range_validator(0, 1),
        required=True,
        help="最低相似度(浮点数值，范围：0~1），例如: 0.7",
    )

    args = parser.parse_args()
    print(args.__dict__)
    src_str = str(args.s)
    des_str = str(args.d)
    similar_num_min = args.b

    # 拆分待匹配字符串
    des_strs = [str.strip() for str in des_str.split()]

    res_str_similar = {}
    for str in des_strs:
        similar_num = similarity(src_str, str)
        if similar_num >= similar_num_min:
            res_str_similar[str] = similar_num

    res_str_similar_sort = dict(
        sorted(res_str_similar.items(), key=lambda item: item[1], reverse=True)
    )
    res_str_arr = [key for key in res_str_similar_sort]
    print("result[" + " ".join(res_str_arr) + "]")
    print(f"SIMILARITY-MATCH:[SUCCESS]-[{res_str_arr[0]}]")
