FROM alpine:latest 


RUN apk add --no-cache openvpn easy-rsa bash tcpdump && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

COPY ./service /service

# /config contains the templates to use for the server and client
# /data is the current working data such as keys, certificates and substituted config

VOLUME [ "/config", "/data" ]

CMD "/service/run_server"
