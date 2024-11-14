from openeuler:22.03-LTS as BUILDER

WORKDIR /root

RUN sed -i "s|repo.openeuler.org|mirrors.nju.edu.cn/openeuler|g" /etc/yum.repos.d/openEuler.repo \
    && sed -i '/metalink/d' /etc/yum.repos.d/openEuler.repo \
    && sed -i '/metadata_expire/d' /etc/yum.repos.d/openEuler.repo

ENV CCI_SRC=/root/compass-ci
ENV LKP_SRC=/root/lkp-tests
ENV PATH $PATH:$LKP_SRC/sbin:$LKP_SRC/bin
ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/

RUN yum install -y git ruby rubygems make gcc diffutils util-linux lftp hostname sudo gzip git ruby-devel rubygem-json rubygem-bundler gcc-c++ ruby-devel rubygem-rake rpm-build python3-pip wget \
    && gem install rest-client \
    && git clone https://gitee.com/compass-ci/lkp-tests.git \
    && git clone https://ghp.ci/https://github.com/opensourceways/easypackages.git \
    && pip install schedule \
    && pip install requests

RUN sed -i 's|api_key: .*|api_key: xxxx（填写自己的ai模型key）|' /root/easypackages/easypackages/pypi/watch_update_source/src/update-pypi.yaml \
    && sed -i 's|base_url: .*|base_url: xxxx（填写自己的ai模型url）|' /root/easypackages/easypackages/pypi/watch_update_source/src/update-pypi.yaml \
    && sed -i 's|ai_model: .*|ai_model: xxxx（填写自己的ai模型）|' /root/easypackages/easypackages/pypi/watch_update_source/src/update-pypi.yaml

WORKDIR /root/easypackages/easypackages/pypi/watch_update_source/src

CMD python3 schedule_main.py
