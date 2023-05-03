#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

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


#Variables y funciones para mostrar las opciones dinamicas del menu.
. ~/.files/setup/linux/_dynamic_commands_menu.bash

#Funciones modificables para el instalador
. ~/.files/setup/linux/_setup_commands_custom_logic.bash


#Opciones de configuración de los repositorio 
# > Por defecto los repositorios son instalados en todo los permitido (valor por defecto es 11)
# > Las opciones puede ser uno o la suma de los siguientes valores:
#   1 (00001) Linux que no WSL2
#   2 (00010) Linux WSL2
#   8 (00100) Windows vinculado al Linux WSL2
#
declare -A gA_repo_config=(
        ['less']=8
        ['k0s']=1
        ['operator-sdk']=3
        ['nerd-fonts']=3
        ['powershell']=3
        ['runc']=3
        ['cni-plugins']=3
        ['rootlesskit']=3
        ['slirp4netns']=3
        ['containerd']=3
        ['buildkit']=3
        ['nerdctl']=3
        ['dive']=3
    )

#Valores de la opcion especiales del menu (no estan vinculado a un repositorio especifico):
# > Actualizar todos paquetes del sistema operativo (Opción 1 del arreglo del menu)
g_opt_update_installed_pckg=$((1 << 0))
# > Actualizar todos los repositorios instalados (Opción 2 del arreglo del menu)
g_opt_update_installed_repo=$((1 << 1))


#Tamaño de la linea del menu
g_max_length_line=130


#Menu dinamico: Offset del indice donde inicia el menu dinamico.
#               Generalmente el menu dinamico no inicia desde la primera opcion personalizado del menú.
g_offset_option_index_menu_install=2
g_offset_option_index_menu_uninstall=0


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
    
    local l_tag="${p_repo_id}"
    if [ ! -z "${p_repo_last_version_pretty}" ]; then
        l_tag="${l_tag}[${p_repo_last_version_pretty}]"
    else
        l_tag="${l_tag}[...]"
    fi

    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}/[${p_arti_version}]"
    fi
    
    echo "Se ha concluido la configuración de los artefactos del repositorio \"${l_tag}\""

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

    local l_tag="${p_repo_id}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}[${p_arti_version}]"
    fi

    for ((l_i=0; l_i<$l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_base_url=$(_get_last_repo_url "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$l_artifact_name" $p_install_win_cmds)
        l_artifact_url="${l_base_url}/${l_artifact_name}"
        printf '\nArtefacto "%s[%s]" a descargar - Name    : %s\n' "$l_tag" "${l_i}" "${l_artifact_name}"
        printf 'Artefacto "%s[%s]" a descargar - URL     : %s\n' "$l_tag" "${l_i}" "${l_artifact_url}"

        
        #Descargar la artefacto
        mkdir -p "/tmp/${p_repo_id}/${l_i}"
        curl -fLo "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" "$l_artifact_url"
        l_status=$?
        if [ $l_status -eq 0 ]; then
            printf 'Artefacto "%s[%s]" descargado en         : "/tmp/%s/%s/%s"\n\n' "$l_tag" "${l_i}" "${p_repo_id}" "${l_i}" "${l_artifact_name}"
        else
            printf 'Artefacto "%s[%s]" no se pudo descargar  : ERROR(%s)\n\n' "$l_tag" "${l_i}" "${l_status}"
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

    local l_tag="${p_repo_id}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}[${p_arti_version}]"
    fi

    for ((l_i=0; l_i<$l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_artifact_type="${pnra_artifact_types[$l_i]}"
        printf 'Artefacto "%s[%s]" a configurar - Name   : %s\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
        printf 'Artefacto "%s[%s]" a configurar - Type   : %s\n' "${l_tag}" "${l_i}" "${l_artifact_type}"


        if [ $l_i -eq $l_n ]; then
            l_is_last=0
        fi

        if [ $l_artifact_type -eq 2 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            printf 'Descomprimiendo el artefacto "%s[%s]" ("%s") en "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}"
            #tar -xvf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            tar -xf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%s[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.tar.gz}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%s[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 5 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            printf 'Descomprimiendo el artefacto "%s[%s]" ("%s") en "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}"
            #tar -xvf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            tar -xf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%s[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.tgz}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%s[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 4 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            l_tmp="${l_artifact_name%.gz}"
            printf 'Descomprimiendo el artefacto "%s[%s]" ("%s") como el archivo "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}/${l_tmp}"
            gunzip -q "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            #gunzip "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            #rm -f "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%s[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_tmp}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%s[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 3 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            printf 'Descomprimiendo el artefacto "%s[%s]" ("%s") en "%s" ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}" "/tmp/${p_repo_id}/${l_i}"
            #unzip "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -d "/tmp/${p_repo_id}/${l_i}"
            unzip -q "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -d "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%s[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.zip}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%s[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 0 ]; then

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%s[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            if [ $p_install_win_cmds -eq 0 ]; then
                _copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.exe}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                    "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            else
                _copy_artifact_files "$p_repo_id" $l_i "$l_artifact_name" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                    "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            fi
            #l_status=0
            printf 'Artefacto "%s[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 1 ]; then

            if [ $g_os_subtype_id -ne 1 ]; then
                printf 'ERROR (%s): No esta permitido instalar el artefacto "%s[%s]" ("%s") en SO que no sean de familia Debian\n\n' "22" "${l_tag}" "${l_i}" "${l_artifact_name}"
                return 22
            fi

            #Instalar y/o actualizar el paquete si ya existe
            printf 'Instalando/Actualizando el paquete/artefacto "%s[%s]" ("%s") en el SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            if [ $g_is_root -eq 0 ]; then
                dpkg -i "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            else
                sudo dpkg -i "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            fi
            #l_status=0
            printf 'Artefacto "%s[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        else
            printf 'ERROR (%s): El tipo del artefacto "%s[%s]" ("%s") no esta implementado "%s"\n\n' "21" "${l_tag}" "${l_i}" "${l_artifact_name}" "${l_artifact_type}"
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
    local l_tag="${p_repo_id}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}[${p_arti_version}]"
    fi
    
    #Vriables de referencias a arreglos que se crearan dentro de la funcion '_load_artifacts'
    local la_artifact_names
    local la_artifact_types
    _load_artifacts "$p_repo_id" "$p_repo_last_version" "$p_repo_last_version_pretty" la_artifact_names la_artifact_types "$p_arti_version" $p_install_win_cmds
    l_status=$?    
    if [ $l_status -ne 0 ]; then
        echo "ERROR (40): No esta configurado los artefactos para el repositorio \"${l_tag}\""
        return 22
    fi

    #si el arreglo es vacio
    local l_n=${#la_artifact_names[@]}
    if [ $l_n -le 0 ]; then
        echo "ERROR (41): No esta configurado los artefactos para el repositorio \"${l_tag}\""
        return 98
    fi
    echo "Repositorio \"${l_tag}\" tiene \"${l_n}\" artefactos"

    #si el tamano del los arrgelos no son iguales
    if [ $l_n -ne ${#la_artifact_types[@]} ]; then
        echo "ERROR (42): No se ha definido todos los tipo de artefactos en el repositorio \"${l_tag}\""
        return 97
    fi    

    #5. Descargar el artifacto en la carpeta
    if ! _download_artifacts "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$p_repo_last_version_pretty" la_artifact_names "$p_arti_version"; then
        echo "ERROR (43): No se ha podido descargar los artefactos del repositorio \"${l_tag}\""
        _clean_temp "$p_repo_id"
        return 23
    fi

    #6. Instalar segun el tipo de artefecto
    if ! _install_artifacts "${p_repo_id}" "${p_repo_name}" la_artifact_names la_artifact_types "${p_repo_current_version}" "${p_repo_last_version}" \
        "$p_repo_last_version_pretty" "$p_arti_version" $p_arti_index $p_install_win_cmds; then
        echo "ERROR (44): No se ha podido instalar los artefecto de repositorio \"${l_tag}\""
        _clean_temp "$p_repo_id"
        return 24
    fi

    _show_final_message "$p_repo_id" "$p_repo_last_version_pretty" "$p_arti_version" $p_install_win_cmds
    _clean_temp "$p_repo_id"
    return 0

}

declare -a _ga_artifact_subversions
declare -a _g_repo_current_version

#Esta funcion solo imprime el titulo del repositorio cuando el valor de retorna es un valor diferente de 99 y 10
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
#  Si el repositorio puede actualizarse (instalarse/actualizarse), devolvera de [0, 9]:
#    0 > El repositorio puede actualizarse
#    1 > El repositorio puede instalarse
#    2 > El repositorio puede configurarse (intalarse/actualizar) aun cuando no puedo obtener la versión actual o se obtuvo un formato invalido de versión.
#    3 > El repositorio puede configurarse (intalarse/actualizar) aun cuando no puedo la ultima versión disponible tiene un formato invalido de versión.
#  Si el repositorio NO puede configurarse devolvera de [10, 99]:
#   10 > El repositorio no puede ser configurado, debido a que solo puede actualizarse los instalados y este repositorio esta instalado.
#   11 > No se ha implamentado la logica para obtener la versión actual.
#   12 > Esta instalado y actualziado (version actual es igual a la ultima).
#   13 > Esta instalado y actualziado (version actual es mayor a la ultima).
#   99 > Argumentos ingresados son invalidos.
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

    _g_repo_current_version=""

    #2. Obtener la versión de repositorio instalado en Linux
    local l_repo_current_version=""
    local l_repo_is_installed=0
    l_repo_current_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "")
    l_repo_is_installed=$?          #(9) El repositorio unknown porque no se implemento la logica
                                    #(3) El repositorio unknown porque no se puede obtener (siempre instalarlo)
                                    #(1) El repositorio no esta instalado 
                                    #(0) El repositorio instalado, con version correcta
                                    #(2) El repositorio instalado, con version incorrecta

    _g_repo_current_version="$l_repo_current_version"

    #Si la unica configuración que puede realizarse es actualizarse (no instalarse) y siempre en cuando el repositorio esta esta instalado.
    if [ $p_only_update_if_its_installed -eq 0 ] && [ $l_repo_is_installed -ne 0 ] && [ $l_repo_is_installed -ne 2 ]; then
        return 10        
    fi

    local l_repo_name_aux="${gA_repositories[$p_repo_id]:-$p_repo_id}"

    #3. Mostrar el titulo
    if [ ! -z "$p_title_template" ]; then

        print_line '-' $g_max_length_line  "$g_color_opaque"

        if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ]; then
            printf "${p_title_template}\n" "se actualizará"
        elif [ $l_repo_is_installed -eq 1 ]; then
            printf "${p_title_template}\n" "se instalará"
        else
            printf "${p_title_template}\n" "se configurará"
        fi

        print_line '-' $g_max_length_line  "$g_color_opaque"

    fi


    if [ $p_install_win_cmds -eq 0 ]; then
        printf 'Analizando el repositorio "%s" en el %bWindows%b vinculado a este Linux WSL...\n' "$p_repo_id" "$g_color_subtitle" "$g_color_reset"
    fi

    #4. Mostrar información de la ultima versión.
    printf 'Repositorio "%s[%s]" (Ultima Versión): "%s"\n' "${p_repo_id}" "${p_repo_last_version_pretty}" "${p_repo_last_version}"

    #Si el artefacto tiene Subversiones, mostrarlos.
    local l_artifact_subversions_nbr=${#_ga_artifact_subversions[@]} 
    if [ $l_artifact_subversions_nbr -ne 0 ]; then
        for ((l_n=0; l_n< ${l_artifact_subversions_nbr}; l_n++)); do
            printf 'Repositorio "%s[%s]" (Ultima Versión): Sub-version[%s] es "%s"\n' "${p_repo_id}" "${p_repo_last_version_pretty}" \
                   "${l_n}" "${_ga_artifact_subversions[${l_n}]}"
        done
    fi

    #5. Mostar información de la versión actual.
    if [ $l_repo_is_installed -eq 9 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No implementado"
    elif [ $l_repo_is_installed -eq 1 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No instalado"
    elif [ $l_repo_is_installed -eq 2 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "Formato invalido"
        l_repo_current_version=""
    elif [ $l_repo_is_installed -eq 3 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "No se puede calcular"
    #else
    #    printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "OK"
    fi

    #6. Si no esta instalado, INICIAR su instalación
    if [ -z "${l_repo_current_version}" ]; then
        printf 'Repositorio "%s[%s]" se instalará\n' "${p_repo_id}" "${p_repo_last_version_pretty}"

        printf 'Iniciando la instalación de los artefactos del repositorio "%s" en ' "${l_repo_name_aux}"
        if [ $p_install_win_cmds -ne 0 ]; then
            printf 'Linux "%s"\n' "$g_os_subtype_name"
        else
            printf 'Windows (asociado al WSL "%s")\n' "$g_os_subtype_name"
        fi

        return 1
    fi

    #7. Evalular los escenarios donde no se obtiene una versión actual correcta

    #No seguir con la instalación si: NO se tiene la logica de obtener la version actual implementado
    if [ $l_repo_is_installed -eq 9 ]; then
        echo "ERROR: Debe implementar la logica para determinar la version actual de repositorio instalado"
        return 11
    fi

    #Mostrar una advertencia si las ultima version y la actual no pueden ser comparables, pero INICIAR su instalación 
    if [ $l_repo_is_installed -eq 2 ] && [ $l_repo_is_installed -eq 3 ]; then
        printf 'Repositorio "%s" tiene como versión actual a "%s" con formato invalido para compararla con la ultima versión "%s", aun asi se iniciará su instalación\n' \
               "${p_repo_id}" "${l_repo_current_version}" "${p_repo_last_version_pretty}"

        printf 'Iniciando la configuración de los artefactos del repositorio "%s" en ' "${l_repo_name_aux}"
        if [ $p_install_win_cmds -ne 0 ]; then
            printf 'Linux "%s"\n' "$g_os_subtype_name"
        else
            printf 'Windows (asociado al WSL "%s")\n' "$g_os_subtype_name"
        fi

        return 2
    fi

    if [ -z "$l_repo_last_version_pretty" ]; then
        printf 'Repositorio "%s" tiene como ultima versión disponible a "%s" la cual es un formato invalido para compararla con la versión actual "%s", aun asi se iniciará su instalación\n' \
               "${p_repo_id}" "${l_repo_last_version}" "${l_repo_current_version}"

        printf 'Iniciando la configuración de los artefactos del repositorio "%s" en ' "${l_repo_name_aux}"
        if [ $p_install_win_cmds -ne 0 ]; then
            printf 'Linux "%s"\n' "$g_os_subtype_name"
        else
            printf 'Windows (asociado al WSL "%s")\n' "$g_os_subtype_name"
        fi

        return 3
    fi

    #8. Si esta instalado y se obtuvo un versión actual valida: comparar las versiones y segun ello, habilitar la actualización.
    compare_version "${l_repo_current_version}" "${p_repo_last_version_pretty}"
    l_status=$?

    #Si ya esta actualizado
    if [ $l_status -eq 0 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "${p_repo_id}" "${l_repo_current_version}" "${p_repo_last_version_pretty}"
        return 12
    elif [ $l_status -eq 1 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "${p_repo_id}" "${l_repo_current_version}" "${p_repo_last_version_pretty}"
        return 13
    fi

    #Si requiere actualizarse
    printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "${p_repo_last_version_pretty}"
    
    printf 'Iniciando la actualización de los artefactos del repositorio "%s" en ' "${l_repo_name_aux}"
    if [ $p_install_win_cmds -ne 0 ]; then
        printf '%bLinux%b "%s"\n' "$g_color_subtitle" "$g_color_reset" "$g_os_subtype_name" 
    else
        printf '%bWindows%b (asociado al WSL "%s")\n' "$g_color_subtitle" "$g_color_reset" "$g_os_subtype_name"
    fi

    return 0


}

#Esta funcion solo imprime el titulo del repositorio cuando retorna un valor de retorno es diferente de 99.
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > Flag '0' si es artefacto instalado en Windows (asociado a WSL2).
#  3 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se desinstalará".
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#  Si el repositorio puede desintalarse si devuelve de [0, 9]:
#    0 > El repositorio se puede desintalar
#  Si el repositorio NO puede desintalarse si devuelve de [10, 99]:
#   10 > No se ha implementado la logica para obtener la versión actual.
#   11 > La verisón actual del repositorio tiene formato invalido.
#   12 > El repositorio no esta instalado (por lo que no puede ser desintalado).
#   99 > Argumentos ingresados son invalidos
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
    local l_repo_is_installed=0
    l_repo_current_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "")
    l_repo_is_installed=$?          #(9) El repositorio unknown porque no se implemento la logica
                                    #(3) El repositorio unknown porque no se puede obtener
                                    #(1) El repositorio no esta instalado 
                                    #(0) El repositorio instalado, con version correcta
                                    #(2) El repositorio instalado, con version incorrecta

    _g_repo_current_version="$l_repo_current_version"


    #3. Mostrar el titulo
    if [ ! -z "$p_title_template" ]; then

        print_line '-' $g_max_length_line  "$g_color_opaque"
        printf "${p_title_template}\n" "se desinstalará"
        print_line '-' $g_max_length_line  "$g_color_opaque"

    fi

    if [ $p_install_win_cmds -eq 0 ]; then
        printf 'Analizando el repositorio "%s" en el Windows vinculado a este Linux WSL...\n' "$p_repo_id"
    fi

    #4. Mostar información de la versión actual.
    if [ $l_repo_is_installed -eq 9 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No implementado"
    elif [ $l_repo_is_installed -eq 1 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No instalado"
    elif [ $l_repo_is_installed -eq 2 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "Formato invalido"
    elif [ $l_repo_is_installed -eq 3 ]; then
        printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "No se puede calcular"
    #else
    #    printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "OK"
    fi

    #5. Evalular los escenarios donde no se obtiene una versión actual correcta
    local l_repo_name_aux="${gA_repositories[$p_repo_id]:-$p_repo_id}"

    #No seguir con la instalación si: NO se tiene la logica de obtener la version actual implementado
    if [ $l_repo_is_installed -eq 9 ]; then
        echo "No se ha implementado una la logica para determinar la version actual de repositorio, NO se iniciará su desinstalación"
        return 10
    fi

    #Mostrar una advertencia si las ultima version y la actual no pueden ser comparables, pero INICIAR su instalación 
    if [ $l_repo_is_installed -eq 2 ] && [ $l_repo_is_installed -eq 3 ]; then
        printf 'Repositorio "%s" tiene como versión actual a "%s" con formato invalido, NO se iniciará su desinstalación\n' \
               "${p_repo_id}" "${l_repo_current_version}"
        return 11
    fi

    #6. Si no esta instalado, NO desinstaler
    if [ $l_repo_is_installed -eq 1 ] ; then
        echo "El repositorio NO esta instalado. No se iniciará su desinstalación"
        return 12
    fi

    #7. Iniciando la desinstalación
    printf 'Iniciando la desinstalacíon de los artefactos del repositorio "%s" en ' "${l_repo_name_aux}"
    if [ $p_install_win_cmds -ne 0 ]; then
        printf '%bLinux%b "%s"\n' "$g_color_subtitle" "$g_color_reset" "$g_os_subtype_name" 
    else
        printf '%bWindows%b (asociado al WSL "%s")\n' "$g_color_subtitle" "$g_color_reset" "$g_os_subtype_name"
    fi

    return 0


}



#}}}


#Codigo principal del script {{{


#Es un arreglo con 2 valores enteros, el primero es el estado de la instalación en Linux, el segundo es el estado de la instalación en Windows.
#Cada estado tiene la suma de los algunos/todos los flag binarios:
#    000X -> Donde X=1 Si se inicio la configuración (instala/actualiza) del repositorio.
#                  X=0 Si NO se inicio la configuración (instala/actualiza) del repositorio debido a no se cumple las precondiciones requeridas. 
#                       - Se ingreso parametros incorrectos para al solicitar su configuración ('i_install_repository' y 'i_uninstall_repository' devuelven 99 o 98).
#                       - No se puede obtener correctamente los parametros del repositorio (no se puede obtener la versión actual, ....).
#                       - El repositorio no esta habilitado para que se procese en este sistema operativo.
#                       - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
#    00X0 -> Donde X=1 Si configuró (instaló/actualizó) el repositorio con exito,
#                  X=0 Si se configuró (instaló/actualizó el repositorio pero tubo errores en el proceso.
declare -a _g_install_repo_status

#Valor constante usada para generar el estado de la configuración (instalación/eliminacion) de un repositorio
declare -r g_flag_setup_begining=1
declare -r g_flag_setup_sucessfully=2



#
#Permite instalar un repositorio en Linux (incluyendo a Windows vinculado a un Linux WSL)
#Un repositorio o se configura en Linux o Windows del WSL o ambos.
#
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se instalará", "se actualizará" o "se configurará")
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#      Se usa "se configurará" si no se puede determinar si se instala o configura pero es necesario que se continue.
#  3 > Flag '0' si la unica configuración que puede realizarse es actualizarse (no instalarse) y siempre en cuando el repositorio esta esta instalado.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > Se inicio la configuración (en por lo menos uno de los 2 SO Linux o Windows), para ver detalle del estado ver '_g_install_repo_status'.
#    1 > No se inicio la configuración del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
#        - No se puede obtener correctamente los parametros del repositorio (no se puede obtener la versión actual, ....).
#        - El repositorio no esta habilitado para que se procese en este sistema operativo.
#        - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
#   98 > No se puede obtener la ultima versión del repositorio o la versión obtenida no es valida.
#   99 > Argumentos ingresados son invalidos
#
#Parametros de salida (variables globales):
#    > '_g_install_repo_status' retona indicadores que indican el estado de la configuración (instalación/actualización) realizada.
#           
function i_install_repository() {

    #1. Argumentos 
    local p_repo_id="$1"

    local p_repo_title_template="$2"

    local p_only_update_if_its_installed=1
    if [ "$3" = "0" ]; then
        p_only_update_if_its_installed=0
    fi

    #1. Inicializaciones
    local l_status=0
    local l_repo_name="${gA_repositories[$p_repo_id]}"


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
        return 98
    fi

    #si el arreglo de menos de 2 elementos
    local l_n=${#la_repo_versions[@]}
    if [ $l_n -lt 2 ]; then
        echo "ERROR: La configuración actual, no obtuvo las 2 formatos de la ultima versiones del repositorio \"${p_repo_id}\""
        return 98
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
        return 98
    fi
   

    local l_artifact_subversions_nbr=${#_ga_artifact_subversions[@]} 
    
    #4. Iniciar la configuración en Linux: 
    local l_install_win_cmds=1
    
    #4.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?

    #Calcular valores necesarios
    local l_aux=""

    #Etiqueta para identificar el repositorio que se usara en lo logs cuando se instala
    local l_tag="${p_repo_id}"
    if [ ! -z "${l_repo_last_version_pretty}" ]; then
        l_tag="${l_tag}[${l_repo_last_version_pretty}]"
    else
        l_tag="${l_tag}[...]"
    fi

    local l_flag_setup_begining=0
    local l_flag_setup_sucessfully=0
    local l_repo_is_beging_setup=1

    #Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then

        #4.2. Validar la versión actual con la ultima existente del repositorio.
        _validate_versions_to_install "$p_repo_id" "$l_repo_last_version" "$l_repo_last_version_pretty" $p_only_update_if_its_installed \
                                      $l_install_win_cmds "$p_repo_title_template"
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede actualizarse (instalarse/actualizarse), devolvera de [0, 9]:
                       #    0 > El repositorio puede actualizarse
                       #    1 > El repositorio puede instalarse
                       #    2 > El repositorio puede configurarse (intalarse/actualizar) aun cuando no puedo obtener la versión actual o se obtuvo un formato invalido de versión.
                       #    3 > El repositorio puede configurarse (intalarse/actualizar) aun cuando no puedo la ultima versión disponible tiene un formato invalido de versión.
                       # Si el repositorio NO puede configurarse devolvera de [10, 99]:
                       #   10 > El repositorio no puede ser configurado, debido a que solo puede actualizarse los instalados y este repositorio esta instalado.
                       #   11 > No se ha implamentado la logica para obtener la versión actual.
                       #   12 > Esta instalado y actualziado (version actual es igual a la ultima).
                       #   13 > Esta instalado y actualziado (version actual es mayor a la ultima).
                       #   99 > Argumentos ingresados son invalidos.


        #¿El titulo se debe mostrar en la instalacion de Windows?
        if [ ! -z "$p_repo_title_template" ] && [ $l_status -ne 10 ] && [ $l_status -ne 99 ]; then
            #Si ya se mostro no hacerlo nuevamente
            p_repo_title_template=""
        fi
            
        #4.3. Instalar el repositorio
        if [ $l_status -ge 0 ] && [ $l_status -le 9 ]; then

            l_repo_is_beging_setup=0
            l_flag_setup_begining=$g_flag_setup_begining
            
            if [ $l_artifact_subversions_nbr -eq 0 ]; then

                printf "\nSe iniciara la configuración de los artefactos del repositorio \"${l_tag}\" ...\n"
                _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds

                l_flag_setup_sucessfully=$g_flag_setup_sucessfully

            else

                for ((l_n=0; l_n<${l_artifact_subversions_nbr}; l_n++)); do
                    l_aux="${l_tag}[${_ga_artifact_subversions[${l_n}]}]"
                    printf "\nSe iniciara la configuración de los artefactos del repositorio \"${l_aux}\" ...\n"
                    _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
                        "${_ga_artifact_subversions[${l_n}]}" ${l_n} $l_install_win_cmds
                done

                l_flag_setup_sucessfully=$g_flag_setup_sucessfully

            fi

            printf "\n"

        fi

    fi

    #Mostrar el status de la instalacion en Linux
    _g_install_repo_status[0]=$((l_flag_setup_begining + l_flag_setup_sucessfully))

    #5. Iniciar la configuración en Windows:
    l_flag_setup_begining=0
    l_flag_setup_sucessfully=0

    l_install_win_cmds=0
    

    #5.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?

    #Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then

        #5.2. Validar la versión actual con la ultima existente del repositorio.
        _validate_versions_to_install "$p_repo_id" "$l_repo_last_version" "$l_repo_last_version_pretty" $p_only_update_if_its_installed \
                                      $l_install_win_cmds "$p_repo_title_template"
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede actualizarse (instalarse/actualizarse), devolvera de [0, 9]:
                       #    0 > El repositorio puede actualizarse
                       #    1 > El repositorio puede instalarse
                       #    2 > El repositorio puede configurarse (intalarse/actualizar) aun cuando no puedo obtener la versión actual o se obtuvo un formato invalido de versión.
                       #    3 > El repositorio puede configurarse (intalarse/actualizar) aun cuando no puedo la ultima versión disponible tiene un formato invalido de versión.
                       # Si el repositorio NO puede configurarse devolvera de [10, 99]:
                       #   10 > El repositorio no puede ser configurado, debido a que solo puede actualizarse los instalados y este repositorio esta instalado.
                       #   11 > No se ha implamentado la logica para obtener la versión actual.
                       #   12 > Esta instalado y actualziado (version actual es igual a la ultima).
                       #   13 > Esta instalado y actualziado (version actual es mayor a la ultima).
                       #   99 > Argumentos ingresados son invalidos.
                       #   99 > Argumentos ingresados son invalidos


        #5.3. Instalar el repositorio
        if [ $l_status -ge 0 ] && [ $l_status -le 9 ]; then

            l_repo_is_beging_setup=0
            l_flag_setup_begining=$g_flag_setup_begining

            if [ $l_artifact_subversions_nbr -eq 0 ]; then

                printf "\nSe iniciara la configuración de los artefactos del repositorio \"${l_tag}\" ...\n"
                _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds

                l_flag_setup_sucessfully=$g_flag_setup_sucessfully

            else

                for ((l_n=0; l_n<${l_artifact_subversions_nbr}; l_n++)); do
                    l_aux="${l_tag}[${_ga_artifact_subversions[${l_n}]}]"
                    printf "\nSe iniciara la configuración de los artefactos del repositorio \"${l_aux}\" ...\n"
                    _install_repository_internal "$p_repo_id" "$l_repo_name" "${_g_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
                        "${_ga_artifact_subversions[${l_n}]}" ${l_n} $l_install_win_cmds
                done

                l_flag_setup_sucessfully=$g_flag_setup_sucessfully

            fi

            printf "\n"

        fi

    fi

    #Mostrar el status de la instalacion en Linux
    _g_install_repo_status[1]=$((l_flag_setup_begining + l_flag_setup_sucessfully))

    if [ $l_repo_is_beging_setup -ne 0 ]; then
        return 1
    fi

    return 0

}



#Un arreglo de asociativo cuyo key es el ID del repositorio hasta el momento procesados en el menu. El valor indica información del información de procesamiento.
#El procesamiento puede ser una configuración (instalación/actualización) o desinstalacíon.
#El valor almacenado para un repositorio es 'X|Y', donde:
#   X es el estado de la primera configuración y sus valores son:
#       '0' Si aun no ha iniciado su procesamiento del repositorio.
#       '1' Se inicio el procesamiento del repositorio pero termino debido no se cumple la precondiciones, por ejemplo:
#           - No se puede obtener correctamente los parametros repositorio (no se puede obtener la versión actual, ....).
#           - El repositorio no esta habilitado para que se procese en este sistema operativo.
#           - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
#       '2' Si se completo el procesamiento del repositorio con exito.
#       '3' Si se completo el procesamiento del repositorio pero con errores.
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


    if [ $p_input_options -le 0 ]; then
        return 99
    fi



    #1. Obtener los repositorios a configurar
    local l_aux="${ga_menu_options_repos[$l_i]}"

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

    #3. Inicializar la opción del menu
    local l_status
    local l_title_template

    if [ -z "$l_result" ]; then
   
        #3.1. Mostrar el titulo
        print_line '─' $g_max_length_line  "$g_color_opaque"
        printf -v l_title_template "Opción %s%s%s '%s%s%s'" "$g_color_opaque" "$l_option_value" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        print_text_in_center2 "$l_title_template" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"
        printf 'Inicializando la opción elegida del menu ...\n'

        #3.2. Inicializar la opcion si aun no ha sido inicializado.
        _initialize_menu_option_install_lnx $p_option_relative_idx
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
    local l_j=0

    local la_processed_repo_info
    local la_previous_options_idx
    local l_status_first_setup
    local l_repo_name_aux
    local l_k
    local l_l
    local l_exits_error=1

    local l_flag_process_next_repo=1      #(0) Se debe intentar procesar (intalar/actualizar o desinstalar) los repositorio de la opción del menu.
                                          #(1) No se debe intentar procesar los repositorios de la opción del menú.
    if [ -z "$l_result" ]; then
        l_flag_process_next_repo=0
    fi

    for((l_j=0; l_j < ${l_n}; l_j++)); do

        #Nombre a mostrar del respositorio
        l_repo_id="${la_repos[$l_j]}"
        l_repo_name_aux="${gA_repositories[$l_repo_id]:-$l_repo_id}"

        #4.1. Obtener el estado del repositorio antes de su instalación.
        l_aux=${lA_repos[$l_repo_id]:-0|}
        
        IFS='|'
        la_processed_repo_info=(${l_aux})
        IFS=$' \t\n'


        l_status_first_setup=${la_processed_repo_info[0]}    #'0' Si aun no ha iniciado su procesamiento del repositorio.
                                                             #'1' Se inicio el procesamiento del repositorio pero termino debido no se cumple la precondiciones, por ejemplo:
                                                             #    - No se pueden obtener correctamente los parametros requeridos del repositorio (no se puede obtener la versión actual, ....).
                                                             #    - El repositorio no esta habilitado para que se procese en este sistema operativo.
                                                             #    - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
                                                             #'2' Si se completo el procesamiento del repositorio con exito.
                                                             #'3' Si se completo el procesamiento del repositorio pero con errores.
        la_previous_options_idx=(${la_processed_repo_info[1]})

        #echo "Index '${p_option_relative_idx}/${l_j}', RepoID '${l_repo_id}', ProcessThisRepo '${l_flag_process_next_repo}', FisrtSetupStatus '${l_status_first_setup}', PreviousOptions '${la_previous_options_idx[@]}'"

        #4.2. Si la opción al cual pertenece el repositorio no fue selecionado, marcarlo como no configurado.
        if [ $l_flag_process_next_repo -ne 0 ]; then
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"
            #echo "A > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #4.3. Calcular la plantilla del titulo.
        printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
               "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"

        #4.4. Si anteriormente ya se ha configuro el repositorio

        #Si se ya configuró con exito
        if [ $l_status_first_setup -eq 2 ]; then

            print_line '-' $g_max_length_line "$g_color_opaque"
            printf "${p_title_template}\n" "ya se instalo"
            print_line '-' $g_max_length_line "$g_color_opaque"

            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))
            printf 'El repositorio "%s" ya se ha instalado con la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            #echo "B > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        #Si se inicio la configuración pero termino debido a que no se cumple las precondiciones (por ejemplo, el repositorio ya estaban actualizados)
        elif [ $l_status_first_setup -eq 1 ]; then

            print_line '-' $g_max_length_line "$g_color_opaque"
            printf "${p_title_template}\n" "esta actualizado"
            print_line '-' $g_max_length_line "$g_color_opaque"

            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))
            printf 'El repositorio "%s" se verifico que ya esta actualizado con la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            #echo "C > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        #Si se ya termino de configurarse pero se obtuvo errores en su configuración
        elif [ $l_status_first_setup -eq 3 ]; then

            print_line '-' $g_max_length_line "$g_color_opaque"
            printf "${p_title_template}\n" "ya se instalo con errores"
            print_line '-' $g_max_length_line "$g_color_opaque"

            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))
            printf 'El repositorio "%s" ya se ha instalado con errores con la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"

            #Detener la instalación
            printf 'Repare la configuración de este repositorio para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0
            #echo "D > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #4.5. Si es la primera vez que se configurar (el repositorios de la opción del menu), inicie la configuración
        
        i_install_repository "$l_repo_id" "$l_title_template" 1 
        l_status=$?

        #4.6. Si fallo en configurarse (instalación/configuración), detenga el proceso (y no se invoca a la finalización).

        #Si se envio parrametros incorrectos
        if [ $l_status -eq 99 ]; then
            printf 'No se pudo iniciar la configuración de este repositorio debido a los parametros incorrectos enviados.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
            #echo "E > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #Si no se pudo obtener la ultima versión del repositorio
        if [ $l_status -eq 98 ]; then
            printf 'No se pudo iniciar la configuración de este repositorio debido su ultima versión obtenida es invalida.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
            #echo "F > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #Si no se puedo iniciar la configuración del repositorio en ninguno de los 2 SO debido a que no se cumple la precondiciones requeridad (por ejemplo, ya estan actualizados)
        if [ $l_status -eq 1 ]; then

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
            #echo "G > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue

        fi

        #4.7. Si se inicio la configuración en almenos uno de los sistemas operativos ($l_status = 0)

        #Si hubo un error en la configuración del repositorio en Linux (se inicio la configruacion pero no concluyo exitosamente)
        l_k=${_g_install_repo_status[0]}          #Estado de la configuración en Linux
        if [ $((l_k & g_flag_setup_begining)) -eq $g_flag_setup_begining ]  && [ $((l_k & g_flag_setup_sucessfully)) -ne $g_flag_setup_sucessfully ]; then 
            
            printf 'Ocurrio un error en la configuración de este repositorio.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="3|${la_previous_options_idx[@]}"
            #echo "H > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #Si hubo un error en la configuración del repositorio en Windows vinculado al Linux WSL (se inicio la configruacion pero no concluyo exitosamente)
        l_l=${_g_install_repo_status[1]}          #Estado en la configuración en Windows
        if [ $((l_l & g_flag_setup_begining)) -eq $g_flag_setup_begining ]  && [ $((l_l & g_flag_setup_sucessfully)) -ne $g_flag_setup_sucessfully ]; then 
            
            printf 'Ocurrio un error en la configuración de este repositorio en Windows asociado al este Linux WSL.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="3|${la_previous_options_idx[@]}"
            #echo "I > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #Si no se pudo iniciar la configuración tanto en Linux como en Windows (no cumplica con las precondiciones requeridas para el sistema operativo, por ejemplo, ya esta actualizado o no se permite en el SO)
        if [ $((l_k & g_flag_setup_begining)) -ne $g_flag_setup_begining ]  && [ $((l_l & g_flag_setup_begining)) -ne $g_flag_setup_begining ]; then 
            
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo=["$l_repo_id"]="1|${la_previous_options_idx[@]}"
            #echo "J > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""
            continue
        fi

        #Si se configuro correctamente en algunos de los sistemas operativos Linux o en Windows (puede que en uno de ellos no se inicio la configuración pero ninguno obtuvo error)
        la_previous_options_idx+=(${p_option_relative_idx})
        _gA_processed_repo["$l_repo_id"]="2|${la_previous_options_idx[@]}"
        #echo "K > _gA_processed_repo['${l_repo_id}']=\"${_gA_processed_repo[$l_repo_id]}\""


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
        _finalize_menu_option_install_lnx $p_option_relative_idx
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

# Argumentos:
#  1 > Opciones relacionados con los repositorios que se se instalaran (entero que es suma de opciones de tipo 2^n).
#  2 > Flag '0' si es invocado directamente, caso contrario es invocado desde otro script.
function i_install_repositories() {
    
    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    local p_is_direct_calling=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_is_direct_calling=$2
    fi


    if [ $p_input_options -le 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
        return 99
    fi

    #2. Validar si fue descarga el repositorio git correspondiente
    if [ ! -d ~/.files/.git ]; then
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
    fi
    
    #3. Inicializaciones cuando se invoca directamente el script
    local l_flag=0
    if [ $p_is_direct_calling -eq 0 ]; then

        #3.1. Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_is_root -ne 0 ]; then

            #echo "Se requiere alamcenar temporalmente su password"
            sudo -v

            if [ $? -ne 0 ]; then
                echo "ERROR(20): Se requiere \"sudo -v\" almacene temporalmente su credenciales de root"
                return 20;
            fi
            printf '\n\n'
        fi

        #3.2. Instalacion de paquetes del SO
        l_flag=$(( $p_input_options & $g_opt_update_installed_pckg ))
        if [ $g_opt_update_installed_pckg -eq $l_flag ]; then

            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "- Actualizar los paquetes de los repositorio del SO Linux"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            
            #Segun el tipo de distribución de Linux
            case "$g_os_subtype_id" in
                1)
                    #Distribución: Ubuntu
                    if [ $g_is_root -eq 0 ]; then
                        apt-get update
                        apt-get upgrade
                    else
                        sudo apt-get update
                        sudo apt-get upgrade
                    fi
                    ;;
                2)
                    #Distribución: Fedora
                    if [ $g_is_root -eq 0 ]; then
                        dnf upgrade
                    else
                        sudo dnf upgrade
                    fi
                    ;;
                0)
                    echo "ERROR (30): No se identificado el tipo de Distribución Linux"
                    return 22;
                    ;;
            esac

        fi
    fi

    #5. Configurar (instalar/actualizar) los repositorios selecionados por las opciones de menú dinamico.
    #   Si la configuración de un repositorio de la opción de menú falla, se deteniene la configuración de la opción.

    local l_i=0
    #Limpiar el arreglo asociativo
    _gA_processed_repo=()

    for((l_i=0; l_i < ${#ga_menu_options_repos[@]}; l_i++)); do
        
        _install_menu_options $p_input_options $l_i

    done

    #echo "Keys de _gA_processed_repo=${!_gA_processed_repo[@]}"
    #echo "Values de _gA_processed_repo=${_gA_processed_repo[@]}"

    #6. Si el flag actualizar todos los instalados esta activo, actualizar todos los instalados que aun no fueron actualizado.
    #   Si la configuración de un repositorio de la opción de menú falla, se continua la configuración con la siguiente opción del menú
    local l_update_all_installed_repo=1
    if [ $((p_input_options & g_opt_update_installed_repo)) -eq $g_opt_update_installed_repo ]; then 
        l_update_all_installed_repo=0
    fi

    local l_repo_id
    local l_repo_name_aux
    local l_title_template
    local la_processed_repo_info
    #local la_previous_options_idx
    local l_status_first_setup
    local l_aux
    local l_j=0
    if [ $l_update_all_installed_repo -eq 0 ]; then

        #6.1. Mostrar el titulo
        print_line '─' $g_max_length_line  "$g_color_opaque"
        printf -v l_title_template "Opción %b%s%b '%bActualizando repositorios instalados%b'" "$g_color_opaque" "$g_opt_update_installed_repo" "$g_color_reset" "$g_color_subtitle" \
               "$g_color_reset"
        print_text_in_center2 "$l_title_template" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"
        printf '\n'

        #6.2. Actualizar los repositorios actualizados
        for l_repo_id in ${!_gA_processed_repo[@]}; do

            #A. Obtener el estado del repositorio despues de las instalación anterior
            l_aux=${_gA_processed_repo[$l_repo_id]:-0|}
            
            IFS='|'
            la_processed_repo_info=(${l_aux})
            IFS=$' \t\n'

            l_status_first_setup=${la_processed_repo_info[0]}    #'0' Si aun no ha iniciado su procesamiento del repositorio.
                                                                 #'1' Se inicio el procesamiento del repositorio pero termino debido no se cumple la precondiciones, por ejemplo:
                                                                 #    - No se pueden obtener correctamente los parametros requeridos del repositorio (no se puede obtener la versión actual, ....).
                                                                 #    - El repositorio no esta habilitado para que se procese en este sistema operativo.
                                                                 #    - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
                                                                 #'2' Si se completo el procesamiento del repositorio con exito.
                                                                 #'3' Si se completo el procesamiento del repositorio pero con errores.
            #la_previous_options_idx=(${la_processed_repo_info[1]})
            #echo "RepoID '${l_repo_id}', FisrtSetupStatus '${l_status_first_setup}', PreviousOptions '${la_previous_options_idx[@]}'"

            #B. Solo iniciar la configuración con lo repositorios que no se han iniciado su configuración
            if [ $l_status_first_setup -eq 0 ]; then

                #B.1. Valores iniciales
                l_repo_name_aux="${gA_repositories[$l_repo_id]:-$l_repo_id}"

                ((l_j++))

                #B.2. Calcular la plantilla del titulo.
                printf -v l_title_template "%s(%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$l_j" "$g_color_reset" "$g_color_subtitle" \
                       "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_opt_update_installed_repo" "$g_color_reset"

                #Configurar el respositorio, con el flag 'solo actulizar si esta instalado'
                i_install_repository "$l_repo_id" "$l_title_template" 0
            fi

        done

    fi

    #7. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 -a $p_is_direct_calling -eq 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}


function _show_menu_install_core() {

    print_text_in_center "Menu de Opciones (Install/Update)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_subtitle" "$g_color_reset"
    printf " (%ba%b) Actualizar los paquetes existentes del SO y los binarios de los repositorios existentes\n" "$g_color_subtitle" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    _get_length_menu_option $g_offset_option_index_menu_install
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes existentes del sistema operativo\n" "$g_color_subtitle" "$g_opt_update_installed_pckg" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar solo los repositorios de programas ya instalados\n" "$g_color_subtitle" "$g_opt_update_installed_repo" "$g_color_reset"

    _show_dynamic_menu 'Instalar o actualizar' $g_offset_option_index_menu_install $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque"

}


function i_main_install() {

    printf '%bOS Type            : (%s)\n' "$g_color_opaque" "$g_os_type"
    printf 'OS Subtype (Distro): (%s) %s - %s%b\n\n' "${g_os_subtype_id}" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR(21): El sistema operativo debe ser Linux"
        return 21;
    fi
   
    print_line '─' $g_max_length_line "$g_color_title" 

    _show_menu_install_core

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
                i_setup_repositories $l_value_option_a 0
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
                    i_install_repositories $l_options 0
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



#Es un arreglo con 2 valores enteros, el primero es el estado de la instalación en Linux, el segundo es el estado de la instalación en Windows.
#Cada estado tiene la suma de los algunos/todos los flag binarios:
#    000X -> Donde X=1 Si se inicio la desinstalación del repositorio.
#                  X=0 Si NO se inicio la desinstalación del repositorio debido a no se cumple las precondiciones requeridas. 
#                       - Se ingreso parametros incorrectos para al solicitar su desinstalación ('i_install_repository' y 'i_uninstall_repository' devuelven 99 o 98).
#                       - No se puede obtener correctamente los parametros del repositorio (no se puede obtener la versión actual, ....).
#                       - El repositorio no esta habilitado para que se procese en este sistema operativo.
#                       - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
#    00X0 -> Donde X=1 Si se desintaló el repositorio con exito,
#                  X=0 Si se desintaló el repositorio pero se obtuvo errores en el proceso.
declare -a _g_uninstall_repo_status

#Valor constante usada para generar el estado de la desinstalacíon de un repositorio
declare -r g_flag_uninstall_begining=1
declare -r g_flag_uninstall_successfully=2


#
#Permite instalar un repositorio en Linux (incluyendo a Windows vinculado a un Linux WSL)
#Un repositorio o se configura en Linux o Windows del WSL o ambos.
#
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se desconfigurará"). 
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#    0 > Se inicio la desinstalacíon (en por lo menos uno de los 2 SO o Windows), para ver el estado ver '_g_uninstall_repo_status'.
#    1 > No se inicio la desinstalacíon del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
#        - No se puede obtener correctamente los parametros del repositorio (no se puede obtener la versión actual, ....).
#        - El repositorio no esta habilitado para que se procese en este sistema operativo.
#        - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
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
    local l_status=0
    #local l_repo_name="${gA_repositories[$p_repo_id]}"
    #local l_repo_name_aux="${l_repo_name:-$p_repo_id}"
    
    _g_uninstall_repo_status=(0 0)




    #3. Iniciar la configuración en Linux: 
    local l_install_win_cmds=1
    
    local l_flag_uninstall_begining=0
    local l_flag_uninstall_sucessfully=0
    local l_repo_is_beging_uninstall=1

    #3.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?


    #3.2. Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then

        #A. Validar la versión actual con la ultima existente del repositorio.
        _validate_versions_to_uninstall "$p_repo_id" $l_install_win_cmds "$p_repo_title_template"
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede desintalarse si devuelve de [0, 9]:
                       #    0 > El repositorio se puede desintalar
                       #Si el repositorio NO puede desintalarse si devuelve de [10, 99]:
                       #   10 > No se ha implementado la logica para obtener la versión actual.
                       #   11 > La verisón actual del repositorio tiene formato invalido.
                       #   12 > El repositorio no esta instalado (por lo que no puede ser desintalado).
                       #   99 > Argumentos ingresados son invalidos


        #B. ¿El titulo se debe mostrar en la instalacion de Windows?
        if [ ! -z "$p_repo_title_template" ] && [ $l_status -ne 99 ]; then
            #Si ya se mostro no hacerlo nuevamente
            p_repo_title_template=""
        fi
            
        #C. Instalar el repositorio
        if [ $l_status -ge 0 ] && [ $l_status -le 9 ]; then

            l_repo_is_beging_uninstall=0
            l_flag_uninstall_begining=$g_flag_uninstall_begining

            _uninstall_repository "$p_repo_id" "$_g_repo_current_version" $l_install_win_cmds

            l_flag_uninstall_sucessfully=$g_flag_uninstall_successfully
        fi

        printf "\n"

    fi


    #Mostrar el status de la instalacion en Linux
    _g_uninstall_repo_status[0]=$((l_flag_uninstall_begining + l_flag_uninstall_sucessfully))




    #4. Iniciar la configuración en Windows:
    l_install_win_cmds=0
    
    l_flag_uninstall_begining=0
    l_flag_uninstall_sucessfully=0

    #4.1. Validar si el repositorio se puede configurarse en el sistema operativo.
    _can_setup_repository_in_this_so "$p_repo_id" $l_install_win_cmds
    l_status=$?

    #4.2. Si esta permitido configurarse en este sistema operativo, iniciar el proceso
    if [ $l_status -eq 0 ]; then

        #A. Validar la versión actual con la ultima existente del repositorio.
        _validate_versions_to_uninstall "$p_repo_id" "$l_repo_description" $l_show_title $l_install_win_cmds
        l_status=$?    #El valor de retorno puede ser:
                       #Si el repositorio puede desintalarse si devuelve de [0, 9]:
                       #    0 > El repositorio se puede desintalar
                       #Si el repositorio NO puede desintalarse si devuelve de [10, 99]:
                       #   10 > No se ha implementado la logica para obtener la versión actual.
                       #   11 > La verisón actual del repositorio tiene formato invalido.
                       #   12 > El repositorio no esta instalado (por lo que no puede ser desintalado).
                       #   99 > Argumentos ingresados son invalidos

            
        #B. Instalar el repositorio
        if [ $l_status -ge 0 ] && [ $l_status -le 9 ]; then

            l_repo_is_beging_uninstall=0
            l_flag_uninstall_begining=$g_flag_uninstall_begining

            _uninstall_repository "$p_repo_id" "$_g_repo_current_version" $l_install_win_cmds

            l_flag_uninstall_sucessfully=$g_flag_uninstall_successfully

        fi


        printf "\n"

    fi

    #Mostrar el status de la instalacion en Windows
    _g_uninstall_repo_status[1]=$((l_flag_uninstall_begining + l_flag_uninstall_sucessfully))

    if [ $l_repo_is_beging_uninstall -ne 0 ]; then
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
    local l_aux="${ga_menu_options_repos[$l_i]}"

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
        printf -v l_title_template "Opción %s%s%s '%s%s%s'" "$g_color_opaque" "$l_option_value" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_relative_idx}]}" "$g_color_reset"
        print_text_in_center2 "$l_title_template" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"
        printf 'Inicializando la opción elegida del menu ...\n'

        #3.2. Inicializar la opcion si aun no ha sido inicializado.
        _initialize_menu_option_uninstall_lnx $p_option_relative_idx
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
    local l_j=0

    local la_processed_repo_info
    local la_previous_options_idx
    local l_status_first_setup
    local l_repo_name_aux
    local l_k
    local l_l
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

        l_repo_name_aux="${gA_repositories[$l_repo_id]:-$l_repo_id}"

        #4.1. Obtener el estado del repositorio antes de su desinstalación.
        l_aux=${gA_repositories[$l_repo_id]:-0|}
        
        IFS='|'
        la_processed_repo_info=(${l_aux})
        IFS=$' \t\n'


        l_status_first_setup=${la_processed_repo_info[0]}    #'0' Si aun no ha iniciado su procesamiento del repositorio.
                                                             #'1' Se inicio el procesamiento del repositorio pero termino debido no se cumple la precondiciones, por ejemplo:
                                                             #    - No se pueden obtener correctamente los parametros requeridos del repositorio (no se puede obtener la versión actual, ....).
                                                             #    - El repositorio no esta habilitado para que se procese en este sistema operativo.
                                                             #    - No se puede actualizar porque ya estaban actualizados o no se puede desintalar porque no esta instalado.
                                                             #'2' Si se completo el procesamiento del repositorio con exito.
                                                             #'3' Si se completo el procesamiento del repositorio pero con errores.
        la_previous_options_idx=(${la_processed_repo_info[1]})

        #4.2. Si la opción al cual pertenece el repositorio no fue selecionado, marcarlo como no configurado.
        if [ $l_flag_process_next_repo -ne 0 ]; then
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="0|${la_previous_options_idx[@]}"
            continue
        fi

        #4.3. Calcular la plantilla del titulo.
        printf -v l_title_template "%s(%s/%s)%s> El repositorio '%s%s%s' %s%%s%s %s(opción de menu %s)%s" "$g_color_opaque" "$((l_j + 1))" "$l_n" "$g_color_reset" "$g_color_subtitle" \
               "$l_repo_name_aux" "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_option_value" "$g_color_reset"

        #4.4. Si anteriormente ya se ha configuro el repositorio

        #Si se ya desintaló con exito
        if [ $l_status_first_setup -eq 2 ]; then

            print_line '-' $g_max_length_line "$g_color_opaque"
            printf "${p_title_template}\n" "ya se instalo"
            print_line '-' $g_max_length_line "$g_color_opaque"

            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))
            printf 'El repositorio "%s" ya se ha desinstalado con la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            continue

        #Si se completo la desinstalación debido a que no cumple las precondiciones (por ejemplo: no esta instalado)
        elif [ $l_status_first_setup -eq 1 ]; then

            print_line '-' $g_max_length_line "$g_color_opaque"
            printf "${p_title_template}\n" "no instalado"
            print_line '-' $g_max_length_line "$g_color_opaque"

            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))
            printf 'El repositorio "%s" se verifico que no esta instalado con la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"
            continue

        #Si se ya se intento desintalarlo pero se obtuvo errores en su configuración
        elif [ $l_status_first_setup -eq 3 ]; then

            print_line '-' $g_max_length_line "$g_color_opaque"
            printf "${p_title_template}\n" "ya se instalo con errores"
            print_line '-' $g_max_length_line "$g_color_opaque"

            l_k=${la_previous_options_idx[0]}
            l_aux=$((1 << (l_k + g_offset_option_index_menu_install)))
            printf 'El repositorio "%s" ya se intento desintalarlo pero se obtuvo errores usando la opción del menu %s ("%s")\n' "$l_repo_id" "$l_aux" "${ga_menu_options_title[$l_k]}"

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="${l_status_first_setup}|${la_previous_options_idx[@]}"

            #Detener la instalación
            printf 'Repare la configuración de este repositorio para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0
            continue
        fi

        #4.5. Si es la primera vez que se desinstala (el repositorios de la opción del menu), inicie su desinstalación
        
        i_uninstall_repository "$l_repo_id" "$l_title_template"
        l_status=$?

        #4.6. Si fallo en la desinstalación, detenga el proceso (y no se invoca a la finalización).

        #Si se envio parrametros incorrectos
        if [ $l_status -eq 99 ]; then
            printf 'No se pudo iniciar la desinstalación de este repositorio debido a los parametros incorrectos enviados.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
            continue
        fi

        #Si no se pudo obtener 
        #if [ $l_status -eq 98 ]; then
        #    printf 'No se pudo iniciar la desinstalación de este repositorio debido XXXX.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
        #    l_flag_process_next_repo=1
        #    l_exits_error=0

        #    la_previous_options_idx+=(${p_option_relative_idx})
        #    _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
        #    continue
        #fi

        #Si no se puedo iniciar la desinstalación en ninguno los SO debido a que no se cumple con los precondiciones (no se obtiene la version actual, no esta instalado, ...)
        if [ $l_status -eq 1 ]; then

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
            continue

        fi

        #4.7. Si se inicio la desinstalación en almenos uno de los SO ($l_status = 0)

        #Si hubo un error en la desinstalación del repositorio en Linux (se inicio la configruacion pero no concluyo exitosamente)
        l_k=${_g_install_repo_status[0]}          #Estado de la configuración en Linux
        if [ $((l_k & g_flag_setup_begining)) -eq $g_flag_setup_begining ]  && [ $((l_k & g_flag_setup_sucessfully)) -ne $g_flag_setup_sucessfully ]; then 
            
            printf 'Ocurrio un error en la desinstalación de este repositorio.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="3|${la_previous_options_idx[@]}"
            continue
        fi

        #Si hubo un error en la desinstalación del repositorio en Windows vinculado al Linux WSL (se inicio la configruacion pero no concluyo exitosamente)
        l_l=${_g_install_repo_status[1]}          #Estado en la configuración en Windows
        if [ $((l_l & g_flag_setup_begining)) -eq $g_flag_setup_begining ]  && [ $((l_l & g_flag_setup_sucessfully)) -ne $g_flag_setup_sucessfully ]; then 
            
            printf 'Ocurrio un error en la desinstalación de este repositorio en Windows asociado al este Linux WSL.\nCorrija el error para continuar con configuración de los demas repositorios de la opción del menú.\n'
            l_flag_process_next_repo=1
            l_exits_error=0

            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="3|${la_previous_options_idx[@]}"
            continue
        fi

        #Si no se pudo iniciar la desinstalación tanto en Linux como en Windows (no estaba permitido para el sistema operativo o ya estaba actualizado)
        if [ $((l_k & g_flag_setup_begining)) -ne $g_flag_setup_begining ]  && [ $((l_l & g_flag_setup_begining)) -ne $g_flag_setup_begining ]; then 
            
            la_previous_options_idx+=(${p_option_relative_idx})
            _gA_processed_repo["$l_repo_id"]="1|${la_previous_options_idx[@]}"
            continue
        fi

        #Si se desinstaló correctamente en algunos de los sistemas operativos Linux o en Windows (puede que en uno de ellos no se inicio la configuración pero ninguno obtuvo error)
        la_previous_options_idx+=(${p_option_relative_idx})
        _gA_processed_repo["$l_repo_id"]="2|${la_previous_options_idx[@]}"


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
        printf 'Se inicia la finalización de la opción del menu...\n'
        _finalize_menu_option_uninstall_lnx $p_option_relative_idx
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


# Argumentos:
#  1 > Opciones relacionados con los repositorios que se se instalaran (entero que es suma de opciones de tipo 2^n).
#  2 > Flag '0' si es invocado directamente, caso contrario es invocado desde otro script.
function i_uninstall_repositories() {
    
    #1. Argumentos 
    local p_input_options=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    local p_is_direct_calling=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_is_direct_calling=$2
    fi

    if [ $p_input_options -eq 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_opciones}\" es incorrecta"
        return 23;
    fi

    #2. Validar si fue descarga el repositorio git correspondiente
    if [ ! -d ~/.files/.git ]; then
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
    fi
    
    #3. Inicializaciones cuando se invoca directamente el script
    local l_flag=0
    if [ $p_is_direct_calling -eq 0 ]; then

        #3.1. Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_is_root -ne 0 ]; then

            #echo "Se requiere alamcenar temporalmente su password"
            sudo -v

            if [ $? -ne 0 ]; then
                echo "ERROR(20): Se requiere \"sudo -v\" almacene temporalmente su credenciales de root"
                return 20;
            fi
            printf '\n\n'
        fi

    fi

    #5. Configurar (Desintalar) los diferentes repositorios
    local l_i=0
    #Limpiar el arreglo asociativo
    _gA_processed_repo=()


    for((l_i=0; l_i < ${#ga_menu_options_repos[@]}; l_i++)); do

        _uninstall_menu_options $p_input_options $l_i

    done

    #echo "Keys de _gA_processed_repo=${!_gA_processed_repo[@]}"
    #echo "Values de _gA_processed_repo=${_gA_processed_repo[@]}"

    #6. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 -a $p_is_direct_calling -eq 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}


function _show_menu_uninstall_core() {

    print_text_in_center "Menu de Opciones (Uninstall)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_subtitle" "$g_color_reset"
    printf " ( ) Para desintalar ingrese un opción o la suma de las opciones que desea configurar:\n"

    _get_length_menu_option $g_offset_option_index_menu_uninstall
    local l_max_digits=$?

    _show_dynamic_menu 'Desinstalar' $g_offset_option_index_menu_uninstall $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque" 

}


function i_main_uninstall() {

    printf '%bOS Type            : (%s)\n' "$g_color_opaque" "$g_os_type"
    printf 'OS Subtype (Distro): (%s) %s - %s%b\n\n' "${g_os_subtype_id}" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR: El sistema operativo debe ser Linux"
        return 21;
    fi
   
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


_usage() {

    printf '%bUsage:\n\n' "$g_color_opaque"
    printf '  > Mostrar el menu para desintalar repositorios:\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash uninstall\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Mostrar el menu para instalar repositorios:\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar uno o mas repositorios (sin menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 1 MENU-OPTIONS\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar un repositorio (sin menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 2 REPO-ID%b\n\n' "$g_color_info" "$g_color_reset"

}


#}}}


#Argumentos del script
gp_uninstall=1          #(0) Para instalar/actualizar
                        #(1) Para desintalar

gp_type_calling=0       #(0) Es llamado directa, es decir se muestra el menu.
                        #(1) Instalando un conjunto de respositorios
                        #(2) Instalando solo un repository

if [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
elif [ "$1" = "uninstall" ]; then
    gp_uninstall=0
elif [ ! -z "$1" ]; then
    printf 'Argumentos invalidos.\n\n'
    _usage
    exit 97
fi


gp_install_all_user=0   #(0) Se instala/configura para ser usuado por todos los usuarios (si es factible).
                        #    Requiere ejecutar con privilegios de administrador.
                        #(1) Solo se instala/configura para el usuario actual (no requiere ser administrador).

#if [[ "$2" =~ ^[0-9]+$ ]]; then
#    gp_install_all_user=$2
#fi

#Logica principal del script

#1. Desintalar los artefactos de un repoistorio
if [ $gp_uninstall -eq 0 ]; then

    i_main_uninstall

#2. Instalar y actualizar los artefactos de un repositorio
else

    #2.1. Por defecto, mostrar el menu para escoger lo que se va instalar
    if [ $gp_type_calling -eq 0 ]; then
    
        i_main_install
    
    #2.2. Instalando los repositorios especificados por las opciones indicas en '$2'
    elif [ $gp_type_calling -eq 1 ]; then
    
        gp_opciones=0
        if [[ "$2" =~ ^[0-9]+$ ]]; then
            gp_opciones=$2
        else
            exit 98
        fi
        i_install_repositories $gp_opciones 1
    
    #2.3. Instalando un solo repostorio del ID indicao por '$2'
    else
    
        gp_repo_id="$2"
        if [ -z "$gp_repo_id" ]; then
           echo "Parametro 2 \"$2\" debe ser un ID de repositorio valido"
           exit 99
        fi
    
        i_install_repository "$gp_repo_id" "" 1
    
    fi

    
fi


