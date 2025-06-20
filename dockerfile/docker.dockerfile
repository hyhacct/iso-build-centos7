FROM centos:7
LABEL maintainer="hyhacct@outlook.com"

# 设置工作目录
WORKDIR /apps

# 安装 tmux 并执行换源操作
RUN tee /etc/yum.repos.d/CentOS-Base.repo <<-'EOF' && \
/apps/log.sh "SUCCESS" "Configured Huawei Cloud CentOS repositories."
[base]
name=CentOS-$releasever - Base
baseurl=https://repo.huaweicloud.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
[updates]
name=CentOS-$releasever - Updates
baseurl=https://repo.huaweicloud.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
[extras]
name=CentOS-$releasever - Extras
baseurl=https://repo.huaweicloud.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
[centosplus]
name=CentOS-$releasever - Plus
baseurl=https://repo.huaweicloud.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

RUN yum -y install bc jq

# 使用 tmux 保持容器运行
CMD ["/bin/bash", "-c", "tmux new-session -d && tmux attach"]
