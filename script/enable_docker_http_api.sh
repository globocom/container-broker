set -e
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo echo "[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix://var/run/docker.sock" > /etc/systemd/system/docker.service.d/docker.conf
sudo systemctl daemon-reload
sudo systemctl restart docker
