# How to build dependency images

## Summary

In order to improve the building efficiency of the omnibus image, multiple components within the image are split into separate images and built separately to manage complex components independently.

All component images are pushed to the internal GitLab container registry at `${GITLAB_REGISTRY}`. The CI skip check (`.gitlab/.component.gitlab-ci.yml`) inspects the same registry, so pushing the same tag there is what makes the pipeline skip a rebuild.

```shell
GITLAB_REGISTRY=git-devops.opencsg.com:5050/product/infra/deployment-automation/standard/csghub-omnibus
OS_RELEASE=ubuntu:22.04
OS_TAG=$(basename ${OS_RELEASE} | sed 's/:/_/g')

docker login -u <user> ${GITLAB_REGISTRY}
```

## Build the image

### Runit

```shell
RUNIT_VERSION=2.3.1
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg RUNIT_VERSION=${RUNIT_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-runit:${RUNIT_VERSION}-${OS_TAG} \
  --file dockerfiles/runit/Dockerfile_runit \
  --push .
```

### Minio

```shell
MINIO_VERSION=RELEASE.2025-09-07T16-13-09Z
MC_VERSION=RELEASE.2025-08-13T08-35-41Z
GOLANG_VERSION=1.24.2
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg MINIO_VERSION=${MINIO_VERSION} \
  --build-arg MC_VERSION=${MC_VERSION} \
  --build-arg GOLANG_VERSION=${GOLANG_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-minio:${MINIO_VERSION}-${OS_TAG} \
  --file dockerfiles/minio/Dockerfile_minio \
  --push .
```

### Toolbox

```shell
GOLANG_VERSION=1.26.3
KUBECTL_VERSION=v1.33.0
DNSMASQ_VERSION=2.91
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg GOLANG_VERSION=${GOLANG_VERSION} \
  --build-arg KUBECTL_VERSION=${KUBECTL_VERSION} \
  --build-arg DNSMASQ_VERSION=${DNSMASQ_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-toolbox:1.4.3-${OS_TAG} \
  --file dockerfiles/toolbox/Dockerfile_toolbox \
  --push .
```

### Temporal

```shell
TEMPORAL_VERSION=1.32.0
TEMPORAL_UI_VERSION=2.48.4
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg TEMPORAL_VERSION=${TEMPORAL_VERSION} \
  --build-arg TEMPORAL_UI_VERSION=${TEMPORAL_UI_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-temporal:${TEMPORAL_VERSION}-${OS_TAG} \
  --file dockerfiles/temporal/Dockerfile_temporal \
  --push .
```

### Redis

```shell
REDIS_VERSION=7.4.11
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg REDIS_VERSION=${REDIS_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-redis:${REDIS_VERSION}-${OS_TAG} \
  --file dockerfiles/redis/Dockerfile_redis \
  --push .
```

### PostgreSQL

```shell
POSTGRESQL_VERSION=16.15
SCWS_VERSION=1.2.3
PGVECTOR_VERSION=v0.8.0
TIMESCALEDB_VERSION=2.28.3
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
  --build-arg SCWS_VERSION=${SCWS_VERSION} \
  --build-arg PGVECTOR_VERSION=${PGVECTOR_VERSION} \
  --build-arg TIMESCALEDB_VERSION=${TIMESCALEDB_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-postgresql:${POSTGRESQL_VERSION}-${OS_TAG} \
  --file dockerfiles/postgresql/Dockerfile_postgresql \
  --push .
```

### Patroni

```shell
POSTGRESQL_VERSION=16.15
SCWS_VERSION=1.2.3
PGVECTOR_VERSION=v0.8.0
TIMESCALEDB_VERSION=2.28.3
PYTHON_VERSION=3.11.11
PATRONI_VERSION=4.0.5
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
  --build-arg SCWS_VERSION=${SCWS_VERSION} \
  --build-arg PGVECTOR_VERSION=${PGVECTOR_VERSION} \
  --build-arg TIMESCALEDB_VERSION=${TIMESCALEDB_VERSION} \
  --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
  --build-arg PATRONI_VERSION=${PATRONI_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-patroni:${PATRONI_VERSION}-${OS_TAG} \
  --file dockerfiles/patroni/Dockerfile_patroni \
  --push .
```

### Nginx

```shell
NGINX_VERSION=1.30.4
docker buildx build \
  --provenance false \
  --platform linux/arm64,linux/amd64 \
  --build-arg OS_RELEASE=${OS_RELEASE} \
  --build-arg NGINX_VERSION=${NGINX_VERSION} \
  --tag ${GITLAB_REGISTRY}/omnibus-nginx:${NGINX_VERSION}-${OS_TAG} \
  --file dockerfiles/nginx/Dockerfile_nginx \
  --push .
```
