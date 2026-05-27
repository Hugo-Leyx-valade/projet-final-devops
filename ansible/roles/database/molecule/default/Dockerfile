FROM amazonlinux:2023

ENV container=docker

# Nettoyer les units systemd incompatibles avec Docker
RUN set -eux; \
    find /usr/lib/systemd/system/sysinit.target.wants/ -mindepth 1 \
         ! -name 'systemd-tmpfiles-setup.service' -delete 2>/dev/null || true; \
    rm -f /usr/lib/systemd/system/multi-user.target.wants/* \
          /etc/systemd/system/*.wants/* \
          /usr/lib/systemd/system/local-fs.target.wants/* \
          /usr/lib/systemd/system/sockets.target.wants/*udev* \
          /usr/lib/systemd/system/sockets.target.wants/*initctl* \
          /usr/lib/systemd/system/basic.target.wants/* 2>/dev/null || true

RUN dnf install -y systemd python3 sudo rsync && dnf clean all

VOLUME ["/sys/fs/cgroup"]
CMD ["/usr/lib/systemd/systemd"]
