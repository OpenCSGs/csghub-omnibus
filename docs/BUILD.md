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

