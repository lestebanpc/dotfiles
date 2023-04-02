#!/bin/bash

. ~/.files/terminal/linux/functions/func_utility.bash

#Colores principales usados para presentar en FZF
g_color_opaque="\x1b[90m"
g_color_reset="\x1b[0m"
g_color_title="\x1b[32m"
g_color_subtitle="\x1b[36m"

# > Argumentos:
#   1> Tipo de objeto GIT
#      1 - Un commit: hash
#      2 - Branch (Local y Remoto): name
#      3 - Remote (Alias del repositorio remoto): name
#      4 - File: name
#      5 - Tag: name
#   2> Nombre del objeto GIT
_get_url_github() {

    #Argumentos
    local p_object_type="$1"
    local p_object_name="$2"

    #Obtener el nombre de la rama
    local l_current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ $l_current_branch = "HEAD" ]; then
        l_current_branch=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
    fi

    #Obtener la ruta del objeto y el alias del repositorio remoto
    local l_path
    local l_remote
    local l_tmp
    
    case "$p_object_type" in
        1)
            #Usando el codigo hash ingresado
            l_remote=$(git config branch."${l_current_branch}".remote || echo 'origin')
            l_path="/commit/$p_object_name"
            ;;
        2)
            #usando el nombre de la rama ingresado
            l_remote=$(git config branch."${p_object_name}".remote || echo 'origin')
            l_tmp=${p_object_name#$l_remote/}
            l_path="/tree/$l_tmp"
            ;;
        3)
            #Usando el alias de repositorio remoto
            l_remote=$p_object_name
            l_path="/tree/$l_current_branch"
            ;;
        4) 
            l_remote=$(git config branch."${l_current_branch}".remote || echo 'origin')
            l_path="/blob/$l_current_branch/$(git rev-parse --show-prefix)$p_object_name"
            ;;
        5) 
            l_remote=$(git config branch."${l_current_branch}".remote || echo 'origin')
            l_path="/releases/tag/$p_object_name"
            ;;
        *)
            return 1
            ;;
    esac
    
    local l_remote_url=$(git remote get-url "$l_remote" 2> /dev/null || echo "$l_remote")

    local l_url
    if [[ $remote_url =~ ^http ]]; then
        #Si usa HTTPS
        l_url=${remote_url%.git}
    else
        #Si usa SSH
        l_url=${l_remote_url%.git}

        if [[ $l_remote_url =~ ^git@ ]]; then
            #Si no usa SSH alias
            l_url=${l_url#git@}
        else
            #Si usa un SSH alias
            l_url=${l_url#*:}
            #TODO obtener el host del alias
            #ssh -G ghub-lucianoepc | awk '$1 == "hostname" { print $2 }'
            l_url="github.com/${l_url}"
        fi
        l_url="https://${l_url/://}"
    fi
    echo "$l_url$l_path"
    return 0

}


git_open_url() {

    #1. Argumentos
    local p_object_type=$1
    local p_object_info="$2"

    #2. Obtener el nombre del objeto
    local l_object_name="$p_object_info"

    if [ $p_object_type -eq 1 ]; then
        #Si el objeto es un commit, obtener el hash del valor
        l_object_name=$(echo "$p_object_info" | grep -o "[a-f0-9]\{7,\}")
    elif [ $p_object_type -eq 2 ]; then
        #Si el objeto es un rama obtener la ...
        l_object_name=$(echo "$p_object_info" | sed 's/^[* ]*//' | cut -d' ' -f1)
    fi

    #3. Obtener la ruta del objeto
    local l_path=$(_get_url_github $p_object_type "$l_object_name")

    echo "$l_path"
    if [ -z "$l_path" ]; then
        return 1
    fi

    #2. Determinar el SO
    get_os_type
    local l_os_type=$?

    if [ $l_os_type -eq 1 ]; then
        explorer.exe "$l_path"
    elif [ $l_os_type -eq 21 ]; then
        open "$l_path"
    else
        xdg-open "$l_path"
    fi
        
}

_branches() {
    git branch "$@" --sort=-committerdate --sort=-HEAD \
        --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=always | column -ts$'\t'
}

_refs() {
    git for-each-ref --sort=-creatordate --sort=-HEAD --color=always \
        --format=$'%(refname) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' |
        eval "$1" |
        sed 's#^refs/remotes/#\x1b[95mremote-branch\t\x1b[33m#; s#^refs/heads/#\x1b[92mbranch\t\x1b[33m#; s#^refs/tags/#\x1b[96mtag\t\x1b[33m#; s#refs/stash#\x1b[91mstash\t\x1b[33mrefs/stash#' |
        column -ts$'\t'
}

list_objects() {

    case "$1" in
        branches)
            echo $'CTRL-o (Open in browser), ALT-a (Show all branches)\n'
            _branches
            ;;
        all-branches)
            echo $'CTRL-o (Open in browser)\n'
            _branches -a
            ;;
        refs)
            echo $'CTRL-o (Open in browser), CTRL-s (Git show branch), CTRL-d (Git diff branch), ALT-a (Show all refs)\n'
            _refs 'grep -v ^refs/remotes'
            ;;
        all-refs)
            echo $'CTRL-o (Open in browser), CTRL-s (Git show branch), CTRL-d (Git diff branch)\n'
            _refs 'cat'
            ;;
        nobeep)
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}


#Uso interno: compartir data entre funciones para evitar pasarselos por argumentos
_g_data_object_json=""

#Parametros (argumentos y opciones):
#  1 > 0 si follow los logs, caso contrario no lo hace.
#  2 > 0 para mostrar el timestamp.
#  3 > n de la opcion '--tail=n' (mostrar las ultimas n lineas mostrados de los logs).
#      Si es <=0, no se especifica
#  4 > Nombre del pod
#  . > Namespace  (si se especifica inicia con "-n=")
#  . > Contenedor (si se especifica inicia con "-c=")
#  . > Ruta de los archivo de datos (si se ingresa se debe eliminarlo)
show_log() {

    #1. Calcular los argumentos del comando y mostrar el mensaje de bienvenida
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    printf 'Pod       : "%b%s%b"\n' "$l_color_1" "$4" "$g_color_reset"
    local l_options="$4"
    local l_data_file

    #Follow el log
    if [ $1 -eq 0 ]; then
        l_options="-f ${l_options}"
    fi

    #Mostrar el timestamp
    if [ $2 -eq 0 ]; then
        l_options="--timestamps ${l_options}"
    fi

    #Mostrar ultimas lineas de log
    if [ $3 -gt 0 ]; then
        l_options="--tail=$3 ${l_options}"
    fi

    #Namespace y/o Contenedor
    if [ ! -z "$5" ]; then

        if [[ "$5" == -n=* ]]; then
            printf 'Namespace : "%b%s%b"\n' "$l_color_2" "${5#-n=}" "$g_color_reset"
            l_options="${5} ${l_options}"

            if [ ! -z "$6" ] && [[ "$6" == -c=* ]]; then
                printf 'Container : "%b%s%b"\n' "$l_color_2" "${6#-c=}" "$g_color_reset"
                l_options="${6} ${l_options}"
                if [ ! -z "$7" ]; then
                    l_data_file="$7"
                fi
            fi

        elif [[ "$5" == -c=* ]]; then
            printf 'Container : "%b%s%b"\n' "$l_color_2" "$5" "$g_color_reset"
            l_options="${5} ${l_options}"
            if [ ! -z "$6" ]; then
                l_data_file="$6"
            fi
        fi
    fi

    printf 'Commnad   : "%bkubectl logs %s%b"\n' "$l_color_2" "${l_options}" "$g_color_reset"
    printf '\n'

    #2. Ejecutar el comando
    kubectl logs ${l_options}

    #3. Limpiar la data temporal (solo si se pasa este valor)
    if [ ! -z "$l_data_file" ]; then
        rm -f $l_data_file
    fi

    return 0

}

#Parametros (argumentos y opciones):
#  1 > La ruta del archivo de datos
#  2 > El nombre deployment
#  3 > El nombre namespace
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

    printf '\n%bInformacion general de Pod:%b\n' "$g_color_subtitle" "$g_color_reset"
    if [ $p_is_template -ne 0 ]; then
        l_jq_query='{ UID: .metadata.uid, Phase: .status.phase, PodIP: .status.podIP, Owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), StartTime: .status.startTime, NodeName: .spec.nodeName, DnsPolicy: .spec.dnsPolicy, RestartPolicy: .spec.restartPolicy, SchedulerName: .spec.schedulerName, Priority: .spec.priority, ServiceAccount: .spec.serviceAccount, ServiceAccountName: .spec.serviceAccountName, ImagePullSecrets: ([.spec.imagePullSecrets[]?.name] | join(", ")), ActiveDeadlineSeconds: .spec.activeDeadlineSeconds, TerminationGracePeriodSeconds:  .spec.terminationGracePeriodSeconds } | to_entries[] | "\t\(.key)\t: \(.value)"'
    else
        l_jq_query='{ NodeName: .spec.template.spec.nodeName, DnsPolicy: .spec.template.spec.dnsPolicy, RestartPolicy: .spec.template.spec.restartPolicy, SchedulerName: .spec.template.spec.schedulerName, Priority: .spec.template.spec.priority, ServiceAccount: .spec.template.spec.serviceAccount, ServiceAccountName: .spec.template.spec.serviceAccountName, ImagePullSecrets: ([.spec.template.spec.imagePullSecrets[]?.name] | join(", ")), ActiveDeadlineSeconds: .spec.template.spec.activeDeadlineSeconds, TerminationGracePeriodSeconds:  .spec.template.spec.terminationGracePeriodSeconds } | to_entries[] | "\t\(.key)\t: \(.value)"'
    fi
    echo "$_g_data_object_json" | jq -r "$l_jq_query"

    
    printf '\n%bContenedores principales:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.containers[] | { NAME: .name, PORTS: ( [ (.ports[]? | "\(.containerPort)/\(.protocol)") ] | join(", ")), IMAGE: .image } ]'
    echo "$_g_data_object_json" | jq "$l_jq_query" | jtbl -n



    printf '\n%bContenedores de inicialización:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.initContainers[]? | { NAME: .name, PORTS: ( [ .ports[]?.containerPort ] | join(", ")), IMAGE: .image } ]'
    
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi



    printf '\n%bVariables de contenedores principales:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.containers[] | { name: .name, env: .env[]? } | { CONTAINER: .name, VARIABLE: .env.name, TYPE: (if .env.value? != null then "VALUE" elif .env.valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .env.valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" else "UNKNOWN" end), VALUE: (if .env.value? != null then .env.value? elif .env.valueFrom?.fieldRef != null then .env.valueFrom?.fieldRef.fieldPath elif .env.valueFrom?.secretKeyRef != null then "\(.env.valueFrom?.secretKeyRef.key) [SecretName: \(.env.valueFrom?.secretKeyRef.name)]" else "..." end) }]'
    
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi

    
    printf '\n%bVolumenes montados por los contenedores:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.volumes as $vols | .spec.containers[] | {name: .name, volumeMount: .volumeMounts[]? } | .volumeMount.name as $volName | { name: .name, volumeMount: .volumeMount, volume: ($vols[]? | select(.name == $volName))} | { CONTAINER: .name, "VOL-NAME": .volumeMount.name, "VOL-TYPE": (if .volume.persistentVolumeClaim?.claimName != null then "PVC" elif .volume.configMap?.name then "CONFIG-MAP" elif .volume.secret?.secretName then "SECRET" elif .volume.hostPath?.path != null then "HOST-PATH" elif .volume.emptyDir? != null then "EMPTY-DIR" elif .volume.downwardAPI?.items != null then "DONWWARD-API" elif .volume.projected?.sources != null then "PROJECTED" else "UNKNOWN" end), "MOUNT-PATH": .volumeMount.mountPath, READONLY: .volumeMount.readOnly?, "VOL-VALUE": (if .volume.persistentVolumeClaim?.claimName != null then .volume.persistentVolumeClaim?.claimName elif .volume.configMap?.name then .volume.configMap?.name elif .volume.secret?.secretName then .volume.secret?.secretName elif .volume.hostPath?.path != null then .volume.hostPath?.path elif .volume.emptyDir? != null then "..." elif .volume.downwardAPI?.items != null then "..." elif .volume.projected?.sources != null then "..." else "???" end) }]'
    
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi

    

    printf '\n%bEtiquetas del pod:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'metadata.labels | to_entries[] | { KEY: .key, VALUE: .value }]'
    
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi

    if [ $p_is_template -ne 0 ]; then
    
        printf '\n%bStatus del pod (Contitions):%b\n' "$g_color_subtitle" "$g_color_reset"
        l_jq_query='[.status.conditions[]? | { TYPE: .type, STATUS: .status, TIME: .lastTransitionTime, REASON: .reason, MESSAGGE: .message }]'
    
        l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
        if [ $? -eq 0 ]; then
            if [ "$l_data" = "[]" ]; then
                printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
            else
                echo "$l_data" | jtbl -n
            fi
        else
            printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
        fi

    

        printf '\n%bStatus de los contenedores del pod:%b\n' "$g_color_subtitle" "$g_color_reset"
        l_jq_query='[.status.containerStatuses[]? | .containerID as $id | .name as $name | (((.state? | to_entries[]) + {type: "Current"}), ((.lastState? | to_entries[]) + { type: "Previous"})) | { CONTAINER: $name, POSITION: .type, TYPE: .key, "STARTED-AT": .value?.startedAt, "FINISHED-AT": .value?.finishedAt, "CONTAINER-ID": (if .type == "Current" then $id else .value?.containerID end), "REASON": .value?.reason, "EXITCODE": .value?.exitCode, "MESSAGE": .value?.message }]'
    
        l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
        if [ $? -eq 0 ]; then
            if [ "$l_data" = "[]" ]; then
                printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
            else
                echo "$l_data" | jtbl -n
            fi
        else
            printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
        fi

    fi    

    printf '\n%bTolerancias del pod:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[ '"${l_root}"'spec.tolerations[]? | {KEY: .key, OPERATOR: .operator, VALUE: .value, EFFECT: .effect, SECONDS: .tolerationSeconds }]'
    
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi



    printf '\n%bNode Selector usados por el pods:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query="${l_root}"'spec.nodeSelector | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$_g_data_object_json" | jq -r "$l_jq_query"


    printf '\n%bPod Affinity:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query="${l_root}"'spec.affinity?.podAffinity'
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$ldata" != "null" ]; then
        printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
    else
        echo "$l_data" | yq -p json -o yaml
    fi

    printf '\n%bPod Anti-Affinity:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query="${l_root}"'spec.affinity?.podAntiAffinity'
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$ldata" != "null" ]; then
        printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
    else
        echo "$l_data" | yq -p json -o yaml
    fi

}


#Parametros (argumentos y opciones):
#  1 > La ruta del archivo de datos
#  2 > El nombre deployment
#  3 > El nombre namespace
#  4 > Las etiquetas para busqueda de pods
show_deploy_info() {

    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
    #local l_data_object_json=""
    local l_data=""

    _g_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi


    #1. Información especifica del contenedor
    printf '%bDeployment :%b %s\n' "$g_color_subtitle" "$g_color_reset" "$2"
    printf '%bNamespace  :%b %s\n' "$g_color_subtitle" "$g_color_reset" "$3"
    printf '%bList pods  :%b oc get pod -n %s -l %s\n' "$g_color_subtitle" "$g_color_reset" "$3" "$4"
    

    printf '%bInformación adicional:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='{ UID: .metadata.uid, Owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), Revision: .metadata.annotations."deployment.kubernetes.io/revision", Generation: .metadata.generation, Replicas: .spec.replicas, ReadyReplicas: "\(.status.readyReplicas)/\(.spec.replicas)", CurrentReplicas: .status.replicas, UpdatedReplicas: .status.updatedReplicas, AvailableReplicas: .status.availableReplicas, ObservedGeneration: .status.observedGeneration, RevisionHistoryLimit: .spec.revisionHistoryLimit, ProgressDeadlineSeconds: .spec.progressDeadlineSeconds } | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$_g_data_object_json" | jq -r "$l_jq_query"


    printf '\n%bEstrategias del Deployment:%b\n' "$g_color_subtitle" "$g_color_reset"
    #l_jq_query='[ .metadata.ownerReferences[]? | { NAME: .name, KIND: .kind, CONTROLLER: .controller, UID: .uid }]'
    
    # l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    # if [ $? -eq 0 ]; then
    #     if [ "$l_data" = "[]" ]; then
    #         printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
    #     else
    #         echo "$l_data" | jtbl -n
    #     fi
    # else
    #     printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    # fi


    printf '\n%bSelector de pods usados:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='.spec.selector.matchLabels | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$_g_data_object_json" | jq -r "$l_jq_query"



    printf '\n%bStatus del Deployment (Contitions):%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[.status.conditions[]? | { TYPE: .type, STATUS: .status, "TRANSITION-TIME": .lastTransitionTime, "UPDATE-TIME": .lastUpdateTime , REASON: .reason, MESSAGGE: .message }]'
    
    l_data=$(echo "$_g_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi

    

    #2. Informacion general del Pod
    printf '\n\n%b########################################################################################\n' "$g_color_opaque" 
    printf '%bPOD TEMPLATE INFO%b\n' "$g_color_title" "$g_color_opaque"
    printf '########################################################################################%b\n' "$g_color_reset"

    _show_pod_info 0


}


#Parametros (argumentos y opciones):
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
    printf '%bContainer  :%b %s\n' "$g_color_subtitle" "$g_color_reset" "$4"
    printf '%bPod        :%b %s\n' "$g_color_subtitle" "$g_color_reset" "$2"
    printf '%bNamespace  :%b %s\n' "$g_color_subtitle" "$g_color_reset" "$3"
    #printf '%bContainers Log    :%b oc logs pod/%s -n %s -c %s --tail=500 -f\n' "$g_color_subtitle" "$g_color_reset" "$2" "$3" "$4"

    local l_data_subobject_json=""
    l_jq_query='{ spec: ( .spec.containers[] | select(.name == $objName)), status: (.status.containerStatuses[]? | select(.name == $objName)), volumes: .spec.volumes }'

    l_data_subobject_json=$(echo "$_g_data_object_json" | jq --arg objName "$4" "$l_jq_query" 2> /dev/null)
    #echo "$l_data_subobject_json"
    if [ $? -ne 0 ]; then
        return 2
    fi

    printf '%bInformación adicional:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='{ Image: .spec.image, ImageID: .status.imageID, ContainerID: .status.containerID, Ready: .status.ready, Started: .status.started, RestartCount: .status.restartCount, Command: ((.spec.command//[]) | join(" ")), Arguments: ((.spec.args//[]) | join(" ")), ImagePullPolicy: .spec.imagePullPolicy } | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$l_data_subobject_json" | jq -r "$l_jq_query"


    printf '\n%bVariables:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[.spec.env[]? | { VARIABLE: .name, TYPE: (if .value? != null then "VALUE" elif .valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" else "UNKNOWN" end), VALUE: (if .value? != null then .value? elif .valueFrom?.fieldRef != null then .valueFrom?.fieldRef.fieldPath elif .valueFrom?.secretKeyRef != null then "\(.valueFrom?.secretKeyRef.key) [SecretName: \(.valueFrom?.secretKeyRef.name)]" else "..." end) }]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi

    
    printf '\n%bPuertos:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[.spec.ports[]? | { NAME: .name, "PORT-HOST": .hostPort, "PORT-CONTAINER": .containerPort, "PROTOCOL": .protocol }]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi


    printf '\n%bVolumenes montados:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[ .volumes as $vols | .spec.volumeMounts[]? | .name as $volName | {name: .name, mountPath: .mountPath, readOnly: .readOnly, volume: ($vols[]? | select(.name == $volName))} | { "VOL-NAME": .name, "VOL-TYPE": (if .volume.persistentVolumeClaim?.claimName != null then "PVC" elif .volume.configMap?.name then "CONFIG-MAP" elif .volume.secret?.secretName then "SECRET" elif .volume.hostPath?.path != null then "HOST-PATH" elif .volume.emptyDir? != null then "EMPTY-DIR" elif .volume.downwardAPI?.items != null then "DONWWARD-API" elif .volume.projected?.sources != null then "PROJECTED" else "UNKNOWN" end), "MOUNT-PATH": .mountPath, READONLY: .readOnly?, "VOL-VALUE": (if .volume.persistentVolumeClaim?.claimName != null then .volume.persistentVolumeClaim?.claimName elif .volume.configMap?.name then .volume.configMap?.name elif .volume.secret?.secretName then .volume.secret?.secretName elif .volume.hostPath?.path != null then .volume.hostPath?.path elif .volume.emptyDir? != null then "..." elif .volume.downwardAPI?.items != null then "..." elif .volume.projected?.sources != null then "..." else "???" end) }]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi


    
    printf '\n%bResources:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[.spec.resources? | ({ TYPE: "Requests", CPU: .requests?.cpu, MEMORY: .requests?.memory }, { TYPE: "Limits", CPU: .limits?.cpu, MEMORY: .limits?.memory })]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi


    printf '\n%bStatus:%b\n' "$g_color_subtitle" "$g_color_reset"
    l_jq_query='[.status | .containerID as $id | (((.state? | to_entries[]) + {type: "Current"}), ((.lastState? | to_entries[]) + { type: "Previous"})) | { POSITION: .type, TYPE: .key, "STARTED-AT": .value?.startedAt, "FINISHED-AT": .value?.finishedAt, "CONTAINER-ID": (if .type == "Current" then $id else .value?.containerID end), "REASON": .value?.reason, "EXITCODE": .value?.exitCode, "MESSAGE": .value?.message }]'  

    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            printf '%bNo data found%b\n' "$g_color_opaque" "$g_color_reset"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        printf '%bError in getting data%b\n' "$g_color_opaque" "$g_color_reset"
    fi

    

    #2. Informacion general del Pod
    printf '\n\n%b########################################################################################\n' "$g_color_opaque" 
    printf '%bADDITIONAL INFO ABOUT POD%b\n' "$g_color_title" "$g_color_opaque"
    printf '########################################################################################%b\n' "$g_color_reset"

    _show_pod_info 1


}

#Parametros (argumentos y opciones):
#  1 > El nombre del pod
#  2 > El nombre namespace
#  3 > El nonbre del contenedor 
#  4 > Puertos TCP del contenedor 
#  . > La ruta del archivo de datos
port_forward_pod() {

    #1. Valores iniciales
    local l_color_1="\x1b[33m"
    local l_color_2="\x1b[95m"

    printf 'Pod       : %b%s%b\n' "$l_color_1" "$1" "$g_color_reset"
    printf 'Namespace : %b%s%b\n' "$l_color_2" "$2" "$g_color_reset"
    printf 'Container : %b%s%b\n' "$l_color_2" "$3" "$g_color_reset"

    if [ -z "$4" ] || [ "$4" == "-" ]; then
        printf "No existe puertos TCP expuestos por el contenedor '%s'.\n" "$3"
        return 1
    fi

    #printf 'Container : %b%s%b\n' "$l_color_2" "$3" "$g_color_reset"
    local IFS=','
    local la_container_ports=($4)


    #2. Leer datos requieridos para los puertos del contenedor que desea forwarding
    IFS=$' \t\n'
    local l_port
    local l_i=0
    #local la_local_ports=()
    local l_availables_ports=0
    local l_input
    local l_option_ports=""

    printf "Local's Ports %b(que se vinculararn los puertos del contenedor)%b:\n" "$g_color_opaque" "$g_color_reset"
    printf '\t%bNota: Especifica un entero positivo, caso contrario el puerto no se tomara en cuenta en el port-forwarding.%b\n' "$g_color_opaque" "$g_color_reset"

    for ((l_i=0; l_i < ${#la_container_ports[@]}; l_i++)); do

        printf "\tLocal's port (Container's port %b%s%b) : " "$l_color_1" "${la_container_ports[$l_i]}" "$g_color_reset"
        read -r l_input

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

    #3. Limpiar la data temporal (solo si se pasa este valor)
    #if [ ! -z "$5" ]; then
    #    rm -f $5
    #fi

    #4. Ejecutar el comando
    printf 'Command   : %bkubectl port-forward pod/%s -n=%s %s%b\n' "$l_color_2" "$1" "$2" "$l_option_ports" "$g_color_reset"
    kubectl port-forward pod/${1} -n=${2} ${l_option_ports}


    return 0
        
}

#Los parametros debe ser la funcion y los parametros
"$@"

