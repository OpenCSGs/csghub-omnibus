FROM debian:bookworm-slim AS Downloader
WORKDIR /
RUN apt update && apt install -y wget golang

# Download gitaly
ARG GITALY_VERSION=v17.7.6
RUN wget http://gitlab-ubi.s3.amazonaws.com/ubi-build-dependencies-${GITALY_VERSION}-ubi/gitaly.tar.gz && \
    tar -zxf gitaly.tar.gz \

# Download Minio
RUN mkdir -p /minio/bin /logger/bin
## Download minio server
RUN wget -O /minio/bin/minio https://dl.min.io/server/minio/release/linux-amd64/minio && \
    chmod -R +x /minio/bin/minio
## Download minio client
RUN wget -O /minio/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod -R +x /minio/bin/mc
## Compile minio webhook logger
RUN git clone https://git-devops.opencsg.com/product/infra/minio/webhook.git && \
    cd webhook && go build -o /logger/bin/logger main.go

# Download Consul
ARG CONSUL_VERSION=1.20.5
RUN wget -O consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    unzip consul.zip -d /consul

FROM ubuntu:22.04 AS Builder
WORKDIR /

# Install the compilation environment
RUN apt update && \
    apt install -y \
      gcc  \
      libicu-dev \
      build-essential \
      libreadline-dev \
      zlib1g-dev \
      pkg-config \
      flex \
      bison \
      make \
      postgresql-common && \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

# Compile postgresql
RUN wget -O postgresql-16.8.tar.gz https://ftp.postgresql.org/pub/source/v16.8/postgresql-16.8.tar.gz && \
    tar -zxf postgresql-16.8.tar.gz && cd postgresql-16.8 && \
    ./configure --prefix=/opt/csghub/embedded/sv/postgresql \
    --with-openssl \
    --with-icu \
    --with-readline && \
    make world -j$(nproc) && make install-world -j$(nproc) \

# Compile zhparser
ENV PGHOME=/opt/csghub/embedded/sv/postgresql \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PGHOME/lib \
    PATH=$PGHOME/bin:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin:$PATH

RUN apt install -y \
      build-essential \
      llvm-16 \
      clang \
      bzip2 \
      wget \
      ca-certificates \
      postgresql-server-dev-16 \

RUN wget -O scws-1.2.3.tar.bz2 http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2 && \
    tar -xjf scws-1.2.3.tar.bz2 && cd /scws-1.2.3 && \
    ./configure --prefix=/opt/csghub/embedded && make install

ENV SCWS_HOME=/opt/csghub/embedded
RUN git clone https://github.com/amutu/zhparser.git && \
    cd /zhparser && make && make install

# Compile Python
RUN apt install -y \
      build-essential \
      zlib1g-dev \
      libncurses5-dev \
      libgdbm-dev \
      libnss3-dev \
      libssl-dev \
      libreadline-dev  \
      libffi-dev \
      libsqlite3-dev \
      libbz2-dev \

RUN wget -O Python-3.13.2.tgz https://www.python.org/ftp/python/3.13.2/Python-3.13.2.tgz && \
    tar -zxf Python-3.13.2.tgz && cd Python-3.13.2 && \
    ./configure --prefix=/opt/csghub/embedded/python \
      --enable-optimizations \
      --enable-shared \
      --with-ensurepip=install && \
    make -j$(nproc) && make altinstall

FROM ubuntu:22.04
WORKDIR /

# --no-install-recommends

# Using bash SHELL default
SHELL ["/bin/bash", "-c"]

# Create the Directory Structure
RUN mkdir -p /opt/csghub/{bin,embedded/{bin,lib,sv},etc,LICENSES}

# Install Gitaly & Praefect
COPY --from=Downloader /gitaly/usr/local /opt/csghub/embedded/sv/gitaly
COPY --from=Downloader /gitaly/licenses/GitLab.txt /opt/csghub/LICENSES/GitLab-LICENSE
## Install Gitaly
COPY ./opt/csghub/etc/gitaly /opt/csghub/etc/gitaly
COPY ./opt/csghub/embedded/sv/gitaly /opt/csghub/embedded/sv/gitaly
## Install Praefect
COPY ./opt/csghub/etc/praefect /opt/csghub/etc/praefect
COPY ./opt/csghub/embedded/sv/praefect /opt/csghub/embedded/sv/praefect

# Install Minio
COPY --from=Downloader /minio /opt/csghub/embedded/sv/minio
COPY ./opt/csghub/embedded/sv/minio /opt/csghub/embedded/sv/minio

# Install Minio Logger Webhook
COPY --from=Downloader /logger /opt/csghub/embedded/sv/logger
COPY ./opt/csghub/embedded/sv/logger /opt/csghub/embedded/sv/logger

# Install Consul
COPY --from=Downloader /consul /opt/csghub/embedded/sv/consul
COPY --from=Downloader /consul/LICENSE.txt /opt/csghub/LICENSES/consul-LICENSE
COPY ./opt/csghub/etc/consul /opt/csghub/etc/consul
COPY ./opt/csghub/embedded/sv/consul /opt/csghub/embedded/sv/consul

# Install PostgreSQL
COPY --from=Builder /opt/csghub/embedded/sv/postgresql /opt/csghub/embedded/sv/postgresql
COPY --from=Builder /opt/csghub/embedded/scws /opt/csghub/embedded/scws
COPY ./opt/csghub/etc/postgresql /opt/csghub/etc/postgresql
COPY ./opt/csghub/embedded/sv/postgresql /opt/csghub/embedded/sv/postgresql

# Install Python3
COPY --from=Builder /opt/csghub/embedded/python /opt/csghub/embedded/python
RUN ln -sf /opt/csghub/embedded/python/bin/* /opt/csghub/embedded/bin/
ENV PYTHONHOME=/opt/csghub/embedded/python \
    PYTHONPATH=/opt/csghub/embedded/sv:$PYTHONPATH \
    PGHOME=/opt/csghub/embedded/sv/postgresql \
    PATH=$PYTHONHOME/bin:$PGHOME/bin:$PATH \
    LD_LIBRARY_PATH=$PYTHONHOME/lib:$PGHOME/lib:$LD_LIBRARY_PATH

# Install Patroni
RUN python3.13 -m pip install \
      --no-cache-dir \
      --prefix=/opt/csghub/embedded/sv/patroni patroni[consul] psycopg2-binary \

COPY ./opt/csghub/etc/patroni /opt/csghub/etc/patroni


