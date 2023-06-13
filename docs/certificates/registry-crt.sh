#!/bin/bash

INTERNAL_IP=192.168.71.47
domain="myregistry"
cat > ${domain}-csr.json <<EOF
{
  "CN": "${domain}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF


cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${domain},${INTERNAL_IP} \
  -profile=kubernetes \
  ${domain}-csr.json | cfssljson -bare ${domain}

