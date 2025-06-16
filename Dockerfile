FROM debian:bookworm-slim

# Install Mosquitto with WebSockets support
RUN apt-get update && \
    apt-get install -y wget gnupg && \
    wget -qO - https://repo.mosquitto.org/debian/mosquitto-repo.gpg.key | apt-key add - && \
    echo "deb https://repo.mosquitto.org/debian bookworm main" > /etc/apt/sources.list.d/mosquitto.list && \
    apt-get update && \
    apt-get install -y mosquitto mosquitto-clients libwebsockets-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log

# Copy JWT plugin (ensure it's compiled for Debian)
COPY custom_jwt_auth_plugin.so /usr/lib/custom_jwt_auth_plugin.so

# Copy config and certs
COPY mosquitto/mosquitto.conf /mosquitto/config/mosquitto.conf
COPY certs /mosquitto/certs

# Run Mosquitto
CMD ["mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]