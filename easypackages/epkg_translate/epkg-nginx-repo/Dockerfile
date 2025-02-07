# SPDX-License-Identifier: MulanPSL-2.0+
# Copyright (c) 2020 Huawei Technologies Co., Ltd. All rights reserved.

FROM nginx:1.20.0-alpine

COPY root /

RUN sed -ri.origin 's|^https?://dl-cdn.alpinelinux.org|http://mirrors.huaweicloud.com|g' /etc/apk/repositories

RUN chmod -R 755 /usr/share/nginx/html

ENV RUN_USER nginx
ENV RUN_GROUP nginx

ENTRYPOINT ["/sbin/entrypoint.sh"]
