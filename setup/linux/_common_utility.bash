#!/bin/bash

#Inicialización Global {{{


#Colores principales usados para presentar información (menu,...)
g_color_opaque="\x1b[90m"
g_color_reset="\x1b[0m"
g_color_title="\x1b[32m"
g_color_subtitle="\x1b[36m"
g_color_warning="\x1b[31m"


#}}}

function show_message_nogitrepo() {

    echo "No existe los archivos necesarios, debera seguir los siguientes pasos:"
    echo "   1> Descargar los archivos del repositorio:"
    echo "      git clone https://github.com/lestebanpc/dotfiles.git ~/.files"
    echo "   2> Instalar comandos basicos:"
    echo "      chmod u+x ~/.files/setup/01_setup_commands.bash"
    echo "      ~/.files/setup/01_setup_commands.bash"
    echo "   3> Configurar el profile del usuario:"
    echo "      chmod u+x ~/.files/setup/02_setup_profile.bash"
    echo "      ~/.files/setup/02_setup_profile.bash"

    return 0
}

# Retorno:
#   0 - Se tiene los programas necesarios para iniciar la configuración
#   1 - No se tiene los programas necesarios para iniciar la configuración
function fulfill_preconditions1() {

    #¿Esta 'curl' instalado?
    local l_curl_version=$(curl --version 2> /dev/null)
    if [ -z "$l_curl_version" ]; then

        printf '\nERROR: CURL no esta instalado, debe instalarlo para descargar los artefactos a instalar/actualizar.\n'
        printf '%bBinarios: https://curl.se/download.html\n' "$g_color_opaque"
        printf 'Paquete Ubuntu/Debian:\n'
        printf '          apt-get install curl\n'
        printf 'Paquete CentOS/Fedora:\n'
        printf '          dnf install curl\n%b' "$g_color_reset"

        return 1
    fi

    l_curl_version=$(echo "$l_curl_version" | head -n 1 | sed "$g_regexp_version1")
    printf '%bCURL version       : (%s)%b\n\n' "$g_color_opaque" "$l_curl_version" "$g_color_reset"
    return 0

}

# Almacena temporalmente las credenciales del usuario para realizar sudo
# Retorno:
#   0 - No es root: se almaceno las credenciales
#   1 - No es root: no se pudo almacenar las credenciales.
#   2 - Es root: no requiere realizar sudo.
function storage_sudo_credencial() {

    #Determinar si es root
    local l_is_root=1
    if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
        l_is_root=0
    fi

    #03. Solicitar credenciales de administrador y almacenarlas temporalmente
    if [ $l_is_root -eq 0 ]; then
        return 2
    fi

    #echo "Se requiere alamcenar temporalmente su password"
    sudo -v
    if [ $? -ne 0 ]; then
        printf 'ERROR: Se requiere alamcenar temporalmente su credencial para realizar sudo ("sudo -v")\n\n'
        return 1
    fi
    printf '\n'
    return 0
}


# Elimina (caduca) las credenciales del usuario para realizar sudo
# Retorno:
#   0 - Se elimino las credencial en el storage temporal
#   1 - Es root, no requiere realizar sudo.
function clean_sudo_credencial() {

    #Determinar si es root
    local l_is_root=1
    if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
        l_is_root=0
    fi

    #Caducar las credecinales de root almacenadas temporalmente
    if [ $l_is_root -eq 0 ]; then
        return 1
    fi

    printf '\nCaducando el cache de temporal password de su "sudo"\n'
    sudo -k
    return 0
}


