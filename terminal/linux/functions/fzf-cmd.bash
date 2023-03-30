#!/bin/bash

. ~/.files/terminal/linux/functions/func_utility.bash

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


m_git_open_url() {

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
    m_get_os_type
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

m_list_objects() {

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

#Parametros (argumentos y opciones):
#  1 > 0 si follow los logs, caso contrario no lo hace.
#  2 > 0 para mostrar el timestamp.
#  3 > n de la opcion '--tail=n' (mostrar las ultimas n lineas mostrados de los logs).
#      Si es <=0, no se especifica
#  4 > Nombre del pod
#  . > Namespace (si se especifica inicia con "-n=")
#  . > Contenedor (si se especifica inicia con "-c=")
#
m_show_log() {

    #1. Calcular los argumentos del comando y mostrar el mensaje de bienvenida
    printf 'Log of "\x1b[33m%s\x1b[0m"' "$4"
    local l_options="$4"

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
            printf ' (Namespace: "\x1b[95m%s\x1b[0m")' "${5#-n=}"
            l_options="${5} ${l_options}"

            if [ ! -z "$6" ] && [[ "$6" == -c=* ]]; then
                printf ' (Container: "\x1b[95m%s\x1b[0m")' "${6#-c=}"
                l_options="${6} ${l_options}"
            fi

        elif [[ "$5" == -c=* ]]; then
            printf ' (Container: "\x1b[95m%s\x1b[0m")' "$5"
            l_options="${5} ${l_options}"
        fi
    fi

    printf '\n\n'

    #2. Ejecutar el comando
    oc logs ${l_options}
    return 0

}

#Parametros (argumentos y opciones):
#  1 > La ruta del archivo donde obtiene la data
#  2 > El nombre deployment
#  3 > El nombre namespace
m_show_object_yaml() {

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

#Parametros (argumentos y opciones):
#  1 > La ruta del archivo donde obtiene la data
#  2 > El nombre deployment
#  3 > El nombre namespace
#  4 > Las etiquetas para busqueda de pods
m_show_deploy_info() {

    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
    local l_data_object_json=""
    local l_data=""

    l_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    #printf 'Información general:\n\n'
    printf 'Deployment : %s\n' "$2"
    printf 'Namespace  : %s\n' "$3"
    printf 'List pods  : oc get pod -n %s -l "%s"\n' "$3" "$4" 

    printf '\nContenedores principales:\n'
    l_jq_query='[ .spec.template.spec.containers[] | { NAME: .name, PORTS: ( [ (.ports[]? | "\(.containerPort)/\(.protocol)") ] | join(", ")), IMAGE: .image } ]'
    echo "$l_data_object_json" | jq "$l_jq_query" | jtbl -n


    printf '\nVariables de contenedores principales:\n'
    l_jq_query='[.spec.template.spec.containers[] | { name: .name, env: .env[]? } | { CONTAINER: .name, VARIABLE: .env.name, TYPE: (if .env.value? != null then "VALUE" elif .env.valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .env.valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" else "UNKNOWN" end), VALUE: (if .env.value? != null then .env.value? elif .env.valueFrom?.fieldRef != null then .env.valueFrom?.fieldRef.fieldPath elif .env.valueFrom?.secretKeyRef != null then "\(.env.valueFrom?.secretKeyRef.key) [SecretName: \(.env.valueFrom?.secretKeyRef.name)]" else "..." end) }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    
    printf '\nVolumenes montados por los contenedores:\n'
    l_jq_query='[.spec.template.spec.containers[] | { name: .name, volumeMounts: .volumeMounts[]? } | { CONTAINER: .name, NAME: .volumeMounts.name, MOUNT_PATH: .volumeMounts.mountPath, READONLY: .volumeMounts.readOnly? }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    printf '\nVolumenes definidos por el Deployment:\n'
    l_jq_query='[.spec.template.spec.volumes[]? | { NAME: .name, TYPE: (if .persistentVolumeClaim?.claimName != null then "PVC" elif .configMap?.name then "CONFIG-MAP" elif .secret?.secretName then "SECRET" elif .emptyDir? != null then "EMPTY-DIR" elif .downwardAPI?.items != null then "DONWWARD-API" elif .projected?.sources != null then "PROJECTED" else "UNKNOWN" end), VALUE: (if .persistentVolumeClaim?.claimName != null then .persistentVolumeClaim?.claimName elif .configMap?.name then .configMap?.name elif .secret?.secretName then .secret?.secretName elif .emptyDir? != null then "..." elif .downwardAPI?.items != null then "..." elif .projected?.sources != null then "..." else "???" end)}]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    printf '\nEtiquetas que usaran en los pod:\n'
    l_jq_query='[.spec.template.metadata.labels | to_entries[] | { KEY: .key, VALUE: .value }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    printf '\nContenedores de inicialización:\n'
    l_jq_query='[ .spec.template.spec.initContainers[]? | { NAME: .name, PORTS: ( [ .ports[]?.containerPort ] | join(", ")), IMAGE: .image } ]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi



    printf '\nTolerancias que usaran en los pods:\n'
    l_jq_query='[.spec.template.spec.tolerations[]? | {KEY: .key, OPERATOR: .operator, VALUE: .value, EFFECT: .effect, SECONDS: .tolerationSeconds }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi


}


#Parametros (argumentos y opciones):
#  1 > La ruta del archivo donde obtiene la data
#  2 > El nombre del pod
#  3 > El nombre namespace
#  4 > El nonbre del contenedor 
m_show_container_info() {

    local l_jq_query='.items[] | select (.metadata.name == $objName and .metadata.namespace == $objNS)'
    local l_data_object_json=""
    local l_data=""

    l_data_object_json=$(jq --arg objName "$2" --arg objNS "$3" "$l_jq_query" "$1" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi

    #1. Información especifica del contenedor
    printf 'Container  : %s\n' "$4"
    printf 'Pod        : %s\n' "$2"
    printf 'Namespace  : %s\n' "$3"
    printf 'Containers Log    : oc logs pod/%s -n %s -c %s --tail=500 -f\n' "$2" "$3" "$4"

    local l_data_subobject_json=""
    l_jq_query='{ spec: ( .spec.containers[] | select(.name == $objName)), status: (.status.containerStatuses[]? | select(.name == $objName))}'

    l_data_subobject_json=$(echo "$l_data_object_json" | jq --arg objName "$4" "$l_jq_query" 2> /dev/null)
    #echo "$l_data_subobject_json"
    if [ $? -ne 0 ]; then
        return 2
    fi


    printf '\nVariables  :\n'
    l_jq_query='[.spec.env[]? | { VARIABLE: .name, TYPE: (if .value? != null then "VALUE" elif .valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" else "UNKNOWN" end), VALUE: (if .value? != null then .value? elif .valueFrom?.fieldRef != null then .valueFrom?.fieldRef.fieldPath elif .valueFrom?.secretKeyRef != null then "\(.valueFrom?.secretKeyRef.key) [SecretName: \(.valueFrom?.secretKeyRef.name)]" else "..." end) }]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    
    printf '\nVolumenes montados:\n'
    l_jq_query='[.spec.volumeMounts[]? | { NAME: .name, MOUNT_PATH: .mountPath, READONLY: .readOnly? }]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi


    
    printf '\nPuertos:\n'
    l_jq_query='[.spec.ports[]? | { NAME: .name, "PORT-HOST": .hostPort, "PORT-CONTAINER": .containerPort, "PROTOCOL": .protocol }]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi


    printf '\nResources:\n'
    l_jq_query='[.spec.resources | ({ TYPE: "Requests", CPU: .requests?.cpu, MEMORY: .requests?.memory }, { TYPE: "Limits", CPU: .limits?.cpu, MEMORY: .limits?.memory })]'
    
    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi


    printf '\nInformación adicional del contenedor:\n'
    l_jq_query='{ Image: .spec.image, ImageID: .status.imageID, ContainerID: .status.containerID, Ready: .status.ready, Started: .status.started, RestartCount: .status.restartCount, Command: (if .spec.command == null then null else (.spec.command | join(" ")) end), Arguments: (if .spec.command == null then null else ( .spec.args | join(" ")) end), ImagePullPolicy: .spec.imagePullPolicy } | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$l_data_subobject_json" | jq -r "$l_jq_query"


    printf '\nStatus:\n'
    l_jq_query='[.status | .containerID as $id | (((.state? | to_entries[]) + {type: "Current"}), ((.lastState? | to_entries[]) + { type: "Previous"})) | { POSITION: .type, TYPE: .key, "STARTED-AT": .value?.startedAt, "FINISHED-AT": .value?.finishedAt, "CONTAINER-ID": (if .type == "Current" then $id else .value?.containerID end), "REASON": .value?.reason, "EXITCODE": .value?.exitCode, "MESSAGE": .value?.message }]'  

    l_data=$(echo "$l_data_subobject_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    #2. Informacion general del Pod
    printf '\n\n########################################################################################\n'
    printf 'ADDITIONAL INFO ABOUT POD:\n'
    printf '########################################################################################\n'

    printf '\nInformacion general de Pod:\n'
    l_jq_query='{ UID: .metadata.uid, Phase: .status.phase, PodIP: .status.podIP, NodeName: .spec.nodeName, QoSClass: .status.qosClass, StartTime: .status.startTime, DnsPolicy: .spec.dnsPolicy, RestartPolicy: .spec.restartPolicy, SchedulerName: .spec.schedulerName, Priority: .spec.priority, ServiceAccount: .spec.serviceAccount, ServiceAccountName: .spec.serviceAccountName, TerminationGracePeriodSeconds:  .spec.terminationGracePeriodSeconds, ImagePullSecrets: ([.spec.imagePullSecrets[]?.name] | join(", ")), ActiveDeadlineSeconds: .spec.activeDeadlineSeconds } | to_entries[] | "\t\(.key)\t: \(.value)"'
    
    echo "$l_data_object_json" | jq -r "$l_jq_query"


    printf '\nOnwers del pod:\n'
    l_jq_query='[ .metadata.ownerReferences[]? | { NAME: .name, KIND: .kind, CONTROLLER: .controller, UID: .uid }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    
    printf '\nContenedores principales:\n'
    l_jq_query='[ .spec.containers[] | { NAME: .name, PORTS: ( [ (.ports[]? | "\(.containerPort)/\(.protocol)") ] | join(", ")), IMAGE: .image } ]'
    echo "$l_data_object_json" | jq "$l_jq_query" | jtbl -n



    printf '\nContenedores de inicialización:\n'
    l_jq_query='[ .spec.initContainers[]? | { NAME: .name, PORTS: ( [ .ports[]?.containerPort ] | join(", ")), IMAGE: .image } ]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi



    printf '\nVariables de contenedores principales:\n'
    l_jq_query='[.spec.containers[] | { name: .name, env: .env[]? } | { CONTAINER: .name, VARIABLE: .env.name, TYPE: (if .env.value? != null then "VALUE" elif .env.valueFrom?.fieldRef != null then "FROM-FIELDREF" elif .env.valueFrom?.secretKeyRef != null then "FROM-SECRET-REF" else "UNKNOWN" end), VALUE: (if .env.value? != null then .env.value? elif .env.valueFrom?.fieldRef != null then .env.valueFrom?.fieldRef.fieldPath elif .env.valueFrom?.secretKeyRef != null then "\(.env.valueFrom?.secretKeyRef.key) [SecretName: \(.env.valueFrom?.secretKeyRef.name)]" else "..." end) }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    
    printf '\nVolumenes montados por los contenedores:\n'
    l_jq_query='[.spec.containers[] | { name: .name, volumeMounts: .volumeMounts[]? } | { CONTAINER: .name, VOLUMEN: .volumeMounts.name, MOUNT_PATH: .volumeMounts.mountPath, READONLY: .volumeMounts.readOnly? }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    printf '\nVolumenes definidos por el Deployment:\n'
    l_jq_query='[.spec.volumes[]? | { VOLUMEN: .name, TYPE: (if .persistentVolumeClaim?.claimName != null then "PVC" elif .configMap?.name then "CONFIG-MAP" elif .secret?.secretName then "SECRET" elif .emptyDir? != null then "EMPTY-DIR" elif .downwardAPI?.items != null then "DONWWARD-API" elif .projected?.sources != null then "PROJECTED" else "UNKNOWN" end), VALUE: (if .persistentVolumeClaim?.claimName != null then .persistentVolumeClaim?.claimName elif .configMap?.name then .configMap?.name elif .secret?.secretName then .secret?.secretName elif .emptyDir? != null then "..." elif .downwardAPI?.items != null then "..." elif .projected?.sources != null then "..." else "???" end)}]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    printf '\nEtiquetas del pod:\n'
    l_jq_query='[.metadata.labels | to_entries[] | { KEY: .key, VALUE: .value }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    
    
    printf '\nStatus del pod (Contitions):\n'
    l_jq_query='[.status.conditions[]? | { TYPE: .type, STATUS: .status, TIME: .lastTransitionTime, REASON: .reason, MESSAGGE: .message }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    printf '\nStatus de los contenedores del pod:\n'
    l_jq_query='[.status.containerStatuses[]? | .containerID as $id | .name as $name | (((.state? | to_entries[]) + {type: "Current"}), ((.lastState? | to_entries[]) + { type: "Previous"})) | { CONTAINER: $name, POSITION: .type, TYPE: .key, "STARTED-AT": .value?.startedAt, "FINISHED-AT": .value?.finishedAt, "CONTAINER-ID": (if .type == "Current" then $id else .value?.containerID end), "REASON": .value?.reason, "EXITCODE": .value?.exitCode, "MESSAGE": .value?.message }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi

    

    printf '\nTolerancias del pod:\n'
    l_jq_query='[.spec.tolerations[]? | {KEY: .key, OPERATOR: .operator, VALUE: .value, EFFECT: .effect, SECONDS: .tolerationSeconds }]'
    
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ $? -eq 0 ]; then
        if [ "$l_data" = "[]" ]; then
            echo "No data found"
        else
            echo "$l_data" | jtbl -n
        fi
    else
        echo "Error in getting data"
    fi



    printf '\nNode Selector usados por el pods:\n'
    l_jq_query='.spec.nodeSelector | to_entries[] | "\t\(.key)\t: \(.value)"'
    echo "$l_data_object_json" | jq -r "$l_jq_query"


    printf '\nPod Affinity:\n'
    l_jq_query='.spec.affinity?.podAffinity'
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$ldata" != "null" ]; then
        echo "No data found"
    else
        echo "$l_data" | yq -p json -o yaml
    fi

    printf '\nPod Anti-Affinity:\n'
    l_jq_query='.spec.affinity?.podAntiAffinity'
    l_data=$(echo "$l_data_object_json" | jq "$l_jq_query")
    if [ -z "$l_data" ] || [ "$ldata" != "null" ]; then
        echo "No data found"
    else
        echo "$l_data" | yq -p json -o yaml
    fi



}

#Los parametros debe ser la funcion y los parametros
"$@"

