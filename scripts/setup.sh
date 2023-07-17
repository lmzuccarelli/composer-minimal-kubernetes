#!/bin/bash
KUBESERVER_IP=192.168.0.29

./scripts/gen-certs.sh \
  ./data/openssl.cnf \
 	config \
	config/ca \
  "${KUBESERVER_IP}"
