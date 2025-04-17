FROM ubuntu

RUN apt update && apt install -y wget stress-ng gnupg curl

RUN wget -q https://repos.influxdata.com/influxdata-archive_compat.key

RUN echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null

RUN echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list

RUN apt update && apt install -y telegraf

COPY configs/telegraf/virtual-devices/telegraf.conf /etc/telegraf/telegraf.conf

COPY scripts/load_simulator.sh /usr/local/bin/load_simulator.sh

RUN chmod +x /usr/local/bin/load_simulator.sh

WORKDIR /

CMD ["/bin/bash", "-c", "/usr/local/bin/load_simulator.sh & telegraf --config /etc/telegraf/telegraf.conf"]