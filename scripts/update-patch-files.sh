#!/bin/bash
#
set -euxo pipefail

LOCAL_KUBEHOST=mostro
LOCAL_COMPOSER_PATH="\/home\/lzuccarelli\/data\/composer"
LOCAL_WORKER_PATH="\/home\/lzuccarelli\/data\/worker"
LOCAL_MINIO_PATH="\/home\/lzuccarelli\/data\/minio"
LOCAL_COMPOSER_IMAGE="quay.io\/luzuccar\/osbuild-composer:v1.0.0"
LOCAL_WORKER_IMAGE="quay.io\/luzuccar\/osbuild-worker:v1.0.0"

# update host in patch files
sed -i "s/KUBEHOST/${LOCAL_KUBEHOST}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-minio-pv.yaml 
sed -i "s/KUBEHOST/${LOCAL_KUBEHOST}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-composer-pv.yaml 
sed -i "s/KUBEHOST/${LOCAL_KUBEHOST}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-worker-pv.yaml 

# update paths
sed -i "s/MINIO_PATH/${LOCAL_MINIO_PATH}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-minio-pv.yaml 
sed -i "s/COMPOSER_PATH/${LOCAL_COMPOSER_PATH}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-composer-pv.yaml 
sed -i "s/WORKER_PATH/${LOCAL_WORKER_PATH}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-worker-pv.yaml 

# update images
sed -i "s/COMPOSER_IMAGE/${LOCAL_COMPOSER_IMAGE}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-composer.yaml 
sed -i "s/WORKER_IMAGE/${LOCAL_WORKER_IMAGE}/g" ./kustomize-templates/overlays/sno-kubernetes/patches/patch-worker.yaml 

