FROM alpine

RUN apk add --no-cache openvpn tcpdump bash


ENTRYPOINT ["/runopenvpn"]

COPY runopenvpn.sh /runopenvpn

