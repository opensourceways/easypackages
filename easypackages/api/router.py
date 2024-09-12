import json
import random
import time
from typing import Annotated, Union

from fastapi import APIRouter, Cookie, Header
from fastapi.encoders import jsonable_encoder

router = APIRouter(prefix="/v1", tags=["演示接口"])


@router.get("/demo")
async def pathParamReceive2():
    """
    路径参数接收-演示-不带路径参数
    """
    return {
        "msg": "hello",
    }
