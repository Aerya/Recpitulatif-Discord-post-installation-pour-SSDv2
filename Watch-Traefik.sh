#!/bin/bash

MAIN_SCRIPT="/home/$user/seedbox/Discord-Notif.sh"

docker events --filter 'type=container' --filter 'event=start' --format '{{.Actor.ID}}' \
| while read -r container_id; do
    labels=$(docker inspect --format '{{json .Config.Labels}}' "$container_id")

    if echo "$labels" | grep -q '"traefik.http.routers.'; then
      echo "Nouveau sous-domaine Traefik détecté ($container_id)"
      bash "$MAIN_SCRIPT"
    fi
done