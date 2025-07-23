#!/bin/bash

#Constantes: Colores
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

#Expresiones regulares de sustitucion mas usuadas para las versiones
if [ -z "$g_regexp_sust_version1" ]; then
    #La version 'x.y.z' esta la inicio o despues de caracteres no numericos
    declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
fi



set_first_dns_server() {

    #De las interfaces de red xxx y la brigde, validar
    # - Validar que el primer DNS esta activo
    # - Validar que el current DNS no sea el primer servidor DNS de la lista de algunas interfaces de red
    #Si alguno de ellos no lo estan homologados, reiniciarlo para que vuelva a escoger el primer servidor DNS

    #Reiniciar
    printf 'Reiniciando el "%bDNS Resolver%b" (%bsudo systemctl restart systemd-resolved.service%b)...\n' \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    sudo systemctl restart systemd-resolved.service

    #Establecer los DNS a la interface brigde (copiar los DNS de la interface ....)
    sudo resolvectl dns br0 192.168.2.202 8.8.8.8 200.48.225.130


}
