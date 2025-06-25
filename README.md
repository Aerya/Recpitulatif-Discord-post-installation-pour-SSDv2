# Récapitulatif Discord post-installation du script SSDv2 | https://github.com/projetssd/ssdv2

Ce script Bash permet de :

1. Lister les containers Docker installés (via `docker ps`), récupérer leurs images depuis les fichiers `*.yml`  
2. Récupérer les sous-domaines Traefik
3. Générer pour chaque container un bloc détaillé (nom, URL Traefik, image, lien de recherche Startpage)  
4. Éviter les embeds indésirables, gérer le rate-limit, chunker les messages trop longs

![](https://github.com/Aerya/Recpitulatif-Discord-post-installation-pour-SSDv2/blob/7bd1091f0e2efa73f3ab9e64c844627e991abbb5/Screenshots/1.png)
![](https://github.com/Aerya/Recpitulatif-Discord-post-installation-pour-SSDv2/blob/7bd1091f0e2efa73f3ab9e64c844627e991abbb5/Screenshots/2.png)


---

# Prérequis

jq (sudo apt install jq)  

---

# Configuration

Placer le script Discord-notif.sh dans /home/$user/seedbox, le rendre exécutable :
```bash
chmod +x Discord-notif.sh
```

Editer ses variables :

```bash
# URL webhook Discord
DISCORD_WEBHOOK_URL="https://canary.discord.com/api/webhooks/…"

# API Traefik
TRAEFIK_API="https://traefik.domain.tld/api/http/routers"
```

---

# Automatisation

Placer le script Script Watch-Traefik.sh dans /home/$user/seedbox et le rendre exécutable :
```bash
chmod +x Watch-Traefik.sh
```

Ecoute en continue les évènements "start" pour Docker et le cas échant regarde les labels pour trouver "traefik.http.routers.*".
Dans ce cas, ça relance le script de notification Discord.

Placer le service Watch-Traefik-systemd.service dans /etc/systemd/system/ et le lancer
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now Watch-Traefik-systemd.service
```