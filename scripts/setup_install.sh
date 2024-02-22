sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
sudo groupadd -f docker
sudo usermod -aG docker $USER
newgrp docker
sudo apt-get install git
sudo apt install nfs-common
sudo mkdir /mnt/ws2022
sudo mount 192.168.1.153:/ws2022 /mnt/ws2022
docker volume create sabnzbd --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:/ws2022/homelab/git/homelab/compose/sabnbd/config
docker volume create nzbget --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:/ws2022/homelab/git/homelab/compose/nzbget/config
docker volume create dls --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:/ws2022/homelab/git/homelab/compose/nzbget/downloads
docker volume create traefik --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:/ws2022/homelab/git/homelab/compose/traefik-app
docker volume create sonarr --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:/ws2022/homelab/git/homelab/compose/sonarr/config
docker volume create movies --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/bluray rips"
docker volume create tv-completed --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/tv shows/completed"
docker volume create tv-current --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/tv shows/currently airing"
docker volume create movies --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/bluray rips"
docker volume create comics --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/comics"
docker volume create books --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/books"
docker volume create books-uploads --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/books/uploads"
docker volume create books-plugins --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/books/plugins"
docker volume create downloads --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/downloads"
docker volume create tdownloads --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/tdownloads"
docker volume create audiobooks --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/audiobooks"
docker volume create podcasts --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/podcasts"
docker volume create netboot --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/netboot"
docker volume create hb-storage --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/hb-storage"
docker volume create hb-watch --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/hb-watch"
docker volume create hb-output --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/hb-output"
docker volume create grafana-data --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/grafana-data"
docker volume create prometheus-data --driver local --opt type=nfs --opt o=addr=192.168.1.153,rw --opt device=:"/ws2022/prometheus-data"
