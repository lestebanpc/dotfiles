#!/bin/bash


#Cuando no se puede determinar la version actual (siempre se instalara)
declare -r g_version_none='0.0.0'



#Funciones modificables (Nivel 2) {{{


#Obtener 2 versiones menores a la actual
#Parametros de salida:
#  > Valor de retorno:
#    0 - OK
#    1 - No OK
#  > STDOUT: Las 2 versiones separadas por ' '
function _dotnet_get_subversions()
{
    local p_repo_name="$1"
    local p_version_pretty="$2"

    #Cortar y obtener 1er numero
    IFS='.'
    la_numbers=($p_version_pretty)
    unset IFS

    local l_n=${#la_numbers[@]}

    #Version enviada es incorrecta
    if [ $l_n -le 1 ]; then
        return 1
    fi

    local l_number=${la_numbers[0]}
    local l_status
    local l_aux
    local l_versions="$p_version_pretty"

    for ((l_i=1; l_i<=2; l_i++)); do

        l_aux=""
        ((l_n=${l_number} - ${l_i}))

        #El artefacto se obtiene del repositorio de Microsoft y usando una version especifica
        #No se usa la version LTS
        l_aux=$(curl -Ls "https://dotnetcli.azureedge.net/${p_repo_name}/${l_n}.0/latest.version")
        l_status=$?
        l_aux=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")

        if [ $l_status -eq 0 ] && [ ! -z "$l_aux" ]; then
            l_versions="${l_aux} ${l_versions}"
        fi

    done 

    if [ -z "$l_versions" ]; then
        return 1
    fi

    echo "$l_versions"
    return 0

}

#Validar si una version esta instalada
#Parametros de salida:
#  > Valor de retorno:
#    0 - Existe
#    1 - No existe
function _dotnet_exist_version()
{
    local p_repo_id="$1"
    local p_version="$2"
    local p_install_win_cmds=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #Calcular la ruta de archivo/comando donde se obtiene la version
    local l_path_file=""
    if [ $p_install_win_cmds -eq 0 ]; then
       l_path_file="${g_path_programs_win}/DotNet"
    else
       l_path_file="${g_path_programs}/dotnet"
    fi

    #Prefijo del nombre del artefacto
    local l_cmd_option=''
    if [ "$p_repo_id" = "net-sdk" ]; then
        l_cmd_option='--list-sdks'
    else
        l_cmd_option='--list-runtimes'
    fi

    #Obtener las versiones instaladas
    local l_info=""
    local l_status
    if [ $p_install_win_cmds -eq 0 ]; then
        l_info=$(${l_path_file}/dotnet.exe ${l_cmd_option} 2> /dev/null)
        l_status=$?
    else
        l_info=$(${l_path_file}/dotnet ${l_cmd_option} 2> /dev/null)
        l_status=$?
    fi

    #echo "RepoID: ${p_repo_id}, Version: ${p_version}"
    #echo "Info: ${l_info}"

    if [ $l_status -eq 0 ] && [ ! -z "$l_info" ]; then

        if [ "$p_repo_id" = "net-sdk" ]; then

            l_info=$(echo "$l_info" | grep "$p_version" | head -n 1)
            l_status=$?

        elif [ "$p_repo_id" = "net-rt-core" ]; then

            l_info=$(echo "$l_info" | grep 'Microsoft.NETCore.App' | grep "$p_version" | head -n 1)
            l_status=$?

        else
            l_info=$(echo "$l_info" | grep 'Microsoft.AspNetCore.App' | grep "$p_version" | head -n 1)
            l_status=$?

        fi

        if [ $l_status -ne 0 ]; then
            l_info=""
        fi

    else
        l_info=""
    fi

    #echo "Info: ${l_info}"

    #Resultados
    if [ -z "$l_info" ]; then
        return 1
    fi

    return 0

}


#}}}




#Funciones modificables (Nivel 2) {{{


function _get_repo_base_url() {

    #1. Argumentos
    local p_repo_id="$1"

    #2. Obtener la URL base
    local l_base_url=""
    case "$p_repo_id" in

        kubectl|kubelet|kubeadm)
            l_base_url="https://dl.k8s.io/release"
            ;;

        net-sdk|net-rt-core|net-rt-aspnet)
            l_base_url="https://dotnetcli.azureedge.net"
            ;;

        helm)
            l_base_url="https://get.helm.sh"
            ;;

        go)
            l_base_url="https://storage.googleapis.com"
            ;;
            
        jdtls)
            l_base_url="https://download.eclipse.org"
            ;;

        step)
            l_base_url="https://dl.smallstep.com/gh-release/cli/gh-release-header"
            ;;

        nodejs)
            l_base_url="https://nodejs.org/dist"
            ;;
        *)
            l_base_url="https://github.com"
            ;;

    esac

    #3. Obtener la URL
    echo "$l_base_url"

}


#Obtiene la ultima version de realease obtenido en un repositorio
# > Los argumentos de entrada son:
#   1ro  - El ID del repositorio
#   2do  - El nombre del repositorio
# > Los argumentos de salida son:
#   3ro  - Arreglo con la version original (usado para descargar) y la version amigable o 'pretty version' (usando para comparar versiones)
#   4to  - Arreglo con la versiones de artefactos de los repostorios (por defecto este es 'null', existe artefactos con la misma version que el repositorio)
#          Debera iniciar por la ultima versión. No existe.
# > Los valores de retorno es 0 si es OK, caso contrario ocurrio un error. Los errores devueltos son
#   1    - Se requiere tener habilitado el comando jq
function _get_repo_latest_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    declare -n pna_repo_versions=$3   #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_arti_subversion_versions=$4
    
    #2. Obtener la version
    local l_repo_last_version=""
    local l_repo_last_version_pretty=""
    local l_aux=""
    local l_aux2=""
    local l_arti_subversion_versions=""
    #local l_status=0

    case "$p_repo_id" in

        kubectl|kubelet|kubeadm)
            #El artefacto se obtiene del repositorio de Kubernates
            l_repo_last_version=$(curl -Ls https://dl.k8s.io/release/stable.txt)
            l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")
            ;;

        net-sdk|net-rt-core|net-rt-aspnet)

            #El artefacto se obtiene del repositorio de Microsoft

            #1. Obtener la maximo version encontrada, ya sea STS (standar term support) o LTS (long term support)
            l_repo_last_version=$(curl -Ls "https://dotnetcli.azureedge.net/${p_repo_name}/STS/latest.version")
            l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")

            l_aux=$(curl -Ls "https://dotnetcli.azureedge.net/${p_repo_name}/LTS/latest.version")
            l_aux2=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")


            compare_version "${l_repo_last_version_pretty}" "${l_aux2}"
            l_status=$?

            #Si es 1ro es < que el 2do
            if [ $l_status -eq 2 ]; then
                l_repo_last_version="$l_aux"
                l_repo_last_version_pretty="$l_aux2"
            fi

            #Obtener las subversiones: estara formado por la ultima version y 2 versiones inferiores 
            l_arti_subversion_versions=$(_dotnet_get_subversions "$p_repo_name" "$l_repo_last_version_pretty")

            #Si solo tiene uns subversion y es la misma que la version, no existe subversiones
            if [ "$l_repo_last_version_pretty" = "$l_arti_subversion_versions" ]; then
                l_arti_subversion_versions=""
            fi
            ;;
        

        jdtls)
            l_aux=$(curl -Ls https://download.eclipse.org/jdtls/snapshots/latest.txt)
            l_aux=${l_aux%.tar.gz}
            l_repo_last_version=$(echo "$l_aux" | sed -e "$g_regexp_sust_version2")
            l_repo_last_version_pretty="${l_repo_last_version//-/.}"
            ;;

        go)
            #Si no esta instalado 'jq' no continuar
            if ! command -v jq &> /dev/null; then
                return 1
            fi

            l_aux=$(curl -Ls -H 'Accept: application/json' "https://go.dev/dl/?mode=json" | jq -r '.[0].version')
            if [ $? -eq 0 ]; then
                l_repo_last_version=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")
                l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")
            else
                l_repo_last_version=""
            fi
            ;;

        jq)
            #Si no esta instalado 'jq' usar expresiones regulares
            if ! command -v jq &> /dev/null; then
                l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://github.com/${p_repo_name}/releases/latest" | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
            else
                l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://github.com/${p_repo_name}/releases/latest" | jq -r '.tag_name')
            fi            
            l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")
            ;;

        neovim)
            #Si no esta instalado 'jq' no continuar
            if ! command -v jq &> /dev/null; then
                return 1
            fi
            
            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://github.com/${p_repo_name}/releases/latest" | jq -r '.tag_name')

            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            l_aux=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | jq -r '.body' | head -n 2 | tail -1)
            if [ $? -eq 0 ]; then
                l_repo_last_version_pretty=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")
            else                                
                l_repo_last_version_pretty=""
            fi
            ;;

        nodejs)
            #Si no esta instalado 'jq' no continuar
            if ! command -v jq &> /dev/null; then
                return 1
            fi
            
            #Usando JSON para obtener la ultima version
            l_aux=$(curl -Ls "https://nodejs.org/dist/index.json" | jq -r 'first(.[] | select(.lts != false)) | "\(.version)"' 2> /dev/null)

            if [ $? -eq 0 ]; then
                l_repo_last_version="$l_aux"
                l_repo_last_version_pretty=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")
            else
                l_repo_last_version=""        
                l_repo_last_version_pretty=""
            fi
            ;;

       less)
            #Si no esta instalado 'jq' no continuar
            if ! command -v jq &> /dev/null; then
                return 1
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://github.com/${p_repo_name}/releases/latest" | jq -r '.tag_name')
            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            #l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | jq -r '.tag_name')

            l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version4")
           ;;

        graalvm)
            #Si no esta instalado 'jq' no continuar
            if ! command -v jq &> /dev/null; then
                return 1
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://github.com/${p_repo_name}/releases/latest" | jq -r '.tag_name')
            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            #l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | jq -r '.tag_name')

            l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")
            l_arti_subversion_versions=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | jq -r '.assets[].name' | \
                grep -e '^graalvm-community-jdk-.*_linux-x64_bin\.tar\.gz$' | sed -e 's/graalvm-community-jdk-\(.*\)_linux-x64_bin.*/\1/' | sort -r)

            #l_arti_subversion_versions=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | jq -r '.assets[].name' | \
            #   grep -e '^graalvm-ce-java.*-linux-amd64-.*\.tar\.gz$' | sed -e 's/graalvm-ce-java\(.*\)-linux-amd64-.*/\1/' | sort -r)

            #Si solo tiene uns subversion y es la misma que la version, no existe subversiones
            if [ "$l_repo_last_version_pretty" = "$l_arti_subversion_versions" ]; then
                l_arti_subversion_versions=""
            fi

            ;;

        #crictl)
        #    #Obtener una ultima version que sea compatible con la version actual de kubelet, kubeadm
        #    ;;

        *)
            #Si no esta instalado 'jq' no continuar
            if ! command -v jq &> /dev/null; then
                return 1
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://github.com/${p_repo_name}/releases/latest" | jq -r '.tag_name')
            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            #l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | jq -r '.tag_name')
            
            if [ "$p_repo_id" = "netcoredbg" ]; then
                l_aux="${l_repo_last_version//-/.}"
            else
                l_aux="$l_repo_last_version"
            fi

            l_repo_last_version_pretty=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")
            ;;
    esac

    #Codificar en base64
    l_aux=$(url_encode "$l_repo_last_version")
    pna_repo_versions=("$l_aux" "$l_repo_last_version_pretty")
    pna_arti_subversion_versions=(${l_arti_subversion_versions})
    return 0
}


#}}}


#Funciones modificables (Nive 1) {{{


#Determinar la version actual del repositorio usado para instalar los comandos instalados:
#  0 - Si existe y se obtiene un valor
#  1 - El comando no existe o existe un error en el comando para obtener la versión
#  2 - La version obtenida no tiene formato valido
#  3 - No existe forma de calcular la version actual (siempre se instala y/o actualizar)
#  9 - No esta implementado un metodo de obtener la version
function _get_repo_current_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_install_win_cmds=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$2" = "0" ]; then
        p_install_win_cmds=0
    fi

    local p_path_file="$3"              #Ruta donde se obtendra el comando para obtener la versión
                                        #es usado para programas que deben ser descargados para recien obtener la ultima versión.

    #2. Obtener la version actual
    local l_sustitution_regexp="$g_regexp_sust_version1"
    local l_repo_current_version=""
    local l_tmp=""
    local l_status=0
    #local l_aux=""

    #Calcular la ruta de archivo/comando donde se obtiene la version (esta ruta termina en "/")
    local l_path_file="" 
    if [ -z "$p_path_file" ]; then
        if [ $p_install_win_cmds -eq 0 ]; then
            l_path_file="${g_path_bin_win}/"
        else
            l_path_file=""
        fi
    else
        l_path_file="${p_path_file}/"
    fi

    case "$p_repo_id" in

        jq)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}jq.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}jq --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        yq)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}yq.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_files}yq --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        fzf)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}fzf.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}fzf --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        helm)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}helm.exe version --short 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}helm version --short 2> /dev/null)
                l_status=$?
            fi
            ;;

        delta)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}delta.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}delta --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                #l_tmp=$(echo "$l_tmp" | tr '\n' '' | cut -d ' ' -f 2)
                l_tmp=$(echo "$l_tmp" | cut -d ' ' -f 2 | head -n 1)
            fi
            ;;
        ripgrep)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}rg.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}rg --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;
        xsv)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}xsv.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}xsv --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;
        bat)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}bat.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}bat --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        oh-my-posh)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}oh-my-posh.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}oh-my-posh --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        fd)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}fd.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}fd --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        less)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}less.exe --version 2> /dev/null)
                l_status=$?
            else
                return 9;
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                l_sustitution_regexp="$g_regexp_sust_version3"
            fi
            ;;
        jwt)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}jwt.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}jwt --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        step)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}step.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}step --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                #l_sustitution_regexp="$g_regexp_sust_version3"
            fi
            ;;

        protoc)
           
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/ProtoC/bin/"
               else
                  l_path_file="${g_path_programs}/protoc/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}protoc.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}protoc --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        grpcurl)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}grpcurl.exe --version 2>&1)
                l_status=$?
            else
                l_tmp=$(${l_path_file}grpcurl --version 2>&1)
                l_status=$?
            fi

            if [ $l_status -ne 0 ]; then
                l_tmp=""
            fi
            ;;

        evans)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}evans.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}evans --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        kubectl)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}kubectl.exe version --client=true -o json 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}kubectl version --client=true -o json 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | jq -r '.clientVersion.gitVersion' 2> /dev/null)
                if [ $? -ne 0 ]; then
                    return 9;
                fi
            fi
            ;;

        kubelet)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}kubelet --version 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                #l_sustitution_regexp="$g_regexp_sust_version3"
            fi
            ;;

        kubeadm)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}kubeadm version -o json 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | jq -r '.clientVersion.gitVersion' 2> /dev/null)
                if [ $? -ne 0 ]; then
                    return 9;
                fi
            fi
            ;;

        operator-sdk)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            else
                l_tmp=$(${l_path_file}operator-sdk version 2> /dev/null)
                l_status=$?
            fi
            ;;

        3scale-toolbox)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            else
                l_tmp=$(${l_path_file}3scale --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        pgo)

            if [ $p_install_win_cmds -eq 0 ]; then
                if [ -f "${g_path_programs_win}/pgo.info" ]; then
                    l_tmp=$(cat "${g_path_programs_win}/pgo.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
            else
                if [ -f "${g_path_programs}/pgo.info" ]; then
                    l_tmp=$(cat "${g_path_programs}/pgo.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
            fi
            ;;

        k0s)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}k0s.exe version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}k0s version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | cut -d ' ' -f 2 | head -n 1)
            fi
            ;;

        roslyn)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/LSP_Servers/Omnisharp_Roslyn/"
               else
                  l_path_file="${g_path_programs}/lsp_servers/omnisharp_roslyn/"
               fi
            fi

            #Obtener la version
            if [ -f "${l_path_file}OmniSharp.deps.json" ]; then
                l_tmp=$(jq -r '.targets[][].dependencies."OmniSharp.Stdio"' "${l_path_file}OmniSharp.deps.json" | grep -v "null" | head -n 1 2> /dev/null)
                l_status=$?
            else
                l_status=1
            fi
            ;;

        netcoredbg)
            
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/DAP_Servers/NetCoreDbg/"
               else
                  l_path_file="${g_path_programs}/dap_servers/netcoredbg/"
               fi
            fi

            #Obtener la version
            if [ -f "${l_path_file}netcoredbg.info" ]; then
                l_tmp=$(cat "${l_path_file}netcoredbg.info" | head -n 1)
            else
                if [ $p_install_win_cmds -eq 0 ]; then
                    l_tmp=$(${l_path_file}netcoredbg.exe --version 2> /dev/null)
                    l_status=$?
                else
                    l_tmp=$(${l_path_file}netcoredbg --version 2> /dev/null)
                    l_status=$?
                fi
                if [ $l_status -eq 0 ]; then
                    l_tmp=$(echo "$l_tmp" | head -n 1)
                    l_sustitution_regexp="$g_regexp_sust_version2"
                fi
            fi
            l_tmp=${l_tmp//-/.}
            ;;

        neovim)
           
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/NeoVim/bin/"
               else
                  l_path_file="${g_path_programs}/neovim/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}nvim.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}nvim --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        nodejs)
           
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/NodeJS/"
               else
                  l_path_file="${g_path_programs}/nodejs/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}node.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}node --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        nerd-fonts)
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ -f "${g_path_programs_win}/nerd-fonts.info" ]; then
                    l_tmp=$(cat "${g_path_programs_win}/nerd-fonts.info" | head -n 1)
                else
                    #Siempre se actualizara la fuentes, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
            else
                if [ -f "${g_path_programs}/nerd-fonts.info" ]; then
                    l_tmp=$(cat "${g_path_programs}/nerd-fonts.info" | head -n 1)
                else
                    #Siempre se actualizara la fuentes, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
            fi
            ;;

        go)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/Go/bin/"
               else
                  l_path_file="${g_path_programs}/go/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}go.exe version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}go version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


       net-sdk)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/DotNet/"
               else
                  l_path_file="${g_path_programs}/dotnet/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}dotnet.exe --list-sdks version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}dotnet --list-sdks version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                l_tmp=$(echo "$l_tmp" | sort -r | head -n 1)
            fi
            ;;


       net-rt-core|net-rt-aspnet)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/DotNet/"
               else
                  l_path_file="${g_path_programs}/dotnet/"
               fi
            fi

            #Si esta instalado SDK, no instalarlo
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}dotnet.exe --list-sdks version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}dotnet --list-sdks version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -ne 0 ] || [ -z "$l_tmp" ]; then
                return 9
            fi


            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}dotnet.exe --list-runtimes version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}dotnet --list-runtimes version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then

                if [ "$p_repo_id" = "net-rt-core" ]; then

                    l_tmp=$(echo "$l_tmp" | grep 'Microsoft.NETCore.App' | sort -r | head -n 1)
                    l_status=$?
                    if [ $l_status -ne 0 ]; then
                        l_tmp=""
                    fi

                else
                    l_tmp=$(echo "$l_tmp" | grep 'Microsoft.AspNetCore.App' | sort -r | head -n 1)
                    l_status=$?
                    if [ $l_status -ne 0 ]; then
                        l_tmp=""
                    fi

                fi

            fi
            ;;


        llvm)

            #No habilitado para Windows
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               l_path_file="${g_path_programs}/llvm/bin/"
            fi

            #Obtener la version
            l_tmp=$(${l_path_file}clang --version 2> /dev/null)
            l_status=$?

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;


        clangd)

            #Solo habilitado para Windows, en Linux esta incluido en LLVM
            if [ $p_install_win_cmds -ne 0 ]; then
                return 9
            fi

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/LSP_Servers/CLangD/bin/"
               else
                  l_path_file="${g_path_programs}/lsp_servers/clangd/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}clangd.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}clangd --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;

        cmake)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/CMake/bin/"
               else
                  l_path_file="${g_path_programs}/cmake/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}cmake.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}cmake --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        ninja)

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}ninja.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}ninja --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        powershell)
            
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/PowerShell/"
               else
                  l_path_file="${g_path_programs}/powershell/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}pwsh.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}pwsh --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        rust-analyzer)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/LSP_Servers/Rust_Analyzer/"
               else
                  l_path_file="${g_path_programs}/lsp_servers/rust_analyzer/"
               fi
            fi

            #Obtener la version
            if [ -f "${l_path_file}rust-analyzer.info" ]; then
                l_tmp=$(cat "${l_path_file}rust-analyzer.info" | head -n 1)
            else
                if [ $p_install_win_cmds -eq 0 ]; then
                    l_tmp=$(${l_path_file}rust-analyzer.exe --version 2> /dev/null)
                    l_status=$?
                else
                    l_tmp=$(${l_path_file}rust-analyzer --version 2> /dev/null)
                    l_status=$?
                fi

                if [ $l_status -eq 0 ]; then
                    l_tmp=$(echo "$l_tmp" | head -n 1)
                fi
            fi
            ;;

        graalvm)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/GraalVM/bin/"
               else
                  l_path_file="${g_path_programs}/graalvm/bin/"
               fi
            fi

            #Obtener la version (no usar la opcion '-version' pues este envia la info al flujo de error estandar)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}java.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}java --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | grep GraalVM | head -n 1)
            fi
            ;;

        jdtls)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/LSP_Servers/JDT_LS/"
               else
                  l_path_file="${g_path_programs}/lsp_servers/jdt_ls/"
               fi
            fi

            #Obtener la version
            l_tmp=$(find ${l_path_file}plugins -maxdepth 1 -mindepth 1 -name 'org.eclipse.jdt.ls.core_*.jar' 2> /dev/null)
            l_status=$?

            if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                #Eliminar la ruta relativa
                l_tmp=${l_tmp##*/}
                #Eliminar la extensión
                l_tmp=${l_tmp%.jar}
            fi
            ;;

        butane)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}butane --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        runc)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}runc --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        crun)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}crun --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        fuse-overlayfs)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}fuse-overlayfs --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | grep fuse-overlayfs)
            fi
            ;;


        cni-plugins)
            
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            if [ -f "${g_path_programs}/cni-plugins.info" ]; then
                l_tmp=$(cat "${g_path_programs}/cni-plugins.info" | head -n 1)
            else

                #Calcular la ruta de archivo/comando donde se obtiene la version
                if [ -z "$p_path_file" ]; then
                    l_path_file="${g_path_programs}/cni_plugins/"
                fi

                #CNI vlan plugin v1.2.0
                l_tmp=$(${l_path_file}vlan --version 2> /dev/null)
                l_status=$?
            
                if [ $l_status -eq 0 ]; then
                    l_tmp=$(echo "$l_tmp" | head -n 1)
                fi            
            fi
            ;;


        slirp4netns)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}slirp4netns --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                l_sustitution_regexp="$g_regexp_sust_version5"
            fi
            ;;


        bypass4netns)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}bypass4netns --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                l_sustitution_regexp="$g_regexp_sust_version5"
            fi
            ;;



        rootlesskit)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}rootlesskit --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        containerd)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #containerd github.com/containerd/containerd v1.6.20 2806fc1057397dbaeefbea0e4e17bddfbd388f38
            l_tmp=$(${l_path_file}containerd --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        nerdctl)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #nerdctl version 1.3.1
            l_tmp=$(${l_path_file}nerdctl --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        buildkit)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #buildctl github.com/moby/buildkit v0.11.5 252ae63bcf2a9b62777add4838df5a257b86e991
            l_tmp=$(${l_path_file}buildkitd --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        dive)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #dive 0.10.0
            l_tmp=$(${l_path_file}dive --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        crictl)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}crictl --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        *)
            return 9
            ;;
    esac

    #Si el comando de obtener la version obtuvo error
    if [ $l_status -ne 0 ]; then
        return 1
    fi

    #Si el comando no devolvio resultado valido
    if [ -z "$l_tmp" ]; then
        return 2
    fi

    #Solo obtiene la 1ra cadena que este formado por caracteres 0-9 y .
    l_repo_current_version=$(echo "$l_tmp" | sed "$l_sustitution_regexp")
    echo "$l_repo_current_version"

    if [[ ! "$l_repo_current_version" == [0-9]* ]]; then
        return 2
    fi
    return 0

}


#Validar si una subversion de un repositorio esta instalada
#Parametros de salida:
#  > Valor de retorno:
#    0 - Esta instalado (Existe)
#    1 - NO esta instalado (No existe)
function is_installed_repo_subversion()
{
    local p_repo_id="$1"
    local p_arti_subversion_version="$2"
    local p_install_win_cmds=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #Por defecto las subversiones de un repositorio no esta intalado
    local l_is_instelled=1
    local l_status

    #Indicar si alguna subversion ya esta instalado
    case "$p_repo_id" in

        net-sdk|net-rt-core|net-rt-aspnet)

            #Validar que existe la version no esta instalado
            _dotnet_exist_version "$p_repo_id" "$p_arti_subversion_version" $p_install_win_cmds
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_is_instelled=0
            fi
            ;;
    
    esac

    return $l_is_instelled

}

#Devuelve un arreglo de artefectos, usando los argumentos 3 y 4 como de referencia:
#  5> Un arrego de bases URL del los artefactos. 
#     Si el repositorio tiene muchos artefactos pero todos tiene la misma URL base, puede indicar
#     solo una URL, para los demas se repitira el mismo valor
#  6> Un arreglo de tipo de artefacto donde cada item puede ser:
#     Un archivo no comprimido
#       >  0 si es un binario o archivo no empaquetado o comprimido
#       >  1 si es un package
#     Comprimidos no tan pesados (se descomprimen y copian en el lugar deseado)
#       > 10 si es un .tar.gz
#       > 11 si es un .zip
#       > 12 si es un .gz
#       > 13 si es un .tgz
#       > 14 si es un .tar.xz
#     Comprimidos muy pesados (se descomprimen directamente en el lugar deseado)
#       > 20 si es un .tar.gz
#       > 21 si es un .zip
#       > 22 si es un .gz
#       > 23 si es un .tgz
#       > 24 si es un .tar.xz
#     No definido
#       > 99 si no se define el artefacto para el prefijo
#  7> Un arreglo de nombre de los artectos a descargar
#En el argumento 2 se debe pasar la version pura quitando, sin contener "v" u otras letras iniciales
function get_repo_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
    local p_repo_last_version_pretty="$4"
    declare -n pna_artifact_baseurl=$5   #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_artifact_names=$6     #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_artifact_types=$7     #Parametro por referencia: Se devuelve un arreglo de los tipos de los artefactos
    local p_arti_subversion_version="$8"
    local p_install_win_cmds=1         #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                       #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$9" = "0" ]; then
        p_install_win_cmds=0
    fi
    
    #Si se estan instalando (la primera vez) es '0', caso contrario es otro valor (se actualiza o se desconoce el estado)
    local p_flag_install=1
    if [ "${10}" = "0" ]; then
        p_flag_install=0
    fi

    #2. Generar el nombre
    local l_artifact_name=""
    local l_artifact_type=99
    local l_status

    #URL base por defecto a usar
    #URL base fijo     :  Usuarlmente "https://github.com"
    local l_base_url_fixed=$(_get_repo_base_url "$p_repo_id")
    #URL base variable :
    local l_base_url_variable="${p_repo_name}/releases/download/${p_repo_last_version}"

    case "$p_repo_id" in

        net-sdk|net-rt-core|net-rt-aspnet)

            #Prefijo del nombre del artefacto
            local l_prefix_repo='dotnet-sdk'
            if [ "p_repo_id" = "net-rt-core" ]; then
                l_prefix_repo='dotnet-runtime'
            elif [ "p_repo_id" = "net-rt-aspnet" ]; then
                l_prefix_repo='aspnetcore-runtime'
            fi

            #Si no existe subversiones un repositorio
            if [ -z "$p_arti_subversion_version" ]; then

                #URL base fijo     : "https://dotnetcli.azureedge.net"
                #URL base variable :
                l_base_url_variable="${p_repo_name}/${p_repo_last_version}"

                #Generar la URL con el artefactado:
                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
                if [ $p_install_win_cmds -eq 0 ]; then
                    pna_artifact_names=("${l_prefix_repo}-${p_repo_last_version_pretty}-win-x64.zip")
                    pna_artifact_types=(11)
                else
                    #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                    if [ $g_os_subtype_id -eq 1 ]; then
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_version_pretty}-linux-musl-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_version_pretty}-linux-musl-x64.tar.gz")
                        fi
                    else
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_version_pretty}-linux-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_version_pretty}-linux-x64.tar.gz")
                        fi
                    fi
                    pna_artifact_types=(10)
                fi

            #Si existe subversiones en un repositorios
            else

                #URL base fijo     : "https://dotnetcli.azureedge.net"
                #URL base variable :
                l_base_url_variable="${p_repo_name}/${p_arti_subversion_version}"

                #Generar la URL con el artefactado:
                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
                if [ $p_install_win_cmds -eq 0 ]; then
                    pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-win-x64.zip")
                    pna_artifact_types=(11)
                else
                    #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                    if [ $g_os_subtype_id -eq 1 ]; then
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-musl-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-musl-x64.tar.gz")
                        fi
                    else
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-x64.tar.gz")
                        fi
                    fi
                    pna_artifact_types=(10)
                fi

            fi
            ;;


        crictl)
            
            #No soportado para Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("crictl-v${p_repo_last_version_pretty}-linux-arm64.tar.gz" "critest-v${p_repo_last_version_pretty}-linux-arm64.tar.gz")
                pna_artifact_types=(10 10)
            else
                pna_artifact_names=("crictl-v${p_repo_last_version_pretty}-linux-amd64.tar.gz" "critest-v${p_repo_last_version_pretty}-linux-amd64.tar.gz")
                pna_artifact_types=(10 10)
            fi
            ;;

        jq)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("jq-windows-amd64.exe")
                pna_artifact_types=(0)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("jq-linux-arm64")
                else
                    pna_artifact_names=("jq-linux-amd64")
                fi
                pna_artifact_types=(0)
            fi
            ;;
        yq)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("yq_windows_amd64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("yq_linux_arm64.tar.gz")
                else
                    pna_artifact_names=("yq_linux_amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;
        fzf)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("fzf-${p_repo_last_version_pretty}-windows_amd64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("fzf-${p_repo_last_version_pretty}-linux_arm64.tar.gz")
                else
                    pna_artifact_names=("fzf-${p_repo_last_version_pretty}-linux_amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        helm)
            #URL base fijo     : "https://get.helm.sh"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("helm-v${p_repo_last_version_pretty}-windows-amd64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("helm-v${p_repo_last_version_pretty}-linux-arm64.tar.gz")
                else
                    pna_artifact_names=("helm-v${p_repo_last_version_pretty}-linux-amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;
        delta)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("delta-${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("delta-${p_repo_last_version_pretty}-aarch64-unknown-linux-gnu.tar.gz")
                else
                    pna_artifact_names=("delta-${p_repo_last_version_pretty}-x86_64-unknown-linux-gnu.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;
        ripgrep)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("ripgrep-${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("ripgrep-${p_repo_last_version_pretty}-aarch64-unknown-linux-gnu.tar.gz")
                else
                    pna_artifact_names=("ripgrep-${p_repo_last_version_pretty}-x86_64-unknown-linux-musl.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;
        xsv)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("xsv-${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("xsv-${p_repo_last_version_pretty}-x86_64-unknown-linux-musl.tar.gz")
                pna_artifact_types=(10)
            fi
            ;;
        bat)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("bat-v${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("bat-v${p_repo_last_version_pretty}-aarch64-unknown-linux-gnu.tar.gz")
                else
                    pna_artifact_names=("bat-v${p_repo_last_version_pretty}-x86_64-unknown-linux-gnu.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;
        oh-my-posh)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("posh-windows-amd64.exe" "themes.zip")
                pna_artifact_types=(0 11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("posh-linux-arm64" "themes.zip")
                else
                    pna_artifact_names=("posh-linux-amd64" "themes.zip")
                fi
                pna_artifact_types=(0 11)
            fi
            ;;
        fd)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("fd-v${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("fd-v${p_repo_last_version_pretty}-aarch64-unknown-linux-gnu.tar.gz")
                else
                    pna_artifact_names=("fd-v${p_repo_last_version_pretty}-x86_64-unknown-linux-gnu.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        jwt)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("jwt-windows.tar.gz")
                pna_artifact_types=(10)
            else
                pna_artifact_names=("jwt-linux.tar.gz")
                pna_artifact_types=(10)
            fi
            ;;

        step)
            #URL base fijo     : "https://dl.smallstep.com/gh-release/cli/gh-release-header"
            #URL base variable :
            l_base_url_variable="${p_repo_last_version}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("step_windows_${p_repo_last_version_pretty}_amd64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("step_linux_${p_repo_last_version_pretty}_arm64.tar.gz")
                else
                    pna_artifact_names=("step_linux_${p_repo_last_version_pretty}_amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        protoc)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("protoc-${p_repo_last_version_pretty}-win64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("protoc-${p_repo_last_version_pretty}-linux-aarch_64.zip")
                else
                    pna_artifact_names=("protoc-${p_repo_last_version_pretty}-linux-x86_64.zip")
                fi
                pna_artifact_types=(11)
            fi
            ;;

        grpcurl)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("grpcurl_${p_repo_last_version_pretty}_windows_x86_64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("grpcurl_${p_repo_last_version_pretty}_linux_arm64.tar.gz")
                else
                    pna_artifact_names=("grpcurl_${p_repo_last_version_pretty}_linux_x86_64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        nodejs)
            #URL base fijo     : "https://nodejs.org/dist"
            #URL base variable :
            l_base_url_variable="${p_repo_last_version}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("node-v${p_repo_last_version_pretty}-win-x64.zip")
                pna_artifact_types=(21)
                #pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("node-v${p_repo_last_version_pretty}-linux-arm64.tar.xz")
                    pna_artifact_types=(24)
                    #pna_artifact_types=(14)
                else
                    pna_artifact_names=("node-v${p_repo_last_version_pretty}-linux-x64.tar.gz")
                    pna_artifact_types=(20)
                    #pna_artifact_types=(10)
                fi
            fi
            ;;

        evans)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("evans_windows_amd64.tar.gz")
                pna_artifact_types=(10)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("evans_linux_arm64.tar.gz")
                else
                    pna_artifact_names=("evans_linux_amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        kubectl)
            #URL base fijo     : "https://dl.k8s.io/release"
            #URL base variable :
            if [ $p_install_win_cmds -eq 0 ]; then
                l_base_url_variable="${p_repo_last_version}/bin/windows/amd64"
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    l_base_url_variable="${p_repo_last_version}/bin/linux/arm64"
                else
                    l_base_url_variable="${p_repo_last_version}/bin/linux/amd64"
                fi
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("kubectl.exe")
                pna_artifact_types=(0)
            else
                pna_artifact_names=("kubectl")
                pna_artifact_types=(0)
            fi
            ;;

        kubelet)
            #URL base fijo     : "https://dl.k8s.io/release"
            #URL base variable :
            if [ $p_install_win_cmds -eq 0 ]; then
                l_base_url_variable="${p_repo_last_version}/bin/windows/amd64"
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    l_base_url_variable="${p_repo_last_version}/bin/linux/arm64"
                else
                    l_base_url_variable="${p_repo_last_version}/bin/linux/amd64"
                fi
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            else
                pna_artifact_names=("kubelet")
                pna_artifact_types=(0)
            fi
            ;;

        kubeadm)
            #URL base fijo     : "https://dl.k8s.io/release"
            #URL base variable :
            if [ $p_install_win_cmds -eq 0 ]; then
                l_base_url_variable="${p_repo_last_version}/bin/windows/amd64"
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    l_base_url_variable="${p_repo_last_version}/bin/linux/arm64"
                else
                    l_base_url_variable="${p_repo_last_version}/bin/linux/amd64"
                fi
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            else
                pna_artifact_names=("kubeadm")
                pna_artifact_types=(0)
            fi
            ;;

        pgo)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("kubectl-pgo-windows-386")
                pna_artifact_types=(0)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("kubectl-pgo-linux-arm64")
                else
                    pna_artifact_names=("kubectl-pgo-linux-amd64")
                fi
                pna_artifact_types=(0)
            fi
            ;;

        less)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("less-x64.zip")
                pna_artifact_types=(11)
            else
                return 1
            fi
            ;;
        k0s)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("k0s-v${p_repo_last_version_pretty}+k0s.0-amd64.exe")
                pna_artifact_types=(0)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("k0s-v${p_repo_last_version_pretty}+k0s.0-arm64")
                else
                    pna_artifact_names=("k0s-v${p_repo_last_version_pretty}+k0s.0-amd64")
                fi
                pna_artifact_types=(0)
            fi
            ;;

        operator-sdk)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("operator-sdk_linux_arm64" "helm-operator_linux_arm64")
                else
                    pna_artifact_names=("operator-sdk_linux_amd64" "helm-operator_linux_amd64")
                fi
                pna_artifact_types=(0 0)
            fi
            ;;

        roslyn)

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("omnisharp-win-x64-net6.0.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("omnisharp-linux-musl-arm64-net6.0.tar.gz")
                    else
                        pna_artifact_names=("omnisharp-linux-musl-x64-net6.0.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("omnisharp-linux-arm64-net6.0.tar.gz")
                    else
                        pna_artifact_names=("omnisharp-linux-x64-net6.0.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;
        netcoredbg)

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("netcoredbg-win64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("netcoredbg-linux-arm64.tar.gz")
                else
                    pna_artifact_names=("netcoredbg-linux-amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;
        neovim)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("nvim-win64.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("nvim-linux64.tar.gz")
                pna_artifact_types=(10)
            fi
            ;;
        nerd-fonts)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            pna_artifact_names=("JetBrainsMono.zip" "CascadiaCode.zip" "DroidSansMono.zip"
                                "InconsolataLGC.zip" "UbuntuMono.zip" "3270.zip")
            pna_artifact_types=(11 11 11 11 11 11)
            ;;

        go)
            #URL base fijo     : "https://storage.googleapis.com"
            #URL base variable :
            l_base_url_variable="${p_repo_name}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("go${p_repo_last_version_pretty}.windows-amd64.zip")
                pna_artifact_types=(21)
                #pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("go${p_repo_last_version_pretty}.linux-arm64.tar.gz")
                else
                    pna_artifact_names=("go${p_repo_last_version_pretty}.linux-amd64.tar.gz")
                fi
                pna_artifact_types=(20)
                #pna_artifact_types=(10)
            fi
            ;;

        llvm)

            #Solo para Linux
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("clang+llvm-${p_repo_last_version_pretty}-aarch64-linux-gnu.tar.xz")
                #pna_artifact_types=(14)
                pna_artifact_types=(24)
            else
                #TODO obtener el nombre dinamicamente
                pna_artifact_names=("clang+llvm-${p_repo_last_version_pretty}-x86_64-linux-gnu-ubuntu-22.04.tar.xz")
                #pna_artifact_types=(14)
                pna_artifact_types=(24)
            fi
            ;;

        clangd)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("clangd-windows-${p_repo_last_version_pretty}.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("clangd-linux-${p_repo_last_version_pretty}.zip")
                pna_artifact_types=(11)
            fi
            ;;

        cmake)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("cmake-${p_repo_last_version#v}-windows-x86_64.zip")
                pna_artifact_types=(21)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("cmake-${p_repo_last_version#v}-linux-aarch64.tar.gz")
                else
                    pna_artifact_names=("cmake-${p_repo_last_version#v}-linux-x86_64.tar.gz")
                fi
                pna_artifact_types=(20)
            fi
            ;;

        ninja)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("ninja-win.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("ninja-linux.zip")
                pna_artifact_types=(11)
            fi
            ;;

        powershell)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("PowerShell-${p_repo_last_version_pretty}-win-x64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("powershell-${p_repo_last_version_pretty}-linux-arm64.tar.gz")
                else
                    pna_artifact_names=("powershell-${p_repo_last_version_pretty}-linux-x64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        3scale-toolbox)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -ne 0 ]; then
                #Si es de la familia Debian
                if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
                    pna_artifact_names=("3scale-toolbox_${p_repo_last_version_pretty}-1_amd64.deb")
                    pna_artifact_types=(1)
                #Si es de la familia Fedora
                elif [ $g_os_subtype_id -ge 10 ] && [ $g_os_subtype_id -lt 30 ]; then
                    pna_artifact_names=("3scale-toolbox_${p_repo_last_version_pretty}-1.el8.x86_64.rpm")
                    pna_artifact_types=(1)
                else
                    #No soportato en esta distribución Linux
                    return 1
                fi
            else
                #No se instala nada en Windows
                return 1
            fi
            ;;

        rust-analyzer)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("rust-analyzer-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("rust-analyzer-aarch64-unknown-linux-gnu.gz")
                else
                    pna_artifact_names=("rust-analyzer-x86_64-unknown-linux-gnu.gz")
                fi
                pna_artifact_types=(12)
            fi
            ;;

        graalvm)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

            #JDK 21, esta diseñando una nueva forma de instalar plugins a GraalVM, dejando de usar 'GraalVM Updater'

            #Si no existe subversiones un repositorio
            if [ -z "$p_arti_subversion_version" ]; then
                if [ $p_install_win_cmds -eq 0 ]; then
                    pna_artifact_names=("graalvm-community-jdk-${p_repo_last_version_pretty}_windows-x64_bin.zip")
                    pna_artifact_types=(21)
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("graalvm-community-jdk-${p_repo_last_version_pretty}_linux-aarch64_bin.tar.gz")
                    else
                        pna_artifact_names=("graalvm-community-jdk-${p_repo_last_version_pretty}_linux-x64_bin.tar.gz")
                    fi
                    pna_artifact_types=(20)
                fi
            #Si existe subversiones en el repositorio
            #TODO Corregir las URLs
            else
                if [ $p_install_win_cmds -eq 0 ]; then
                    pna_artifact_names=("graalvm-ce-java${p_arti_subversion_version}-windows-amd64-${p_repo_last_version_pretty}.zip")
                    pna_artifact_types=(21)
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("graalvm-ce-java${p_arti_subversion_version}-linux-aarch64-${p_repo_last_version_pretty}.tar.gz")
                    else
                        pna_artifact_names=("graalvm-ce-java${p_arti_subversion_version}-linux-amd64-${p_repo_last_version_pretty}.tar.gz")
                    fi
                    pna_artifact_types=(20)
                fi
            fi
            ;;
        
        jdtls)
            #URL base fijo     : "https://download.eclipse.org"
            #URL base variable :
            l_base_url_variable="${p_repo_name}/snapshots"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            pna_artifact_names=("jdt-language-server-${p_repo_last_version}.tar.gz")
            pna_artifact_types=(10)
            ;;

        butane)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("butane-aarch64-unknown-linux-gnu")
            else
                pna_artifact_names=("butane-x86_64-unknown-linux-gnu")
            fi
            pna_artifact_types=(0)
            ;;

        runc)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("runc.arm64")
            else
                pna_artifact_names=("runc.amd64")
            fi
            pna_artifact_types=(0)
            ;;

        crun)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("crun-${p_repo_last_version}-linux-arm64")
            else
                pna_artifact_names=("crun-${p_repo_last_version}-linux-amd64")
            fi
            pna_artifact_types=(0)
            ;;

        fuse-overlayfs)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("fuse-overlayfs-aarch64")
            else
                pna_artifact_names=("fuse-overlayfs-x86_64")
            fi
            pna_artifact_types=(0)
            ;;

        cni-plugins)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("cni-plugins-linux-arm64-${p_repo_last_version}.tgz")
            else
                pna_artifact_names=("cni-plugins-linux-amd64-${p_repo_last_version}.tgz")
            fi
            pna_artifact_types=(13)
            ;;

        slirp4netns)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("slirp4netns-aarch64")
            else
                pna_artifact_names=("slirp4netns-x86_64")
            fi
            pna_artifact_types=(0)
            ;;

        rootlesskit)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("rootlesskit-aarch64.tar.gz")
            else
                pna_artifact_names=("rootlesskit-x86_64.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;

        containerd)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("containerd-${p_repo_last_version_pretty}-linux-arm64.tar.gz")
            else
                pna_artifact_names=("containerd-${p_repo_last_version_pretty}-linux-amd64.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;

        buildkit)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            pna_artifact_names=("buildkit-${p_repo_last_version}.linux-amd64.tar.gz")
            pna_artifact_types=(10)
            ;;

        nerdctl)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("nerdctl-${p_repo_last_version_pretty}-linux-arm64.tar.gz" "nerdctl-full-${p_repo_last_version_pretty}-linux-arm64.tar.gz")
            else
                pna_artifact_names=("nerdctl-${p_repo_last_version_pretty}-linux-amd64.tar.gz" "nerdctl-full-${p_repo_last_version_pretty}-linux-amd64.tar.gz")
            fi
            pna_artifact_types=(10 10)
            ;;


        dive)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("dive_${p_repo_last_version_pretty}_linux_arm64.tar.gz")
            else
                pna_artifact_names=("dive_${p_repo_last_version_pretty}_linux_amd64.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;



        *)
           return 1
           ;;
    esac

    return 0
}



#Parametros de entrada (argumentos y opciones):
#   1 > Nombre del repo donde se encuentra la logica para obtener la versión del comando.
#   2 > Ruta donde desea obtener la versión a comparar con la actual (no debe termina en '/').
#   3 > El flag sera '0' si es comando de windows (vinculado a WSL2), caso contraro es Linux.
#Parametros de salida (valor de retorno):
#   9 > Si el comando de la version actual aun no existe (no esta configurado o instalado).
#   8 > Si el comando de la especificada como parametro aun no existe.
#   0 > si la versión actual = versión especificada como parametro.
#   1 > si la versión actual > versión especificada como parametro.
#   2 > si la versión actual < versión especificada como parametro.
_compare_version_current_with() {

    #1. Argumentos
    local p_repo_id=$1
    local p_path="$2/"
    local p_install_win_cmds=1
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    printf "Comparando versiones de '%s': \"Versión actual\" vs \"Versión ubica en '%s'\"...\n" "$p_repo_id" "$p_path"

    #2. Obteniendo la versión actual
    local l_current_version
    l_current_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds})

    local l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '   No se puede obtener la versión actual de "%s" (status: %s)\n' "$p_repo_id" "$l_status"
        return 9
    fi

    #3. Obteniendo la versión de lo especificado como parametro
    local l_other_version
    l_other_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "$p_path")

    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '   No se puede obtener la versión de "%s" ubicada en "%s" (status: %s)\n' "$p_repo_id" "$p_path" "$l_status"
        return 8
    fi

    #4. Comparando ambas versiones
    compare_version "$l_current_version" "$l_other_version"
    l_status=$?

    if [ $l_status -eq 0 ]; then

        printf '   La versión actual "%s" ya esta actualizado %b(= "%s" que es la versión ubicada en "%s")%b\n' "$l_current_version" "$g_color_opaque" \
               "$l_other_version" "$p_path" "$g_color_reset"

    elif [ $l_status -eq 1 ]; then

        printf '   La versión actual "%s" ya esta actualizado %b(> "%s" que es la versión ubicada en "%s")%b\n' "$l_current_version" "$g_color_opaque" \
               "$l_other_version" "$p_path" "$g_color_reset"


    else

        printf '   La versión actual "%s" requiere ser actualizado %b(= "%s" que es la versión ubicada en "%s")%b\n' "$l_current_version" "$g_color_opaque" \
               "$l_other_version" "$p_path" "$g_color_reset"

    fi

    return $l_status


}


function _copy_artifact_files() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_artifact_index="$2"
    local p_artifact_name="$3"
    local p_artifact_name_woext="$4"
    local p_artifact_type=$5

    local p_install_win_cmds=1           #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                         #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$6" = "0" ]; then
        p_install_win_cmds=0
    fi

    local p_repo_current_version="$7"
    local p_repo_last_version="$8"
    local p_repo_last_version_pretty="$9"
    local p_artifact_is_last=${10}

    local p_arti_subversion_version="${11}"
    local p_arti_subversion_index=0
    if [[ "${12}" =~ ^[0-9]+$ ]]; then
        p_arti_subversion_index=${12}
    fi

    #Tag usuado para imprimir un identificador del artefacto en un log
    local l_tag="${p_repo_id}${g_color_opaque}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_subversion_version}" ]; then
        l_tag="${l_tag}[${p_arti_subversion_version}]${g_color_reset}"
    else
        l_tag="${l_tag}${g_color_reset}"
    fi

    #3. Copiar loa archivos del artefacto segun el prefijo
    local l_path_source=""

    local l_path_target_man=""
    local l_path_target_bin=""
    if [ $p_install_win_cmds -ne 0 ]; then
        l_path_target_bin="$g_path_bin"
        l_path_target_man="$g_path_man"
    else
        l_path_target_bin="$g_path_bin_win"
        l_path_target_man="$g_path_man_win"
    fi

    local l_status=0
    local l_flag_install=1
    local l_aux

    case "$p_repo_id" in

        bat)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"bat\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/bat" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/bat"
                    mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/bat" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/bat"
                    sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/bat.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"bat.1\" a \"${l_path_target_man}/\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/bat.1" "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/bat.1" "${l_path_target_man}"
                fi
            fi

            #Copiar los script de completado
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"autocomplete/bat.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_source}/autocomplete/bat.bash" ~/.files/terminal/linux/complete/bat.bash
                echo "Copiando \"autocomplete/_bat.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                cp "${l_path_source}/autocomplete/_bat.ps1" ~/.files/terminal/powershell/complete/bat.ps1
            fi
            ;;

        ripgrep)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"rg\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/rg" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/rg"
                    mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/rg" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/rg"
                    sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/rg.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"doc/rg.1\" a \""${l_path_target_man}"/\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/doc/rg.1" "${l_path_target_man}"/
                else
                    sudo cp "${l_path_source}/doc/rg.1" "${l_path_target_man}"/
                fi
            fi

            #Copiar los script de completado
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"complete/rg.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_source}/complete/rg.bash" ~/.files/terminal/linux/complete/rg.bash
                echo "Copiando \"autocomplete/_rg.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                cp "${l_path_source}/complete/_rg.ps1" ~/.files/terminal/powershell/complete/rg.ps1
            fi
            ;;

        xsv)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"csv\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/xsv" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/xsv"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/xsv" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/xsv"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/xsv.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            ;;

        delta)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"delta\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/delta" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/delta"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/delta" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/delta"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/delta.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            
            ##Copiar los archivos de ayuda man para comando
            #if [ $p_install_win_cmds -ne 0 ]; then
            #    echo "Copiando \"doc/rg.1\" a \""${l_path_target_man}"/\" ..."
            #    if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
            #        cp "${l_path_source}/doc/rg.1" "${l_path_target_man}"/
            #    else
            #        sudo cp "${l_path_source}/doc/rg.1" "${l_path_target_man}"/
            #    fi
            #fi

            ##Copiar los script de completado
            #if [ $p_install_win_cmds -ne 0 ]; then
            #    echo "Copiando \"complete/rg.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #    cp "${l_path_source}/complete/rg.bash" ~/.files/terminal/linux/complete/rg.bash
            #    echo "Copiando \"autocomplete/_rg.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
            #    cp "${l_path_source}/complete/_rg.ps1" ~/.files/terminal/powershell/complete/rg.ps1
            #fi
            ;;

        less)

            if [ $p_install_win_cmds -eq 0 ]; then

                #Ruta local de los artefactos
                #l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
                l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                echo "Copiando \"less\" a \"${l_path_target_bin}\" ..."
                if [ $p_artifact_index -eq 0 ]; then
                    cp "${l_path_source}/less.exe" "${l_path_target_bin}"
                else
                    cp "${l_path_source}/lesskey.exe" "${l_path_target_bin}"
                fi

            else
                echo "ERROR (50): El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi            
            ;;

        butane)

            if [ $p_install_win_cmds -ne 0 ]; then

                #Ruta local de los artefactos
                #l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
                l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                echo "Copiando \"butane-x86_64-unknown-linux-gn4\" como \"${l_path_target_bin}/butane\" ..."
                mv "${l_path_source}/butane-x86_64-unknown-linux-gnu" "${l_path_source}/butane"

                echo "Copiando \"butane\" a \"${l_path_target_bin}\" ..."
                if [ $g_user_is_root -eq 0 ]; then
                    cp "${l_path_source}/butane" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/butane"
                else
                    sudo cp "${l_path_source}/butane" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/butane"
                fi

            else
                echo "ERROR (50): El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Windows"
                return 40
            fi            
            ;;

        fzf)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiar el comando fzf y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"fzf\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/fzf" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/fzf"
                    mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/fzf" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/fzf"
                    sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/fzf.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            
            if [ $p_install_win_cmds -ne 0 ]; then

                #Descargar archivos necesarios
                echo "Descargando \"https://github.com/junegunn/fzf.git\" en el folder \"git/\" ..."
                git clone --depth 1 https://github.com/junegunn/fzf.git "${l_path_source}/git"

                #Copiar los archivos de ayuda man para comando fzf y el script fzf-tmux
                echo "Copiando \"git/man/man1/fzf.1\" y \"git/man/man1/fzf-tmux.1\" a \"${l_path_target_man}/\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/git/man/man1/fzf.1" "${l_path_target_man}"
                    cp "${l_path_source}/git/man/man1/fzf-tmux.1" "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/git/man/man1/fzf.1" "${l_path_target_man}"
                    sudo cp "${l_path_source}/git/man/man1/fzf-tmux.1" "${l_path_target_man}"
                fi

                #Copiar los archivos requeridos por el plugin vim base "fzf"
                #mkdir -p ~/.files/vim/packages/fzf/doc
                #mkdir -p ~/.files/vim/packages/fzf/plugin
                #echo "Copiando \"git/doc/fzf.txt\" a \"~/.files/vim/packages/fzf/doc/\" ..."
                #cp "${l_path_source}/git/doc/fzf.txt" ~/.files/vim/packages/fzf/doc/
                #echo "Copiando \"git/doc/fzf.vim\" a \"~/.files/vim/packages/fzf/plugin/\" ..."
                #cp "${l_path_source}/git/plugin/fzf.vim" ~/.files/vim/packages/fzf/plugin/

                #Copiar los archivos opcionales del plugin
                #echo "Copiando \"git/LICENSE\" en \"~/.files/vim/packages/fzf/\" .."
                #cp "${l_path_source}/git/LICENSE" ~/.files/vim/packages/fzf/LICENSE
            
                #Copiar los script de completado
                echo "Copiando \"git/shell/completion.bash\" como \"~/.files/terminal/linux/complete/fzf.bash\" ..."
                cp "${l_path_source}/git/shell/completion.bash" ~/.files/terminal/linux/complete/fzf.bash
            
                #Copiar los script de keybindings
                echo "Copiando \"git/shell/key-bindings.bash\" como \"~/.files/terminal/linux/keybindings/fzf.bash\" ..."
                cp "${l_path_source}/git/shell/key-bindings.bash" ~/.files/terminal/linux/keybindings/fzf.bash
            
                # Script que se usara como comando para abrir fzf en un panel popup tmux
                echo "Copiando \"git/bin/fzf-tmux\" como \"~/.files/terminal/linux/functions/fzf-tmux.bash\" y crear un enlace como comando \"~/.local/bin/fzf-tmux\"..."
                cp "${l_path_source}/git/bin/fzf-tmux" ~/.files/terminal/linux/functions/fzf-tmux.bash
                mkdir -p ~/.local/bin
                ln -sfn ~/.files/terminal/linux/functions/fzf-tmux.bash ~/.local/bin/fzf-tmux
            fi
            ;;

        jq)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"jq-linux64\" como \"${l_path_target_bin}/jq\" ..."
                mv "${l_path_source}/jq-linux64" "${l_path_source}/jq"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/jq" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/jq"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/jq" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/jq"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                echo "Copiando \"jq-win64.exe\" como \"${l_path_target_bin}/jq.exe\" ..."
                mv "${l_path_source}/jq-win64.exe" "${l_path_source}/jq.exe"

                cp "${l_path_source}/jq.exe" "${l_path_target_bin}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            #echo "Copiando \"jq.1\" a \"${l_path_target_man"/\" ..."
            #if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
            #    cp "${l_path_source}/jq.1" "${l_path_target_man}"
            #else
            #    sudo cp "${l_path_source}/jq.1" "${l_path_target_man}"
            #fi

            #Copiar los script de completado
            #echo "Copiando \"autocomplete/jq.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #cp "${l_path_source}/autocomplete/jq.bash" ~/.files/terminal/linux/complete/jq.bash
            #echo "Copiando \"autocomplete/_jq.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
            #cp "${l_path_source}/autocomplete/jq.ps1" ~/.files/terminal/powershell/complete/jq.ps1
            ;;

        yq)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then

                echo "Copiando \"yq_linux_amd64\" como \"${l_path_target_bin}/yq\" ..."
                mv "${l_path_source}/yq_linux_amd64" "${l_path_source}/yq"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/yq" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/yq"
                    mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/yq" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/yq"
                    sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                echo "Copiando \"yq_windows_amd64.exe\" como \"${l_path_target_bin}/yq.exe\" ..."
                mv "${l_path_source}/yq_windows_amd64.exe" "${l_path_source}/yq.exe"

                cp "${l_path_source}/yq.exe" "${l_path_target_bin}"
            fi

            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"yq.1\" a \"${l_path_target_man}/\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/yq.1" "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/yq.1" "${l_path_target_man}"
                fi
            fi
            ;;
        
        oh-my-posh)
            
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #En Linux
            if [ $p_install_win_cmds -ne 0 ]; then

                #Instalación de binario 'oh-my-posh'
                if [ $p_artifact_index -eq 0 ]; then

                    echo "Copiando \"posh-linux-amd64\" como \"${l_path_target_bin}/oh-my-posh\" ..."
                    mv "${l_path_source}/posh-linux-amd64" "${l_path_source}/oh-my-posh"
                
                    #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                    if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                        cp "${l_path_source}/oh-my-posh" "${l_path_target_bin}"
                        chmod +x "${l_path_target_bin}/oh-my-posh"
                        #mkdir -pm 755 "${l_path_target_man}"
                    else
                        sudo cp "${l_path_source}/oh-my-posh" "${l_path_target_bin}"
                        sudo chmod +x "${l_path_target_bin}/oh-my-posh"
                        #sudo mkdir -pm 755 "${l_path_target_man}"
                    fi

                    #Copiar los archivos de ayuda man para comando
                    #echo "Copiando \"yq.1\" a \"${l_path_target_man}/\" ..."
                    #if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    #    cp "${l_path_source}/yq.1" "${l_path_target_man}"
                    #else
                    #    sudo cp "${l_path_source}/yq.1" "${l_path_target_man}"
                    #fi

                    #Copiar los script de completado
                    #echo "Copiando \"autocomplete/yq.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                    #cp "${l_path_source}/autocomplete/yq.bash" ~/.files/terminal/linux/complete/yq.bash
                    #echo "Copiando \"autocomplete/_yq.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                    #cp "${l_path_source}/autocomplete/yq.ps1" ~/.files/terminal/powershell/complete/yq.ps1

                #Instalación del tema
                else

                    mkdir -p ~/.files/terminal/oh-my-posh/themes
                    cp -f ${l_path_source}/*.json ~/.files/terminal/oh-my-posh/themes

                fi

            #En Windows
            else

                #Instalación de binario 'oh-my-posh'
                if [ $p_artifact_index -eq 0 ]; then

                    echo "Copiando \"posh-windows-amd64.exe\" como \"${l_path_target_bin}/oh-my-posh.exe\" ..."
                    mv "${l_path_source}/posh-windows-amd64.exe" "${l_path_source}/oh-my-posh.exe"

                    cp "${l_path_source}/oh-my-posh.exe" "${l_path_target_bin}"

                #Instalación del tema
                else
                    mkdir -p "${g_path_etc_win}/oh-my-posh/themes"
                    cp -f ${l_path_source}/*.json "${g_path_etc_win}/oh-my-posh/themes"
                fi
            fi
            ;;

        jwt)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"jwt\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/jwt" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/jwt"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/jwt" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/jwt"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/jwt.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            ;;
            
        grpcurl)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"grpcurl\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/grpcurl" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/grpcurl"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/grpcurl" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/grpcurl"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/grpcurl.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            ;;
            
        evans)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"evans\" a \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/evans" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/evans"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/evans" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/evans"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/evans.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            ;;
            
        protoc)
            
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/protoc"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                    chmod g+rx,o+rx $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover todos archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.tar.gz"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;

                #Validar si 'protoc' esta en el PATH
                echo "$PATH" | grep "${g_path_programs}/protoc/bin" &> /dev/null
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                        "$g_color_warning" "ProtoC"  "$p_repo_last_version_pretty" "$g_color_reset"
                    printf 'Adicionando a la sesion actual: PATH=%s/protoc/bin:$PATH\n' "${g_path_programs}"
                    export PATH=${g_path_programs}/protoc/bin:$PATH
                fi

            else
                
                l_path_target_bin="${g_path_programs_win}/ProtoC"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover los archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.zip"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;
            fi
            ;;

        fd)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"

            #Copiando el binario en una ruta del path
            echo "Copiando \"fd\" en \"${l_path_target_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/fd" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/fd"
                    mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/fd" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/fd"
                    sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/fd.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"fd.1\" a \"${l_path_target_man}/\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/fd.1" "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/fd.1" "${l_path_target_man}"
                fi
            fi

            #Copiar los script de completado
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"autocomplete/fd.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_source}/autocomplete/fd.bash" ~/.files/terminal/linux/complete/fd.bash
                echo "Copiando \"autocomplete/fd.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                cp "${l_path_source}/autocomplete/fd.ps1" ~/.files/terminal/powershell/complete/fd.ps1
            fi
            ;;

            
        crictl)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then

                if [ $p_artifact_index -eq 0 ]; then

                    if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                        echo "Copiando \"crictl\" en \"${l_path_target_bin}/\" ..."
                        cp "${l_path_source}/crictl" "${l_path_target_bin}"
                        chmod +x "${l_path_target_bin}/crictl"
                    else
                        echo "Copiando \"crictl\" en \"${l_path_target_bin}/\" ..."
                        sudo cp "${l_path_source}/crictl" "${l_path_target_bin}"
                        sudo chmod +x "${l_path_target_bin}/crictl"
                    fi

                else

                    if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                        echo "Copiando \"critest\" en \"${l_path_target_bin}/\" ..."
                        cp "${l_path_source}/critest" "${l_path_target_bin}"
                        chmod +x "${l_path_target_bin}/critest"
                    else
                        echo "Copiando \"critest\" en \"${l_path_target_bin}/\" ..."
                        sudo cp "${l_path_source}/critest" "${l_path_target_bin}"
                        sudo chmod +x "${l_path_target_bin}/critest"
                    fi

                fi
            else
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Windows"
                return 40
            fi
            ;;

            
        kubelet)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    echo "Copiando \"kubelet\" en \"${l_path_target_bin}/\" ..."
                    cp "${l_path_source}/kubelet" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/kubelet"
                else
                    echo "Copiando \"kubelet\" en \"${l_path_target_bin}/\" ..."
                    sudo cp "${l_path_source}/kubelet" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/kubelet"
                fi

                #Desacargar archivos adicionales para su configuración
                mkdir -p ~/.files/setup/programs/kubelet
                l_aux=$(curl -sL https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubelet/kubelet.service 2> /dev/null)
                l_status=$?
                if [ $l_status -eq 0 ]; then
                    printf 'Creando el archivo "%b~/.files/setup/programs/kubelet/kubelet.service%b" ... \n' "$g_color_opaque" "$g_color_reset"
                    echo "$l_aux" | sed "s:/usr/bin:${l_path_target_bin}:g" > ~/.files/setup/programs/kubelet/kubelet.service
                fi

            else
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Windows"
                return 40
            fi
            ;;

            
        kubeadm)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    echo "Copiando \"kubeadm\" en \"${l_path_target_bin}/\" ..."
                    cp "${l_path_source}/kubeadm" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/kubeadm"
                else
                    echo "Copiando \"kubeadm\" en \"${l_path_target_bin}/\" ..."
                    sudo cp "${l_path_source}/kubeadm" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/kubeadm"
                fi

                #Desacargar archivos adicionales para su configuración
                mkdir -p ~/.files/setup/programs/kubeadm
                l_aux=$(curl -sL https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf 2> /dev/null)
                l_status=$?
                if [ $l_status -eq 0 ]; then
                    printf 'Creando el archivo "%b~/.files/setup/programs/kubeadm/10-kubeadm.conf%b" ... \n' "$g_color_opaque" "$g_color_reset"
                    echo "$l_aux" | sed "s:/usr/bin:${l_path_target_bin}:g" > ~/.files/setup/programs/kubeadm/10-kubeadm.conf
                fi

            else
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Windows"
                return 40
            fi
            ;;

            
        kubectl)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    echo "Copiando \"kubectl\" en \"${l_path_target_bin}/\" ..."
                    cp "${l_path_source}/kubectl" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/kubectl"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    echo "Copiando \"kubectl\" en \"${l_path_target_bin}/\" ..."
                    sudo cp "${l_path_source}/kubectl" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/kubectl"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                echo "Copiando \"kubectl.exe\" en \"${l_path_target_bin}/\" ..."
                cp "${l_path_source}/kubectl.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            
            ##Copiar los archivos de ayuda man para comando
            #echo "Copiando \"fd.1\" a \"${l_path_target_man}/\" ..."
            #if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
            #    cp "${l_path_source}/fd.1" "${l_path_target_man}"
            #else
            #    sudo cp "${l_path_source}/fd.1" "${l_path_target_man}"
            #fi

            ##Copiar los script de completado
            #echo "Copiando \"autocomplete/fd.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #cp "${l_path_source}/autocomplete/fd.bash" ~/.files/terminal/linux/complete/fd.bash
            #echo "Copiando \"autocomplete/fd.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
            #cp "${l_path_source}/autocomplete/fd.ps1" ~/.files/terminal/powershell/complete/fd.ps1
            ;;
        
        pgo)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then

                echo "Renombrando \"kubectl-pgo-linux-amd64\" en \"${l_path_source}/kubectl-pgo\" ..."
                mv "${l_path_source}/kubectl-pgo-linux-amd64" "${l_path_source}/kubectl-pgo"

                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    echo "Copiando \"kubectl-pgo\" en \"${l_path_target_bin}/\" ..."
                    cp "${l_path_source}/kubectl-pgo" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/kubectl-pgo"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    echo "Copiando \"kubectl-pgo\" en \"${l_path_target_bin}/\" ..."
                    sudo cp "${l_path_source}/kubectl-pgo" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/kubectl-pgo"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                echo "$p_repo_last_version_pretty" > "${g_path_programs}/pgo.info" 
            else

                echo "Renombrando \"kubectl-pgo-windows-386\" en \"${l_path_source}/kubectl-pgo.exe\" ..."
                mv "${l_path_source}/kubectl-pgo-windows-386" "${l_path_source}/kubectl-pgo.exe"

                echo "Copiando \"kubectl-pgo.exe\" en \"${l_path_target_bin}/\" ..."
                cp "${l_path_source}/kubectl-pgo.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
                
                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                echo "$p_repo_last_version_pretty" > "${g_path_programs_win}/pgo.info" 
            fi
            ;;
            
        helm)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                l_path_source="${l_path_source}/linux-amd64"
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/helm" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/helm"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/helm" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/helm"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                l_path_source="${l_path_source}/windows-amd64"
                cp "${l_path_source}/helm.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            ;;

        operator-sdk)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then

                #Instalacion del SDK para construir el operador
                if [ $p_artifact_index -eq 0 ]; then

                   mv "${l_path_source}/operator-sdk_linux_amd64" "${l_path_source}/operator-sdk"
                   if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                      cp "${l_path_source}/operator-sdk" "${l_path_target_bin}"
                      chmod +x "${l_path_target_bin}/operator-sdk"
                      #mkdir -pm 755 "${l_path_target_man}"
                   else
                      sudo cp "${l_path_source}/operator-sdk" "${l_path_target_bin}"
                      sudo chmod +x "${l_path_target_bin}/operator-sdk"
                      #sudo mkdir -pm 755 "${l_path_target_man}"
                   fi

                #Instalacion del SDK para construir el operador usando Ansible
                #elif [ $p_artifact_index -eq 1 ]; then

                #   mv "${l_path_source}/ansible-operator_linux_amd64" "${l_path_source}/ansible-operator"
                #   if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                #      cp "${l_path_source}/ansible-operator" "${l_path_target_bin}"
                #      chmod +x "${l_path_target_bin}/ansible-operator"
                #      #mkdir -pm 755 "${l_path_target_man}"
                #   else
                #      sudo cp "${l_path_source}/ansible-operator" "${l_path_target_bin}"
                #      sudo chmod +x "${l_path_target_bin}/ansible-operator"
                #      #sudo mkdir -pm 755 "${l_path_target_man}"
                #   fi

                #Instalacion del SDK para construir el operador usando Helm
                else

                   mv "${l_path_source}/helm-operator_linux_amd64" "${l_path_source}/helm-operator"
                   if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                      cp "${l_path_source}/helm-operator" "${l_path_target_bin}"
                      chmod +x "${l_path_target_bin}/helm-operator"
                      #mkdir -pm 755 "${l_path_target_man}"
                   else
                      sudo cp "${l_path_source}/helm-operator" "${l_path_target_bin}"
                      sudo chmod +x "${l_path_target_bin}/helm-operator"
                      #sudo mkdir -pm 755 "${l_path_target_man}"
                   fi

                fi

            fi
            ;;


        k0s)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi

            #2. Si la nodo k0s esta iniciado, solicitar su detención
            request_stop_k0s_node 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 1 ]; then
                return 41
            fi


            #3. Renombrar el binario antes de copiarlo
            echo "Copiando \"${p_artifact_name_woext}\" como \"${l_path_target_bin}/k0s\" ..."
            mv "${l_path_source}/${p_artifact_name_woext}" "${l_path_source}/k0s"

            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                cp "${l_path_source}/k0s" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/k0s"
            else
                sudo cp "${l_path_source}/k0s" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/k0s"
                #sudo mkdir -pm 755 "${l_path_target_man}"
            fi


            #4. Si el nodo k0s estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 2 ]; then

                printf 'Iniciando el nodo k0s...\n'
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    k0s start
                else
                    sudo k0s start
                fi
            fi
            ;;

        roslyn)
            
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/lsp_servers/omnisharp_roslyn"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                    chmod g+rx,o+rx $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover todos archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.tar.gz"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_target_bin} \;

            else
                
                l_path_target_bin="${g_path_programs_win}/LSP_Servers/Omnisharp_Roslyn"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover los archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.zip"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;
            fi
            ;;

        netcoredbg)
            
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/netcoredbg"
            l_flag_install=0            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/dap_servers/netcoredbg"

                #1. Comparando la version instalada con la version descargada
                _compare_version_current_with "$p_repo_id" "$l_path_source" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    l_flag_install=0
                else
                    l_flag_install=1
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_target_bin" ]; then
                        mkdir -p $l_path_target_bin
                        chmod g+rx,o+rx $l_path_target_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_target_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_source}/${p_artifact_name_woext}.tar.gz"
                    find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_target_bin} \;
                    
                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_target_bin}/netcoredbg.info" 
                fi


            else
                
                l_path_target_bin="${g_path_programs_win}/DAP_Servers/NetCoreDbg"

                #1. Comparando la version instalada con la version descargada
                _compare_version_current_with "$p_repo_id" "$l_path_source" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    l_flag_install=0
                else
                    l_flag_install=1
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_target_bin" ]; then
                        mkdir -p $l_path_target_bin
                        #chmod g+rx,o+rx $l_path_target_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_target_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_source}/${p_artifact_name_woext}.zip"
                    find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;

                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_target_bin}/netcoredbg.info" 
                fi

            fi
            ;;

        neovim)
            
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            l_flag_install=0            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/neovim"

                #1. Comparando la version instalada con la version descargada
                _compare_version_current_with "$p_repo_id" "$l_path_source/bin" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    l_flag_install=0
                else
                    l_flag_install=1
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_target_bin" ]; then
                        mkdir -p $l_path_target_bin
                        chmod g+rx,o+rx $l_path_target_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_target_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_source}/${p_artifact_name_woext}.tar.gz"
                    find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_target_bin} \;

                    #Validar si 'nvim' esta en el PATH
                    echo "$PATH" | grep "${g_path_programs}/neovim/bin" &> /dev/null
                    l_status=$?
                    if [ $l_status -ne 0 ]; then
                        printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                            "$g_color_warning" "NeoVIM"  "$p_repo_last_version_pretty" "$g_color_reset"
                        printf 'Adicionando a la sesion actual: PATH=%s/neovim/bin:$PATH\n' "${g_path_programs}"
                        export PATH=${g_path_programs}/neovim/bin:$PATH
                    fi

                fi


            else
                
                l_path_target_bin="${g_path_programs_win}/NeoVim"

                #1. Comparando la version instalada con la version descargada
                _compare_version_current_with "$p_repo_id" "$l_path_source/bin" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    l_flag_install=0
                else
                    l_flag_install=1
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_target_bin" ]; then
                        mkdir -p $l_path_target_bin
                        #chmod g+rx,o+rx $l_path_target_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_target_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_source}/${p_artifact_name_woext}.zip"
                    find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;
                fi

            fi
            ;;

        nerd-fonts)
            
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #Solo para Linux
            if [ $p_install_win_cmds -ne 0 ]; then
                
                #Copiando el binario en una ruta del path
                l_path_target_bin="${g_path_fonts}/${p_artifact_name_woext}"

                #Instalación de la fuente
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    
                    #Crear la carpeta de fuente, si no existe
                    if  [ ! -d "$l_path_target_bin" ]; then
                        mkdir -p $l_path_target_bin
                        chmod g+rx,o+rx $l_path_target_bin
                    fi

                    #Copiar y/o sobrescribir archivos existente
                    find "${l_path_source}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
                         ! \( -name '*Windows Compatible*.otf' -o -name '*Windows Compatible*.ttf' \) \
                         -exec cp '{}' ${l_path_target_bin} \;
                    chmod g+r,o+r ${l_path_target_bin}/*

                    #Actualizar el cache de fuentes del SO
                    if [ $p_artifact_is_last -eq 0 ]; then
                        fc-cache -v
                    fi

                else
                    
                    #Crear la carpeta de fuente, si no existe
                    if  [ ! -d "$l_path_target_bin" ]; then
                        sudo mkdir -p ${l_path_target_bin}
                        sudo chmod g+rx,o+rx $l_path_target_bin
                    fi

                    #Copiar y/o sobrescribir archivos existente
                    sudo find "${l_path_source}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
                         ! \( -name '*Windows Compatible*.otf' -o -name '*Windows Compatible*.ttf' \) \
                         -exec cp '{}' ${l_path_target_bin} \;
                    sudo chmod g+r,o+r ${l_path_target_bin}/*

                    #Actualizar el cache de fuentes del SO
                    if [ $p_artifact_is_last -eq 0 ]; then
                        sudo fc-cache -v
                    fi

                    #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${g_path_programs}/nerd-fonts.info" 
                fi
                    
                #Si es WSL2, copiar los archivos para instalarlo manualmente.
                if [ $g_os_type -eq 1 ]; then
                    
                    l_path_target_bin="${g_path_programs_win}/NerdFonts"
                    if  [ ! -d "$l_path_target_bin" ]; then
                        mkdir -p ${l_path_target_bin}
                    fi

                    find "${l_path_source}" -maxdepth 1 -mindepth 1 \
                         \( -name '*Windows Compatible*.otf' -o -name '*Windows Compatible*.ttf' \) \
                         -exec cp '{}' ${l_path_target_bin} \;
                    
                    #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${g_path_programs}/nerd-fonts.info" 

                    #Notas
                    echo "Debera instalar (copiar) manualmente los archivos de '${l_path_target_bin}' en 'C:/Windows/Fonts'"
                fi

            fi
            ;;
        
        llvm)
           
            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi
                
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            l_path_target_bin="${g_path_programs}/llvm"

            #Limpiar el directorio del programa
            if  [ -d "$l_path_target_bin" ]; then
                #Limpieza
                rm -rf $l_path_target_bin
            fi

            #Descomprimiendo el archivo 'clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04'
            printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "$l_path_target_bin"
            uncompress_program "$l_path_source" "$p_artifact_name" "${g_path_programs}" $((l_artifact_type - 20))
            #l_artifact_name_without_ext="$g_filename_without_ext"

            #Obteniendo el nombre de la carpeta que genero al descromprimir
            l_aux=$(find "$g_path_programs" -maxdepth 1 -mindepth 1 -type d -name 'clang+llvm-*' 2> /dev/null | head -n 1)

            if [ -z "$l_aux" ]; then
                printf 'El comprimido %b"LLVM" se debio descromprimir en un carpeta que inicia con "%s/%s", pero no existe%b.\n' "$g_color_warning" \
                    "$g_path_programs" 'clang+llvm-*' "$g_color_reset"
                return 41
            fi

            #Acceso al folder creado
            printf 'Renombrando "%b%s%b" en "%b%s%b"...\n' "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_opaque" "$l_path_target_bin" "$g_color_reset"
            mv "$l_aux" "$l_path_target_bin"
            chmod g+rx,o+rx ${l_path_target_bin}

            #Validar si 'LLVM' esta en el PATH
            echo "$PATH" | grep "${g_path_programs}/llvm/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_warning" "Go"  "$p_repo_last_version_pretty" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/llvm/bin:$PATH\n' "${g_path_programs}"
                export PATH=${g_path_programs}/llvm/bin:$PATH
            fi
            ;;


        clangd)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/clangd_${p_repo_last_version}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/lsp_servers/clangd"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                    chmod g+rx,o+rx $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover todos archivos
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;


            else
                
                l_path_target_bin="${g_path_programs_win}/LSP_Servers/CLangD"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover los archivos
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;
            fi
            ;;


        net-sdk|net-rt-core|net-rt-aspnet)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/dotnet"

                #Crear el directorio si no existe (no limpiar)
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                    chmod g+rx,o+rx $l_path_target_bin
                #else
                    #Limpieza
                    #rm -rf ${l_path_target_bin}/*
                fi
                    
                #No es necesario eliminarlo, lo hace el metodo que lo descarga y lo descomprime
                #find "${l_path_source}/*.tar.gz" -maxdepth 1 -mindepth 1 -type f -exec rm '{}' \;
                 
                #Mover todos archivos (remplazando los existentes sin advertencia interactiva)
                printf '%b' "$g_color_opaque"
                rsync -a --stats "${l_path_source}/" "${l_path_target_bin}"
                printf '%b' "$g_color_reset"

                #Validar si 'DotNet' esta en el PATH
                echo "$PATH" | grep "${g_path_programs}/dotnet" &> /dev/null
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                        "$g_color_warning" "DotNet"  "$p_repo_last_version_pretty" "$g_color_reset"
                    printf 'Adicionando a la sesion actual: PATH=%s/dotnet:$PATH\n' "${g_path_programs}"

                    export DOTNET_ROOT=${g_path_programs}/dotnet
                    PATH=${g_path_programs}/dotnet:$PATH                    
                    if [ "$p_repo_id" = "net-sdk" ]; then
                        PATH=${g_path_programs}/dotnet/tools:$PATH
                    fi
                    export PATH
                fi

            else
                
                l_path_target_bin="${g_path_programs_win}/DotNet"

                #Crear el directorio si no existe (no limpiar)
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                #else
                    #Limpieza
                    #rm -rf ${l_path_target_bin}/*
                fi
                    
                #No es necesario eliminarlo, lo hace el metodo que lo descarga y lo descomprime
                #find "${l_path_source}/*.zip" -maxdepth 1 -mindepth 1 -type f -exec rm '{}' \;

                #Mover todos archivos (remplazando los existentes sin advertencia interactiva)
                printf '%b' "$g_color_opaque"
                rsync -a --stats "${l_path_source}/" "${l_path_target_bin}"
                printf '%b' "$g_color_reset"
            fi
            ;;



        go)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
               
                #Limpiar el directorio del programa
                if  [ -d "${g_path_programs}/go" ]; then
                    rm -rf ${g_path_programs}/go
                fi
                    
                #Descomprimiendo el archivo (descomprime en la carpeta './go')
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "${g_path_programs}/go"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"

                #Acceso al folder creado
                chmod g+rx,o+rx ${g_path_programs}/go

                #Validar si 'Go' esta en el PATH
                echo "$PATH" | grep "${g_path_programs}/go/bin" &> /dev/null
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                        "$g_color_warning" "Go"  "$p_repo_last_version_pretty" "$g_color_reset"
                    printf 'Adicionando a la sesion actual: PATH=%s/go/bin:$PATH\n' "${g_path_programs}"
                    export PATH=${g_path_programs}/go/bin:$PATH
                    [ -d ~/go/bin ] && PATH=$PATH:~/go/bin
                fi

            else
                
                #Limpiar el directorio del programa
                if  [ -d "${g_path_programs_win}/Go" ]; then
                    rm -rf ${g_path_programs_win}/Go
                fi
                    
                #Descomprimiendo el archivo (descomprime en la carpeta './go')
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "${g_path_programs_win}/Go"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs_win}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"

                #Acceso al folder creado
                mv ${g_path_programs_win}/go ${g_path_programs_win}/Go
                #chmod g+rx,o+rx ${g_path_programs_win}/Go
                
            fi
            ;;


        nodejs)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then

                #Limpiar el directorio del programa
                if  [ -d "${g_path_programs}/nodejs" ]; then
                    rm -rf ${g_path_programs}/nodejs
                fi
                    
                #Descomprimiendo el archivo (descomprime en la carpeta './node-${p_repo_last_version}-linux-x64')
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "${g_path_programs}/nodejs"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"

                #Acceso al folder creado
                printf 'Renombrando "%b%s%b" en "%b%s%b"...\n' "$g_color_opaque" "${g_path_programs}/node-${p_repo_last_version}-linux-x64" "$g_color_reset" "$g_color_opaque" \
                       "${g_path_programs}/nodejs" "$g_color_reset"
                mv "${g_path_programs}/node-${p_repo_last_version}-linux-x64" "${g_path_programs}/nodejs"
                chmod g+rx,o+rx ${g_path_programs}/nodejs

                #Validar si 'Node.JS' esta en el PATH
                echo "$PATH" | grep "${g_path_programs}/nodejs/bin" &> /dev/null
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                        "$g_color_warning" "Node.JS"  "$p_repo_last_version_pretty" "$g_color_reset"
                    printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_path_programs}"
                    export PATH=${g_path_programs}/nodejs/bin:$PATH
                fi

            else
                
                #Limpiar el directorio del programa
                if  [ -d "${g_path_programs_win}/NodeJS" ]; then
                    rm -rf ${g_path_programs_win}/NodeJS
                fi
                    
                #Descomprimiendo el archivo (descomprime en la carpeta './node-${p_repo_last_version}-linux-x64')
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "${g_path_programs_win}/NodeJS"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs_win}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"

                #Acceso al folder creado
                printf 'Renombrando "%b%s%b" en "%b%s%b"...\n' "$g_color_opaque" "${g_path_programs_win}/node-${p_repo_last_version}-win-x64" "$g_color_reset" "$g_color_opaque" \
                       "${g_path_programs_win}/NodeJS" "$g_color_reset"
                mv "${g_path_programs_win}/node-${p_repo_last_version}-win-x64" "${g_path_programs_win}/NodeJS"
                #chmod g+rx,o+rx ${g_path_programs_win}/NodeJS

            fi
            ;;


        cmake)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/cmake"

                #Limpiar el directorio del programa
                if  [ -d "$l_path_target_bin" ]; then
                    rm -rf ${l_path_target_bin}
                fi
                
                #Descomprimiendo el archivo (descomprime en la carpeta cuyo nombre puede variar)
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "$l_path_target_bin"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"
                
                #Obteniendo el nombre de la carpeta que genero al descromprimir
                #l_aux=$(find "$g_path_programs" -maxdepth 1 -mindepth 1 -type d -name 'cmake-*' 2> /dev/null | head -n 1)

                #if [ -z "$l_aux" ]; then
                #    printf 'El comprimido %b"GraalVM" se debio descromprimir en un carpeta que inicia con "%s/%s", pero no existe%b.\n' "$g_color_warning" \
                #        "$g_path_programs" 'cmake-*' "$g_color_reset"
                #    return 41
                #fi

                #Acceso al folder creado
                l_aux="${l_path_source}/${p_artifact_name_woext}"
                printf 'Renombrando "%b%s%b" en "%b%s%b"...\n' "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_opaque" "$l_path_target_bin" "$g_color_reset"
                mv "$l_aux" "$l_path_target_bin"
                chmod g+rx,o+rx ${l_path_target_bin}

                #Copiando los archivos de ayuda
                #./man/man1/*.1
                #./man/man1/*.7

                #Copiando los script para el autocompletado
                #bash-completion/completions/cmake
                #bash-completion/completions/cpack
                #bash-completion/completions/ctest

                #Validar si 'CMake' esta en el PATH
                echo "$PATH" | grep "${g_path_programs}/cmake/bin" &> /dev/null
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                        "$g_color_warning" "CMake"  "$p_repo_last_version_pretty" "$g_color_reset"
                    printf 'Adicionando a la sesion actual: PATH=%s/cmake/bin:$PATH\n' "${g_path_programs}"
                    export PATH=${g_path_programs}/cmake/bin:$PATH
                fi

            else
                
                l_path_target_bin="${g_path_programs_win}/CMake"

                #Limpiar el directorio del programa
                if  [ -d "$l_path_target_bin" ]; then
                    rm -rf ${l_path_target_bin}
                fi
                
                #Descomprimiendo el archivo (descomprime en la carpeta cuyo nombre puede variar)
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "$l_path_target_bin"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs_win}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"
                
                #Obteniendo el nombre de la carpeta que genero al descromprimir
                #l_aux=$(find "$g_path_programs_win" -maxdepth 1 -mindepth 1 -type d -name 'cmake-*' 2> /dev/null | head -n 1)

                #if [ -z "$l_aux" ]; then
                #    printf 'El comprimido %b"GraalVM" se debio descromprimir en un carpeta que inicia con "%s/%s", pero no existe%b.\n' "$g_color_warning" \
                #        "$g_path_programs_win" 'cmake-*' "$g_color_reset"
                #    return 41
                #fi

                #Acceso al folder creado
                l_aux="${l_path_source}/${p_artifact_name_woext}"
                printf 'Renombrando "%b%s%b" en "%b%s%b"...\n' "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_opaque" "$l_path_target_bin" "$g_color_reset"
                mv "$l_aux" "$l_path_target_bin"
                #chmod g+rx,o+rx ${l_path_target_bin}
                
            fi
            ;;


        step)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/step_${p_repo_last_version_pretty}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/bin/step" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/step"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/bin/step" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/step"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi

                #Copiando los archivos de ayuda
                #./man/man1/*.1
                #./man/man1/*.7

                #Copiando los script para el autocompletado
                echo "Copiando \"autocomplete/bash_autocomplete\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_source}/autocomplete/bash_autocomplete" ~/.files/terminal/linux/complete/step.bash
                echo "Copiando \"autocomplete/zsh_autocomplete\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_source}/autocomplete/zsh_autocomplete" ~/.files/terminal/linux/complete/step.zsh

            else
                cp "${l_path_source}/bin/step.exe" "${l_path_target_bin}"
            fi
            ;;


        ninja)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    cp "${l_path_source}/ninja" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/ninja"
                    #mkdir -pm 755 "${l_path_target_man}"
                else
                    sudo cp "${l_path_source}/ninja" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/ninja"
                    #sudo mkdir -pm 755 "${l_path_target_man}"
                fi
            else
                cp "${l_path_source}/ninja.exe" "${l_path_target_bin}"
                #mkdir -p "${l_path_target_man}"
            fi
            ;;


        rust-analyzer)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            l_flag_install=0
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
               
                echo "Renombrando \"${l_path_source}/${p_artifact_name_woext}\" a \"${l_path_source}/rust-analyzer\""
                #ls -la ${l_path_source}
                mv "${l_path_source}/${p_artifact_name_woext}" "${l_path_source}/rust-analyzer"
                #ls -la ${l_path_source}
                #id
                chmod u+x "${l_path_source}/rust-analyzer"
                
                #1. Comparando la version instalada con la version descargada
                #_compare_version_current_with "$p_repo_id" "$l_path_source" $p_install_win_cmds
                #l_status=$?

                ##Actualizar solo no esta configurado o tiene una version menor a la actual
                #if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                #    l_flag_install=0
                #else
                #    l_flag_install=1
                #fi


                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then
                    l_path_target_bin="${g_path_programs}/lsp_servers/rust_analyzer"
                    mkdir -p "${l_path_target_bin}"

                    echo "Copiando \"${l_path_source}/rust-analyzer\" a \"${l_path_target_bin}/\""
                    cp "${l_path_source}/rust-analyzer" "${l_path_target_bin}/"
                    chmod +x "${l_path_target_bin}/rust-analyzer"
                    #mkdir -pm 755 "${l_path_target_man}"

                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_target_bin}/rust-analyzer.info" 
                fi


                #Validar si 'Rust Analizer' esta en el PATH
                #echo "$PATH" | grep "${g_path_programs}/lsp_servers/rust_analyzer" &> /dev/null
                #l_status=$?
                #if [ $l_status -ne 0 ]; then
                #    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                #        "$g_color_warning" "Rust-Analizer"  "$p_repo_last_version_pretty" "$g_color_reset"
                #    printf 'Adicionando a la sesion actual: PATH=%s/lsp_servers/rust_analyzer:$PATH\n' "${g_path_programs}"
                #    export PATH=${g_path_programs}/lsp_servers/rust_analyzer:$PATH
                #fi

            else

                #1. Comparando la version instalada con la version descargada
                #_compare_version_current_with "$p_repo_id" "$l_path_source" $p_install_win_cmds
                #l_status=$?

                ##Actualizar solo no esta configurado o tiene una version menor a la actual
                #if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                #    l_flag_install=0
                #else
                #    l_flag_install=1
                #fi


                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then
                    l_path_target_bin="${g_path_programs_win}/LSP_Servers/Rust_Analyzer"
                    mkdir -p "${l_path_target_bin}"

                    echo "Copiando \"${l_path_source}/rust-analyzer.exe\" a \"${l_path_target_bin}\""
                    cp "${l_path_source}/rust-analyzer.exe" "${l_path_target_bin}"
                    #echo "Copiando \"${l_path_source}/rust-analyzer.pdb\" a \"${l_path_target_bin}\""
                    #cp "${l_path_source}/rust-analyzer.pdb" "${l_path_target_bin}"
                    #mkdir -p "${l_path_target_man}"
                    
                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_target_bin}/rust-analyzer.info" 
                fi
            fi
            ;;


        graalvm)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"

            #No eso se instalaran los plugins (use 'gu install [tool-name]'):
            # Native Image
            # VisualVM
            # LLVM
            # JavaScript (GraalJS)
            # Node.js
            # Python (GraalPy)
            # Ruby (TruffleRuby)
            # R (FastR)
            # WebAssembly (Wasm)
            # Java on Truffle (Espresso)
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/graalvm"
                if [ $p_arti_subversion_index -ne 0 ]; then
                    l_path_target_bin="${l_path_target_bin}_${p_arti_subversion_version}"
                fi

                #Limpiar el directorio del programa
                if  [ -d "$l_path_target_bin" ]; then
                    rm -rf ${l_path_target_bin}
                fi
                    
                #Descomprimiendo el archivo (descomprime en la carpeta cuyo nombre puede variar)
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "$l_path_target_bin"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"
                
                #Obteniendo el nombre de la carpeta que genero al descromprimir
                l_aux=$(find "$g_path_programs" -maxdepth 1 -mindepth 1 -type d -name 'graalvm-community-*' 2> /dev/null | head -n 1)

                if [ -z "$l_aux" ]; then
                    printf 'El comprimido %b"GraalVM" se debio descromprimir en un carpeta que inicia con "%s/%s", pero no existe%b.\n' "$g_color_warning" \
                        "$g_path_programs" 'graalvm-community-*' "$g_color_reset"
                    return 41
                fi

                #Acceso al folder creado
                printf 'Renombrando "%b%s%b" en "%b%s%b"...\n' "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_opaque" "$l_path_target_bin" "$g_color_reset"
                mv "$l_aux" "$l_path_target_bin"
                chmod g+rx,o+rx ${l_path_target_bin}

                #Validar si 'GraalVM' esta en el PATH
                echo "$PATH" | grep "${g_path_programs}/graalvm/bin" &> /dev/null
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                        "$g_color_warning" "GraalVM"  "$p_repo_last_version_pretty" "$g_color_reset"
                    printf 'Adicionando a la sesion actual: PATH=%s/graalvm/bin:$PATH\n' "${g_path_programs}"
                    export PATH=${g_path_programs}/graalvm/bin:$PATH
                    GRAALVM_HOME=${g_path_programs}/graalvm
                    JAVA_HOME=${GRAALVM_HOME}
                    export GRAALVM_HOME JAVA_HOME
                fi

            else
                
                l_path_target_bin="${g_path_programs_win}/GraalVM"
                if [ $p_arti_subversion_index -ne 0 ]; then
                    l_path_target_bin="${l_path_target_bin}_${p_arti_subversion_version}"
                fi

                #Limpiar el directorio del programa
                if  [ -d "$l_path_target_bin" ]; then
                    rm -rf ${l_path_target_bin}
                fi
                    
                #Descomprimiendo el archivo (descomprime en la carpeta cuyo nombre puede variar)
                printf 'Descomprimiendo el artefacto "%b[%s]" ("%s") en "%s" ...\n' "$l_tag" "$p_artifact_index" "$p_artifact_name" "$l_path_target_bin"
                uncompress_program "${l_path_source}" "$p_artifact_name" "${g_path_programs_win}" $((l_artifact_type - 20))
                #l_artifact_name_without_ext="$g_filename_without_ext"
                
                #Obteniendo el nombre de la carpeta que genero al descromprimir
                l_aux=$(find "$g_path_programs_win" -maxdepth 1 -mindepth 1 -type d -name 'graalvm-community-*' 2> /dev/null | head -n 1)

                if [ -z "$l_aux" ]; then
                    printf 'El comprimido %b"GraalVM" se debio descromprimir en un carpeta que inicia con "%s/%s", pero no existe%b.\n' "$g_color_warning" \
                        "$g_path_programs_win" 'graalvm-community-*' "$g_color_reset"
                    return 41
                fi

                #Acceso al folder creado
                printf 'Renombrando "%b%s%b" en "%b%s%b"...\n' "$g_color_opaque" "$l_aux" "$g_color_reset" "$g_color_opaque" "$l_path_target_bin" "$g_color_reset"
                mv "$l_aux" "$l_path_target_bin"
                #chmod g+rx,o+rx ${l_path_target_bin}
                
            fi
            ;;


        jdtls)
            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/lsp_servers/jdt_ls"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                    chmod g+rx,o+rx $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                
                #Mover todos archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.tar.gz"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_target_bin} \;

            else
                
                l_path_target_bin="${g_path_programs_win}/LSP_Servers/JDT_LS"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover los archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.tar.zp"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_target_bin} \;
            fi
            ;;


        runc)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${l_path_source}/runc.amd64\" a \"${l_path_source}/runc\""
            mv "${l_path_source}/runc.amd64" "${l_path_source}/runc"

            echo "Copiando \"runc\" a \"${l_path_target_bin}\" ..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                cp "${l_path_source}/runc" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/runc"
            else
                sudo cp "${l_path_source}/runc" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/runc"
            fi

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;



        crun)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'podman' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "podman" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            fi

            request_stop_systemd_unit 'podman.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${l_path_source}/crun-${p_repo_last_version_pretty}-linux-amd64\" a \"${l_path_source}/crun\""
            mv "${l_path_source}/crun-${p_repo_last_version_pretty}-linux-amd64" "${l_path_source}/crun"

            echo "Copiando \"crun\" a \"${l_path_target_bin}\" ..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                cp "${l_path_source}/crun" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/crun"
            else
                sudo cp "${l_path_source}/crun" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/crun"
            fi

            #4. Si la unidad servicio 'podman' estaba iniciando y se detuvo, iniciarlo
            #if [ $l_status -eq 3 ]; then
            if [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'podman.service'
                if [ $g_user_is_root -eq 0 ]; then
                    systemctl start podman.service 
                else
                    sudo systemctl start podman.service 
                fi
            fi
            ;;


        slirp4netns)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd.io' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${l_path_source}/slirp4netns-x86_64\" a \"${l_path_source}/slirp4netns\""
            mv "${l_path_source}/slirp4netns-x86_64" "${l_path_source}/slirp4netns"

            echo "Copiando \"${l_path_source}/slirp4netns\" a \"${l_path_target_bin}\" ..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                cp "${l_path_source}/slirp4netns" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/slirp4netns"
            else
                sudo cp "${l_path_source}/slirp4netns" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/slirp4netns"
            fi

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_user_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        fuse-overlayfs)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd.io' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${l_path_source}/fuse-overlayfs-x86_64\" a \"${l_path_source}/fuse-overlayfs\""
            mv "${l_path_source}/fuse-overlayfs-x86_64" "${l_path_source}/fuse-overlayfs"

            echo "Copiando \"${l_path_source}/fuse-overlayfs\" a \"${l_path_target_bin}\" ..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                cp "${l_path_source}/fuse-overlayfs" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/fuse-overlayfs"
            else
                sudo cp "${l_path_source}/fuse-overlayfs" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/fuse-overlayfs"
            fi

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_user_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        rootlesskit)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                echo "Copiando \"${l_path_source}/rootlesskit-docker-proxy\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/rootlesskit-docker-proxy" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/rootlesskit-docker-proxy"

                echo "Copiando \"${l_path_source}/rootlesskit\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/rootlesskit" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/rootlesskit"

                echo "Copiando \"${l_path_source}/rootlessctl\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/rootlessctl" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/rootlessctl"

            else

                echo "Copiando \"${l_path_source}/rootlesskit-docker-proxy\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/rootlesskit-docker-proxy" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/rootlesskit-docker-proxy"

                echo "Copiando \"${l_path_source}/rootlesskit\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/rootlesskit" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/rootlesskit"

                echo "Copiando \"${l_path_source}/rootlessctl\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/rootlessctl" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/rootlessctl"

            fi

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_user_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;



        cni-plugins)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            l_path_target_bin="${g_path_programs}/cni_plugins"

            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi
            

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Configurar: Si no existe el directorio
            if  [ ! -d "$l_path_target_bin" ]; then

                #Crear las carpeta
                echo "Creando la carpeta \"${l_path_target_bin}\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    mkdir -pm 755 $l_path_target_bin
                else
                    sudo mkdir -pm 755 $l_path_target_bin
                fi

                #Copiando los binarios
                echo "Copiando los binarios de \"${l_path_source}\" a \"${l_path_target_bin}\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_target_bin} \;
                    chmod +x ${l_path_target_bin}/*
                else
                    sudo find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_target_bin} \;
                    sudo chmod +x ${l_path_target_bin}/*
                fi

            #4. Configurar: Si existe el directorio: actualizar
            else

                #Elimimiando los binarios
                echo "Eliminando los binarios de \"${l_path_target_bin}\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    rm ${l_path_target_bin}/*
                else
                    sudo rm ${l_path_target_bin}/*
                fi

                #Copiando los binarios
                echo "Copiando los nuevos binarios de \"${l_path_source}\" a \"${l_path_target_bin}\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_target_bin} \;
                    chmod +x ${l_path_target_bin}/*
                else
                    sudo find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_target_bin} \;
                    sudo chmod +x ${l_path_target_bin}/*
                fi

            fi

            #5. Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            echo "$p_repo_last_version_pretty" > "${g_path_programs}/cni-plugins.info" 

            #6. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_user_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        containerd)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/bin"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi


            #3. Configurar: Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                echo "Copiando \"${l_path_source}/containerd-shim\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/containerd-shim" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/containerd-shim"

                echo "Copiando \"${l_path_source}/containerd-shim-runc-v1\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/containerd-shim-runc-v1" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/containerd-shim-runc-v1"

                echo "Copiando \"${l_path_source}/containerd-shim-runc-v2\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/containerd-shim-runc-v2" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/containerd-shim-runc-v2"

                echo "Copiando \"${l_path_source}/containerd-stress\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/containerd-stress" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/containerd-stress"

                echo "Copiando \"${l_path_source}/ctr\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/ctr" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/ctr"

                echo "Copiando \"${l_path_source}/containerd\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/containerd" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/containerd"

            else

                echo "Copiando \"${l_path_source}/containerd-shim\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/containerd-shim" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/containerd-shim"

                echo "Copiando \"${l_path_source}/containerd-shim-runc-v1\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/containerd-shim-runc-v1" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/containerd-shim-runc-v1"

                echo "Copiando \"${l_path_source}/containerd-shim-runc-v2\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/containerd-shim-runc-v2" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/containerd-shim-runc-v2"

                echo "Copiando \"${l_path_source}/containerd-stress\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/containerd-stress" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/containerd-stress"

                echo "Copiando \"${l_path_source}/ctr\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/ctr" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/ctr"

                echo "Copiando \"${l_path_source}/containerd\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/containerd" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/containerd"

            fi

            #Descargar archivo de configuracion como servicio a nivel system:
            mkdir -p ~/.files/setup/programs/nerdctl/systemd/user
            
            printf 'Descargando el archivo de configuracion de "%s" a nivel system en "%s"\n' "containerd.service" "~/.files/setup/programs/nerdctl/systemd/user/"
            curl -fLo ~/.files/setup/programs/nerdctl/systemd/user/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 2 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 3 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_user_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi

            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:
            if [ $l_status -eq 0 ]; then

                printf 'El artefacto de "%s" aun no esta aun esta instalada. Se recomiendo crear una unidad systemd "%s" para gestionar su inicio y detención.\n' "$p_repo_id" "containerd.service"
                printf 'Para instalar "%s" tiene 2 opciones:\n' "$p_repo_id"
                printf '%b1> Instalar en modo rootless%b (la unidad "%s" se ejecutara en modo user)%b:%b\n' "$g_color_info" "$g_color_opaque" "containerd.service" "$g_color_info" "$g_color_reset"
                printf '%b   export PATH="$PATH:$HOME/.files/setup/programs/nerdctl"%b\n' "$g_color_info" "$g_color_reset"
                printf '%b   containerd-rootless-setuptool.sh install%b\n' "$g_color_info" "$g_color_reset"
                printf '%b   Opcional:%b\n' "$g_color_opaque" "$g_color_reset"
                printf '%b      > Para ingresar al user-namespace creado use:%b containerd-rootless-setuptool.sh nsenter bash%b\n' "$g_color_opaque" "$g_color_info" "$g_color_reset"
                printf '%b      > Establezca el servicio containerd para inicio manual:%b systemctl --user disable containerd.service%b\n' "$g_color_opaque" "$g_color_info" "$g_color_reset"
                printf '%b2> Instalar en modo root%b (la unidad "%s" se ejecutara en modo system)%b:%b\n' "$g_color_info" "$g_color_opaque" "containerd.service" "$g_color_info" "$g_color_reset"
                printf '%b   sudo cp ~/.files/setup/programs/nerdctl/systemd/system/containerd.service /usr/lib/systemd/system/%b\n' "$g_color_info" "$g_color_reset"
                #printf '%b   sudo systemctl daemon-reload%b\n' "$g_color_info" "$g_color_reset"
                printf '%b   sudo systemctl start containerd%b\n' "$g_color_info" "$g_color_reset"                 

            fi
            ;;


        buildkit)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/bin"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            request_stop_systemd_unit 'buildkit.service' 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Configurar: Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                echo "Copiando \"${l_path_source}/buildkit-runc\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/buildkit-runc" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/buildkit-runc"

                echo "Copiando \"${l_path_source}/buildkitd\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/buildkitd" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/buildkitd"

                echo "Copiando \"${l_path_source}/buildkit-qemu-*\" a \"${l_path_target_bin}\" ..."
                cp ${l_path_source}/buildkit-qemu-* "${l_path_target_bin}"
                chmod +x ${l_path_target_bin}/buildkit-qemu-*

                echo "Copiando \"${l_path_source}/buildctl\" a \"${l_path_target_bin}\" ..."
                cp "${l_path_source}/buildctl" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/buildctl"

            else

                echo "Copiando \"${l_path_source}/buildkit-runc\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/buildkit-runc" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/buildkit-runc"

                echo "Copiando \"${l_path_source}/buildkitd\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/buildkitd" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/buildkitd"

                echo "Copiando \"${l_path_source}/buildkit-qemu-*\" a \"${l_path_target_bin}\" ..."
                sudo cp ${l_path_source}/buildkit-qemu-* "${l_path_target_bin}"
                sudo chmod +x ${l_path_target_bin}/buildkit-qemu-*

                echo "Copiando \"${l_path_source}/buildctl\" a \"${l_path_target_bin}\" ..."
                sudo cp "${l_path_source}/buildctl" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/buildctl"

            fi

            #Descargar archivo de configuracion como servicio a nivel system:
            mkdir -p ~/.files/setup/programs/nerdctl/systemd/system
            mkdir -p ~/.files/setup/programs/nerdctl/systemd/user
            
            printf 'Descargando el archivo de configuracion de "%s" a nivel usuario en "%s"\n' "buildkit.service" "~/.files/setup/programs/nerdctl/systemd/user/"
            curl -fLo ~/.files/setup/programs/nerdctl/systemd/user/buildkit.service https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/user/buildkit.service
            printf 'Descargando el archivo de configuracion de "%s" a nivel usuario en "%s"\n' "buildkit.socket" "~/.files/setup/programs/nerdctl/systemd/user/"
            curl -fLo ~/.files/setup/programs/nerdctl/systemd/user/buildkit.socket https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/user/buildkit.socket

            printf 'Descargando el archivo de configuracion de "%s" a nivel sistema en "%s"\n' "buildkit.service" "~/.files/setup/programs/nerdctl/systemd/system/"
            curl -fLo ~/.files/setup/programs/nerdctl/systemd/system/buildkit.service https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.service
            printf 'Descargando el archivo de configuracion de "%s" a nivel sistema en "%s"\n' "buildkit.socket" "~/.files/setup/programs/nerdctl/systemd/system/"
            curl -fLo ~/.files/setup/programs/nerdctl/systemd/system/buildkit.socket https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.socket


            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:            
            if [ $l_status -eq 0 ]; then

                printf 'El artefacto de "%s" aun no esta aun esta instalada. Se recomiendo crear una unidad systemd "%s" para gestionar su inicio y detención.\n' "$p_repo_id" "buildkit.service"
                printf 'Para instalar "%s" tiene 2 opciones:\n' "$p_repo_id"
                printf '%b1> Instalar en modo rootless%b (la unidad "%s" se ejecutara en modo user)%b:%b\n' "$g_color_info" "$g_color_opaque" "buildkit.service" "$g_color_info" "$g_color_reset"
                printf '%b   export PATH="$PATH:$HOME/.files/setup/programs/nerdctl"%b\n' "$g_color_info" "$g_color_reset"
                printf '%b   containerd-rootless-setuptool.sh install-buildkit%b\n' "$g_color_info" "$g_color_reset"
                printf '%b   Opcional:%b\n' "$g_color_opaque" "$g_color_reset"
                printf '%b      > Para ingresar al user-namespace creado use:%b containerd-rootless-setuptool.sh nsenter bash%b\n' "$g_color_opaque" "$g_color_info" "$g_color_reset"
                printf '%b      > Establezca el servicio buildkit para inicio manual:%b systemctl --user disable buildkit.service%b\n' "$g_color_opaque" "$g_color_info" "$g_color_reset"
                printf '%b2> Instalar en modo root%b (la unidad "%s" se ejecutara en modo system)%b:%b\n' "$g_color_info" "$g_color_opaque" "buildkit.service" "$g_color_info" "$g_color_reset"
                printf '%b   sudo cp ~/.files/setup/programs/nerdctl/systemd/system/buildkit.socket /usr/lib/systemd/system/%b\n' "$g_color_info" "$g_color_reset"
                printf '%b   sudo cp ~/.files/setup/programs/nerdctl/systemd/system/buildkit.service /usr/lib/systemd/system/%b\n' "$g_color_info" "$g_color_reset"
                #printf '%b   sudo systemctl daemon-reload%b\n' "$g_color_info" "$g_color_reset"
                printf '%b   sudo systemctl start buildkit.service%b\n' "$g_color_info" "$g_color_reset"                 

            fi
            ;;


        nerdctl)

            #1. Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            local l_status_stop=-1
          
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi


            #2. Configuración: Instalación de binario basico
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                    echo "Copiando \"${l_path_source}/nerdctl\" a \"${l_path_target_bin}\" ..."
                    cp "${l_path_source}/nerdctl" "${l_path_target_bin}"
                    chmod +x "${l_path_target_bin}/nerdctl"

                else

                    echo "Copiando \"${l_path_source}/nerdctl\" a \"${l_path_target_bin}\" ..."
                    sudo cp "${l_path_source}/nerdctl" "${l_path_target_bin}"
                    sudo chmod +x "${l_path_target_bin}/nerdctl"

                fi

                mkdir -p ~/.files/setup/programs/containerd

                #Archivos para instalar 'containerd' de modo rootless
                echo "Copiando \"${l_path_source}/containerd-rootless.sh\" (tool gestión del ContainerD en modo rootless) a \"~/.files/setup/programs/containerd\" ..."
                cp "${l_path_source}/containerd-rootless.sh" ~/.files/setup/programs/containerd
                chmod u+x ~/.files/setup/programs/containerd/containerd-rootless.sh

                echo "Copiando \"${l_path_source}/containerd-rootless-setuptool.sh\" (instalador de ContainerD en modo rootless)  a \"~/.files/setup/programs/containerd\" ..."
                cp "${l_path_source}/containerd-rootless-setuptool.sh" ~/.files/setup/programs/containerd
                chmod u+x ~/.files/setup/programs/containerd/containerd-rootless-setuptool.sh

            #3. Configuración: Instalación de binarios de complementos que su reposotrio no ofrece el compilado (solo la fuente). Para ello se usa el full
            else

                #3.1. Rutas de los artectos 
                l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}/bin"

                #3.2. Configurar 'rootless-containers/bypass4netns' usado para accelar 'Slirp4netns' (NAT o port-forwading de llamadas del exterior al contenedor)

                #Comparar la versión actual con la versión descargada
                _compare_version_current_with "bypass4netns" "$l_path_source" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then

                    #Instalar este artefacto requiere solicitar detener el servicio solo la versión actual existe
                    #Solo solicitarlo una vez
                    if [ $l_status_stop -ge 0 ]; then

                        is_package_installed 'containerd' $g_os_subtype_id
                        l_status_stop=$?

                        if [ $l_status_stop -eq 0 ]; then
                            printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
                        fi

                        request_stop_systemd_unit 'containerd.service' 1 "$p_repo_id" "$p_artifact_index"
                        l_status_stop=$?
                    fi

                    #Si no esta iniciado o si esta iniciado se acepta detenerlo, instalarlo
                    if [ $l_status_stop -ne 2 ]; then

                        printf 'Instalando el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s ...\n' "$p_artifact_index" "$p_repo_id"
                        #Instalando
                        if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                            echo "Copiando \"${l_path_source}/bypass4netns\" a \"${l_path_target_bin}\" ..."
                            cp "${l_path_source}/bypass4netns" "${l_path_target_bin}"
                            chmod +x "${l_path_target_bin}/bypass4netns"

                            echo "Copiando \"${l_path_source}/bypass4netnsd\" a \"${l_path_target_bin}\" ..."
                            cp "${l_path_source}/bypass4netnsd" "${l_path_target_bin}"
                            chmod +x "${l_path_target_bin}/bypass4netnsd"

                        else

                            echo "Copiando \"${l_path_source}/bypass4netns\" a \"${l_path_target_bin}\" ..."
                            sudo cp "${l_path_source}/bypass4netns" "${l_path_target_bin}"
                            sudo chmod +x "${l_path_target_bin}/bypass4netns"

                            echo "Copiando \"${l_path_source}/bypass4netnsd\" a \"${l_path_target_bin}\" ..."
                            sudo cp "${l_path_source}/bypass4netnsd" "${l_path_target_bin}"
                            sudo chmod +x "${l_path_target_bin}/bypass4netnsd"

                        fi

                    else

                        printf 'No se instalará el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s.\n' "$p_artifact_index" "$p_repo_id"

                    fi

                fi

                #3.3. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
                if [ $l_status_stop -eq 3 ]; then

                    #Iniciar a nivel usuario
                    printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                    systemctl --user start containerd.service

                elif [ $l_status_stop -eq 4 ]; then

                    #Iniciar a nivel system
                    printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                    if [ $g_user_is_root -eq 0 ]; then
                        systemctl start containerd.service 
                    else
                        sudo systemctl start containerd.service 
                    fi
                fi

            fi
            ;;


        dive)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"${l_path_source}/dive\" a \"${l_path_target_bin}\" ..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                cp "${l_path_source}/dive" "${l_path_target_bin}"
                chmod +x "${l_path_target_bin}/dive"
            else
                sudo cp "${l_path_source}/dive" "${l_path_target_bin}"
                sudo chmod +x "${l_path_target_bin}/dive"
            fi
            ;;


        powershell)

            #Ruta local de los artefactos
            l_path_source="${g_path_temp}/${p_repo_id}/${p_artifact_index}"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_target_bin="${g_path_programs}/powershell"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                    chmod g+rx,o+rx $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover todos archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.tar.gz"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_target_bin} \;
                
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    chmod +x ${g_path_programs}/powershell/pwsh
                    ln -snf ${g_path_programs}/powershell/pwsh /usr/bin/pwsh
                else
                    sudo chmod +x ${g_path_programs}/powershell/pwsh
                    sudo ln -snf ${g_path_programs}/powershell/pwsh /usr/bin/pwsh
                fi

            else
                
                l_path_target_bin="${g_path_programs_win}/PowerShell"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_target_bin" ]; then
                    mkdir -p $l_path_target_bin
                else
                    #Limpieza
                    rm -rf ${l_path_target_bin}/*
                fi
                    
                #Mover los archivos
                #rm "${l_path_source}/${p_artifact_name_woext}.zip"
                find "${l_path_source}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_target_bin} \;
            fi
            ;;


        *)
           printf 'ERROR: No esta definido logica para el repositorio "%s" para procesar el artefacto "%b"\n' "$p_repo_id" "$l_tag"
           return 50
            
    esac

    return 0

}


#
#La inicialización del menú opcion de instalación (codigo que se ejecuta antes de instalar los repositorios de la opcion menú)
#Solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index (inicia en 0) de la opcion de menu elegista para instalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si inicializo con exito.
#  1 > No se inicializo por opcion del usuario.
#  2 > Hubo un error en la inicialización.
#
install_initialize_menu_option() {

    #1. Argumentos
    local p_option_relative_idx=$1

    #2. Inicialización
    local l_status
    local l_repo_id
    local l_artifact_index
    #local l_aux
    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #3. Realizar validaciones segun la opcion de menu escogida
    case "$p_option_relative_idx" in

        #Container Runtime 'ContainerD'
        6)
            #Los valores son solo para logs, pero se calcular manualmente
            l_repo_id='containerd'
            
            #1. Determinar si el paquete 'containerd.io' esta instalado en el sistema operativo
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            #Si existe el paquete no instalar nada
            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
                printf 'Solo se puede instalar si no se instalo usando el repositorio de github. No se puede desintalar si se instalo usando repositorio de paquetes del SO.\n'
                return 2
            fi
            ;;

        #Instalacion de DotNet (runtime o SDK o ambos)
        11|12)

            #Validar si algunos paquees necesarios estan instalados
            #https://learn.microsoft.com/en-us/dotnet/core/install/linux-fedora#dependencies
            #https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#dependencies
            
            #1. Obtener los paquetes que requeridos
            local la_packages_needed=()

            #Si es de la familia Fedora/CentOS
            if [ $g_os_subtype_id -ge 10 ] && [ $g_os_subtype_id -lt 30 ]; then

                #la_packages_needed=("krb5-libs" "libicu" "openssl-libs" "zlib" "compat-openssl10")
                la_packages_needed=("krb5-libs" "libicu" "openssl-libs" "zlib")

            #Si es de la familia Debian
            elif [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then

                #Existe diferentes paquetes para Debian y para Ubuntu que depende de la version
                
                #libc6
                #libgssapi-krb5-2
                #libstdc++6
                #zlib1g
                #
                la_packages_needed=("libc6" "libgssapi-krb5-2" "libstdc++6" "zlib1g")

                #libicu55          (Ubuntu 16.x)
                #libicu60          (Ubuntu 18.x)
                #libicu66          (Ubuntu 20.x)
                #libicu70          (Ubuntu 22.04)
                #libicu71          (Ubuntu 22.10)
                #libicu72          (Ubuntu 23.04, 23.10)
                #libicu63          (Debian 10.x)
                #libicu67          (Debian 11.x)
                #libicu72          (Debian 12.x)
                #
                if [ $g_os_subtype_id -eq 31 ]; then
                    if [[ "$g_os_subtype_version" =~ ^16\..+$ ]]; then
                        la_packages_needed+=("libicu55")
                    elif [[ "$g_os_subtype_version" =~ ^18\..+$ ]]; then
                        la_packages_needed+=("libicu60")
                    elif [[ "$g_os_subtype_version" =~ ^20\..+$ ]]; then
                        la_packages_needed+=("libicu66")
                    elif [ "$g_os_subtype_version" = "22.04" ]; then
                        la_packages_needed+=("libicu70")
                    elif [ "$g_os_subtype_version" = "22.10" ]; then
                        la_packages_needed+=("libicu71")
                    elif [[ "$g_os_subtype_version" =~ ^23\..+$ ]]; then
                        la_packages_needed+=("libicu72")
                    fi
                else
                    if [[ "$g_os_subtype_version" =~ ^10\..+$ ]]; then
                        la_packages_needed+=("libicu63")
                    elif [[ "$g_os_subtype_version" =~ ^11\..+$ ]]; then
                        la_packages_needed+=("libicu67")
                    elif [[ "$g_os_subtype_version" =~ ^12\..+$ ]]; then
                        la_packages_needed+=("libicu72")
                    fi
                fi

                #libssl1.0.0       (Ubuntu 16.x)
                #libssl1.1         (Debian/Ubuntu 18.x, 20.x)
                #libssl3           (Ubuntu 22.x, 23.x)
                #
                if [ $g_os_subtype_id -eq 31 ]; then
                    if [[ "$g_os_subtype_version" =~ ^16\..+$ ]]; then
                        la_packages_needed+=("libssl1.0.0")
                    elif [[ "$g_os_subtype_version" =~ ^18\..+$ ]]; then
                        la_packages_needed+=("libssl1.1")
                    elif [[ "$g_os_subtype_version" =~ ^20\..+$ ]]; then
                        la_packages_needed+=("libssl1.1")
                    elif [[ "$g_os_subtype_version" =~ ^22\..+$ ]]; then
                        la_packages_needed+=("libssl3")
                    elif [[ "$g_os_subtype_version" =~ ^23\..+$ ]]; then
                        la_packages_needed+=("libssl3")
                    fi
                else
                    la_packages_needed+=("libssl1.1")
                fi

                #libgcc1           (Debian/Ubuntu 16.x, 18.x, 20.x, 22.x)
                #libgcc-s1         (Debian/Ubuntu 22.x, 23.x)
                #liblttng-ust1     (Ubuntu 22.x, 23.x)
                #libunwind8        (Ubuntu 22.x, 23.x)
                #
                if [ $g_os_subtype_id -eq 31 ]; then
                    if [[ "$g_os_subtype_version" =~ ^22\..+$ ]]; then
                        la_packages_needed+=("libgcc1" "libgcc-s1" "liblttng-ust1" "libunwind8")
                    elif [[ "$g_os_subtype_version" =~ ^23\..+$ ]]; then
                        la_packages_needed+=("libgcc-s1" "liblttng-ust1" "libunwind8")
                    else
                        la_packages_needed+=("libgcc1" "libgcc-s1")
                    fi
                else
                    la_packages_needed+=("libgcc1" "libgcc-s1")
                fi


            fi

            #2. Determinar los paquetes que ya estan instalados
            local l_n=${#la_packages_needed[@]}
            local l_packages=''
            local l_package
            local l_i

            if [ $l_n -gt 0 ]; then

                for ((l_i=0; l_i < l_n; l_i++)); do

                    l_package="${la_packages_needed[$l_i]}"

                    #Buscar si el paquete esta instalado
                    is_package_installed "$l_package" $g_os_subtype_id
                    l_status=$?

                    if [ $l_status -eq 1 ]; then
                        if [ -z "$l_packages" ]; then
                            l_packages="$l_package"
                        else
                            l_packages="${l_package} ${l_packages}"
                        fi
                    else
                        printf '%bEl paquete "%s" requerido por .NET ya esta instalado.%b\n' "$g_color_opaque" "$l_package" "$g_color_reset"
                    fi

                done
            fi

            #3. Instalar los paquetes
            if [ ! -z "$l_packages" ]; then

                if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
                    printf '%bNo esta habilitada para instalar paquetes%b. Se recomienda que Instalé los paquetes "%b%s%b".\n' "$g_color_warning" "$g_color_reset" \
                        "$g_color_opaque" "$l_packages" "$g_color_reset"
                else
                    printf 'Se requiere instalar los paquetes "%b%s%b".\n' "$g_color_opaque" "$l_packages" "$g_color_reset"

                    #Solicitar credenciales de administrador y almacenarlas temporalmente
                    if [ $g_status_crendential_storage -eq 0 ]; then

                        #Solicitar credenciales de administrador y almacenarlas temporalmente
                        storage_sudo_credencial
                        g_status_crendential_storage=$?
                        #Se requiere almacenar las credenciales para realizar cambio con sudo. 
                        #  Si es 0 o 1: la instalación/configuración es completar
                        #  Si es 2    : el usuario no acepto la instalación/configuración
                        #  Si es 3 0 4: la instalacion/configuración es parcial (solo se instala/configura, lo que no requiere sudo)
                        if [ $g_status_crendential_storage -eq 2 ]; then
                            #return 120
                            return 2
                        fi
                    fi

                    #Instalar los paquetes
                    install_os_package "$l_packages" $g_os_subtype_id
                fi
            fi

            return 0
            ;;        

        *)
            return 0
            ;;
    esac

    #Por defecto, se debe continuar con la instalación
    return 0


}

#
#La finalización del menú opcion de instalación (codigo que se ejecuta despues de instalar todos los repositorios de la opcion de menú)
#Solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para instalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
install_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #Realizar validaciones segun la opcion de menu escogida

    #Por defecto, se debe continuar con la instalación
    return 0

}



#Codigo que se ejecuta cuando se inicializa la opcion de menu de desinstalación.
#La inicialización solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si inicializo con exito.
#  1 > No se inicializo por opcion del usuario.
#  2 > Hubo un error en la inicialización.
#
uninstall_initialize_menu_option() {

    #1. Argumentos
    local p_option_relative_idx=$1

    #2. Inicialización
    local l_status
    #local l_artifact_index
    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))
    
    #3. Preguntar antes de eliminar los archivos
    printf 'Se va ha iniciar con la desinstalación de los siguientes repositorios: '
    
    #Obtener los repositorios a configurar
    local l_aux="${ga_menu_options_packages[$l_i]}"
    local IFS=','
    local la_repos=(${l_aux})
    IFS=$' \t\n'

    local l_n=${#la_repos[@]}
    local l_repo_names=''
    local l_repo_id
    for((l_j=0; l_j < ${l_n}; l_j++)); do

        l_repo_id="${la_repos[${l_j}]}"
        l_aux="${gA_packages[${l_repo_id}]}"
        if [ -z "$l_aux" ]; then
            l_aux="$l_repo_id"
        fi

        if [ $l_j -eq 0 ]; then
            l_repo_names="'${g_color_opaque}${l_aux}${g_color_reset}'" 
        else
            l_repo_names="${l_repo_names}, '${g_color_opaque}${l_aux}${g_color_reset}'"
        fi

    done
    printf '%b\n' "$l_repo_names"

    printf "%b¿Desea continuar con la desinstalación de estos repositorios?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_warning" "$g_color_opaque" "$g_color_reset"
    read -rei 's' -p ': ' l_option
    if [ "$l_option" != "s" ]; then
        printf 'Se cancela la desinstalación de los repositorios\n'
        return 1
    fi

    #4. Realizar validaciones segun la opcion de menu escogida
    case "$p_option_relative_idx" in

        6)
            #Container Runtime 'ContainerD'
            #Los valores son solo para logs
            l_repo_id='containerd'
            
            #1. Determinar si el paquete 'containerd.io' esta instalado en el sistema operativo
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            #Si existe el paquete no desintalar nada
            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
                printf 'Solo se puede desinstalar si no se instalo usando el repositorio de github. No se puede desintalar si se instalo usando repositorio de paquetes del SO.\n'
                return 2
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            request_stop_systemd_unit 'containerd.service' 0 "$l_repo_id"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 1
            fi
        
            #"Tools para cualquier Container Runtime": BuildKit
            #Los valores son solo para logs
            l_repo_id='buildkit'
            
            #1. Determinar si el paquete 'containerd.io' esta instalado en el sistema operativo
            is_package_installed 'buildkit' $g_os_subtype_id
            l_status=$?

            #Si existe el paquete no desintalar nada
            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "buildkit" "$g_color_reset" "$g_color_warning" "$g_color_reset"
                printf 'Solo se puede desinstalar si no se instalo usando el repositorio de github. No se puede desintalar si se instalo usando repositorio de paquetes del SO.\n'
                return 2
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            request_stop_systemd_unit 'buildkit.service' 0 "$l_repo_id"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 1
            fi
            ;;

        *)
            return 0
            ;;
    esac

    #Por defecto, se debe continuar con la instalación
    return 0

}

#Codigo que se ejecuta cuando se finaliza la opcion de menu de desinstalación.
#La finalización solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
uninstall_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #Realizar validaciones segun la opcion de menu escogida

    #Por defecto, se debe continuar con la instalación
    return 0

}




#Only for test
_uninstall_repository2() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_current_version="$2"
    local p_install_win_cmds=1
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #2. Inicialización de variables
    local l_repo_name="${gA_packages[$p_repo_id]}"
    #local l_repo_name_aux="${l_repo_name:-$p_repo_id}"
    
    #Tag usuado para imprimir un identificador del artefacto en un log
    local l_tag="${p_repo_id}[${p_repo_current_version}]"

    printf 'No esta definido logica para desintalar los artectactos del repositorio "%s"\n' "$l_tag"
}

#
#Los argumentos de entrada son:
#  1 > ID del repositorio
#  2 > Nombre del repostorio
#  3 > Version del repositorio
#  4 > Flag '0' si es artefacto instalado en Windows (asociado a WSL2)
_uninstall_repository() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_current_version="$2"
    local p_install_win_cmds=1
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #2. Inicialización de variables
    local l_repo_name="${gA_packages[$p_repo_id]}"
    #local l_repo_name_aux="${l_repo_name:-$p_repo_id}"

    #local l_path_source=""

    #local l_path_target_man=""
    local l_path_target_bin=""
    if [ $p_install_win_cmds -ne 0 ]; then
        l_path_target_bin="$g_path_bin"
        #l_path_target_man="$g_path_man"
    else
        l_path_target_bin="$g_path_bin_win"
        #l_path_target_man="$g_path_man_win"
    fi

    local l_status
    local l_flag_uninstall
    local l_aux

    case "$p_repo_id" in


        runc)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi

            #2. Eliminando los archivos
            echo "Eliminado \"runc\" de \"${l_path_target_bin}\" ..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                rm "${l_path_target_bin}/runc"
            else
                sudo rm "${l_path_target_bin}/runc"
            fi
            ;;


        slirp4netns)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos 
            echo "Eliminando \"slirp4netns\" de \"${l_path_target_bin}\" ..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                if [ -f "${l_path_target_bin}/slirp4netns" ]; then
                    rm "${l_path_target_bin}/slirp4netns"
                fi
            else
                if [ -f "${l_path_target_bin}/slirp4netns" ]; then
                    sudo rm "${l_path_target_bin}/slirp4netns"
                fi
            fi
            ;;


        rootlesskit)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos 
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                if [ -f "${l_path_target_bin}/rootlesskit-docker-proxy" ]; then
                    echo "Eliminando \"rootlesskit-docker-proxy\" a \"${l_path_target_bin}\" ..."
                    rm "${l_path_target_bin}/rootlesskit-docker-proxy"
                fi

                if [ -f "${l_path_target_bin}/rootlesskit" ]; then
                    echo "Eliminando \"rootlesskit\" a \"${l_path_target_bin}\" ..."
                    rm "${l_path_target_bin}/rootlesskit"
                fi

                if [ -f "${l_path_target_bin}/rootlessctl" ]; then
                    echo "Eliminando \"rootlessctl\" a \"${l_path_target_bin}\" ..."
                    rm "${l_path_target_bin}/rootlessctl"
                fi

            else

                if [ -f "${l_path_target_bin}/rootlesskit-docker-proxy" ]; then
                    echo "Eliminando \"rootlesskit-docker-proxy\" a \"${l_path_target_bin}\" ..."
                    sudo rm "${l_path_target_bin}/rootlesskit-docker-proxy"
                fi

                if [ -f "${l_path_target_bin}/rootlesskit" ]; then
                    echo "Eliminando\"rootlesskit\" a \"${l_path_target_bin}\" ..."
                    sudo rm "${l_path_target_bin}/rootlesskit"
                fi

                if [ -f "${l_path_target_bin}/rootlessctl" ]; then
                    echo "Eliminando \"rootlessctl\" a \"${l_path_target_bin}\" ..."
                    sudo rm "${l_path_target_bin}/rootlessctl"
                fi

            fi
            ;;



        cni-plugins)

            #1. Ruta local de los artefactos
            l_path_target_bin="${g_path_programs}/cni_plugins"

            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos
            if  [ -d "$l_path_target_bin" ]; then

                #Elimimiando los binarios
                echo "Eliminando los binarios de \"${l_path_target_bin}\" ..."
                if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
                    rm ${l_path_target_bin}/*
                else
                    sudo rm ${l_path_target_bin}/*
                fi

            fi

            #3. Eliminado el archivo para determinar la version actual
            rm "${g_path_programs}/cni-plugins.info" 
            ;;


        containerd)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi


            #2. Eliminando archivos 
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                if [ -f "${l_path_target_bin}/containerd-shim" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-shim\"..."
                    rm "${l_path_target_bin}/containerd-shim"
                fi

                if [ -f "${l_path_target_bin}/containerd-shim-runc-v1" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-shim-runc-v1\"..."
                    rm "${l_path_target_bin}/containerd-shim-runc-v1"
                fi

                if [ -f "${l_path_target_bin}/containerd-shim-runc-v2" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-shim-runc-v2\"..."
                    rm "${l_path_target_bin}/containerd-shim-runc-v2"
                fi

                if [ -f "${l_path_target_bin}/containerd-stress" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-stress\"..."
                    rm "${l_path_target_bin}/containerd-stress"
                fi

                if [ -f "${l_path_target_bin}/ctr" ]; then
                    echo "Eliminando \"${l_path_target_bin}/ctr\"..."
                    rm "${l_path_target_bin}/ctr"
                fi

                if [ -f "${l_path_target_bin}/containerd" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd\"..."
                    rm "${l_path_target_bin}/containerd"
                fi

            else

                if [ -f "${l_path_target_bin}/containerd-shim" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-shim\"..."
                    sudo rm "${l_path_target_bin}/containerd-shim"
                fi

                if [ -f "${l_path_target_bin}/containerd-shim-runc-v1" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-shim-runc-v1\"..."
                    sudo rm "${l_path_target_bin}/containerd-shim-runc-v1"
                fi

                if [ -f "${l_path_target_bin}/containerd-shim-runc-v2" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-shim-runc-v2\"..."
                    sudo rm "${l_path_target_bin}/containerd-shim-runc-v2"
                fi

                if [ -f "${l_path_target_bin}/containerd-stress" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd-stress\"..."
                    sudo rm "${l_path_target_bin}/containerd-stress"
                fi

                if [ -f "${l_path_target_bin}/ctr" ]; then
                    echo "Eliminando \"${l_path_target_bin}/ctr\" ..."
                    sudo rm "${l_path_target_bin}/ctr"
                fi

                if [ -f "${l_path_target_bin}/containerd" ]; then
                    echo "Eliminando \"${l_path_target_bin}/containerd\"..."
                    sudo rm "${l_path_target_bin}/containerd"
                fi

            fi

            #3. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo

            #Buscar si esta instalado a nive usuario
            local l_is_user=0
            exist_systemd_unit "containerd.service" $l_is_user
            l_status=$?   #  0 > La unidad no esta instalada (no tiene archivo de configuracion): 
                          #  1 > La unidad instalada pero aun no esta en cache (no ha sido ejecutada desde el inicio del SO)
                          #  2 > La unidad instalada, en cache, pero marcada para no iniciarse ('unmask', 'inactive').
                          #  3 > La unidad instalada, en cache, pero no iniciado ('loaded', 'inactive').
                          #  4 > La unidad instalada, en cache, iniciado y aun ejecutandose ('loaded', 'active'/'running').
                          #  5 > La unidad instalada, en cache, iniciado y esperando peticionese ('loaded', 'active'/'waiting').
                          #  6 > La unidad instalada, en cache, iniciado y terminado ('loaded', 'active'/'exited' or 'dead').
                          #  7 > La unidad instalada, en cache, iniciado pero se desconoce su subestado.
                          # 99 > La unidad instalada, en cache, pero no se puede leer su información.
        
            if [ $l_status -eq 0 ]; then
        
                #Averiguar si esta instalado a nivel system
                l_is_user=1
                exist_systemd_unit "containerd.service" $l_is_user
                l_status=$?
       
               #Si no esta instalado en nivel user ni system 
                if [ $l_status -eq 0 ]; then
                    return 0
                fi
            fi

            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:
            l_aux="containerd.service"

            if [ $l_status -ne 0 ]; then

                if [ $l_is_user -eq 0 ]; then

                    if [ -f ~/.config/systemd/user/${l_aux} ]; then

                        #Si esta configurado para inicio automatico desactivarlo
                        printf "Disable la unidad systemd '%s'" "$l_aux"
                        systemctl --user disable $l_aux

                        echo "Eliminando la configuración '~/.config/systemd/user/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                        rm ~/.config/systemd/user/${l_aux}

                        #Recargar el arbol de dependencies cargados por systemd
                        printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                        systemctl --user daemon-reload
                    fi

                else

                    if [ -f /usr/lib/systemd/system/${l_aux} ]; then

                        if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            systemctl daemon-reload

                        else

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            sudo systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            sudo rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            sudo systemctl daemon-reload

                        fi
                    fi

                fi
            fi
            ;;


        buildkit)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando archivos 
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                if [ -f "${l_path_target_bin}/buildkit-runc" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildkit-runc\"..."
                    rm "${l_path_target_bin}/buildkit-runc"
                fi

                if [ -f "${l_path_target_bin}/buildkitd" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildkitd\"..."
                    rm "${l_path_target_bin}/buildkitd"
                fi

                if [ -f "${l_path_target_bin}/buildkit-qemu-*" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildkit-qemu-*\"..."
                    rm ${l_path_target_bin}/buildkit-qemu-*
                fi

                if [ -f "${l_path_target_bin}/buildctl" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildctl\"..."
                    rm "${l_path_target_bin}/buildctl"
                fi

            else

                if [ -f "${l_path_target_bin}/buildkit-runc" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildkit-runc\"..."
                    sudo rm "${l_path_target_bin}/buildkit-runc"
                fi

                if [ -f "${l_path_target_bin}/buildkitd" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildkitd\"..."
                    sudo rm "${l_path_target_bin}/buildkitd"
                fi

                if [ -f "${l_path_target_bin}/buildkit-qemu-*" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildkit-qemu-*\"..."
                    sudo rm ${l_path_target_bin}/buildkit-qemu-*
                fi

                if [ -f "${l_path_target_bin}/buildctl" ]; then
                    echo "Eliminando \"${l_path_target_bin}/buildctl\"..."
                    sudo rm "${l_path_target_bin}/buildctl"
                fi

            fi

            #3. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo

            #Buscar si esta instalado a nive usuario
            local l_is_user=0
            exist_systemd_unit "buildkit.service" $l_is_user
            l_status=$?   #  1 > La unidad instalada pero aun no esta en cache (no ha sido ejecutada desde el inicio del SO)
                          #  2 > La unidad instalada, en cache, pero marcada para no iniciarse ('unmask', 'inactive').
                          #  3 > La unidad instalada, en cache, pero no iniciado ('loaded', 'inactive').
                          #  4 > La unidad instalada, en cache, iniciado y aun ejecutandose ('loaded', 'active'/'running').
                          #  5 > La unidad instalada, en cache, iniciado y esperando peticionese ('loaded', 'active'/'waiting').
                          #  6 > La unidad instalada, en cache, iniciado y terminado ('loaded', 'active'/'exited' or 'dead').
                          #  7 > La unidad instalada, en cache, iniciado pero se desconoce su subestado.
                          # 99 > La unidad instalada, en cache, pero no se puede leer su información.
        
            if [ $l_status -eq 0 ]; then
        
                #Averiguar si esta instalado a nivel system
                l_is_user=1
                exist_systemd_unit "buildkit.service" $l_is_user
                l_status=$?
        
               #Si no esta instalado en nivel user ni system 
                if [ $l_status -eq 0 ]; then
                    return 0
                fi
            fi

            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:
            l_aux="buildkit.service"

            if [ $l_status -ne 0 ]; then

                if [ $l_is_user -eq 0 ]; then

                    if [ -f ~/.config/systemd/user/${l_aux} ]; then

                        #Si esta configurado para inicio automatico desactivarlo
                        printf "Disable la unidad systemd '%s'" "$l_aux"
                        systemctl --user disable $l_aux

                        echo "Eliminando la configuración '~/.config/systemd/user/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                        rm ~/.config/systemd/user/${l_aux}

                        #Recargar el arbol de dependencies cargados por systemd
                        printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                        systemctl --user daemon-reload
                    fi

                else

                    if [ -f /usr/lib/systemd/system/${l_aux} ]; then

                        if [ $g_user_is_root -eq 0 ]; then

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            systemctl daemon-reload

                        else

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            sudo systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            sudo rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            sudo systemctl daemon-reload

                        fi
                    fi

                fi
            fi
            ;;


        nerdctl)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                if [ -f "${l_path_target_bin}/nerdctl" ]; then
                    echo "Eliminando \"${l_path_target_bin}/nerdctl\"..."
                    rm "${l_path_target_bin}/nerdctl"
                fi

            else

                if [ -f "${l_path_target_bin}/nerdctl" ]; then
                    echo "Eliminando \"${l_path_target_bin}/nerdctl\"..."
                    sudo rm "${l_path_target_bin}/nerdctl"
                fi

            fi

            #3. Eliminando archivos del programa "bypass4netns" (acelerador de "Slirp4netns")
            #is_package_installed 'containerd' $g_os_subtype_id
            #l_status=$?

            #if [ $l_status -eq 0 ]; then

            #    printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_warning" "containerd.io" "$g_color_reset" "$g_color_warning" "$g_color_reset"
            #    printf 'No se desinstalará el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s.\n' "$p_artifact_index" "$p_repo_id"
            #    return 0

            #else

            #    printf 'Desinstalando el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s ...\n' "$p_artifact_index" "$p_repo_id"

            #    #Instalando
            #    if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

            #        echo "Eliminando \"${l_path_target_bin}/bypass4netns\"..."
            #        rm "${l_path_target_bin}/bypass4netns"

            #        echo "Eliminando \"${l_path_target_bin}/bypass4netnsd\"..."
            #        rm "${l_path_target_bin}/bypass4netnsd"

            #    else

            #        echo "Eliminando \"${l_path_target_bin}/bypass4netns\"..."
            #        sudo rm "${l_path_target_bin}/bypass4netns"

            #        echo "Eliminando \"${l_path_target_bin}/bypass4netnsd\"..."
            #        sudo rm "${l_path_target_bin}/bypass4netnsd"

            #    fi

            #fi
            ;;


        dive)

            #Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Eliminando \"${l_path_target_bin}/dive\"..."
            if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then

                if [ -f "${l_path_target_bin}/dive" ]; then
                    echo "Eliminando \"${l_path_target_bin}/dive\"..."
                    rm "${l_path_target_bin}/dive"
                fi

            else

                if [ -f "${l_path_target_bin}/dive" ]; then
                    echo "Eliminando \"${l_path_target_bin}/dive\"..."
                    sudo rm "${l_path_target_bin}/dive"
                fi

            fi
            ;;


        *)
            printf 'No esta definido logica para desintalar los artectactos del repositorio "%s"\n' "$l_tag"
            return 50
            ;;
    esac

    return 0

}


#}}}









