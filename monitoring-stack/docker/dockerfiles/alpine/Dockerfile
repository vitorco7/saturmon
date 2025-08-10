FROM alpine:3.21.3

RUN apk update && apk add --no-cache wget stress-ng gnupg curl bash iperf3

RUN apk add --no-cache ca-certificates procps lm-sensors tzdata iputils 

RUN wget -q https://dl.influxdata.com/telegraf/releases/telegraf-1.29.4_linux_amd64.tar.gz && \
    tar -xzf telegraf-1.29.4_linux_amd64.tar.gz && \
    cp -r telegraf-1.29.4/* / && \
    rm -rf telegraf-1.29.4* && \
    mkdir -p /etc/telegraf

COPY configs/telegraf/virtual-devices/telegraf.conf /etc/telegraf/telegraf.conf

COPY scripts/load_simulator.sh /usr/local/bin/load_simulator.sh

RUN chmod +x /usr/local/bin/load_simulator.sh

WORKDIR /

CMD ["/bin/bash", "-c", "/usr/local/bin/load_simulator.sh & telegraf --config /etc/telegraf/telegraf.conf"]