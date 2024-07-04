# syntax=docker/dockerfile:1.4
FROM ubuntu:jammy
ENV DEBIAN_FRONTEND=noninteractive
RUN <<EOF
apt-get -q -q update
apt-get full-upgrade --yes
apt-get install --yes bash jq wget
# Install lp-api from https://github.com/fourdollars/lp-api
wget https://raw.githubusercontent.com/fourdollars/scripts/master/golang.sh -O - | bash -x -
cat > /root/.bash_aliases <<ENDLINE
# https://golang.org/
if [ -d "\$HOME/.local/share/go/bin" ]; then
    GOPATH="\$HOME/.local/share/go"
    PATH="\$PATH:\$GOPATH/bin"
    export GOPATH
    export PATH
fi
ENDLINE
. /root/.bash_aliases
rm /root/.bash_aliases
go install -ldflags="-s -w" github.com/fourdollars/lp-api@latest
mkdir -p /usr/local/bin/
cp -v /root/.local/share/go/bin/lp-api /usr/local/bin/
rm -fr /root/.local/share/go /root/.cache/go-build
apt-get autopurge --yes wget
rm -fr /var/lib/apt /var/lib/dpkg
EOF
ADD /check /opt/resource/check
ADD /out /opt/resource/out
ADD /in /opt/resource/in
RUN chmod +x /opt/resource/*
