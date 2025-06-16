#!/bin/sh
set -e

# Verify envsubst is available
if ! command -v envsubst >/dev/null 2>&1; then
    echo "ERROR: envsubst not found! This should not happen in the custom image."
    exit 1
fi

# Process the template file with environment variable substitution
echo "Processing alertmanager configuration template..."
envsubst < /etc/alertmanager/alertmanager.yml.template > /etc/alertmanager/alertmanager.yml

# Validate the generated config (optional but recommended)
echo "Validating alertmanager configuration..."
alertmanager --config.file=/etc/alertmanager/alertmanager.yml

# Start alertmanager
echo "Starting Alertmanager..."
exec alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/alertmanager \
    --web.external-url=http://localhost:9093