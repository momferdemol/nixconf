# Unbound

Unbound is a validating, recursive, caching DNS resolver. It is designed to be fast and lean and incorporates modern features based on open standards. Unbound is created by NLnet Labs.

# DNS servers

```yaml
1.1.1.1           # Cloudflare
9.9.9.9           # Quad9
208.67.222.222    # OpenDNS
```

# Background

- Unbound DNS [tutorial](https://calomel.org/unbound_dns.html)
- Unbound [documentation](https://unbound.docs.nlnetlabs.nl/en/latest/)

# Installation

## Proxmox CLI

Use the following commands (steps) to create the container.

```sh
TEMPLATE_STORAGE='local'
TEMPLATE_FILE='nixos-24.05-system-x86_64-linux.tar.xz'
CONTAINER_HOSTNAME='lxc-unbound'
CONTAINER_STORAGE='local-lvm'
CONTAINER_RAM_IN_MB='1024'
CONTAINER_CPU_CORES='1'
CONTAINER_DISK_SIZE_IN_GB='8'
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
curl https://raw.githubusercontent.com/momferdemol/nixconf/refs/heads/main/lxc-unbound/configuration.nix \
> /etc/nixos/configuration.nix
```
