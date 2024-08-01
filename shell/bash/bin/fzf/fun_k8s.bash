#!/bin/bash


#Colores principales usados para presentar en FZF
g_color_reset="\x1b[0m"
g_color_gray1="\x1b[90m"
g_color_green1="\x1b[32m"
g_color_cyan1="\x1b[36m"

#Uso interno: compartir data entre funciones para evitar pasarselos por argumentos
_g_data_object_json=""

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

    printf 'Commnad   : "%bkubectl exec %s%b"\n\n' "$l_color_2" "${l_options}" "$g_color_reset"

    #2. Ejecutar el comando
    kubectl exec ${l_options}

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

    #1. Obtener informacion de los contenedores del pod que tiene puertos (y luego limpiar esta data temporal)
    
    #Obtener el arreglo de los contenedores habilitados ({ spec: .spec.containers[x], status: .status.containerStatuses[x] } donde x esta vinculado al mismo contenedor).
    local l_jq_query='[.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | { containers: .spec.containers, statuses: .status.containerStatuses } | { container: .containers[], statuses: .statuses } | .container.name as $name | { spec: .container, status: (.statuses[] | select(.name == $name)) } | select(.status.started) ]'

    local l_data_object_json
    l_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$5" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data de los contenedores del pod.\n"
        return 1
    fi

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

    #1. Obtener informacion de los contenedores del pod que tiene puertos (y luego limpiar esta data temporal)
    
    #Obtener el objeto del contenedores si esta iniciado ({ spec: .spec.containers[x], status: .status.containerStatuses[x] } donde x esta vinculado al mismo contenedor).
    #Validar si existe y esta en ejecución
    local l_jq_query='.items[] | select (.metadata.name == $podName and .metadata.namespace == $objNS) | { containers: .spec.containers, statuses: .status.containerStatuses } | { container: .containers[], statuses: .statuses } | .container.name as $name | { spec: .container, status: (.statuses[] | select(.name == $name)) } | select(.status.started and .spec.name == $conName)'

    local l_data_object_json
    l_data_object_json=$(jq --arg podName "$1" --arg conName "$3" --arg objNS "$2" "$l_jq_query" "$6" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data de los contenedores del pod.\n"
        return 1
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

    printf 'Commnad   : "%bkubectl logs %s%b"\n\n' "$l_color_2" "${l_options}" "$g_color_reset"

    #2. Ejecutar el comando
    kubectl logs ${l_options}

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
    if [ -z "$3"]; then
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

    #1. Obtener informacion de los contenedores del pod que tiene puertos (y luego limpiar esta data temporal)
    
    #Obtener el arrgelo de los contenedores habilitados
    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | .spec.template.spec.containers'

    #local l_data_object_json
    _g_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$5" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data de los contenedores del deployment.\n"
        return 1
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

    #1. Obtener informacion de los contenedores del pod que tiene puertos (y luego limpiar esta data temporal)
    
    #Obtener el arrgelo de los contenedores habilitados
    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | .spec.containers'

    #local l_data_object_json
    _g_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$5" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data de los contenedores del pod.\n"
        return 1
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
#  3 > El nombre namespace (si el objeto esta vinculado a un namespace)
show_object_yaml() {

    local l_jq_query='.items[] | select (.metadata.name == $objName'
    if [ -z "$3" ]; then
        l_jq_query="${l_jq_query})"
    else
        l_jq_query="${l_jq_query} and .metadata.namespace == \$objNS)"
    fi

    local l_data_yaml=""
    l_data_yaml=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null | yq -p json -o yaml 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
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
    l_jq_query='[ '"${l_root}"'spec.containers[] | { name: .name, env: .env[]? } | { CONTAINER: .name, VARIABLE: .env.name, TYPE: (if .env.value? != null then "VALUE" elif .env.valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .env.valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" else "UNKNOWN" end), VALUE: (if .env.value? != null then .env.value? elif .env.valueFrom?.fieldRef != null then .env.valueFrom?.fieldRef.fieldPath elif .env.valueFrom?.secretKeyRef != null then "[SecretName: \(.env.valueFrom?.secretKeyRef.name)] \(.env.valueFrom?.secretKeyRef.key)" else "..." end) }]'
    
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

    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
    #local l_data_object_json=""
    local l_data=""

    _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
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

    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
    #local l_data_object_json=""
    local l_data=""

    _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
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

    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
    #local l_data_object_json=""
    local l_data=""

    _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
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

    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
    #local l_data_object_json=""
    local l_data=""

    _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
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


    printf 'Command   : "%bkubectl port-forward %s%b"\n\n' "$l_color_2" "$l_options" "$g_color_reset"

    #2. Ejecutar el comando
    kubectl port-forward ${l_options}
    return 0


}


#Parametros (argumentos y opciones) de entrada:
#  1 > El nombre del pod
#  2 > El nombre namespace
#  3 > La ruta del archivo de datos
port_forward_pod() {

    #1. Obtener informacion de los contenedores del pod que tiene puertos (y luego limpiar esta data temporal)
    
    #Obtener el arrgelo de los contenedores habilitados
    local l_jq_query='[.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | .spec.containers[] | select((.ports//[]) | any(.protocol == "TCP" and .containerPort > 0))]'

    local l_data_object_json
    l_data_object_json=$(jq --arg objName "$1" --arg objNS "$2" "$l_jq_query" "$3" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf "Error al obtener la data de los contenedores del pod.\n"
        return 1
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
#  1 > La ruta del archivo de datos
#  2 > El nombre deployment
#  3 > El nombre namespace
show_dply_revision1() {

    #1. Información basica del Deployment
    #¿Why show a TAB in the beginning?
    printf '\n'
    printf '%bDeployment         :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"
    printf '%bNamespace          :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$3"
    
    #2. Obtener información del los replicaset asociado a las revisiones dle deployment
    local l_data_json=""
    l_data_json=$(kubectl get replicaset -n ${3} -o json 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf '%b\tNo se puede conectarse con el cluster de Kubernates, revise la conexión.%b\n' "$g_color_gray1" "$g_color_reset"
        return 1
    fi

    local l_jq_query='[.items[] | select(any(.metadata.ownerReferences[]; .kind == "Deployment" and .name == $objName)) ] | sort_by(.metadata.annotations."deployment.kubernetes.io/revision") | reverse'
    _g_data_object_json=$(echo "$l_data_json" | jq --arg objName "$2" "$l_jq_query" 2> /dev/null)
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

    #1. Información basica del Deployment
    #¿Why show a TAB in the beginning?
    printf '\n'
    printf '%bReplicaSet         :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$2"
    printf '%bNamespace          :%b %s\n' "$g_color_cyan1" "$g_color_reset" "$3"
   
    #2. Obtener informacion del replicaset: ¿tiene como owner un deployment?  
    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS) | { owner: (.metadata.ownerReferences[]? | select(.kind == "Deployment") | .name), revision: .metadata.annotations."deployment.kubernetes.io/revision", creationTime: .metadata.creationTimestamp } | "\(.owner)|\(.revision)|\(.creationTime)"'
    local l_data=""

    l_data=$(jq -r --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf '%b\tError al obtener información del replicaset.%b\n' "$g_color_gray1" "$g_color_reset"
        return 1
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
    local l_jq_query='[.items[] | select(any(.metadata.ownerReferences[]; .kind == "Deployment" and .name == $objName)) ] | sort_by(.metadata.annotations."deployment.kubernetes.io/revision") | reverse'
    _g_data_object_json=$(jq --arg objName "$l_deployment_name" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        printf '%b\tError al obtener la data de las revisiones.%b\n' "$g_color_gray1" "$g_color_reset"
        return 4
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
show_replicasets_table() {

    #Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_jq_query='[.items[] | '

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
show_pods_table() {

    #Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_jq_query='[.items[] | '

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
show_containers_table() {

    #Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_jq_query='[.items[] | '

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
show_deployment_table() {

    #Generar el reporte deseado con la data ingresada
    local l_jq_query='[.items[] | (reduce (.spec.selector.matchLabels | to_entries[]) as $i (""; . + (if . != "" then "," else "" end) + "\($i.key)=\($i.value)")) as $labels | { name: .metadata.name, namespace: .metadata.namespace, revision: .metadata.annotations."deployment.kubernetes.io/revision", desiredReplicas: .spec.replicas, currentReplicas: .status.replicas, readyReplicas: .status.readyReplicas, availableReplicas: .status.availableReplicas, updatedReplicas: .status.updatedReplicas, owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), lastTransitionTime: (.status.conditions[] | select(.type=="Progressing") | .lastTransitionTime) } | { NAME: .name, NAMESPACE: .namespace, DESIRED: .desiredReplicas, READY: "\(.readyReplicas)/\(.currentReplicas)", "UP-TO-DATE": .updatedReplicas, AVAILABLE: .availableReplicas, INITIAL: .lastTransitionTime, REVISION: .revision, "SELECTOR-MATCH-LABELS": $labels, OWNERS: (if .owners == "" then "-" else .owners end)}]'

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



#Los parametros debe ser la funcion y los parametros
"$@"

