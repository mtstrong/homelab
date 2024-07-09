docker volume rm movies
docker volume rm tv
docker volume rm audiobooks
docker volume rm podcasts
docker volume rm torrent-dls
docker volume rm nzb-dls
docker volume rm handbrake
docker volume rm comics
docker volume rm books
docker volume rm b-dls
docker volume rm netboot
docker volume rm book-uploads
docker volume rm book-plugins

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