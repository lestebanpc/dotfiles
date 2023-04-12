#!/bin/bash


#Obtener el comando bat: 'bat' y 'batcat'
if [ -z "$_g_fzf_bat" ]; then

    if command -v batcat > /dev/null; then
        _g_fzf_bat="batcat --color=always"
    elif command -v bat > /dev/null; then
        _g_fzf_bat="bat --color=always"
    fi
fi

#Ruta del script para ejecutar funciones en acciones FZF
_g_fzf_script_cmd=~/.files/terminal/linux/functions/fzf-cmd.bash

#Carpetas de archivos temporales
_g_fzf_cache_path="/tmp/fzf"
if [ ! -d "$_g_fzf_cache_path" ]; then
    mkdir -p $_g_fzf_cache_path
fi

#Identificador de una session interactiva (usuario y id por sesion)
if [ -z "$_g_uid" ]; then
    #ID del proceso del interprete shell actual (pueder ser bash o no)
    _g_uid="$$"
fi

################################################################################################
# Editing Code> General Functions
################################################################################################

# Listar archivos/folderes de una carpeta.
# - Argumentos :
#   01 - Ruta del folder donde se busca los archivos.
#   02 - Usar '0' para incluir todos los archivos, incluido los temporales de desarrollo.
_g_fzf_fd=""
gl_ls() {

    #1. Argumentos
    local l_include=1
    if [ "$2" = "0" ]; then
        l_include=0
    fi

    #2. Generar el comando
    if [ $l_include -eq 0 ]; then
        _g_fzf_fd="fd -H -I"
    else
        _g_fzf_fd="fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
    fi
    [ ! -z "$1" ] && _g_fzf_fd="${_g_fzf_fd} . '$1'"

    #echo "$_g_fzf_fd"

    #3. Usar FZF
    FZF_DEFAULT_COMMAND="$_g_fzf_fd" \
    fzf --prompt 'All> ' \
        --bind "ctrl-d:change-prompt(📁 Directories> )+reload(${_g_fzf_fd} -t d)" \
        --bind "ctrl-f:change-prompt(📄 Files> )+reload(${_g_fzf_fd} -t f)" \
        --header $'CTRL-d (Search directories), CTRL-f (Search files)\n'
}

# Buscar archivos con vista previa.
# - Argumentos :
#   01 - Ruta del folder donde se busca los archivos.
gl_files() {
    local l_cmd_ls="fd -H -t f -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
    [ ! -z "$1" ] && l_cmd_ls="${l_cmd_ls} . '$1'"

    FZF_DEFAULT_COMMAND="$l_cmd_ls" \
    fzf --preview "$_g_fzf_bat --style=numbers {}" \
        --prompt '📄 File> ' -m \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-a:execute:$_g_fzf_bat --paging always --style=numbers,header-filename,grid {}" \
        --header $'CTRL-a (Show in full-screen), SHIFT-↑/↓ (Navigate preview\'s pages)\n'
}

# Listar los procesos del SO
gl_ps() {
    (echo "Date: $(date '+%F %T') (Use CTRL-r to reload screen)"; ps -ef) |
    fzf --bind=$'ctrl-r:reload(echo "Date: $(date \'+%F %T\') (Use CTRL-r to reload screen)"; ps -ef)' \
        --prompt '🔧 Process> ' --header-lines=2 \
        --preview='echo {}' --preview-window=down,3,wrap \
        --layout=reverse --height=80% | awk '{print $2}'
}        

_g_fzf_rg="rg --column --line-number --no-heading --color=always --smart-case "
_g_fzf_rg_initial_query=""


gl_rg() {
    #Todo los Argumentos pasados se le quitaran el entrecomillado y se pasara como criterio de busqueda
    _g_fzf_rg_initial_query="${*:-}"

    FZF_DEFAULT_COMMAND="$_g_fzf_rg $(printf %q "$_g_fzf_rg_initial_query")" \
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --header 'CTRL-r (ripgrep mode), CTRL-f (fzf mode), ENTER (Exit & view file)' \
        --disabled --query "$_g_fzf_rg_initial_query" \
        --bind "change:reload:sleep 0.1; $_g_fzf_rg {q} || true" \
        --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(🔦 fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f)" \
        --bind "ctrl-r:unbind(ctrl-r)+change-prompt(🔍 ripgrep> )+disable-search+reload($_g_fzf_rg {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r)" \
        --bind "start:unbind(ctrl-r)" \
        --prompt '🔍 ripgrep> ' \
        --delimiter : \
        --preview "$_g_fzf_bat --style=numbers,header-filename,grid {1} --highlight-line {2}" \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(vim {1} +{2})'
}


################################################################################################
# Editing Code> GIT Functions
################################################################################################

#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
# Utilidades generales
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 


# Redefine this function to change the options
_fzf_git_fzf() {
    fzf-tmux -p80%,60% -- \
        --layout=reverse --multi --min-height=20 --border \
        --color='header:italic:underline' \
        --preview-window='right,50%,border-left' \
        --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
        #--height=50%
}

_fzf_git_check() {
    git rev-parse HEAD > /dev/null 2>&1 && return
    [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
    return 1
}


#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
# Funciones 
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 

# > Argumentos:
#   > Tipo de objeto GIT:
#      1 - Un commit: hash
#      2 - Branch (Local y Remoto): name
#      3 - Remote (Alias del repositorio remoto): name
#      4 - File: name
#      5 - Tag: name


#for Files
gi_files() {

    _fzf_git_check || return

    (git -c color.status=always status --short
    git ls-files | grep -vxFf <(git status -s | grep '^[^?]' | cut -c4-; echo :) | sed 's/^/   /') |
    _fzf_git_fzf -m --ansi --nth 2..,.. \
        --prompt '📄 Files> ' \
        --header $'CTRL-o (open in browser) ╱ ALT-e (open in editor)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash $_g_fzf_script_cmd git_open_url 4 {-1}" \
        --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
        --preview "git diff --color=always -- {-1} | delta; $_g_fzf_bat --style=numbers,header-filename,grid {-1}" "$@" |
    cut -c4- | sed 's/.* -> //'
}

#for Branches (Local y Remoto)
gi_branches() {

    _fzf_git_check || return

    bash "$_g_fzf_script_cmd" list_objects branches |
    _fzf_git_fzf --ansi \
        --prompt '🌲 Branches> ' \
        --header-lines 2 \
        --tiebreak begin \
        --preview-window down,border-top,40% \
        --color hl:underline,hl+:underline \
        --no-hscroll \
        --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
        --bind "ctrl-o:execute-silent:bash $_g_fzf_script_cmd git_open_url 2 {}" \
        --bind "alt-a:change-prompt(🌳 All branches> )+reload:bash \"$_g_fzf_script_cmd\" list_objects all-branches" \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' "$@" |
    sed 's/^..//' | cut -d' ' -f1
}

#for Tags
gi_tags() {

    _fzf_git_check || return

    git tag --sort -version:refname |
    _fzf_git_fzf --preview-window right,70% \
        --prompt '📛 Tags> ' \
        --header $'CTRL-o (Open in browser)\n\n' \
        --bind "ctrl-o:execute-silent:bash $_g_fzf_script_cmd git_open_url 5 {}" \
        --preview 'git show --color=always {} | delta' "$@"
}

#for commit Hashes
gi_hashes() {
    _fzf_git_check || return

    git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
    _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
        --prompt '🍡 Hashes> ' \
        --header $'CTRL-o (Open in browser), CTRL-d (Diff), CTRL-s (Toggle sort)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash $_g_fzf_script_cmd git_open_url 1 {}" \
        --bind 'ctrl-d:execute:grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git diff | delta > /dev/tty' \
        --color hl:underline,hl+:underline \
        --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git show --color=always | delta' "$@" |
    awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}

#alias glog='git log --color=always --format="%C(cyan)%h%Creset %C(blue)%ar%Creset%C(auto)%d%Creset %C(yellow)%s%+b %C(white)%ae%Creset" "$@"'
##¿que pase si en la linea ({}) existe una comilla? ... ¿como se ejecuta el comando?
#_g_fzf_glog_hash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
#_g_fzf_glog_view="$_g_fzf_glog_hash | xargs git show --color=always | delta"
#
#gi_log() {
#
#    #Obtener el directorio .git pero no imprimir su valor ni los errores. Si no es un repositorio valido salir
#    if ! git rev-parse --git-dir > /dev/null 2>&1; then
#        echo 'Invalid git repository'
#        return 0
#    fi
#
#    #Mostrar los commit y su preview
#    glog | fzf -i -e --no-sort --reverse --tiebreak index -m --ansi \
#        --preview "$_g_fzf_glog_view" \
#        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "ctrl-z:execute:$_g_fzf_glog_view" \
#        --header $'CTRL-z (Show in full-screen), SHIFT-↑/↓ (Navigate preview\'s pages)\n' \
#        | grep -o '[a-f0-9]\{7\}' 
#        #--print-query 
#}


#for Remotes (Alias de los repositorios remotos)
gi_remotes() {
    _fzf_git_check || return

    git remote -v | awk '{print $1 "\t" $2}' | uniq |
    _fzf_git_fzf --tac \
        --prompt '📡 Remotes> ' \
        --header $'CTRL-o (Open in browser)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash $_g_fzf_script_cmd git_open_url 3 {1}" \
        --preview-window right,70% \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1}/"$(git rev-parse --abbrev-ref HEAD)"' "$@" |
    cut -d$'\t' -f1
}

#for Stashes
gi_stashes() {
    _fzf_git_check || return

    git stash list | _fzf_git_fzf \
        --prompt '🥡 Stashes> ' \
        --header $'CTRL-x (Drop stash)\n\n' \
        --bind 'ctrl-x:execute-silent(git stash drop {1})+reload(git stash list)' \
        -d: --preview 'git show --color=always {1} | delta' "$@" |
    cut -d: -f1
}

#for Each ref (git for-each-ref)
gi_eachref() {
    _fzf_git_check || return

    bash "$_g_fzf_script_cmd" list_objects refs | _fzf_git_fzf --ansi \
        --nth 2,2.. \
        --tiebreak begin \
        --prompt '☘️  Each ref> ' \
        --header-lines 2 \
        --preview-window down,border-top,40% \
        --color hl:underline,hl+:underline \
        --no-hscroll \
        --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
        --bind "ctrl-o:execute-silent:bash $_g_fzf_script_cmd git_open_url 2 {2}" \
        --bind "ctrl-s:execute:git show {2} | delta > /dev/tty" \
        --bind "ctrl-d:execute:git diff {2} | delta > /dev/tty" \
        --bind "alt-a:change-prompt(🍀 Every ref> )+reload:bash \"$_g_fzf_script_cmd\" list_objects all-refs" \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {2}' "$@" |
    awk '{print $2}'
    #--bind "alt-e:execute:${EDITOR:-vim} <(git show {2}) > /dev/tty" \
}


################################################################################################
# K8S Functions (Se usara 'kubectl' por defecto, opcionalmente se usara 'oc' de RHOCP)
################################################################################################

#Resources short-names:
#componentstatuses = cs
#configmaps = cm
#endpoints = ep
#events = ev
#limitranges = limits
#namespaces = ns
#nodes = no
#persistentvolumeclaims = pvc
#persistentvolumes = pv
#pods = po
#replicationcontrollers = rc
#resourcequotas = quota
#serviceaccounts = sa
#services = svc
#customresourcedefinitions = crd, crds
#daemonsets = ds
#deployments = deploy
#replicasets = rs
#statefulsets = sts
#horizontalpodautoscalers = hpa
#cronjobs = cj
#certificiaterequests = cr, crs
#certificates = cert, certs
#certificatesigningrequests = csr
#ingresses = ing
#networkpolicies = netpol
#podsecuritypolicies = psp
#replicasets = rs
#scheduledscalers = ss
#priorityclasses = pc
#storageclasses = sc


#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
# Utilidades generales
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 

_fzf_kc_get_context_info() {

    #TODO mejorar para obtener la URL del servidor, nombre del usuario, ...
    local l_data=$(kubectl config current-context)
    local l_tmp="${l_data//// }"
    local l_items=($l_tmp)
    local l_n=${#l_items[@]}
    
    local l_color_1="\x1b[91m"
    local l_color_2="\x1b[33m"
    #local l_color_opaque="\x1b[90m"
    local l_color_reset="\x1b[0m"

    if [ $l_n -lt 3 ]; then
        printf "Context: '%b%s%b'" "$l_color_1" "${l_data}" "$l_color_reset" 
    else
        printf "User: '%b%s%b', Server: '%b%s%b'" "$l_color_1" "${l_items[2]}" "$l_color_reset" "$l_color_2" "${l_items[1]}" "$l_color_reset"
        #printf "User: '\x1b[91m%s\x1b[m', Default Namespace: '\x1b[92m%s\x1b[m', Server: '\x1b[33m%s\x1b[m'" "${l_items[2]}" "${l_items[0]}" "${l_items[1]}"
    fi
}

#Plantilla de opciones usando en las acciones FZF, cuyo formato es "resource-type/[resource-name] -n=[namespace]"
#  > "[resource-name]" puede ser el nombre del recurso o "{n}" donde n es el numero de campo donde se obtendra.
#  > "[namespace]" puede ser el nombre del namespace o "{n}" donde n es el numero de campo donde se obtendra.
_g_fzf_kc_options=""

#Nombre del archivo de dato
_g_fzf_kc_data_file=""


#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
# Funciones
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 

kc_resources() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_resource_name="$1"
    local l_awk_template="{print \"${l_resource_name}/\"\$1}"
    _g_fzf_kc_options="${l_resource_name}/{1}"

    #2. Procesar los argumentos y modificar las variables segun ello

    #Ayuda
    if [ -z "$1" ]; then
        echo "Parametros invalidos. Use 'oc_resources --help' para ver mas detalle de su uso."
        return 1
    elif [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_resources RESOURCE-KIND NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_resources --help" 
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi 
    
    #Resource KIND o Name
    local l_cmd="kubectl get $1"

    #Namespace
    if [ ! -z "$2" ] && [ "$2" != "." ]; then
        if [ "$2" = "--all" ]; then
            l_cmd="${l_cmd} --all-namespaces"
            l_awk_template="{print \"${l_resource_name}/\"\$2\" -n \"\$1}"
            _g_fzf_kc_options="${l_resource_name}/{2} -n={1}"
        else
            l_cmd="${l_cmd} -n $2"
            l_awk_template="{print \"${l_resource_name}/\"\$1\" -n $2\"}"
            _g_fzf_kc_options="${l_resource_name}/{1} -n=$2"
        fi
    fi
    
    #Labels
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd="${l_cmd} -l $3"
    fi

    #Filed Selectors
    if [ ! -z "$4" ] &&  [ "$4" != "." ]; then
        l_cmd="${l_cmd} --field-selector $4"
    fi

    #echo "$_g_fzf_oc_pod_path"
    #echo "$l_awk_template"

    #3. Generar el reporte deseado con la data ingresada
    FZF_DEFAULT_COMMAND="$l_cmd" \
    fzf --info=inline --layout=reverse --header-lines=1 -m \
        --prompt "${l_resource_name}> " \
        --header "$(_fzf_kc_get_context_info)"$'\nCTRL-r (reload), CTRL-a (View yaml)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(oc get ${_g_fzf_kc_options} -o yaml) > /dev/tty" \
        --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' |
    awk "$l_awk_template"

}


kc_pods() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_awk_template='{print "pod/"$1" -n "$2}'
    local l_cmd_options="get pod -o json"
    _g_fzf_kc_data_file="${_g_fzf_cache_path}/pods_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello
    
    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_pods NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_pods --help" 
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi
    
    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi
    
    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data=""
    local l_jq_query='[.items[] | { name: .metadata.name, namespace: .metadata.namespace, status: .status.phase, startTime: .status.startTime, ip: .status.podIP, nodeName: .spec.nodeName, owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(",")), ready: (first(.status.conditions[]? | select(.type == "Ready"))), cntNbr: (.spec.containers | length), cntNbrPorts: ([.spec.containers[].ports[]? | select(.protocol == "TCP") | .containerPort] | length), cntNbrReadys: ([.status.containerStatuses[]? | select(.ready)] | length), cntNbrRestarts: ([.status.containerStatuses[]? | .restartCount] | add), cnt: ([.spec.containers[]?.name] | join(",")) } | { "POD-NAME": .name, "POD-NAMESPACE": .namespace, STATE: .status, READY: ("\(.cntNbrReadys)/\(.cntNbr)" + (if .cntNbrReadys == .cntNbr then "" elif  .ready?.status == "False" then "" else "(OB=\(.cntNbr - .cntNbrReadys))" end)), RESTARTS: .cntNbrRestarts, "START-TIME": .startTime, "READY-TIME": (if .ready?.status == "True" then .ready?.lastTransitionTime else "-" end), "FINISHED-TIME": (if .ready?.status == "False" then .ready?.lastTransitionTime else "-" end), "PORTS-NBR": .cntNbrPorts, OWNERS: (if .owners == "" then "-" else .owners end), "NODE-NAME": .nodeName, "POD-IP": .ip, CONTAINERS: .cnt}]'

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    l_data=$(jq "$l_jq_query" $_g_fzf_kc_data_file)
    if [ $? -ne 0 ]; then
        echo "Error en el fitro usado"
        return 2
    fi

    if [ "$l_data" = "[]" ]; then
        echo "No data found"
        return 3
    fi
    
    #5. Mostrar el reporte
    echo "$l_data" | jtbl -n |
    fzf --info=inline --layout=reverse --header-lines=2 -m --nth=..2 \
        --prompt "Container> " \
        --header "$(_fzf_kc_get_context_info)"$'\nCTRL-a (View pod yaml), CTRL-b (Preview in full-screen), CTRL-t (Bash Terminal), CTRL-l (View log), CTRL-p (Exit & Port-Forward), CTRL-x (Exit & follow logs)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${_g_fzf_script_cmd} show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:$_g_fzf_bat --paging always --style plain <(bash ${_g_fzf_script_cmd} show_pod_info '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-t:execute:bash \"${_g_fzf_script_cmd}\" open_terminal '{1}' '{2}' 'bash' '${_g_fzf_kc_data_file}'  > /dev/tty" \
        --bind "ctrl-l:execute(bash \"${_g_fzf_script_cmd}\" show_log_pod '{1}' '{2}' 1 10000 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-p:become(bash \"${_g_fzf_script_cmd}\" port_forward_pod '{1}' '{2}' '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-x:become(bash \"${_g_fzf_script_cmd}\" show_log_pod '{1}' '{2}' 0 200 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${_g_fzf_script_cmd} show_pod_info '${_g_fzf_kc_data_file}' '{1}' '{2}' | $_g_fzf_bat --style plain" |
    awk "$l_awk_template"

    rm -f $_g_fzf_kc_data_file

}



kc_containers() {

    #1. Inicializar variables requeridas para fzf y awk
    local l_awk_template='{print "pod/"$1" -n "$2" -c "$3}'
    local l_cmd_options="get pod -o json"
    _g_fzf_kc_data_file="${_g_fzf_cache_path}/containers_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello
    
    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_containers NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_containers --help" 
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi
    
    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi
    
    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data=""
    local l_jq_query='[.items[] | (.spec.containers | length) as $allcont | { podName: .metadata.name, podNamespace: .metadata.namespace, podStatus: .status.phase, podStartTime: .status.startTime, podIP: .status.podIP, nodeName: .spec.nodeName, container: .spec.containers[], containerStatuses: .status.containerStatuses } | .container.name as $name | { podName: .podName, podNamespace: .podNamespace, podCntNbr: $allcont, podCntReady: ([.containerStatuses[].ready | select(. == true)] | length), podStartTime: .podStartTime, podIP: .podIP, nodeName: .nodeName, name: .container.name, image: .container.image, ports: ([.container.ports[]? | select(.protocol == "TCP") | .containerPort] | join(",")), status: (.containerStatuses[] | select(.name == $name)) } | (.status.state | to_entries[0]) as $st | { "POD-NAME": .podName, "POD-NAMESPACE": .podNamespace, CONTAINER: .name, "STATE": $st.key, READY: .status.ready, "POD-READY": ("\(.podCntReady)/\(.podCntNbr)" + (if .podCntReady == .podCntNbr then "" else "(OB=\(.podCntNbr - .podCntReady))" end)), "TCP-PORTS": (if .ports == "" then "-" else .ports end), "RESTART": .status.restartCount, "STARTED": (.status.started//"-"), "STARTED-AT": ($st.value.startedAt//"-"),  "FINISHED-AT": ($st.value.finishedAt//"-"), REASON: ($st.value.reason//"-"), "EXIT-CODE": ($st.value.exitCode//"-"), "POD-STARTED-AT": .podStartTime, "POD-IP": .podIP, "NODE-NAME": .nodeName }]'

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    l_data=$(jq "$l_jq_query" $_g_fzf_kc_data_file)
    if [ $? -ne 0 ]; then
        echo "Error en el fitro usado"
        return 2
    fi

    if [ "$l_data" = "[]" ]; then
        echo "No data found"
        return 3
    fi
    
    #5. Mostrar el reporte
    echo "$l_data" | jtbl -n |
    fzf --info=inline --layout=reverse --header-lines=2 -m --nth=..3 \
        --prompt "Container> " \
        --header "$(_fzf_kc_get_context_info)"$'\nCTRL-a (View pod yaml), CTRL-b (Preview in full-screen), CTRL-t (Bash Terminal), CTRL-l (View log), CTRL-p (Exit & Port-Forward), CTRL-x (Exit & follow logs)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${_g_fzf_script_cmd} show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:$_g_fzf_bat --paging always --style plain <(bash ${_g_fzf_script_cmd} show_container_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{3}') > /dev/tty" \
        --bind "ctrl-t:execute:oc exec -it {1} -n={2} -c={3} -- bash > /dev/tty" \
        --bind "ctrl-l:execute(bash \"${_g_fzf_script_cmd}\" show_log_container '{1}' '{2}' '{3}' 1 10000 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-p:become(bash \"${_g_fzf_script_cmd}\" port_forward_container '{1}' '{2}' '{3}' '{7}' '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --bind "ctrl-x:become(bash \"${_g_fzf_script_cmd}\" show_log_container '{1}' '{2}' '{3}' 0 200 '${_g_fzf_kc_data_file}' > /dev/tty)" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${_g_fzf_script_cmd} show_container_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{3}' | $_g_fzf_bat --style plain" |
    awk "$l_awk_template"

    #    --bind "ctrl-l:execute:$_g_fzf_bat --paging always --style plain  <(kubectl logs {1} -n={2} -c={3} --tail=10000 --timestamps) > /dev/tty" \
    #    --bind "ctrl-x:become(bash \"${_g_fzf_script_cmd}\" show_log 0 0 200 '{1}' '-n={2}' '-c={3}' '${_g_fzf_kc_data_file}' > /dev/tty)" \

    rm -f $_g_fzf_kc_data_file

}


kc_deployments() {

    #1. Inicializar variables requeridas para fzf y awk
    #local l_awk_template='{print "deployment/"$1" -n "$2" | pod -n "$2"-l "$7}'
    local l_awk_template='{print "deployment/"$1" -n "$2}'
    local l_cmd_options="get deployment -o json"
    _g_fzf_kc_data_file="${_g_fzf_cache_path}/deployments_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello
    
    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_deployments NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_deployments --help" 
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi
    
    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi

    
    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > "$_g_fzf_kc_data_file"
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada
    local l_data=""
    local l_jq_query='[.items[] | (reduce (.spec.selector.matchLabels | to_entries[]) as $i (""; . + (if . != "" then "," else "" end) + "\($i.key)=\($i.value)")) as $labels | { name: .metadata.name, namespace: .metadata.namespace, revision: .metadata.annotations."deployment.kubernetes.io/revision", desiredReplicas: .spec.replicas, currentReplicas: .status.replicas, readyReplicas: .status.readyReplicas, availableReplicas: .status.availableReplicas, updatedReplicas: .status.updatedReplicas, owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), lastTransitionTime: (.status.conditions[] | select(.type=="Progressing") | .lastTransitionTime) } | { NAME: .name, NAMESPACE: .namespace, DESIRED: .desiredReplicas, READY: "\(.readyReplicas)/\(.currentReplicas)", "UP-TO-DATE": .updatedReplicas, AVAILABLE: .availableReplicas, INITIAL: .lastTransitionTime, REVISION: .revision, "SELECTOR-MATCH-LABELS": $labels, OWNERS: (if .owners == "" then "-" else .owners end)}]'

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    l_data=$(jq "$l_jq_query" ${_g_fzf_kc_data_file})
    if [ $? -ne 0 ]; then
        echo "Error en el fitro usado"
        return 2
    fi

    if [ "$l_data" = "[]" ]; then
        echo "No data found"
        return 3
    fi
    
    #5. Mostrar el reporte
    echo "$l_data" | jtbl -n |
    fzf --info=inline --layout=reverse --header-lines=2 -m --nth=..2 \
        --prompt "Deployment> " \
        --header "$(_fzf_kc_get_context_info)"$'\nCTRL-a (View yaml), CTRL-b (Preview in full-screen), CTRL-d (View revisions)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${_g_fzf_script_cmd} show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:$_g_fzf_bat --paging always --style plain <(bash ${_g_fzf_script_cmd} show_deployment_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{7}') > /dev/tty" \
        --bind "ctrl-d:execute:$_g_fzf_bat --paging always --style plain <(bash ${_g_fzf_script_cmd} show_dply_revision1 '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${_g_fzf_script_cmd} show_deployment_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{7}' | $_g_fzf_bat --style plain" |
    awk "$l_awk_template"

    rm -f ${_g_fzf_kc_data_file}

    #    --header "$(_fzf_kc_get_context_info)"$'\nCTRL-a (View yaml), CTRL-b (Preview in full-screen), CTRL-d (View revisions), CTRL-l (View logs), CTRL-x (Exit & follow logs)\n' \
    #    --bind "ctrl-l:execute(bash \"${_g_fzf_script_cmd}\" show_log_dply '{1}' '{2}' 1 10000 '${_g_fzf_kc_data_file}' > /dev/tty)" \
    #    --bind "ctrl-x:become(bash \"${_g_fzf_script_cmd}\" show_log_dply '{1}' '{2}' 0 200 '${_g_fzf_kc_data_file}' > /dev/tty)" \
}



kc_replicasets() {

    #1. Inicializar variables requeridas para fzf y awk
    #local l_awk_template='{print "replicaset/"$1" -n "$2" | pod -n "$2"-l "$7}'
    local l_awk_template='{print "replicaset/"$1" -n "$2}'
    local l_cmd_options="get replicaset -o json"
    _g_fzf_kc_data_file="${_g_fzf_cache_path}/replicaset_${_g_uid}.json"

    #2. Procesar los argumentos y modificar las variables segun ello
    
    #Ayuda
    if [ "$1" = "--help" ]; then
        echo "Usar: "
        echo "     kc_replicasets NAMESPACE FILTER-LABELS FILTER-FIELDS"
        echo "     kc_replicasets --help" 
        echo "> Use '.' si desea no ingresar valor para el argumento."
        echo "> Argumento 'NAMESPACE'    : Coloque solo el nombre del namespace o use '--all' para establecer todos los namespaces. "
        echo "  Si el recurso no posee namespace o no desea colocarlo, use '.'."
        echo "> Argumento 'FILTER-LABELS': Coloque el listado de los labels deseado (igual al valor de '-l' o '--selector' de kubectl)."
        echo "  Ejemplo 'label1=value1,label2=value2'"
        echo "> Argumento 'FILTER-FIELDS': Coloque el listado de los campos deseado (igual al valor de '--field-selector' de kubectl)."
        echo "  Ejemplo 'field1=value1,field2==value1,field2!=value'"
        return 0
    fi
    
    #Namespace
    if [ ! -z "$1" ] && [ "$1" != "." ]; then
        if [ "$1" = "--all" ]; then
            l_cmd_options="${l_cmd_options} --all-namespaces"
        else
            l_cmd_options="${l_cmd_options} -n $1"
        fi
    fi

    
    #Labels
    if [ ! -z "$2" ] &&  [ "$2" != "." ]; then
        l_cmd_options="${l_cmd_options} -l $2"
    fi

    #Filed Selectors
    if [ ! -z "$3" ] &&  [ "$3" != "." ]; then
        l_cmd_options="${l_cmd_options} --field-selector $3"
    fi

    #echo "$l_cmd_options"

    #3. Obtener la data del cluster y almacenarlo en un archivo temporal
    kubectl $l_cmd_options > $_g_fzf_kc_data_file 
    if [ $? -ne 0 ]; then
        echo "Check the connection to k8s cluster"
        return 1
    fi

    #4. Generar el reporte deseado con la data ingresada (por ahora solo muestra los '.spec.replicas' no sea 0)
    local l_data=""
    local l_jq_query='[.items[] | select(.spec.replicas > 0) | (reduce (.spec.selector.matchLabels | to_entries[]) as $i (""; . + (if . != "" then "," else "" end) + "\($i.key)=\($i.value)")) as $labels | { name: .metadata.name, namespace: .metadata.namespace, revision: .metadata.annotations."deployment.kubernetes.io/revision", desiredReplicas: .spec.replicas, currentReplicas: .status.replicas, readyReplicas: (.status.readyReplicas//0), availableReplicas: (.status.availableReplicas//0), fullyLabeledReplicas: .status.fullyLabeledReplicas, owners: ([.metadata.ownerReferences[]? | "\(.kind)/\(.name)"] | join(", ")), time:  .metadata.creationTimestamp} | { NAME: .name, NAMESPACE: .namespace, OWNERS: .owners, DESIRED: .desiredReplicas, READY: "\(.readyReplicas)/\(.currentReplicas)", AVAILABLE: .availableReplicas, INITIAL: .time, REVISION: .revision, "SELECTOR-MATCH-LABELS": $labels}]'

    #Debido a que jtbl genera error cuando se el envia un arreglo vacio, usando
    l_data=$(jq "$l_jq_query" ${_g_fzf_kc_data_file})
    if [ $? -ne 0 ]; then
        echo "Error en el fitro usado"
        return 2
    fi

    if [ "$l_data" = "[]" ]; then
        echo "No data found"
        return 3
    fi
    
    #5. Mostrar el reporte
    echo "$l_data" | jtbl -n |
    fzf --info=inline --layout=reverse --header-lines=2 -m --nth=..3 \
        --prompt "ReplicaSet> " \
        --header "$(_fzf_kc_get_context_info)"$'\nCTRL-a (View yaml), CTRL-b (Preview in full-screen), CTRL-d (View revisions)\n' \
        --bind "ctrl-a:execute:vim -c 'set filetype=yaml' <(bash ${_g_fzf_script_cmd} show_object_yaml '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --bind "ctrl-b:execute:$_g_fzf_bat --paging always --style plain <(bash ${_g_fzf_script_cmd} show_replicaset_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{9}') > /dev/tty" \
        --bind "ctrl-d:execute:$_g_fzf_bat --paging always --style plain <(bash ${_g_fzf_script_cmd} show_dply_revision2 '${_g_fzf_kc_data_file}' '{1}' '{2}') > /dev/tty" \
        --preview-window "down,border-top,70%" \
        --preview "bash ${_g_fzf_script_cmd} show_replicaset_info '${_g_fzf_kc_data_file}' '{1}' '{2}' '{9}' | $_g_fzf_bat --style plain" |
    awk "$l_awk_template"

    rm -f ${_g_fzf_kc_data_file}

}








