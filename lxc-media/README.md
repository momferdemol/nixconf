# Jellyfin

The free software media system. Stream to any device from you own server, with no strings attached.

# Background

- Jellyfin [website](https://jellyfin.org/)

# Installation

## Proxmox CLI

Use the following commands (steps) to create the container.

```sh
TEMPLATE_STORAGE='local'
TEMPLATE_FILE='nixos-25.05-minimal-x86_64-linux.tar.xz'
CONTAINER_HOSTNAME='lxc-media'
CONTAINER_STORAGE='local-lvm'
CONTAINER_RAM_IN_MB='2048'
CONTAINER_CPU_CORES='2'
CONTAINER_DISK_SIZE_IN_GB='12'
```

```sh
pct create "$(pvesh get /cluster/nextid)" \
  --arch amd64 \
  "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE_FILE}" \
  --ostype unmanaged \
  --description nixos \
  --hostname "${CONTAINER_HOSTNAME}" \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp,firewall=1 \
  --storage "${CONTAINER_STORAGE}" \
  --memory "${CONTAINER_RAM_IN_MB}" \
  --cores "${CONTAINER_CPU_CORES}" \
  --rootfs ${CONTAINER_STORAGE}:${CONTAINER_DISK_SIZE_IN_GB} \
  --unprivileged 1 \
  --features nesting=1 \
  --cmode console \
  --onboot 1 \
  --start 0
  ```

```sh
rm /etc/nixos/configuration.nix && \
curl https://raw.githubusercontent.com/momferdemol/nixconf/refs/heads/main/lxc-media/configuration.nix \
> /etc/nixos/configuration.nix
```
