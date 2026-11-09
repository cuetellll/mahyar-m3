# Source of libssl 1.1 (the bot's .NET Core 3.1 runtime can't use OpenSSL 3)
FROM mcr.microsoft.com/dotnet/runtime-deps:3.1-bullseye-slim AS ssl

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \
    CLR_OPENSSL_VERSION_OVERRIDE=1.1

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl ffmpeg libopus0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ssl /usr/lib/x86_64-linux-gnu/libssl.so.1.1 /usr/lib/x86_64-linux-gnu/
COPY --from=ssl /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/
RUN ldconfig

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
