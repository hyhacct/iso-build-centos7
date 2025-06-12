# 构建步骤

主要用于构建 `CentOS7` 系统镜像,并内置使用`task`命令行工具,具体学习参考: (https://github.com/lwmacct/250300-task-template)

## 启动构建容器

接下来的构建操作都在容器内进行,因为是 `centos`,这里启动一个 `centos7` 环境的容器,用于构建

```bash
#!/usr/bin/env bash

__main() {
  _name="centos7-libvirt"
  _image1="registry.cn-hangzhou.aliyuncs.com/wangsendi/centos7-libvirt:build-t23110918"
  _image2="i:$(echo "$_image1:$_name" | md5sum | cut -c1-6)"
  docker rmi "$_image2" 2>/dev/null || true
  if [[ "$(docker images "$_image2" | wc -l)" != "2" ]]; then
    docker pull $_image1 && docker tag "$_image1" "$_image2"
  fi
  docker rm -f $_name 2>/dev/null || true
  docker run -itd \
    --name=$_name \
    --hostname=$_name \
    --restart=always \
    --ipc=host \
    --network=host \
    --cgroupns=host \
    --cap-add=SYS_MODULE \
    --privileged=true \
    --security-opt apparmor=unconfined \
    --device /dev/kvm \
    -v /data/:/data \
    -v /lib/modules:/lib/modules:ro \
    -v /run/:/host/run:ro \
    -v /proc/:/host/proc:ro \
    -v /data/docker-data/$_name:/apps/data \
    "$_image2"
}
__main
```

## 目录介绍

先进入容器并创建基础路径,用于构建

```bash
docker exec -it centos7-libvirt bash
mkdir -p /apps/data
cd /apps/data
```

然后把仓库拉下来

```bash
git clone https://github.com/hyhacct/iso-build-centos7.git
```

目录介绍

```txt
.
├── build
│   ├── alter
│   │   └── kickstart
│   │       ├── 00-post.sh
│   │       ├── 01-disk_first.cfg
│   │       ├── 02-disk_smallest.cfg
│   │       ├── cfg-base.sh
│   │       ├── cfg-disk_first.sh
│   │       ├── cfg-disk_smallest.sh
│   │       └── isolinux.cfg              --- 制作自动应答,自动化
│   ├── repo
│   │   └── repo
│   └── script
│       ├── build.sh                      --- 构建脚本,当你准备好了,直接执行他就行了
│       └── temp.sh                       --- 测试脚本,不用管
├── iso                                   --- 用于存放镜像,你需要下载iso到这里
│   └── centos7-images.iso
├── poweriso-x64
├── README.md
├── Taskfile.yml
└── w.code-workspace

7 directories, 15 files
```
