# install details

## where to download k8s binaries
https://www.downloadkubernetes.com/
```sh
curl -sSLO https://dl.k8s.io/v1.27.2/bin/linux/amd64/kubectl
curl -sSLO https://dl.k8s.io/v1.27.2/bin/linux/amd64/kubelet
curl -sSLO https://dl.k8s.io/v1.27.2/bin/linux/amd64/kube-proxy
curl -sSLO https://dl.k8s.io/v1.27.2/bin/linux/amd64/kube-apiserver
curl -sSLO https://dl.k8s.io/v1.27.2/bin/linux/amd64/kube-scheduler
curl -sSLO https://dl.k8s.io/v1.27.2/bin/linux/amd64/kube-controller-manager
```

## install local image registry
自建镜像仓库
### 准备证书
- ca证书
- 用ca证书生成服务端证书，也就是registry需要加载的证书

### 启动registry容器
```
docker run -d \
  --restart=always \
  --name myregistry-secure \
  -v /Users/yyliao/certificates:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/myregistry.pem \
  -e REGISTRY_HTTP_TLS_KEY=/certs/myregistry-key.pem \
  -p 5000:5000 \
  registry

```

### 配置客户端
客户端需要把第一步用到的ca证书加载到本地的信任列表中，不同的系统设置方式不同.
mac的设置方式 (https://docs.docker.com/desktop/faqs/macfaqs/#how-do-i-add-tls-certificates ).
其他的参照 ( https://docs.docker.com/registry/insecure/#use-self-signed-certificates )


docker pull xxx
docker tag xxx ddddd
doker push ddddd

### 增加访问控制
https://docs.docker.com/registry/deploying/#restricting-access

registry启动的时候需要开启选项 -e "REGISTRY_AUTH=htpasswd" 
 -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd ,
这样重启registry以后，客户端必须先登录registry才能访问registry

### 文档
install docker desktop on MacOSX, install following official docs:
https://docs.docker.com/registry/deploying/



## containerd配置

### config.toml配置containerd
https://github.com/containerd/containerd/blob/main/docs/cri/config.md  


### 配置hosts.toml，使用registry mirror
https://github.com/containerd/containerd/blob/main/docs/hosts.md

#### istio 拉取镜像
kubectl describe pod istio-egressgateway-69cbcfc4d-89zmk -n istio-system
```
Normal   Pulling      18m                    kubelet  Pulling image "docker.io/istio/proxyv2:1.18.0"
  Warning  Failed       17m                    kubelet  Error: ErrImagePull
  Warning  Failed       16m (x3 over 17m)      kubelet  Failed to pull image "docker.io/istio/proxyv2:1.18.0": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/istio/proxyv2:1.18.0": failed to resolve reference "docker.io/istio/proxyv2:1.18.0": docker.io/istio/proxyv2:1.18.0: not found
  Normal   BackOff      88s (x62 over 17m)     kubelet  Back-off pulling image "docker.io/istio/proxyv2:1.18.0"
```

此时执行sudo crictl images会发现并没有istio/proxy2:1.18.0镜像

解决方案：
```
在mac上docker pull istio/proxyv2:1.18.0
docker tag istio/proxyv2:1.18.0 myregistry:5000/istio/proxyv2:1.18.0
docker push myregistry:5000/istio/proxyv2:1.18.02
```

然后删除pod,由于在/etc/containerd/certs.d/_default/hosts.toml中配置了如下的内容
```
[host."https://myregistry:5000"]
  capabilities = ["pull", "resolve", "push"]
  ca = "/etc/containerd/certs.d/_default/ca.pem"
  skip_verify = false
```
使得使用myregistry:5000作为默认的registry-mirror，所以会从myregistry:5000拉取istio/proxyv2的镜像。
过一会儿发现pod是running了，crictl images也发现了docker.io/istio/proxyv2这个镜像

