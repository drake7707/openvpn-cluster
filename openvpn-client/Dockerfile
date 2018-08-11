FROM alpine

RUN apk add --no-cache openvpn tcpdump


ENTRYPOINT ["/runopenvpn"]

COPY runopenvpn.sh /runopenvpn

