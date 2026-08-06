#!/bin/bash

# Obtenido y modificado de https://github.com/junegunn/fzf-git.sh

# Constantes
g_fzf_height='60%'
g_fzf_popup_height='80%'
g_fzf_popup_width='99%'

# Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cyan1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

# Obtener la del script
g_script_path="${BASH_SOURCE[0]}"


g_kubectl_cmd="kubectl"

g_cmd_name='k8su'

declare -a ga_exported_functions=(
        "show_object_yaml"
        "show_namespace_info"
        "show_pod_info"
        "show_pods_table"
        "show_log_pod"
        "port_forward_pod"
        "show_container_info"
        "show_containers_table"
        "show_log_container"
        "show_deployment_info"
        "show_deployment_table"
        "show_log_dply"
        "show_replicaset_info"
        "show_replicasets_table"
        "show_dply_revision1"
        "show_dply_revision2"
        "open_terminal1"
        "open_terminal2"
    )

# Diccionario de subcomandos de nivel 1.
# > La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_CMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'm_controller_CMD-ID'.
declare -A gA_subcmd_ids=(
        ['get']='Lista los objetos de un recurso k8s especifico'
        ['logs']='Obtiene los logs de pod de un namespace y los almacena en archivos de texto'
        #['delete']='Elimina pod de un namespace, descargado antes sus archivos logs'
        ['restart']='Reinicia los pod de deployment(s) de un namespace, descargando antes sus archivos logs'
    )

# Diccionario de alias de subcomandos de nivel 1.
# > La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_subcmd_alias=(
    )

# Diccionario de subcomandos de nivel 2: Subcomandos para el subcomando 'get'
# > La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
declare -A gA_get_subcmd_ids=(
        ['resource']='Lista los objeto de un recurso k8s especifico'
        ['project']='Lista los proyectos de cluster openshift'
        ['namespace']='Lista los namespaces de un cluster k8s'
        ['pod']='Lista los pod de un namespace especifico'
        ['container']='Lista los contenedor de los pod dentro de un namespace'
        ['deployment']='Lista los deployments de un determinado namespace'
        ['replicaset']='Lista los deployments de un determinado namespace'
    )

#
# > Para 'kubectl', en caso de existir, se usara el "short-names" del recursos:
#    componentstatuses          = cs
#    configmaps                 = cm
#    endpoints                  = ep
#    events                     = ev
#    limitranges                = limits
#    namespaces                 = ns
#    nodes                      = no
#    persistentvolumeclaims     = pvc
#    persistentvolumes          = pv
#    pods                       = po
#    replicationcontrollers     = rc
#    resourcequotas             = quota
#    serviceaccounts            = sa
#    services                   = svc
#    customresourcedefinitions  = crd, crds
#    daemonsets                 = ds
#    deployments                = deploy
#    replicasets                = rs
#    statefulsets               = sts
#    horizontalpodautoscalers   = hpa
#    cronjobs                   = cj
#    certificiaterequests       = cr, crs
#    certificates               = cert, certs
#    certificatesigningrequests = csr
#    ingresses                  = ing
#    networkpolicies            = netpol
#    podsecuritypolicies        = psp
#    replicasets                = rs
#    scheduledscalers           = ss
#    priorityclasses            = pc
#    storageclasses             = sc
#
# Diccionario de alias de subcomandos de nivel 1: Alias de subcomandos para el subcomando 'get'
declare -A gA_get_subcmd_alias=(
        ['ns']='namespace'
        ['po']='pod'
        ['deploy']='deployment'
        ['rs']='replicaset'
    )


# Carpetas de archivos temporales
g_tmpfile_path="${XDG_RUNTIME_DIR:-/tmp}/myfiles"
if [ ! -d "$g_tmpfile_path" ]; then
    mkdir -p "$g_tmpfile_path"
fi

declare -r g_max_length_line=110


# Sufijo unico del nombre del archivo temporal unico que almacena la data de los subcomando get.
# > El archivo se caracteriza por:
#   > No colisiona entre usuarios.
#   > No colisiona entre sesiones simultáneas.
# > Se calcula cuando se ejecuta un subcomando 'get'.
g_tmpfile_suffix=""


#Plantilla de opciones usando en las acciones FZF, cuyo formato es "resource-type/[resource-name] -n=[namespace]"
#  > "[resource-name]" puede ser el nombre del recurso o "{n}" donde n es el numero de campo donde se obtendra.
#  > "[namespace]" puede ser el nombre del namespace o "{n}" donde n es el numero de campo donde se obtendra.
_g_fzf_kc_options=""

#Nombre del archivo de dato
_g_temfile_fullpath=""

_g_data_object_json=""

declare -i _g_use_cache_before=1
declare -i _g_preserve_cache_after=1

declare -i _g_use_one_object=1


# -------------------------------------------------------------------------------------
# General functions > Genericas
# -------------------------------------------------------------------------------------

# Sufijo unico del nombre del archivo temporal unico que almacena la data de los subcomando get.
# > El archivo se caracteriza por:
#   > No colisiona entre usuarios.
#   > No colisiona entre sesiones simultáneas.
m_get_tmpfile_suffix() {

    local l_tty=$(tty | sed 's#^/dev/##; s#/##g')

    # Usando
    # > Se limpia automáticamente al cerrar la última sesión del usuario.
    # > No dependes de políticas de limpieza de /tmp
    local l_suffix=''
    if [ ! -z "$XDG_RUNTIME_DIR" ]; then

        if [ ! -z "$XDG_SESSION_ID" ]; then
            l_suffix="ses${XDG_SESSION_ID}_${l_tty}"
        else
            l_suffix="${l_tty}_pid$$"
        fi

    else

        local l_uid="${UID}"
        if [ -z "$l_uid" ]; then
            l_uid=$(id -u)
        fi

        if [ ! -z "$XDG_SESSION_ID" ]; then
            l_suffix="uid${l_uid}_ses${XDG_SESSION_ID}_${l_tty}"
        else
            l_suffix="uid${l_uid}_${l_tty}_pid$$"
        fi

    fi

    echo "$l_suffix"

}


# -------------------------------------------------------------------------------------
# General functions > Show Menu
# -------------------------------------------------------------------------------------

#Parametros de entrada:
#  1 > caracter de la cual esta formada la linea
#  2 > Tamaño de caracteres la linea
#  3 > Color de la linea
print_line() {

    printf '%b' "$3"
    #Usar -- para no se interprete como linea de comandos y puede crearse lienas con - (usado en opcion de un comando)
    printf -- "${1}%.0s" $(seq $2)
    printf '%b\n' "$g_color_reset"

}

# Obtener los alias asociados del subcomando ID
m_get_alias_by_subcmd_id() {

    if [ -z "$1" ]; then
        return 0
    fi
    local -n rA_subcmd_alias="$1"

    if [ -z "$2" ]; then
        return 0
    fi
    local p_scmd_id="$2"

    # Obtener los alias del comando
    local l_alias_list=''
    local l_alias
    local l_id

    for l_alias in "${!rA_subcmd_alias[@]}"; do

        l_id="${rA_subcmd_alias[${l_alias}]}"

        if [ "$l_id" = "$p_scmd_id" ]; then
            if [ -z "$l_alias_list" ]; then
                printf -v l_alias_list "'%b%s%b'" "$g_color_yellow1" "$l_alias" "$g_color_reset"
            else
                printf -v l_alias_list "%b, '%b%s%b'" "$l_alias_list" "$g_color_yellow1" "$l_alias" "$g_color_reset"
            fi
        fi

    done

    echo "$l_alias_list"
    return 0

}


m_get_subcmd_infos() {

    if [ -z "$1" ]; then
        return 0
    fi
    local -n rA_subcmd_ids="$1"

    local p_varname_subcmd_alias="$2"

    local l_scmd_id
    local l_scmd_description
    local l_alias
    local l_alias_list
    local l_id

    for l_scmd_id in "${!rA_subcmd_ids[@]}"; do

        printf "%b  > %b%s%b\n" "$g_color_gray1" "$g_color_yellow1" "$l_scmd_id" "$g_color_reset"

        # Obtener los alias del comando
        if [ ! -z "$p_varname_subcmd_alias" ]; then

            l_alias_list=$(m_get_alias_by_subcmd_id "$p_varname_subcmd_alias" "$l_scmd_id")

            # Mostrar el alias:
            if [ ! -z "$l_alias_list" ]; then
                printf '%b    Alias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
            fi

        fi

        # Mostrar la descripcion
        l_scmd_description="${rA_subcmd_ids[${l_scmd_id}]}"
        printf "    %b%s%b\n" "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    done


}



# -------------------------------------------------------------------------------------
# General functions > kubectl utils
# -------------------------------------------------------------------------------------

#Argumentos:
#  1 > Si es 0, se muestra el default Namespace
_fzf_kc_get_context_info() {

    #TODO mejorar para obtener la URL del servidor, nombre del usuario, ...
    local l_data=$(${g_kubectl_cmd} config current-context)
    local l_tmp="${l_data//// }"
    local l_items=($l_tmp)
    local l_n=${#l_items[@]}

    local l_color_1="\x1b[91m"
    local l_color_2="\x1b[33m"
    local l_color_3="\x1b[92m"
    #local l_color_opaque="\x1b[90m"
    local l_color_reset="\x1b[0m"

    if [ $l_n -lt 3 ]; then
        printf "Context: '%b%s%b'" "$l_color_1" "${l_data}" "$l_color_reset"
    else
        if [ "$1" = "0" ]; then
            printf "User: '%b%s%b', Server: '%b%s%b', Default Namespace: '%b%s%b'" "$l_color_1" "${l_items[2]}" "$l_color_reset" "$l_color_2" "${l_items[1]}" "$l_color_reset" "$l_color_3" "${l_items[2]}" "$l_color_reset"
        else
            printf "User: '%b%s%b', Server: '%b%s%b'" "$l_color_1" "${l_items[2]}" "$l_color_reset" "$l_color_2" "${l_items[1]}" "$l_color_reset"
        fi
    fi
}


m_get_pod_logs() {

    #1. Argumentos
    local p_pod_name="$1"
    local p_pod_ns="$2"
    local p_path_dir="$3"

    local -i p_flag_show_timestamp=1
    if [ "$4" = "0" ]; then
        p_flag_show_timestamp=0
    fi

    local -i p_flag_save_json=1
    if [ "$5" = "0" ]; then
        p_flag_save_json=0
    fi

    local -i p_flag_save_all_main=1
    if [ "$6" = "0" ]; then
        p_flag_save_all_main=0
    fi

    local -i p_flag_save_all_init=1
    if [ "$7" = "0" ]; then
        p_flag_save_all_init=0
    fi

    local -i p_flag_save_all_ephemeral=1
    if [ "$8" = "0" ]; then
        p_flag_save_all_ephemeral=0
    fi

    local -i p_file_sufix_nodename=1
    if [ "$9" = "0" ]; then
        p_file_sufix_nodename=0
    fi

    local -i p_file_sufix_containername=0
    if [ "${10}" != "0" ]; then
        p_file_sufix_containername=1
    fi

    local -i p_file_sufix_time=1
    if [ "${11}" = "0" ]; then
        p_file_sufix_time=0
    fi

    #2. Obtener el descriptor json del pod
    local l_data_json
    local -i l_status=0
    l_data_json=$(${g_kubectl_cmd} get pod -n "$p_pod_ns" "$p_pod_name" -o json 2> /dev/null)
    l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_data_json" ]; then
        printf 'No se puede obtener el descriptor del pod "%b%s%b/%b%s%b".\n' "$g_color_gray1" "$p_pod_ns" "$g_color_reset" \
                "$g_color_gray1" "$p_pod_name" "$g_color_reset"
        return 1
    fi

    #3. Obtener el sufijo fijo del pod
    local l_suffix_begin=''
    local l_tmp

    # Obtener el nombre del nodo donde esta el pod
    l_tmp=$(echo "$l_data_json" | jq -r '.spec.nodeName')

    if [ ! -z "$l_tmp" ]; then

        printf '  NodeName         : %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"

        if [ $p_file_sufix_nodename -eq 0 ]; then
            l_suffix_begin="_${l_tmp}"
        fi

    fi

    local l_suffix_end=''
    if [ $p_file_sufix_time -eq 0 ]; then
        l_suffix_end="_$(date +'%Y%m%d_%H%M')"
    fi

    if [ $p_flag_show_timestamp -eq 0 ]; then
        printf '  Features         : %bshow timestamps%b\n' "$g_color_gray1" "$g_color_reset"
    else
        printf '  Features         : not %bshow timestamps%b\n' "$g_color_gray1" "$g_color_reset"
    fi


    #4. Obtener los contenedores principales
    local -a la_containers_main=()

    # Obtener el contenedor por defecto
    l_tmp=$(echo "$l_data_json" | jq -r '.metadata.annotations."kubectl.kubernetes.io/default-container"')
    l_status=$?
    if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ] && [ "$l_tmp" != "null" ]; then
        printf '  Default Container: %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"
        la_containers_main=(${l_tmp})
    else
        l_tmp=""
    fi

    #echo "l_flag_save_all_main: ${p_flag_save_all_main}"

    if [ -z "$l_tmp" ] || [ $p_flag_save_all_main -eq 0 ]; then
        l_tmp=$(echo "$l_data_json" | jq -r '.spec.containers[].name')
        la_containers_main=(${l_tmp})
    fi

    #5. Obtener los contenedores de inicializacion
    local -a la_containers_init=()
    if [ $p_flag_save_all_init -eq 0 ]; then
        l_tmp=$(echo "$l_data_json" | jq -r '.spec.initContainers[]?.name')
        l_status=$?

        if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ] && [ "$l_tmp" != "null" ]; then
            la_containers_init=(${l_tmp})
        fi
    fi

    #6. Obtener los contenedores epheremal
    local -a la_containers_ephemeral=()
    if [ $p_flag_save_all_ephemeral -eq 0 ]; then
        l_tmp=$(echo "$l_data_json" | jq -r '.spec.ephemeralContainers[]?.name')
        l_status=$?

        if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ] && [ "$l_tmp" != "null" ]; then
            la_containers_ephemeral=(${l_tmp})
        fi
    fi

    #7. Almacenar el descriptor
    local l_filename
    if [ $p_flag_save_json -eq 0 ]; then

        l_filename="${p_pod_name}${l_suffix_begin}${l_suffix_end}.json"
        if [ ! -z "$p_path_dir" ]; then
            l_filename="${p_path_dir}/${l_filename}"
        fi

        printf '  Descriptor       : %b%s%b\n' "$g_color_gray1" "$l_filename" "$g_color_reset"
        echo "$l_data_json" > "$l_filename"
        #echo "$l_data_json" | jq "." > "$l_filename"

    fi


    #8. Mostrar los log de los contenedores
    local l_container_name

    local -i l_i=0
    local -i l_n=0
    l_n=${#la_containers_main[@]}

    # Mostrar los logs de los contenedores principales
    local l_container_json2
    local l_jq_query2='.status?.containerStatuses[]? | select(.name == $container)'
    local l_restart_count=0

    if [ $l_n -gt 0 ]; then

        if [ $p_flag_save_all_main -eq 0 ]; then
            printf '  > Main Containers     : %b%s%b (%ball%b)\n' "$g_color_gray1" "$l_n" "$g_color_reset" \
                   "$g_color_gray1" "$g_color_reset"
        else
            l_n=1
            printf '  > Main Containers     : %b%s%b (%bonly-one%b)\n' "$g_color_gray1" "$l_n" "$g_color_reset" \
                   "$g_color_gray1" "$g_color_reset"
        fi

        for((l_i = 0; l_i < l_n; l_i++)); do

            # Obtener el contenedor
            l_container_name="${la_containers_main[$l_i]}"
            if [ -z "$l_container_name" ]; then
                continue
            fi

            printf '    Container name      : %b%s%b\n' "$g_color_gray1" "$l_container_name" "$g_color_reset"

            # Obtener el estado del contenedor
            l_container_json2=$(echo "$l_data_json" | jq --arg container "$l_container_name" "$l_jq_query2")
            l_status=$?

            if [ $l_status -eq 0 ] && [ ! -z "$l_data_json" ] && [ "$l_data_json" != "null" ]; then

                # Nombre de la imagen (usando tag)
                l_tmp=$(echo "$l_container_json2" | jq -r '.image')
                l_status=$?

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                    printf '    Image               : %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"
                fi

                # Nombre de la imagen (usando hash)
                l_tmp=$(echo "$l_container_json2" | jq -r '.imageID')
                l_status=$?

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                    printf '    Image ID            : %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"
                fi

                # Reinicios del contenedor
                l_tmp=$(echo "$l_container_json2" | jq -r '.restartCount')
                l_status=$?

                l_restart_count=0

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then

                    l_restart_count="$l_tmp"
                    if [ "$l_restart_count" != "0"  ]; then
                        printf '    Restart Count       : %b%s%b\n' "$g_color_gray1" "$l_restart_count" "$g_color_reset"
                    fi
                fi

            fi

            # Obtener el nombre de archivo del log
            if [ $p_file_sufix_containername -eq 0 ]; then
                l_filename="${p_pod_name}${l_suffix_begin}_${l_container_name}${l_suffix_end}"
            else
                l_filename="${p_pod_name}${l_suffix_begin}${l_suffix_end}"
            fi

            if [ ! -z "$p_path_dir" ]; then
                l_filename="${p_path_dir}/${l_filename}"
            fi
            printf '    Log filename        : %b%s%b\n' "$g_color_gray1" "${l_filename}.log" "$g_color_reset"

            # Mostrar el log del contenedor
            if [ $p_flag_show_timestamp -eq 0 ]; then
                printf '    %b%s logs%b -n "%s" "%s" -c "%s" --timestamps > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                       "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}.log" "$g_color_reset"
                ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" --timestamps > "${l_filename}.log"
            else
                printf '    %b%s logs%b -n "%s" "%s" -c "%s" > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                       "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}.log" "$g_color_reset"
                ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" > "${l_filename}.log"
            fi

            # TODO Improvement
            # Si el numero de reinicios es mayor a 0 y el estado actual es diferente a 'Completed' o 'Running', almacenar el log '--previous' o '-p'
            if [ "$l_restart_count" -gt 0 ]; then

                if [ $p_flag_show_timestamp -eq 0 ]; then
                    ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" -p --timestamps > "${l_filename}_previous.log" 2> /dev/null
                    l_status=$?
                else
                    ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" -p > "${l_filename}_previous.log" 2> /dev/null
                    l_status=$?
                fi

                if [ $l_status -eq 0 ]; then

                    printf '    Previous log        : %b%s%b\n' "$g_color_gray1" "${l_filename}_previous.log" "$g_color_reset"
                    if [ $p_flag_show_timestamp -eq 0 ]; then
                        printf '    %b%s logs%b -n "%s" "%s" -c "%s" -p --timestamps > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                               "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}_previous.log" "$g_color_reset"
                    else
                        printf '    %b%s logs%b -n "%s" "%s" -c "%s" -p > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                               "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}_previous.log" "$g_color_reset"
                    fi

                else
                    printf '    Previous log        : %b%s%b\n' "$g_color_gray1" "none" "$g_color_reset"
                fi

            fi


        done

    fi

    # Mostrar los logs de los contenedores de inicializacion
    l_n=${#la_containers_init[@]}

    if [ $l_n -gt 0 ]; then

        printf '  > Init Containers     : %b%s%b\n' "$g_color_gray1" "$l_n" "$g_color_reset"

        l_jq_query2='.status?.initContainerStatuses[]? | select(.name == $container)'

        for((l_i = 0; l_i < l_n; l_i++)); do

            # Obtener el contenedor
            l_container_name="${la_containers_init[$l_i]}"
            if [ -z "$l_container_name" ]; then
                continue
            fi

            printf '    Container name      : %b%s%b\n' "$g_color_gray1" "$l_container_name" "$g_color_reset"

            # Obtener el estado del contenedor
            l_container_json2=$(echo "$l_data_json" | jq --arg container "$l_container_name" "$l_jq_query2")
            l_status=$?

            if [ $l_status -eq 0 ] && [ ! -z "$l_data_json" ] && [ "$l_data_json" != "null" ]; then

                # Nombre de la imagen (usando tag)
                l_tmp=$(echo "$l_container_json2" | jq -r '.image')
                l_status=$?

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                    printf '    Image               : %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"
                fi

                # Nombre de la imagen (usando hash)
                l_tmp=$(echo "$l_container_json2" | jq -r '.imageID')
                l_status=$?

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                    printf '    Image ID            : %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"
                fi

                # Reinicios del contenedor
                l_tmp=$(echo "$l_container_json2" | jq -r '.restartCount')
                l_status=$?

                l_restart_count=0

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then

                    l_restart_count="$l_tmp"
                    if [ "$l_restart_count" != "0"  ]; then
                        printf '    Restart Count       : %b%s%b\n' "$g_color_gray1" "$l_restart_count" "$g_color_reset"
                    fi
                fi

            fi

            # Obtener el nombre de archivo del log
            if [ $p_file_sufix_containername -eq 0 ]; then
                l_filename="${p_pod_name}${l_suffix_begin}_${l_container_name}${l_suffix_end}"
            else
                l_filename="${p_pod_name}${l_suffix_begin}${l_suffix_end}"
            fi

            if [ ! -z "$p_path_dir" ]; then
                l_filename="${p_path_dir}/${l_filename}"
            fi
            printf '    Log filename        : %b%s%b\n' "$g_color_gray1" "${l_filename}.log" "$g_color_reset"

            # Mostrar el log del contenedor
            if [ $p_flag_show_timestamp -eq 0 ]; then
                printf '    %b%s logs%b -n "%s" "%s" -c "%s" --timestamps > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                       "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}.log" "$g_color_reset"
                ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" --timestamps > "${l_filename}.log"
            else
                printf '    %b%s logs%b -n "%s" "%s" -c "%s" > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                       "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}.log" "$g_color_reset"
                ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" > "${l_filename}.log"
            fi

            # Si el numero de reinicios es mayor a 0 y el estado actual es diferente a 'Completed' o 'Running', almacenar el log '--previous' o '-p'

        done

    fi

    # Mostrar los logs de los contenedores de inicializacion
    l_n=${#la_containers_ephemeral[@]}

    if [ $l_n -gt 0 ]; then

        printf '  > Ephemeral containers: %b%s%b\n' "$g_color_gray1" "$l_n" "$g_color_reset"

        l_jq_query2='.status?.ephemeralContainerStatuses[]? | select(.name == $container)'
        for((l_i = 0; l_i < l_n; l_i++)); do

            # Obtener el contenedor
            l_container_name="${la_containers_ephemeral[$l_i]}"
            if [ -z "$l_container_name" ]; then
                continue
            fi

            printf '    Container name      : %b%s%b\n' "$g_color_gray1" "$l_container_name" "$g_color_reset"

            # Obtener el estado del contenedor
            l_container_json2=$(echo "$l_data_json" | jq --arg container "$l_container_name" "$l_jq_query2")
            l_status=$?

            if [ $l_status -eq 0 ] && [ ! -z "$l_data_json" ] && [ "$l_data_json" != "null" ]; then

                # Nombre de la imagen (usando tag)
                l_tmp=$(echo "$l_container_json2" | jq -r '.image')
                l_status=$?

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                    printf '    Image               : %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"
                fi

                # Nombre de la imagen (usando hash)
                l_tmp=$(echo "$l_container_json2" | jq -r '.imageID')
                l_status=$?

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                    printf '    Image ID            : %b%s%b\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"
                fi

                # Reinicios del contenedor
                l_tmp=$(echo "$l_container_json2" | jq -r '.restartCount')
                l_status=$?

                l_restart_count=0

                if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then

                    l_restart_count="$l_tmp"
                    if [ "$l_restart_count" != "0"  ]; then
                        printf '    Restart Count       : %b%s%b\n' "$g_color_gray1" "$l_restart_count" "$g_color_reset"
                    fi
                fi

            fi

            # Obtener el nombre de archivo del log
            if [ $p_file_sufix_containername -eq 0 ]; then
                l_filename="${p_pod_name}${l_suffix_begin}_${l_container_name}${l_suffix_end}"
            else
                l_filename="${p_pod_name}${l_suffix_begin}${l_suffix_end}"
            fi

            if [ ! -z "$p_path_dir" ]; then
                l_filename="${p_path_dir}/${l_filename}"
            fi
            printf '    Log filename        : %b%s%b\n' "$g_color_gray1" "${l_filename}.log" "$g_color_reset"

            # Mostrar el log del contenedor
            if [ $p_flag_show_timestamp -eq 0 ]; then
                printf '    %b%s logs%b -n "%s" "%s" -c "%s" --timestamps > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                       "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}.log" "$g_color_reset"
                ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" --timestamps > "${l_filename}.log"
            else
                printf '   %b%s logs%b -n "%s" "%s" -c "%s" > %b%s%b\n' "$g_color_blue1" "$g_kubectl_cmd" "$g_color_gray1" \
                       "$p_pod_ns" "$p_pod_name" "$l_container_name" "$g_color_blue1" "${l_filename}.log" "$g_color_reset"
                ${g_kubectl_cmd} logs -n "$p_pod_ns" "$p_pod_name" -c "$l_container_name" > "${l_filename}.log"
            fi

            # Si el numero de reinicios es mayor a 0 y el estado actual es diferente a 'Completed' o 'Running', almacenar el log '--previous' o '-p'

        done

    fi

    return 0

}




# -------------------------------------------------------------------------------------
# Exported functions
# -------------------------------------------------------------------------------------

#Parametros (argumentos y opciones) de entrada:
#  1 > Pod del contenedor donde se ejecuta el comando
#  2 > Namespace (si se especifica se usa el por namespace actual).
#  3 > Contenedor.
#  4 > Comando (nombre, opciones y argumentos) a ejecutar.
#  5 > Use el flag 0 si se abre un terminal /dev/tty en el contenedor.
#  6 > Use el flag 0 si se envia el flujo de entrada 'stdin' del proceso actual al contenedor.
#  7 > Use el flag 0 si desea un modo 'quiet' que solo imprime el 'stdout' del contenedor al proceso actual.
_exec_cmd() {

    #1. Calcular los argumentos del comando y mostrar el mensaje de bienvenida
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    #Objetos asociados a conjuntos de pods/contenedores
    printf 'Pod       : "%b%s%b"\n' "$l_color_1" "$1" "$g_color_reset"
    local l_options="$1"

    #Namespace
    if [ ! -z "$2" ]; then
        printf 'Namespace : "%b%s%b"\n' "$l_color_2" "$2" "$g_color_reset"
        l_options="-n=${2} ${l_options}"
    fi

    #Contenedor
    if [ ! -z "$3" ]; then
        printf 'Container : "%b%s%b"\n' "$l_color_2" "$3" "$g_color_reset"
        l_options="-c=${3} ${l_options}"
    fi

    #Flag para abrir un terminal /dev/tty en el contenedor
    if [ $5 -eq 0 ]; then
        l_options="-t ${l_options}"
    fi

    #Flag para el flujo de entrada 'stdin' del proceso actual al contenedor
    if [ $6 -eq 0 ]; then
        l_options="-i ${l_options}"
    fi

    #Flag de modo 'quiet'
    if [ $7 -eq 0 ]; then
        l_options="-q ${l_options}"
    fi

    #Comando
    if [ ! -z "$4" ]; then
        l_options="${l_options} -- $4"
    fi

    printf 'Commnad   : "%b%s exec %s%b"\n\n' "$l_color_2" "$g_kubectl_cmd" "${l_options}" "$g_color_reset"

    #2. Ejecutar el comando
    ${g_kubectl_cmd} exec ${l_options}

    return 0

}




#Parametros (argumentos y opciones) de entrada:
#  1 > Nombre del pod
#  2 > Namespace (si no se especifica se usa el namespace actual).
#  3 > Interprete shell.
#  4 > Modo exit (si es 0, sale de fzf)
#  5 > Archivos de datos.
open_terminal1() {

    local l_mode_exit=1
    if [ "$4" = "0" ]; then
        l_mode_exit=0
    fi

    local -i p_use_one_object=1
    if [ "$6" = "0"  ]; then
        p_use_one_object=0
    fi

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    local l_jq_query
    local l_data_object_json

    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='[.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | { containers: .spec.containers, statuses: .status.containerStatuses } | { container: .containers[], statuses: .statuses } | .container.name as $name | { spec: .container, status: (.statuses[] | select(.name == $name)) } | select(.status.started) ]'

        l_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$5" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    else

        l_jq_query='[ { containers: .spec.containers, statuses: .status.containerStatuses } | { container: .containers[], statuses: .statuses } | .container.name as $name | { spec: .container, status: (.statuses[] | select(.name == $name)) } | select(.status.started) ]'

        l_data_object_json=$(cat "$5" | jq "$l_jq_query" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    fi

    #1. Obtener informacion de los contenedores del pod que tiene puertos (y luego limpiar esta data temporal)

    #Obtener el arreglo de los contenedores habilitados ({ spec: .spec.containers[x], status: .status.containerStatuses[x] } donde x esta vinculado al mismo contenedor).

    if [ "$l_data_object_json" = "[]" ]; then
        printf "No existe contenedores en ejecución en el pod.\n"
        return 2
    fi

    #Eliminar la data temporal
    if [ $l_mode_exit -eq 0 ] && [ ! -z "$5" ]; then
        rm -f $5
    fi


    #2. Obtener datos ingresado por el usuario y requeridos para ejecutar la el comando
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    #2.1. Obtener los nombres de los contenedores (manteniendo el orden del arreglo como estan declarados)
    local l_data
    l_jq_query='[ .[].spec.name ] | join("|")'

    l_data=$(echo "$l_data_object_json" | jq -r "$l_jq_query")
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data los nombres de los contenedores del pod.\n"
        return 3
    fi

    local IFS='|'
    local la_containers=($l_data)
    IFS=$' \t\n'
    local l_n=${#la_containers[@]}

    if [ $l_n -lt 1 ]; then
        printf "No existe contenedores en ejecución dentro del pod.\n"
        return 4
    fi

    #2.2 Capturar el nombre de contenedor ingresado por el usuario
    local l_in_opcion
    local l_container

    local l_i=-1

    if [ $l_n -gt 1 ]; then

        printf 'Ingrese valores de los parametros requeridos para mostrar el log:\n\n'
        printf "> Choose the container %bthe following table%b:\n\n" "$g_color_gray1" "$g_color_reset"

        #Mostrando la tabla con los contenodores
        l_jq_query='[. | to_entries[] | { IDX: .key, NAME: .value.spec.name, PORTS: (if .value.spec.ports == null then "" else ([.value.spec.ports[] | select(.protocol == "TCP") | .containerPort] | join(",")) end), IMAGE: .value.spec.image }]'
        l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
        if [ $? -ne 0 ]; then
            printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
            return 5
        fi

        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
            return 6
        else
            echo "$l_data" | jtbl -n
            printf '\n'
        fi

        #Eligiendo la posicion correcta
        l_i=-1
        while [ $l_i -lt 0  ]; do

            #
            printf "  Choose IDX container %b(Ingrese un entero desde 0 hasta %s)%b" "$g_color_gray1" "$((l_n - 1))" "$g_color_reset"
            read -r -p ": " l_in_option

            if [[ "$l_in_option" =~ ^[0-9]+$ ]]; then
                l_i=$l_in_option

                if [ $l_i -ge $l_n  ] || [ $l_i -lt 0 ]; then
                    l_i=-1
                    printf "  %bEl entero debe ser 0 hasta %s inclusive%b\n" "$g_color_gray1" "$((l_n - 1))" "$g_color_reset"
                fi

            else
                printf "  %bIngrese un entero desde 0 hasta %s inclusive%b\n" "$g_color_gray1" "$((l_n - 1))" "$g_color_reset"
                l_i=-1
            fi

        done

    else
        l_i=0
    fi

    #Contenedor elegido
    l_container=${la_containers[${l_i}]}

    printf '\n'
    _exec_cmd "$1" "$2" "$l_container" "$3" 0 0 1


}



#Parametros (argumentos y opciones) de entrada:
#  1 > Nombre del pod
#  2 > Namespace (si no se especifica se usa el namespace actual).
#  3 > Nombre del contenedor
#  4 > Interprete shell.
#  5 > Modo exit (si es 0, sale de fzf)
#  6 > Archivos de datos.
open_terminal2() {

    local l_mode_exit=1
    if [ "$5" = "0" ]; then
        l_mode_exit=0
    fi

    local -i p_use_one_object=1
    if [ "$7" = "0"  ]; then
        p_use_one_object=0
    fi

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    local l_jq_query
    local l_data_object_json

    #Obtener el objeto del contenedores si esta iniciado ({ spec: .spec.containers[x], status: .status.containerStatuses[x] } donde x esta vinculado al mismo contenedor).
    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $podName and .metadata.namespace == $objNS) | { containers: .spec.containers, statuses: .status.containerStatuses } | { container: .containers[], statuses: .statuses } | .container.name as $name | { spec: .container, status: (.statuses[] | select(.name == $name)) } | select(.status.started and .spec.name == $conName)'

        l_data_object_json=$(jq --arg podName "$1" --arg conName "$3" --arg objNS "$2" "$l_jq_query" "$6" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    else

        l_jq_query='{ containers: .spec.containers, statuses: .status.containerStatuses } | { container: .containers[], statuses: .statuses } | .container.name as $name | { spec: .container, status: (.statuses[] | select(.name == $name)) } | select(.status.started and .spec.name == $conName)'

        l_data_object_json=$(cat "$6" | jq --arg conName "$3" "$l_jq_query" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    fi

    if [ -z "$l_data_object_json" ] || [ "$l_data_object_json" = "null" ]; then
        printf "El contenedor no esta en ejucución o no existe.\n"
        return 2
    fi

    #Eliminar la data temporal
    if [ $l_mode_exit -eq 0 ] && [ ! -z "$5" ]; then
        rm -f $5
    fi


    #2. Ejecutar el comando
    printf '\n'
    _exec_cmd "$1" "$2" "$3" "$4" 0 0 1


}




#Parametros (argumentos y opciones):
#  1 > Recursos y el Objeto 'Resource/Objet' (pod, deployments, job, ...) que referencia un conjunto de los pods
#      donde obtendra los logs (La mayor parte de los log son de contenedores de los pod).
#  2 > Namespace (si se especifica se usa el por namespace actual).
#  3 > Contenedor (si no se especifica se obtendra el contenedor por defecto del pod).
#      Use '--all' si se usara todos los contenedores de los pod selecionados.
#  4 > Use el flag 0 si follow los logs, caso contrario no lo hace.
#  5 > Use el flag 0 para mostrar el timestamp.
#  6 > Filtra lo log mostrando los ultimos n lineas ('--tail=n').
#      Si es <=0, no se especifica y tratara de mostrar todos.
#  7 > Filtrar los ultimos logs desde tiempo: 5s, 2m, 3h, ...
_show_log() {

    #1. Calcular los argumentos del comando y mostrar el mensaje de bienvenida
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    #Objetos asociados a conjuntos de pods/contenedores
    printf 'Object    : "%b%s%b"\n' "$l_color_1" "$1" "$g_color_reset"
    local l_options="$1"

    #Namespace
    if [ ! -z "$2" ]; then
        printf 'Namespace : "%b%s%b"\n' "$l_color_2" "$2" "$g_color_reset"
        l_options="-n=${2} ${l_options}"
    fi

    #Contenedor
    if [ ! -z "$3" ]; then
        if [ "$3" = "--all" ]; then
            printf 'Container : "%b%s%b"\n' "$l_color_2" "All pod's containers" "$g_color_reset"
            l_options="--all-containers ${l_options}"
        else
            printf 'Container : "%b%s%b"\n' "$l_color_2" "$3" "$g_color_reset"
            l_options="-c=${3} ${l_options}"
        fi
    fi

    #Follow el log
    if [ $4 -eq 0 ]; then
        l_options="-f ${l_options}"
    fi

    #Mostrar el timestamp
    if [ $5 -eq 0 ]; then
        l_options="--timestamps ${l_options}"
    fi

    #Mostrar ultimas lineas de log
    if [ $6 -gt 0 ]; then
        l_options="--tail=$6 ${l_options}"
    fi

    #Mostrar ultimas lineas de log
    if [ ! -z "$7" ]; then
        l_options="--since=$7 ${l_options}"
    fi

    printf 'Commnad   : "%b%s logs %s%b"\n\n' "$l_color_2" "$g_kubectl_cmd" "${l_options}" "$g_color_reset"

    #2. Ejecutar el comando
    ${g_kubectl_cmd} logs ${l_options}

    return 0

}

#Parametros (argumentos y opciones) de entrada:
#  1 > xxx
#Variables globales de entrada:
#  '_g_data_object_json' > arreglo JSON con los contenedores ...
#Variables globales de salida:
#  '_g_container_name'   > Nombre del contenedor elegido
_choose_container_for_log() {

    #1. Obtener los nombres de los contenedores (manteniendo el orden del arreglo como estan declarados)
    local l_data
    local l_jq_query='[ .[].name ] | join("|")'

    l_data=$(echo "$_g_data_object_json" | jq -r "$l_jq_query")
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data de los nombres de los contenedores del pod.\n"
        return 3
    fi

    local IFS='|'
    local la_containers=($l_data)
    IFS=$' \t\n'
    local l_n=${#la_containers[@]}

    if [ $l_n -lt 1 ]; then
        printf "No existe contenedores con puertos TCP a exponer dentro del pod.\n"
        return 4
    fi

    #2 Capturar el nombre de contenedor ingresado por el usuario
    local l_in_opcion
    #local l_container

    printf 'Ingrese valores de los parametros requeridos para mostrar el log:\n\n'
    local l_i=-1

    if [ $l_n -gt 1 ]; then

        printf "> Choose the container %bthe following table%b:\n\n" "$g_color_gray1" "$g_color_reset"

        #Mostrando la tabla con los contenodores
        l_jq_query='[. | to_entries[] | { IDX: .key, NAME: .value.name, PORTS: (if .value.ports == null then "" else ([.value.ports[] | select(.protocol == "TCP") | .containerPort] | join(",")) end), IMAGE: .value.image }]'
        l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
        if [ $? -ne 0 ]; then
            printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
            return 5
        fi

        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
            return 6
        else
            echo "$l_data" | jtbl -n
            printf '\n'
        fi

        #Eligiendo la posicion correcta
        l_i=-1
        while [ $l_i -lt 0  ]; do

            #
            printf "  Choose %bContainer IDX%b (de 0 hasta %s asociado a un contenedor)%b or Enter %b'--all'%b (para seleccionar todos los contenedores)%b [ ]" \
                   "$g_color_cyan1" "$g_color_gray1" "$((l_n - 1))" "$g_color_reset" "$g_color_cyan1" "$g_color_gray1" "$g_color_reset"
            read -re -p ": " l_in_option

            if [[ "$l_in_option" =~ ^[0-9]+$ ]]; then
                l_i=$l_in_option

                if [ $l_i -ge $l_n  ] || [ $l_i -lt 0 ]; then
                    l_i=-1
                    printf "  %bEl entero debe ser 0 hasta %s inclusive%b\n" "$g_color_gray1" "$((l_n - 1))" "$g_color_reset"
                fi

            else

                l_i=-1
                if [ "$l_in_option" = "--all" ]; then
                    break
                else
                    printf "  %bIngrese un entero desde 0 hasta %s inclusive o ingrese '--all'%b\n" "$g_color_gray1" "$((l_n - 1))" "$g_color_reset"
                fi
            fi

        done

    else
        l_i=0
    fi

    #3. Contenedor elegido
    if [ $l_i -ge 0 ]; then
        #l_container=${la_containers[${l_i}]}
        _g_container_name=${la_containers[${l_i}]}
    else
        #l_container='--all'
        _g_container_name='--all'
    fi

    return 0

}


#Parametros (argumentos y opciones) de entrada:
#  1 > Recursos y el Objeto 'Resource/Objet' (pod, deployments, job, ...) que referencia un conjunto de los pods
#      donde obtendra los logs (La mayor parte de los log son de contenedores de los pod).
#  2 > Namespace (si se especifica se usa el por namespace actual).
#  3 > Nombre del contenedor
#  4 > Flag the 'follow el log' si es 0.
#  5 > Valor por defecto del filtro de logs las ultimas lineas. Ejemplo: 500
_choose_and_show_logs() {

    #1. Datos basicos
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    #2. Obtener datos ingresado por el usuario y requeridos para ejecutar la el comando

    #2.1. Obtener los nombres del contenedor si no se especifica
    local l_container
    if [ -z "$3" ]; then
        _choose_container_for_log
        l_container="$_g_container_name"
    else
        l_container="$3"
    fi

    #2.2. Leer el flag show timestamp
    local l_show_timestamp=0
    printf "> Show the timestamps %b('n' para desactivarlo. 's' u otro valor para activarlo)%b [s]" "$g_color_gray1" "$g_color_reset"
    read -rei 's' -p ": " l_in_option

    if [ "$l_in_option" = "n" ]; then
        l_show_timestamp=1
    fi

    #2.3. Leer el flag the following logs
    local l_follow_log=1
    if [ "$4" = "0" ]; then
        l_follow_log=0
    fi

    #2.4. Filtro de las ultimas lineas
    local l_filter_lines=-1
    if [[ "$5" =~ ^[1-9][0-9]+$ ]]; then
        l_filter_lines=$5
    fi

    printf "> Filter > Show last number lines %b(un entero positivo para activar el filtro, entero negativo para desabilitarlo, otro valor se considera '%s' lineas)%b [%s]" "$g_color_gray1" \
           "$l_filter_lines" "$g_color_reset" "$l_filter_lines"
    read -rei "$l_filter_lines" -p ": " l_in_option

    if [[ "$l_in_option" =~ ^-[1-9][0-9]+$ ]]; then
        l_filter_lines=-1
    elif [[ "$l_in_option" =~ ^[1-9][0-9]+$ ]]; then
        l_filter_lines=$l_in_option
    fi

    #2.5. Filtro de un rango de tiempo relativo
    local l_filter_time=""

    printf "> Filter > Show last log since %b(un entero positivo seguido de 's' para segundos, 'm' para minutos y 'h' para horas; caso contrario se desactiva el filtro)%b [ ]" "$g_color_gray1" "$g_color_reset"
    read -re -p ": " l_in_option

    if [[ "$l_in_option" =~ ^[1-9][0-9]+[smh]$ ]]; then
        l_filter_time="$l_in_option"
    fi

    #3. Ejecutar los comandos y mostrar el log deseado
    printf '\n'
    if [ $l_mode_exit_follow -eq 0 ]; then

        #Mostrar el log en la terminal
        _show_log "${1}" "$2" "$l_container" $l_follow_log $l_show_timestamp $l_filter_lines "$l_filter_time"

    else

        #Mostrar el log en bat siempre el pager (modo interactivo y capacidad de leer archivos grandes)
        bat --paging always --style plain  <(_show_log "${1}" "$2" "$l_container" $l_follow_log $l_show_timestamp $l_filter_lines "$l_filter_time")
    fi


}



#Parametros (argumentos y opciones) de entrada:
#  1 > Nombre del Deployment
#  2 > Namespace (si se especifica se usa el por namespace actual).
#  3 > Flag the 'follow el log' si es 0.
#  4 > Valor por defecto del filtro de logs las ultimas lineas. Ejemplo: 500
#  5 > Archivos de datos.
show_log_dply() {

    local l_mode_exit_follow=1
    if [ "$3" = "0" ]; then
        l_mode_exit_follow=0
    fi

    local -i p_use_one_object=1
    if [ "$6" = "0"  ]; then
        p_use_one_object=0
    fi

    # Obtener el arreglo de los contenedores habilitados
    local l_jq_query

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | .spec.template.spec.containers'
        _g_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$5" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del deployment.\n"
            return 1
        fi

    else
        l_jq_query='.spec.template.spec.containers'
        _g_data_object_json=$(cat "$5" | jq "$l_jq_query" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del deployment.\n"
            return 1
        fi
    fi


    if [ "$_g_data_object_json" = "[]" ]; then
        printf "No existe contenedores habilitados en el deployment.\n"
        return 2
    fi

    #Eliminar la data temporal
    if [ $l_mode_exit_follow -eq 0 ] && [ ! -z "$5" ]; then
        rm -f $5
    fi

    #2. Obtener el container escogido por el usuario y los demas parametros
    _choose_and_show_logs "deployment/${1}" "$2" "" $l_mode_exit_follow $4

}




#Parametros (argumentos y opciones) de entrada:
#  1 > Nombre del pod
#  2 > Namespace (si se especifica se usa el por namespace actual).
#  3 > Flag the 'follow el log' si es 0.
#  4 > Valor por defecto del filtro de logs las ultimas lineas. Ejemplo: 500
#  5 > Archivos de datos.
show_log_pod() {

    local l_mode_exit_follow=1
    if [ "$3" = "0" ]; then
        l_mode_exit_follow=0
    fi

    local -i p_use_one_object=1
    if [ "$6" = "0"  ]; then
        p_use_one_object=0
    fi

    # Obtener el arreglo de los contenedores habilitados
    local l_jq_query

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | .spec.containers'
        _g_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$5" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    else

        l_jq_query='.spec.containers'
        _g_data_object_json=$(cat "$5" | jq "$l_jq_query" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    fi

    if [ "$_g_data_object_json" = "[]" ]; then
        printf "No existe contenedores habilitados en el pod.\n"
        return 2
    fi

    #2. Eliminar la data temporal
    if [ $l_mode_exit_follow -eq 0 ] && [ ! -z "$5" ]; then
        rm -f $5
    fi


    #3. Obtener el container escogido por el usuario y los demas parametros
    _choose_and_show_logs "pod/${1}" "$2" "" $l_mode_exit_follow $4


}




#Parametros (argumentos y opciones) de entrada:
#  1 > Nombre del pod
#  2 > Namespace (si se especifica se usa el por namespace actual).
#  3 > Contenedor (si no se especifica se obtendra el contenedor por defecto del pod).
#      Use '--all' si se usara todos los contenedores de los pod selecionados.
#  4 > Modo 'exit & follow' si es 0.
#  5 > Valor por defecto del filtro de logs las ultimas lineas. Ejemplo: 500
#  6 > Archivos de datos.
show_log_container() {

    local l_mode_exit_follow=1
    if [ "$4" = "0" ]; then
        l_mode_exit_follow=0
    fi

    #1. Eiminar la data temporal
    if [ $l_mode_exit_follow -eq 0 ] && [ ! -z "$5" ]; then
        rm -f $5
    fi


    #2. Obtener el container escogido por el usuario y los demas parametros
    _choose_and_show_logs "pod/${1}" "$2" "$3" $l_mode_exit_follow $4


}




#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos
#  2 > El nombre objeto
#  4 > El nombre namespace (si el objeto esta vinculado a un namespace)
show_object_yaml() {

    local -i p_use_one_object=1
    if [ "$3" = "0"  ]; then
        p_use_one_object=0
    fi

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    local l_jq_query
    local l_data
    local -i l_status=0
    local l_data_yaml

    if [ $p_use_one_object -ne 0 ]; then

        if [ -z "$4" ]; then
            l_jq_query='.items[] | select (.metadata.name == $objName)'
            l_data_yaml=$(jq --arg objName "$2" "$l_jq_query" "$1" 2> /dev/null | yq -p json -o yaml 2> /dev/null)
            l_status=$?
        else
            l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
            l_data_yaml=$(jq --arg objName "$2" --arg objNS "$4" "$l_jq_query" "$1" 2> /dev/null | yq -p json -o yaml 2> /dev/null)
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            return 1
        fi

    else
        l_data_yaml=$(cat "$1" | yq -p json -o yaml 2> /dev/null)
    fi

    echo "$l_data_yaml"
}



#Muestra la informacion de un pod (requiere que '_g_data_object_json' tenga el valor json del pod)
#Parametros:
#  1 > Si es pod's template usar '0', en caso que ser un pod usar un valor diferente ('1')
#
_show_pod_info() {

    #1. Parametros
    local p_is_template=1
    if [ "$1" = "0" ]; then
        p_is_template=0
    fi

    #2. Información del Pod
    local l_data=""
    local l_jq_query=""
    local l_root="."
    if [ $p_is_template -eq 0 ]; then
        l_root=".spec.template."
    fi

    printf '\n%bInformacion general de Pod:%b\n' "$g_color_cyan1" "$g_color_reset"
    if [ $p_is_template -ne 0 ]; then
        l_jq_query='{ UID: .metadata.uid, Phase: .status.phase, PodIP: .status.podIP, Owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), StartTime: .status.startTime, NodeName: .spec.nodeName, DnsPolicy: .spec.dnsPolicy, RestartPolicy: .spec.restartPolicy, SchedulerName: .spec.schedulerName, Priority: .spec.priority, ServiceAccount: .spec.serviceAccount, ServiceAccountName: .spec.serviceAccountName, ImagePullSecrets: ([.spec.imagePullSecrets[]?.name] | join(", ")), ActiveDeadlineSeconds: .spec.activeDeadlineSeconds, TerminationGracePeriodSeconds:  .spec.terminationGracePeriodSeconds } | to_entries[] | "\t\(.key)\t: \(.value)"'
    else
        l_jq_query='{ NodeName: .spec.template.spec.nodeName, DnsPolicy: .spec.template.spec.dnsPolicy, RestartPolicy: .spec.template.spec.restartPolicy, SchedulerName: .spec.template.spec.schedulerName, Priority: .spec.template.spec.priority, ServiceAccount: .spec.template.spec.serviceAccount, ServiceAccountName: .spec.template.spec.serviceAccountName, ImagePullSecrets: ([.spec.template.spec.imagePullSecrets[]?.name] | join(", ")), ActiveDeadlineSeconds: .spec.template.spec.activeDeadlineSeconds, TerminationGracePeriodSeconds:  .spec.template.spec.terminationGracePeriodSeconds } | to_entries[] | "\t\(.key)\t: \(.value)"'
    fi
    echo "$_g_data_object_json" | jq -r "$l_jq_query"

    if [ $p_is_template -ne 0 ]; then

        printf "\n%bPod's Contitions:%b\n" "$g_color_cyan1" "$g_color_reset"
        l_jq_query='[.status.conditions[]? | { TYPE: .type, STATUS: .status, TIME: .lastTransitionTime, REASON: .reason, MESSAGGE: .message }]'

        l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
        if [ $? -eq 0 ]; then
            if [ "$l_data" = "[]" ]; then
                printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
            else
                echo "$l_data" | jtbl -n
            fi
        else
            printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
        fi



        printf '\n%bStatus de los contenedores del pod:%b\n' "$g_color_cyan1" "$g_color_reset"
        l_jq_query='[.status.containerStatuses[]? | . as $item | (.imageID/"/") as $imgIdParts | (.image/"/") as $imgParts | (((.state? | to_entries[]) + {type: "Current"}), ((.lastState? | to_entries[]) + { type: "Previous"})) | { CONTAINER: $item.name, POSITION: .type, TYPE: .key, "STARTED-AT": .value?.startedAt, "FINISHED-AT": .value?.finishedAt, "CONTAINER-ID": (if .type == "Current" then $item.containerID else .value?.containerID end), "REASON": .value?.reason, "EXITCODE": .value?.exitCode, "MESSAGE": .value?.message, "IMAGE-HASH": (if .type == "Current" then $imgIdParts[2] else "" end), "IMAGE-TAG": (if .type == "Current" and $imgParts[2] != $imgIdParts[2] then $imgParts[2] else "" end) }]'

        l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
        if [ $? -eq 0 ]; then
            if [ "$l_data" = "[]" ]; then
                printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
            else
                echo "$l_data" | jtbl -n
            fi
        else
            printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
        fi

    fi


    printf '\n%bContenedores principales:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.containers[] | { NAME: .name, PORTS: ( [ (.ports[]? | "\(.containerPort)/\(.protocol)") ] | join(", ")), IMAGE: .image } ]'
    echo "$_g_data_object_json" | jq "$l_jq_query" | jtbl -n



    printf '\n%bContenedores de inicialización:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.initContainers[]? | { NAME: .name, PORTS: ( [ .ports[]?.containerPort ] | join(", ")), IMAGE: .image } ]'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi



    printf '\n%bVariables de contenedores principales:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.containers[] | { name: .name, env: .env[]? } | { CONTAINER: .name, VARIABLE: .env.name, TYPE: (if .env.value? != null then "VALUE" elif .env.valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .env.valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" elif .env.valueFrom?.configMapKeyRef != null then "FROM-CFGMAP-REF" else "UNKNOWN" end), VALUE: (if .env.value? != null then .env.value? elif .env.valueFrom?.fieldRef != null then .env.valueFrom?.fieldRef.fieldPath elif .env.valueFrom?.secretKeyRef != null then "[SecretName: \(.env.valueFrom?.secretKeyRef.name)] \(.env.valueFrom?.secretKeyRef.key)" elif .env.valueFrom?.configMapKeyRef != null then "[ConfigMap: \(.env.valueFrom?.configMapKeyRef.name)] \(.env.valueFrom?.configMapKeyRef.key)" else "..." end) }]'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi


    printf '\n%bVolumenes montados por los contenedores:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.volumes as $vols | '"${l_root}"'spec.containers[] | {name: .name, volumeMount: .volumeMounts[]? } | .volumeMount.name as $volName | { name: .name, volumeMount: .volumeMount, volume: ($vols[]? | select(.name == $volName))} | { CONTAINER: .name, "VOL-NAME": .volumeMount.name, "VOL-TYPE": (if .volume.persistentVolumeClaim?.claimName != null then "PVC" elif .volume.configMap?.name then "CONFIG-MAP" elif .volume.secret?.secretName then "SECRET" elif .volume.hostPath?.path != null then "HOST-PATH" elif .volume.emptyDir? != null then "EMPTY-DIR" elif .volume.downwardAPI?.items != null then "DONWWARD-API" elif .volume.projected?.sources != null then "PROJECTED" else "UNKNOWN" end), "MOUNT-PATH": .volumeMount.mountPath, READONLY: .volumeMount.readOnly?, "VOL-VALUE": (if .volume.persistentVolumeClaim?.claimName != null then .volume.persistentVolumeClaim?.claimName elif .volume.configMap?.name then .volume.configMap?.name elif .volume.secret?.secretName then .volume.secret?.secretName elif .volume.hostPath?.path != null then .volume.hostPath?.path elif .volume.emptyDir? != null then "..." elif .volume.downwardAPI?.items != null then "..." elif .volume.projected?.sources != null then "..." else "???" end) }]'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi



    printf '\n%bEtiquetas del pod:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'metadata.labels | to_entries[] | { KEY: .key, VALUE: .value }]'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi

    printf '\n%bTolerancias del pod:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.tolerations[]? | {KEY: .key, OPERATOR: .operator, VALUE: .value, EFFECT: .effect, SECONDS: .tolerationSeconds }]'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi



    printf '\n%bNode Selector usados por el pods:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='if '"${l_root}"'spec.nodeSelector == null then null else ('"${l_root}"'spec.nodeSelector | to_entries[] | "\t\(.key)\t: \(.value)") end'
    l_data=$(echo "$_g_data_object_json" | jq -r "$l_jq_query")
    if [ -z "$l_data" ] || [ "$l_data" == "null" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
    else
        echo "$l_data"
    fi


    printf '\n%bPod Affinity:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query="${l_root}"'spec.affinity?.podAffinity'
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$l_data" == "null" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
    else
        echo "$l_data" | yq -p json -o yaml
    fi

    printf '\n%bPod Anti-Affinity:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query="${l_root}"'spec.affinity?.podAntiAffinity'
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$l_data" == "null" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
    else
        echo "$l_data" | yq -p json -o yaml
    fi

}


#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos
#  2 > El nombre deployment
#  3 > El nombre namespace
#  4 > Las etiquetas para busqueda de pods
show_deployment_info() {

    local -i p_use_one_object=1
    if [ "$5" = "0"  ]; then
        p_use_one_object=0
    fi

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    local l_jq_query
    local l_data

    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'

        _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
        if [ $? -ne 0 ]; then
            return 1
        fi

    else
        _g_data_object_json=$(cat "$1")
    fi


    #1. Información especifica del deployment
    printf '%bDeployment :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"
    printf '%bNamespace  :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$3"
    printf '%bList pods  :%b oc get pod -n %s -l %s\n' "$g_color_cyan1" "$g_color_reset" "$3" "$4"


    printf '%bInformación adicional:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='{ UID: .metadata.uid, Owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), Revision: .metadata.annotations."deployment.kubernetes.io/revision", Generation: .metadata.generation, DesiredReplicas: .spec.replicas, ReadyReplicas: .status.readyReplicas, CurrentReplicas: .status.replicas, UpdatedReplicas: .status.updatedReplicas, AvailableReplicas: .status.availableReplicas, ObservedGeneration: .status.observedGeneration, RevisionHistoryLimit: .spec.revisionHistoryLimit, ProgressDeadlineSeconds: .spec.progressDeadlineSeconds } | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$_g_data_object_json" | jq -r "$l_jq_query"


    printf '\n%bEstrategias del Deployment:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='.spec.strategy?'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$l_data" == "null" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
    else
        echo "$l_data" | yq -p json -o yaml
    fi


    printf '\n%bSelector de pods usados:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='.spec.selector.matchLabels | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$_g_data_object_json" | jq -r "$l_jq_query"



    printf '\n%bStatus del Deployment (Contitions):%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[.status.conditions[]? | { TYPE: .type, STATUS: .status, "TRANSITION-TIME": .lastTransitionTime, "UPDATE-TIME": .lastUpdateTime , REASON: .reason, MESSAGGE: .message }]'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi



    #2. Informacion general del Pod
    printf '\n\n%b########################################################################################\n' "$g_color_gray1"
    printf '%bPOD TEMPLATE INFO%b\n' "$g_color_green1" "$g_color_gray1"
    printf '########################################################################################%b\n' "$g_color_reset"

    _show_pod_info 0


}

#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos
#  2 > El nombre deployment
#  3 > El nombre namespace
#  4 > Las etiquetas para busqueda de pods
show_replicaset_info() {

    local -i p_use_one_object=1
    if [ "$5" = "0"  ]; then
        p_use_one_object=0
    fi

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    local l_jq_query
    local l_data

    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'

        _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
        if [ $? -ne 0 ]; then
            return 1
        fi

    else
        _g_data_object_json=$(cat "$1")
    fi


    #1. Información especifica del contenedor
    printf '%bReplicaSet :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"
    printf '%bNamespace  :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$3"
    printf '%bList pods  :%b oc get pod -n %s -l %s\n' "$g_color_cyan1" "$g_color_reset" "$3" "$4"


    printf '%bInformación adicional:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='{ UID: .metadata.uid, Owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), DesiredReplicas: .spec.replicas, ReadyReplicas: .status.readyReplicas, CurrentReplicas: .status.replicas, AvailableReplicas: .status.availableReplicas, FullyLabeledReplicas: .status.fullyLabeledReplicas, DeploymentRevision: .metadata.annotations."deployment.kubernetes.io/revision", DeploymentMaxReplicas: .metadata.annotations."deployment.kubernetes.io/max-replicas", DeploymentDesiredReplicas: .metadata.annotations."deployment.kubernetes.io/desired-replicas" } | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$_g_data_object_json" | jq -r "$l_jq_query"



    printf '\n%bSelector de pods usados:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='.spec.selector.matchLabels | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$_g_data_object_json" | jq -r "$l_jq_query"



    printf '\n%bStatus del Deployment (Contitions):%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[.status.conditions[]? | { TYPE: .type, STATUS: .status, "TRANSITION-TIME": .lastTransitionTime, "UPDATE-TIME": .lastUpdateTime , REASON: .reason, MESSAGGE: .message }]'

    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi



    #2. Informacion general del Pod
    printf '\n\n%b########################################################################################\n' "$g_color_gray1"
    printf '%bPOD TEMPLATE INFO%b\n' "$g_color_green1" "$g_color_gray1"
    printf '########################################################################################%b\n' "$g_color_reset"

    _show_pod_info 0


}


#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos
#  2 > El nombre del pod
#  3 > El nombre namespace
show_pod_info() {

    local -i p_use_one_object=1
    if [ "$4" = "0"  ]; then
        p_use_one_object=0
    fi

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    local l_jq_query
    local l_data

    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'

        _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
        if [ $? -ne 0 ]; then
            return 1
        fi

    else
        _g_data_object_json=$(cat "$1")
    fi


    #1. Información especifica del Pod
    printf '%bPod        :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"
    printf '%bNamespace  :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$3"


    #2. Informacion general del Pod
    _show_pod_info 1


}



#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos
#  2 > El nombre del pod
#  3 > El nombre namespace
#  4 > El nonbre del contenedor
show_container_info() {

    local -i p_use_one_object=1
    if [ "$5" = "0"  ]; then
        p_use_one_object=0
    fi

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    local l_jq_query

    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'

        _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
        if [ $? -ne 0 ]; then
            return 1
        fi

    else
        _g_data_object_json=$(cat "$1")
    fi


    #1. Información especifica del contenedor
    printf '%bContainer  :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$4"
    printf '%bPod        :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"
    printf '%bNamespace  :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$3"
    #printf '%bContainers Log    :%b oc logs pod/%s -n %s -c %s --tail=500 -f\n' "$g_color_cyan1" "$g_color_reset" "$2" "$3" "$4"

    local l_data_subobject_json=""
    l_jq_query='{ spec: ( .spec.containers[] | select(.name == $objName)), status: (.status.containerStatuses[]? | select(.name == $objName)), volumes: .spec.volumes }'

    l_data_subobject_json=$(echo "$_g_data_object_json" | jq --arg objName "$4" "$l_jq_query" 2> /dev/null)
    #echo "$l_data_subobject_json"
    if [ $? -ne 0 ]; then
        return 2
    fi

    printf '%bInformación adicional:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='{ Image: .spec.image, ImageID: .status.imageID, ContainerID: .status.containerID, Ready: .status.ready, Started: .status.started, RestartCount: .status.restartCount, Command: ((.spec.command//[]) | join(" ")), Arguments: ((.spec.args//[]) | join(" ")), ImagePullPolicy: .spec.imagePullPolicy } | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$l_data_subobject_json" | jq -r "$l_jq_query"


    printf '\n%bVariables:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[.spec.env[]? | { VARIABLE: .name, TYPE: (if .value? != null then "VALUE" elif .valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" else "UNKNOWN" end), VALUE: (if .value? != null then .value? elif .valueFrom?.fieldRef != null then .valueFrom?.fieldRef.fieldPath elif .valueFrom?.secretKeyRef != null then "\(.valueFrom?.secretKeyRef.key) [SecretName: \(.valueFrom?.secretKeyRef.name)]" else "..." end) }]'

    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi


    printf '\n%bPuertos:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[.spec.ports[]? | { NAME: .name, "PORT-HOST": .hostPort, "PORT-CONTAINER": .containerPort, "PROTOCOL": .protocol }]'

    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi


    printf '\n%bVolumenes montados:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ .volumes as $vols | .spec.volumeMounts[]? | .name as $volName | {name: .name, mountPath: .mountPath, readOnly: .readOnly, volume: ($vols[]? | select(.name == $volName))} | { "VOL-NAME": .name, "VOL-TYPE": (if .volume.persistentVolumeClaim?.claimName != null then "PVC" elif .volume.configMap?.name then "CONFIG-MAP" elif .volume.secret?.secretName then "SECRET" elif .volume.hostPath?.path != null then "HOST-PATH" elif .volume.emptyDir? != null then "EMPTY-DIR" elif .volume.downwardAPI?.items != null then "DONWWARD-API" elif .volume.projected?.sources != null then "PROJECTED" else "UNKNOWN" end), "MOUNT-PATH": .mountPath, READONLY: .readOnly?, "VOL-VALUE": (if .volume.persistentVolumeClaim?.claimName != null then .volume.persistentVolumeClaim?.claimName elif .volume.configMap?.name then .volume.configMap?.name elif .volume.secret?.secretName then .volume.secret?.secretName elif .volume.hostPath?.path != null then .volume.hostPath?.path elif .volume.emptyDir? != null then "..." elif .volume.downwardAPI?.items != null then "..." elif .volume.projected?.sources != null then "..." else "???" end) }]'

    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi



    printf '\n%bResources:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[.spec.resources? | ({ TYPE: "Requests", CPU: .requests?.cpu, MEMORY: .requests?.memory }, { TYPE: "Limits", CPU: .limits?.cpu, MEMORY: .limits?.memory })]'

    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi


    printf '\n%bStatus:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[.status | .containerID as $id | (((.state? | to_entries[]) + {type: "Current"}), ((.lastState? | to_entries[]) + { type: "Previous"})) | { POSITION: .type, TYPE: .key, "STARTED-AT": .value?.startedAt, "FINISHED-AT": .value?.finishedAt, "CONTAINER-ID": (if .type == "Current" then $id else .value?.containerID end), "REASON": .value?.reason, "EXITCODE": .value?.exitCode, "MESSAGE": .value?.message }]'

    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi



    #2. Informacion general del Pod
    printf '\n\n%b########################################################################################\n' "$g_color_gray1"
    printf '%bADDITIONAL INFO ABOUT POD%b\n' "$g_color_green1" "$g_color_gray1"
    printf '########################################################################################%b\n' "$g_color_reset"

    _show_pod_info 1


}

#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos
#  2 > El nombre del namespace
#  3 > Flag '0' si es project (caso contrarios es namespace)
show_namespace_info() {

    local l_is_project=1
    if [ "$3" = "0" ]; then
        l_is_project=0
    fi

    local l_jq_query='.items[] | select (.metadata.name == $objName)'
    local l_data_object_json
    local l_data=""

    l_data_object_json=$(jq --arg objName "$2" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi


    #1. Información especifica del Pod
    printf '%bNamespace    :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"

    l_jq_query='"\(.metadata.uid)|\(.metadata.creationTimestamp)|\(.status.phase)"'

    l_data=$(echo "$l_data_object_json" | jq -r "$l_jq_query")
    local IFS='|'
    local la_info=(${l_data})
    IFS=$' \t\n'
    #local l_n=${#la_info[@]}

    printf '%bUID          :%b %s\n' "$g_color_cyan1" "$g_color_reset" "${la_info[0]}"
    printf '%bCreation Time:%b %s\n' "$g_color_cyan1" "$g_color_reset" "${la_info[1]}"
    printf '%bSatus        :%b %s\n' "$g_color_cyan1" "$g_color_reset" "${la_info[2]}"

    #2. Informacion general del Pod
    if [ $l_is_project -eq 0 ]; then
        printf '%bInformación adicional:%b\n' "$g_color_cyan1" "$g_color_reset"
        l_jq_query=' { Description: (.metadata.annotations."openshift.io/description"//""), DisplayName: (.metadata.annotations."openshift.io/display-name"//"") } | to_entries[] | "\t\(.key)\t: \(.value)"'
        echo "$l_data_object_json" | jq -r "$l_jq_query"
    fi

    #3. Obtener las etiquetas de la metadata
    printf '\n%bEtiquetas:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='[ .metadata.labels | to_entries[] | { KEY: .key, VALUE: .value }]'

    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
    fi

    #4. Obtener las anotaciones de la metadata
    printf '\n%bAnotaciones:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='.metadata.annotations'
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$l_data" == "null" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
    else
        echo "$l_data" | yq -p json -o yaml
    fi

    #5. Mostrar otros detalles de las especificaciones:
    #resource quota.
    #LimitRange resource.
    printf '\n%bSpecifications:%b\n' "$g_color_cyan1" "$g_color_reset"
    l_jq_query='.spec'
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$l_data" == "null" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
    else
        echo "$l_data" | yq -p json -o yaml
    fi


}



#Parametros (argumentos y opciones) de entrada:
#  1 > Recursos y Objetos 'Resource/Objet' (pod, deployments, job, ...) que referencia un conjunto de los pods
#  2 > Namespace (si se especifica se usa el por namespace actual).
#  3 > Lista de adrress locales que expondra el puerto local (por defecto es 'localhost')
#  4 > Lista de puertos locales y puertos del contenedor: local-port1:port1 local-port2:port2 ...
_port_forward() {

    #1. Calcular los argumentos del comando y mostrar el mensaje de bienvenida
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    #Objetos asociados a conjuntos de pods/contenedores
    printf 'Object    : "%b%s%b"\n' "$l_color_1" "$1" "$g_color_reset"
    local l_options="$1"

    #Namespace
    if [ ! -z "$2" ]; then
        printf 'Namespace : "%b%s%b"\n' "$l_color_2" "$2" "$g_color_reset"
        l_options="-n=${2} ${l_options}"
    fi

    #Lista de adrress locales que expondra el puerto local (por defecto es 'localhost')
    if [ ! -z "$3" ]; then
        l_options="--address=${3} ${l_options}"
    fi

    #Lista de puertos locales y puertos del contenedor: local-port1:port1 local-port2:port2 ...
    if [ ! -z "$4" ]; then
        l_options="${l_options} ${4}"
    fi


    printf 'Command   : "%b%s port-forward %s%b"\n\n' "$l_color_2" "$g_kubectl_cmd" "$l_options" "$g_color_reset"

    #2. Ejecutar el comando
    ${g_kubectl_cmd} port-forward ${l_options}
    return 0


}


#Parametros (argumentos y opciones) de entrada:
#  1 > El nombre del pod
#  2 > El nombre namespace
#  3 > La ruta del archivo de datos
port_forward_pod() {

    local -i p_use_one_object=1
    if [ "$4" = "0"  ]; then
        p_use_one_object=0
    fi

    # Obtener el arreglo de los contenedores habilitados
    local l_jq_query
    local l_data_object_json

    # Si la data tiene un conjunto de items, obtener solo uno de ellos
    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='[.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | .spec.containers[] | select((.ports//[]) | any(.protocol == "TCP" and .containerPort > 0))]'

        l_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$3" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    else

        l_jq_query='[ .spec.containers[] | select((.ports//[]) | any(.protocol == "TCP" and .containerPort > 0))]'

        l_data_object_json=$(cat "$3" | jq "$l_jq_query" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf "Error al obtener la data de los contenedores del pod.\n"
            return 1
        fi

    fi

    if [ "$l_data_object_json" = "[]" ]; then
        printf "No existe puertos TCP expuestos por los contenedores del pod.\n"
        return 2
    fi

    #Eliminar la data temporal
    if [ ! -z "$3" ]; then
        rm -f $3
    fi

    #2. Obtener datos ingresado por el usuario y requeridos para ejecutar la el comando
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    #2.1 Obtener los nombres de los contenedores (mantieniendo el oden del arreglo como estan declarados)
    local l_data
    l_jq_query='[ .[].name ] | join("|")'

    l_data=$(echo "$l_data_object_json" | jq -r "$l_jq_query")
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data los nombres de los contenedores del pod.\n"
        return 3
    fi

    local IFS='|'
    local la_container_names=($l_data)
    local l_n=${#la_container_names[@]}

    if [ $l_n -lt 1 ]; then
        printf "No existe contenedores con puertos TCP a exponer dentro del pod.\n"
        return 4
    fi

    #2.2 Obtener los puertos por cada contenedor
    l_jq_query='[.[] | { name: .name, ports: ([.ports[] | select(.protocol == "TCP") | .containerPort] | join(",")) } | .ports] | join("|")'

    l_data=$(echo "$l_data_object_json" | jq -r "$l_jq_query")
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data de puertos TCP de los contenedores del pod.\n"
        return 5
    fi

    la_container_ports=($l_data)
    l_n=${#la_container_ports[@]}

    if [ $l_n -lt 1 ]; then
        printf "No existe contenedores con puertos TCP a exponer dentro del pod.\n"
        return 6
    fi

    #2.3 Mostrando la tabla con los contenedores y puertos disponibles:
    l_jq_query='[. | to_entries[] | { ID: .key, NAME: .value.name, PORTS: (if .value.ports == null then "" else ([.value.ports[] | select(.protocol == "TCP") | .containerPort] | join(",")) end), IMAGE: .value.image }]'
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -ne 0 ]; then
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
        return 7
    fi

    if [ "$l_data" = "[]" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        return 8
    fi

    printf "Los contenedores que exponen puertos TCP en el pod '%s' son:\n\n" "$1"
    echo "$l_data" | jtbl -n

    #2.2 El usuario debera ingresar el datos del port local
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"
    local l_i=0
    local l_j=0
    local l_in_opcion
    local l_container
    local l_m=0
    local la_ports
    local l_port
    local l_cmd_options
    local l_availables_ports=0

    printf '\nIngrese valores de los parametros requeridos para realizar el port-forward:\n\n'
    printf "> Local's ports %bthat is linking to a container's port%b:\n" "$g_color_gray1" "$g_color_reset"
    printf '  %bEl puerto a ingresar debe ser un entero positivo, caso contrario se omitirá en el port-forwarding.%b\n\n' "$g_color_gray1" "$g_color_reset"

    for ((l_i=0; l_i < ${l_n}; l_i++)); do

        #Contenedor actual
        l_container=${la_container_names[${l_i}]}

        #Obteniendo los puertos del contenedor actual
        IFS=','
        la_ports=(${la_container_ports[${l_i}]})
        l_m=${#la_ports[@]}

        #¿Se debe analizar el puertos de este contenedor?
        if [ $l_n -gt 1 ] && [ $l_m -gt 1 ]; then
            IFS=$' \t\n'
            printf "\t> %bInclude%b ports of '%b%s%b' container %b('n' si no se incluye. Si desea inclurlos use 's' o cualquier otro valor)%b [s]" "$l_color_2" "$g_color_reset" "$l_color_1" \
                   "$l_container" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
            read -rei "s" -p ": " l_in_opcion

            if [ "$l_in_opcion" = "n" ]; then
                continue
            fi
        fi

        #Por cada contenedor solicitar el puerto local de sus puertos TCP
        for ((l_j=0; l_j < ${l_m}; l_j++)); do

            #Puerto actual
            l_port=${la_ports[${l_j}]}

            #Obteniendo el puerto local
            IFS=$' \t\n'
            printf "\t> Local's port of %b%s%b's port %b%s%b %b(ingrese un puerto disponible de su computador)%b [ ]" "$l_color_2" "$l_container" "$g_color_reset" "$l_color_1" "$l_port" \
                   "$g_color_reset" "$g_color_gray1" "$g_color_reset"
            read -rei "$l_port" -p ": " l_in_opcion

            if [[ "$l_in_opcion" =~ ^[1-9][0-9]+$ ]]; then
                ((l_availables_ports++))
                if [ -z "$l_cmd_options" ]; then
                    l_cmd_options="${l_in_opcion}:${l_port}"
                else
                    l_cmd_options="${l_cmd_options} ${l_in_opcion}:${l_port}"
                fi
            fi

        done

    done


    IFS=$' \t\n'
    if [ $l_availables_ports -le 0 ]; then
        printf 'No se ha especificado los puertos locales a vincularse.\n'
        return 2
    fi

    printf '\n'

    #3. Ejecutar el comando
    _port_forward "pod/${1}" "$2" "" "$l_cmd_options"

    return 0


}


#Parametros (argumentos y opciones) de entrada:
#  1 > El nombre del pod
#  2 > El nombre namespace
#  3 > El nombre del contenedor
#  4 > Puertos TCP del contenedor
#  5 > La ruta del archivo de datos
port_forward_container() {

    #1. Limpiar la data temporal
    if [ ! -z "$5" ]; then
        rm -f $5
    fi

    #2. Valores iniciales
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    if [ -z "$4" ] || [ "$4" == "-" ]; then
        printf "No existe puertos TCP expuestos por el contenedor '%s'.\n" "$3"
        return 1
    fi

    local IFS=','
    local la_container_ports=($4)

    #3. Obtener datos ingresado por el usuario y requeridos para ejecutar la el comando
    IFS=$' \t\n'
    local l_port
    local l_i=0
    local l_availables_ports=0
    local l_input
    local l_option_ports=""
    #local la_local_ports=()


    printf 'Ingrese valores de los parametros requeridos para realizar el port-forward:\n\n'

    printf "> Local's Ports %bthat is linking a Container's Port%b:\n" "$g_color_gray1" "$g_color_reset"
    printf '  %bEl puerto a ingresar debe ser un entero positivo, caso contrario se omitirá en el port-forwarding.%b\n\n' "$g_color_gray1" "$g_color_reset"

    for ((l_i=0; l_i < ${#la_container_ports[@]}; l_i++)); do

        printf "\t> Local's port of %b%s%b's port %b%s%b %b(ingrese un puerto disponible de su computador)%b [ ]" "$l_color_2" "$3" "$g_color_reset" "$l_color_1" "${la_container_ports[$l_i]}" \
               "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        read -rei "${la_container_ports[$l_i]}" -p ": " l_input

        if [[ "$l_input" =~ ^[1-9][0-9]+$ ]]; then
            ((l_availables_ports++))
            if [ -z "$l_option_ports" ]; then
                l_option_ports="${l_input}:${la_container_ports[$l_i]}"
            else
                l_option_ports="${l_option_ports} ${l_input}:${la_container_ports[$l_i]}"
            fi
            #la_local_ports[$l_i]=$l_input
        #else
            #la_local_ports[$l_i]=0
        fi
    done

    if [ $l_availables_ports -le 0 ]; then
        printf 'No se ha especificado los puertos locales a vincularse.\n'
        return 2
    fi

    printf '\n'

    #5. Ejecutar el comando
    _port_forward "pod/${1}" "$2" "" "$l_option_ports"

    return 0

}


#Parametros (argumentos y opciones) de entrada:
#  1 > Nombre del replicaset actual
#Variables globales de entrada:
#  '_g_data_object_json' >  Es un arreglo ordenado de replicaset ordenados vincualados al deployment y
#                           ordenado por fecha creación descente (vital para la compración)
_show_compare_revision() {

    if [ ! -z "$1" ]; then
        printf '%b(*)                :%b Indicador de la revisión actual (ReplicaSet "%s")\n' "$g_color_cyan1" "$g_color_reset" "$1"
    fi

    #1. Mostrar las revisiones encontradas
    printf '\n%bRevisiones         :%b\n' "$g_color_cyan1" "$g_color_reset"
    local l_data
    local l_status

    if [ -z "$1" ]; then
        l_jq_query='[.[] | { REPLICASET: .metadata.name, REVISION: .metadata.annotations."deployment.kubernetes.io/revision", CREATION_TIME: .metadata.creationTimestamp, DESIRED: .spec.replicas, CURRENT: .status.replicas, READY: (.status.readyReplicas//0), GENERATION: .metadata.generation, POD_HASH: .metadata.labels."pod-template-hash" }]'

        l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
        l_status=$?
    else
        l_jq_query='[.[] | { REPLICASET: (.metadata.name + (if .metadata.name == $objName then "(*)" else "" end)), REVISION: .metadata.annotations."deployment.kubernetes.io/revision", CREATION_TIME: .metadata.creationTimestamp, DESIRED: .spec.replicas, CURRENT: .status.replicas, READY: (.status.readyReplicas//0), GENERATION: .metadata.generation, POD_HASH: .metadata.labels."pod-template-hash" }]'

        l_data=$(echo "$_g_data_object_json" | jq --arg objName "$1" "$l_jq_query")
        l_status=$?
    fi

    if [ $l_status -ne 0 ]; then
        printf '%bError in getting data%b\n' "$g_color_gray1" "$g_color_reset"
        return 1
    fi

    if [ "$l_data" = "[]" ]; then
        printf '%bNo data found%b\n' "$g_color_gray1" "$g_color_reset"
        return 2
    fi

    echo "$l_data" | jtbl -n

    #2. Obtener data basica de las revisiones
    #   La fecha usan ISO 8601 usando UTC: 'yyyy-MM-ddThh:mm:ssZ' o  'yyyy-MM-ddThh:mm:ss.fffZ'
    l_jq_query='.[] | "\(.metadata.name)\t\(.metadata.annotations."deployment.kubernetes.io/revision")\t\(.metadata.creationTimestamp)"'
    local l_rev_name
    local l_rev_nbr
    local l_rev_date
    local la_rev_names=()
    local la_rev_nbrs=()
    local la_rev_dates=()
    local l_n=0

    while read -r l_rev_name l_rev_nbr l_rev_date; do
        la_rev_nbrs[${l_n}]=$l_rev_nbr
        la_rev_names[${l_n}]=$l_rev_name
        la_rev_dates[${l_n}]=$(date -d "$l_rev_date" '+%Y-%m-%d %H:%M:%S')
        ((l_n++))
    done < <(echo "$_g_data_object_json" | jq -r "$l_jq_query")

    #echo "${la_rev_nbrs[@]}"
    #echo "${la_rev_names[@]}"
    #echo "${la_rev_dates[@]}"

    if [ $l_n -le 0 ]; then
        printf '%bError in getting revisions names%b\n' "$g_color_gray1" "$g_color_reset"
        return 3
    fi

    #3. Mostar información de la revision ultima/actual
    local i

    #Buscar el indice de la revision actual
    local l_idx_revision=-1
    for ((i=0; i< $((l_n -1)); i++)); do

        l_name="${la_rev_names[$i]}"
        if [ ! -z "$1" ] && [ $l_idx_revision -lt 0 ] && [ "$1" = "$l_name"  ]; then
            l_idx_revision=$i
            break
        fi

    done

    #Mostrar el ultimo y el actual
    local l_revision_flag
    local l_name
    local l_date
    if [ $l_idx_revision -eq 0 ]; then

        l_date="${la_rev_dates[$l_idx_revision]}"
        l_name="${la_rev_names[$l_idx_revision]}"
        l_revision_flag='(*)'
        printf '\n%bUltima revisión%s :%b %s %b(ReplicaSet "%s" creado el "%s")%b\n' "$g_color_cyan1" "${l_revision_flag}" \
               "$g_color_reset" "${la_rev_nbrs[$l_idx_revision]}" "$g_color_gray1" "$l_name" "$l_date" "$g_color_reset"

    elif [ $l_idx_revision -gt 0 ]; then

        l_date="${la_rev_dates[$l_idx_revision]}"
        l_name="${la_rev_names[$l_idx_revision]}"
        l_revision_flag='(*)'
        printf '\n%bActual revisión%s :%b %s %b(ReplicaSet "%s" creado el "%s")%b\n' "$g_color_cyan1" "${l_revision_flag}" \
               "$g_color_reset" "${la_rev_nbrs[$l_idx_revision]}" "$g_color_gray1" "$l_name" "$l_date" "$g_color_reset"

        l_date="${la_rev_dates[0]}"
        l_name="${la_rev_names[0]}"
        l_revision_flag='   '
        printf '%bUltima revisión%s :%b %s %b(ReplicaSet "%s" creado el "%s")%b\n' "$g_color_cyan1" "${l_revision_flag}" \
               "$g_color_reset" "${la_rev_nbrs[0]}" "$g_color_gray1" "$l_name" "$l_date" "$g_color_reset"

    else

        l_date="${la_rev_dates[0]}"
        l_name="${la_rev_names[0]}"
        l_revision_flag='   '
        printf '\n%bUltima revisión%s :%b %s %b(ReplicaSet "%s" creado el "%s")%b\n' "$g_color_cyan1" "${l_revision_flag}" \
               "$g_color_reset" "${la_rev_nbrs[0]}" "$g_color_gray1" "$l_name" "$l_date" "$g_color_reset"

    fi

    #4. Mostrar las diferentes entre las revisiones:
    local l_color_old="\x1b[31m"
    local l_color_new="\x1b[32m"
    local l_name_next
    local l_revision_flag_next

    l_jq_query='.[$index] | { metadata: .metadata, spec: .spec } | del(.metadata.ownerReferences[].uid) | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.metadata.name) | del(.metadata.annotations."deployment.kubernetes.io/revision") | del(.metadata.creationTimestamp) | del(.metadata.labels."pod-template-hash") | del(.spec.selector.matchLabels."pod-template-hash") | del(.spec.template.metadata.labels."pod-template-hash")'

    #export DELTA_FEATURES=+side-by-side
    for ((i=0; i< $((l_n -1)); i++)); do

        l_date="${la_rev_dates[$i]}"
        l_name="${la_rev_names[$i]}"
        l_name_next="${la_rev_names[$((i + 1))]}"

        #Calcular si es la revision actual y sus etiquetas
        l_revision_flag=''
        l_revision_flag_next=''
        if [ $l_idx_revision -ge 0 ]; then
            if [ $l_idx_revision -eq $i ]; then
                l_revision_flag='(*)'
            elif [ $l_idx_revision -eq $((i + 1)) ]; then
                l_revision_flag_next='(*)'
            fi
        fi

        #Mostrar como tabla, con texto rojo y verde
        printf '\n\n%bCambios %s%s -> %s%s :%b ' "$g_color_cyan1" "${la_rev_nbrs[$((i + 1))]}" "$l_revision_flag_next" \
               "${la_rev_nbrs[$i]}" "$l_revision_flag" "$g_color_reset"
        printf 'Realizados el "%s" en la revisión %b%s%b%s ("%b%s%b") ' "$l_date" "$l_color_old" "${la_rev_nbrs[$((i + 1))]}" \
               "$g_color_reset" "$l_revision_flag_next" "$l_color_old" "$l_name_next" "$g_color_reset"
        printf 'para llegar a ser revisión %b%s%b%s ("%b%s%b")\n' "$l_color_new" "${la_rev_nbrs[$i]}" \
               "$g_color_reset" "$l_revision_flag" "$l_color_new" "$l_name" "$g_color_reset"

        printf "%bThe following field are not considered: '.metadata.name', '.metadata.uid', '.metadata.creationTimestamp', '.metadata.resourceVersion', '.metadata.annotations.\"deployment.kubernetes.io/revision\"', '.metadata.ownerReferences[].uid', '.metadata.labels.\"pod-template-hash\", '.spec.selector.matchLabels.\"pod-template-hash\"' and '.spec.template.metadata.labels.\"pod-template-hash\"'%b\\n" "$g_color_gray1" "$g_color_reset"

        #Mostrar la diferencias sin mostrar el paginado (mostrar el pager muestra UI interactiva que detendria el proceso hasta que el usuario termine a revisarlo)
        delta --paging never <(echo "$_g_data_object_json" | jq --argjson index "$((i + 1))" "$l_jq_query") <(echo "$_g_data_object_json" | jq --argjson index "$i" "$l_jq_query")

    done

}


#Parametros (argumentos y opciones) de entrada:
#  1 > El nombre deployment
#  2 > El nombre namespace
show_dply_revision1() {

    #1. Información basica del Deployment
    #¿Why show a TAB in the beginning?
    printf '\n'
    printf '%bDeployment         :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$1"
    printf '%bNamespace          :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"

    #2. Obtener información del los replicaset asociado a las revisiones dle deployment
    local l_data_json=""
    l_data_json=$(${g_kubectl_cmd} get replicaset -n ${2} -o json 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf '%b\tNo se puede conectarse con el cluster de Kubernates, revise la conexión.%b\n' "$g_color_gray1" "$g_color_reset"
        return 1
    fi

    local l_jq_query='[.items[] | select(any(.metadata.ownerReferences[]; .kind == "Deployment" and .name == $objName)) ] | sort_by(.metadata.annotations."deployment.kubernetes.io/revision") | reverse'
    _g_data_object_json=$(echo "$l_data_json" | jq --arg objName "$1" "$l_jq_query" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf '%b\tError al obtener la data de los ReplicaSet.%b\n' "$g_color_gray1" "$g_color_reset"
        return 2
    fi

    if [ -z "$_g_data_object_json" ] || [ "$_g_data_object_json" = "null" ] || [ "$_g_data_object_json" = "[]" ]; then
        printf '%bNo se han encontrado revisiones para el deployment.%b\n' "$g_color_gray1" "$g_color_reset"
        return 3
    fi

    #3. Mostrar las revisiones encontradas y compararlas
    _show_compare_revision

}


#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos
#  2 > El nombre replicaset
#  3 > El nombre namespace
show_dply_revision2() {

    local -i p_use_one_object=1
    if [ "$4" = "0"  ]; then
        p_use_one_object=0
    fi

    #1. Información basica del Deployment
    #¿Why show a TAB in the beginning?
    printf '\n'
    printf '%bReplicaSet         :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"
    printf '%bNamespace          :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$3"

    #2. Obtener informacion del replicaset: ¿tiene como owner un deployment?
    local l_jq_query
    local l_data

    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | { owner: (.metadata.ownerReferences[]? | select(.kind == "Deployment") | .name), revision: .metadata.annotations."deployment.kubernetes.io/revision", creationTime: .metadata.creationTimestamp } | "\(.owner)|\(.revision)|\(.creationTime)"'

        l_data=$(jq -r --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf '%b\tError al obtener información del replicaset.%b\n' "$g_color_gray1" "$g_color_reset"
            return 1
        fi

    else

        l_jq_query='{ owner: (.metadata.ownerReferences[]? | select(.kind == "Deployment") | .name), revision: .metadata.annotations."deployment.kubernetes.io/revision", creationTime: .metadata.creationTimestamp } | "\(.owner)|\(.revision)|\(.creationTime)"'

        l_data=$(cat "$1" | jq -r "$l_jq_query" 2> /dev/null)
        if [ $? -ne 0 ]; then
            printf '%b\tError al obtener información del replicaset.%b\n' "$g_color_gray1" "$g_color_reset"
            return 1
        fi
    fi

    local IFS='|'
    local la_data=(${l_data})
    IFS=$' \t\n'
    local l_n=${#la_data[@]}

    if [ $l_n -le 0 ]; then
        printf '%b\tEl replicaset no esta vinculado a un Deployment.%b\n' "$g_color_gray1" "$g_color_reset"
        return 2
    fi

    local l_deployment_name="${la_data[0]}"
    if [ -z "$l_deployment_name" ]; then
        printf '%b\tEl replicaset no tiene owner a un Deployment.%b\n' "$g_color_gray1" "$g_color_reset"
        return 3
    fi

    printf '%bDeployment         :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$l_deployment_name"

    #2. Obtener información del los replicaset asociado a las revisiones dle deployment
    if [ $p_use_one_object -ne 0 ]; then

        l_jq_query='[.items[] | select(any(.metadata.ownerReferences[]; .kind == "Deployment" and .name == $objName)) ] | sort_by(.metadata.annotations."deployment.kubernetes.io/revision") | reverse'
        _g_data_object_json=$(jq --arg objName "$l_deployment_name" "$l_jq_query" "$1" 2> /dev/null)

        if [ $? -ne 0 ]; then
            printf '%b\tError al obtener la data de las revisiones.%b\n' "$g_color_gray1" "$g_color_reset"
            return 4
        fi

    else

        l_jq_query='[ . | select(any(.metadata.ownerReferences[]; .kind == "Deployment" and .name == $objName)) ] | sort_by(.metadata.annotations."deployment.kubernetes.io/revision") | reverse'
        _g_data_object_json=$(cat "$1" | jq --arg objName "$l_deployment_name" "$l_jq_query" 2> /dev/null)

        if [ $? -ne 0 ]; then
            printf '%b\tError al obtener la data de las revisiones.%b\n' "$g_color_gray1" "$g_color_reset"
            return 4
        fi

    fi

    if [ -z "$_g_data_object_json" ] || [ "$_g_data_object_json" = "null" ] || [ "$_g_data_object_json" = "[]" ]; then
        printf '%bNo se han encontrado revisiones para el deployment %s.%b\n' "$g_color_gray1" "$l_deployment_name" "$g_color_reset"
        return 5
    fi

    #3. Mostrar las revisiones encontradas y compararlas
    _show_compare_revision "$2"

}



#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos de los replicaset.
#  2 > Flag '0' para mostrar solo las replicaset con pods, caso contrario muestra todos.
#  3 > Flag '0' si se trata de un solo objeto (no tiene '.items[]')
show_replicasets_table() {

    local -i p_use_one_object=1
    if [ "$3" = "0"  ]; then
        p_use_one_object=0
    fi

    #Generar el reporte deseado con la data ingresada
    local l_jq_query='[.items[] | '
    if [ $p_use_one_object -eq 0 ]; then
        l_jq_query='[ . | '
    fi

    if [ "$2" = "0" ]; then
        l_jq_query="${l_jq_query}"'select(.spec.replicas > 0) | '
    fi

    l_jq_query="${l_jq_query}"'(reduce (.spec.selector.matchLabels | to_entries[]) as $i (""; . + (if . != "" then "," else "" end) + "\($i.key)=\($i.value)")) as $labels | { name: .metadata.name, namespace: .metadata.namespace, revision: .metadata.annotations."deployment.kubernetes.io/revision", desiredReplicas: .spec.replicas, currentReplicas: .status.replicas, readyReplicas: (.status.readyReplicas//0), availableReplicas: (.status.availableReplicas//0), fullyLabeledReplicas: .status.fullyLabeledReplicas, owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), time:  .metadata.creationTimestamp} | { NAME: .name, NAMESPACE: .namespace, OWNERS: .owners, DESIRED: .desiredReplicas, READY: "\(.readyReplicas)/\(.currentReplicas)", AVAILABLE: .availableReplicas, INITIAL: .time, REVISION: .revision, "SELECTOR-MATCH-LABELS": $labels}]'

    local l_data=""
    l_data=$(jq "$l_jq_query" "${1}" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    if [ -z "$l_data" ] || [ "$l_data" = "[]" ]; then
        return 2
    fi

    echo "$l_data" | jtbl -n
    return 0

}



#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos de los pods.
#  2 > Flag '0' para mostrar solo los pod que no terminen 'Succeeded' (Not-succeeded), caso contrario muestra todos.
#  3 > Flag '0' si se trata de un solo objeto (no tiene '.items[]')
show_pods_table() {

    local -i p_use_one_object=1
    if [ "$3" = "0"  ]; then
        p_use_one_object=0
    fi

    #Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_jq_query='[.items[] | '
    if [ $p_use_one_object -eq 0 ]; then
        l_jq_query='[ . | '
    fi

    if [ "$2" = "0" ]; then
        l_jq_query="${l_jq_query}"'select(.status.phase != "Succeeded") | '
    fi

    l_jq_query="${l_jq_query}"'{ name: .metadata.name, namespace: .metadata.namespace, status: .status.phase, startTime: .status.startTime, ip: .status.podIP, nodeName: .spec.nodeName, owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(",")), ready: (first(.status.conditions[]? | select(.type == "Ready"))), cntNbr: (.spec.containers | length), cntNbrPorts: ([.spec.containers[].ports[]? | select(.protocol == "TCP") | .containerPort] | length), cntNbrReadys: ([.status.containerStatuses[]? | select(.ready)] | length), cntNbrRestarts: ([.status.containerStatuses[]? | .restartCount] | add), cnt: ([.spec.containers[]?.name] | join(",")) } | { "POD-NAME": .name, "POD-NAMESPACE": .namespace, STATE: .status, READY: ("\(.cntNbrReadys)/\(.cntNbr)" + (if .cntNbrReadys == .cntNbr then "" elif  .ready?.status == "False" then "" else "(OB=\(.cntNbr - .cntNbrReadys))" end)), RESTARTS: .cntNbrRestarts, "START-TIME": .startTime, "READY-TIME": (if .ready?.status == "True" then .ready?.lastTransitionTime else "-" end), "FINISHED-TIME": (if .ready?.status == "False" then .ready?.lastTransitionTime else "-" end), "PORTS-NBR": .cntNbrPorts, OWNERS: (if .owners == "" then "-" else .owners end), "NODE-NAME": .nodeName, "POD-IP": .ip, CONTAINERS: .cnt}]'

    local l_data=""
    l_data=$(jq "$l_jq_query" "${1}" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    if [ -z "$l_data" ] || [ "$l_data" = "[]" ]; then
        return 2
    fi

    echo "$l_data" | jtbl -n
    return 0

}



#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos de los pods.
#  2 > Flag '0' para mostrar solo los pod que no terminen 'Succeeded' (Not-succeeded), caso contrario muestra todos.
#  3 > Flag '0' si se trata de un solo objeto (no tiene '.items[]')
show_containers_table() {

    local -i p_use_one_object=1
    if [ "$3" = "0"  ]; then
        p_use_one_object=0
    fi

    #Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_jq_query='[.items[] | '
    if [ $p_use_one_object -eq 0 ]; then
        l_jq_query='[ . | '
    fi

    if [ "$2" = "0" ]; then
        l_jq_query="${l_jq_query}"'select(.status.phase != "Succeeded") | '
    fi

    l_jq_query="${l_jq_query}"'(.spec.containers | length) as $allcont | { podName: .metadata.name, podNamespace: .metadata.namespace, podStatus: .status.phase, podStartTime: .status.startTime, podIP: .status.podIP, nodeName: .spec.nodeName, container: .spec.containers[], containerStatuses: .status.containerStatuses } | .container.name as $name | { podName: .podName, podNamespace: .podNamespace, podCntNbr: $allcont, podCntReady: ([.containerStatuses[].ready | select(. == true)] | length), podStartTime: .podStartTime, podIP: .podIP, nodeName: .nodeName, name: .container.name, image: .container.image, ports: ([.container.ports[]? | select(.protocol == "TCP") | .containerPort] | join(",")), status: (.containerStatuses[] | select(.name == $name)) } | (.status.state | to_entries[0]) as $st | { "POD-NAME": .podName, "POD-NAMESPACE": .podNamespace, CONTAINER: .name, "STATE": $st.key, READY: .status.ready, "POD-READY": ("\(.podCntReady)/\(.podCntNbr)" + (if .podCntReady == .podCntNbr then "" else "(OB=\(.podCntNbr - .podCntReady))" end)), "TCP-PORTS": (if .ports == "" then "-" else .ports end), "RESTART": .status.restartCount, "STARTED": (.status.started//"-"), "STARTED-AT": ($st.value.startedAt//"-"),  "FINISHED-AT": ($st.value.finishedAt//"-"), REASON: ($st.value.reason//"-"), "EXIT-CODE": ($st.value.exitCode//"-"), "POD-STARTED-AT": .podStartTime, "POD-IP": .podIP, "NODE-NAME": .nodeName }]'

    local l_data=""
    l_data=$(jq "$l_jq_query" "${1}" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    if [ -z "$l_data" ] || [ "$l_data" = "[]" ]; then
        return 2
    fi

    echo "$l_data" | jtbl -n
    return 0

}




#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos de los pods.
#  2 > Flag '0' si se trata de un solo objeto (no tiene '.items[]')
show_deployment_table() {

    local -i p_use_one_object=1
    if [ "$2" = "0"  ]; then
        p_use_one_object=0
    fi

    local l_jq_query='[.items[] | '
    if [ $p_use_one_object -eq 0 ]; then
        l_jq_query='[ . | '
    fi

    #Generar el reporte deseado con la data ingresada
    local l_jq_query="$l_jq_query"'(reduce (.spec.selector.matchLabels | to_entries[]) as $i (""; . + (if . != "" then "," else "" end) + "\($i.key)=\($i.value)")) as $labels | { name: .metadata.name, namespace: .metadata.namespace, revision: .metadata.annotations."deployment.kubernetes.io/revision", desiredReplicas: .spec.replicas, currentReplicas: .status.replicas, readyReplicas: .status.readyReplicas, availableReplicas: .status.availableReplicas, updatedReplicas: .status.updatedReplicas, owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), lastTransitionTime: (.status.conditions[] | select(.type=="Progressing") | .lastTransitionTime) } | { NAME: .name, NAMESPACE: .namespace, DESIRED: .desiredReplicas, READY: "\(.readyReplicas)/\(.currentReplicas)", "UP-TO-DATE": .updatedReplicas, AVAILABLE: .availableReplicas, INITIAL: .lastTransitionTime, REVISION: .revision, "SELECTOR-MATCH-LABELS": $labels, OWNERS: (if .owners == "" then "-" else .owners end)}]'

    local l_data=""
    l_data=$(jq "$l_jq_query" "${1}" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    if [ -z "$l_data" ] || [ "$l_data" = "[]" ]; then
        return 2
    fi

    echo "$l_data" | jtbl -n
    return 0

}




#Parametros (argumentos y opciones) de entrada:
#  1 > La ruta del archivo de datos de los pods.
#  2 > Flag '0' si es un projecto
show_namespace_table() {

    local l_is_project=1
    if [ "$3" = "0" ]; then
        l_is_project=0
    fi

    #Generar el reporte deseado con la data ingresada
    local l_jq_query='[.items[] | { NAME: .metadata.name, STATUS: .status.phase, "CREATION-TIME": .metadata.creationTimestamp }]'

    local l_data=""
    l_data=$(jq "$l_jq_query" "${1}" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    if [ -z "$l_data" ] || [ "$l_data" = "[]" ]; then
        return 2
    fi

    echo "$l_data" | jtbl -n
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> resource
# -------------------------------------------------------------------------------------

m_usage_resource() {

    local l_scmd_id='resource'
    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-l LABEL_SELECTORS] [-f FIELD_SELECTORS] %bRESOURCE_NAME%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_green1" "$g_color_reset"

    printf '\nLas opciones usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-n%b NAMESPACE%b Nombre del namespace. Si no se especifica se usara el actual.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-A%b Busca en todos los namespace del cluster.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n\n" "$g_color_gray1" "$g_color_reset"

    printf 'Los argumentos usados son:\n'
    printf '%b  > %bRESOURCE_NAME%b nombre o tipo de recurso a buscar.%b\n\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"

}


m_kc_resources() {

    #1. Argumentos
    local p_resource_name="$1"
    local p_flag_all_ns="$2"
    local p_ns="$3"
    local p_filter_label="$4"
    local p_filter_field="$5"

    #2. Procesar los argumentos y modificar las variables segun ello
    local l_awk_template="{print \"${p_resource_name}/\"\$1}"
    _g_fzf_kc_options="${p_resource_name}/{1}"
    local la_args=("get" "$p_resource_name")

    #Namespace
    if [ ! -z "$p_ns" ]; then
        la_args+=("-n" "$p_ns")
        l_awk_template="{print \"${p_resource_name}/\"\$1\" -n $2\"}"
        _g_fzf_kc_options="${p_resource_name}/{1} -n=$2"
    elif [ "$p_flag_all_ns" -eq 0 ]; then
        la_args+=("-A")
        l_awk_template="{print \"${p_resource_name}/\"\$2\" -n \"\$1}"
        _g_fzf_kc_options="${p_resource_name}/{2} -n={1}"
    fi


    #Labels
    if [ ! -z "$p_filter_label" ]; then
        la_args+=("-l" "$p_filter_label")
    fi

    #Filed Selectors
    if [ ! -z "$p_filter_field" ]; then
        la_args+=("--field-selector" "$p_filter_field")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    _g_temfile_fullpath="${g_tmpfile_path}/resource_${g_tmpfile_suffix}.json"

    if [ "$_g_use_cache_before" -ne 0 ] || [ ! -f "$_g_temfile_fullpath" ]; then

        oc "${la_args[@]}" > "$_g_temfile_fullpath"
        if [ $? -ne 0 ]; then
            echo "Check the connection to k8s cluster"
            return 1
        fi

    else
        printf 'Cache file: "%b%s%b"\n' "$g_color_gray1" "$_g_temfile_fullpath" "$g_color_reset"
    fi

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi


    #3. Generar el reporte deseado con la data ingresada
    FZF_DEFAULT_COMMAND="$l_cmd" \
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=1 -m \
        --prompt "${l_resource_name}> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-r (reload), CTRL-a (View yaml)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(oc get ${_g_fzf_kc_options} -o yaml) > /dev/tty" \
        --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' |
    awk "$l_awk_template"

    if [ "$_g_preserve_cache_after" -ne 0 ]; then
        rm -f "${_g_temfile_fullpath}"
    fi

}


m_controller_get_resource() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_flag_all_ns=1
    local l_ns
    local l_filter_label
    local l_filter_field

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_resource
                return 0
                ;;


            -A)
                l_flag_all_ns=0
                ;;


            -n)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requiere un valor especifico.\n' "$g_color_gray1" "-n" "$g_color_reset"
                    return 3
                fi

                l_ns="$2"
                shift 2
                ;;


            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requiere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requiere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_resource
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_resource_name="$1"
    if [ -z "$l_resource_name" ]; then
        printf 'El nombre de recurso "%b%s%b" debe ser especifico.\n' "$g_color_gray1" "$l_resource_name" "$g_color_reset"
        return 3
    fi

    #5. Ejecutando el comando
    m_kc_resources "$l_resource_name" "$l_flag_all_ns" "$l_ns" "$l_filter_label" "$l_filter_field"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> project
# -------------------------------------------------------------------------------------

m_usage_project() {

    local l_scmd_id='project'
    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-l LABEL_SELECTORS] [-f FIELD_SELECTORS]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n\n" "$g_color_gray1" "$g_color_reset"

}


m_oc_projects() {

    #1. Argumentos
    local p_filter_label="$1"
    local p_filter_field="$2"

    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get" "project")

    #Labels
    if [ ! -z "$p_filter_label" ]; then
        la_args+=("-l" "$p_filter_label")
    fi

    #Filed Selectors
    if [ ! -z "$p_filter_field" ]; then
        la_args+=("--field-selector" "$p_filter_field")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    _g_temfile_fullpath="${g_tmpfile_path}/projects_${g_tmpfile_suffix}.json"

    if [ "$_g_use_cache_before" -ne 0 ] || [ ! -f "$_g_temfile_fullpath" ]; then

        oc "${la_args[@]}" > "$_g_temfile_fullpath"
        if [ $? -ne 0 ]; then
            echo "Check the connection to k8s cluster"
            return 1
        fi

    else
        printf 'Cache file: "%b%s%b"\n' "$g_color_gray1" "$_g_temfile_fullpath" "$g_color_reset"
    fi


    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(show_namespace_table "${_g_temfile_fullpath}" 0)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi



    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    local l_awk_template='{print $1}'

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..1 \
        --prompt "Project> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTRL-d (Set Default), CTRL-e (View Events)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${g_script_path} -i show_object_yaml '${_g_temfile_fullpath}' '{1}' 1) > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_namespace_info '${_g_temfile_fullpath}' '{1}' 0) > /dev/tty" \
        --bind "ctrl-d:execute-silent:oc project {1}" \
        --bind "ctrl-e:execute:bat --color=always --paging always --style plain <(${g_kubectl_cmd} get event -n={1}) > /dev/tty" \
        --preview-window "right,60%" \
        --preview "bash ${g_script_path} -i show_namespace_info '${_g_temfile_fullpath}' '{1}' 0 | bat --color=always --style plain" |
    awk "$l_awk_template"


    if [ "$_g_preserve_cache_after" -ne 0 ]; then
        rm -f "${_g_temfile_fullpath}"
    fi


}



m_controller_get_project() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_filter_label
    local l_filter_field

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_project
                return 0
                ;;

            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_project
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_oc_projects "$l_filter_label" "$l_filter_field"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> namespace
# -------------------------------------------------------------------------------------

m_usage_namespace() {

    local l_scmd_id='namespace'
    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-l LABEL_SELECTORS] [-f FIELD_SELECTORS]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n\n" "$g_color_gray1" "$g_color_reset"

}


m_kc_namespaces() {

    #1. Argumentos
    local p_filter_label="$1"
    local p_filter_field="$2"

    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get" "namespace")

    #Labels
    if [ ! -z "$p_filter_label" ]; then
        la_args+=("-l" "$p_filter_label")
    fi

    #Filed Selectors
    if [ ! -z "$p_filter_field" ]; then
        la_args+=("--field-selector" "$p_filter_field")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    _g_temfile_fullpath="${g_tmpfile_path}/namespaces_${g_tmpfile_suffix}.json"

    if [ "$_g_use_cache_before" -ne 0 ] || [ ! -f "$_g_temfile_fullpath" ]; then

        ${g_kubectl_cmd} "${la_args[@]}" > "$_g_temfile_fullpath"
        if [ $? -ne 0 ]; then
            echo "Check the connection to k8s cluster"
            return 1
        fi

    else
        printf 'Cache file: "%b%s%b"\n' "$g_color_gray1" "$_g_temfile_fullpath" "$g_color_reset"
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(show_namespace_table "${_g_temfile_fullpath}" 1)
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    local l_awk_template='{print $1}'

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..1 \
        --prompt "Project> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTR-d (Set Default), CTRL-e (View Events)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${g_script_path} -i show_object_yaml '${_g_temfile_fullpath}' '{1}' 1) > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_namespace_info '${_g_temfile_fullpath}' '{1}' 1) > /dev/tty" \
        --bind "ctrl-d:execute-silent:${g_kubectl_cmd} config set-context --current --namespace={1}" \
        --bind "ctrl-e:execute:bat --color=always --paging always --style plain <(${g_kubectl_cmd} get event -n={1}) > /dev/tty" \
        --preview-window "right,60%" \
        --preview "bash ${g_script_path} -i show_namespace_info '${_g_temfile_fullpath}' '{1}' 1 | bat --color=always --style plain" |
    awk "$l_awk_template"


    if [ "$_g_preserve_cache_after" -ne 0 ]; then
        rm -f "${_g_temfile_fullpath}"
    fi

}


m_controller_get_namespace() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_filter_label
    local l_filter_field

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_namespace
                return 0
                ;;

            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_namespace
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes


    #5. Ejecutando el comando
    m_kc_namespaces "$l_filter_label" "$l_filter_field"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> pod
# -------------------------------------------------------------------------------------

m_usage_pod() {

    local l_scmd_id='pod'
    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A] [-l LABEL_SELECTORS] [-f FIELD_SELECTORS]%b\n' "$g_color_yellow1" \
           "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A]%b OBJECT_NAME%b\n' "$g_color_yellow1" \
           "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_green1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones para filtrar los pods:\n'
    printf '%b  > %b-n%b NAMESPACE%b Nombre del namespace. Si no se especifica se usara el actual.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-A%b Busca en todos los namespace del cluster.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" \
           "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n" "$g_color_gray1" "$g_color_reset"

    printf '\nLas argumentos puede ser:\n'
    printf '%b  > %bOBJECT_NAME%b Nombre del objeto de recurso "Pod".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_kc_pod() {

    #1. Argumentos
    local p_flag_all_ns="$1"
    local p_ns="$2"
    local p_filter_label="$3"
    local p_filter_field="$4"
    local p_object_name="$5"


    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get" "pod")

    #Namespace
    if [ ! -z "$p_ns" ]; then
        la_args+=("-n" "$p_ns")
    elif [ "$p_flag_all_ns" -eq 0 ]; then
        la_args+=("-A")
    fi

    # Filtros
    if [ -z "$p_object_name" ]; then

        _g_use_one_object=1

        # Filtro de Labels
        if [ ! -z "$p_filter_label" ]; then
            la_args+=("-l" "$p_filter_label")
        fi

        # Filtro de Filed Selectors
        if [ ! -z "$p_filter_field" ]; then
            la_args+=("--field-selector" "$p_filter_field")
        fi

    else
        _g_use_one_object=0
        la_args+=("$p_object_name")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    _g_temfile_fullpath="${g_tmpfile_path}/pods_${g_tmpfile_suffix}.json"

    if [ "$_g_use_cache_before" -ne 0 ] || [ ! -f "$_g_temfile_fullpath" ]; then

        ${g_kubectl_cmd} "${la_args[@]}" > "$_g_temfile_fullpath"
        if [ $? -ne 0 ]; then
            echo "Check the connection to k8s cluster"
            return 1
        fi

    else
        printf 'Cache file: "%b%s%b"\n' "$g_color_gray1" "$_g_temfile_fullpath" "$g_color_reset"
    fi


    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(show_pods_table "${_g_temfile_fullpath}" 0 "$_g_use_one_object")
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    local l_awk_template='{print "pod/"$1" -n "$2}'

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..2 \
        --prompt "Not-succeeded Pod> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTRL-e (Exit & Terminal), CTRL-t (Bash Terminal), CTRL-l (View log), CTRL-p (Exit & Port-Forward), CTRL-x (Exit & follow logs), ALT-a (View all Pods), ATL-b (View Not-succeeded pods)\n' \
        --bind "alt-a:change-prompt(Pod> )+reload:bash \"${g_script_path}\" -i show_pods_table \"${_g_temfile_fullpath}\" 1 ${_g_use_one_object}" \
		--bind "alt-b:change-prompt(Not-succeeded Pod> )+reload:bash \"${g_script_path}\" -i show_pods_table \"${_g_temfile_fullpath}\" 0 ${_g_use_one_object}" \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${g_script_path} -i show_object_yaml '${_g_temfile_fullpath}' '{1}' ${_g_use_one_object} '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_pod_info '${_g_temfile_fullpath}' '{1}' '{2}' ${_g_use_one_object}) > /dev/tty" \
        --bind "ctrl-e:become:bash \"${g_script_path}\" -i open_terminal1 '{1}' '{2}' 'sh' 0 '${_g_temfile_fullpath}' ${_g_use_one_object} > /dev/tty" \
        --bind "ctrl-t:execute:bash \"${g_script_path}\" -i open_terminal1 '{1}' '{2}' 'sh' 1 '${_g_temfile_fullpath}' ${_g_use_one_object} > /dev/tty" \
        --bind "ctrl-l:execute(bash \"${g_script_path}\" -i show_log_pod '{1}' '{2}' 1 10000 '${_g_temfile_fullpath}' ${_g_use_one_object} > /dev/tty)" \
        --bind "ctrl-p:become(bash \"${g_script_path}\" -i port_forward_pod '{1}' '{2}' '${_g_temfile_fullpath}' ${_g_use_one_object} > /dev/tty)" \
        --bind "ctrl-x:become(bash \"${g_script_path}\" -i show_log_pod '{1}' '{2}' 0 200 '${_g_temfile_fullpath}' ${_g_use_one_object} > /dev/tty)" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${g_script_path} -i show_pod_info '${_g_temfile_fullpath}' '{1}' '{2}' ${_g_use_one_object} | bat --color=always --style plain" |
    awk "$l_awk_template"

    if [ "$_g_preserve_cache_after" -ne 0 ]; then
        rm -f "${_g_temfile_fullpath}"
    fi

}


m_controller_get_pod() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_flag_all_ns=1
    local l_ns
    local l_filter_label
    local l_filter_field

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_pod
                return 0
                ;;


            -A)
                l_flag_all_ns=0
                ;;


            -n)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-n" "$g_color_reset"
                    return 3
                fi

                l_ns="$2"
                shift 2
                ;;


            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_pod
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_object_name=""

    if [ ! -z "$1" ]; then
        if [ ! -z "$l_filter_label" ] || [ ! -z "$l_filter_field" ]; then
            printf '[%bERROR%b] Opción "%b%%%b" y/o "%b%s%b" no puede usarse cuando se especifica el argumento "%b%s%b".\n\n' \
                   "$g_color_red1" "$g_color_reset" "$g_color_gray1" "-l" "$g_color_reset" \
                   "$g_color_gray1" "-f" "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"
            m_usage_pod
            return 3
        fi

        l_object_name="$1"
    fi



    #5. Ejecutando el comando
    m_kc_pod "$l_flag_all_ns" "$l_ns" "$l_filter_label" "$l_filter_field" "$l_object_name"
    return 0

}





# -------------------------------------------------------------------------------------
# Subcomand Controller> container
# -------------------------------------------------------------------------------------

m_usage_container() {

    local l_scmd_id='container'
    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A] [-l LABEL_SELECTORS] [-f FIELD_SELECTORS]%b\n' "$g_color_yellow1" "$g_cmd_name" \
           "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A]%b OBJECT_NAME%b\n' "$g_color_yellow1" \
           "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_green1" "$g_color_reset"

    printf '\nLas opciones generales son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones para filtrar los pods:\n'
    printf '%b  > %b-n%b NAMESPACE%b Nombre del namespace. Si no se especifica se usara el actual.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-A%b Busca en todos los namespace del cluster.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" \
           "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n" "$g_color_gray1" "$g_color_reset"

    printf '\nLas argumentos puede ser:\n'
    printf '%b  > %bOBJECT_NAME%b Nombre del objeto de recurso "Pod".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_kc_containers() {

    #1. Argumentos
    local p_flag_all_ns="$1"
    local p_ns="$2"
    local p_filter_label="$3"
    local p_filter_field="$4"
    local p_object_name="$5"


    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get" "pod")

    #Namespace
    if [ ! -z "$p_ns" ]; then
        la_args+=("-n" "$p_ns")
    elif [ "$p_flag_all_ns" -eq 0 ]; then
        la_args+=("-A")
    fi

    # Filtros
    if [ -z "$p_object_name" ]; then

        _g_use_one_object=1

        # Filtro de Labels
        if [ ! -z "$p_filter_label" ]; then
            la_args+=("-l" "$p_filter_label")
        fi

        # Filtro de Filed Selectors
        if [ ! -z "$p_filter_field" ]; then
            la_args+=("--field-selector" "$p_filter_field")
        fi

    else
        _g_use_one_object=0
        la_args+=("$p_object_name")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    _g_temfile_fullpath="${g_tmpfile_path}/containers_${g_tmpfile_suffix}.json"

    if [ "$_g_use_cache_before" -ne 0 ] || [ ! -f "$_g_temfile_fullpath" ]; then

        ${g_kubectl_cmd} "${la_args[@]}" > "$_g_temfile_fullpath"
        if [ $? -ne 0 ]; then
            echo "Check the connection to k8s cluster"
            return 1
        fi

    else
        printf 'Cache file: "%b%s%b"\n' "$g_color_gray1" "$_g_temfile_fullpath" "$g_color_reset"
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data
    local l_status
    l_data=$(show_containers_table "${_g_temfile_fullpath}" 0 "${_g_use_one_object}")
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi

    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    local l_awk_template='{print "pod/"$1" -n "$2" -c "$3}'

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..3 \
        --prompt "Not-succeeded Pod's Container> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View pod yaml), CTRL-b (View Preview), CTRL-e (Exit & Terminal), CTRL-t (Bash Terminal), CTRL-l (View log), CTRL-p (Exit & Port-Forward), CTRL-x (Exit & follow logs), ALT-a (View all Pods), ATL-b (View Not-succeeded pods)\n' \
        --bind "alt-a:change-prompt(Pod's Container> )+reload:bash \"${g_script_path}\" -i show_containers_table \"${_g_temfile_fullpath}\" 1 ${_g_use_one_object}" \
		--bind "alt-b:change-prompt(Not-succeeded Pod's Container> )+reload:bash \"${g_script_path}\" -i show_containers_table \"${_g_temfile_fullpath}\" 0 ${_g_use_one_object}" \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${g_script_path} -i show_object_yaml '${_g_temfile_fullpath}' '{1}' ${_g_use_one_object} '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_container_info '${_g_temfile_fullpath}' '{1}' '{2}' '{3}' ${_g_use_one_object}) > /dev/tty" \
        --bind "ctrl-e:become:bash \"${g_script_path}\" -i open_terminal2 '{1}' '{2}' '{3}' 'sh' 0 '${_g_temfile_fullpath}' ${_g_use_one_object} > /dev/tty" \
        --bind "ctrl-t:execute:bash \"${g_script_path}\" -i open_terminal2 '{1}' '{2}' '{3}' 'sh' 1 '${_g_temfile_fullpath}' ${_g_use_one_object} > /dev/tty" \
        --bind "ctrl-l:execute(bash \"${g_script_path}\" -i show_log_container '{1}' '{2}' '{3}' 1 10000 '${_g_temfile_fullpath}' > /dev/tty)" \
        --bind "ctrl-p:become(bash \"${g_script_path}\" -i port_forward_container '{1}' '{2}' '{3}' '{7}' '${_g_temfile_fullpath}' > /dev/tty)" \
        --bind "ctrl-x:become(bash \"${g_script_path}\" -i show_log_container '{1}' '{2}' '{3}' 0 200 '${_g_temfile_fullpath}' > /dev/tty)" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${g_script_path} -i show_container_info '${_g_temfile_fullpath}' '{1}' '{2}' '{3}' ${_g_use_one_object} | bat --color=always --style plain" |
    awk "$l_awk_template"

    #    --bind "ctrl-l:execute:bat --color=always --paging always --style plain  <(${g_kubectl_cmd} logs {1} -n={2} -c={3} --tail=10000 --timestamps) > /dev/tty" \
    #    --bind "ctrl-x:become(bash \"${g_script_path}\" show_log 0 0 200 '{1}' '-n={2}' '-c={3}' '${_g_temfile_fullpath}' > /dev/tty)" \

    if [ "$_g_preserve_cache_after" -ne 0 ]; then
        rm -f "${_g_temfile_fullpath}"
    fi


}


m_controller_get_container() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_flag_all_ns=1
    local l_ns
    local l_filter_label
    local l_filter_field

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_container
                return 0
                ;;


            -A)
                l_flag_all_ns=0
                ;;


            -n)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-n" "$g_color_reset"
                    return 3
                fi

                l_ns="$2"
                shift 2
                ;;


            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_container
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_object_name=""

    if [ ! -z "$1" ]; then
        if [ ! -z "$l_filter_label" ] || [ ! -z "$l_filter_field" ]; then
            printf '[%bERROR%b] Opción "%b%%%b" y/o "%b%s%b" no puede usarse cuando se especifica el argumento "%b%s%b".\n\n' \
                   "$g_color_red1" "$g_color_reset" "$g_color_gray1" "-l" "$g_color_reset" \
                   "$g_color_gray1" "-f" "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"
            m_usage_container
            return 3
        fi

        l_object_name="$1"
    fi



    #5. Ejecutando el comando
    m_kc_containers "$l_flag_all_ns" "$l_ns" "$l_filter_label" "$l_filter_field" "$l_object_name"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> deployment
# -------------------------------------------------------------------------------------

m_usage_deployment() {

    local l_scmd_id='deployment'
    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A] [-l LABEL_SELECTORS] [-f FIELD_SELECTORS]%b\n' "$g_color_yellow1" "$g_cmd_name" \
           "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A]%b OBJECT_NAME%b\n' "$g_color_yellow1" \
           "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_green1" "$g_color_reset"

    printf '\nLas opciones generales son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones para filtrar los deployment:\n'
    printf '%b  > %b-n%b NAMESPACE%b Nombre del namespace. Si no se especifica se usara el actual.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-A%b Busca en todos los namespace del cluster.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n" "$g_color_gray1" "$g_color_reset"

    printf '\nLas argumentos puede ser:\n'
    printf '%b  > %bOBJECT_NAME%b Nombre del objeto de recurso "Deployment".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_kc_deployments() {

    #1. Argumentos
    local p_flag_all_ns="$1"
    local p_ns="$2"
    local p_filter_label="$3"
    local p_filter_field="$4"
    local p_object_name="$5"


    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get" "deployment")

    #Namespace
    if [ ! -z "$p_ns" ]; then
        la_args+=("-n" "$p_ns")
    elif [ "$p_flag_all_ns" -eq 0 ]; then
        la_args+=("-A")
    fi

    # Filtros
    if [ -z "$p_object_name" ]; then

        _g_use_one_object=1

        # Filtro de Labels
        if [ ! -z "$p_filter_label" ]; then
            la_args+=("-l" "$p_filter_label")
        fi

        # Filtro de Filed Selectors
        if [ ! -z "$p_filter_field" ]; then
            la_args+=("--field-selector" "$p_filter_field")
        fi

    else
        _g_use_one_object=0
        la_args+=("$p_object_name")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    _g_temfile_fullpath="${g_tmpfile_path}/deployments_${g_tmpfile_suffix}.json"

    if [ "$_g_use_cache_before" -ne 0 ] || [ ! -f "$_g_temfile_fullpath" ]; then

        ${g_kubectl_cmd} "${la_args[@]}" > "$_g_temfile_fullpath"
        if [ $? -ne 0 ]; then
            echo "Check the connection to k8s cluster"
            return 1
        fi

    else
        printf 'Cache file: "%b%s%b"\n' "$g_color_gray1" "$_g_temfile_fullpath" "$g_color_reset"
    fi

    #4. Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_data
    local l_status
    l_data=$(show_deployment_table "${_g_temfile_fullpath}" "${_g_use_one_object}")
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #1. Inicializar variables requeridas para fzf y awk
    #local l_awk_template='{print "deployment/"$1" -n "$2" | pod -n "$2"-l "$7}'
    local l_awk_template='{print "deployment/"$1" -n "$2}'

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..2 \
        --prompt "Deployment> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View yaml), CTRL-b (View Preview), CTRL-d (View Revisions), CTRL-w (Watch pods)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${g_script_path} -i show_object_yaml '${_g_temfile_fullpath}' '{1}' ${_g_use_one_object} '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_deployment_info '${_g_temfile_fullpath}' '{1}' '{2}' '{9}' ${_g_use_one_object}) > /dev/tty" \
        --bind "ctrl-d:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_dply_revision1 '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-w:execute:${g_kubectl_cmd} get pod -n={2} -l='{9}' -w -o wide > /dev/tty" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${g_script_path} -i show_deployment_info '${_g_temfile_fullpath}' '{1}' '{2}' '{9}' ${_g_use_one_object} | bat --color=always --style plain" |
    awk "$l_awk_template"

    if [ "$_g_preserve_cache_after" -ne 0 ]; then
        rm -f "${_g_temfile_fullpath}"
    fi

    #    --header "$(_fzf_kc_get_context_info 1)"$'\nCTRL-a (View yaml), CTRL-b (Preview in full-screen), CTRL-d (View revisions), CTRL-l (View logs), CTRL-x (Exit & follow logs)\n' \
    #    --bind "ctrl-l:execute(bash \"${g_script_path}\" show_log_dply '{1}' '{2}' 1 10000 '${_g_temfile_fullpath}' > /dev/tty)" \
    #    --bind "ctrl-x:become(bash \"${g_script_path}\" show_log_dply '{1}' '{2}' 0 200 '${_g_temfile_fullpath}' > /dev/tty)" \

}


m_controller_get_deployment() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_flag_all_ns=1
    local l_ns
    local l_filter_label
    local l_filter_field

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_deployment
                return 0
                ;;


            -A)
                l_flag_all_ns=0
                ;;


            -n)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-n" "$g_color_reset"
                    return 3
                fi

                l_ns="$2"
                shift 2
                ;;


            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_deployment
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_object_name=""

    if [ ! -z "$1" ]; then
        if [ ! -z "$l_filter_label" ] || [ ! -z "$l_filter_field" ]; then
            printf '[%bERROR%b] Opción "%b%%%b" y/o "%b%s%b" no puede usarse cuando se especifica el argumento "%b%s%b".\n\n' \
                   "$g_color_red1" "$g_color_reset" "$g_color_gray1" "-l" "$g_color_reset" \
                   "$g_color_gray1" "-f" "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"
            m_usage_deployment
            return 3
        fi

        l_object_name="$1"
    fi



    #5. Ejecutando el comando
    m_kc_deployments "$l_flag_all_ns" "$l_ns" "$l_filter_label" "$l_filter_field" "$l_object_name"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> replicaset
# -------------------------------------------------------------------------------------

m_usage_replicaset() {

    local l_scmd_id='replicaset'
    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A] [-l LABEL_SELECTORS] [-f FIELD_SELECTORS]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A]%b OBJECT_NAME%b\n' "$g_color_yellow1" \
           "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_green1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones para filtrar los replicaset:\n'
    printf '%b  > %b-n%b NAMESPACE%b Nombre del namespace. Si no se especifica se usara el actual.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-A%b Busca en todos los namespace del cluster.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n" "$g_color_gray1" "$g_color_reset"

    printf '\nLas argumentos puede ser:\n'
    printf '%b  > %bOBJECT_NAME%b Nombre del objeto de recurso "ReplicaSet".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_kc_replicaset() {

    #1. Argumentos
    local p_flag_all_ns="$1"
    local p_ns="$2"
    local p_filter_label="$3"
    local p_filter_field="$4"
    local p_object_name="$5"


    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get" "replicaset")

    #Namespace
    if [ ! -z "$p_ns" ]; then
        la_args+=("-n" "$p_ns")
    elif [ "$p_flag_all_ns" -eq 0 ]; then
        la_args+=("-A")
    fi

    # Filtros
    if [ -z "$p_object_name" ]; then

        _g_use_one_object=1

        # Filtro de Labels
        if [ ! -z "$p_filter_label" ]; then
            la_args+=("-l" "$p_filter_label")
        fi

        # Filtro de Filed Selectors
        if [ ! -z "$p_filter_field" ]; then
            la_args+=("--field-selector" "$p_filter_field")
        fi

    else
        _g_use_one_object=0
        la_args+=("$p_object_name")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    _g_temfile_fullpath="${g_tmpfile_path}/replicaset_${g_tmpfile_suffix}.json"

    if [ "$_g_use_cache_before" -ne 0 ] || [ ! -f "$_g_temfile_fullpath" ]; then

        ${g_kubectl_cmd} "${la_args[@]}" > "$_g_temfile_fullpath"
        if [ $? -ne 0 ]; then
            echo "Check the connection to k8s cluster"
            return 1
        fi

    else
        printf 'Cache file: "%b%s%b"\n' "$g_color_gray1" "$_g_temfile_fullpath" "$g_color_reset"
    fi


    #4. Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_data
    local l_status
    l_data=$(show_replicasets_table "${_g_temfile_fullpath}" 0 "${_g_use_one_object}")
    l_status=$?

    if [ $l_status -eq 1 ]; then
        echo "Error en el fitro usado"
        return 2
    elif [ $l_status -ne 0 ]; then
        echo "No data found"
        return 3
    fi


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    #local l_awk_template='{print "replicaset/"$1" -n "$2" | pod -n "$2"-l "$7}'
    local l_awk_template='{print "replicaset/"$1" -n "$2}'

    #5. Mostrar el reporte
    echo "$l_data" |
    $l_fzf_cmd $l_fzf_size_args --info=inline --layout=reverse --header-lines=2 -m --nth=..3 \
        --prompt "Active ReplicaSet> " \
        --header "$(_fzf_kc_get_context_info 1)"$'\nALT-a (View all rs), ATL-b (View rs with pods), CTRL-a (View yaml), CTRL-b (View Preview), CTRL-d (View Revisions), CTRL-w (Watch pods)\n' \
        --bind "alt-a:change-prompt(All Replicaset> )+reload:bash \"${g_script_path}\" -i show_replicasets_table \"${_g_temfile_fullpath}\" 1 ${_g_use_one_object}" \
		--bind "alt-b:change-prompt(Active Replicaset> )+reload:bash \"${g_script_path}\" -i show_replicasets_table \"${_g_temfile_fullpath}\" 0 ${_g_use_one_object}" \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${g_script_path} -i show_object_yaml '${_g_temfile_fullpath}' '{1}' ${_g_use_one_object} '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_replicaset_info '${_g_temfile_fullpath}' '{1}' '{2}' '{9}' ${_g_use_one_object}) > /dev/tty" \
        --bind "ctrl-d:execute:bat --color=always --paging always --style plain <(bash ${g_script_path} -i show_dply_revision2 '${_g_temfile_fullpath}' '{1}' '{2}' ${_g_use_one_object}) > /dev/tty" \
        --bind "ctrl-w:execute:${g_kubectl_cmd} get pod -n={2} -l='{9}' -w -o wide > /dev/tty" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${g_script_path} -i show_replicaset_info '${_g_temfile_fullpath}' '{1}' '{2}' '{9}' ${_g_use_one_object} | bat --color=always --style plain" |
    awk "$l_awk_template"

    if [ "$_g_preserve_cache_after" -ne 0 ]; then
        rm -f "${_g_temfile_fullpath}"
    fi

}


m_controller_get_replicaset() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_flag_all_ns=1
    local l_ns
    local l_filter_label
    local l_filter_field

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_replicaset
                return 0
                ;;


            -A)
                l_flag_all_ns=0
                ;;


            -n)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-n" "$g_color_reset"
                    return 3
                fi

                l_ns="$2"
                shift 2
                ;;


            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_replicaset
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_object_name=""

    if [ ! -z "$1" ]; then
        if [ ! -z "$l_filter_label" ] || [ ! -z "$l_filter_field" ]; then
            printf '[%bERROR%b] Opción "%b%%%b" y/o "%b%s%b" no puede usarse cuando se especifica el argumento "%b%s%b".\n\n' \
                   "$g_color_red1" "$g_color_reset" "$g_color_gray1" "-l" "$g_color_reset" \
                   "$g_color_gray1" "-f" "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"
            m_usage_replicaset
            return 3
        fi

        l_object_name="$1"
    fi


    #5. Ejecutando el comando
    m_kc_replicaset "$l_flag_all_ns" "$l_ns" "$l_filter_label" "$l_filter_field" "$l_object_name"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> logs
# -------------------------------------------------------------------------------------

m_usage_logs() {

    local l_scmd_id='logs'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_get_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE] [-l LABEL_SELECTORS] [-f FIELD_SELECTORS]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE | -A]%b OBJECT_NAME%b\n' "$g_color_yellow1" \
           "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_green1" "$g_color_reset"

    printf '\nLas opciones generales son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones para filtrar los pods:\n'
    printf '%b  > %b-n%b NAMESPACE%b Nombre del namespace. Si no se especifica se usara el actual.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones usados para almacenar el log de los pods:\n'
    printf '%b  > %b-d%b FOLDER_PATH%b Ruta del folder donde se almacenara los archivos logs.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"

    printf '%b  > %b-T%b Flag que muestra el timestamps en cada linea del archivo log. Por defecto no se muestra.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '%b  > %b-j%b Flag para almacenar el descriptor json del pod. Por defecto se almacena el descriptor.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-m%b Flag para almacenar los logs de todos los contenedor principales del pod. Por defecto solo se almacena el contenedor por defecto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-i%b Flag para almacenar los logs de todos los contenedores de inicialización del pod. Por defecto no se almacena logs de estos contenedores.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-e%b Flag para almacenar los logs de todos los contenedores efimeros del pod. Por defecto no se almacena logs de estos contenedores.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-x%b Flag para usar, en el sufijo del nombre del log, el nombre nodo. Por defecto no se adiciona al nombre de del log.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-y%b Flag para NO usar, en el sufijo del nombre del log, el nombre contenedor. Por defecto se adiciona al nombre del contenedor.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-z%b Flag para usar, en el sufijo del nombre del log, una marca de tiempo "yyyyMMdd_HHMM". Por defecto no se adiciona al nombre de del log.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas argumentos puede ser:\n'
    printf '%b  > %bOBJECT_NAME%b Nombre del objeto de recurso "Pod".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_kc_logs() {

    #1. Argumentos
    local p_ns="$1"
    local p_filter_label="$2"
    local p_filter_field="$3"

    local p_object_name="$4"
    local p_path_dir="$5"

    local -i p_flag_show_timestamp=1
    if [ "$6" = "0" ]; then
        p_flag_show_timestamp=0
    fi

    local -i p_flag_save_json=1
    if [ "$7" = "0" ]; then
        p_flag_save_json=0
    fi

    local -i p_flag_save_all_main=1
    if [ "$8" = "0" ]; then
        p_flag_save_all_main=0
    fi

    local -i p_flag_save_all_init=1
    if [ "$9" = "0" ]; then
        p_flag_save_all_init=0
    fi

    local -i p_flag_save_all_ephemeral=1
    if [ "${10}" = "0" ]; then
        p_flag_save_all_ephemeral=0
    fi

    local -i p_file_sufix_nodename=1
    if [ "${11}" = "0" ]; then
        p_file_sufix_nodename=0
    fi

    local -i p_file_sufix_containername=0
    if [ "${12}" != "0" ]; then
        p_file_sufix_containername=1
    fi

    local -i p_file_sufix_time=1
    if [ "${13}" = "0" ]; then
        p_file_sufix_time=0
    fi

    #echo "l_flag_save_all_main > ${p_flag_save_all_main}"

    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get" "pods")

    #Filtro de Namespace
    if [ ! -z "$p_ns" ]; then
        la_args+=("-n" "$p_ns")
    fi


    # Filtros
    if [ -z "$p_object_name" ]; then

        # Filtro de Labels
        if [ ! -z "$p_filter_label" ]; then
            la_args+=("-l" "$p_filter_label")
        fi

        # Filtro de Filed Selectors
        if [ ! -z "$p_filter_field" ]; then
            la_args+=("--field-selector" "$p_filter_field")
        fi

    else
        la_args+=("$p_object_name")
    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"

    #3. Filtro jq para obtener el listado de pod ordenados por el controlador del pod
    local l_filter='[.items[] | { name: .metadata.name, ns: .metadata.namespace, owner: (.metadata.ownerReferences[0]? | if . == null then "" else "\(.kind)/\(.name)" end) }] | sort_by(.owner, .name) | .[] | "\(.name)|\(.ns)|\(.owner)"'

    if [ ! -z "$p_object_name" ]; then
        l_filter='{ name: .metadata.name, ns: .metadata.namespace, owner: (.metadata.ownerReferences[0]? | if . == null then "" else "\(.kind)/\(.name)" end) } |  "\(.name)|\(.ns)|\(.owner)"'
    fi

    #4. Obtener los pods (ordenados por el nombre del controlador de pods)
    local -i l_status=0
    local l_data=''

    l_data=$(${g_kubectl_cmd} "${la_args[@]}" | jq -r "$l_filter")
    l_status=$?

    if [ $l_status -ne 0 ]; then

        printf "Ocurrio un error a listar los pod.\n"
        if [ ! -z "$l_data" ]; then
            printf "Detail: %s\n" "$l_data"
        fi

        return 1
    fi

    if [ -z "$l_data" ] || [ "$l_data" = 'null' ]; then
        printf "No se encuentra pod disponibles.\n"
        return 0
    fi

    #5. Si es un pod especifico
    local l_pod_name
    local l_pod_ns
    local l_pod_owner

    if [ ! -z "$p_object_name" ]; then

        IFS='|' read -r l_pod_name l_pod_ns l_pod_owner <<< "$l_data"

        printf '> Pod name         : %b%s%b\n' "$g_color_blue1" "$l_pod_name" "$g_color_reset"

        if [ ! -z "$l_pod_owner" ]; then
            printf '  Pod controller   : %b%s%b\n' "$g_color_gray1" "$l_pod_owner" "$g_color_reset"
        fi

        m_get_pod_logs "$l_pod_name" "$l_pod_ns" "$p_path_dir" "$p_flag_show_timestamp" "$p_flag_save_json" "$p_flag_save_all_main" \
                       "$p_flag_save_all_init" "$p_flag_save_all_ephemeral" "$p_file_sufix_nodename" "$p_file_sufix_containername" \
                       "$p_file_sufix_time"

        return 0

    fi

    #6. Si es un conjuntos de pod
    local l_n
    l_n=$(echo "$l_data" | wc -l)
    printf 'Guardando el log de %b%s%b pod(s) disponibles ...\n' "$g_color_gray1" "$l_n" "$g_color_reset"

    local l_pod_owner_previous
    local -i l_i=0
    local -i l_j=0

    # Incluir un contador y un resumen final
    while IFS='|' read -r l_pod_name l_pod_ns l_pod_owner; do

        ((l_i++))
        if [ -z "$l_pod_name" ]; then
            continue
        fi

        printf '> Pod name         : (%b%s%b/%b%s%b) %b%s%b\n' "$g_color_gray1" "$l_i" "$g_color_reset" \
               "$g_color_gray1" "$l_n" "$g_color_reset" "$g_color_blue1" "$l_pod_name" "$g_color_reset"


        if [ -z "$l_pod_owner_previous" ] || [ "$l_pod_owner" != "$l_pod_owner_previous" ]; then
            ((l_j++))
        fi

        if [ ! -z "$l_pod_owner" ]; then
            printf '  Pod controller   : (%b%s%b) %b%s%b\n' "$g_color_gray1" "$l_j" "$g_color_reset" \
                   "$g_color_gray1" "$l_pod_owner" "$g_color_reset"
        fi

        m_get_pod_logs "$l_pod_name" "$l_pod_ns" "$p_path_dir" "$p_flag_show_timestamp" "$p_flag_save_json" "$p_flag_save_all_main" \
                       "$p_flag_save_all_init" "$p_flag_save_all_ephemeral" "$p_file_sufix_nodename" "$p_file_sufix_containername" \
                       "$p_file_sufix_time"

        l_pod_owner_previous="$l_pod_owner"

    done <<< "$l_data"

    return 0

}



m_controller_logs() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_ns
    local l_filter_label
    local l_filter_field

    local l_path_dir=""

    local -i l_flag_show_timestamp=1
    local -i l_flag_save_json=1
    local -i l_flag_save_all_main=1
    local -i l_flag_save_all_init=1
    local -i l_flag_save_all_ephemeral=1
    local -i l_file_sufix_nodename=1
    local -i l_file_sufix_containername=0
    local -i l_file_sufix_time=1

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_logs
                return 0
                ;;


            -n)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-n" "$g_color_reset"
                    return 3
                fi

                l_ns="$2"
                shift 2
                ;;


            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -d)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no puede ser vacio.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset"
                    m_usage_logs
                    return 3
                fi

                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido "%b%s%b". Debe ser un folder valido.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    return 3
                fi

                l_path_dir="$2"
                shift 2
                ;;


            -T)
                l_flag_show_timestamp=0
                shift 1
                ;;

            -j)
                l_flag_save_json=0
                shift 1
                ;;

            -m)
                l_flag_save_all_main=0
                shift 1
                ;;

            -i)
                l_flag_save_all_init=0
                shift 1
                ;;

            -e)
                l_flag_save_all_ephemeral=0
                shift 1
                ;;


            -x)
                l_file_sufix_nodename=0
                shift 1
                ;;

            -y)
                l_file_sufix_containername=1
                shift 1
                ;;

            -z)
                l_file_sufix_time=0
                shift 1
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_logs
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_object_name=""

    if [ ! -z "$1" ]; then
        if [ ! -z "$l_filter_label" ] || [ ! -z "$l_filter_field" ]; then
            printf '[%bERROR%b] Opción "%b%%%b" y/o "%b%s%b" no puede usarse cuando se especifica el argumento "%b%s%b".\n\n' \
                   "$g_color_red1" "$g_color_reset" "$g_color_gray1" "-l" "$g_color_reset" \
                   "$g_color_gray1" "-f" "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"
            m_usage_restart
            return 3
        fi

        l_object_name="$1"
    fi


    #5. Ejecutando el comando
    m_kc_logs "$l_ns" "$l_filter_label" "$l_filter_field" "$l_object_name" "$l_path_dir" "$l_flag_show_timestamp" "$l_flag_save_json" \
              "$l_flag_save_all_main" "$l_flag_save_all_init" "$l_flag_save_all_ephemeral" "$l_file_sufix_nodename" \
              "$l_file_sufix_containername" "$l_file_sufix_time"
    return 0

}



# -------------------------------------------------------------------------------------
# Subcomand Controller> restart
# -------------------------------------------------------------------------------------

m_usage_restart() {

    local l_scmd_id='restart'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE] [-l LABEL_SELECTORS] [-f FIELD_SELECTORS] [-t RESOURCE] %b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [-n NAMESPACE] [-t RESOURCE] OBJECT_NAME%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones generales son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones para filtrar el Deployment/DaemonSet/StatufulSet:\n'
    printf '%b  > %b-n%b NAMESPACE%b Nombre del namespace. Si no se especifica se usara el actual.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-l%b LABEL_SELECTORS%b Fitro de objetos en servidor basado en las label del objeto.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'label1=value1,label2=value2'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-f%b FIELD_SELECTORS%b Fitro de objetos en servidor basado en las nombre de algunos field especiales del objeto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Ejemplos: 'field1=value1,field2==value1,field2!=value'.%b\n" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-t%b RESOURCE%b Tipo de controller long-lived. Su valor puede ser "deployment", "daemonset" o "statufulset".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf "%b    Si no se especifica su valor por defecto es 'deployment'.%b\n" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones usados para almacenar el log de los pods:\n'
    printf '%b  > %b-d%b FOLDER_PATH%b Ruta del folder donde se almacenara los archivos logs.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_yellow1" \
           "$g_color_gray1" "$g_color_reset"

    printf '%b  > %b-T%b Flag que muestra el timestamps en cada linea del archivo log. Por defecto no se muestra.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '%b  > %b-j%b Flag para almacenar el descriptor json del pod. Por defecto se almacena el descriptor.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-m%b Flag para almacenar los logs de todos los contenedor principales del pod. Por defecto solo se almacena el contenedor por defecto.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-i%b Flag para almacenar los logs de todos los contenedores de inicialización del pod. Por defecto no se almacena logs de estos contenedores.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-e%b Flag para almacenar los logs de todos los contenedores efimeros del pod. Por defecto no se almacena logs de estos contenedores.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-x%b Flag para usar, en el sufijo del nombre del log, el nombre nodo. Por defecto no se adiciona al nombre de del log.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-y%b Flag para NO usar, en el sufijo del nombre del log, el nombre contenedor. Por defecto se adiciona al nombre del contenedor.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-z%b Flag para usar, en el sufijo del nombre del log, una marca de tiempo "yyyyMMdd_HHMM". Por defecto no se adiciona al nombre de del log.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas argumentos puede ser:\n'
    printf '%b  > %bOBJECT_NAME%b Nombre del objeto de recurso de tipo "-t" (deployment, daemonset, statefulset).%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_kc_restart() {

    #1. Argumentos
    local p_ns="$1"
    local p_filter_label="$2"
    local p_filter_field="$3"

    # Valores:
    # > 0 - Si es un deployment
    # > 1 - Si es un daemonset
    # > 2 - Si es un statefulset
    local -i p_resource_type=0
    if [ ! -z "$4" ]; then
        p_resource_type="$4"
    fi

    local p_object_name="$5"

    local p_path_dir="$6"

    local -i p_flag_show_timestamp=1
    if [ "$7" = "0" ]; then
        p_flag_show_timestamp=0
    fi

    local -i p_flag_save_json=1
    if [ "$8" = "0" ]; then
        p_flag_save_json=0
    fi

    local -i p_flag_save_all_main=1
    if [ "$9" = "0" ]; then
        p_flag_save_all_main=0
    fi

    local -i p_flag_save_all_init=1
    if [ "${10}" = "0" ]; then
        p_flag_save_all_init=0
    fi

    local -i p_flag_save_all_ephemeral=1
    if [ "${11}" = "0" ]; then
        p_flag_save_all_ephemeral=0
    fi

    local -i p_file_sufix_nodename=1
    if [ "${12}" = "0" ]; then
        p_file_sufix_nodename=0
    fi

    local -i p_file_sufix_containername=0
    if [ "${13}" != "0" ]; then
        p_file_sufix_containername=1
    fi

    local -i p_file_sufix_time=1
    if [ "${14}" = "0" ]; then
        p_file_sufix_time=0
    fi


    #2. Procesar los argumentos y modificar las variables segun ello
    local la_args=("get")

    # Filtro de Namespace
    if [ ! -z "$p_ns" ]; then
        la_args+=("-n" "$p_ns")
    fi

    # Tipo de recurso
    local l_resource=''
    if [ $p_resource_type -eq 0 ]; then
        l_resource="Deployment"
        la_args+=("deployment")
    elif [ $p_resource_type -eq 1 ]; then
        l_resource="Daemonset"
        la_args+=("daemonset")
    else
        l_resource="Statefulset"
        la_args+=("statefulset")
    fi


    # Filtros
    if [ -z "$p_object_name" ]; then

        # Filtro de Labels
        if [ ! -z "$p_filter_label" ]; then
            la_args+=("-l" "$p_filter_label")
        fi

        # Filtro de Filed Selectors
        if [ ! -z "$p_filter_field" ]; then
            la_args+=("--field-selector" "$p_filter_field")
        fi

    else

        la_args+=("$p_object_name")

    fi

    la_args+=("-o" "json")
    #echo "Argumentos:" "${la_args[@]}"


    #3. Filtro jq para obtener el listado de controladores (ordenados por su controlador)
    local l_filter

    if [ ! -z "$p_object_name" ]; then
        l_filter='{ name: .metadata.name, ns: .metadata.namespace, owner: (.metadata.ownerReferences[0]? | if . == null then "" else "\(.kind)/\(.name)" end) } | "\(.name)|\(.ns)|\(.owner)"'
    else
        l_filter='[.items[] | { name: .metadata.name, ns: .metadata.namespace, owner: (.metadata.ownerReferences[0]? | if . == null then "" else "\(.kind)/\(.name)" end) }] | sort_by(.owner, .name) | .[] | "\(.name)|\(.ns)|\(.owner)"'
    fi


    #4. Obtener listado de controladroes (ordenados por el nombre de su controlador)
    local -i l_status=0
    local l_data=''

    l_data=$(${g_kubectl_cmd} "${la_args[@]}" | jq -r "$l_filter")
    l_status=$?

    if [ $l_status -ne 0 ]; then

        printf "Ocurrio un error a listar los %s.\n" "$l_resource"
        if [ ! -z "$l_data" ]; then
            printf "Detail: %s\n" "$l_data"
        fi

        return 1
    fi

    if [ -z "$l_data" ]; then
        printf "No se encuentra %s disponibles.\n" "$l_resource"
        return 0
    fi


    #5. Si solo se analiza a un controlador
    local l_rs_name
    local l_rs_ns
    local l_rs_owner

    local l_data_json
    local l_tmp
    local l_jq_query1
    l_jq_query1='reduce (.spec.selector.matchLabels | to_entries[]) as $i (""; . + (if . != "" then "," else "" end) + "\($i.key)=\($i.value)")'

    if [ ! -z "$p_object_name" ]; then

        # Informnacion generar del controllador
        IFS='|' read -r l_rs_name l_rs_ns l_rs_owner <<< "$l_data"

        printf '%s name        : %b%s%b\n' "$l_resource" "$g_color_blue1" "$l_rs_name" "$g_color_reset"
        if [ ! -z "$l_rs_owner" ]; then
            printf '%s controller  : %b%s%b\n' "$l_resource" "$g_color_gray1" "$l_rs_owner" "$g_color_reset"
        #else
        #    printf '%s controller  : %b%s%b\n' "$l_resource" "$g_color_gray1" "none" "$g_color_reset"
        fi

        # Obtener el descriptor del controlador
        #echo "$l_rs_ns $l_resource $l_rs_name"
        l_data_json=$(${g_kubectl_cmd} get -n "$l_rs_ns" "$l_resource" "$l_rs_name" -o json)
        l_status=$?

        if [ $l_status -ne 0 ] || [ -z "$l_data_json" ] || [ "$l_data_json" = 'null' ]; then
            printf 'No se puedo obtener el descriptor del %s.\n' "$l_resource"
            return 3
        fi


        # Obtener el selector de pods
        l_tmp=$(echo "$l_data_json" | jq -r "$l_jq_query1")
        l_status=$?

        if [ $l_status -ne 0 ] || [ -z "$l_tmp" ] || [ "$l_tmp" = 'null' ]; then
            printf 'El %s no tiene definido un selector de pods.\n' "$l_resource"
            return 3
        fi

        printf '%s pod selector: "%b%s%b"\n' "$l_resource" "$g_color_gray1" "$l_tmp" "$g_color_reset"

        printf '\n'

        # Obtener los pod segun este selector
        m_kc_logs "$l_rs_ns" "$l_tmp" "" "" "$p_path_dir" "$p_flag_show_timestamp" "$p_flag_save_json" "$p_flag_save_all_main" \
                       "$p_flag_save_all_init" "$p_flag_save_all_ephemeral" "$p_file_sufix_nodename" "$p_file_sufix_containername" \
                       "$p_file_sufix_time"

        printf '\n'

        # Realizar un restart de controlador
        printf 'Restart el %s: %b%s rollout restart%b -n "%s" "%s/%s"%b\n' "$l_resource" "$g_color_green1" "$g_kubectl_cmd" \
               "$g_color_gray1" "$l_rs_ns" "$l_resource" "$l_rs_name"  "$g_color_reset"
        ${g_kubectl_cmd} rollout restart -n "$l_rs_ns" "${l_resource}/${l_rs_name}"

        printf '\n'

        return 0

    fi

    #6. Si se analiza a un conjuntos de controladores
    local l_n
    l_n=$(echo "$l_data" | wc -l)
    printf '%s(s) disponibles : %b%s%b\n' "$l_resource" "$g_color_gray1" "$l_n" "$g_color_reset"

    if [ ! -z "$l_n" ] && [ "$l_n" -gt 0 ]; then

        local l_in_option
        printf '¿Desea reiniciar %b%s%b %ss%b? %bNo [%bn%b], Yes [y]%b' "$g_color_cyan1" "$l_n" "$g_color_gray1" \
               "$l_resource" "$g_color_reset" "$g_color_gray1" "$g_color_cyan1" "$g_color_gray1" "$g_color_reset"
        read -rei "n" -p ": " l_in_option

        if [ "$l_in_option" != "y" ] && [ "$l_in_option" != "Y" ]; then
            return 0
        fi

    fi

    printf '\n'

    #5. Procesar los pod
    local -i l_i=0

    # Incluir un contador y un resumen final
    while IFS='|' read -r l_rs_name l_rs_ns l_rs_owner; do

        ((l_i++))
        if [ -z "$l_rs_name" ]; then
            continue
        fi

        print_line '─' $g_max_length_line  "$g_color_gray1"
        printf '(%b%s%b/%b%s%b) %s "%b%s%b"\n' "$g_color_gray1" "$l_i" "$g_color_reset" \
               "$g_color_gray1" "$l_n" "$g_color_reset" "$l_resource" "$g_color_gray1" "$l_rs_name" "$g_color_reset"
        print_line '─' $g_max_length_line  "$g_color_gray1"

        printf 'Name        : %b%s%b\n' "$g_color_blue1" "$l_rs_name" "$g_color_reset"
        if [ ! -z "$l_rs_owner" ]; then
            printf 'Controller  : %b%s%b\n' "$g_color_gray1" "$l_rs_owner" "$g_color_reset"
        #else
        #    printf 'Controller  : %b%s%b\n' "$g_color_gray1" "none" "$g_color_reset"
        fi

        # Obtener el descriptor del controlador
        l_data_json=$(${g_kubectl_cmd} get -n "$l_rs_ns" "$l_resource" "$l_rs_name" -o json)
        l_status=$?

        if [ $l_status -ne 0 ] || [ -z "$l_data_json" ] || [ "$l_data_json" = 'null' ]; then
            printf 'No se puedo obtener el descriptor del %s.\n' "$l_resource"
            continue
        fi

        # Obtener el selector de pods
        l_tmp=$(echo "$l_data_json" | jq -r "$l_jq_query1")
        l_status=$?

        if [ $l_status -ne 0 ] || [ -z "$l_tmp" ] || [ "$l_tmp" = 'null' ]; then
            printf 'El %s no tiene definido un selector de pods.\n' "$l_resource"
            continue
        fi

        printf 'Pod selector: "%b%s%b"\n' "$g_color_gray1" "$l_tmp" "$g_color_reset"

        printf '\n'

        # Obtener los pod segun este selector
        m_kc_logs "$l_rs_ns" "$l_tmp" "" "" "$p_path_dir" "$p_flag_show_timestamp" "$p_flag_save_json" "$p_flag_save_all_main" \
                       "$p_flag_save_all_init" "$p_flag_save_all_ephemeral" "$p_file_sufix_nodename" "$p_file_sufix_containername" \
                       "$p_file_sufix_time"

        printf '\n'

        # Realizar un restart de controlador
        printf 'Restart el %s: %b%s rollout restart%b -n "%s" "%s/%s"%b\n' "$l_resource" "$g_color_green1" "$g_kubectl_cmd" \
               "$g_color_gray1" "$l_rs_ns" "$l_resource" "$l_rs_name"  "$g_color_reset"
        "$g_kubectl_cmd" rollout restart -n "$l_rs_ns" "${l_resource}/${l_rs_name}"

        printf '\n'

    done <<< "$l_data"

    return 0

}



m_controller_restart() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_ns
    local l_filter_label
    local l_filter_field

    # Valores:
    # > 0 - Si es un deployment
    # > 1 - Si es un daemonset
    # > 2 - Si es un statefulset
    local -i l_resource_type=0

    local l_path_dir=""

    local -i l_flag_show_timestamp=1
    local -i l_flag_save_json=1
    local -i l_flag_save_all_main=1
    local -i l_flag_save_all_init=1
    local -i l_flag_save_all_ephemeral=1
    local -i l_file_sufix_nodename=1
    local -i l_file_sufix_containername=0
    local -i l_file_sufix_time=1

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_restart
                return 0
                ;;


            -n)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-n" "$g_color_reset"
                    return 3
                fi

                l_ns="$2"
                shift 2
                ;;


            -l)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_label="$2"
                shift 2
                ;;


            -f)
                if [ -z "$2" ]; then
                    printf 'La opción "%b%s%b" requere un valor especifico.\n' "$g_color_gray1" "-l" "$g_color_reset"
                    return 3
                fi

                l_filter_field="$2"
                shift 2
                ;;


            -t)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no puede ser vacio.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-t" "$g_color_reset"
                    m_usage_restart
                    return 3
                fi

                if [ "$2" == "deployment" ]; then
                    l_resource_type=0
                elif [ "$2" == "daemonset" ]; then
                    l_resource_type=1
                elif [ "$2" == "statefulset" ]; then
                    l_resource_type=2
                else
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es "%b%s%b". Este solo puede ser "deployment", "daemonset" o "statefulset".\n' \
                           "$g_color_red1" "$g_color_reset" "$g_color_gray1" "-t" "$g_color_reset" "$g_color_gray1" "$2" \
                           "$g_color_reset"
                    m_usage_restart
                    return 3
                fi

                shift 2
                ;;

            -d)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no puede ser vacio.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset"
                    m_usage_restart
                    return 3
                fi

                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido "%b%s%b". Debe ser un folder valido.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    return 3
                fi

                l_path_dir="$2"
                shift 2
                ;;


            -T)
                l_flag_show_timestamp=0
                shift 1
                ;;

            -j)
                l_flag_save_json=0
                shift 1
                ;;

            -m)
                l_flag_save_all_main=0
                shift 1
                ;;

            -i)
                l_flag_save_all_init=0
                shift 1
                ;;

            -e)
                l_flag_save_all_ephemeral=0
                shift 1
                ;;


            -x)
                l_file_sufix_nodename=0
                shift 1
                ;;

            -y)
                l_file_sufix_containername=1
                shift 1
                ;;

            -z)
                l_file_sufix_time=0
                shift 1
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_restart
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes
    local l_object_name=""

    if [ ! -z "$1" ]; then
        if [ ! -z "$l_filter_label" ] || [ ! -z "$l_filter_field" ]; then
            printf '[%bERROR%b] Opción "%b%%%b" y/o "%b%s%b" no puede usarse cuando se especifica el argumento "%b%s%b".\n\n' \
                   "$g_color_red1" "$g_color_reset" "$g_color_gray1" "-l" "$g_color_reset" \
                   "$g_color_gray1" "-f" "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"
            m_usage_restart
            return 3
        fi

        l_object_name="$1"
    fi

    #5. Ejecutando el comando
    m_kc_restart "$l_ns" "$l_filter_label" "$l_filter_field" "$l_resource_type" "$l_object_name" "$l_path_dir" "$l_flag_show_timestamp" \
              "$l_flag_save_json" "$l_flag_save_all_main" "$l_flag_save_all_init" "$l_flag_save_all_ephemeral" "$l_file_sufix_nodename" \
              "$l_file_sufix_containername" "$l_file_sufix_time"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> get
# -------------------------------------------------------------------------------------

m_usage_get() {

    local l_scmd_id='get'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s.%b\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    # Obtener los alias del comando
    local l_alias_list
    l_alias_list=$(m_get_alias_by_subcmd_id "gA_subcmd_alias" "$l_scmd_id")

    # Mostrar el alias:
    if [ ! -z "$l_alias_list" ]; then
        printf '%bAlias: %b%b\n' "$g_color_gray1" "$g_color_reset" "$l_alias_list"
    fi


    printf '\nUsage:\n'
    printf '  %b%s %s%b -h | --help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b [options]%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-u%b Usa un cache de la consulta anterior y existente. No vuelve a realizar la consulta (no hace caso a los filtros de busqueda).%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s%b\n' "$g_color_gray1" "Por defecto, siempre siempre realiza la consulta y lo almacena en un archivo como cache." "$g_color_reset"
    printf '%b  > %b-p%b Preserva el cache de la consulta despues de presentar/usar la consulta.%b\n' "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
    printf '    %b%s%b\n' "$g_color_gray1" "Por defecto, el resultado de la consulta que esta en un archivo como cache, siempre se elimina despues de usarlo." \
           "$g_color_reset"

    printf '\nEl argumento principal es el nombre del subcomando %bSUBCOMMAND%b. Los cuales puede ser:\n' "$g_color_green1" "$g_color_reset"
    m_get_subcmd_infos "gA_get_subcmd_ids" "gA_get_subcmd_alias"
    printf '\n'

}



m_controller_get() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_get
                return 0
                ;;


            -u)
                _g_use_cache_before=0
                shift 1
                ;;


            -p)
                _g_preserve_cache_after=0
                shift 1
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_get
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Procesar el 1er argumentos (nombre del subcomando o alias)
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Se debe especificarse un subcomando.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_global
        return 3
    fi

    # Identificar si es un alias
    local l_scmd_id="${gA_get_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_get_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_get
        return 3
    fi

    shift

    #4. Nombre del sufijo unico del nombre del archivo temporal unico que almacena la data de los subcomando get.
    if [ -z "$g_tmpfile_suffix" ]; then
        g_tmpfile_suffix=$(m_get_tmpfile_suffix)
    fi

    #5. Ejecutando el controlador principal del subcomando
    "m_controller_get_${l_scmd_id}" "$@"
    return 0

}





# -------------------------------------------------------------------------------------
# Main code > Utilities
# -------------------------------------------------------------------------------------

m_get_exported_functions() {

    # Recorrer la lista de parametros identificados ....
    local l_infos=""
    local l_id

    for l_id in "${ga_exported_functions[@]}"; do

        if [ -z "$l_infos" ]; then
            printf -v l_infos "'%b%s%b'" "$g_color_yellow1" "$l_id" "$g_color_reset"
        else
            printf -v l_infos "%b, '%b%s%b'" "$l_infos" "$g_color_yellow1" "$l_id" "$g_color_reset"
        fi

    done

    echo "$l_infos"

}

m_is_function_exported() {

    local p_func_name="$1"

    if [ -z "$p_func_name" ]; then
        return 1
    fi

    local l_found=1
    local l_item

    for l_item in "${ga_exported_functions[@]}"; do

        if [[ "$l_item" == "$p_func_name" ]]; then
            l_found=0
            break
        fi

    done

    return $l_found

}

m_usage_global() {

    local l_infos=""
    l_infos=$(m_get_exported_functions)

    printf 'Usage:\n'
    printf '  %b%s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s%b -o%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '  %b%s%b -i FUNC_NAME [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    fi

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '%b  > %b-o%b Obliga usar solo el comando "oc". No usa el comando "kubectl".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b    Si define la variable de entorno %bUSE_OC=0%b tambien se usara el comando "oc". Este tiene menor prioridad que la opción "-o"%b\n' \
           "$g_color_gray1" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '%b  > %b-i FUNC_NAME%b Especifica el nombre de la funcion interna del script a ejecutar (uso interno y/o debugging).%b\n' \
               "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
        printf '    %bFUNC_NAME puede ser:%b %b\n' "$g_color_gray1" "$g_color_reset" "$l_infos"
    fi

    printf '\nEl argumento principal es el nombre del subcomando %bSUBCOMMAND%b. Los cuales puede ser:\n' "$g_color_green1" "$g_color_reset"
    m_get_subcmd_infos "gA_subcmd_ids" "gA_subcmd_alias"
    printf '\n'

}



# -------------------------------------------------------------------------------------
# Main code > Main Function
# -------------------------------------------------------------------------------------

# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
main() {

    #1. Validaciones previas

    # Validar comando requeridos
    if ! command -v fzf >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "fzf" "$g_color_reset"
        return 1
    fi

    if ! command -v jq 2> /dev/null 1>&2; then
       printf 'El comando "%b%s%b" no esta instalado.\n' "$g_color_gray1" "jq" "$g_color_reset"
       return 2
    fi


    #2. Procesar las opciones globales
    local l_func_name=""
    local -i l_use_only_oc=1

    if [ "$USE_OC" = "0" ]; then
        l_use_only_oc=0
    fi


    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help|help)
                m_usage_global
                return 0
                ;;


            -o)
                l_use_only_oc=0
                shift 1
                ;;

            -u)
                _g_use_cache_before=0
                shift 1
                ;;


            -p)
                _g_preserve_cache_after=0
                shift 1
                ;;

            -i)
                m_is_function_exported "$2"
                local l_found=$?
                if [ "$l_found" -ne 0 ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es function exportada valida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-i" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_global
                    return 3
                fi

                l_func_name="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_global
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    if [ $l_use_only_oc -eq 0 ]; then

        g_kubectl_cmd="oc"

        if ! command -v oc 2> /dev/null 1>&2; then
            printf 'El comando "%b%s%b" no esta instalado.\n' "$g_color_gray1" "oc" "$g_color_reset"
            return 2
        fi

    else

        g_kubectl_cmd="kubectl"

        if ! command -v kubectl 2> /dev/null 1>&2; then
            printf 'El comando "%b%s%b" no esta instalado.\n' "$g_color_gray1" "kubectl" "$g_color_reset"
            return 2
        fi

    fi


    #3. Si es una funcion exportada, invocarlo
    if [ ! -z "$l_func_name" ]; then
        "$l_func_name" "$@"
        return 0
    fi


    #4. Procesar el 1er argumentos (nombre del subcomando o alias)
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Se debe especificarse un subcomando.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_global
        return 3
    fi

    # Identificar si es un alias
    local l_scmd_id="${gA_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_global
        return 3
    fi

    shift

    #5. Ejecutando el controlador principal del subcomando
    "m_controller_${l_scmd_id}" "$@"
    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
