@ -0,0 +1,106 @@
#!/bin/bash

# Par Aerya | https://upandclear.org | 06.2025
# Nécessite jq (sudo apt install jq)

DISCORD_WEBHOOK_URL="https://canary.discord.com/api/webhooks/…"
YML_DIR="/home/$USER/seedbox-compose/includes/dockerapps/vars" # Normalement à ne pas changer
MAX_LENGTH=1900 # Taille maximale du message sur Discord, contenu scindé en conséquence
TRAEFIK_API="https://traefik.domain.tld/api/http/routers"
AVATAR_URL="https://user-images.githubusercontent.com/64525827/107496602-ceddbb80-6b91-11eb-9a05-ac311eedf150.png" # J'ai pas trouvé mieux, mais il faudra

urlencode() {
  local str="$1" pos c o encoded=""
  for ((pos=0; pos<${#str}; pos++)); do
    c=${str:pos:1}
    case "$c" in
      [a-zA-Z0-9.~_-]) o="$c" ;;
      *) printf -v o '%%%02X' "'$c" ;;
    esac
    encoded+="$o"
  done
  echo "$encoded"
}

send_chunks() {
  local text="$1" chunk last_pos cut_pos
  while [[ -n "$text" ]]; do
    chunk="${text:0:$MAX_LENGTH}"
    if ((${#text} > MAX_LENGTH)); then
      last_pos=$(echo "$chunk" | grep -b -o $'\n' | tail -n1 | cut -d: -f1)
      [[ -z "$last_pos" ]] && cut_pos=$MAX_LENGTH || cut_pos=$((last_pos+1))
      chunk="${chunk:0:$cut_pos}"
    fi
    curl -s -H "Content-Type: application/json" \
      -X POST -d "$(jq -n --arg content "$chunk" '{content:$content}')" \
      "$DISCORD_WEBHOOK_URL"
    text="${text:${#chunk}}"
    sleep 1
  done
}


header=$'**__Liste des Dockers SSDv2 installés__**\n\n'
curl -s -H "Content-Type: application/json" \
     -X POST -d "$(jq -n --arg content "$header" '{content:$content}')" \
     "$DISCORD_WEBHOOK_URL"

curl -s -H "Content-Type: application/json" \
     -X POST -d "$(jq -n --arg url "$AVATAR_URL" '{embeds:[{image:{url:$url}}]}')" \
     "$DISCORD_WEBHOOK_URL"

containers=($(docker ps --format '{{.Names}}' | sort))
declare -A url_map

domains=$(curl -s "$TRAEFIK_API" \
  | jq -r '.[].rule' \
  | grep -oE 'Host\(`[^`]+`\)' \
  | sed -E 's/Host\(`([^`]+)`\)/\1/' \
  | sort -u)
for d in $domains; do
  sub=${d%%.*}
  url_map["$sub"]="https://$d"
done

for c in "${containers[@]}"; do
  yml=$(find "$YML_DIR" -type f -name "*$c*.yml" | head -n1)
  [[ -z "$yml" ]] && continue
  img=$(grep -E '^\s*image:' "$yml" | head -n1 | sed -E "s/^\s*image:\s*['\"]?([^'\"]+)['\"]?/\1/")
  [[ -z "$img" ]] && continue

  enc=$(urlencode "$img")
  search="https://www.startpage.com/do/dsearch?query=docker%2B${enc}"
  traefik_url=${url_map[$c]:-"(aucune URL Traefik trouvée)"}
  traefik_tagged="<${traefik_url}>"

  block="🧩 $c
🌐 Mon URL : $traefik_tagged
🐳 Image : $img
🔎 Rechercher : <$search>
────────────────────────────
"
  send_chunks "$block"
done

sleep 2


md=""
while read -r d; do md+="• https://$d"$'\n'; done <<<"$domains"
md=$(echo -n "$md" | sed '${/^$/d;}')

payload_traefik=$(jq -n \
  --arg avatar_url "$AVATAR_URL" \
  --arg description "$md" \
  '{
    avatar_url: $avatar_url,
    embeds:[{
      description:$description,
      color:3066993
    }]
  }')
curl -s -H "Content-Type: application/json" \
     -X POST -d "$payload_traefik" \
     "$DISCORD_WEBHOOK_URL"

echo "Envoi Docker + Traefik terminé."