FROM idlabfuse/openvpn-server-amd64

# Make sure you have a etcdctl version compatible with alpine:linux, so built for musl, not glibc. Easiest is to just copy it from the quay.io/etcd docker image
COPY ./etcdctl /usr/bin/etcdctl

CMD "/service/run_server"
