#!/bin/bash
# Initialize state by pulling images and stuff
rm -rf /tmp/backup
mkdir /tmp/backup
docker pull loomchild/volume-backup
#Shut off services
sleep 1
sudo systemctl stop cloudflare-ddns
sleep 1
sudo systemctl stop code-server
sleep 1
sudo systemctl stop heimdall
sleep 1
sudo systemctl stop mango
sleep 1
sudo systemctl stop matrix
sleep 1
sudo systemctl stop paperless-ng
sleep 1
sudo systemctl stop vaultwarden
sleep 1
sudo systemctl stop wirehole
sleep 1
sudo systemctl stop trilium
sleep 1
#Make the backup as quickly as possible
docker run -v paperless_data:/volume -v /tmp/backup:/backup --rm loomchild/volume-backup backup -c 0 paperless_data &
sleep 1
docker run -v paperless_media:/volume -v /tmp/backup:/backup --rm loomchild/volume-backup backup -c 0 paperless_media &
sleep 1
docker run -v paperless_pgdata:/volume -v /tmp/backup:/backup --rm loomchild/volume-backup backup -c 0 paperless_pgdata &
sleep 1
docker run -v trilium_trilium:/volume -v /tmp/backup:/backup --rm loomchild/volume-backup backup -c 0 trilium_trilium &
sleep 1
docker run -v vaultwarden-rclone-data:/volume -v /tmp/backup:/backup --rm loomchild/volume-backup backup -c 0 vaultwarden-rclone-data &
sleep 1
docker run -v vaultwarden-data:/volume -v /tmp/backup:/backup --rm loomchild/volume-backup backup -c 0 vaultwarden-data &
sleep 1
# Copy docker directory
cp -r /srv/docker /tmp/backup/ &
wait $(jobs -p)
#Restart services
sleep 1
sudo systemctl start cloudflare-ddns
sleep 1
sudo systemctl start code-server
sleep 1
sudo systemctl start heimdall
sleep 1
sudo systemctl start mango
sleep 1
sudo systemctl start matrix
sleep 1
sudo systemctl start paperless-ng
sleep 1
sudo systemctl start vaultwarden
sleep 1
sudo systemctl start wirehole
sleep 1
sudo systemctl start trilium
sleep 1
#Use zstd to actually backup everything - wrap in zip with password?
time=`date +%m:%d:%y-%T`
tar -I 'zstd --ultra -22' -cf /tmp/backup-$time.tar.zst /tmp/backup
zip --password password /tmp/backup.$time.zip /tmp/backup-$time.tar.zst
#Upload to gdrive
sleep 1
if rclone copy /tmp/backup.$time.zip mydrive:DockerBackup ; then
	curl -m 10 --retry 5 https://hc-ping.com/putyourstuffhere
else
	echo "FAILURE"
fi
rm /tmp/backup-$time.tar.zst
rm /tmp/backup.$time.zip
