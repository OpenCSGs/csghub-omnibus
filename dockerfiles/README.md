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
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:runit-${RUNIT_VERSION} \
  --file dockerfiles/Dockerfile_runit \
  --push .
```

### Minio

```shell
## Minio
MINIO_VERSION=RELEASE.2025-03-12T18-04-18Z
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg MINIO_VERSION=${MINIO_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:minio-${MINIO_VERSION} \
  --file dockerfiles/Dockerfile_minio \
  --push .
```

### Toolbox

```shell
## Toolbox
OS_RELEASE=ubuntu:22.04
TOOLBOX_VERSION=1.2.1
GOMPLATE_VERSION=v4.3.2
KUBECTL_VERSION=v1.33.0
DNSMASQ_VERSION=2.91
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg GOMPLATE_VERSION=${GOMPLATE_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:toolbox-${TOOLBOX_VERSION} \
  --file dockerfiles/Dockerfile_toolbox \
  --push .
```

### Temporal

```shell
## temporal
OS_RELEASE=ubuntu:22.04
TEMPORAL_VERSION=1.25.1
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg TEMPORAL_VERSION=${TEMPORAL_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:temporal-${TEMPORAL_VERSION} \
  --file dockerfiles/Dockerfile_temporal \
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
  --build-arg REDIS_VERSION=${REDIS_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:redis-${REDIS_VERSION} \
  --file dockerfiles/Dockerfile_redis \
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
  --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
  --build-arg SCWS_VERSION=${SCWS_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:postgresql-${POSTGRESQL_VERSION} \
  --file dockerfiles/Dockerfile_postgresql \
  --push .
```

### Patroni

```shell
## Patroni
OS_RELEASE=ubuntu:22.04
POSTGRESQL_VERSION=16.8
SCWS_VERSION=1.2.3
PYTHON_VERSION=3.13.3
PATRONI_VERSION=4.0.5
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
  --build-arg SCWS_VERSION=${SCWS_VERSION} \
  --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
  --build-arg PATRONI_VERSION=${PATRONI_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:patroni-${PATRONI_VERSION} \
  --file dockerfiles/Dockerfile_patroni \
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
  --build-arg NGINX_VERSION=${NGINX_VERSION} \
  --tag opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:nginx-${NGINX_VERSION} \
  --file dockerfiles/Dockerfile_nginx \
  --push .

```

