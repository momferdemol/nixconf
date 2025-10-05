# karakeep

Bookmark links, take simple notes and store images and pdfs.

# Background

- Karakeep [website](https://karakeep.app/)

# Installation

## Proxmox CLI

Use the following commands (steps) to create the container.

```
TEMPLATE_STORAGE='local'
TEMPLATE_FILE='nixos-25.05-system-x86_64-linux.tar.xz'
CONTAINER_HOSTNAME='lxc-karakeep'
CONTAINER_STORAGE='local-lvm'
CONTAINER_RAM_IN_MB='1024'
CONTAINER_CPU_CORES='1'
CONTAINER_DISK_SIZE_IN_GB='15'
```

```
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

production
```
rm /etc/nixos/configuration.nix && \
curl https://raw.githubusercontent.com/momferdemol/nixconf/refs/heads/main/lxc-karakeep/configuration.nix \
> /etc/nixos/configuration.nix
```

development
```
rm /etc/nixos/configuration.nix && \
curl https://raw.githubusercontent.com/momferdemol/nixconf/refs/heads/dev/lxc-karakeep/configuration.nix \
> /etc/nixos/configuration.nix
```
