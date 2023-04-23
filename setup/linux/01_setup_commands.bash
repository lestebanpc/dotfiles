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

#}}}


#Funciones genericas {{{


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

function _intall_repository() { 

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
    
    declare -a la_artifact_names
    declare -a la_artifact_types
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

#}}}


#Codigo principal del script {{{


function i_setup_repository() {

    #1. Argumentos 
    local p_repo_id="$1"

    local p_repo_can_setup=1
    if [ "$2" = "0" ]; then
        p_repo_can_setup=0
    fi

    local p_must_update_all_installed_repo=1
    if [ "$3" = "0" ]; then
        p_must_update_all_installed_repo=0
    fi

    local p_option_idx=-1
    if [[ "$4" =~ ^[0-9]+$ ]]; then
        p_option_idx=$4
    fi

    local p_option_repo_tag="$5"

    #1. Validaciones iniciales
    local l_status=0
    
    #Si no se puede configurar y no se debe actualizar, salir
    if [ $p_repo_can_setup -ne 0 ] && [ $p_must_update_all_installed_repo -ne 0 ]; then
        return 80
    fi

    #2. Nombre a mostrar el respositorio
    local l_repo_name_aux
    local l_repo_name="${gA_repositories[$p_repo_id]}"
    if [ -z "$l_repo_name" ]; then
        l_repo_name_aux="$p_repo_id"
    else
        l_repo_name_aux="$l_repo_name"
    fi

    #3. Obtneer la ultima version del repositorio
    declare -a la_repo_versions
    declare -a la_arti_versions
    _get_repo_latest_version "$p_repo_id" "$l_repo_name" la_repo_versions la_arti_versions
    l_status=$?
    #echo "Subversiones: ${la_arti_versions[@]}"

    #Si ocurrio un error al obtener la versión
    if [ $l_status -ne 0 ]; then

        if [ $l_status -ne 1 ]; then
            echo "ERROR: Primero debe tener a 'jq' en el PATH del usuario para obtener la ultima version del repositorio \"$p_repo_id\""
        else
            echo "ERROR: Ocurrio un error al obtener la ultima version del repositorio \"$p_repo_id\""
        fi
        return 81
    fi

    #si el arreglo de menos de 2 elementos
    local l_n=${#la_repo_versions[@]}
    if [ $l_n -lt 2 ]; then
        echo "ERROR: La configuración actual, no obtuvo las 2 formatos de la ultima versiones del repositorio \"${p_repo_id}\""
        return 82
    fi
    #echo "Repositorio - Ultimas Versiones : \"${l_n}\""

    #Version usada para descargar la version (por ejemplo 'v3.4.6', 'latest', ...)
    local l_repo_last_version=${la_repo_versions[0]}

    #Version usada para comparar versiones (por ejemplo '3.4.6', '0.8.3', ...)
    local l_repo_last_version_pretty=${la_repo_versions[1]}
    if [[ ! "$l_repo_last_version_pretty" =~ ^[0-9] ]]; then
        l_repo_last_version_pretty=""
    fi
       
    if [ -z "$l_repo_last_version" ]; then
        echo "ERROR: La ultiva version del repositorio \"$p_repo_id\" no puede ser vacia"
        return 83
    fi
   
    local l_arti_versions_nbr=${#la_arti_versions[@]} 
    #Si la ultima version amigable es vacia, no se podra comparar las versiones, pero se esta permitiendo configurar el repositorio
    #if [ -z "$l_repo_last_version_pretty" ]; then
    #    echo "ERROR: La ultiva version amigable del repositorio \"$p_repo_id\" no puede ser vacia"
    #    return 84
    #fi
    
    #Etiqueta para identificar el repositorio que se usara en lo logs cuando se instala
    local l_tag="${p_repo_id}"
    if [ ! -z "${l_repo_last_version_pretty}" ]; then
        l_tag="${l_tag}[${l_repo_last_version_pretty}]"
    else
        l_tag="${l_tag}[...]"
    fi

    #4. Iniciar la configuración en Linux: 
    local l_install_win_cmds=1
    
    #Obtener la versión de repositorio instalado en Linux
    local l_repo_current_version=""
    local l_repo_is_installed=0
    l_repo_current_version=$(_get_repo_current_version "$p_repo_id" ${l_install_win_cmds} "")
    l_repo_is_installed=$?          #(9) El repositorio unknown porque no se implemento la logica
                                    #(3) El repositorio unknown porque no se puede obtener (siempre instalarlo)
                                    #(1) El repositorio no esta instalado 
                                    #(0) El repositorio instalado, con version correcta
                                    #(2) El repositorio instalado, con version incorrecta

    #Obtener el valor inicial del flag que indica si se debe configurar el paquete
    local l_repo_must_setup_lnx=1  #(1) No debe configurarse, (0) Debe configurarse (instalarse/actualizarse)

    if [ $p_repo_can_setup -ne 0 ]; then
       #Si no se puede configurar, pero el flag de actualización de un repo existente esta habilitado: instalarlo
       if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ] && [ $p_must_update_all_installed_repo -eq 0 ]; then
           l_repo_must_setup_lnx=0
       else
           l_repo_must_setup_lnx=1
       fi
    else
       l_repo_must_setup_lnx=0
    fi

    #Obtener las opciones de configuración del repositorio. 
    #  > Puede ser uno o la suma de los siguientes valores:
    #    1 (00001) Linux No-WSL2 (que no WSL2)
    #    2 (00010) Linux WSL2
    #    8 (00100) Windows vinculado al Linux WSL2
    #  > Si no se especifica, su valor es 11 (se instala en todo lo permitido.
    local l_repo_config=${gA_repo_config[${p_repo_id}]}
    if [ -z "$l_repo_config" ]; then
        l_repo_config=11
    fi

    #Repositorios especiales que no deberia instalarse segun el tipo de distribución Linux
    local l_flag
    if [ $l_repo_must_setup_lnx -eq 0 ]; then

        #Si es Linux
        if [ $g_os_type -ge 0 ] && [ $g_os_type -le 10 ]; then

            #Si es Linux WSL2
            if [ $g_os_type -eq 1 ]; then

                #Si no se usa el flag '2' (Linux WSL2), no configurarlo
                l_flag=$(($l_repo_config & 2))
                if [ $l_flag -ne 2 ]; then
                    l_repo_must_setup_lnx=1
                fi

            #Si es Linux No-WSL2
            else

                #Si no se usa el flag '1' (Linux No-WSL2), no configurarlo
                l_flag=$(($l_repo_config & 1))
                if [ $l_flag -ne 1 ]; then
                    l_repo_must_setup_lnx=1
                fi
            fi
            
        #Si no es Linux: No configurar
        else
            l_repo_must_setup_lnx=1
        fi

    fi

    #5. Setup el repositorio en Linux
    local l_aux=''
    local l_title_is_showed=1
    if [ $l_repo_must_setup_lnx -eq 0 ]; then

        #5.1 Mostrar el titulo
        if [ $p_option_idx -ge 0 ]; then

            print_line '-' $g_max_length_line  "$g_color_opaque"
            l_aux="$((1 << ${p_option_idx}))"

            if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ]; then
                printf "> Actualizando el repositorio %b%s%b '%b%s%b' de la opción %b%s%b (%b%s%b)\n" "$g_color_opaque" "$p_option_repo_tag" "$g_color_reset" "$g_color_subtitle" "$l_repo_name_aux" \
                       "$g_color_reset" "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_idx}]}" "$g_color_reset"
            elif [ $l_repo_is_installed -eq 1 ]; then
                printf "> Instalando el repositorio %b%s%b '%b%s%b' de la opción %b%s%b (%b%s%b)\n" "$g_color_opaque" "$p_option_repo_tag" "$g_color_reset" "$g_color_subtitle" "$l_repo_name_aux" \
                       "$g_color_reset" "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_idx}]}" "$g_color_reset"
            else
                printf "> Configurar el repositorio %b%s%b '%b%s%b' de la opción %b%s%b (%b%s%b)\n" "$g_color_opaque" "$p_option_repo_tag" "$g_color_reset" "$g_color_subtitle" "$l_repo_name_aux" \
                       "$g_color_reset" "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_idx}]}" "$g_color_reset"
            fi

            print_line '-' $g_max_length_line  "$g_color_opaque"
            l_title_is_showed=0

        fi

        echo "Iniciando la configuración de los artefactos del repositorio \"${l_repo_name_aux}\" en Linux \"${g_os_subtype_name}\""
        printf 'Repositorio "%s" usara el nombre "%s"\n' "${p_repo_id}" "${l_repo_name}"
        printf 'Repositorio "%s[%s]" (Ultima Versión): "%s"\n' "${p_repo_id}" "${l_repo_last_version_pretty}" "${l_repo_last_version}"
        if [ $l_arti_versions_nbr -ne 0 ]; then
            for ((l_n=0; l_n<${l_arti_versions_nbr}; l_n++)); do
                printf 'Repositorio "%s[%s]" (Ultima Versión): Sub-version[%s] es "%s"\n' "${p_repo_id}" "${l_repo_last_version_pretty}" \
                       "${l_n}" "${la_arti_versions[${l_n}]}"
            done
        fi

        #5.2 Segun la version del repositorio actual, habilitar la instalación 
        if [ $l_repo_is_installed -eq 9 ]; then
            printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No implementado"
            echo "ERROR: Debe implementar la logica para determinar la version actual de repositorio instalado"
            l_repo_must_setup_lnx=1
        else
            #Si se tiene implementado la logica para obtener la version actual o se debe instalar sin ella
            if [ $l_repo_is_installed -eq 1 ]; then
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No instalado"
            elif [ $l_repo_is_installed -eq 2 ]; then
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "Formato invalido"
                l_repo_current_version=""
            elif [ $l_repo_is_installed -eq 3 ]; then
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "No se puede calcular"
            else
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "OK"
            fi
        fi

        #5.3 Comparando versiones y segun ello, habilitar la instalación
        if [ $l_repo_must_setup_lnx -eq 0 ]; then
   
            #Comparando las versiones
            if [ ! -z "$l_repo_last_version_pretty" ] && [ $l_repo_is_installed -ne 3 ]; then
                 
                #compare_version "${p_repo_current_version}" "${l_repo_last_version_pretty}"
                compare_version "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                l_status=$?

                if [ $l_status -eq 0 ]; then
                    printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                    l_repo_must_setup_lnx=1
                elif [ $l_status -eq 1 ]; then
                    printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                    l_repo_must_setup_lnx=1
                else
                    if [ -z "${l_repo_current_version}" ]; then
                        printf 'Repositorio "%s[%s]" se instalará\n' "${p_repo_id}" "${l_repo_last_version_pretty}"
                    else
                        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                    fi
                fi

            else
                printf 'Repositorio "%s[%s]" (Versión Actual): No se pueden comparar con la versión "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
            fi
             
        fi
    

        #5.4 Instalar el repositorio
        if [ $l_repo_must_setup_lnx -eq 0 ]; then

            if [ $l_arti_versions_nbr -eq 0 ]; then
                printf "\nSe iniciara la configuración de los artefactos del repositorio \"${l_tag}\" ...\n"
                _intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds
            else
                for ((l_n=0; l_n<${l_arti_versions_nbr}; l_n++)); do
                    l_aux="${l_tag}[${la_arti_versions[${l_n}]}]"
                    printf "\n\nSe iniciara la configuración de los artefactos del repositorio \"${l_aux}\" ...\n"
                    _intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
                        "${la_arti_versions[${l_n}]}" ${l_n} $l_install_win_cmds
                done
            fi
        fi

        printf "\n\n"
       
    fi

    #4. Iniciar la configuración en Windows:
    l_install_win_cmds=0
    
    #Si no es Linux WSL, salir
    if [ $g_os_type -ne 1 ]; then
        return 89
    fi

    #Obtener la versión de repositorio instalado en Windows
    l_repo_current_version=$(_get_repo_current_version "$p_repo_id" ${l_install_win_cmds} "")
    l_repo_is_installed=$?          #(9) El repositorio unknown (no implementado la logica)
                                    #(3) El repositorio unknown porque no se puede obtener (siempre instalarlo)
                                    #(1) El repositorio no esta instalado 
                                    #(0) El repositorio instalado, con version correcta
                                    #(2) El repositorio instalado, con version incorrecta

    #Obtener el valor inicial del flag que indica si se debe configurar el paquete
    local l_repo_must_setup_win=1  #(1) No debe configurarse, (0) Debe configurarse (instalarse/actualizarse)

    if [ $p_repo_can_setup -ne 0 ]; then
       #Si no se puede configurar, pero el flag de actualización de un repo existente esta habilitado: instalarlo
       if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ] && [ $p_must_update_all_installed_repo -eq 0 ]; then
           l_repo_must_setup_win=0
       else
           l_repo_must_setup_win=1
       fi
    else
       l_repo_must_setup_win=0
    fi


    #Repositorios especiales que no deberia instalarse en Windows (siempre vinculado a un Linux WSL2)
    if [ $l_repo_must_setup_win -eq 0 ]; then

        #Si es Linux WSL2
        if [ $g_os_type -eq 1 ]; then

            #Si no se usa el flag '8' (Windows vinculado al Linux WSL2), no configurarlo
            l_flag=$(($l_repo_config & 8))
            if [ $l_flag -ne 8 ]; then
                l_repo_must_setup_win=1
            fi

        #Si es Linux No-WSL2, no se configura
        else
            l_repo_must_setup_win=1
        fi

    fi

    #7. Setup el repositorio en Windows
    if [ $l_repo_must_setup_win -eq 0 ]; then
        
        #7.1 Mostrar el titulo
        if [ $l_title_is_showed -ne 0 ] && [ $p_option_idx -ge 0 ]; then

            print_line '-' $g_max_length_line  "$g_color_opaque"
            l_aux="$((1 << ${p_option_idx}))"

            if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ]; then
                printf "> Actualizando el repositorio %b%s%b '%b%s%b' de la opción %b%s%b (%b%s%b)\n" "$g_color_opaque" "$p_option_repo_tag" "$g_color_reset" "$g_color_subtitle" "$l_repo_name_aux" \
                       "$g_color_reset" "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_idx}]}" "$g_color_reset"
            elif [ $l_repo_is_installed -eq 1 ]; then
                printf "> Instalando el repositorio %b%s%b '%b%s%b' de la opción %b%s%b (%b%s%b)\n" "$g_color_opaque" "$p_option_repo_tag" "$g_color_reset" "$g_color_subtitle" "$l_repo_name_aux" \
                       "$g_color_reset" "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_idx}]}" "$g_color_reset"
            else
                printf "> Configurar el repositorio %b%s%b '%b%s%b' de la opción %b%s%b (%b%s%b)\n" "$g_color_opaque" "$p_option_repo_tag" "$g_color_reset" "$g_color_subtitle" "$l_repo_name_aux" \
                       "$g_color_reset" "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_subtitle" "${ga_menu_options_title[${p_option_idx}]}" "$g_color_reset"
            fi

            print_line '-' $g_max_length_line  "$g_color_opaque"

        fi

        echo "Iniciando la configuración de los artefactos del repositorio \"${l_repo_name_aux}\" en Windows (asociado al WSL \"${g_os_subtype_name}\")"
        printf 'Repositorio "%s" usara el nombre "%s"\n' "${p_repo_id}" "${l_repo_name}"
        printf 'Repositorio "%s[%s]" (Ultima Versión): "%s"\n' "${p_repo_id}" "${l_repo_last_version_pretty}" "${l_repo_last_version}"
        if [ $l_arti_versions_nbr -ne 0 ]; then
            for ((l_n=0; l_n<${l_arti_versions_nbr}; l_n++)); do
                printf 'Repositorio "%s[%s]" (Ultima Versión): Sub-version[%s] es "%s"\n' "${p_repo_id}" "${l_repo_last_version_pretty}" \
                       "${l_n}" "${la_arti_versions[${l_n}]}"
            done
        fi

        #7.2 Segun la version del repositorio actual, habilitar la instalación 
        if [ $l_repo_is_installed -eq 9 ]; then
            printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No implementado"
            echo "ERROR: Debe implementar la logica para determinar la version actual de repositorio instalado"
            l_repo_must_setup_win=1
        else
            #Si se tiene implementado la logica para obtener la version actual o se debe instalar sin ella
            if [ $l_repo_is_installed -eq 1 ]; then
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "..." "No instalado"
            elif [ $l_repo_is_installed -eq 2 ]; then
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "Formato invalido"
                l_repo_current_version=""
            elif [ $l_repo_is_installed -eq 3 ]; then
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "No se puede calcular"
            else
                printf 'Repositorio "%s[%s]" (Versión Actual): "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "OK"
            fi
        fi
        

        #7.3 Comparando versiones y segun ello, habilitar la instalación
        if [ $l_repo_must_setup_win -eq 0 ]; then
    
            #Comparando las versiones
            if [ ! -z "$l_repo_last_version_pretty" ] && [ $l_repo_is_installed -ne 3 ]; then
                 
                #compare_version "${p_repo_current_version}" "${l_repo_last_version_pretty}"
                compare_version "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                l_status=$?

                if [ $l_status -eq 0 ]; then
                    printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                    l_repo_must_setup_win=1
                elif [ $l_status -eq 1 ]; then
                    printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                    l_repo_must_setup_win=1
                else
                    if [ -z "${l_repo_current_version}" ]; then
                        printf 'Repositorio "%s[%s]" se instalará\n' "${p_repo_id}" "${l_repo_last_version_pretty}"
                    else
                        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                    fi
                fi

            else
                printf 'Repositorio "%s[%s]" (Versión Actual): No se pueden comparar con la versión "%s"\n' "${p_repo_id}" "${l_repo_current_version}" "${l_repo_last_version_pretty}"
            fi

        fi

        #7.4 Instalar el repositorio
        if [ $l_repo_must_setup_win -eq 0 ]; then

            if [ $l_arti_versions_nbr -eq 0 ]; then
                printf '\nSe iniciara la configuración de los artefactos del repositorio "%s" ...\n' "${l_tag}"
                _intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds
            else
                for ((l_n=0; l_n<${l_arti_versions_nbr}; l_n++)); do
                    l_aux="${l_tag}[${la_arti_versions[${l_n}]}]"
                    printf '\n\nSe iniciara la configuración de los artefactos del repositorio "%s" ...\n' "${l_aux}"
                    _intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
                        "${la_arti_versions[${l_n}]}" ${l_n} $l_install_win_cmds
                done
            fi

        fi

        printf "\n\n"
       
    fi

}


# Argunentos:
# - Repositorios opcionales que se se instalaran (flag en binario. entero que es suma de 2^n).
# - Si es invocado desde otro script, su valor es 1 y no se solicita las credenciales sudo. Si el script se invoca directamente, es 0
function i_setup_repositories() {
    
    #1. Argumentos 
    local p_opciones=2
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local p_is_direct_calling=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_is_direct_calling=$2
    fi

    if [ $p_opciones -eq 0 ]; then
        echo "ERROR(23): Argumento de opciones \"${p_opciones}\" es incorrecta"
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

        #3.2. Instalacion de paquetes del SO
        l_flag=$(( $p_opciones & $g_opt_update_installed_pckg ))
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

    #5. Configurar (Instalar o Actualizar) los diferentes repositorios
    
    #Determinar si si se requiere actualizar todos los  repositorio instalados.
    local l_must_update_all_installed_repo=1
    l_flag=$(( $p_opciones & $g_opt_update_installed_repo ))
    if [ $l_flag -eq $g_opt_update_installed_repo ]; then l_must_update_all_installed_repo=0; fi

    #Validar que opciones del menu seleccionó el usuario y los repositorios que deben configurarse
    local l_i=0
    local l_j=0
    local l_n
    local l_aux
    local l_option
    local l_option_is_selected
    local IFS=','
    local la_repos
    for((l_i=0; l_i < ${#ga_menu_options_repos[@]}; l_i++)); do

        #Por defecto la opcion es la selecionada para configurarse
        l_option_is_selected=1

        #Si no tiene repositorios a instalar, omitirlos
        l_aux="${ga_menu_options_repos[$l_i]}"
        if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
            continue
        fi

        #La opción actual se debe instalar?
        l_option=$((1 << (l_i + g_offset_index_option_menu)))
        l_flag=$(( $p_opciones & $l_option ))

        if [ $l_option -eq $l_flag ]; then 
            l_option_is_selected=0; 
        else
            #Si no se solicita instalar repositorios instalados, continuar
            if [ $l_must_update_all_installed_repo -ne 0 ]; then
                continue
            fi
        fi

        #Obtener los repositorios a configurar
        IFS=','
        la_repos=(${l_aux})
        IFS=$' \t\n'

        l_n=${#la_repos[@]}
        if [ $l_n -le 0 ]; then
            continue
        fi

        for((l_j=0; l_j < ${l_n}; l_j++)); do

            #Instalar el repositorio
            i_setup_repository "${la_repos[$l_j]}" $l_option_is_selected $l_must_update_all_installed_repo $l_i "$((l_j + 1))/${l_n}"
        done

    done


    #6. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 -a $p_is_direct_calling -eq 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}


function _show_menu_core() {

    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_subtitle" "$g_color_reset"
    printf " (%ba%b) Actualizar los paquetes existentes del SO y los binarios de los repositorios existentes\n" "$g_color_subtitle" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    _get_length_menu_option
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes existentes del sistema operativo\n" "$g_color_subtitle" "$g_opt_update_installed_pckg" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar solo los repositorios de programas ya instalados\n" "$g_color_subtitle" "$g_opt_update_installed_repo" "$g_color_reset"

    _show_dynamic_menu $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque" 

}

function i_main() {

    printf '%bOS Type            : (%s)\n' "$g_color_opaque" "$g_os_type"
    printf 'OS Subtype (Distro): (%s) %s - %s%b\n\n' "${g_os_subtype_id}" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR(21): El sistema operativo debe ser Linux"
        return 21;
    fi
   
    print_line '#' $g_max_length_line "$g_color_title" 

    _show_menu_core

    local l_flag_continue=0
    local l_options=""
    local l_value_option_a=$(($g_opt_update_installed_pckg + $g_opt_update_installed_repo))
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '#' $g_max_length_line "$g_color_title" 
                printf '\n'
                i_setup_repositories $l_value_option_a 0
                ;;

            q)
                l_flag_continue=1
                print_line '#' $g_max_length_line "$g_color_title" 
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
                    print_line '#' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    i_setup_repositories $l_options 0
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


#}}}


#Argumentos del script 
gp_type_calling=0       #(0) Es llamado directa, es decir se muestra el menu.
                        #(1) Instalando un conjunto de respositorios
                        #(2) Instalando solo un repository
if [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
fi


gp_install_all_user=0   #(0) Se instala/configura para ser usuado por todos los usuarios (si es factible).
                        #    Requiere ejecutar con privilegios de administrador.
                        #(1) Solo se instala/configura para el usuario actual (no requiere ser administrador).

#if [[ "$2" =~ ^[0-9]+$ ]]; then
#    gp_install_all_user=$2
#fi

#Logica principal del script
#0. Por defecto, mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    i_main

#1. Instalando los repositorios especificados por las opciones indicas en '$2'
elif [ $gp_type_calling -eq 1 ]; then

    gp_opciones=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_opciones=$2
    else
        exit 98
    fi
    i_setup_repositories $gp_opciones 1

#3. Instalando un solo repostorio del ID indicao por '$2'
else

    gp_repo_id="$2"
    if [ -z "$gp_repo_id" ]; then
       echo "Parametro 3 \"$3\" debe ser un ID de repositorio valido"
       exit 99
    fi

    i_setup_repository "$gp_repo_id" 0 0 -1 ""

fi


