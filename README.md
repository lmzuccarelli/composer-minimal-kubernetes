# Overview

This is a simple quick start to get a composer client and worker from the image-builder project (refer to the main [project](https://github.com/osbuild/osbuild-composer))
together with minio, a generic s3 bucket for local on-prem use, on a vanilla single node Kubernetes cluster, for a simplified dev environment

## Architecture (Kubernetes)

![architecture](./readme-images/osbuild-architecture.jpg)


## Prerequisites

The following is a list of prerequisites 

- A single node Kubernetes cluster is installed and running, version 1.26 or greater.

  I have created a quick install [guide](https://docs.google.com/document/d/1ymRJ-gc7sdAedhWYN3jg2rVlf2StA4bIvq11TTQ-_fA/edit)
- go version 1.20 or greater
- kustomization v4.2.0


## Compile osbuild-composer & osbuild-worker (optional)

We have already built and pushed working version of both the composer and worker containers. 
This step is only relevant if you want to build and push you own versions.

```
cd `/path/to/osbuild-composer`

go build -o bin ./cmd/osbuild-composer

go build -o bin ./cmd/osbuild-worker
```

Copy these binaries back into the repo, under the bin directory

## Build the containers (optional)

We have already built and pushed working version of both the composer and worker containers. 
This step is only relevant if you want to build and push you own versions.

Build and push composer 

```
podman build -t <registry/user/osbuild-composer:v1.0.0> -f Dockerfile-composer

podman push <registry/user/osbuild-composer:v1.0.0>
 
```
Build and push the worker

```
podman build -t <registry/user/osbuild-worker:v1.0.0> -f Dockerfile-worker

podman push <registry/user/osbuild-composer:v1.0.0>
```


## Generate the certs

N.B. The certs make use of an IP address (refer to the setup.sh) for the Kubernetes server. 
We have used NodePort settings to access the composer api remotely so please change this accordingly.

```
./scripts/setup.sh
```


**_NOTE_**: The worker container needs to be run in privileged mode and have additional
capabilities. Refer to the kustomize-templates/base/apps/deployment/osbuild-worker.yaml file

We are using local (hostpath) storage on the SNO Kubernetes cluster. 
Obvisuosly this will change if you are using NFS or something similar. 
Remember to update the StorageClass and PersistentVolume files in the kustomize-templates folder

The concept of copying the ./config folder is required as both the worker and composer containers 
will mount these folders to make use of the relevant certs and configs.

Create the relevant paths for PV's etc on you Kubernetes host (open a new terminal and ssh to the kube server) 

```
mkdir /path-to-composer/
mkdir /path-to-worker/
mkdir /path-to-minio/

```
Ensure the kustomize patch files have all the updates

**NB** - If you created your own version of the composer and worker containers remember to update the image values also

Edit the ./update-patch-files.sh script, change the relevant vars (default values are set) 

```
LOCAL_KUBEHOST=<your-kubeserver-hostname>
LOCAL_COMPOSER_PATH=<path-to-composer>
LOCAL_WORKER_PATH=<path-to-worker>
LOCAL_COMPOSER_IMAGE=<composer-image>
LOCAL_WORKER_IMAGE=<worker-image>

```

Execute the update-patch-files-script

```
./scripts/update-patch-files.sh
```

Before deploying copy all the contents of the config directory (certs generated from the ./setup.sh command)
to the relevant folders that you created in the previous step

As an example I used scp on the Kubernetes server to copy from my development machine
```
scp -r lzuccarelli@192.168.0.17:/home/lzuccarelli/Projects/composer-minimal/config/* data/worker
scp -r lzuccarelli@192.168.0.17:/home/lzuccarelli/Projects/composer-minimal/config/* data/composer
```

Verify the kustomization build

```
kustomize build ./kustomize-templates/overlays/sno-kubernetes/ -o test.yaml

```

Open the test.yaml file to verify that all changes have been made correctly


Deploy to your SNO Kubernetes cluster

Assume you have already exported KUBECONFIG

```
kubectl apply -k kustomize-templates/overlays/sno-kubernetes
```

Monitor the deploy 

```
kubectl get all -n osbuild
```

Once all pods are in "RUNNING" status (as shown below) - we can now configure the minio service

```
$ kubectl get all -n osbuild
NAME                            READY   STATUS    RESTARTS   AGE
pod/composer-7447b7d944-8shp6   1/1     Running   0          2d16h
pod/minio-67fdd4dd45-qlqgm      1/1     Running   0          2d19h
pod/worker-7b75fcdcbc-rx9hc     1/1     Running   0          2d17h

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
service/composer   NodePort    10.96.130.188   <none>        8700:30037/TCP,8080:30030/TCP   2d19h
service/minio      NodePort    10.96.211.213   <none>        9000:32013/TCP,9001:30031/TCP   2d19h
service/worker     ClusterIP   10.96.236.12    <none>        8700/TCP                        2d19h

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/composer   1/1     1            1           2d19h
deployment.apps/minio      1/1     1            1           2d19h
deployment.apps/worker     1/1     1            1           2d19h

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/composer-7447b7d944   1         1         1       2d19h
replicaset.apps/minio-67fdd4dd45      1         1         1       2d19h
replicaset.apps/worker-7b75fcdcbc     1         1         1       2d19h

```

Use your browser to navigate to `http://kubernetes-server-ip:30031`

Log into the minio service (default user is minioadmin and password is minioadmin)

Create a bucket called composer-minimal

Navigate to settings (on the left menu) and update the region setting to `us-east-1`

At the top of the browser a *Restart* server button will appear - click it to restart minio

You are now ready to start a build.

Create a build  

```
curl -X 'POST' \
  'https://${KUBERNETES_IP}:30030/api/image-builder-composer/v2/compose' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  --cacert ./config/ca-crt.pem \
  --key ./config/client-key.pem \
  --cert ./config/client-crt.pem \
  -d @examples/compose-request.json
```

Results from worker pod

```
time="2023-07-17T13:00:06Z" level=info msg="Job 'd7ffecd8-0228-47d3-91de-7decba307d56' (depsolve) finished"
time="2023-07-17T13:00:19Z" level=info msg="Running job 'da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec' (osbuild)\n"
time="2023-07-17T13:06:29Z" level=info msg="build pipeline results:\n" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.rpm success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.selinux success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="os pipeline results:\n" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.kernel-cmdline success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.rpm success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.fix-bls success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.locale success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.hostname success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.timezone success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.users success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.fstab success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.grub2 success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.systemd success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.selinux success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="image pipeline results:\n" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.truncate success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.sfdisk success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.mkfs.fat success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.mkfs.ext4 success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.mkfs.ext4 success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.copy success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.grub2.inst success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="qcow2 pipeline results:\n" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="  org.osbuild.qemu success" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:29Z" level=info msg="[AWS] 🚀 Uploading image to S3: composer-minimal/composer-api-594fb507-c227-4d00-9bb2-5d23a3be9570-disk.qcow2"
time="2023-07-17T13:06:30Z" level=info msg="[AWS] 📋 Generating Presigned URL for S3 object composer-minimal/composer-api-594fb507-c227-4d00-9bb2-5d23a3be9570-disk.qcow2"
time="2023-07-17T13:06:30Z" level=info msg="[AWS] 🎉 S3 Presigned URL ready"
time="2023-07-17T13:06:30Z" level=info msg="osbuild job succeeded" jobId=da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec
time="2023-07-17T13:06:31Z" level=info msg="Job 'da6a5dc5-a76b-43d7-9eb0-acbdbeceb5ec' (osbuild) finished"

```

Screenshot from minio

![screenshot](./readme-images/minio.png)
