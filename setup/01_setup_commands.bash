#!/bin/bash

#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/setup/basic_functions.bash

#Variable global pero solo se usar localmente en las funciones
t_tmp=""

#Determinar la clase del SO
#  00 - 10: Si es Linux
#           00 - Si es Linux generico
#           01 - Si es WSL2
#  11 - 20: Si es Unix
#  21 - 30: si es MacOS
#  31 - 40: Si es Windows
m_get_os_type
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
#  00 : Distribución de Linux desconocido
#  01 : Ubuntu
#  02 : Fedora
if [ $g_os_type -le 10 ]; then
    t_tmp=$(m_get_linux_type_id)
    declare -r g_os_subtype_id=$?
    declare -r g_os_subtype_name="$t_tmp"
    t_tmp=$(m_get_linux_type_version)
    declare -r g_os_subtype_version="$t_tmp"
fi

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi

#Variable global de la ruta donde los programas se instalaran (complejos) 
declare -r g_path_lnx_programs='/opt/tools'

#Variable global ruta de los programas CLI y/o binarios en Windows desde su WSL2
if [ $g_os_type -eq 1 ]; then
   declare -r g_path_win_programs='/mnt/d/Tools/CLI'
   declare -r g_path_win_commands="${g_path_win_programs}/Cmds"
fi

#Expresiones regulares de sustitucion mas usuadas para las versiones
#Se extrae la 1ra subcadena que inicie con enteros 0-9 y continue con . y luego continue con cualquier caracter que solo sea 0-9 o . o -
declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
declare -r g_regexp_sust_version2='s/[^0-9]*\([0-9]\+\.[0-9.-]\+\).*/\1/'
declare -r g_regexp_sust_version3='s/[^0-9]*\([0-9.]\+\).*/\1/'

#Cuando no se puede determinar la version actual (siempre se instalara)
declare -r g_version_none='0.0.0'

#}}}

#Funciones especificas {{{

#Solo se invoca cuando se instala con exito un repositorio y sus artefactos
function m_show_final_message() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_install_win_cmds=1         #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                       #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$2" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    case "$p_repo_id" in
        fzf)

            if [ $p_install_win_cmds -eq 0 ]; then
                echo "En Windows, debe homologar los plugins de \"FZF\" de VIM y NeoVim para tener soporte a powershell:"
                echo "   1. Homologar el plugin \"FZF base\" tanto en VIM como NeoVim:"
                echo '      Ultimo vs Fixed  > vim -d ${env:USERPROFILE}\.files\vim\packages\fzf\plugin\fzf.vim ${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim'
                echo '      Validar Soft-Link> dir ${env:USERPROFILE}\vimfiles\pack\ui\opt\'
                echo '                       > MKLINK /D %USERPROFILE%\vimfiles\pack\ui\opt\fzf %USERPROFILE%\.files\vim\packages\fzf'
                echo '      Validar Soft-Link> dir ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\'
                echo '                       > MKLINK /D %LOCALAPPDATA%\nvim-data\site\pack\ui\opt\fzf %USERPROFILE%\.files\vim\packages\fzf'
                echo "   2. Homologar el plugin \"FZF vim\" para VIM:"
                echo '      Obtener ultimo   > . ${env:USERPROFILE}\.files\setup\03_update_all.ps1'
                echo '                       > cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\'
                echo '                       > git restore autoload/fzf/vim.vim'
                echo '      Ultimo ->  Fixed > vim -d ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim'
                echo '      Fixed  ->  Vim   > cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim'
                echo '      Fixed  ->  NeoVim> cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim ${env:LOCALAPPDATA}\nvim-data\site\pack\packer\opt\fzf.vim\autoload\fzf\vim.vim' 
            fi
            ;;
        *)
            ;;
    esac
    
    echo "Se ha concluido la configuración de los artefactos del repositorio \"${p_repo_id}\""

}

#Determinar la version actual del repositorio usado para instalar los comandos instalados:
#  0 - Si existe y se obtiene un valor
#  1 - El comando no existe o existe un error en el comando para obtener la versión
#  2 - La version obtenida no tiene formato valido
#  3 - No existe forma de calcular la version actual (siempre se instala y/o actualizar)
#  9 - No esta implementado un metodo de obtener la version
function m_get_repo_current_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_install_win_cmds=1         #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                       #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$2" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    local p_path_file="$3"             #Ruta donde se obtendra el comando para obtener la versión

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
            l_path_file="${g_path_win_commands}/bin/"
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
        kustomize)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}kustomize.exe version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}kustomize version 2> /dev/null)
                l_status=$?
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
                  l_path_file="${g_path_win_programs}/Omnisharp_Roslyn/"
               else
                  l_path_file="${g_path_lnx_programs}/omnisharp_roslyn/"
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
                  l_path_file="${g_path_win_programs}/DAP_Adapters/NetCoreDbg/"
               else
                  l_path_file="${g_path_lnx_programs}/dap_adapters/netcoredbg/"
               fi
            fi

            #Obtener la version
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
            ;;

        neovim)
           
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_win_programs}/NeoVim/bin/"
               else
                  l_path_file="${g_path_lnx_programs}/neovim/bin/"
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
        nerd-fonts)
            #Siempre se actualizara la fuentes, por ahora no se puede determinar la version instalada
            echo "$g_version_none"
            return 3
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

#Devuelve un arreglo de artefectos, usando los argumentos 3 y 4 como de referencia:
#  - Argumento 4, un arreglo de tipo de artefacto donde cada item puede ser:
#    0 si es binario, 1 si es package, 2 si es un tar.gz, 3 si es un zip
#    99 si no se define el artefacto para el prefijo
#  - Argumento 3, un arreglo de nombre de los artectos a descargar
#En el argumento 2 se debe pasar la version pura quitando, sin contener "v" u otras letras iniciales
function m_load_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_last_version="$2"
    declare -n pna_artifact_names=$3   #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_artifact_types=$4   #Parametro por referencia: Se devuelve un arreglo de los tipos de los artefactos
    local p_install_win_cmds=1         #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                       #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$5" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi
    
    #2. Generar el nombre
    local l_artifact_name=""
    local l_artifact_type=99

    case "$p_repo_id" in
        jq)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("jq_linux64")
                pna_artifact_types=(0)
            else
                pna_artifact_names=("jq_win64.exe")
                pna_artifact_types=(0)
            fi
            ;;
        yq)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("yq_linux_amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("yq_windows_amd64.zip")
                pna_artifact_types=(3)
            fi
            ;;
        fzf)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("fzf-${p_repo_last_version}-linux_amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("fzf-${p_repo_last_version}-windows_amd64.zip")
                pna_artifact_types=(3)
            fi
            ;;
        helm)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("helm-v${p_repo_last_version}-linux-amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("helm-v${p_repo_last_version}-windows-amd64.zip")
                pna_artifact_types=(3)
            fi
            ;;
        delta)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("git-delta_${p_repo_last_version}_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("delta-${p_repo_last_version}-x86_64-unknown-linux-gnu.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("delta-${p_repo_last_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;
        ripgrep)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("ripgrep_${p_repo_last_version}_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("ripgrep-${p_repo_last_version}-x86_64-unknown-linux-musl.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("ripgrep-${p_repo_last_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;
        bat)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("bat_${p_repo_last_version}_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("bat-v${p_repo_last_version}-x86_64-unknown-linux-gnu.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("bat-v${p_repo_last_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;
        oh-my-posh)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("posh-linux-amd64" "themes.zip")
                pna_artifact_types=(0 3)
            else
                pna_artifact_names=("posh-windows-amd64.exe" "themes.zip")
                pna_artifact_types=(0 3)
            fi
            ;;
        fd)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("fd_${p_repo_last_version}_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("fd-v${p_repo_last_version}-x86_64-unknown-linux-gnu.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("fd-v${p_repo_last_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;
        kubectl)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("kubectl")
                pna_artifact_types=(0)
            else
                pna_artifact_names=("kubectl.exe")
                pna_artifact_types=(0)
            fi
            ;;
        less)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("less.exe" "lesskey.exe")
                pna_artifact_types=(0 0)
            else
                return 1
            fi
            ;;
        k0s)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("k0s-v${p_repo_last_version}+k0s.0-amd64")
                pna_artifact_types=(0)
            else
                pna_artifact_names=("k0s-v${p_repo_last_version}+k0s.0-amd64.exe")
                pna_artifact_types=(0)
            fi
            ;;
        kustomize)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("kustomize_v${p_repo_last_version}_linux_amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("kustomize_v${p_repo_last_version}_windows_amd64.tar.gz")
                pna_artifact_types=(2)
            fi
            ;;
        operator-sdk)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("operator-sdk_linux_amd64" "ansible-operator_linux_amd64" "helm-operator_linux_amd64")
                pna_artifact_types=(0 0 0)
            else
                return 1
            fi
            ;;
        roslyn)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("omnisharp-win-x64-net6.0.zip")
                pna_artifact_types=(3)
            else
                pna_artifact_names=("omnisharp-linux-x64-net6.0.tar.gz")
                pna_artifact_types=(2)
            fi
            ;;
        netcoredbg)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("netcoredbg-win64.zip")
                pna_artifact_types=(3)
            else
                pna_artifact_names=("netcoredbg-linux-amd64.tar.gz")
                pna_artifact_types=(2)
            fi
            ;;
        neovim)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    #pna_artifact_names=("nvim-linux64.deb")
                    #pna_artifact_types=(1)
                    pna_artifact_names=("nvim-linux64.tar.gz")
                    pna_artifact_types=(2)
                else
                    pna_artifact_names=("nvim-linux64.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("nvim-win64.zip")
                pna_artifact_types=(3)
            fi
            ;;
         nerd-fonts)
            pna_artifact_names=("JetBrainsMono.zip" "DroidSansMono.zip" "InconsolataLGC.zip" "UbuntuMono.zip" "3270.zip")
            pna_artifact_types=(3 3 3 3 3)
            ;;
       *)
           return 1
           ;;
    esac

    return 0
}


function m_get_repo_latest_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    #local p_install_win_cmds=1           #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
    #                                     #(0) Los binarios de los comandos se estan instalando en Linux
    
    #2. Obtener la version
    local l_repo_last_version=""
    local l_aux=""
    #local l_status=0

    case "$p_repo_id" in

        kubectl)
            #El artefacto se obtiene del repositorio de Kubernates
            l_repo_last_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
            ;;
        
        kustomize)
            l_repo_last_version=$(kubectl version --client=true -o json  | jq -r '.kustomizeVersion' 2> /dev/null)
            ;;

        *)
            #Artefecto se obtiene de un repository GitHub
            l_aux=$(curl -Ls -H 'Accept: application/json' "https://github.com/${p_repo_name}/releases/latest")
            #Si no esta instalado 'jq' usar expresiones regulares
            if ! command -v jq &> /dev/null; then
                l_repo_last_version=$(echo $l_aux | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
            else
                l_repo_last_version=$(echo $l_aux | jq -r .tag_name)
            fi
            ;;
    esac

    #Codificar en base64
    l_aux=$(m_url_encode "$l_repo_last_version")
    echo "$l_aux"
}


function m_get_artifact_url() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
    local p_artifact_name="$4"
    local p_install_win_cmds=1           #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                         #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$5" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    #2. Obtener la URL base
    local l_base_url=""
    case "$p_repo_id" in

        kubectl)

            if [ $p_install_win_cmds -eq 0 ]; then
                l_base_url="https://dl.k8s.io/release/${p_repo_last_version}/bin/windows/amd64"
            else
                l_base_url="https://dl.k8s.io/release/${p_repo_last_version}/bin/linux/amd64"
            fi
            ;;

        kustomize)
            l_base_url="https://github.com/${p_repo_name}/releases/download/kustomize%2F${p_repo_last_version}"
            ;;

        helm)
            l_base_url="https://get.helm.sh"
            ;;
            
        *)
            l_base_url="https://github.com/${p_repo_name}/releases/download/${p_repo_last_version}"
            ;;

    esac

    #3. Obtener la URL
    l_base_url="${l_base_url}/${p_artifact_name}"
    echo "$l_base_url"

}


function m_copy_artifact_files() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_artifact_index="$2"
    local p_artifact_name_woext="$3"
    local p_install_win_cmds=1           #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                         #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$4" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    local p_repo_current_version="$5"
    local p_artifact_is_last=$6

    #3. Copiar loa archivos del artefacto segun el prefijo
    local l_path_temp=""

    local l_path_man=""
    local l_path_bin=""
    if [ $p_install_win_cmds -ne 0 ]; then
        l_path_bin='/usr/local/bin'
        l_path_man='/usr/local/man/man1'
    else
        l_path_bin="${g_path_win_commands}/bin"
        l_path_man="${g_path_win_commands}/man"
    fi

    local l_repo_download_version=""
    local l_status=0
    local l_flag_install=1

    case "$p_repo_id" in

        bat)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"bat\" a \"${l_path_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/bat" "${l_path_bin}"
                    chmod +x "${l_path_bin}/bat"
                    mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/bat" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/bat"
                    sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/bat.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"bat.1\" a \"${l_path_man}/\" ..."
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/bat.1" "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/bat.1" "${l_path_man}"
                fi
            fi

            #Copiar los script de completado
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"autocomplete/bat.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_temp}/autocomplete/bat.bash" ~/.files/terminal/linux/complete/bat.bash
                echo "Copiando \"autocomplete/_bat.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                cp "${l_path_temp}/autocomplete/_bat.ps1" ~/.files/terminal/powershell/complete/bat.ps1
            fi
            ;;

        ripgrep)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"rg\" a \"${l_path_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/rg" "${l_path_bin}"
                    chmod +x "${l_path_bin}/rg"
                    mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/rg" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/rg"
                    sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/rg.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"doc/rg.1\" a \""${l_path_man}"/\" ..."
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/doc/rg.1" "${l_path_man}"/
                else
                    sudo cp "${l_path_temp}/doc/rg.1" "${l_path_man}"/
                fi
            fi

            #Copiar los script de completado
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"complete/rg.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_temp}/complete/rg.bash" ~/.files/terminal/linux/complete/rg.bash
                echo "Copiando \"autocomplete/_rg.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                cp "${l_path_temp}/complete/_rg.ps1" ~/.files/terminal/powershell/complete/rg.ps1
            fi
            ;;

        delta)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"delta\" a \"${l_path_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/delta" "${l_path_bin}"
                    chmod +x "${l_path_bin}/delta"
                    #mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/delta" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/delta"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/delta.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            
            ##Copiar los archivos de ayuda man para comando
            #if [ $p_install_win_cmds -ne 0 ]; then
            #    echo "Copiando \"doc/rg.1\" a \""${l_path_man}"/\" ..."
            #    if [ $g_is_root -eq 0 ]; then
            #        cp "${l_path_temp}/doc/rg.1" "${l_path_man}"/
            #    else
            #        sudo cp "${l_path_temp}/doc/rg.1" "${l_path_man}"/
            #    fi
            #fi

            ##Copiar los script de completado
            #if [ $p_install_win_cmds -ne 0 ]; then
            #    echo "Copiando \"complete/rg.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #    cp "${l_path_temp}/complete/rg.bash" ~/.files/terminal/linux/complete/rg.bash
            #    echo "Copiando \"autocomplete/_rg.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
            #    cp "${l_path_temp}/complete/_rg.ps1" ~/.files/terminal/powershell/complete/rg.ps1
            #fi
            ;;

        less)

            if [ $p_install_win_cmds -eq 0 ]; then

                #Ruta local de los artefactos
                l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                echo "Copiando \"less\" a \"${l_path_bin}\" ..."
                if [ $p_artifact_id -eq 0 ]; then
                    cp "${l_path_temp}/less.exe" "${l_path_bin}"
                else
                    cp "${l_path_temp}/lesskey.exe" "${l_path_bin}"
                fi

            else
                echo "ERROR (50): El artefacto[${p_artifact_id}] del repositorio \"${p_repo_id}\" solo esta habilitado para Windows"
                return 40
            fi            
            ;;

        fzf)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Copiar el comando fzf y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"fzf\" a \"${l_path_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/fzf" "${l_path_bin}"
                    chmod +x "${l_path_bin}/fzf"
                    mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/fzf" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/fzf"
                    sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/fzf.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            
            if [ $p_install_win_cmds -ne 0 ]; then

                #Descargar archivos necesarios
                echo "Descargando \"https://github.com/junegunn/fzf.git\" en el folder \"git/\" ..."
                git clone --depth 1 https://github.com/junegunn/fzf.git "${l_path_temp}/git"

                #Copiar los archivos de ayuda man para comando fzf y el script fzf-tmux
                echo "Copiando \"git/man/man1/fzf.1\" y \"git/man/man1/fzf-tmux.1\" a \"${l_path_man}/\" ..."
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/git/man/man1/fzf.1" "${l_path_man}"
                    cp "${l_path_temp}/git/man/man1/fzf-tmux.1" "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/git/man/man1/fzf.1" "${l_path_man}"
                    sudo cp "${l_path_temp}/git/man/man1/fzf-tmux.1" "${l_path_man}"
                fi

                #Copiar los archivos requeridos por el plugin vim base "fzf"
                mkdir -p ~/.files/vim/packages/fzf/doc
                mkdir -p ~/.files/vim/packages/fzf/plugin
                echo "Copiando \"git/doc/fzf.txt\" a \"~/.files/vim/packages/fzf/doc/\" ..."
                cp "${l_path_temp}/git/doc/fzf.txt" ~/.files/vim/packages/fzf/doc/
                echo "Copiando \"git/doc/fzf.vim\" a \"~/.files/vim/packages/fzf/plugin/\" ..."
                cp "${l_path_temp}/git/plugin/fzf.vim" ~/.files/vim/packages/fzf/plugin/

                #Copiar los archivos opcionales del plugin
                echo "Copiando \"git/LICENSE\" en \"~/.files/vim/packages/fzf/\" .."
                cp "${l_path_temp}/git/LICENSE" ~/.files/vim/packages/fzf/LICENSE
            
                #Copiar los script de completado
                echo "Copiando \"git/shell/completion.bash\" como \"~/.files/terminal/linux/complete/fzf.bash\" ..."
                cp "${l_path_temp}/git/shell/completion.bash" ~/.files/terminal/linux/complete/fzf.bash
            
                #Copiar los script de keybindings
                echo "Copiando \"git/shell/key-bindings.bash\" como \"~/.files/terminal/linux/keybindings/fzf.bash\" ..."
                cp "${l_path_temp}/git/shell/key-bindings.bash" ~/.files/terminal/linux/keybindings/fzf.bash
            
                # Script que se usara como comando para abrir fzf en un panel popup tmux
                echo "Copiando \"git/bin/fzf-tmux\" como \"~/.files/terminal/linux/functions/fzf-tmux.bash\" y crear un enlace como comando \"~/.local/bin/fzf-tmux\"..."
                cp "${l_path_temp}/git/bin/fzf-tmux" ~/.files/terminal/linux/functions/fzf-tmux.bash
                mkdir -p ~/.local/bin
                ln -sfn ~/.files/terminal/linux/functions/fzf-tmux.bash ~/.local/bin/fzf-tmux
            fi
            ;;

        jq)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"jq-linux64\" como \"${l_path_bin}/jq\" ..."
                mv "${l_path_temp}/jq-linux64" "${l_path_temp}/jq"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/jq" "${l_path_bin}"
                    chmod +x "${l_path_bin}/jq"
                    #mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/jq" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/jq"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                echo "Copiando \"jq-win64.exe\" como \"${l_path_bin}/jq.exe\" ..."
                mv "${l_path_temp}/jq-win64.exe" "${l_path_temp}/jq.exe"

                cp "${l_path_temp}/jq.exe" "${l_path_bin}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            #echo "Copiando \"jq.1\" a \"${l_path_man"/\" ..."
            #if [ $g_is_root -eq 0 ]; then
            #    cp "${l_path_temp}/jq.1" "${l_path_man}"
            #else
            #    sudo cp "${l_path_temp}/jq.1" "${l_path_man}"
            #fi

            #Copiar los script de completado
            #echo "Copiando \"autocomplete/jq.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #cp "${l_path_temp}/autocomplete/jq.bash" ~/.files/terminal/linux/complete/jq.bash
            #echo "Copiando \"autocomplete/_jq.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
            #cp "${l_path_temp}/autocomplete/jq.ps1" ~/.files/terminal/powershell/complete/jq.ps1
            ;;

        yq)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then

                echo "Copiando \"yq_linux_amd64\" como \"${l_path_bin}/yq\" ..."
                mv "${l_path_temp}/yq_linux_amd64" "${l_path_temp}/yq"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/yq" "${l_path_bin}"
                    chmod +x "${l_path_bin}/yq"
                    mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/yq" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/yq"
                    sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                echo "Copiando \"yq_windows_amd64.exe\" como \"${l_path_bin}/yq.exe\" ..."
                mv "${l_path_temp}/yq_windows_amd64.exe" "${l_path_temp}/yq.exe"

                cp "${l_path_temp}/yq.exe" "${l_path_bin}"
            fi

            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"yq.1\" a \"${l_path_man}/\" ..."
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/yq.1" "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/yq.1" "${l_path_man}"
                fi
            fi
            ;;
        
        oh-my-posh)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            if [ $p_artifact_index -eq 0 ]; then

                #Renombrar el binario antes de copiarlo
                if [ $p_install_win_cmds -ne 0 ]; then
                    echo "Copiando \"posh-linux-amd64\" como \"${l_path_bin}/oh-my-posh\" ..."
                    mv "${l_path_temp}/posh-linux-amd64" "${l_path_temp}/oh-my-posh"
                
                    #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                    if [ $g_is_root -eq 0 ]; then
                        cp "${l_path_temp}/oh-my-posh" "${l_path_bin}"
                        chmod +x "${l_path_bin}/oh-my-posh"
                        #mkdir -pm 755 "${l_path_man}"
                    else
                        sudo cp "${l_path_temp}/oh-my-posh" "${l_path_bin}"
                        sudo chmod +x "${l_path_bin}/oh-my-posh"
                        #sudo mkdir -pm 755 "${l_path_man}"
                    fi
                else
                    echo "Copiando \"posh-windows-amd64.exe\" como \"${l_path_bin}/oh-my-posh.exe\" ..."
                    mv "${l_path_temp}/posh-windows-amd64.exe" "${l_path_temp}/oh-my-posh.exe"

                    cp "${l_path_temp}/oh-my-posh.exe" "${l_path_bin}"
                fi
            
                #Copiar los archivos de ayuda man para comando
                #echo "Copiando \"yq.1\" a \"${l_path_man}/\" ..."
                #if [ $g_is_root -eq 0 ]; then
                #    cp "${l_path_temp}/yq.1" "${l_path_man}"
                #else
                #    sudo cp "${l_path_temp}/yq.1" "${l_path_man}"
                #fi

                #Copiar los script de completado
                #echo "Copiando \"autocomplete/yq.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                #cp "${l_path_temp}/autocomplete/yq.bash" ~/.files/terminal/linux/complete/yq.bash
                #echo "Copiando \"autocomplete/_yq.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                #cp "${l_path_temp}/autocomplete/yq.ps1" ~/.files/terminal/powershell/complete/yq.ps1
            else
                if [ $p_install_win_cmds -ne 0 ]; then
                    mkdir -p ~/.files/terminal/oh-my-posh/themes
                    cp -f ${l_path_temp}/*.json ~/.files/terminal/oh-my-posh/themes
                else
                    mkdir -p "${g_path_win_commands}/etc/oh-my-posh/themes"
                    cp -f ${l_path_temp}/*.json "${g_path_win_commands}/etc/oh-my-posh/themes"
                fi
            fi
            ;;

        fd)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"

            #Copiando el binario en una ruta del path
            echo "Copiando \"fd\" en \"${l_path_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/fd" "${l_path_bin}"
                    chmod +x "${l_path_bin}/fd"
                    mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/fd" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/fd"
                    sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/fd.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            
            #Copiar los archivos de ayuda man para comando
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"fd.1\" a \"${l_path_man}/\" ..."
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/fd.1" "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/fd.1" "${l_path_man}"
                fi
            fi

            #Copiar los script de completado
            if [ $p_install_win_cmds -ne 0 ]; then
                echo "Copiando \"autocomplete/fd.bash\" a \"~/.files/terminal/linux/complete/\" ..."
                cp "${l_path_temp}/autocomplete/fd.bash" ~/.files/terminal/linux/complete/fd.bash
                echo "Copiando \"autocomplete/fd.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
                cp "${l_path_temp}/autocomplete/fd.ps1" ~/.files/terminal/powershell/complete/fd.ps1
            fi
            ;;

        kubectl)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/kubectl" "${l_path_bin}"
                    chmod +x "${l_path_bin}/kubectl"
                    #mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/kubectl" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/kubectl"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/kubectl.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            
            ##Copiar los archivos de ayuda man para comando
            #echo "Copiando \"fd.1\" a \"${l_path_man}/\" ..."
            #if [ $g_is_root -eq 0 ]; then
            #    cp "${l_path_temp}/fd.1" "${l_path_man}"
            #else
            #    sudo cp "${l_path_temp}/fd.1" "${l_path_man}"
            #fi

            ##Copiar los script de completado
            #echo "Copiando \"autocomplete/fd.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #cp "${l_path_temp}/autocomplete/fd.bash" ~/.files/terminal/linux/complete/fd.bash
            #echo "Copiando \"autocomplete/fd.ps1\" a \"~/.files/terminal/powershell/complete/\" ..."
            #cp "${l_path_temp}/autocomplete/fd.ps1" ~/.files/terminal/powershell/complete/fd.ps1
            ;;
        
        helm)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                l_path_temp="${l_path_temp}/linux-amd64"
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/helm" "${l_path_bin}"
                    chmod +x "${l_path_bin}/helm"
                    #mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/helm" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/helm"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                l_path_temp="${l_path_temp}/windows-amd64"
                cp "${l_path_temp}/helm.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            ;;

        kustomize)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                #l_path_temp="${l_path_temp}/kustomize"
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/kustomize" "${l_path_bin}"
                    chmod +x "${l_path_bin}/kustomize"
                    #mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/kustomize" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/kustomize"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                #l_path_temp="${l_path_temp}/kustomize"
                cp "${l_path_temp}/kustomize.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            ;;


        operator-sdk)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then

                if [ $p_artifact_index -eq 0 ]; then

                   mv "${l_path_temp}/operator-sdk_linux_amd64" "${l_path_temp}/operator-sdk"
                   if [ $g_is_root -eq 0 ]; then
                      cp "${l_path_temp}/operator-sdk" "${l_path_bin}"
                      chmod +x "${l_path_bin}/operator-sdk"
                      #mkdir -pm 755 "${l_path_man}"
                   else
                      sudo cp "${l_path_temp}/operator-sdk" "${l_path_bin}"
                      sudo chmod +x "${l_path_bin}/operator-sdk"
                      #sudo mkdir -pm 755 "${l_path_man}"
                   fi

                elif [ $p_artifact_index -eq 1 ]; then

                   mv "${l_path_temp}/ansible-operator_linux_amd64" "${l_path_temp}/ansible-operator"
                   if [ $g_is_root -eq 0 ]; then
                      cp "${l_path_temp}/ansible-operator" "${l_path_bin}"
                      chmod +x "${l_path_bin}/ansible-operator"
                      #mkdir -pm 755 "${l_path_man}"
                   else
                      sudo cp "${l_path_temp}/ansible-operator" "${l_path_bin}"
                      sudo chmod +x "${l_path_bin}/ansible-operator"
                      #sudo mkdir -pm 755 "${l_path_man}"
                   fi

                else

                   mv "${l_path_temp}/helm-operator_linux_amd64" "${l_path_temp}/helm-operator"
                   if [ $g_is_root -eq 0 ]; then
                      cp "${l_path_temp}/helm-operator" "${l_path_bin}"
                      chmod +x "${l_path_bin}/helm-operator"
                      #mkdir -pm 755 "${l_path_man}"
                   else
                      sudo cp "${l_path_temp}/helm-operator" "${l_path_bin}"
                      sudo chmod +x "${l_path_bin}/helm-operator"
                      #sudo mkdir -pm 755 "${l_path_man}"
                   fi

                fi

            fi
            ;;


        k0s)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then

                echo "Copiando \"${p_artifact_name_woext}\" como \"${l_path_bin}/k0s\" ..."
                mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_temp}/k0s"

                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/k0s" "${l_path_bin}"
                    chmod +x "${l_path_bin}/k0s"
                else
                    sudo cp "${l_path_temp}/k0s" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/k0s"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                echo "Copiando \"${p_artifact_name_woext}.exe\" como \"${l_path_bin}/k0s.exe\" ..."
                mv "${l_path_temp}/${p_artifact_name_woext}.exe" "${l_path_temp}/k0s.exe"
                cp "${l_path_temp}/k0s.exe" "${l_path_bin}"
            fi
            ;;

        roslyn)
            
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_lnx_programs}/omnisharp_roslyn"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_bin" ]; then
                    mkdir -p $l_path_bin
                    chmod g+rx,o+rx $l_path_bin
                else
                    #Limpieza
                    rm -rf ${l_path_bin}/*
                fi
                    
                #Mover todos archivos
                #rm "${l_path_temp}/${p_artifact_name_woext}.tar.gz"
                find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_bin} \;

            else
                
                l_path_bin="${g_path_win_programs}/Omnisharp_Roslyn"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_bin" ]; then
                    mkdir -p $l_path_bin
                else
                    #Limpieza
                    rm -rf ${l_path_bin}/*
                fi
                    
                #Mover los archivos
                #rm "${l_path_temp}/${p_artifact_name_woext}.zip"
                find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_bin} \;
            fi
            ;;

        netcoredbg)
            
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/netcoredbg"
            l_flag_install=0            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_lnx_programs}/dap_adapters/netcoredbg"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    m_compare_version2 "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?
                    echo "Repositorio descargado - Versión: \"${l_repo_download_version}\""

                    if [ $l_status -eq 0 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" = Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" > Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    else
                        echo "Se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" < Versión Descargada \"${l_repo_download_version}\")"
                    fi
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_bin" ]; then
                        mkdir -p $l_path_bin
                        chmod g+rx,o+rx $l_path_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_temp}/${p_artifact_name_woext}.tar.gz"
                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_bin} \;
                fi


            else
                
                l_path_bin="${g_path_win_programs}/DAP_Adapters/NetCoreDbg"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    m_compare_version2 "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?
                    echo "Repositorio descargado - Versión: \"${l_repo_download_version}\""

                    if [ $l_status -eq 0 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" = Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" > Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    else
                        echo "Se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" < Versión Descargada \"${l_repo_download_version}\")"
                    fi
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_bin" ]; then
                        mkdir -p $l_path_bin
                        #chmod g+rx,o+rx $l_path_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_temp}/${p_artifact_name_woext}.zip"
                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_bin} \;
                fi

            fi
            ;;

        neovim)
            
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            l_flag_install=0            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_lnx_programs}/neovim"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/bin")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    m_compare_version2 "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?
                    echo "Repositorio descargado - Versión: \"${l_repo_download_version}\""

                    if [ $l_status -eq 0 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" = Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" > Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    else
                        echo "Se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" < Versión Descargada \"${l_repo_download_version}\")"
                    fi
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_bin" ]; then
                        mkdir -p $l_path_bin
                        chmod g+rx,o+rx $l_path_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_temp}/${p_artifact_name_woext}.tar.gz"
                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_bin} \;
                fi


            else
                
                l_path_bin="${g_path_win_programs}/NeoVim"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/bin")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    m_compare_version2 "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?
                    echo "Repositorio descargado - Versión: \"${l_repo_download_version}\""

                    if [ $l_status -eq 0 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" = Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        echo "NO se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" > Versión Descargada \"${l_repo_download_version}\")"
                        l_flag_install=1

                    else
                        echo "Se actualizará este repositorio (Versión Actual \"${l_repo_current_version}\" < Versión Descargada \"${l_repo_download_version}\")"
                    fi
                fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then

                    #2.1. Instalación: Limpieza del directorio del programa
                    if  [ ! -d "$l_path_bin" ]; then
                        mkdir -p $l_path_bin
                        #chmod g+rx,o+rx $l_path_bin
                    else
                        #Limpieza
                        rm -rf ${l_path_bin}/*
                    fi
                        
                    #2.2. Instalación: Mover todos archivos
                    #rm "${l_path_temp}/${p_artifact_name_woext}.zip"
                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_bin} \;
                fi

            fi
            ;;

        nerd-fonts)
            
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Solo para Linux
            if [ $p_install_win_cmds -ne 0 ]; then
                
                #Copiando el binario en una ruta del path
                l_path_bin="/usr/share/fonts/${p_artifact_name_woext}"

                #Instalación de la fuente
                if [ $g_is_root -eq 0 ]; then
                    
                    #Crear la carpeta de fuente, si no existe
                    if  [ ! -d "$l_path_bin" ]; then
                        mkdir -p $l_path_bin
                        chmod g+rx,o+rx $l_path_bin
                    fi

                    #Copiar y/o sobrescribir archivos existente
                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
                         ! \( -name '*Windows Compatible.otf' -o -name '*Windows Compatible.ttf' \) \
                         -exec cp '{}' ${l_path_bin} \;
                    chmod g+r,o+r ${l_path_bin}/*

                    #Actualizar el cache de fuentes del SO
                    if [ $p_artifact_is_last -eq 0 ]; then
                        fc-cache -v
                    fi

                else
                    
                    #Crear la carpeta de fuente, si no existe
                    if  [ ! -d "$l_path_bin" ]; then
                        sudo mkdir -p ${l_path_bin}
                        sudo chmod g+rx,o+rx $l_path_bin
                    fi

                    #Copiar y/o sobrescribir archivos existente
                    sudo find "${l_path_temp}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
                         ! \( -name '*Windows Compatible.otf' -o -name '*Windows Compatible.ttf' \) \
                         -exec cp '{}' ${l_path_bin} \;
                    sudo chmod g+r,o+r ${l_path_bin}/*

                    #Actualizar el cache de fuentes del SO
                    if [ $p_artifact_is_last -eq 0 ]; then
                        sudo fc-cache -v
                    fi

                fi
                    
                #Si es WSL2, copiar los archivos para instalarlo manualmente.
                if [ $g_os_type -eq 1 ]; then
                    
                    l_path_bin="${g_path_win_programs}/NerdFonts"
                    if  [ ! -d "$l_path_bin" ]; then
                        mkdir -p ${l_path_bin}
                    fi

                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 \
                         \( -name '*Windows Compatible.otf' -o -name '*Windows Compatible.ttf' \) \
                         -exec cp '{}' ${l_path_bin} \;
                fi

            fi
            ;;

       *)
           echo "ERROR (50): El artefacto[${p_artifact_id}] del repositorio \"${p_repo_id}\" no implementa logica de copiado de archivos"
           return 50
            
    esac

    return 0

}

#}}}

#Funciones genericas {{{

function m_clean_temp() {

    #1. Argumentos
    local p_repo_id="$1"

    #2. Eliminar los archivos de trabajo temporales
    echo "Eliminado archivos temporales \"/tmp/${p_repo_id}\" ..."
    rm -rf "/tmp/${p_repo_id}"
}

function m_download_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
    declare -nr pnra_artifact_names=$4   #Parametro por referencia: Arreglo de los nombres de los artefactos

    #2. Descargar los artectos del repositorio
    local l_n=${#pnra_artifact_names[@]}

    local l_artifact_name
    local l_artifact_url
    local l_i=0
    local l_status=0

    mkdir -p "/tmp/${p_repo_id}"

    for ((l_i=0; l_i<$l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_artifact_url=$(m_get_artifact_url "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$l_artifact_name" $p_install_win_cmds)
        printf '\nArtefecto[%s] a descargar - Name    : %s\n' "${l_i}" "${l_artifact_name}"
        printf 'Artefecto[%s] a descargar - URL     : %s\n' "${l_i}" "${l_artifact_url}"

        
        #Descargar la artefacto
        mkdir -p "/tmp/${p_repo_id}/${l_i}"
        curl -fLo "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" "$l_artifact_url"
        l_status=$?
        if [ $l_status -eq 0 ]; then
            printf 'Artefacto[%s] descargado en         : "/tmp/%s/%s/%s"\n\n' "${l_i}" "${p_repo_id}" "${l_i}" "${l_artifact_name}"
        else
            printf 'Artefecto[%s] no se pudo descargar  : ERROR(%s)\n\n' "${l_i}" "${l_status}"
            return $l_status
        fi

    done

    return 0
}

function m_install_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    declare -nr pnra_artifact_names=$3   #Parametro por referencia: Arreglo de los nombres de los artefactos
    declare -nr pnra_artifact_types=$4   #Parametro por referencia: Arreglo de los tipos de los artefactos

    local p_install_win_cmds=1           #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                         #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$5" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    local p_repo_current_version="$6"

    #2. Descargar los artectos del repositorio
    local l_n=${#pnra_artifact_names[@]}

    local l_artifact_name
    local l_artifact_type
    local l_i=0

    #3. Instalación de los artectactos
    local l_is_last=1
    mkdir -p "/tmp/${p_repo_id}"

    for ((l_i=0; l_i<$l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_artifact_type="${pnra_artifact_types[$l_i]}"
        echo "Artefecto[${l_i}] a configurar - Name   : ${l_artifact_name}"
        echo "Artefecto[${l_i}] a configurar - Type   : ${l_artifact_type}"
        if [ $l_i -eq l_n ]; then
            l_is_last=0
        fi

        if [ $l_artifact_type -eq 2 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            echo "Descomprimiendo el artefacto[${l_i}] \"${l_artifact_name}\" en \"/tmp/${p_repo_id}/${l_i}\" ..."
            tar -xvf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            m_copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.tar.gz}" $p_install_win_cmds "$p_repo_current_version" $l_is_last
            #l_status=0

        elif [ $l_artifact_type -eq 3 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            echo "Descomprimiendo el artefacto[${l_i}] \"${l_artifact_name}\" en \"/tmp/${p_repo_id}/${l_i}\" ..."
            unzip "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -d "/tmp/${p_repo_id}/${l_i}"
            rm "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            m_copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.zip}" $p_install_win_cmds "$p_repo_current_version" $l_is_last
            #l_status=0

        elif [ $l_artifact_type -eq 0 ]; then

            #Copiar los archivos necesarios
            if [ $p_install_win_cmds -eq 0 ]; then
                m_copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.exe}" $p_install_win_cmds "$p_repo_current_version" $l_is_last
            else
                m_copy_artifact_files "$p_repo_id" $l_i "$l_artifact_name" $p_install_win_cmds "$p_repo_current_version" $l_is_last
            fi
            #l_status=0

        elif [ $l_artifact_type -eq 1 ]; then

            if [ $g_is_debian_os -ne 0 ]; then
                echo "ERROR (22): No esta permitido instalar el artefacto[${l_i}] \"${l_artifact_name}\" en SO que no sean de la familia debian"
                return 22
            fi

            #Instalar y/o actualizar el paquete si ya existe
            echo "Instalando/Actualizando el artefacto[${l_i}] \"${l_artifact_name}\""
            if [ $g_is_root -eq 0 ]; then
                dpkg -i "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            else
                sudo dpkg -i "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}"
            fi
            #l_status=0

        else
            echo "ERROR (21): Configure la logica del tipo de artefacto \"${l_artifact_type}\" para que puede ser configurado"
            return 21
        fi

    done

    return 0
}

function m_intall_repository() { 

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_current_version="$3"
    local p_repo_last_version="$4"
    local p_repo_last_version_pretty="$5"
    local p_install_win_cmds=1            #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                          #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$6" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    #4. Obtener el los artefacto que se instalaran del repositorio
    declare -a la_artifact_names
    declare -a la_artifact_types
    m_load_artifacts "$p_repo_id" "$p_repo_last_version_pretty" la_artifact_names la_artifact_types $p_install_win_cmds
    l_status=$?    
    if [ $l_status -ne 0 ]; then
        echo "ERROR (40): No esta configurado los artefactos para el repositorio \"${p_repo_id}\""
        return 22
    fi

    #si el arreglo es vacio
    local l_n=${#la_artifact_names[@]}
    if [ $l_n -le 0 ]; then
        echo "ERROR (41): No esta configurado los artefactos para el repositorio \"${p_repo_id}\""
        return 98
    fi
    echo "Repositorio - Nro Artefactos : \"${l_n}\""

    #si el tamano del los arrgelos no son iguales
    if [ $l_n -ne ${#la_artifact_types[@]} ]; then
        echo "ERROR (42): No se ha definido todos los tipo de artefactos en el repositorio \"${p_repo_id}\""
        return 97
    fi    

    #5. Descargar el artifacto en la carpeta
    if ! m_download_artifacts "$p_repo_id" "$p_repo_name" "$p_repo_last_version" la_artifact_names; then
        echo "ERROR (43): No se ha podido descargar los artefactos del repositorio \"${p_repo_id}\""
        m_clean_temp "$p_repo_id"
        return 23
    fi

    #6. Instalar segun el tipo de artefecto
    if ! m_install_artifacts "$p_repo_id" "$p_repo_name" la_artifact_names la_artifact_types $p_install_win_cmds "$p_repo_current_version"; then
        echo "ERROR (44): No se ha podido instalar los artefecto de repositorio \"${p_repo_id}\""
        m_clean_temp "$p_repo_id"
        return 24
    fi

    m_show_final_message "$p_repo_id" $p_install_win_cmds
    m_clean_temp "$p_repo_id"
    return 0

}

#}}}

#Codigo principal del script {{{

#Todos los repositorios que se pueden instalar
declare -A gA_repositories=(
        ['bat']='sharkdp/bat'
        ['ripgrep']='BurntSushi/ripgrep'
        ['delta']='dandavison/delta'
        ['fzf']='junegunn/fzf'
        ['jq']='stedolan/jq'
        ['yq']='mikefarah/yq'
        ['kubectl']=''
        ['less']='jftuga/less-Windows'
        ['fd']='sharkdp/fd'
        ['oh-my-posh']='JanDeDobbeleer/oh-my-posh'
        ['helm']='helm/helm'
        ['kustomize']='kubernetes-sigs/kustomize'
        ['operator-sdk']='operator-framework/operator-sdk'
        ['neovim']='neovim/neovim'
        ['k0s']='k0sproject/k0s'
        ['roslyn']='OmniSharp/omnisharp-roslyn'
        ['netcoredbg']='Samsung/netcoredbg'
        ['neovim']='neovim/neovim'
        ['nerd-fonts']='ryanoasis/nerd-fonts'
    )


#Repositorios opcionales y su flag para configuración. Usar valores 2^n (4, 8, 16, ...)
#Sus valores debera coincider con lo que se muestra en el menu "m_show_menu_core"
declare -A gA_optional_repositories=(
        ['neovim']=8
        ['k0s']=16
        ['roslyn']=32
        ['netcoredbg']=64
        ['nerd-fonts']=128
    )


function m_setup_repository() {

    #1. Argumentos 
    local p_repo_id="$1"

    local p_opciones=2
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_opciones=$2
    fi

    local p_show_title=0
    if [[ "$3" =~ ^[0-9]+$ ]]; then
        p_show_title=$3
    fi

    local l_repo_must_setup_lnx=1  #(1) No debe configurarse, (0) Debe configurarse (instalarse/actualizarse)

    #1. Nombre a mostrar el respositorio
    local l_repo_name_aux
    local l_repo_name="${gA_repositories[$p_repo_id]}"
    if [ -z "$l_repo_name" ]; then
        l_repo_name_aux="$l_repo_id"
    else
        l_repo_name_aux="$l_repo_name"
    fi

    #2. El tipo de repositorios y deteminar si debe instalarse
    local l_repo_is_optional=1     #(1) repositorio basico, (0) repositorio opcional
    local l_option=${gA_optional_repositories[$p_repo_id]}
    local l_flag=0
    if [ -z "$l_option" ]; then

        #Es un repositorio basico
        l_repo_is_optional=1

        #Si es un repositorio basico, permitir la instalación si se ingresa la opciones 4
        l_flag=$(( $p_opciones & 4 ))
        if [ $l_flag -eq 4 ]; then l_repo_must_setup_lnx=0; fi

    else

        #Es un repositorio opcional
        l_repo_is_optional=0

        #Esta habilitado para instalar el repositorio opcional
        if [[ "$l_option" =~ ^[0-9]+$ ]]; then
            if [ $l_option -ne 0 ]; then
                #Suma binarios es igual al flag, se debe instalar el repo opcional
                l_flag=$(( $p_opciones & $l_option ))
                if [ $l_option -eq $l_flag ]; then l_repo_must_setup_lnx=0; fi
            fi 
        fi

    fi

    #3. ¿Existe un repositorio valido de artectactos?
    local l_repo_last_version=$(m_get_repo_latest_version "$p_repo_id" "$l_repo_name")
    local l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed "$g_regexp_sust_version2")
    if [[ ! "$l_repo_last_version_pretty" =~ ^[0-9] ]]; then
        l_repo_last_version_pretty=""
    fi
       
    if [ -z "$l_repo_last_version" ]; then
        echo "ERROR: El repositorio \"$p_repo_id\" no es valido (no se puede obtener la ultima versión existente en el repo)"
        l_repo_must_setup_lnx=1
        return 80
    fi
    
    #4. ¿Debe instalarse en Linux?
    local l_repo_must_setup_win=$l_repo_must_setup_lnx  #El de instalación en windows debe iniciar igual
    local l_install_win_cmds=1

    #Obtener la versión de repositorio instalado en Linux
    local l_repo_current_version=""
    local l_repo_is_installed=0
    l_repo_current_version=$(m_get_repo_current_version "$p_repo_id" ${l_install_win_cmds} "")
    l_repo_is_installed=$?          #(9) El repositorio unknown porque no se implemento la logica
                                    #(3) El repositorio unknown porque no se puede obtener (siempre instalarlo)
                                    #(1) El repositorio no esta instalado 
                                    #(0) El repositorio instalado, con version correcta
                                    #(2) El repositorio instalado, con version incorrecta

    #Si esta instalado, permitir su instalación si se ingresada la opcion 2
    if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ]; then
       l_flag=$(( $p_opciones & 2 ))
       if [ $l_flag -eq 2 ]; then l_repo_must_setup_lnx=0; fi
    fi

    #Repositorios especiales que no deberia instalarse, segun el tipo de Linux
    if [ $l_repo_must_setup_lnx -eq 0 ]; then

        case "$l_repo_id" in
            less)
                #Repositorio "less": Solo se instala si es WSL2 y en el windows asociado
                if [ $g_os_type -eq 1 ]; then l_repo_must_setup_lnx=1; fi
                ;;
            k0s)
                #Repositorio "k0s": Solo si es Linux que no es WSL2                
                if [ $g_os_type -eq 1 ]; then l_repo_must_setup_lnx=1; fi
                ;;
        esac

    fi


    #5. Setup el repositorio en Linux
    if [ $l_repo_must_setup_lnx -eq 0 ]; then

        #5.1 Mostrar el titulo
        if [ $p_show_title -eq 0 ]; then
            echo "-------------------------------------------------------------------------------------------------"
            printf '%s' "- Repositorio Git"

            if [ $l_repo_is_optional -eq 0 ]; then
                printf ' opcional "%s"' "${l_repo_name_aux}"
            else
                printf ' basico "%s"' "${l_repo_name_aux}"
            fi

            if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ]; then
               printf " (UPDATE)\n"
            elif [ $l_repo_is_optional -eq 1 ]; then
               printf " (INSTALL)\n"
            else
               printf "\n"
            fi
            echo "-------------------------------------------------------------------------------------------------"
        fi

        echo "Iniciando la configuración de los artefactos del repositorio \"${l_repo_name_aux}\" en Linux \"${g_os_subtype_name}\""
        echo "Repositorio - Name           : \"${l_repo_name}\""
        echo "Repositorio - ID             : \"${p_repo_id}\""
        echo "Repositorio - Ultima Versión : \"${l_repo_last_version_pretty}\" (${l_repo_last_version})"

        #5.2 Segun la version del repositorio actual, habilitar la instalación 
        if [ $l_repo_is_installed -eq 9 ]; then
            echo "Repositorio - Versión Actual : \"Unknown\" (No implementado)"
            echo "ERROR: Implemente la logica para determinar la version actual de repositorio instalado"
            l_repo_must_setup_lnx=1
        else
            #Si se tiene implementado la logica para obtener la version actual o se debe instalar sin ella
            if [ $l_repo_is_installed -eq 1 ]; then
                echo "Repositorio - Versión Actual : \"No instalado\""
            elif [ $l_repo_is_installed -eq 2 ]; then
                echo "Repositorio - Versión Actual : \"${l_repo_current_version}\" (formato invalido)"
                l_repo_current_version=""
            elif [ $l_repo_is_installed -eq 3 ]; then
                echo "Repositorio - Versión Actual : \"${l_repo_current_version}\" (No se puede calcular)"
            else
                echo "Repositorio - Versión Actual : \"${l_repo_current_version}\""
            fi
        fi

        #5.3 Comparando versiones y segun ello, habilitar la instalación
        if [ $l_repo_must_setup_lnx -eq 0 ]; then
   
            #Comparando las versiones
            if [ ! -z "$l_repo_last_version_pretty" ] && [ $l_repo_is_installed -ne 3 ]; then
                 
                #m_compare_version "${p_repo_current_version}" "${l_repo_last_version_pretty}"
                m_compare_version2 "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                l_status=$?

                if [ $l_status -eq 0 ]; then
                    echo "NO se actualizará este repositorio \"${p_repo_id}\" (Versión Actual \"${l_repo_current_version}\" = Ultima Versión \"${l_repo_last_version_pretty}\")"
                    l_repo_must_setup_lnx=1
                elif [ $l_status -eq 1 ]; then
                    echo "NO se actualizará este repositorio \"${p_repo_id}\" (Versión Actual \"${l_repo_current_version}\" > Ultima Versión \"${l_repo_last_version_pretty}\")"
                    l_repo_must_setup_lnx=1
                fi
                echo "Se actualizará este repositorio \"${p_repo_id}\" (Versión Actual \"${l_repo_current_version}\" < Ultima Versión \"${l_repo_last_version_pretty}\")"

            else
                echo "La ultima versión del repositorio \"${l_repo_last_version}\" no es una version comparable. Se iniciara la instalación del repositorio \"${p_repo_id}\""
            fi
             
        fi
    

        #5.4 Instalar el repositorio
        if [ $l_repo_must_setup_lnx -eq 0 ]; then
            m_intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" $l_install_win_cmds 
        fi

        printf "\n\n"
       
    fi

    #6. ¿Debe instalarse en Windows?
    local l_install_win_cmds=0
    if [ $g_os_type -eq 1 ]; then

        #Versión de repositorio instalado en Linux
        l_repo_current_version=$(m_get_repo_current_version "$p_repo_id" ${l_install_win_cmds} "")
        l_repo_is_installed=$?          #(9) El repositorio unknown (no implementado la logica)
                                        #(3) El repositorio unknown porque no se puede obtener (siempre instalarlo)
                                        #(1) El repositorio no esta instalado 
                                        #(0) El repositorio instalado, con version correcta
                                        #(2) El repositorio instalado, con version incorrecta

        #Si esta instalado, permitir su instalación si se ingresada la opcion 2 
        if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ]; then
           l_flag=$(( $p_opciones & 2 ))
           if [ $l_flag -eq 2 ]; then l_repo_must_setup_win=0; fi
        fi

        #Repositorios especiales que no deberia instalarse en Windows
        if [ $l_repo_must_setup_win -eq 0 ]; then

            case "$l_repo_id" in
                k0s)
                    #Repositorio "k0s": Solo si es Linux que no es WSL2                
                    l_repo_must_setup_win=1;
                    ;;
                operator-sdk)
                    #Repositorio "operator-sdk": Solo si es Linux                
                    l_repo_must_setup_win=1;
                    ;;
                nerd-fonts)
                   #Las fuentes en Windows se instalan manualmente (requiere del registro de windows)                
                    l_repo_must_setup_win=1;
                    ;;
            esac

        fi
    else
        l_repo_must_setup_win=1
    fi

    #7. Setup el repositorio en Windows
    if [ $l_repo_must_setup_win -eq 0 ]; then
        
        #7.1 Mostrar el titulo
        if [ $l_repo_must_setup_lnx -ne 0 -a $p_show_title -eq 0 ]; then
            echo "-------------------------------------------------------------------------------------------------"
            printf '%s' "- Repositorio Git"

            if [ $l_repo_is_optional -eq 0 ]; then
                printf ' opcional "%s"' "${l_repo_name_aux}"
            else
                printf ' basico "%s"' "${l_repo_name_aux}"
            fi

            if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ]; then
                printf " (UPDATE)\n"
            elif [ $l_repo_is_optional -eq 1 ]; then
                printf " (INSTALL)\n"
            else
                printf "\n"
            fi
            echo "-------------------------------------------------------------------------------------------------"
        fi

        echo "Iniciando la configuración de los artefactos del repositorio \"${l_repo_name_aux}\" en Windows (asociado al WSL \"${g_os_subtype_name}\")"
        echo "Repositorio - Name           : \"${l_repo_name}\""
        echo "Repositorio - ID             : \"${p_repo_id}\""
        echo "Repositorio - Ultima Versión : \"${l_repo_last_version_pretty}\" (${l_repo_last_version})"

        #7.2 Segun la version del repositorio actual, habilitar la instalación 
        if [ $l_repo_is_installed -eq 9 ]; then
            echo "Repositorio - Versión Actual : \"Unknown\" (No implementado)"
            echo "ERROR: Implemente la logica para determinar la version actual de repositorio instalado"
            l_repo_must_setup_win=1
        else
            #Si se tiene implementado la logica para obtener la version actual
            if [ $l_repo_is_installed -eq 1 ]; then
                echo "Repositorio - Versión Actual : \"No instalado\""
             elif [ $l_repo_is_installed -eq 2 ]; then
                echo "Repositorio - Versión Actual : \"${l_repo_current_version}\" (formato invalido)"
                l_repo_current_version=""
            elif [ $l_repo_is_installed -eq 3 ]; then
                echo "Repositorio - Versión Actual : \"${l_repo_current_version}\" (No se puede calcular)"
            else
                echo "Repositorio - Versión Actual : \"${l_repo_current_version}\""
            fi
        fi

        #7.3 Comparando versiones y segun ello, habilitar la instalación
        if [ $l_repo_must_setup_win -eq 0 ]; then
    
            #Comparando las versiones
            if [ ! -z "$l_repo_last_version_pretty" ] && [ $l_repo_is_installed -ne 3 ]; then
                 
                #m_compare_version "${p_repo_current_version}" "${l_repo_last_version_pretty}"
                m_compare_version2 "${l_repo_current_version}" "${l_repo_last_version_pretty}"
                l_status=$?

                if [ $l_status -eq 0 ]; then
                    echo "NO se actualizará este repositorio \"${p_repo_id}\" (Versión Actual \"${l_repo_current_version}\" = Ultima Versión \"${l_repo_last_version_pretty}\")"
                    l_repo_must_setup_lnx=1
                elif [ $l_status -eq 1 ]; then
                    echo "NO se actualizará este repositorio \"${p_repo_id}\" (Versión Actual \"${l_repo_current_version}\" > Ultima Versión \"${l_repo_last_version_pretty}\")"
                    l_repo_must_setup_lnx=1
                fi
                echo "Se actualizará este repositorio \"${p_repo_id}\" (Versión Actual \"${l_repo_current_version}\" < Ultima Versión \"${l_repo_last_version_pretty}\")"

            else
                echo "La ultima versión del repositorio \"${l_repo_last_version}\" no es una version comparable. Se iniciara la instalación del repositorio \"${p_repo_id}\""
            fi

        fi

        #7.4 Instalar el repositorio
        if [ $l_repo_must_setup_win -eq 0 ]; then
            #echo "Se instalará el repositorio \"${p_repo_id}\""
            m_intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" $l_install_win_cmds 
        fi

        printf "\n\n"
       
    fi

}


# Argunentos:
# - Repositorios opcionales que se se instalaran (flag en binario. entero que es suma de 2^n).
# - Si es invocado desde otro script, su valor es 1 y no se solicita las credenciales sudo. Si el script se invoca directamente, es 0
function m_setup_repositories() {
    
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
        local l_option=1
        local l_flag=$(( $p_opciones & $l_option ))
        if [ $l_option -eq $l_flag ]; then

            echo "-------------------------------------------------------------------------------------------------"
            echo "- Actualizar los paquetes de los repositorio del SO Linux"
            echo "-------------------------------------------------------------------------------------------------"
            
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

    #5. Instalar los comandos de los diferentes repositorios
    local l_repo_id
    for l_repo_id in "${!gA_repositories[@]}"; do

        #Instalar el repositorio
        m_setup_repository "$l_repo_id" $p_opciones

    done; 

    #6. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 -a $p_is_direct_calling -eq 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}


function m_show_menu_core() {

    echo "                                  Escoger la opción"
    echo "-------------------------------------------------------------------------------------------------"
    echo " (q) Salir del menu"
    echo " (a) Actualizar los paquetes existentes del SO y los binarios de los repositorios existentes"
    echo " ( ) Actualización personalizado. Ingrese la suma de las opciones que desea configurar:"
    #echo "    (  0) Actualizar xxx (siempre se realizara esta opción)"
    echo "     (  1) Actualizar los paquetes existentes del sistema operativo"   
    echo "     (  2) Actualizar los binarios de los repositorios existentes"
    echo "     (  4) Instalar/Actualizar los binarios de los repositorios basicos"
    echo "     (  8) Instalar/Actualizar el binario del repositorio opcional \"NeoVim\""
    echo "     ( 16) Instalar/Actualizar el binario del repositorio opcional \"k0s\""
    echo "     ( 32) Instalar/Actualizar el binario del repositorio opcional \"OmniSharp/omnisharp-roslyn\""
    echo "     ( 64) Instalar/Actualizar el binario del repositorio opcional \"Samsung/netcoredbg\""
    echo "     (128) (Re)Instalar en el servidor fuentes Nerd Fonts desde    \"ryanoasis/nerd-fonts\""
    echo "-------------------------------------------------------------------------------------------------"
    printf "Opción : "

}

function m_main() {

    echo "OS Type            : (${g_os_type})"
    echo "OS Subtype (Distro): (${g_os_subtype_id}) ${g_os_subtype_name} - ${g_os_subtype_version}"$'\n'
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR(21): El sistema operativo debe ser Linux"
        return 21;
    fi
    
    echo "#################################################################################################"

    local l_flag_continue=0
    local l_opciones=""
    while [ $l_flag_continue -eq 0 ]; do

        m_show_menu_core
        read l_opciones

        case "$l_opciones" in
            a)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                m_setup_repositories 3 0
                ;;

            q)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                ;;


            0)
                l_flag_continue=0
                echo "Opción incorrecta"
                echo "-------------------------------------------------------------------------------------------------"
                ;;

            [1-9]*)
                if [[ "$l_opciones" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    echo "#################################################################################################"$'\n'
                    m_setup_repositories $l_opciones 0
                else
                    l_flag_continue=0
                    echo "Opción incorrecta"
                    echo "-------------------------------------------------------------------------------------------------"
                fi
                ;;

            *)
                l_flag_continue=0
                echo "Opción incorrecta"
                echo "-------------------------------------------------------------------------------------------------"
                ;;
        esac
        
    done

}


#}}}

#Argumentos 
gp_type_calling=0       #(0) Es llamado directa, es decir se muestra el menu.
                        #(1) Instalando un conjunto de respositorios
                        #(2) Instalando solo un repository
if [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
fi

if [ $gp_type_calling -eq 0 ]; then

    m_main

elif [ $gp_type_calling -eq 1 ]; then

    gp_opciones=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_opciones=$2
    fi
    m_setup_repositories $gp_opciones 1

else

    gp_opciones=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_opciones=$2
    fi

    gp_repo_id="$3"
    if [ -z "$gp_repo_id" ]; then
       echo "Parametro (3) debe ser un ID de repositorio valido"
       return 99
    fi

    m_setup_repository "$gp_repo_id" $gp_opciones 1

fi


