#!/bin/bash
KUBESERVER_IP=192.168.0.29

./gen-certs.sh 
openssl.cnf \
 	config \
	config/ca \
  ${KUBESERVER_IP}

