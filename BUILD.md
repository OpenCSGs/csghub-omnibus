

# How to Build Omnibus-CSGHub Docker Image

## Omnibus CSGHub CE

```shell
cd omnibus-csghub
docker buildx build --provenance false --platform linux/amd64,linux/arm64 \
  -t opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:v1.7.1-ce \
  -f Dockerfile \
  --push .
```

## Omnibus CSGHub EE

```shell
cd omnibus-csghub
docker buildx build --provenance false --platform linux/amd64,linux/arm64 \
  -t opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:v1.7.1-ee \
  -f ee.Dockerfile \
  --push .
```

