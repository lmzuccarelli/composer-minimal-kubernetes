# Getting started

Podman needs to be run in rootful.

## Compile osbuild-composer & osbuild-worker and place in bin directory

```
cd `/path/to/osbuild-composer`
```

```
go build -o bin ./cmd/osbuild-composer
```

```
go build -o bin ./cmd/osbuild-worker
```

Copy these binaries back into the repo.

## Generate the certs

`./setup.sh`

## Create network

```
sudo podman network create --subnet 172.16.0.0/24 --gateway 172.16.0.1 osbuild-net
```

## Build the containers

```
sudo podman build -t composer -f Dockerfile-composer
```

```
sudo podman build -t worker -f Dockerfile-worker
```

## Run the containers

```
sudo podman run \
--rm -d \
-p 8081:8080 \
-p 8700:8700 \
-v ./config:/etc/osbuild-composer \
--network osbuild-net \
--name composer composer
```

```
sudo podman run \
--rm -d \
-v ./config:/etc/osbuild-composer \
-v ./config:/etc/osbuild-worker \
-e CACHE_DIRECTORY=/var/cache/osbuild-worker \
--privileged \
--cap-add MKNOD \
--cap-add SYS_ADMIN \
--cap-add NET_ADMIN \
--network osbuild-net \
--name worker worker
```
