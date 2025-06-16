# Multi-stage build to get envsubst
FROM alpine:3.21.3
RUN apk add --no-cache curl gettext

ENV ALERTMANAGER_VERSION=0.28.1
RUN curl -L https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz | \
    tar xz && \
    mv alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/alertmanager /bin/alertmanager && \
    mv alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/amtool /bin/amtool && \
    rm -rf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64

# Copy your entrypoint script and config template
COPY scripts/alertmanager_entrypoint.sh /usr/local/bin/alertmanager_entrypoint.sh
COPY configs/prometheus/alertmanager/alertmanager.yml.template /etc/alertmanager/alertmanager.yml.template

RUN chmod +x /usr/local/bin/alertmanager_entrypoint.sh

ENTRYPOINT ["/usr/local/bin/alertmanager_entrypoint.sh"]