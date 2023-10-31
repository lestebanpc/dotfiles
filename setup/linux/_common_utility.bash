#!/bin/bash

#Inicialización Global {{{


#Colores principales usados para presentar información (menu,...)
g_color_opaque="\x1b[90m"
g_color_reset="\x1b[0m"
g_color_title="\x1b[32m"
g_color_subtitle="\x1b[36m"
g_color_info="\x1b[33m"
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




#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
#  - Cada repositorio tiene un ID interno del un repositorios y un identifificador realizar: 
#    ['internal-id']='external-id'
#  - Por ejemplo para el repositorio GitHub 'stedolan/jq', el item se tendria:
#    ['jq']='stedolan/jq'
declare -A gA_repositories=(
    )

#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
declare -a ga_menu_options_title=(
    )

#Menu dinamico: Repositorios de programas asociados asociados a una opciones del menu.
#  - Cada entrada define un opcion de menú. 
#  - Su valor es un cadena con ID de repositorios separados por comas.
declare -a ga_menu_options_repos=(
    )


#Parametros:
# 1 > Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
_get_length_menu_option() {
    
    local p_offset_option_index=$1

    local l_nbr_options=${#ga_menu_options_repos[@]}
    local l_max_digits_aux="$((1 << (p_offset_option_index + l_nbr_options)))"

    return ${#l_max_digits_aux}
}

#El menu dinamico muestra una opción de menú que es:
#   ([Correlativo]) [Etiquete del opción de menu] [Titulo de la opción de menu]: [Listado de los repositorio que se configurará]
#Parametros de entrada:
#  1> Etiqueta de la opción de menú. 
#     Texto que aparece al costado del opción ('Instalar o actualizar' o 'Desintalar')
#  2> Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
#  3> Numero maximo de digitos de una opción del menu personalizado.
#Variables de entrada
#  ga_menu_options_title > Listado titulos de una opción de menú.
#  ga_menu_options_repos > Listado de ID de repositorios configurados por una opción de menú.
#  gA_repositories       > Diccionario de identificadores de repositorios configurados por una opción de menú.  
_show_dynamic_menu() {

    #Argumentos
    local p_option_tag=$1
    local p_offset_option_index=$2
    local p_max_digits=$3


#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas

    #Espacios vacios al inicio del menu
    local l_empty_space
    local l_aux=$((8 + p_max_digits))
    printf -v l_empty_space ' %.0s' $(seq $l_aux)

    #Recorreger las opciones dinamicas del menu personalizado
    local l_i=0
    local l_j=0
    local IFS=','
    local la_repos
    local l_option_value
    local l_n
    local l_repo_names
    local l_repo_id



    for((l_i=0; l_i < ${#ga_menu_options_repos[@]}; l_i++)); do

        #Si no tiene repositorios a instalar, omitirlos
        l_option_value=$((1 << (p_offset_option_index + l_i)))

        l_aux="${ga_menu_options_repos[$l_i]}"
        #if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
        #    printf "     (%b%0${p_max_digits}d%b) %s\n" "$g_color_title" "$l_option_value" "$g_color_reset" "${ga_menu_options_title[$l_i]}"
        #    continue
        #fi

        #Obtener los repositorios a configurar
        IFS=','
        la_repos=(${l_aux})
        IFS=$' \t\n'

        printf "     (%b%0${p_max_digits}d%b) %s \"%b%s%b\": " "$g_color_title" "$l_option_value" "$g_color_reset" \
               "$p_option_tag" "$g_color_title" "${ga_menu_options_title[$l_i]}" "$g_color_reset"

        l_n=${#la_repos[@]}
        if [ $l_n -gt 3 ]; then
            printf "\n${l_empty_space}"
        fi

        l_repo_names=''
        for((l_j=0; l_j < ${l_n}; l_j++)); do

            l_repo_id="${la_repos[${l_j}]}"
            l_aux="${gA_repositories[${l_repo_id}]}"
            if [ -z "$l_aux" ]; then
                l_aux="$l_repo_id"
            fi

            if [ $l_j -eq 0 ]; then
                l_repo_names="'${g_color_opaque}${l_aux}${g_color_reset}'" 
            else
                if [ $l_j -eq 6 ]; then
                    l_repo_names="${l_repo_names},\n${l_empty_space}'${g_color_opaque}${l_aux}${g_color_reset}'"
                else
                    l_repo_names="${l_repo_names}, '${g_color_opaque}${l_aux}${g_color_reset}'"
                fi
            fi

        done

        printf '%b\n' "$l_repo_names"

    done


}


