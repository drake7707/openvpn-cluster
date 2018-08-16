FROM alpine

RUN apk add --no-cache openvpn tcpdump bash

COPY ./service /service

CMD "/service/run.sh"



