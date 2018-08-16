ARCH=${ARCH:-amd64}

image_name=${IMAGE_PREFIX:-}idlabfuse/openvpn-clustered-client-${ARCH}:${TAG:-latest}

docker rmi ${image_name}
docker build -t ${image_name} .

if [[ "${PUSH_IMAGES:-}" ]]; then
  docker push ${image_name}
fi
