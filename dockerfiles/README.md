# How to build dependency images

## Summary

In order to improve the building efficiency of the omnibus image, multiple components within the image are split into separate images and built separately to manage complex components independently.

## Build the image

### Runit

```shell
# Runit-2.1.2
OS_RELEASE=ubuntu:22.04
RUNIT_VERSION=2.1.2
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg RUNIT_VERSION=${RUNIT_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:runit-${RUNIT_VERSION} \
  --tag opencsghq/omnibus-csghub:runit-${RUNIT_VERSION} \
  --file dockerfiles/runit/Dockerfile_runit \
  --push .
```

### Minio

```shell
## Minio
MINIO_VERSION=RELEASE.2025-03-12T18-04-18Z
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg MINIO_VERSION=${MINIO_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:minio-${MINIO_VERSION} \
  --tag opencsghq/omnibus-csghub:minio-${MINIO_VERSION} \
  --file dockerfiles/minio/Dockerfile_minio \
  --push .
```

### Toolbox

```shell
## Toolbox
OS_RELEASE=ubuntu:22.04
TOOLBOX_VERSION=1.2.8
GOMPLATE_VERSION=v4.3.2
KUBECTL_VERSION=v1.33.0
DNSMASQ_VERSION=2.91
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg GOMPLATE_VERSION=${GOMPLATE_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:toolbox-${TOOLBOX_VERSION} \
  --tag opencsghq/omnibus-csghub:toolbox-${TOOLBOX_VERSION} \
  --file dockerfiles/toolbox/Dockerfile_toolbox \
  --push .
```

### Temporal

```shell
## temporal
OS_RELEASE=ubuntu:22.04
TEMPORAL_VERSION=1.25.2
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg TEMPORAL_VERSION=${TEMPORAL_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:temporal-${TEMPORAL_VERSION} \
  --tag opencsghq/omnibus-csghub:temporal-${TEMPORAL_VERSION} \
  --file dockerfiles/temporal/Dockerfile_temporal \
  --push .
```

### Redis

```shell
## Redis
OS_RELEASE=ubuntu:22.04
REDIS_VERSION=6.2.14
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg REDIS_VERSION=${REDIS_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:redis-${REDIS_VERSION} \
  --tag opencsghq/omnibus-csghub:redis-${REDIS_VERSION} \
  --file dockerfiles/redis/Dockerfile_redis \
  --push .
```

### PostgreSQL

```shell
## PostgreSQL
OS_RELEASE=ubuntu:22.04
POSTGRESQL_VERSION=16.8
SCWS_VERSION=1.2.3
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
  --build-arg SCWS_VERSION=${SCWS_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:postgresql-${POSTGRESQL_VERSION} \
  --tag opencsghq/omnibus-csghub:postgresql-${POSTGRESQL_VERSION} \
  --file dockerfiles/postgresql/Dockerfile_postgresql \
  --push .
```

### Patroni

```shell
## Patroni
OS_RELEASE=ubuntu:22.04
POSTGRESQL_VERSION=16.8
SCWS_VERSION=1.2.3
PYTHON_VERSION=3.11.11
PATRONI_VERSION=4.0.5
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
  --build-arg SCWS_VERSION=${SCWS_VERSION} \
  --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
  --build-arg PATRONI_VERSION=${PATRONI_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:patroni-${PATRONI_VERSION} \
  --tag opencsghq/omnibus-csghub:patroni-${PATRONI_VERSION} \
  --file dockerfiles/patroni/Dockerfile_patroni \
  --push .
```

### Nginx

```shell
## Nginx
OS_RELEASE=ubuntu:22.04
NGINX_VERSION=1.22.1
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg NGINX_VERSION=${NGINX_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsghq/omnibus-csghub:nginx-${NGINX_VERSION} \
  --tag opencsghq/omnibus-csghub:nginx-${NGINX_VERSION} \
  --file dockerfiles/nginx/Dockerfile_nginx \
  --push .
```

