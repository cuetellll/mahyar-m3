#!/bin/sh
set -e

# Railway variables (set these in the Railway dashboard)
TS_ADDRESS="${TS_ADDRESS:-5.57.37.100:12141}"
BOT_NAME="${BOT_NAME:-Radio 24/7}"
CHANNEL="${CHANNEL:-}"
RADIO_URL="${RADIO_URL:-https://stream.radiox.pro/listen/dep/radio.mp3}"
VOLUME="${VOLUME:-50}"
ADMIN_UID="${ADMIN_UID:-}"

mkdir -p /data/bots/default
cd /data

# Write bot config only if missing (keeps the bot's identity stable across restarts).
# Set FORCE_REGEN=1 once to rewrite it after changing variables.
if [ ! -f bots/default/bot.toml ] || [ "${FORCE_REGEN:-0}" = "1" ]; then
  {
    echo 'run = true'
    echo '[connect]'
    echo "address = \"$TS_ADDRESS\""
    echo "name = \"$BOT_NAME\""
    [ -n "$CHANNEL" ] && echo "channel = \"$CHANNEL\""
    [ -n "$TS_PASSWORD" ] && printf '[connect.server_password]\npw = "%s"\n' "$TS_PASSWORD"
    echo '[events]'
    echo "onconnect = \"!play $RADIO_URL\""
    echo '[audio.volume]'
    echo "default = $VOLUME"
  } > bots/default/bot.toml
fi

# Admin rights (so you can control the bot with !play, !stop, !volume ...)
if [ -n "$ADMIN_UID" ] && [ ! -f rights.toml ]; then
  cat > rights.toml <<RIGHTS
[[rule]]
	useruid = ["$ADMIN_UID"]
	"+" = "*"
RIGHTS
fi

exec /app/TS3AudioBot --non-interactive
