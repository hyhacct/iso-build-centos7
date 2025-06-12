# centos7

```bash
    __main() {

        {
            # 镜像准备
            _name=centos7-libvirt
            _image1="registry.cn-hangzhou.aliyuncs.com/wangsendi/centos7-libvirt:build-t23110918"
            _image2="i:$(echo "$_image1:$_name" | md5sum | cut -c1-6)"
            docker rmi "$_image2" 2>/dev/null || true
            if [[ "$(docker images "$_image2" | wc -l)" != "2" ]]; then
                docker pull $_image1 && docker tag "$_image1" "$_image2"
            fi
        }

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
# iso-build-centos7
