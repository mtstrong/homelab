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

docker volume create movies --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"mnt/TrueNAS/movies"
docker volume create tv --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/tv"
docker volume create audiobooks --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/audiobooks"
docker volume create podcasts --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/podcasts"
docker volume create torrent-dls --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/torrent-dls"
docker volume create nzb-dls --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/nzb-dls"
docker volume create handbrake --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/handbrake"
docker volume create comics --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/comics"
docker volume create books --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/books"
docker volume create b-dls --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/b-dls"
docker volume create netboot --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/netboot"
docker volume create book-uploads --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/book-uploads"
docker volume create book-plugins --driver local --opt type=nfs --opt o=addr=192.168.1.38,rw --opt device=:"/mnt/TrueNAS/book-plugins"
