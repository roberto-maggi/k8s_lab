#!/bin/sh

VIP=192.168.1.230
KUBE_PORT=6444
errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl --silent --max-time 2 --insecure https://localhost:$KUBE_PORT/ -o /dev/null || errorExit "Error GET https://localhost:$KUBE_PORT/"
if ip addr | grep -q $VIP; then
  curl --silent --max-time 2 --insecure https://$VIP:$KUBE_PORT/ -o /dev/null || errorExit "Error GET https://$VIP:$KUBE_PORT/"
fi
