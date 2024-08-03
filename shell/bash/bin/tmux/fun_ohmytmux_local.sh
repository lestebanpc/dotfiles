#!/bin/sh 

# Source: 'oh-my-tmux', creado por Gregory Pakosz (@gpakosz). 
# URL   : https://github.com/gpakosz/.tmux 
# Se modifica para tener shell en otro archivos y no dentro de los archivos de configuracion. 


weather() {                                         # see https://github.com/chubin/wttr.in#one-line-output
  curl -f -s -m 2 'wttr.in?format=3' || printf '\n' # /!\ make sure curl is installed
  sleep 900                                         # sleep for 15 minutes, throttle network requests whatever the value of status-interval
}

online() {
  ping -c 1 1.1.1.1 >/dev/null 2>&1 && printf '✔' || printf '✘'
}

wan_ip_v4() {
  curl -f -s -m 2 -4 ifconfig.me
  sleep 300                                         # sleep for 5 minutes, throttle network requests whatever the value of status-interval
}

wan_ip_v6() {
  curl -f -s -m 2 -6 ifconfig.me
  sleep 300                                         # sleep for 5 minutes, throttle network requests whatever the value of status-interval
}

"$@"

