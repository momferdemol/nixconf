# Jellyfin

The free software media system. Stream to any device from you own server, with no strings attached.

# Background

- Jellyfin [website](https://jellyfin.org/)
- Mount [CIFS share](https://forum.proxmox.com/threads/tutorial-unprivileged-lxcs-mount-cifs-shares.101795/) on Proxmox
- GPU [passthrough](https://www.simplehomelab.com/udms-11-gpu-passthrough-on-proxmox-lxc/) on Proxmox LXC
- [Hardware Transcode](https://www.youtube.com/watch?v=tWumbDlbzLY)

# Installation

- host: create a new container
- host: install nixos
- host: `apt-get install cfis-utils`
- host: `mkdir /media/synology`
- host: `nano /etc/fstab`

```
//ip-address/share /media/synology
cifs
_netdev,x-systemd.automount,noatime,uid=100000,gid=110000,dir_mode=0770,file_mode=0770,
credentials=/home/.synology 0 0
```

- host: credentials `nano /home/.synology`
- host: `mount /media/synology`
- host: `nano /etc/pve/lxc/LXC_ID.conf`

Mount synology file share
```
mp0: /media/synology/,mp=/media/synology,ro=1
```

Set GPU passthrough
```
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
```

# Post-installation checks

Check the supported QSV / VA-API codecs
```
vainfo --display drm --device /dev/dri/renderD128
```

Check the OpenCL runtime status
```
ffmpeg -v verbose -init_hw_device vaapi=va:/dev/dri/renderD128 -init_hw_device opencl@va
```

See render in action
```
intel_gpu_top
```

## Proxmox CLI

Use the following commands (steps) to create the container.

```sh
TEMPLATE_STORAGE='local'
TEMPLATE_FILE='nixos-24.05-system-x86_64-linux.tar.xz'
CONTAINER_HOSTNAME='lxc-jellyfin'
CONTAINER_STORAGE='local-lvm'
CONTAINER_RAM_IN_MB='2048'
CONTAINER_CPU_CORES='2'
CONTAINER_DISK_SIZE_IN_GB='32'
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
  --unprivileged 0 \
  --features nesting=0 \
  --cmode console \
  --onboot 1 \
  --start 0
  ```

```sh
rm /etc/nixos/configuration.nix && \
curl https://raw.githubusercontent.com/momferdemol/nixconf/refs/heads/main/lxc-jellyfin/configuration.nix \
> /etc/nixos/configuration.nix
```
