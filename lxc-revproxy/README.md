# Reverse Proxy

A reverse proxy is a server that sits in front of one or more web servers, intercepting requests from clients. This configuration will build an internal reverse proxy based on nginx. 

Use certbot in manual mode to request a certificate for `lan.d35c.net`.

# Background

- Nginx [website](https://nginx.org/en/)
- Certbot [documentation](https://eff-certbot.readthedocs.io/en/stable/)

# Installation

- Create the container
- Install certbot with `nix-shell`
- Request the certificate
- Create directory `/etc/nginx/ssl`
- Copy the *.pem files
- Install nixos with `nixos-rebuild`
- Update permissions with `chown`
- Reboot

## Proxmox CLI

Use the following commands (steps) to create the container.

```sh
TEMPLATE_STORAGE='local'
TEMPLATE_FILE='nixos-24.05-system-x86_64-linux.tar.xz'
CONTAINER_HOSTNAME='lxc-revproxy'
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
  --start 1
  ```

```sh
rm /etc/nixos/configuration.nix && \
curl https://raw.githubusercontent.com/momferdemol/nixconf/refs/heads/main/lxc-revproxy/configuration.nix \
> /etc/nixos/configuration.nix
```

## Lets Encrypt

```sh
nix-shell -p certbot
```

```sh
certbot certonly \
-d "*.lan.d35c.net" \
-d "lan.d35c.net" \
--manual \
--preferred-challenges=dns
```

```sh
mkdir /etc/nginx/ssl
```

```sh
cp [file] /etc/nginx/ssl
```

```sh
chown -R nginx:nginx /etc/nginx
```

```sh
certbot revoke \
--cert-name [domain]
```
