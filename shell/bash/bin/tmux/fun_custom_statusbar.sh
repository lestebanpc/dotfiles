#!/bin/sh 

# Permite realizar personalizaciones de la barra de estado
# Permite definir variables personalizadas '#{foo}' que se define en la barra de estado usando las variables entorno de 
# 'tmux_conf_theme_status_left' y 'tmux_conf_theme_status_right'.
# Donde 'foo' es:
#   > Una funcion que devulve una cadena de texto que se ejecutara en modo backgrund.
#   > Si la funcion invoa algun servicio de la red, para no tener saturar el servicio use sleep:
#     sleep 900 (15 minutos)
#     sleep 300 (05 minutos)
#


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

