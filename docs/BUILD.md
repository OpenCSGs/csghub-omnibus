# How to Build Omnibus-CSGHub Docker Image

## Omnibus CSGHub CE

```shell
cd omnibus-csghub
docker buildx build --provenance false --platform linux/amd64,linux/arm64 \
  -t opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:v1.7.1-ce \
  -t opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:latest \
  -f Dockerfile \
  --push .
```

## Omnibus CSGHub EE

```shell
cd omnibus-csghub
docker buildx build --provenance false --platform linux/amd64,linux/arm64 \
  -t opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:v1.7.1-ee \
  -t opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/omnibus-csghub:latest \
  -f ee.Dockerfile \
  --push .
```

## Omnibus Components 

Most images are go programs, which do not rely much on the operating environment. However, for postgresql, redis, runit, nginx and other components, they rely on the system dynamic link library environment, so they need to be built for different operating systems and kernel versions.

Because they are all Docker builds, please make sure that the kernel version of the Docker host running the runner is the expected version.

### How to build single component image

**Prerequisites：**

- `dockerfiles/{{component}}/version-manifests.json` changed.

     In short, the component version has changed.

#### Trigger Pipeline

There are two situations here：

1. Only build component under the default `OS_RELEASE`=`ubuntu:22.04`

    You can update current component's `dockerfiles/{{component}}/version-manifests.json` to trigger pipeline.

2. build component with non-default `OS_RELEASE`

    Only git command line can be used.

    example:

    1. update `dockerfiles/{{component}}/version-manifests.json`
    2. commit changes with `git commit`
    3. commit push with option `git push -o ci.variable="OS_RELEASE=hxsoong/kylin:v10-sp1"`

### How to build all components image

Only trigger pipeline manual can build all components. When trigger pipeline, you should specify environment `OS_RELEASE`, it shouldn't with registry prefix.

example：

![image-20250612122940476](./assets/image-20250612122940476.png)

This will pull image from `opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public/hxsoong/kylin:v10-sp1`.



_Notes: All images will pulled from `opencsg-registry.cn-beijing.cr.aliyuncs.com/opencsg_public`, you can overwrite by set `REGISTRY=<new registry>`. If you are not sure how to transfer multiple images, please upload your image to the default image address directly._

## How to Build KyLin V10 Docker Image

### 1. Download KyLin ISO

[Kylin-Server-V10-SP3-2403-Release-20240426-x86_64.iso](https://iso.kylinos.cn/web_pungi/download/cdn/9D2GPNhvxfsF3BpmRbJjlKu0dowkAc4i/Kylin-Server-V10-SP3-2403-Release-20240426-x86_64.iso)

### 2. Install Necessary Tools

```shell
sudo apt-get install debootstrap squashfs-tools
```

### 2. Extract the file system from the ISO

*Mount the ISO first.*

```shell
# Mount ISO as local filesystem
mkdir /mnt/kylin-server-v10 && mount -o loop /dev/cdrom /mnt/kylin-server-v10

# Find and mount install.img
find /mnt/kylin-server-v10 -name install.img

# Mount install.img
mkdir /install && mount -o loop /mnt/kylin-server-v10/images/install.img /install
mkdir /rootfs && mount -o loop /install/LiveOS/rootfs.img /rootfs

sudo tar -C /rootfs -c . | docker import \
	--change 'ENTRYPOINT ["/usr/lib/systemd/systemd"]' \
	--change 'CMD ["/bin/bash"]' \
	- kylinsoft/kylin_v10:2403
```

