#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

#Funciones de utilidad
. ~/.files/setup/linux/_common_utility.bash

#Variable global pero solo se usar localmente en las funciones
_g_tmp=""

#Determinar la clase del SO
#  00 - 10: Si es Linux
#           00 - Si es Linux generico
#           01 - Si es WSL2
#  11 - 20: Si es Unix
#  21 - 30: si es MacOS
#  31 - 40: Si es Windows
get_os_type 
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
#  00 : Distribución de Linux desconocido
#  01 : Ubuntu
#  02 : Fedora
if [ $g_os_type -le 10 ]; then
    _g_tmp=$(get_linux_type_id)
    declare -r g_os_subtype_id=$?
    declare -r g_os_subtype_name="$_g_tmp"
    _g_tmp=$(get_linux_type_version)
    declare -r g_os_subtype_version="$_g_tmp"
fi

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi

#Parametros (argumentos) basicos del script
gp_uninstall=1          #(0) Para instalar/actualizar
                        #(1) Para desintalar

#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución interactiva del script (muestra el menu).
                        #(1) Ejecución no-interactiva del script para instalar/actualizar un conjunto de respositorios
                        #(2) Ejecución no-interactiva del script para instalar/actualizar un solo repositorio

#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1

#Si la credenciales de sudo es abierto externamente.
#  1 - No se abrio externamente
#  0 - Se abrio externamente (solo se puede dar en una ejecución no-interactiva)
g_is_credential_storage_externally=1


#Valores de la opcion especiales del menu (no estan vinculado a un repositorio especifico):
# > Actualizar todos paquetes del sistema operativo (Opción 1 del arreglo del menu)
g_opt_update_installed_pckg=$((1 << 0))
# > Actualizar todos los repositorios instalados (Opción 2 del arreglo del menu)
g_opt_update_installed_repo=$((1 << 1))


#Menu dinamico: Offset del indice donde inicia el menu dinamico.
#               Generalmente el menu dinamico no inicia desde la primera opcion personalizado del menú.
g_offset_option_index_menu_install=2
g_offset_option_index_menu_uninstall=0


#Personalización: Variables a modificar.
. ~/.files/setup/linux/_setup_commands_custom_settings.bash

#Personalización: Funciones modificables para el instalador.
. ~/.files/setup/linux/_setup_commands_custom_logic.bash


#}}}


#Funciones genericas {{{

#Indica si un determinido repositorio se permite ser configurado (instalado/actualizado/desinstalado) en el sistema operativo actual
#Argumentos de entrada:
#  1 > ID del repositorio a configurar
#  2 > Flag '0' si es artefacto sera configurado en Windows (asociado a WSL2)
#Valor de retorno:
#  0 > Si el repositorio puede configurarse en este sistema operativo
_can_setup_repository_in_this_so() {

    #1. Argumentos
    local p_repo_id="$1"

    local p_install_win_cmds=1
    if [ "$2" = "0" ]; then
        p_install_win_cmds=0
    fi


    #2. Obtener las opciones de configuración del repositorio. 
    #  > Puede ser uno o la suma de los siguientes valores:
    #    1 (00001) Linux No-WSL2 (que no WSL2)
    #    2 (00010) Linux WSL2
    #    8 (00100) Windows vinculado al Linux WSL2
    #  > Si no se especifica, su valor es 11 (se instala en todo lo permitido.
    local l_repo_config=${gA_repo_config[${p_repo_id}]:-11}

    #3. Repositorios especiales que no deberia instalarse segun el tipo de distribución Linux
    local l_repo_can_setup=1  #(1) No debe configurarse, (0) Debe configurarse (instalarse/actualizarse)
    local l_flag
    if [ $p_install_win_cmds -ne 0 ]; then

        #Si es Linux
        if [ $g_os_type -ge 0 ] && [ $g_os_type -le 10 ]; then

            #Si es Linux WSL2
            if [ $g_os_type -eq 1 ]; then

                #Si se usa el flag '2' (Linux WSL2), configurarlo
                if [ $((l_repo_config & 2)) -eq 2 ]; then
                    l_repo_can_setup=0
                fi

            #Si es Linux No-WSL2
            else

                #Si se usa el flag '1' (Linux No-WSL2), configurarlo
                if [ $((l_repo_config & 1)) -eq 1 ]; then
                    l_repo_can_setup=0
                fi
            fi
            
        fi

    #4. Repositorios especiales que no deberia instalarse en Windows (siempre vinculado a un Linux WSL2)
    else


        #Si es Linux WSL2
        if [ $g_os_type -eq 1 ]; then

            #Si se usa el flag '8' (Windows vinculado al Linux WSL2), configurarlo
            if [ $((l_repo_config & 8)) -eq 8 ]; then
                l_repo_can_setup=0
            fi

        fi

    fi

    return $l_repo_can_setup

}


#Solo se invoca cuando se instala con exito un repositorio y sus artefactos
function _show_final_message() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_last_version_pretty="$2"
    local p_arti_version="$3"    
    local p_install_win_cmds=1         #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                       #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$4" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    #case "$p_repo_id" in
    #    fzf)

    #        ;;
    #    *)
    #        ;;
    #esac
   
    local l_empty_version

    local l_tag
    if [ ! -z "${p_repo_last_version_pretty}" ]; then
        l_tag="${p_repo_id}${g_color_opaque}[${p_repo_last_version_pretty}]"
    else
        printf -v l_empty_version ' %.0s' $(seq ${#_g_repo_current_version})
        l_tag="${p_repo_id}${g_color_opaque}[${l_empty_version}]"
    fi

    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}/[${p_arti_version}]${g_color_reset}"
    else
        l_tag="${l_tag}${g_color_reset}"
    fi
    
    printf 'Se ha concluido la configuración de los artefactos del repositorio "%b".\n' ${l_tag}

}



function _clean_temp() {

    #1. Argumentos
    local p_repo_id="$1"

    #2. Eliminar los archivos de trabajo temporales
    echo "Eliminado archivos temporales \"/tmp/${p_repo_id}\" ..."
    rm -rf "/tmp/${p_repo_id}"
}

function _download_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
    local p_repo_last_version_pretty="$4"
    declare -nr pnra_artifact_names=$5   #Parametro por referencia: Arreglo de los nombres de los artefactos
    local p_arti_version="$6"    


    #2. Descargar los artectos del repositorio
    local l_n=${#pnra_artifact_names[@]}

    local l_artifact_name
    local l_artifact_url
    local l_base_url
    local l_i=0
    local l_status=0

    mkdir -p "/tmp/${p_repo_id}"

    local l_tag="${p_repo_id}${g_color_opaque}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}[${p_arti_version}]${g_color_reset}"
    else
        l_tag="${l_tag}${g_color_reset}"
    fi

    for ((l_i=0; l_i<$l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_base_url=$(_get_last_repo_url "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$l_artifact_name" $p_install_win_cmds)
        l_artifact_url="${l_base_url}/${l_artifact_name}"
        printf '\nArtefacto "%b[%s]" a descargar - Name    : %s\n' "$l_tag" "${l_i}" "${l_artifact_name}"
        printf 'Artefacto "%b[%s]" a descargar - URL     : %s\n' "$l_tag" "${l_i}" "${l_artifact_url}"

        
        #Descargar la artefacto
        mkdir -p "/tmp/${p_repo_id}/${l_i}"

        printf "$g_color_opaque"
        curl -fLo "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" "$l_artifact_url"
        l_status=$?
        printf "$g_color_reset"

        if [ $l_status -eq 0 ]; then
            printf 'Artefacto "%b[%s]" descargado en         : "/tmp/%s/%s/%s"\n\n' "$l_tag" "${l_i}" "${p_repo_id}" "${l_i}" "${l_artifact_name}"
        else
            printf 'Artefacto "%b[%s]" no se pudo descargar  : ERROR(%s)\n\n' "$l_tag" "${l_i}" "${l_status}"
            return $l_status
        fi

    done

    return 0
}

function _install_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    declare -nr pnra_artifact_names=$3   #Parametro por referencia: Arreglo de los nombres de los artefactos
    declare -nr pnra_artifact_types=$4   #Parametro por referencia: Arreglo de los tipos de los artefactos

    local p_repo_current_version="$5"
    local p_repo_last_version="$6"
    local p_repo_last_version_pretty="$7"

    local p_arti_version="$8"    
    local p_arti_index=0
    if [[ "$9" =~ ^[0-9]+$ ]]; then
        p_arti_index=$9
    fi

    local p_install_win_cmds=1           #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                         #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "${10}" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    #2. Descargar los artectos del repositorio
    local l_n=${#pnra_artifact_names[@]}

    local l_artifact_name
    local l_artifact_type
    local l_i=0

    #3. Instalación de los artectactos
    local l_is_last=1
    local l_tmp=""
    mkdir -p "/tmp/${p_repo_id}"

    local l_tag="${p_repo_id}${g_color_opaque}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}[${p_arti_version}]${g_color_reset}"
    else
        l_tag="${l_tag}${g_color_reset}"
    fi

    for ((l_i=0; l_i<$l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_artifact_type="${pnra_artifact_types[$l_i]}"
        printf 'Artefacto "%b[%s]" a configurar - Name   : %s\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
        printf 'Artefacto "%b[%s]" a configurar - Type   : %s\n' "${l_tag}" "${l_i}" "${l_artifact_type}"


        if [ $l_i -eq $l_n ]; then
            l_is_last=0
        fi

        if [ $l_artifact_type -eq 2 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}"
            #tar -xvf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            tar -xf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%b[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.tar.gz}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%b[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 5 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}"
            #tar -xvf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            tar -xf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%b[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.tgz}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%b[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 4 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            l_tmp="${l_artifact_name%.gz}"
            printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") como el archivo "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}/${l_tmp}"
            gunzip -q "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            #gunzip "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            #rm -f "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%b[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_tmp}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%b[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 3 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}"
            #unzip "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -d "/tmp/${p_repo_id}/${l_i}"
            unzip -q "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -d "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%b[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.zip}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%b[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 0 ]; then

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%b[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            if [ $p_install_win_cmds -eq 0 ]; then
                _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.exe}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                    "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            else
                _copy_artifact_files "$p_repo_id" $l_i "$l_artifact_name" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                    "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            fi
            #l_status=0
            printf 'Artefacto "%b[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 1 ]; then

            if [ $g_os_subtype_id -ne 1 ]; then
                printf 'ERROR (%s): No esta permitido instalar el artefacto "%b[%s]" ("%s") en SO que no sean de familia Debian\n\n' "22" "${l_tag}" "${l_i}" "${l_artifact_name}"
                return 22
            fi

            #Instalar y/o actualizar el paquete si ya existe
            printf 'Instalando/Actualizando el paquete/artefacto "%b[%s]" ("%s") en el SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            if [ $g_is_root -eq 0 ]; then
                dpkg -i "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            else
                sudo dpkg -i "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            fi
            #l_status=0
            printf 'Artefacto "%b[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        else
            printf 'ERROR (%s): El tipo del artefacto "%b[%s]" ("%s") no esta implementado "%s"\n\n' "21" "${l_tag}" "${l_i}" "${l_artifact_name}" "${l_artifact_type}"
            return 21
        fi

    done

    return 0
}

function _install_repository_internal() { 

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_current_version="$3"
    local p_repo_last_version="$4"
    local p_repo_last_version_pretty="$5"

    local p_arti_version="$6"    
    local p_arti_index=0
    if [[ "$7" =~ ^[0-9]+$ ]]; then
        p_arti_index=$7
    fi

    local p_install_win_cmds=1            #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                          #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$8" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi
    #echo "p_repo_current_version = ${p_repo_current_version}"

    #4. Obtener el los artefacto que se instalaran del repositorio
    local l_tag="${p_repo_id}${g_color_opaque}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}[${p_arti_version}]${g_color_reset}"
    else
        l_tag="${l_tag}${g_color_reset}"
    fi

    
    #Vriables de referencias a arreglos que se crearan dentro de la funcion '_load_artifacts'
    local la_artifact_names
    local la_artifact_types
    _load_artifacts "$p_repo_id" "$p_repo_last_version" "$p_repo_last_version_pretty" la_artifact_names la_artifact_types "$p_arti_version" $p_install_win_cmds
    l_status=$?    
    if [ $l_status -ne 0 ]; then
        printf 'ERROR: No esta configurado correctamente los artefactos para el repositorio "%b"\n' ${l_tag}
        return 22
    fi

    #si el arreglo es vacio
    local l_n=${#la_artifact_names[@]}
    if [ $l_n -le 0 ]; then
        printf 'ERROR: No esta configurado correctamente los artefactos para el repositorio "%b".\n' ${l_tag}
        return 98
    fi
    printf 'Repositorio "%b" tiene "%s" artefactos.\n' ${l_tag} ${l_n}

    #si el tamano del los arrgelos no son iguales
    if [ $l_n -ne ${#la_artifact_types[@]} ]; then
        printf 'ERROR: No se ha definido todos los tipo de artefactos en el repositorio "%b".\n' ${l_tag}
        return 97
    fi    

    #5. Descargar el artifacto en la carpeta
    if ! _download_artifacts "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$p_repo_last_version_pretty" la_artifact_names "$p_arti_version"; then
        printf 'ERROR: No se ha podido descargar los artefactos del repositorio "%b".\n' ${l_tag}
        _clean_temp "$p_repo_id"
        return 23
    fi

    #6. Instalar segun el tipo de artefecto
    if ! _install_artifacts "${p_repo_id}" "${p_repo_name}" la_artifact_names la_artifact_types "${p_repo_current_version}" "${p_repo_last_version}" \
        "$p_repo_last_version_pretty" "$p_arti_version" $p_arti_index $p_install_win_cmds; then
        printf 'ERROR: No se ha podido instalar los artefecto de repositorio "%b".\n' ${l_tag}
        _clean_temp "$p_repo_id"
        return 24
    fi

    _show_final_message "$p_repo_id" "$p_repo_last_version_pretty" "$p_arti_version" $p_install_win_cmds
    _clean_temp "$p_repo_id"
    return 0

}

declare -a _ga_artifact_subversions
declare -a _g_repo_current_version

#Esta funcion solo imprime el titulo del repositorio cuando el valor de retorna es un valor diferente de 14.
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > Ultima version del repository
#  3 > Ultima version del repository (version amigable)
#  4 > Flag '0' si la unica configuración que puede realizarse es actualizarse (no instalarse) y siempre en cuando el repositorio esta esta instalado.
#  5 > Flag '0' si es artefacto instalado en Windows (asociado a WSL2).
#  6 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se instalará", "se actualizará" o "se configurará")
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#      Se usa "se configurará" si no se puede determinar si se instala o configura pero es necesario que se continue.
#
#Parametros de entrada (variables globales):
#    > '_ga_artifact_subversions' todas las subversiones definidas en la ultima version del repositorio 
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
# Si el repositorio puede instalarse devolverá de [0, 4]:
#    0 > El repositorio no esta instalado y su ultima versión disponible es valido.
#    1 > El repositorio no esta instalado pero su ultima versión disponible es invalido.
# Si el repositorio puede actualizarse devolverá de [5,9]:
#    5 > El repositorio esta desactualizado y su ultima version disponible es valido.
#    6 > El repositorio esta instalado pero su ultima versión disponible invalido.
#    7 > El repositorio tiene una versión actual invalido (la ultima verisón disponible puede ser valido e invalido).
# Si el repositorio NO se puede configurarse devolvera de [10, 99]:
#   10 > El repositorio ya esta instalado y actualizado (version actual es igual a la ultima).
#   11 > El repositorio ya esta instalado y actualizado (version actual es mayor a la ultima).
#   12 > El repositorio no puede determinarse su versión actual (la logica para obtener la version genero un error).
#   13 > El repositorio no tiene implamentado la logica para obtener la versión actual del repositorio.
#   14 > El repositorio no puede ser configurado, debido a que solo puede actualizarse los instalados y este repositorio esta instalado.
#
#Parametros de salida (variables globales):
#    > '_g_repo_current_version' retona la version actual del repositorio
#
_validate_versions_to_install() {

    #1. Argumentos
    local p_repo_id=$1

    local p_repo_last_version="$2"
    local p_repo_last_version_pretty="$3"

    local p_only_update_if_its_installed=1
    if [ "$4" = "0" ]; then
        p_only_update_if_its_installed=0
    fi

    local p_install_win_cmds=1
    if [ "$5" = "0" ]; then
        p_install_win_cmds=0
    fi

    local p_title_template="$6"

    #Inicialización
    _g_repo_current_version=""
    local l_empty_version
    printf -v l_empty_version ' %.0s' $(seq ${#l_repo_last_version_pretty})


    #2. Obtener la versión de repositorio instalado en Linux
    local l_repo_current_version=""
    local l_status=0
    l_repo_current_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "")
    l_status=$?          #(9) El repositorio unknown porque no se implemento la logica
                         #(3) El repositorio unknown porque no se puede obtener su versión (se desconoce si esta instaldo o no)
                         #(1) El repositorio no esta instalado 
                         #(0) El repositorio instalado, con version correcta
                         #(2) El repositorio instalado, con version incorrecta

    _g_repo_current_version="$l_repo_current_version"

    #Si la unica configuración que puede realizarse es actualizarse (no instalarse) y siempre en cuando el repositorio esta esta instalado.
    if [ $p_only_update_if_its_installed -eq 0 ] && [ $l_status -ne 0 ] && [ $l_status -ne 2 ]; then
        return 14        
    fi

    local l_repo_name_aux="${gA_packages[$p_repo_id]:-$p_repo_id}"


    #3. Mostrar el titulo

    if [ ! -z "$p_title_template" ]; then

        print_line '-' $g_max_length_line  "$g_color_opaque"

        if [ $l_status -eq 0 -o $l_status -eq 2 ]; then
            printf "${p_title_template}\n" "se actualizará"
        elif [ $l_status -eq 1 ]; then
            printf "${p_title_template}\n" "se instalará"
        else
            printf "${p_title_template}\n" "se configurará"
        fi

        print_line '-' $g_max_length_line  "$g_color_opaque"

    fi


    if [ $p_install_win_cmds -eq 0 ]; then
        printf 'Analizando el repositorio "%s" en el %bWindows%b vinculado a este Linux WSL...\n' "$p_repo_id" "$g_color_subtitle" "$g_color_reset"
    fi


    #5. Mostar información de la versión actual.
    if [ $l_status -ne 0 ]; then
        printf 'Repositorio "%s%b[%s]%b" ' "${p_repo_id}" "$g_color_opaque" "${l_repo_current_version:-${l_empty_version}}" "$g_color_reset"
    fi

    if [ $l_status -eq 9 ]; then
        printf 'actual no tiene implamentado la logica para obtener la versión actual.\n'
    elif [ $l_status -eq 1 ]; then
        printf 'no esta instalado.\n'
    elif [ $l_status -eq 2 ]; then
        printf 'tiene una versión "%s" con formato invalido.\n' "$l_repo_current_version"
        l_repo_current_version=""
    elif [ $l_status -eq 3 ]; then
        printf 'ocurrio un error al obtener la versión actual "%s".\n' "$l_repo_current_version"
    #else
    #    printf 'esta instalado y tiene como versión actual "%s".\n' "${l_repo_current_version}"
    fi

    #4. Mostrar información de la ultima versión.
    printf 'Repositorio "%s%b[%s]%b" actual tiene la versión disponible "%s%b[%s]%b" (%s)\n' "${p_repo_id}" "$g_color_opaque" "${l_repo_current_version:-${l_empty_version}}" "$g_color_reset" \
            "${p_repo_id}" "$g_color_opaque" "${p_repo_last_version_pretty}" "$g_color_reset" "${p_repo_last_version}" 

    #Si el artefacto tiene Subversiones, mostrarlos.
    local l_artifact_subversions_nbr=${#_ga_artifact_subversions[@]} 
    if [ $l_artifact_subversions_nbr -ne 0 ]; then
        for ((l_n=0; l_n< ${l_artifact_subversions_nbr}; l_n++)); do
            printf 'Repositorio "%s%b[%s]%b" actual tiene la versión disponible "%s%b[%s]%b" con subversiones: Subversion[%s] es "%s"\n' "${p_repo_id}" "$g_color_opaque" "${l_repo_current_version:-${l_empty_version}}" "$g_color_reset" \
                   "${p_repo_id}" "$g_color_opaque" "${p_repo_last_version_pretty}" "$g_color_reset" "${l_n}" "${_ga_artifact_subversions[${l_n}]}"
        done
    fi



    #6. Evaluar los escenarios donde se obtiene una versión actual invalido.

    #Si no se tiene implementado la logica para obtener la version actual
    if [ $l_status -eq 9 ]; then
        echo "ERROR: Debe implementar la logica para determinar la version actual de repositorio instalado"

        return 13
    fi

    #Si no se puede obtener la version actual
    if [ $l_status -eq 2 ]; then
        printf 'Repositorio "%s" no se puede obtener la versión actual ("%s") por lo que no se puede compararla con la ultima versión "%s".\n' \
               "${p_repo_id}" "${l_repo_current_version}" "${p_repo_last_version_pretty}"

        return 12
    fi

    #Si obtuvo la version actual pero tiene formato invalido
    if [ $l_status -eq 3 ]; then
        printf 'Repositorio "%s" tiene como versión actual a "%s" con formato invalido por lo que no puede compararla con la ultima versión "%s".\n' \
               "${p_repo_id}" "${l_repo_current_version}" "${p_repo_last_version_pretty}"

        return 7
    fi

    #7. Evaluar los escenarios donde se obtiene una versión ultima invalido.
    if [ -z "$l_repo_last_version_pretty" ]; then
        printf 'Repositorio "%s" tiene como ultima versión disponible a "%s" la cual es un formato invalido para compararla con la versión actual "%s".\n' \
               "${p_repo_id}" "${l_repo_last_version}" "${l_repo_current_version}"

        if [ -z "${l_repo_current_version}" ]; then
            return 1
        fi

        return 6
    fi

    #8. Si no esta instalado, INICIAR su instalación.
    if [ -z "${l_repo_current_version}" ]; then

        printf 'Repositorio "%s%b[%s]%b" se instalará\n' "${p_repo_id}" "$g_color_opaque" "$l_empty_version" "$g_color_reset"
        return 0
    fi


    #9. Si esta instalado y se obtuvo un versión actual valida: comparar las versiones y segun ello, habilitar la actualización.
    compare_version "${l_repo_current_version}" "${p_repo_last_version_pretty}"
    l_status=$?

    #Si ya esta actualizado
    if [ $l_status -eq 0 ]; then

        printf 'Repositorio "%s%b[%s]%b" actual ya esta actualizado (= "%s")\n' "${p_repo_id}" "$g_color_opaque" "${l_repo_current_version}" "$g_color_reset" "${p_repo_last_version_pretty}"
        return 10

    elif [ $l_status -eq 1 ]; then

        printf 'Repositorio "%s%b[%s]%b" actual ya esta actualizado (> "%s")\n' "${p_repo_id}" "$g_color_opaque" "${l_repo_current_version}" "$g_color_reset" "${p_repo_last_version_pretty}"
        return 11

    fi

    #Si requiere actualizarse
    printf 'Repositorio "%s%b[%s]%b" se actualizará a la versión "%s"\n' "${p_repo_id}" "$g_color_opaque" "${l_repo_current_version}" "$g_color_reset" "${p_repo_last_version_pretty}"

    return 5


}

#Esta funcion siempre imprime el titulo del repositorio.
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > Flag '0' si es artefacto instalado en Windows (asociado a WSL2).
#  3 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se desinstalará".
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
# Si el repositorio puede actualizarse devolverá de [1,9]:
#    0 > El repositorio esta instalado.
#    1 > El repositorio esta instalado pero tiene una versión actual invalido.
# Si el repositorio NO se puede desintalarse [10, 99]:
#   10 > El repositorio no esta instalado.
#   11 > El repositorio no puede determinarse su versión actual (la logica para obtener la version genero un error).
#   12 > El repositorio no tiene implamentado la logica para obtener la versión actual del repositorio.
#
#Parametros de salida (variables globales):
#    > '_g_repo_current_version' retona la version actual del repositorio
#
_validate_versions_to_uninstall() {

    #1. Argumentos
    local p_repo_id=$1


    local p_install_win_cmds=1
    if [ "$2" = "0" ]; then
        p_install_win_cmds=0
    fi

    local p_title_template="$3"

    _g_repo_current_version=""


    #2. Obtener la versión de repositorio instalado en Linux
    local l_repo_current_version=""
    local l_status=0
    l_repo_current_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "")
    l_status=$?          #(9) El repositorio unknown porque no se implemento la logica
                         #(3) El repositorio unknown porque no se puede obtener su versión (se desconoce si esta instaldo o no)
                         #(1) El repositorio no esta instalado 
                         #(0) El repositorio instalado, con version correcta
                         #(2) El repositorio instalado, con version incorrecta

    _g_repo_current_version="$l_repo_current_version"


    local l_repo_name_aux="${gA_packages[$p_repo_id]:-$p_repo_id}"


    #3. Mostrar el titulo
    if [ ! -z "$p_title_template" ]; then

        print_line '-' $g_max_length_line  "$g_color_opaque"

        printf "${p_title_template}\n" "se desinstalará"

        print_line '-' $g_max_length_line  "$g_color_opaque"

    fi


    if [ $p_install_win_cmds -eq 0 ]; then
        printf 'Analizando el repositorio "%s" en el %bWindows%b vinculado a este Linux WSL...\n' "$p_repo_id" "$g_color_subtitle" "$g_color_reset"
    fi



    #5. Mostar información de la versión actual.
    local l_empty_version
    printf -v l_empty_version ' %.0s' $(seq 3)

    if [ $l_status -eq 9 ]; then
        printf 'Repositorio "%s%b[%s]%b" (Versión Actual): "%s"\n' "${p_repo_id}" "$g_color_opaque" "$l_empty_version" "$g_color_reset" "No implementado"
    elif [ $l_status -eq 1 ]; then
        printf 'Repositorio "%s%b[%s]%b" (Versión Actual): "%s"\n' "${p_repo_id}" "$g_color_opaque" "$l_empty_version" "$g_color_reset" "No instalado"
    elif [ $l_status -eq 2 ]; then
        printf 'Repositorio "%s%b[%s]%b" (Versión Actual): "%s"\n' "${p_repo_id}" "$g_color_opaque" "$l_repo_current_version" "$g_color_reset" "Formato invalido"
        l_repo_current_version=""
    elif [ $l_status -eq 3 ]; then
        printf 'Repositorio "%s%b[%s]%b" (Versión Actual): "%s"\n' "${p_repo_id}" "$g_color_opaque" "$l_repo_current_version" "$g_color_reset" "No se puede determinar"
    #else
    #    printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "OK"
    fi


    #6. Evaluar los escenarios donde se obtiene una versión actual invalido.

    #Si no se tiene implementado la logica para obtener la version actual
    if [ $l_status -eq 9 ]; then
        echo "ERROR: Debe implementar la logica para determinar la version actual de repositorio instalado"

        return 12
    fi

    #Si no se puede obtener la version actual
    if [ $l_status -eq 2 ]; then
        printf 'Repositorio "%s" no se puede obtener la versión actual ("%s").\n' \
               "${p_repo_id}" "${l_repo_current_version}"

        return 11
    fi

    #Si obtuvo la version actual pero tiene formato invalido
    if [ $l_status -eq 3 ]; then
        printf 'Repositorio "%s" su como versión actual a "%s" con formato invalido. Se desinstalará...\n' \
               "${p_repo_id}" "${l_repo_current_version}"

        return 1
    fi


    #8. Si no esta instalado, no se puede desinstalar.
    if [ -z "${l_repo_current_version}" ]; then

        printf 'Repositorio "%s%b[%s]%b" no esta instalado. No se desinstalará.\n' "${p_repo_id}" "$g_color_opaque" "$l_empty_version" "$g_color_reset"
        return 10
    fi


    #Si requiere actualizarse
    printf 'Repositorio "%s%b[%s]%b" (Versión Actual): Se desinstalará...\n' "${p_repo_id}" "$g_color_opaque" "${l_repo_current_version}" "$g_color_reset"
    return 0


}



#}}}


#Codigo principal del script {{{


#Un arreglo de asociativo cuyo key es el ID del repositorio hasta el momento procesados en el menu. El valor indica información del información de procesamiento.
#El procesamiento puede ser una configuración (instalación/actualización) o desinstalacíon.
#El valor almacenado para un repositorio es 'X|Y', donde:
#   X es el estado de la primera configuración y sus valores son:
#     . -1 > El repositorio aun no se ha se ha analizado (ni iniciado su proceso).
#     .  n > Los definidos por la variable '_g_install_repo_status' para una instalación/actualización o '_g_uninstall_repo_status' para una desinstalación.
#   Y Listado de indice relativo (de las opcion de menú) separados por espacios ' ' donde (hasta el momento) se usa el repositorio.
#     El primer indice es de la primera opción del menu que instala los artefactos. Los demas opciones no vuelven a instalar el artefacto
declare -A _gA_processed_repo=()



#
#El proceso de configuración (instalación/configuración) no es transaccional (no hay un rollback si hay un error) pero es idempotente (se puede reintar y solo 
#configura a los que falto configurar).
#Solo existe inicializacion y finalización para la configuración de repositorios Linux (en Windows, la configuración solo es copiar archivos, no se instala programas).
#
#Parametros de entrada (argumentos de entrada son):
#  1 > Opciones de menu ingresada por el usuario 
#  2 > Indice relativo de la opcion en el menú de opciones (inicia con 0 y solo considera el indice del menu dinamico).
#
#Parametros de entrada (variables globales):
#    > '_g_install_repo_status' indicadores que muestran el estado de la configuración (instalación/actualización) realizada.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > La opcion de menu se configuro con exito (se inicializo, se configuro los repositorios y se finalizo existosamente).
#    1 > No se inicio con la configuración de la opcion del menu (no se instalo, ni se se inicializo/finalizo).
#    2 > La inicialización de la opción no termino con exito.
#    3 > Alguno de lo repositorios fallo en configurarse (instalación/configuración). Ello provoca que se detiene el proceso (y no se invoca a la finalización).
#    4 > La finalización de la opción no termino con exito. 
#   98 > El repositorios vinculados a la opcion del menu no han sido configurados correctamente. 
#   99 > Argumentos ingresados son invalidos
#
#Parametros de salida (variables globales):
#    > '_gA_processed_repo' retona el estado de procesamiento de los repositorios hasta el momento procesados por el usuario. 
#           
function _install_menu_options() {

    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    local p_option_relative_idx=-1
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$2
    fi


    if [ $p_input_options -le 0 ] || [ $p_option_relative_idx -lt 0 ]; then
        return 99
    fi



    #1. Obtener los repositorios a configurar
    local l_aux="${ga_menu_options_packages[$p_option_relative_idx]}"
    #echo "Input: ${p_input_options} , Repos[${p_option_relative_idx}]: ${l_aux}"

    if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
        return 98
    fi

    local IFS=','
    local la_repos=(${l_aux})
    IFS=$' \t\n'

    local l_n=${#la_repos[@]}
    if [ $l_n -le 0 ]; then
        return 98
    fi


    #2. ¿La opción actual ha sido elejido para configurarse?
    local l_result       #0 > La opcion de menu se configuro con exito (se inicializo, se configuro los repositorios y se finalizo existosamente).
                         #1 > No se inicio con la inicialización ni la configuración la opcion del menu (no se instalo, ni se se inicializo/finalizo).
                         #2 > La inicialización de la opción termino con errores.
                         #3 > Alguno de los repositorios fallo en configurarse (instalación/configuración), se detiene el proceso (no se invoca a la finalización).
                         #4 > La finalización de la opción no termino con exito. 

    local l_option_value=$((1 << (p_option_relative_idx + g_offset_option_index_menu_install)))

    if [ $((p_input_options & l_option_value)) -ne $l_option_value ]; then 
        l_result=1
    fi
    #echo "l_result: ${l_result}"

    #3. Inicializar la opción del menu
    local l_status
    local l_title_template

    if [ -z "$l_result" ]; then
   
        #3.1. Mostrar el titulo
        print_line '─' $g_max_length_line  "$g_color_opaque"

        #Si se ejecuta en forma interactiva
        if [ $gp_type_calling -eq 0 ]; then
            printf -v l_title_template 'Opción %b%s%b: %b%s%b' "$g_color_opaque" "$l_option_value" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        #Si se ejecuta en forma no-interactiva
        else
            printf -v l_title_template 'Grupo de repositorios: %b%s%b' "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        fi

        print_text_in_center2 "$l_title_template" $g_max_length_line
        print_line '─' $g_max_length_line "$g_color_opaque"

        #3.2. Inicializar la opcion si aun no ha sido inicializado.
        install_initialize_menu_option $p_option_relative_idx
        l_status=$?

        #3.3. Si se inicializo no se realizo con exito.
        if [ $l_status -ne 0 ]; then

            printf 'No se ha completo la inicialización de la opción del menu elegida...\n'
            l_result=2

        fi

        printf '\n'

    fi


    #4. Recorriendo los los repositorios, opcionalmente procesarlo, y almacenando el estado en la variable '_gA_processed_repo'
    local l_status
    local l_repo_id
    local l_j
    local l_k

    local la_aux
    local la_previous_options_idx
    local l_status_first_setup
    local l_repo_name_aux
    local l_processed_repo
    local l_exits_error=1

    local l_flag_process_next_repo=1      #(0) Se debe intentar procesar (intalar/actualizar o desinstalar) los repositorio de la opción del menu.
                                          #(1) No se debe intentar procesar los repositorios de la opción del menú.
    if [ -z "$l_result" ]; then
        l_flag_process_next_repo=0
    fi

    for((l_j=0; l_j < ${l_n}; l_j++)); do

        #Nombre a mostrar del respositorio
        l_repo_id="${la_repos[$l_j]}"
        l_repo_name_aux="${gA_packages[${l_repo_id}]:-${l_repo_id}}"

        #4.1. Obtener el estado del repositorio antes de su instalación.
        l_aux="${_gA_processed_repo[$l_repo_id]:--1|}"
        
        IFS='|'
        la_aux=(${l_aux})
        IFS=$' \t\n'

        l_status_first_setup=${la_aux[0]}    #'g_install_repository' solo se puede mostrar el titulo del repositorio cuando ninguno de los estados de '_g_install_repo_status' es [0, 2].
                                             # -1 > El repositorio no se ha iniciado su analisis ni su proceso.
                                             #Estados de un proceso no iniciado:
                                             #  0 > El repositorio tiene parametros invalidos que impiden que se inicie el analisis para determinar si este repositorio se procesa o no ('g_install_repository' retorno 2 o 99).
                                             #  1 > El repositorio no esta habilitado para este SO.
                                             #  2 > El repositorio no puede configurarse debido a que no esta instalado y solo pueden hacerlo para actualizarse.
                                             #  3 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
                                             #  4 > El repositorio esta instalado y ya esta actualizado.
                                             #Estados de un proceso iniciado:
                                             #  5 > El repositorio inicio la instalación y lo termino con exito.
                                             #  6 > El repositorio inicio la actualización y lo termino con exito.
                                             #  7 > El repositorio inicio la instalación y lo termino con error.
                                             #  8 > El repositorio inicio la actualización y lo termino con error.

        la_previous_options_idx=(${la_aux[1]})
        l_title_template=""
        #echo "Index '${p_option_relative_idx}/${l_j}', RepoID '${l_repo_id}', ProcessThisRepo '${l_flag_process_next_repo}', FisrtSetupStatus '${l_status_first_setup}', PreviousOptions '${la_previous_options_idx[@]}'"

        #4.2. Si el repositorio ya ha pasado por el analisis para determinar si debe ser procesado o no
        if [ $l_status_first_setup -ne -1 ]; then

            #4.2.1. Almacenar la información del procesamiento.
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            #echo "A > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""

            #4.2.2. Si ya no se debe procesar mas repositorios de la opción del menú.
            if [ $l_flag_process_next_repo -ne 0 ]; then
                continue
            fi

            #4.2.3. No mostrar titulo, ni información alguna en los casos [0, 2]
            if [ $l_status_first_setup -ge 0 ] && [ $l_status_first_setup -le 2 ]; then
                continue
            fi

            #4.2.4. Calcular la plantilla del titulo.
            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no-interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
            fi

            #El primer repositorio donde se ha analizado si se puede o no ser procesado.
            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))

            #4.2.5. Mostrar el titulo y mensaje en los casos donde hubo error antes de procesarse y/o durante el procesamiento


            #Estados de un proceso no iniciado:
            #  3 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
            if [ $l_status_first_setup -eq 3 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" no se pudo obtener su versión cuando se analizó con la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  4 > El repositorio esta instalado y ya esta actualizado.
            elif [ $l_status_first_setup -eq 4 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" ya esta instalado y actualizado con la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #Estados de un proceso iniciado:
            #  5 > El repositorio inicio la instalación y lo termino con exito.
            elif [ $l_status_first_setup -eq 5 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" se acaba de instalar en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  6 > El repositorio inicio la actualización y lo termino con exito.
            elif [ $l_status_first_setup -eq 6 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de actualizar"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" se acaba de actualizar en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  7 > El repositorio inicio la instalación y lo termino con error.
            elif [ $l_status_first_setup -eq 7 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar con error"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" se acaba de instalar con error en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  8 > El repositorio inicio la actualización y lo termino con error.
            elif [ $l_status_first_setup -eq 8 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar con error"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" se acaba de instalar con error en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            fi

            continue

        fi


        #4.3. Si es la primera vez que se configurar (el repositorios de la opción del menu), inicie la configuración

        #Si no se debe procesar mas repositorios de la opción del menú.
        if [ $l_flag_process_next_repo -ne 0 ]; then
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            continue
        fi

        if [ -z "$l_title_template" ]; then

            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no-interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
            fi
        fi
        
        g_install_repository "$l_repo_id" "$l_title_template" 1 
        l_status=$?   #'g_install_repository' solo se puede mostrar el titulo del repositorio cuando retorna [0, 1] y ninguno de los estados de '_g_install_repo_status' sea [0, 2].
                      # 0 > Se inicio la configuración (en por lo menos uno de los 2 SO Linux o Windows).
                      #     Para ver detalle del estado ver '_g_install_repo_status'.
                      # 1 > No se inicio la configuración del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
                      #     Para ver detalle del estado ver '_g_install_repo_status'.
                      # 2 > No se puede obtener la ultima versión del repositorio o la versión obtenida no es valida.
                      #99 > Argumentos ingresados son invalidos.

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

        #4.4. Si no se inicio el analisis para evaluar si se debe dar el proceso de configuración: 

        #4.4.1. Si se envio parametros incorrectos
        if [ $l_status -eq 99 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del repositorio "%s"%b debido a los parametros incorrectos enviados.\n' \
                          "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi

        #4.4.2. Si no se pudo obtener la ultima versión del repositorio
        if [ $l_status -eq 2 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del repositorio "%s"%b debido su ultima versión obtenida es invalida.\n' \
                   "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

            #echo "C > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #4.4.3. Si el repositorio no esta permitido procesarse en ninguno de los SO (no esta permitido para ser instalado en SO).
        if [ ${_g_install_repo_status[0]} -le 1 ] && [ ${_g_install_repo_status[1]} -le 1 ]; then

            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"

            #echo "E > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi 

        #4.5. Si se inicio el pocesamiento del repositorio en Linux o en Windows.

        #4.5.1. Obtener el status del procesamiento principal del repositorio
        if [ ${_g_install_repo_status[0]} -gt 1 ] && [ ${_g_install_repo_status[1]} -le 1 ]; then
            #Si solo este permitido iniciar su proceso en Linux.
            l_processed_repo=${_g_install_repo_status[0]}
            l_aux="Linux '${g_os_subtype_name}'"
        elif [ ${_g_install_repo_status[0]} -le 1 ] && [ ${_g_install_repo_status[1]} -gt 1 ]; then
            #Si solo este permitido iniciar su proceso en Windows.
            l_processed_repo=${_g_install_repo_status[1]}
            l_aux="Windows vinculado a su Linux WSL '${g_os_subtype_name}')"
        else
            #Si esta permitido iniciar el procesa tanto el Linux como en Windows (solo se considera como estado de Linux. El Windows es opcional y pocas veces usado).
            l_processed_repo=${_g_install_repo_status[0]}
            l_aux="Linux WSL '${g_os_subtype_name}' (o su Windows vinculado)"
        fi

        #4.5.2. Almacenar la información del procesamiento
        la_previous_options_idx+=(${p_option_relative_idx})
        _gA_processed_repo["$l_repo_id"]="${l_processed_repo}|${la_previous_options_idx[@]}"
        #echo "F > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""

        #4.5.3. Mostrar información adicional

        #A. Estados de un proceso no iniciado:
        #   2 > El repositorio no puede configurarse debido a que no esta instalado y solo pueden hacerlo para actualizarse.
        if [ $l_processed_repo -eq 2 ]; then
            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            continue

        #   3 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
        elif [ $l_processed_repo -eq 3 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al obtener la versión actual%b del respositorio "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

        #   4 > El repositorio esta instalado y ya esta actualizado.
        elif [ $l_processed_repo -eq 4 ]; then
            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            printf '\n'

        #B. Estados de un proceso iniciado:
        #   5 > El repositorio inicio la instalación y lo termino con exito.
        elif [ $l_processed_repo -eq 5 ]; then
            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            printf '\n'

        #   6 > El repositorio inicio la actualización y lo termino con exito.
        elif [ $l_processed_repo -eq 6 ]; then
            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            printf '\n'

        #   7 > El repositorio inicio la instalación y lo termino con error.
        elif [ $l_processed_repo -eq 7 ]; then
            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al instalar el respositorio%b "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

        #   8 > El repositorio inicio la actualización y lo termino con error.
        elif [ $l_processed_repo -eq 8 ]; then
            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al actualizar el respositorio%b "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'
        fi


    done

    #Establecer el estado despues del procesamiento
    if [ -z "$l_result" ]; then
    
        #Si se inicio la configuración de algun repositorio y se obtuvo error
        if [ $l_exits_error -eq 0 ]; then
            l_result=3
        fi

    fi

    #5. Iniciar la finalización (solo si se proceso correctamente todos los repositorios de la opción de menú)
    if [ -z "$l_result" ]; then
   

        #5.1. Inicializar la opcion si aun no ha sido inicializado.
        install_finalize_menu_option $p_option_relative_idx
        l_status=$?

        #5.2. Si se inicializo con exito.
        if [ $l_status -eq 0 ]; then

            l_result=0

        else

            printf 'No se completo la finalización de la opción del menu ...\n'
            l_result=4

        fi


    fi

    return $l_result

}

#
#
#Parametros de entrada (argumentos de entrada son):
#
#Parametros de entrada (variables globales):
#    > '_gA_processed_repo' diccionario el estado de procesamiento de los repositorios hasta el momento procesados por el usuario.
#    > 'gA_packages' listado de repositorios.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > Resultado exitoso. 
#   99 > Argumentos ingresados son invalidos.
#
#Parametros de salida (variables globales):
#           
function _update_installed_repository() {

    #A. Argumentos

    #B. Inicialización
    local l_repo_id
    local l_repo_name_aux
    local l_title_template
    #local la_previous_options_idx
    local l_status_first_setup
    local l_processed_repo

    #local l_flag_process_next_repo
    local l_exits_error=1

    local l_aux
    local la_aux
    local l_i=1


    #C. Mostrar el titulo
    print_line '─' $g_max_length_line  "$g_color_opaque"
    
    #Si se ejecuta en forma interactiva
    if [ $gp_type_calling -eq 0 ]; then
        printf -v l_title_template 'Opción %b%s%b: %bActualizando repositorios instalados%b' "$g_color_opaque" "$g_opt_update_installed_repo" "$g_color_reset" "$g_color_subtitle" \
           "$g_color_reset"
    #Si se ejecuta en forma no-interactiva
    else
        printf -v l_title_template 'Grupo de respositorios: %bActualizando repositorios instalados%b' "$g_color_subtitle" \
           "$g_color_reset"
    fi
    print_text_in_center2 "$l_title_template" $g_max_length_line 
    print_line '─' $g_max_length_line "$g_color_opaque"
    printf '\n'

    #D. Actualizar los repositorios actualizados
    for l_repo_id in ${!_gA_processed_repo[@]}; do


         #1. Obtener el estado del repositorio antes de su instalación.
         l_aux="${_gA_processed_repo[$l_repo_id]:--1|}"
         
         IFS='|'
         la_aux=(${l_aux})
         IFS=$' \t\n'

         l_status_first_setup=${la_aux[0]}    #'g_install_repository' solo se puede mostrar el titulo del repositorio cuando ninguno de los estados de '_g_install_repo_status' es [0, 2].
                                              # -1 > El repositorio no se ha iniciado su analisis ni su proceso.
                                              #Estados de un proceso no iniciado:
                                              #  0 > El repositorio tiene parametros invalidos que impiden que se inicie el analisis para determinar si este repositorio se procesa o no ('g_install_repository' retorno 2 o 99).
                                              #  1 > El repositorio no esta habilitado para este SO.
                                              #  2 > El repositorio no puede configurarse debido a que no esta instalado y solo pueden hacerlo para actualizarse.
                                              #  3 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
                                              #  4 > El repositorio esta instalado y ya esta actualizado.
                                              #Estados de un proceso iniciado:
                                              #  5 > El repositorio inicio la instalación y lo termino con exito.
                                              #  6 > El repositorio inicio la actualización y lo termino con exito.
                                              #  7 > El repositorio inicio la instalación y lo termino con error.
                                              #  8 > El repositorio inicio la actualización y lo termino con error.

        #la_previous_options_idx=(${la_processed_repo_info[1]})
        l_title_template=""
        #echo "RepoID '${l_repo_id}', FisrtSetupStatus '${l_status_first_setup}', PreviousOptions '${la_previous_options_idx[@]}'"

        #2. Solo iniciar la configuración con lo repositorios que no se han iniciado su configuración
        if [ $l_status_first_setup -eq -1 ]; then

            #2.1. Valores iniciales
            l_repo_name_aux="${gA_packages[${l_repo_id}]:-${l_repo_id}}"


            #B.2. Calcular la plantilla del titulo.
            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$l_i" "$g_color_reset" "$g_color_subtitle" \
                   "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_opt_update_installed_repo" "$g_color_reset"
            #Si se ejecuta en forma no-interactiva
            else
                printf -v l_title_template "%s(%s)%s> El repositorio '%s%s%s' %s%%s%s" "$g_color_opaque" "$l_i" "$g_color_reset" "$g_color_subtitle" \
                   "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
            fi

            #Configurar el respositorio, con el flag 'solo actulizar si esta instalado'
            g_install_repository "$l_repo_id" "$l_title_template" 0
            l_status=$?   #'g_install_repository' solo se puede mostrar el titulo del repositorio cuando retorna [0, 1] y ninguno de los estados de '_g_install_repo_status' sea [0, 2].
                          # 0 > Se inicio la configuración (en por lo menos uno de los 2 SO Linux o Windows).
                          #     Para ver detalle del estado ver '_g_install_repo_status'.
                          # 1 > No se inicio la configuración del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
                          #     Para ver detalle del estado ver '_g_install_repo_status'.
                          # 2 > No se puede obtener la ultima versión del repositorio o la versión obtenida no es valida.
                          #99 > Argumentos ingresados son invalidos.

            #Se requiere almacenar las credenciales para realizar cambios con sudo.
            if [ $l_status -eq 120 ]; then
                return 120
            fi

            #2.3. Si no se inicio el analisis para evaluar si se debe dar el proceso de configuración: 

            #2.3.1. Si se envio parametros incorrectos
            if [ $l_status -eq 99 ]; then

                #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
                #l_flag_process_next_repo=1
                l_exits_error=0

                #la_previous_options_idx+=(${p_option_relative_idx})
                #_gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

                printf '%bNo se pudo iniciar el procesamiento del repositorio "%s"%b debido a los parametros incorrectos enviados.\n' \
                              "$g_color_warning" "$l_repo_id" "$g_color_reset"
                printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'
                continue

            fi

            #2.3.2. Si no se pudo obtener la ultima versión del repositorio
            if [ $l_status -eq 2 ]; then

                #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
                #l_flag_process_next_repo=1
                l_exits_error=0

                #la_previous_options_idx+=(${p_option_relative_idx})
                #_gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

                printf '%bNo se pudo iniciar el procesamiento del repositorio "%s"%b debido su ultima versión obtenida es invalida.\n' \
                       "$g_color_warning" "$l_repo_id" "$g_color_reset"
                printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'
                continue
            fi

            #2.3.3. Si el repositorio no esta permitido procesarse en ninguno de los SO (no esta permitido para ser instalado en SO).
            if [ ${_g_install_repo_status[0]} -le 1 ] && [ ${_g_install_repo_status[1]} -le 1 ]; then

                #No se considera un error, continue con el procesamiento de los siguientes repositorios.
                #la_previous_options_idx+=(${p_option_relative_idx})
                #_gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
                continue
            fi 

            #2.4. Si se inicio el pocesamiento del repositorio en Linux o en Windows.

            #2.4.1. Obtener el status del procesamiento principal del repositorio
            if [ ${_g_install_repo_status[0]} -gt 1 ] && [ ${_g_install_repo_status[1]} -le 1 ]; then
                #Si solo este permitido iniciar su proceso en Linux.
                l_processed_repo=${_g_install_repo_status[0]}
                l_aux="Linux '${g_os_subtype_name}'"
            elif [ ${_g_install_repo_status[0]} -le 1 ] && [ ${_g_install_repo_status[1]} -gt 1 ]; then
                #Si solo este permitido iniciar su proceso en Windows.
                l_processed_repo=${_g_install_repo_status[1]}
                l_aux="Windows vinculado a su Linux WSL '${g_os_subtype_name}')"
            else
                #Si esta permitido iniciar el procesa tanto el Linux como en Windows (solo se considera como estado de Linux. El Windows es opcional y pocas veces usado).
                l_processed_repo=${_g_install_repo_status[0]}
                l_aux="Linux WSL '${g_os_subtype_name}' (o su Windows vinculado)"
            fi
                #Si termino sin errores cambiar al estado

            #la_previous_options_idx+=(${p_option_relative_idx})
            #_gA_processed_repo["$l_repo_id"]="${l_processed_repo}|${la_previous_options_idx[@]}"

            #2.4.2. Mostrar información adicional

            #A. Estados de un proceso no iniciado:
            #   2 > El repositorio no puede configurarse debido a que no esta instalado y solo pueden hacerlo para actualizarse.
            if [ $l_processed_repo -eq 2 ]; then
                #No se considera un error, continue con el procesamiento de los siguientes repositorios.
                continue

            #   3 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
            elif [ $l_processed_repo -eq 3 ]; then

                #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
                #l_flag_process_next_repo=1
                l_exits_error=0
                ((l_i++))

                printf '%bError al obtener la versión actual%b del respositorio "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
                printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'


            #   4 > El repositorio esta instalado y ya esta actualizado.
            elif [ $l_processed_repo -eq 4 ]; then
                #No se considera un error, continue con el procesamiento de los siguientes repositorios.
                ((l_i++))
                printf '\n'

            #B. Estados de un proceso iniciado:
            #   5 > El repositorio inicio la instalación y lo termino con exito.
            elif [ $l_processed_repo -eq 5 ]; then
                #No se considera un error, continue con el procesamiento de los siguientes repositorios.
                ((l_i++))
                printf '\n'

            #   6 > El repositorio inicio la actualización y lo termino con exito.
            elif [ $l_processed_repo -eq 6 ]; then
                #No se considera un error, continue con el procesamiento de los siguientes repositorios.
                ((l_i++))
                printf '\n'

            #   7 > El repositorio inicio la instalación y lo termino con error.
            elif [ $l_processed_repo -eq 7 ]; then
                #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
                #l_flag_process_next_repo=1
                l_exits_error=0
                ((l_i++))

                printf '%bError al instalar el respositorio%b "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
                printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

            #   8 > El repositorio inicio la actualización y lo termino con error.
            elif [ $l_processed_repo -eq 8 ]; then
                #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
                #l_flag_process_next_repo=1
                l_exits_error=0
                ((l_i++))

                printf '%bError al actualizar el respositorio%b "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
                printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'
            fi

        fi

    done


}


#Es un arreglo con 2 valores enteros, el primero es el estado de la desinstalación en Linux, el segundo es el estado de la desinstalación en Windows.
#'i_uninstall_repository' solo se puede mostrar el titulo del repositorio cuando ninguno de los estados de '_g_uninstall_repo_status' es [0, 1].
#Cada estado puede tener uno de los siguiente valores: 
# Estados de un proceso no se ha iniciado:
#  0 > El repositorio tiene parametros invalidos que impiden que se inicie el analisis para determinar si este repositorio se procesa o no ('i_uninstall_repository' retorno 2 o 99).
#  1 > El repositorio no esta habilitado para este SO.
#  2 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
#  3 > El repositorio no esta instalado.
# Estados de un proceso iniciado:
#  4 > El repositorio inicio la desinstalación y lo termino con exito.
#  5 > El repositorio inicio la desinstalación y lo termino con error.
declare -a _g_uninstall_repo_status



#
#Permite desinstalar un repositorio en Linux (incluyendo a Windows vinculado a un Linux WSL)
#Un repositorio o se configura en Linux o Windows del WSL o ambos.
#'i_uninstall_repository' nunca se muestra con el titulo del repositorio cuando retorna 99 y 2. 
#'i_uninstall_repository' solo se puede mostrar el titulo del repositorio cuando retorno [0, 1] y ninguno de los estados de '_g_uninstall_repo_status' es [0, 1].
#
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se desconfigurará"). 
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > Se inicio la desinstalacíon (en por lo menos uno de los 2 SO o Windows)
#        Para ver el estado ver '_g_uninstall_repo_status'.
#    1 > No se inicio la desinstalacíon del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
#        Para ver el estado ver '_g_uninstall_repo_status'.
#   99 > Argumentos ingresados son invalidos
#
#Parametros de salida (variables globales):
#    > '_g_uninstall_repo_status' retorna indicadores que indican el estado de la desinstalacíon realizada.
#           
function i_uninstall_repository() {

    #1. Argumentos 
    local p_repo_id="$1"
    local p_repo_title_template="$2"


    #2. Valores iniciales
    local l_status
    #local l_repo_name="${gA_packages[$p_repo_id]}"
    #local l_repo_name_aux="${l_repo_name:-$p_repo_id}"
    
    _g_uninstall_repo_status=(0 0)


    #4. Iniciar la configuración en Linux: 
    local l_aux
    local l_status2
    local l_tag
    
    #4.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    local l_install_win_cmds=1
    local l_status_process_lnx     # Estados de un proceso no se ha iniciado:
                                   # Estados de un proceso no se ha iniciado:
                                   #  0 > El repositorio tiene parametros invalidos que impiden que se inicie el analisis para determinar si este repositorio se procesa o no ('i_uninstall_repository' retornó 99).
                                   #  1 > El repositorio no esta habilitado para este SO.
                                   #  2 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
                                   #  3 > El repositorio no esta instalado.
                                   # Estados de un proceso iniciado:
                                   #  4 > El repositorio inicio la desinstalación y lo termino con exito.
                                   #  5 > El repositorio inicio la desinstalación y lo termino con error.

    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?


    #Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then

        #4.2. Validar la versión actual para poder desinstalar el repositorio.
        _validate_versions_to_uninstall "$p_repo_id" $l_install_win_cmds "$p_repo_title_template"
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede actualizarse devolverá de [1,9]:
                       #    0 > El repositorio esta instalado.
                       #    1 > El repositorio esta instalado pero tiene una versión actual invalido.
                       #Si el repositorio NO se puede desintalarse [10, 99]:
                       #   10 > El repositorio no esta instalado.
                       #   11 > El repositorio no puede determinarse su versión actual (la logica para obtener la version genero un error).
                       #   12 > El repositorio no tiene implamentado la logica para obtener la versión actual del repositorio.


        #Establecer el estado del proceso que no seran procesados (instalados/actualizados)
        if [ $l_status -eq 11 ] || [ $l_status -eq 12 ]; then
            l_status_process_lnx=2
        elif [ $l_status -eq 10 ]; then
            l_status_process_lnx=3
        fi

        #¿El titulo se debe mostrar en la instalacion de Windows? 
        #'_validate_versions_to_uninstall' siempre muestra un titulo e información.
        if [ ! -z "$p_repo_title_template" ]; then
            #Si ya se mostro no hacerlo nuevamente
            p_repo_title_template=""
        fi
            
        #4.3. Instalar el repositorio
        if [ -z "$l_status_process_lnx" ]; then

            #Por defecto considerando que termino con error
            l_status_process_lnx=5
            l_tag="${l_tag}${g_color_opaque}[${_g_repo_current_version}]${g_color_reset}"
            printf '\nIniciando la %s de los artefactos del repositorio "%b" en Linux "%s" ...\n' "desinstalación" "${l_tag}" "$g_os_subtype_name"
            _uninstall_repository "$p_repo_id" "$_g_repo_current_version" $l_install_win_cmds
            l_status2=$?

            #Si termino sin errores cambiar al estado
            l_status_process_lnx=4

        fi

    else

        l_status_process_lnx=1

    fi

    #Mostrar el status de la instalacion en Linux
    _g_install_repo_status[0]=$l_status_process_lnx

    #5. Iniciar la configuración en Windows:
    local l_status_process_win
    l_install_win_cmds=0
    

    #5.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?

    #Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then


        if [ $l_status_process_lnx -ge 2 ]; then
            printf "\n\n"
        fi

        #5.2. Validar la versión actual para poder desinstalar el repositorio.
        _validate_versions_to_uninstall "$p_repo_id" $l_install_win_cmds "$p_repo_title_template"
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede actualizarse devolverá de [1,9]:
                       #    0 > El repositorio esta instalado.
                       #    1 > El repositorio esta instalado pero tiene una versión actual invalido.
                       #Si el repositorio NO se puede desintalarse [10, 99]:
                       #   10 > El repositorio no esta instalado.
                       #   11 > El repositorio no puede determinarse su versión actual (la logica para obtener la version genero un error).
                       #   12 > El repositorio no tiene implamentado la logica para obtener la versión actual del repositorio.


        #Establecer el estado del proceso que no seran procesados (instalados/actualizados)
        if [ $l_status -eq 11 ] || [ $l_status -eq 12 ]; then
            l_status_process_win=2
        elif [ $l_status -eq 10 ]; then
            l_status_process_win=3
        fi
            
        #5.3. Instalar el repositorio
        if [ -z "$l_status_process_lnx" ]; then

            #Por defecto considerando que termino con error
            l_status_process_win=5

            l_tag="${l_tag}${g_color_opaque}[${_g_repo_current_version}]${g_color_reset}"
            printf '\nIniciando la %s de los artefactos del repositorio "%b" en Windows vinculado a Linux "%s" ...\n' "desinstalación" "${l_tag}" "$g_os_subtype_name"
            _uninstall_repository "$p_repo_id" "$_g_repo_current_version" $l_install_win_cmds
            l_status2=$?

            #Si termino sin errores cambiar al estado
            l_status_process_win=4

        fi


    else

        l_status_process_win=1

    fi

    #Mostrar el status de la instalacion en Linux
    _g_install_repo_status[1]=$l_status_process_win

    #Si no se llego a iniciar el proceso de configuración en ninguno de los 2 sistemas operativos
    if [ $l_status_process_lnx -lt 4 ] && [ $l_status_process_win -lt 4 ]; then
        return 1
    fi

    return 0



}


#
#Parametros de entrada (argumentos de entrada son):
#  1 > Opciones de menu ingresada por el usuario 
#  2 > Indice relativo de la opcion en el menú de opciones (inicia con 0 y solo considera el indice del menu dinamico).
#
#Parametros de entrada (variables globales):
#    > '_g_uninstall_repo_status' indicadores que muestran el estado de la configuración (instalación/actualización) realizada.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > La opcion de menu se desintaló con exito (se inicializo, se configuro los repositorios y se finalizo existosamente).
#    1 > No se ha inicio la desinstalacíon de la opcion del menu debido a que no se cumple las precondiciones requeridas (no se desintaló, ni se se inicializo/finalizo).
#    2 > La inicialización de la opción no termino con exito.
#    3 > Alguno de lo repositorios fallo en desinstalacíon. Ello provoca que se detiene el proceso (y no se invoca a la finalización).
#    4 > La finalización de la opción no termino con exito. 
#   98 > El repositorios vinculados a la opcion del menu no tienen parametros configurados correctos. 
#   99 > Argumentos ingresados son invalidos
#
#Parametros de salida (variables globales):
#    > '_gA_processed_repo' retona el estado de procesamiento de los repositorios hasta el momento procesados por el usuario. 
#           
function _uninstall_menu_options() {

    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    local p_option_relative_idx=-1
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$2
    fi


    if [ $p_input_options -le 0 ]; then
        return 99
    fi


    #1. Obtener los repositorios a configurar
    local l_aux="${ga_menu_options_packages[$p_option_relative_idx]}"

    if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
        return 98
    fi

    local IFS=','
    local la_repos=(${l_aux})
    IFS=$' \t\n'

    local l_n=${#la_repos[@]}
    if [ $l_n -le 0 ]; then
        return 98
    fi


    #2. ¿La opción actual ha sido elejido para configurarse?
    local l_result       #0 > La opcion de menu se desintaló con exito (se inicializo, se configuro los repositorios y se finalizo existosamente).
                         #1 > No se inicio la inicialización ni la desinstalacíon de la opcion del menu (no se desintaló, ni se se inicializo/finalizo).
                         #2 > La inicialización de la opción no termino con exito.
                         #3 > Alguno de lo repositorios fallo en desinstalacíon. Ello provoca que se detiene el proceso (y no se invoca a la finalización).
                         #4 > La finalización de la opción no termino con exito. 

    local l_option_value=$((1 << (p_option_relative_idx + g_offset_option_index_menu_uninstall)))

    if [ $((p_input_options & l_option_value)) -ne $l_option_value ]; then
        #No inicializar ni instalar
        l_result=1 
    fi

    #echo "index: ${p_option_relative_idx}, input: ${p_input_options}, value: ${l_option_value}"

    #3. Inicializar la opción del menu
    local l_status
    local l_title_template

    if [ -z "$l_result" ]; then
   
        #3.1. Mostrar el titulo
        print_line '─' $g_max_length_line  "$g_color_opaque"

        #Si se ejecuta en forma interactiva
        if [ $gp_type_calling -eq 0 ]; then
            printf -v l_title_template "Opción %s%s%s '%s%s%s'" "$g_color_opaque" "$l_option_value" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        #Si se ejecuta en forma no-interactiva
        else
            printf -v l_title_template "Grupo de respositorios: '%s%s%s'" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        fi

        print_text_in_center2 "$l_title_template" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"

        #3.2. Inicializar la opcion si aun no ha sido inicializado.
        uninstall_initialize_menu_option $p_option_relative_idx
        l_status=$?

        #3.3. Si se inicializo con error (cancelado por el usuario u otro error) 
        if [ $l_status -ne 0 ]; then

            printf 'No se ha completo la inicialización de la opción del menu elegida...\n'
            l_result=2

        fi

        printf '\n'

    fi


    #4. Recorriendo todos los repositorios, opcionalmente procesarlo, y almacenando el estado en la variable '_gA_processed_repo'
    local l_status
    local l_repo_id
    local l_j
    local l_k

    local la_aux
    local la_previous_options_idx
    local l_status_first_setup
    local l_repo_name_aux
    local l_processed_repo
    local l_exits_error=1

    local l_flag_process_next_repo=1      #(0) Se debe intentar procesar (intalar/actualizar o desinstalar) los repositorio de la opción del menu.
                                          #(1) No se debe intentar procesar los repositorios de la opción del menú.
    if [ -z "$l_result" ]; then
        l_flag_process_next_repo=0
    fi

    #Se desintanla en orden inverso a la instalación
    for((l_j=(l_n-1); l_j >= 0; l_j--)); do

        #Nombre a mostrar del respositorio
        l_repo_id="${la_repos[$l_j]}"
        l_repo_name_aux="${gA_packages[$l_repo_id]:-$l_repo_id}"

        #4.1. Obtener el estado del repositorio antes de su instalación.
        l_aux="${_gA_processed_repo[$l_repo_id]:--1|}"
        
        IFS='|'
        la_aux=(${l_aux})
        IFS=$' \t\n'

        l_status_first_setup=${la_aux[0]}    #'i_uninstall_repository' solo se puede mostrar el titulo del repositorio cuando ninguno de los estados de '_g_uninstall_repo_status' es [0, 1].
                                             # -1 > El repositorio no se ha iniciado su analisis ni su proceso.
                                             #Estados de un proceso no se ha iniciado:
                                             #  0 > El repositorio tiene parametros invalidos que impiden que se inicie el analisis para determinar si este repositorio se procesa o no ('i_uninstall_repository' retorno 99).
                                             #  1 > El repositorio no esta habilitado para este SO.
                                             #  2 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
                                             #  3 > El repositorio no esta instalado.
                                             #Estados de un proceso iniciado:
                                             #  4 > El repositorio inicio la desinstalación y lo termino con exito.
                                             #  5 > El repositorio inicio la desinstalación y lo termino con error.

        la_previous_options_idx=(${la_aux[1]})
        l_title_template=""
        #echo "Index '${p_option_relative_idx}/${l_j}', RepoID '${l_repo_id}', ProcessThisRepo '${l_flag_process_next_repo}', FisrtSetupStatus '${l_status_first_setup}', PreviousOptions '${la_previous_options_idx[@]}'"

        #4.2. Si el repositorio ya ha pasado por el analisis para determinar si debe ser procesado o no
        if [ $l_status_first_setup -ne -1 ]; then

            #4.2.1. Almacenar la información del procesamiento.
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            #echo "A > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""

            #4.2.2. Si ya no se debe procesar mas repositorios de la opción del menú.
            if [ $l_flag_process_next_repo -ne 0 ]; then
                continue
            fi

            #4.2.3. No mostrar titulo, ni información alguna en los casos [0, 1]
            if [ $l_status_first_setup -ge 0 ] && [ $l_status_first_setup -le 1 ]; then
                continue
            fi

            #4.2.4. Calcular la plantilla del titulo.
            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no-interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
            fi

            #El primer repositorio donde se ha analizado si se puede o no ser procesado.
            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))

            #4.2.5. Mostrar el titulo y mensaje en los casos donde hubo error antes de procesarse y/o durante el procesamiento


            #Estados de un proceso no iniciado:
            #  2 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
            if [ $l_status_first_setup -eq 2 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" no se pudo obtener su versión cuando se analizó con la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #  3 > El repositorio no esta instalado.
            elif [ $l_status_first_setup -eq 3 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "no procesado"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" no esta instalado, ello se determino con la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            #Estados de un proceso iniciado:
            #  4 > El repositorio inicio la desinstalación y lo termino con exito.
            elif [ $l_status_first_setup -eq 4 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" se acaba de desinstalar en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"


            #  5 > El repositorio inicio la desinstalación y lo termino con error.
            elif [ $l_status_first_setup -eq 5 ]; then

                print_line '-' $g_max_length_line "$g_color_opaque"
                printf "${l_title_template}\n" "se acaba de instalar con error"
                print_line '-' $g_max_length_line "$g_color_opaque"

                printf 'El repositorio "%s" se acaba de desinstalar con error en la opción del menu %s ("%s")\n\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"


            fi

            continue

        fi


        #4.3. Si es la primera vez que se configurar (el repositorios de la opción del menu), inicie la configuración

        #Si no se debe procesar mas repositorios de la opción del menú.
        if [ $l_flag_process_next_repo -ne 0 ]; then
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            continue
        fi

        if [ -z "$l_title_template" ]; then
            #Si se ejecuta en forma interactiva
            if [ $gp_type_calling -eq 0 ]; then
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"
            #Si se ejecuta en forma no-interactiva
            else
                printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
                      "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
            fi
        fi
        
        i_uninstall_repository "$l_repo_id" "$l_title_template" 
        l_status=$?   #'i_uninstall_repository' solo se puede mostrar el titulo del repositorio cuando retorna [0, 1] y ninguno de los estados de '_g_install_repo_status' sea [0, 1].
                      #    0 > Se inicio la desinstalacíon (en por lo menos uno de los 2 SO o Windows)
                      #        Para ver el estado ver '_g_uninstall_repo_status'.
                      #    1 > No se inicio la desinstalacíon del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
                      #        Para ver el estado ver '_g_uninstall_repo_status'.
                      #   99 > Argumentos ingresados son invalidos


        #4.4. Si no se inicio el analisis para evaluar si se debe dar el proceso de configuración: 

        #4.4.1. Si se envio parametros incorrectos
        if [ $l_status -eq 99 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"

            printf '%bNo se pudo iniciar el procesamiento del repositorio "%s"%b debido a los parametros incorrectos enviados.\n' \
                          "$g_color_warning" "$l_repo_id" "$g_color_reset"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi



        #4.4.3. Si el repositorio no esta permitido procesarse en ninguno de los SO (no esta permitido para ser instalado en SO).
        if [ ${_g_install_repo_status[0]} -le 1 ] && [ ${_g_install_repo_status[1]} -le 1 ]; then

            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"

            #echo "E > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi 

        #4.5. Si se inicio el pocesamiento del repositorio en Linux o en Windows.

        #4.5.1. Obtener el status del procesamiento principal del repositorio
        if [ ${_g_install_repo_status[0]} -gt 1 ] && [ ${_g_install_repo_status[1]} -le 1 ]; then
            #Si solo este permitido iniciar su proceso en Linux.
            l_processed_repo=${_g_install_repo_status[0]}

            l_aux="Linux '${g_os_subtype_name}'"
        elif [ ${_g_install_repo_status[0]} -le 1 ] && [ ${_g_install_repo_status[1]} -gt 1 ]; then
            #Si solo este permitido iniciar su proceso en Windows.
            l_processed_repo=${_g_install_repo_status[1]}
            l_aux="Windows vinculado a su Linux WSL '${g_os_subtype_name}')"
        else
            #Si esta permitido iniciar el procesa tanto el Linux como en Windows (solo se considera como estado de Linux. El Windows es opcional y pocas veces usado).
            l_processed_repo=${_g_install_repo_status[0]}
            l_aux="Linux WSL '${g_os_subtype_name}' (o su Windows vinculado)"
        fi

        #4.5.2. Almacenar la información del procesamiento
        la_previous_options_idx+=(${p_option_relative_idx})
        _gA_processed_repo["$l_repo_id"]="${l_processed_repo}|${la_previous_options_idx[@]}"
        #echo "F > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""


        #4.5.3. Mostrar información adicional

        #A. Estados de un proceso no iniciado:
        #   2 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
        if [ $l_processed_repo -le 2 ]; then

            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al obtener la versión actual%b del respositorio "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

        #   3 > El repositorio no esta instalado.
        elif [ $l_processed_repo -eq 3 ]; then
            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            printf '\n'

        #B. Estados de un proceso iniciado:
        #   4 > El repositorio inicio la desinstalación y lo termino con exito.
        elif [ $l_processed_repo -eq 4 ]; then
            #No se considera un error, continue con el procesamiento de los siguientes repositorios.
            printf '\n'


        #   5 > El repositorio inicio la desinstalación y lo termino con error.
        elif [ $l_processed_repo -eq 5 ]; then
            #Es un error, se debe detener el proceso de la opción de menu (y no se debe invocar a la finalización).
            l_flag_process_next_repo=1
            l_exits_error=0

            printf '%bError al desinstalar el respositorio%b "%s" en %s\n' "$g_color_warning" "$g_color_reset" "$l_repo_name_aux" "$l_aux"
            printf 'Corrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n\n'

        fi


    done

    #Calcular el estado despues del procesamiento de repositorios
    if [ -z "$l_result" ]; then

        #Si se inicio la desinstalación de algun repositorio y se obtuvo error
        if [ $l_exits_error -eq 0 ]; then
            l_result=3
        fi
    fi

    #5. Iniciar la finalización (solo si no hubo error despues de la procesamiento de respositorios)
    if [ -z "$l_result" ]; then

        #5.1. Inicializar la opcion si aun no ha sido inicializado.
        #printf 'Se inicia la finalización de la opción del menu...\n'
        uninstall_finalize_menu_option $p_option_relative_idx
        l_status=$?

        #5.2. Si se inicializo con exito.
        if [ $l_status -eq 0 ]; then

            l_result=0

        #5.3. Si en la inicialización hubo un error.
        else

            printf 'No se completo la finalización de la opción del menu.\n'
            l_result=4

        fi


    fi

    return $l_result

}


#Parametros de entrada (Argumentos):
#  1 > Opciones relacionados con los repositorios que se se instalaran (entero que es suma de opciones de tipo 2^n).
#
#Parametros de entrada (Globales):
#    > 'gp_type_calling' es el flag '0' si es invocado directamente, caso contrario es invocado desde otro script.
#
function i_uninstall_repositories() {
    
    #1. Argumentos 
    local p_input_options=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    if [ $p_input_options -eq 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_opciones}\" es incorrecta"
        return 23;
    fi

    
    #3. Inicializaciones cuando se invoca directamente el script
    local l_status
    if [ $gp_type_calling -eq 0 ]; then

        printf '\n'

    fi

    #5. Configurar (Desintalar) los diferentes repositorios
    local l_i=0

    #Limpiar el arreglo asociativo
    _gA_processed_repo=()


    for((l_i=0; l_i < ${#ga_menu_options_packages[@]}; l_i++)); do

        _uninstall_menu_options $p_input_options $l_i

    done

    #echo "Keys de _gA_processed_repo=${!_gA_processed_repo[@]}"
    #echo "Values de _gA_processed_repo=${_gA_processed_repo[@]}"

    #6. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_status_crendential_storage -eq 0 ]; then
        clean_sudo_credencial
    fi

}



#}}}




#Funciones genericas - 1er nivel de ejecución {{{


#Es un arreglo con 2 valores enteros, el primero es el estado de la instalación en Linux, el segundo es el estado de la instalación en Windows.
#'g_install_repository' solo se puede mostrar el titulo del repositorio cuando ninguno de los estados de '_g_install_repo_status' es [0, 2].
#Cada estado puede tener uno de los siguiente valores: 
# Estados de un proceso no se ha iniciado:
#  0 > El repositorio tiene parametros invalidos que impiden que se inicie el analisis para determinar si este repositorio se procesa o no ('g_install_repository' retorno 2 o 99).
#  1 > El repositorio no esta habilitado para este SO.
#  2 > El repositorio no puede configurarse debido a que no esta instalado y solo pueden hacerlo para actualizarse.
#  3 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
#  4 > El repositorio esta instalado y ya esta actualizado.
# Estados de un proceso iniciado:
#  5 > El repositorio inicio la instalación y lo termino con exito.
#  6 > El repositorio inicio la actualización y lo termino con exito.
#  7 > El repositorio inicio la instalación y lo termino con error.
#  8 > El repositorio inicio la actualización y lo termino con error.
declare -a _g_install_repo_status

#
#Permite instalar un repositorio en Linux (incluyendo a Windows vinculado a un Linux WSL)
#Un repositorio o se configura en Linux o Windows del WSL o ambos.
#'g_install_repository' nunca se muestra con el titulo del repositorio cuando retorna 99 y 2. 
#'g_install_repository' solo se puede mostrar el titulo del repositorio cuando retorno [0, 1] y ninguno de los estados de '_g_install_repo_status' es [0, 2].
#
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se instalará", "se actualizará" o "se configurará")
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#      Se usa "se configurará" si no se puede determinar si se instala o configura pero es necesario que se continue.
#  3 > Flag '0' si la unica configuración que puede realizarse es actualizarse (no instalarse) y siempre en cuando el repositorio esta esta instalado.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#   0 > Se inicio la configuración (en por lo menos uno de los 2 SO Linux o Windows).
#       Para ver detalle del estado ver '_g_install_repo_status'.
#   1 > No se inicio la configuración del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
#       Para ver detalle del estado ver '_g_install_repo_status'.
#   2 > No se puede obtener correctamente la ultima versión del repositorio.
#  99 > Argumentos ingresados son invalidos.
#
#Parametros de salida (variables globales):
#    > '_g_install_repo_status' retona indicadores que indican el estado de la configuración (instalación/actualización) realizada.
#           
function g_install_repository() {

    #1. Argumentos 
    local p_repo_id="$1"
    local p_repo_title_template="$2"

    local p_only_update_if_its_installed=1
    if [ "$3" = "0" ]; then
        p_only_update_if_its_installed=0
    fi

    #1. Inicializaciones
    local l_status=0
    local l_repo_name="${gA_packages[$p_repo_id]}"


    #2. Obtener la ultima version del repositorio
    declare -a la_repo_versions
    #Estado de instalación del respositorio
    _g_install_repo_status=(0 0)

    _get_repo_latest_version "$p_repo_id" "$l_repo_name" la_repo_versions _ga_artifact_subversions
    l_status=$?

    #Si ocurrio un error al obtener la versión
    if [ $l_status -ne 0 ]; then

        if [ $l_status -ne 1 ]; then
            echo "ERROR: Primero debe tener a 'jq' en el PATH del usuario para obtener la ultima version del repositorio \"$p_repo_id\""
        else
            echo "ERROR: Ocurrio un error al obtener la ultima version del repositorio \"$p_repo_id\""
        fi
        return 2
    fi

    #si el arreglo de menos de 2 elementos
    local l_n=${#la_repo_versions[@]}
    if [ $l_n -lt 2 ]; then
        echo "ERROR: La configuración actual, no obtuvo las 2 formatos de la ultima versiones del repositorio \"${p_repo_id}\""
        return 2
    fi

    #Version usada para descargar la version (por ejemplo 'v3.4.6', 'latest', ...)
    local l_repo_last_version="${la_repo_versions[0]}"

    #Si la ultima version no tiene un formato correcto (no inicia con un numero, por ejemplo '3.4.6', '0.8.3', ...)
    local l_repo_last_version_pretty="${la_repo_versions[1]}"
    if [[ ! "$l_repo_last_version_pretty" =~ ^[0-9] ]]; then
        l_repo_last_version_pretty=""
    fi
       
    if [ -z "$l_repo_last_version" ]; then
        echo "ERROR: La ultima versión del repositorio \"$p_repo_id\" no puede ser vacia"
        return 2
    fi
   

    local l_artifact_subversions_nbr=${#_ga_artifact_subversions[@]} 
    
    #4. Iniciar la configuración en Linux: 
    local l_tag

    local l_empty_version

    local l_aux
    local l_status2
    
    #4.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    local l_install_win_cmds=1
    local l_status_process_lnx     # Estados de un proceso no se ha iniciado:
                                   #  0 > El repositorio tiene parametros invalidos que impiden su proceso (se da cuando 'g_install_repository' retorno 99).
                                   #  1 > El repositorio no esta habilitado para este SO.
                                   #  2 > El repositorio no puede configurarse debido a que no esta instalado y solo pueden hacerlo para actualizarse.
                                   #  3 > Al repositorio no se puede obtener la versión actual (no tiene implemento la logica o genero error al obtenerlo).
                                   #  4 > El repositorio esta instalado y ya esta actualizado.
                                   # Estados de un proceso iniciado:
                                   #  5 > El repositorio inicio la instalación y lo termino con exito.
                                   #  6 > El repositorio inicio la actualización y lo termino con exito.
                                   #  7 > El repositorio inicio la instalación y lo termino con error.
                                   #  8 > El repositorio inicio la actualización y lo termino con error.

    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?


    #Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then

        #4.2. Validar la versión actual con la ultima existente del repositorio.
        _validate_versions_to_install "$p_repo_id" "$l_repo_last_version" "$l_repo_last_version_pretty" $p_only_update_if_its_installed \
                                      $l_install_win_cmds "$p_repo_title_template"
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede instalarse devolverá de [0, 4]:
                       #    0 > El repositorio no esta instalado y su ultima versión disponible es valido.
                       #    1 > El repositorio no esta instalado pero su ultima versión disponible es invalido.
                       #Si el repositorio puede actualizarse devolverá de [5,9]:
                       #    5 > El repositorio esta desactualizado y su ultima version disponible es valido.
                       #    6 > El repositorio esta instalado pero su ultima versión disponible invalido.
                       #    7 > El repositorio tiene una versión actual invalido (la ultima verisón disponible puede ser valido e invalido).
                       #Si el repositorio NO se puede configurarse devolvera de [10, 99]:
                       #   10 > El repositorio ya esta instalado y actualizado (version actual es igual a la ultima).
                       #   11 > El repositorio ya esta instalado y actualizado (version actual es mayor a la ultima).
                       #   12 > El repositorio no puede determinarse su versión actual (la logica para obtener la version genero un error).
                       #   13 > El repositorio no tiene implamentado la logica para obtener la versión actual del repositorio.
                       #   14 > El repositorio no puede ser configurado, debido a que solo puede actualizarse los instalados y este repositorio esta instalado.


        #Establecer el estado del proceso que no seran procesados (instalados/actualizados)
        if [ $l_status -eq 14 ]; then
            l_status_process_lnx=2
        elif [ $l_status -eq 13 ] || [ $l_status -eq 12 ]; then
            l_status_process_lnx=3
        elif [ $l_status -eq 10 ] || [ $l_status -eq 11 ]; then
            l_status_process_lnx=4
        fi

        #¿El titulo se debe mostrar en la instalacion de Windows? 
        #'_validate_versions_to_install' solo muestra el titulo cuando retorna diferente a 99 y 14 (es decir solo se muestra cuando 'l_status_process_lnx' no es 0 ni 3).
        if [ ! -z "$p_repo_title_template" ] && [ $l_status -ne 14 ] && [ $l_status -ne 99 ]; then
            #Si ya se mostro no hacerlo nuevamente
            p_repo_title_template=""
        fi
            
        #4.3. Instalar el repositorio
        if [ -z "$l_status_process_lnx" ]; then

            #Solicitar credenciales para sudo y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then
                storage_sudo_credencial
                g_status_crendential_storage=$?
                #Se requiere almacenar las credenciales para realizar cambiso con sudo.
                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 120
                fi
            fi

            #Por defecto considerando que termino con error
            if [ $l_status -gt 0 ] && [ $l_status -lt 4 ]; then
                l_status_process_lnx=7
                l_aux='instalación'
            else
                l_status_process_lnx=8
                l_aux='actualización'
            fi

            printf -v l_empty_version ' %.0s' $(seq ${#_g_repo_current_version})

            if [ $l_artifact_subversions_nbr -eq 0 ]; then

                #Etiqueta para identificar el repositorio que se usara en lo logs cuando se instala
                if [ ! -z "${l_repo_last_version_pretty}" ]; then
                    l_tag="${p_repo_id}${g_color_opaque}[${l_repo_last_version_pretty}]${g_color_reset}"
                else
                    l_tag="${p_repo_id}${g_color_opaque}[${l_empty_version}]${g_color_reset}"
                fi

                printf '\nIniciando la %s de los artefactos del repositorio "%b" en Linux "%s" ...\n' "$l_aux" "${l_tag}" "$g_os_subtype_name"

                _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds
                l_status2=$?

                #Se requiere almacenar las credenciales para realizar cambios con sudo.
                if [ $l_status2 -eq 120 ]; then
                    return 120
                fi

                #Si termino sin errores cambiar al estado
                if [ $l_status -gt 0 ] && [ $l_status -lt 4 ]; then
                    l_status_process_lnx=5
                else
                    l_status_process_lnx=6
                fi
                

            else

    
                for ((l_n=0; l_n<${l_artifact_subversions_nbr}; l_n++)); do

                    #Etiqueta para identificar el repositorio que se usara en lo logs cuando se instala
                    if [ ! -z "${l_repo_last_version_pretty}" ]; then
                        l_tag="${p_repo_id}${g_color_opaque}[${l_repo_last_version_pretty}][${_ga_artifact_subversions[${l_n}]}]${g_color_reset}"
                    else
                        l_tag="${p_repo_id}${g_color_opaque}[${l_empty_version}][${_ga_artifact_subversions[${l_n}]}]${g_color_reset}"
                    fi
                    printf '\nIniciando la %s de los artefactos del repositorio "%b" en Linux "%s" ...\n' "$l_aux" "${l_tag}" "$g_os_subtype_name"

                    _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
                        "${_ga_artifact_subversions[${l_n}]}" ${l_n} $l_install_win_cmds
                    l_status2=$?

                    #Se requiere almacenar las credenciales para realizar cambios con sudo.
                    if [ $l_status2 -eq 120 ]; then
                        return 120
                    fi

                done

                #Si termino sin errores cambiar al estado
                if [ $l_status -gt 0 ] && [ $l_status -lt 4 ]; then
                    l_status_process_lnx=5
                else
                    l_status_process_lnx=6
                fi

            fi

        fi

    else

        l_status_process_lnx=1

    fi

    #Mostrar el status de la instalacion en Linux
    _g_install_repo_status[0]=$l_status_process_lnx

    #5. Iniciar la configuración en Windows:
    local l_status_process_win
    l_install_win_cmds=0
    

    #5.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?

    #Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then


        if [ $l_status_process_lnx -ge 3 ]; then
            printf "\n\n"
        fi

        #5.2. Validar la versión actual con la ultima existente del repositorio.
        _validate_versions_to_install "$p_repo_id" "$l_repo_last_version" "$l_repo_last_version_pretty" $p_only_update_if_its_installed \
                                      $l_install_win_cmds "$p_repo_title_template"
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede instalarse devolverá de [0, 4]:
                       #    0 > El repositorio no esta instalado y su ultima versión disponible es valido.
                       #    1 > El repositorio no esta instalado pero su ultima versión disponible es invalido.
                       #Si el repositorio puede actualizarse devolverá de [5,9]:
                       #    5 > El repositorio esta desactualizado y su ultima version disponible es valido.
                       #    6 > El repositorio esta instalado pero su ultima versión disponible invalido.
                       #    7 > El repositorio tiene una versión actual invalido (la ultima verisón disponible puede ser valido e invalido).
                       #Si el repositorio NO se puede configurarse devolvera de [10, 99]:
                       #   10 > El repositorio ya esta instalado y actualizado (version actual es igual a la ultima).
                       #   11 > El repositorio ya esta instalado y actualizado (version actual es mayor a la ultima).
                       #   12 > El repositorio no puede determinarse su versión actual (la logica para obtener la version genero un error).
                       #   13 > El repositorio no tiene implamentado la logica para obtener la versión actual del repositorio.
                       #   14 > El repositorio no puede ser configurado, debido a que solo puede actualizarse los instalados y este repositorio esta instalado.


        #Establecer el estado del proceso que no seran procesados (instalados/actualizados)
        if [ $l_status -eq 14 ]; then
            l_status_process_win=2
        elif [ $l_status -eq 13 ] || [ $l_status -eq 12 ]; then
            l_status_process_win=3
        elif [ $l_status -eq 10 ] || [ $l_status -eq 11 ]; then
            l_status_process_win=4
        fi


        #5.3. Instalar el repositorio
        if [ -z "$l_status_process_win" ]; then

            #Por defecto considerando que termino con error
            if [ $l_status -gt 0 ] && [ $l_status -lt 4 ]; then
                l_status_process_win=7
                l_aux='instalación'
            else
                l_status_process_win=8
                l_aux='actualización'
            fi
            
            printf -v l_empty_version ' %.0s' $(seq ${#_g_repo_current_version})


            if [ $l_artifact_subversions_nbr -eq 0 ]; then

                #Etiqueta para identificar el repositorio que se usara en lo logs cuando se instala
                if [ ! -z "${l_repo_last_version_pretty}" ]; then
                    l_tag="${p_repo_id}${g_color_opaque}[${l_repo_last_version_pretty}]${g_color_reset}"
                else
                    l_tag="${p_repo_id}${g_color_opaque}[${l_empty_version}]${g_color_reset}"
                fi

                printf '\nIniciando la %s de los artefactos del repositorio "%b" Windows (asociado al WSL "%s")\n' "$l_aux" "${l_tag}" "$g_os_subtype_name"

                _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds
                l_status2=$?

                #Si termino sin errores cambiar al estado
                if [ $l_status -gt 0 ] && [ $l_status -lt 4 ]; then
                    l_status_process_win=5
                else
                    l_status_process_win=6
                fi
                

            else

                for ((l_n=0; l_n<${l_artifact_subversions_nbr}; l_n++)); do

                    #Etiqueta para identificar el repositorio que se usara en lo logs cuando se instala
                    if [ ! -z "${l_repo_last_version_pretty}" ]; then
                        l_tag="${p_repo_id}${g_color_opaque}[${l_repo_last_version_pretty}][${_ga_artifact_subversions[${l_n}]}]${g_color_reset}"
                    else
                        l_tag="${p_repo_id}${g_color_opaque}[${l_empty_version}][${_ga_artifact_subversions[${l_n}]}]${g_color_reset}"
                    fi

                    printf '\nIniciando la %s de los artefactos del repositorio "%b" Windows (asociado al WSL "%s")\n' "$l_aux" "${l_tag}" "$g_os_subtype_name"

                    _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
                        "${_ga_artifact_subversions[${l_n}]}" ${l_n} $l_install_win_cmds
                    l_status2=$?

                done

                #Si termino sin errores cambiar al estado
                if [ $l_status -gt 0 ] && [ $l_status -lt 4 ]; then
                    l_status_process_win=5
                else
                    l_status_process_win=6
                fi

            fi

        fi

    else

        l_status_process_win=1

    fi

    #Mostrar el status de la instalacion en Linux
    _g_install_repo_status[1]=$l_status_process_win


    #Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #Si no se invoca interactivamente y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ] && [ $gp_type_calling -eq 2 ]; then
    #    clean_sudo_credencial
    #fi


    #Si no se llego a iniciar el proceso de configuración en ninguno de los 2 sistemas operativos
    if [ $l_status_process_lnx -lt 5 ] && [ $l_status_process_win -lt 5 ]; then
        return 1
    fi


    return 0

}


#
#Parametros de entrada (Argumentos):
#  1 > Opciones relacionados con los repositorios que se se instalaran (entero que es suma de opciones de tipo 2^n).
#
function g_install_repositories() {
    
    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    if [ $p_input_options -le 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
        return 99
    fi

    
    #3. Inicializaciones cuando se invoca directamente el script
    local l_flag=0
    local l_status
    local l_title

    if [ $gp_type_calling -eq 0 ]; then

        #Instalacion de paquetes del SO
        l_flag=$(( $p_input_options & $g_opt_update_installed_pckg ))
        if [ $g_opt_update_installed_pckg -eq $l_flag ]; then

            #Solicitar credenciales para sudo y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then
                storage_sudo_credencial
                g_status_crendential_storage=$?
                #Se requiere almacenar las credenciales para realizar cambiso con sudo.
                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 120
                fi
            fi

            print_line '─' $g_max_length_line  "$g_color_opaque"
            printf -v l_title "Actualizar los paquetes del SO '%s%s %s%s'" "$g_color_subtitle" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
            print_text_in_center2 "$l_title" $g_max_length_line 
            print_line '─' $g_max_length_line "$g_color_opaque"

            
            upgrade_os_packages $g_os_subtype_id

        fi
    fi

    #5. Configurar (instalar/actualizar) los repositorios selecionados por las opciones de menú dinamico.
    #   Si la configuración de un repositorio de la opción de menú falla, se deteniene la configuración de la opción.

    local l_i=0
    #Limpiar el arreglo asociativo
    _gA_processed_repo=()

    for((l_i=0; l_i < ${#ga_menu_options_packages[@]}; l_i++)); do
        
        _install_menu_options $p_input_options $l_i
        l_status=$?

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

    done

    #echo "Keys de _gA_processed_repo=${!_gA_processed_repo[@]}"
    #echo "Values de _gA_processed_repo=${_gA_p_title_templateprocessed_repo[@]}"

    #6. Si el flag actualizar todos los instalados esta activo, actualizar todos los instalados que aun no fueron actualizado.
    #   Si la configuración de un repositorio p_title_templatede la opción de menú falla, se continua la configuración con la siguiente opción del menú
    local l_update_all_installed_repo=1
    if [ $((p_input_options & g_opt_update_installed_repo)) -eq $g_opt_update_installed_repo ]; then 
        l_update_all_installed_repo=0
    fi


    if [ $l_update_all_installed_repo -eq 0 ]; then

        _update_installed_repository
        l_status=$?

        #Se requiere almacenar las credenciales para realizar cambios con sudo.
        if [ $l_status -eq 120 ]; then
            return 120
        fi

    fi


    #7. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca interactivamente y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi


}

function _show_menu_install_core() {

    print_text_in_center "Menu de Opciones (Install/Update)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " (%ba%b) Actualizar los paquetes existentes del SO y los binarios de los repositorios existentes\n" "$g_color_title" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    _get_length_menu_option $g_offset_option_index_menu_install
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes existentes del sistema operativo\n" "$g_color_title" "$g_opt_update_installed_pckg" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar solo los repositorios de programas ya instalados\n" "$g_color_title" "$g_opt_update_installed_repo" "$g_color_reset"

    _show_dynamic_menu 'Instalar o actualizar' $g_offset_option_index_menu_install $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque"

}


function g_install_main() {

    #1. Pre-requisitos
   
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_title" 
    _show_menu_install_core

    #3. Mostar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    local l_value_option_a=$(($g_opt_update_installed_pckg + $g_opt_update_installed_repo))
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                g_install_repositories $l_value_option_a 0
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    g_install_repositories $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_opaque" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;
        esac
        
    done

}



function _show_menu_uninstall_core() {

    print_text_in_center "Menu de Opciones (Uninstall)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " ( ) Para desintalar ingrese un opción o la suma de las opciones que desea configurar:\n"

    _get_length_menu_option $g_offset_option_index_menu_uninstall
    local l_max_digits=$?

    _show_dynamic_menu 'Desinstalar' $g_offset_option_index_menu_uninstall $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque" 

}


function g_uninstall_main() {

  
    #Mostrar la parte superior del menu 
    print_line '─' $g_max_length_line "$g_color_title" 

    _show_menu_uninstall_core

    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;


            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    i_uninstall_repositories $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_opaque" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;
        esac
        
    done

}


g_usage() {

    printf '%bUsage:\n\n' "$g_color_opaque"
    printf '  > Desintalar repositorios de manera interactiva (muestra el menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash uninstall\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar repositorios de manera interactiva (muestra el menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar/Actualizar uno o mas repositorios en forma no interactiva (sin menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 1 MENU-OPTIONS\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar/Actualizar un repositorio en forma no interactiva (sin menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 2 REPO-ID%b\n\n' "$g_color_info" "$g_color_reset"

}


#}}}


#1. Argumentos fijos del script


#Argumento 1: ¿instalar/actualizar o desintalar?
if [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
elif [ "$1" = "uninstall" ]; then
    gp_uninstall=0
elif [ ! -z "$1" ]; then
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi


#Argumento 2: ¿solo para el usuario actual? ¿para todos los usuarios?
gp_install_all_user=0   #(0) Se instala/configura para ser usuado por todos los usuarios (si es factible).
                        #    Requiere ejecutar con privilegios de administrador.
                        #(1) Solo se instala/configura para el usuario actual (no requiere ser administrador).

#if [[ "$2" =~ ^[0-9]+$ ]]; then
#    gp_install_all_user=$2
#fi



#2. Logica principal del script (incluyendo los argumentos variables)
_g_result=0
_g_status=0

#Aun no se ha solicitado almacenar temporalmente las credenciales para el sudo
g_status_crendential_storage=-1
#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1

#2.1. Desintalar los artefactos de un repoistorio
if [ $gp_uninstall -eq 0 ]; then

    #Validar los requisitos
    fulfill_preconditions2 $g_os_type $gp_type_calling
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_uninstall_main
    else
        _g_result=111
    fi


#2.2. Instalar y actualizar los artefactos de un repositorio
else

    #2.2.1. Por defecto, mostrar el menu para escoger lo que se va instalar
    if [ $gp_type_calling -eq 0 ]; then
    
        #Validar los requisitos
        fulfill_preconditions1 $g_os_type $gp_type_calling
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then
            g_install_main
        else
            _g_result=111
        fi
    
    #2.2.2. Instalando los repositorios especificados por las opciones indicas en '$2'
    elif [ $gp_type_calling -eq 1 ]; then
    
        #Parametros del script usados hasta el momento:
        # 1> Tipo de configuración: 1 (instalación/actualización).
        # 2> Opciones de menu a ejecutar: entero positivo.
        # 3> El estado de la credencial almacenada para el sudo.
        gp_opciones=0
        if [[ "$2" =~ ^[0-9]+$ ]]; then
            gp_opciones=$2
        else
            exit 110
        fi

        if [[ "$3" =~ ^[0-2]$ ]]; then
            g_status_crendential_storage=$3

            if [ $g_status_crendential_storage -eq 0 ]; then
                g_is_credential_storage_externally=0
            fi

        fi

        #Validar los requisitos
        fulfill_preconditions1 $g_os_type $gp_type_calling
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then

            g_install_repositories $gp_opciones
            _g_status=$?

            #Informar si se nego almacenar las credencial cuando es requirido
            if [ $_g_status -eq 120 ]; then
                _g_result=120
            #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
            elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
                _g_result=119
            fi

        else
            _g_result=111
        fi
    
    #2.2.3. Instalando un solo repostorio del ID indicao por '$2'
    else
    
        #Parametros del script usados hasta el momento:
        # 1> Tipo de configuración: 1 (instalación/actualización).
        # 2> ID del repositorio a instalar: identificado interno del respositorio
        # 3> El estado de la credencial almacenada para el sudo.
        gp_repo_id="$2"
        if [ -z "$gp_repo_id" ]; then
           echo "Parametro 2 \"$2\" debe ser un ID de repositorio valido"
           exit 110
        fi

        if [[ "$3" =~ ^[0-2]$ ]]; then
            g_status_crendential_storage=$3

            if [ $g_status_crendential_storage -eq 0 ]; then
                g_is_credential_storage_externally=0
            fi
        fi
    
        #Validar los requisitos
        fulfill_preconditions1 $g_os_type $gp_type_calling
        _g_status=$?

        #Iniciar el procesamiento
        if [ $_g_status -eq 0 ]; then

            g_install_repository "$gp_repo_id" "" 1
            _g_status=$?

            #Informar si se nego almacenar las credencial cuando es requirido
            if [ $_g_status -eq 0 ]; then

                if [ $_g_status -eq 120 ]; then
                    _g_result=120
                #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
                elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
                    _g_result=119
                fi

            fi

        else
            _g_result=111
        fi
    
    fi
    
fi

exit $_g_result


