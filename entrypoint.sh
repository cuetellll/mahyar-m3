#!/bin/sh
set -e

# Railway variables (set these in the Railway dashboard)
TS_ADDRESS="${TS_ADDRESS:-5.57.37.100:12141}"
BOT_NAME="${BOT_NAME:-Radio 24/7}"
CHANNEL="${CHANNEL:-}"
RADIO_URL="${RADIO_URL:-}"
VOLUME="${VOLUME:-50}"
ADMIN_UID="${ADMIN_UID:-}"

cd /data
mkdir -p bots

# write_bot <folder> <display name> <channel> <url>
write_bot() {
  mkdir -p "bots/$1"
  {
    echo 'run = true'
    echo '[connect]'
    echo "address = \"$TS_ADDRESS\""
    echo "name = \"$2\""
    [ -n "$3" ] && echo "channel = \"$3\""
    [ -n "$TS_PASSWORD" ] && printf '[connect.server_password]\npw = "%s"\n' "$TS_PASSWORD"
    echo '[events]'
    echo "onconnect = \"!play $4\""
    echo '[audio.volume]'
    echo "default = $VOLUME"
  } > "bots/$1/bot.toml"
}

# FORCE_REGEN=1 wipes every bot config so they are rebuilt from radios.txt (identities change).
if [ "${FORCE_REGEN:-0}" = "1" ]; then
  rm -rf bots
  mkdir -p bots
fi

# Main bot: only exists if the RADIO_URL variable is set. Otherwise it is removed.
if [ -n "$RADIO_URL" ]; then
  if [ ! -f bots/default/bot.toml ]; then
    write_bot default "$BOT_NAME" "$CHANNEL" "$RADIO_URL"
  fi
else
  rm -rf bots/default
fi

rm -f /tmp/active_bots
# Extra bots from radios.txt, one per line:  name | channel | stream url
if [ -f /app/radios.txt ]; then
  while IFS='|' read -r name channel url; do
    name=$(echo "$name" | sed 's/^[ \t]*//;s/[ \t]*$//')
    channel=$(echo "$channel" | sed 's/^[ \t]*//;s/[ \t]*$//')
    url=$(echo "$url" | sed 's/^[ \t]*//;s/[ \t]*$//')
    case "$name" in ''|\#*) continue ;; esac
    [ -z "$url" ] && continue
    slug=$(echo "$name" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]/-/g')
    [ -z "$slug" ] && slug="bot-$(echo "$url" | cksum | cut -d' ' -f1)"
    if [ ! -f "bots/$slug/bot.toml" ]; then
      write_bot "$slug" "$name" "$channel" "$url"
    fi
    echo "$slug" >> /tmp/active_bots
    # Check that the stream is reachable from this server and print the result to the log
    (
      if timeout 20 ffprobe -v error -i "$url" -show_entries format=format_name -of default=nw=1:nk=1 > /tmp/probe_$slug.txt 2>&1; then
        echo "[radio-check] OK     $name -> $url"
      else
        echo "[radio-check] FAILED $name -> $url : $(head -c 300 /tmp/probe_$slug.txt | tr '\n' ' ')"
      fi
    ) &
  done < /app/radios.txt
fi

# Remove bots that were deleted from radios.txt
for d in bots/*/; do
  b=$(basename "$d")
  [ "$b" = "default" ] && continue
  grep -qx "$b" /tmp/active_bots 2>/dev/null || rm -rf "bots/$b"
done

# Admin rights (so you can control the bots with !play, !stop, !volume ...)
if [ -n "$ADMIN_UID" ] && [ ! -f rights.toml ]; then
  cat > rights.toml <<RIGHTS
[[rule]]
	useruid = ["$ADMIN_UID"]
	"+" = "*"
RIGHTS
fi

exec /app/TS3AudioBot --non-interactive
