ARG REGISTRY=docker.io
ARG GITLAB_REGISTRY=git-devops.opencsg.com:5050/product/infra/deployment-automation/standard/omnibus
ARG OS_RELEASE=ubuntu:22.04
ARG OS_TAG=ubuntu_22.04

ARG CSGHUB_VERSION=v1.8.0-ce
ARG RUNIT_VERSION=2.1.2
ARG TOOLBOX_VERSION=1.2.4
ARG CONSUL_VERSION=1.20.5
ARG MINIO_VERSION=RELEASE.2025-03-12T18-04-18Z
ARG POSTGRESQL_VERSION=16.8
ARG REDIS_VERSION=6.2.14
ARG REGISTRY_VERSION=2.8.3
ARG GITALY_VERSION=v17.5.0
ARG GITLAB_SHELL_VERSION=v17.5.0
ARG TEMPORAL_VERSION=1.25.1
ARG NATS_VERSION=2.10.16
ARG CASDOOR_VERSION=v1.799.0
ARG DNSMASQ_VERSION=2.91
ARG NGINX_VERSION=1.27.5

## Install Runit Service Daemon
FROM ${GITLAB_REGISTRY}/omnibus-runit:${RUNIT_VERSION}-${OS_TAG} AS runit

## Install csghub-ctl, gomplate, htpasswd, ssh host key pairs
FROM ${GITLAB_REGISTRY}/omnibus-toolbox:${TOOLBOX_VERSION}-${OS_TAG} AS toolbox

## Install Consul
FROM ${REGISTRY}/hashicorp/consul:${CONSUL_VERSION} AS consul

## Install Minio
FROM ${GITLAB_REGISTRY}/omnibus-minio:${MINIO_VERSION}-${OS_TAG} AS minio

## Install PostgreSQL
FROM ${GITLAB_REGISTRY}/omnibus-postgresql:${POSTGRESQL_VERSION}-${OS_TAG} AS postgresql

## Install Redis
FROM ${GITLAB_REGISTRY}/omnibus-redis:${REDIS_VERSION}-${OS_TAG} AS redis

## Install Registry
FROM ${REGISTRY}/registry:${REGISTRY_VERSION} AS registry

## Install Gitaly
FROM ${REGISTRY}/gitlab-org/build/cng/gitaly:${GITALY_VERSION} AS gitaly

## Install Gitlab-Shell
FROM ${REGISTRY}/gitlab-org/build/cng/gitlab-shell:${GITLAB_SHELL_VERSION} AS gitlab-shell

## Install Temporal
FROM ${GITLAB_REGISTRY}/omnibus-temporal:${TEMPORAL_VERSION}-${OS_TAG} AS temporal

## Install NATS
FROM ${REGISTRY}/nats:${NATS_VERSION} AS nats

## Install Casdoor
FROM ${REGISTRY}/casbin/casdoor:${CASDOOR_VERSION} AS casdoor

## Install Nginx
FROM ${GITLAB_REGISTRY}/omnibus-nginx:${NGINX_VERSION}-${OS_TAG} AS nginx

## Install csghub-server
FROM ${REGISTRY}/csghub-server:${CSGHUB_VERSION} AS server

## Install csghub-portal
FROM ${REGISTRY}/csghub-portal:${CSGHUB_VERSION} AS portal

FROM ${REGISTRY}/${OS_RELEASE}
WORKDIR /

LABEL org.opencontainers.image.licenses="Apache-2.0, AGPL-3.0, GPL-2.0-only" \
      org.opencontainers.image.minio.source="https://github.com/minio/minio/tree/RELEASE.2025-03-12T18-04-18Z" \
      org.opencontainers.image.dnsmasq.source="http://thekelleys.org.uk/dnsmasq/dnsmasq-2.91.tar.gz"

COPY ./NOTICE /NOTICE
COPY ./opt/. /opt/
COPY ./scripts/. /scripts/

ENV CSGHUB_HOME=/opt/csghub
ENV CSGHUB_EMBEDDED=${CSGHUB_HOME}/embedded
ENV CSGHUB_SRV_HOME=${CSGHUB_EMBEDDED}/sv

SHELL ["/bin/bash", "-c"]

RUN mkdir -p \
      ${CSGHUB_HOME}/{LICENSES,bin} \
      ${CSGHUB_EMBEDDED}/{bin,lib,sv} \
      ${CSGHUB_SRV_HOME}/{registry,nats,temporal,temporal_ui,casdoor,dnsmasq,consul,server,portal}/bin

## Install Runit Service Daemon
COPY --from=runit ${CSGHUB_EMBEDDED}/bin/. ${CSGHUB_EMBEDDED}/bin/

## Install csghub-ctl, gomplate, htpasswd, ssh host key pairs
COPY --from=toolbox /etc/ssh/ssh_host_* /etc/ssh/
COPY --from=toolbox ${CSGHUB_HOME}/bin/. ${CSGHUB_HOME}/bin/
COPY --from=toolbox ${CSGHUB_EMBEDDED}/bin/. ${CSGHUB_EMBEDDED}/bin/
COPY --from=toolbox ${CSGHUB_SRV_HOME}/dnsmasq/. ${CSGHUB_SRV_HOME}/dnsmasq/

## Install Consul
COPY --from=consul /bin/consul ${CSGHUB_SRV_HOME}/consul/bin/
COPY --from=consul /usr/share/doc/consul/LICENSE.txt ${CSGHUB_HOME}/LICENSES/Consul-LICENSE

## Install Minio
COPY --from=minio ${CSGHUB_SRV_HOME}/minio/bin/. ${CSGHUB_SRV_HOME}/minio/bin/
COPY --from=minio ${CSGHUB_SRV_HOME}/logger/bin/. ${CSGHUB_SRV_HOME}/logger/bin/

## Installer PostgreSQL (or Patroni Python)
COPY --from=postgresql ${CSGHUB_EMBEDDED}/. ${CSGHUB_EMBEDDED}/

## Install Redis
COPY --from=redis ${CSGHUB_SRV_HOME}/redis/bin/. ${CSGHUB_SRV_HOME}/redis/bin/

## Install Registry
COPY --from=registry /bin/registry ${CSGHUB_SRV_HOME}/registry/bin/
COPY --from=registry /bin/busybox ${CSGHUB_SRV_HOME}/registry/bin/

## Install Gitaly
COPY --from=gitaly /usr/local/. ${CSGHUB_SRV_HOME}/gitaly/

## Install Gitlab-Shell
COPY --from=gitlab-shell /srv/gitlab-shell/. ${CSGHUB_SRV_HOME}/gitlab_shell/

## Install Temporal & Temporal-ui
COPY --from=temporal ${CSGHUB_HOME}/etc/temporal/. ${CSGHUB_HOME}/etc/temporal/
COPY --from=temporal ${CSGHUB_SRV_HOME}/temporal/. ${CSGHUB_SRV_HOME}/temporal/
COPY --from=temporal ${CSGHUB_HOME}/etc/temporal_ui/. ${CSGHUB_HOME}/etc/temporal_ui/
COPY --from=temporal ${CSGHUB_SRV_HOME}/temporal_ui/. ${CSGHUB_SRV_HOME}/temporal_ui/

# Using 8182 as temporal-ui default listen port
RUN sed -i 's/8080/8182/g' ${CSGHUB_HOME}/etc/temporal_ui/config-template.yaml

## Install NATS
COPY --from=nats /nats-server ${CSGHUB_SRV_HOME}/nats/bin/

## Install Casdoor
COPY --from=casdoor /server ${CSGHUB_SRV_HOME}/casdoor/bin/casdoor
COPY --from=casdoor /web ${CSGHUB_HOME}/etc/casdoor/web

## Install Nginx
COPY --from=nginx /opt/csghub/. /opt/csghub/
COPY ./opt/csghub/etc/nginx/. /opt/csghub/etc/nginx/

## Install csghub-server
ENV GIN_MODE=release

COPY --from=server /starhub-bin/starhub ${CSGHUB_SRV_HOME}/server/bin/csghub-server
COPY --from=server /starhub-bin/. ${CSGHUB_HOME}/etc/server/
COPY --from=server /root/.duckdb ${CSGHUB_SRV_HOME}/server/.duckdb

RUN rm ${CSGHUB_HOME}/etc/server/starhub

## Install csghub-portal
COPY --from=portal /myapp/csghub-portal ${CSGHUB_SRV_HOME}/server/bin/

ENV PATH=$PATH:/opt/csghub/embedded/bin
RUN if grep -q -i -E 'ubuntu|debian' /etc/os-release; then \
        apt update && \
        UBUNTU_VERSION=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release) && \
        if dpkg --compare-versions "$UBUNTU_VERSION" ge "24.04"; then \
            # Ubuntu 24.04+ (新包名带 t64 后缀)
            apt install -y --no-install-recommends \
                ca-certificates \
                libicu74 \
                libreadline8t64 \
                netcat-openbsd \
                libaprutil1t64 \
                libgeoip1t64 \
                libgd3 \
                libxml2 \
                libxslt1.1 \
                libcurl4t64 \
                libpq-dev \
                vim lsof; \
        else \
            # Ubuntu 22.04 or older (旧包名)
            apt install -y --no-install-recommends \
                ca-certificates \
                libicu70 \
                libreadline8 \
                netcat-openbsd \
                libaprutil1 \
                libgeoip1 \
                libgd3 \
                libxml2 \
                libxslt1.1 \
                libcurl3-gnutls \
                libpq-dev \
                vim lsof; \
        fi && \
        apt clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*; \
    else \
        # CentOS/RHEL 部分
        if command -v dnf >/dev/null; then \
            # CentOS/RHEL 8/9 (dnf)
            CENTOS_VERSION=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release) && \
            if [ "${CENTOS_VERSION%%.*}" -ge 9 ]; then \
                # CentOS 9+ (libmaxminddb 替代 GeoIP)
                dnf install -y \
                    ca-certificates \
                    icu \
                    readline \
                    nmap-ncat \
                    apr-util \
                    libmaxminddb \
                    gd \
                    libxml2 \
                    libxslt \
                    libcurl \
                    postgresql-devel \
                    vim lsof; \
            else \
                # CentOS 8 (GeoIP)
                dnf install -y \
                    ca-certificates \
                    icu \
                    readline \
                    nmap-ncat \
                    apr-util \
                    GeoIP \
                    gd \
                    libxml2 \
                    libxslt \
                    libcurl \
                    postgresql-devel \
                    vim lsof; \
            fi && \
            dnf clean all; \
        else \
            # CentOS 7 (yum)
            yum install -y \
                ca-certificates \
                libicu \
                readline \
                nmap-ncat \
                apr-util \
                GeoIP \
                gd \
                libxml2 \
                libxslt \
                libcurl \
                postgresql-devel \
                vim lsof && \
            yum clean all; \
        fi; \
        rm -rf /var/cache/yum /tmp/* /var/tmp/* /var/log/*; \
    fi

RUN chmod +x -R /opt/csghub/bin && \
    chmod +x -R /opt/csghub/embedded/bin && \
    chmod +x -R /opt/csghub/embedded/sv/**/bin && \
    chmod +x -R /opt/csghub/embedded/sv/**/templates && \
    chmod +x -R /scripts && \
    ln -s /opt/csghub/bin/* /usr/bin/ && \
    find /opt/csghub/etc/ -type f -name "*.sh" -exec chmod +x {} \;

EXPOSE 80 443 2222 5000 8000 9000 9001
ENTRYPOINT ["/scripts/entrypoint.sh"]