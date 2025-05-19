FROM alpine:3.21.3

# Install basic dependencies
RUN apk update && apk add --no-cache wget stress-ng gnupg curl bash

# Install required dependencies for Telegraf
RUN apk add --no-cache ca-certificates procps lm-sensors tzdata iputils 

# Install Telegraf directly using the binary package
RUN wget -q https://dl.influxdata.com/telegraf/releases/telegraf-1.29.4_linux_amd64.tar.gz && \
    tar -xzf telegraf-1.29.4_linux_amd64.tar.gz && \
    cp -r telegraf-1.29.4/* / && \
    rm -rf telegraf-1.29.4* && \
    mkdir -p /etc/telegraf

# Copy configuration files
COPY configs/telegraf/virtual-devices/telegraf.conf /etc/telegraf/telegraf.conf

COPY scripts/load_simulator.sh /usr/local/bin/load_simulator.sh

RUN chmod +x /usr/local/bin/load_simulator.sh

# Set working directory
WORKDIR /

# Run the load simulator and Telegraf
CMD ["/bin/bash", "-c", "/usr/local/bin/load_simulator.sh & telegraf --config /etc/telegraf/telegraf.conf"]