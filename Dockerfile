FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl ffmpeg libopus0 libssl3 \
    && rm -rf /var/lib/apt/lists/*

ARG BOT_VERSION=0.12.0
RUN mkdir -p /app && cd /app \
    && curl -fsSL -o bot.tar.gz \
       "https://github.com/Splamy/TS3AudioBot/releases/download/${BOT_VERSION}/TS3AudioBot_linux_x64.tar.gz" \
    && tar -xzf bot.tar.gz && rm bot.tar.gz \
    && chmod +x /app/TS3AudioBot

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data
ENTRYPOINT ["/entrypoint.sh"]
