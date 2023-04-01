#!/bin/bash

#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

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

#Variable global de la ruta donde se instalaran los programas CLI (mas complejos que un simple comando).
declare -r g_path_programs_lnx='/opt/tools'

#Variable global ruta de los programas CLI y/o binarios en Windows desde su WSL2
if [ $g_os_type -eq 1 ]; then
   declare -r g_path_programs_win='/mnt/d/CLI'
   declare -r g_path_commands_win="${g_path_programs_win}/Cmds"
fi

#Expresiones regulares de sustitucion mas usuadas para las versiones
#Se extrae la 1ra subcadena que inicie con enteros 0-9 y continue con . y luego continue con cualquier caracter que solo sea 0-9 o .
declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
#Se extrae la 1ra subcadena que inicie con enteros 0-9 y continue con . y luego continue con cualquier caracter que solo sea 0-9 o . o -
declare -r g_regexp_sust_version2='s/[^0-9]*\([0-9]\+\.[0-9.-]\+\).*/\1/'
declare -r g_regexp_sust_version3='s/[^0-9]*\([0-9.]\+\).*/\1/'
#Solo lo numeros sin puntos
declare -r g_regexp_sust_version4='s/[^0-9]*\([0-9]\+\).*/\1/'
#Cuando no se puede determinar la version actual (siempre se instalara)
declare -r g_version_none='0.0.0'


#}}}

#Funciones especificas {{{

#Solo se invoca cuando se instala con exito un repositorio y sus artefactos
function m_show_final_message() {

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

#Determinar la version actual del repositorio usado para instalar los comandos instalados:
#  0 - Si existe y se obtiene un valor
#  1 - El comando no existe o existe un error en el comando para obtener la versión
#  2 - La version obtenida no tiene formato valido
#  3 - No existe forma de calcular la version actual (siempre se instala y/o actualizar)
#  9 - No esta implementado un metodo de obtener la version
function m_get_repo_current_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_install_win_cmds=1          #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$2" -eq 0 2> /dev/null ]; then
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
            l_path_file="${g_path_commands_win}/bin/"
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
                  l_path_file="${g_path_programs_win}/LSP_Servers/Omnisharp_Roslyn/"
               else
                  l_path_file="${g_path_programs_lnx}/lsp_servers/omnisharp_roslyn/"
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
                  l_path_file="${g_path_programs_lnx}/dap_servers/netcoredbg/"
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
                  l_path_file="${g_path_programs_lnx}/neovim/bin/"
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
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ -f "${g_path_programs_win}/nerd-fonts.info" ]; then
                    l_tmp=$(cat "${g_path_programs_win}/nerd-fonts.info" | head -n 1)
                else
                    #Siempre se actualizara la fuentes, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
            else
                if [ -f "${g_path_programs_lnx}/nerd-fonts.info" ]; then
                    l_tmp=$(cat "${g_path_programs_lnx}/nerd-fonts.info" | head -n 1)
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
                  l_path_file="${g_path_programs_lnx}/go/bin/"
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

        clangd)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/LSP_Servers/CLangD/bin/"
               else
                  l_path_file="${g_path_programs_lnx}/lsp_servers/clangd/bin/"
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
            fi
            ;;

        cmake)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_path_programs_win}/CMake/bin/"
               else
                  l_path_file="${g_path_programs_lnx}/cmake/bin/"
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
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}pwsh --version 2> /dev/null)
            l_status=$?
            
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
                  l_path_file="${g_path_programs_lnx}/lsp_servers/rust_analyzer/"
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
                  l_path_file="${g_path_programs_lnx}/graalvm/bin/"
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
                  l_path_file="${g_path_programs_lnx}/lsp_servers/jdt_ls/"
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
#       >  0 si es binario
#       >  1 si es package
#       >  2 si es un tar.gz
#       >  3 si es un zip
#       >  4 si es un .gz
#       > 99 si no se define el artefacto para el prefijo
#  - Argumento 3, un arreglo de nombre de los artectos a descargar
#En el argumento 2 se debe pasar la version pura quitando, sin contener "v" u otras letras iniciales
function m_load_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_last_version="$2"
    local p_repo_last_version_pretty="$3"
    declare -n pna_artifact_names=$4   #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_artifact_types=$5   #Parametro por referencia: Se devuelve un arreglo de los tipos de los artefactos
    local p_arti_version="$6"
    local p_install_win_cmds=1         #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                       #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$7" -eq 0 2> /dev/null ]; then
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
                pna_artifact_names=("fzf-${p_repo_last_version_pretty}-linux_amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("fzf-${p_repo_last_version_pretty}-windows_amd64.zip")
                pna_artifact_types=(3)
            fi
            ;;
        helm)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("helm-v${p_repo_last_version_pretty}-linux-amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("helm-v${p_repo_last_version_pretty}-windows-amd64.zip")
                pna_artifact_types=(3)
            fi
            ;;
        delta)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("git-delta_${p_repo_last_version_pretty}_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("delta-${p_repo_last_version_pretty}-x86_64-unknown-linux-gnu.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("delta-${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;
        ripgrep)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("ripgrep_${p_repo_last_version_pretty}_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("ripgrep-${p_repo_last_version_pretty}-x86_64-unknown-linux-musl.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("ripgrep-${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;
        xsv)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("xsv-${p_repo_last_version_pretty}-x86_64-unknown-linux-musl.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("xsv-${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;
        bat)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("bat_${p_repo_last_version_pretty}_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("bat-v${p_repo_last_version_pretty}-x86_64-unknown-linux-gnu.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("bat-v${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
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
                    #pna_artifact_names=("fd_${p_repo_last_version_pretty}_amd64.deb")
                    #pna_artifact_types=(1)
                    pna_artifact_names=("fd-v${p_repo_last_version_pretty}-x86_64-unknown-linux-gnu.tar.gz")
                    pna_artifact_types=(2)
                else
                    pna_artifact_names=("fd-v${p_repo_last_version_pretty}-x86_64-unknown-linux-gnu.tar.gz")
                    pna_artifact_types=(2)
                fi
            else
                pna_artifact_names=("fd-v${p_repo_last_version_pretty}-x86_64-pc-windows-msvc.zip")
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
                pna_artifact_names=("k0s-v${p_repo_last_version_pretty}+k0s.0-amd64")
                pna_artifact_types=(0)
            else
                pna_artifact_names=("k0s-v${p_repo_last_version_pretty}+k0s.0-amd64.exe")
                pna_artifact_types=(0)
            fi
            ;;
        kustomize)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("kustomize_v${p_repo_last_version_pretty}_linux_amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("kustomize_v${p_repo_last_version_pretty}_windows_amd64.tar.gz")
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
            pna_artifact_names=("JetBrainsMono.zip" "CascadiaCode.zip" "DroidSansMono.zip" "InconsolataLGC.zip" "UbuntuMono.zip" "3270.zip")
            pna_artifact_types=(3 3 3 3 3 3)
            ;;

        go)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("go${p_repo_last_version_pretty}.linux-amd64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("go${p_repo_last_version_pretty}.windows-amd64.zip")
                pna_artifact_types=(3)
            fi
            ;;

        clangd)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("clangd-linux-${p_repo_last_version_pretty}.zip")
                pna_artifact_types=(3)
            else
                pna_artifact_names=("clangd-windows-${p_repo_last_version_pretty}.zip")
                pna_artifact_types=(3)
            fi
            ;;

        cmake)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("cmake-${p_repo_last_version#v}-linux-x86_64.tar.gz")
                pna_artifact_types=(2)
            else
                pna_artifact_names=("cmake-${p_repo_last_version#v}-windows-x86_64.zip")
                pna_artifact_types=(3)
            fi
            ;;

        ninja)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("ninja-linux.zip")
                pna_artifact_types=(3)
            else
                pna_artifact_names=("ninja-win.zip")
                pna_artifact_types=(3)
            fi
            ;;

        powershell)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("powershell_${p_repo_last_version_pretty}-1.deb_amd64.deb")
                    pna_artifact_types=(1)
                else
                    pna_artifact_names=("powershell-${p_repo_last_version_pretty}-1.rh.x86_64.rpm")
                    pna_artifact_types=(1)
                fi
            else
                #No se instala nada en Windows
                return 1
            fi
            ;;

        rust-analyzer)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("rust-analyzer-x86_64-unknown-linux-gnu.gz")
                pna_artifact_types=(4)
            else
                pna_artifact_names=("rust-analyzer-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(3)
            fi
            ;;

        graalvm)
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_names=("graalvm-ce-java${p_arti_version}-linux-amd64-${p_repo_last_version_pretty}.tar.gz" 
                                    "native-image-installable-svm-java${p_arti_version}-linux-amd64-${p_repo_last_version_pretty}.jar"
                                    "visualvm-installable-ce-java${p_arti_version}-linux-amd64-${p_repo_last_version_pretty}.jar")
                pna_artifact_types=(2 0 0)
            else
                pna_artifact_names=("graalvm-ce-java${p_arti_version}-windows-amd64-${p_repo_last_version_pretty}.zip"
                                    "native-image-installable-svm-java${p_arti_version}-windows-amd64-${p_repo_last_version_pretty}.jar"
                                    "visualvm-installable-ce-java${p_arti_version}-windows-amd64-${p_repo_last_version_pretty}.jar")
                pna_artifact_types=(3 0 0)
            fi
            ;;
        
        jdtls)
            pna_artifact_names=("jdt-language-server-${p_repo_last_version}.tar.gz")
            pna_artifact_types=(2)
            ;;

        *)
           return 1
           ;;
    esac

    return 0
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
function m_get_repo_latest_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    declare -n pna_repo_versions=$3   #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_arti_versions=$4
    
    #2. Obtener la version
    local l_repo_last_version=""
    local l_repo_last_version_pretty=""
    local l_aux=""
    local l_arti_versions=""
    #local l_status=0

    case "$p_repo_id" in

        kubectl)
            #El artefacto se obtiene del repositorio de Kubernates
            l_repo_last_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
            l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")
            ;;
        
        kustomize)
            #Si no esta instalado 'jq' no continuar
            if ! command -v jq &> /dev/null; then
                return 1
            fi

            l_repo_last_version=$(kubectl version --client=true -o json  | jq -r '.kustomizeVersion' 2> /dev/null)
            l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")
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
            l_arti_versions=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | jq -r '.assets[].name' | \
                  grep -e '^graalvm-ce-java.*-linux-amd64-.*\.tar\.gz$' | sed -e 's/graalvm-ce-java\(.*\)-linux-amd64-.*/\1/' | sort -r)
            ;;

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
    l_aux=$(m_url_encode "$l_repo_last_version")
    pna_repo_versions=("$l_aux" "$l_repo_last_version_pretty")
    pna_arti_versions=(${l_arti_versions})
    return 0
}


function m_get_last_repo_url() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
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

        go)
            l_base_url="https://storage.googleapis.com/${p_repo_name}"
            ;;
            
        jdtls)
            l_base_url="https://download.eclipse.org/${p_repo_name}/snapshots"
            ;;

        *)
            l_base_url="https://github.com/${p_repo_name}/releases/download/${p_repo_last_version}"
            ;;

    esac

    #3. Obtener la URL
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
    local p_repo_last_version="$6"
    local p_repo_last_version_pretty="$7"
    local p_artifact_is_last=$8

    local p_arti_version="$9"
    local p_arti_index=0
    if [[ "${10}" =~ ^[0-9]+$ ]]; then
        p_arti_index=${10}
    fi

    #Tag usuado para imprimir un identificador del artefacto en un log
    local l_tag="${p_repo_id}[${p_repo_last_version_pretty}]"
    if [ ! -z "${p_arti_version}" ]; then
        l_tag="${l_tag}[${p_arti_version}]"
    fi

    #3. Copiar loa archivos del artefacto segun el prefijo
    local l_path_temp=""

    local l_path_man=""
    local l_path_bin=""
    if [ $p_install_win_cmds -ne 0 ]; then
        l_path_bin='/usr/local/bin'
        l_path_man='/usr/local/man/man1'
    else
        l_path_bin="${g_path_commands_win}/bin"
        l_path_man="${g_path_commands_win}/man"
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

        xsv)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"csv\" a \"${l_path_bin}\" ..."
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/xsv" "${l_path_bin}"
                    chmod +x "${l_path_bin}/xsv"
                    #mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/xsv" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/xsv"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/xsv.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
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
                #mkdir -p ~/.files/vim/packages/fzf/doc
                #mkdir -p ~/.files/vim/packages/fzf/plugin
                #echo "Copiando \"git/doc/fzf.txt\" a \"~/.files/vim/packages/fzf/doc/\" ..."
                #cp "${l_path_temp}/git/doc/fzf.txt" ~/.files/vim/packages/fzf/doc/
                #echo "Copiando \"git/doc/fzf.vim\" a \"~/.files/vim/packages/fzf/plugin/\" ..."
                #cp "${l_path_temp}/git/plugin/fzf.vim" ~/.files/vim/packages/fzf/plugin/

                #Copiar los archivos opcionales del plugin
                #echo "Copiando \"git/LICENSE\" en \"~/.files/vim/packages/fzf/\" .."
                #cp "${l_path_temp}/git/LICENSE" ~/.files/vim/packages/fzf/LICENSE
            
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
                    mkdir -p "${g_path_commands_win}/etc/oh-my-posh/themes"
                    cp -f ${l_path_temp}/*.json "${g_path_commands_win}/etc/oh-my-posh/themes"
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
                
                l_path_bin="${g_path_programs_lnx}/lsp_servers/omnisharp_roslyn"

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
                
                l_path_bin="${g_path_programs_win}/LSP_Servers/Omnisharp_Roslyn"

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
                
                l_path_bin="${g_path_programs_lnx}/dap_servers/netcoredbg"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    printf 'Evaluar si el repositorio actual "%s[%s]" debe actualizarse al repositorio descargado "%s[%s]" ...\n' "$p_repo_id" "$l_repo_current_version" \
                        "$l_repo_id" "$l_repo_download_version"
                    m_compare_version "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?

                    if [ $l_status -eq 0 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    else
                        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
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
                    
                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_bin}/netcoredbg.info" 
                fi


            else
                
                l_path_bin="${g_path_programs_win}/DAP_Servers/NetCoreDbg"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    printf 'Evaluar si el repositorio actual "%s[%s]" debe actualizarse al repositorio descargado "%s[%s]" ...\n' "$p_repo_id" "$l_repo_current_version" \
                        "$l_repo_id" "$l_repo_download_version"
                    m_compare_version "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?

                    if [ $l_status -eq 0 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    else
                        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
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

                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_bin}/netcoredbg.info" 
                fi

            fi
            ;;

        neovim)
            
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            l_flag_install=0            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_programs_lnx}/neovim"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/bin")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    printf 'Evaluar si el repositorio actual "%s[%s]" debe actualizarse al repositorio descargado "%s[%s]" ...\n' "$p_repo_id" "$l_repo_current_version" \
                        "$l_repo_id" "$l_repo_download_version"
                    m_compare_version "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?

                    if [ $l_status -eq 0 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    else
                        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
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
                
                l_path_bin="${g_path_programs_win}/NeoVim"

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/bin")
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    l_flag_install=1
                else

                    printf 'Evaluar si el repositorio actual "%s[%s]" debe actualizarse al repositorio descargado "%s[%s]" ...\n' "$p_repo_id" "$l_repo_current_version" \
                        "$l_repo_id" "$l_repo_download_version"
                    m_compare_version "${l_repo_current_version}" "${l_repo_download_version}"
                    l_status=$?

                    if [ $l_status -eq 0 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    elif [ $l_status -eq 1 ]; then

                        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                        l_flag_install=1

                    else
                        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
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
                         ! \( -name '*Windows Compatible*.otf' -o -name '*Windows Compatible*.ttf' \) \
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
                         ! \( -name '*Windows Compatible*.otf' -o -name '*Windows Compatible*.ttf' \) \
                         -exec cp '{}' ${l_path_bin} \;
                    sudo chmod g+r,o+r ${l_path_bin}/*

                    #Actualizar el cache de fuentes del SO
                    if [ $p_artifact_is_last -eq 0 ]; then
                        sudo fc-cache -v
                    fi

                    #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${g_path_programs_lnx}/nerd-fonts.info" 
                fi
                    
                #Si es WSL2, copiar los archivos para instalarlo manualmente.
                if [ $g_os_type -eq 1 ]; then
                    
                    l_path_bin="${g_path_programs_win}/NerdFonts"
                    if  [ ! -d "$l_path_bin" ]; then
                        mkdir -p ${l_path_bin}
                    fi

                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 \
                         \( -name '*Windows Compatible*.otf' -o -name '*Windows Compatible*.ttf' \) \
                         -exec cp '{}' ${l_path_bin} \;
                    
                    #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${g_path_programs_lnx}/nerd-fonts.info" 

                    #Notas
                    echo "Debera instalar (copiar) manualmente los archivos de '${l_path_bin}' en 'C:/Windows/Fonts'"
                fi

            fi
            ;;

        clangd)

            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/clangd_${p_repo_last_version}"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_programs_lnx}/lsp_servers/clangd"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_bin" ]; then
                    mkdir -p $l_path_bin
                    chmod g+rx,o+rx $l_path_bin
                else
                    #Limpieza
                    rm -rf ${l_path_bin}/*
                fi
                    
                #Mover todos archivos
                #rm "${l_path_temp}/${p_artifact_name_woext}.zip"
                find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.zip" -exec mv '{}' ${l_path_bin} \;

            else
                
                l_path_bin="${g_path_programs_win}/LSP_Servers/CLangD"

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

        go)

            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/go"
            

            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_programs_lnx}/go"

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
                
                l_path_bin="${g_path_programs_win}/Go"

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


        cmake)

            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_artifact_name_woext}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_programs_lnx}/cmake"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_bin" ]; then
                    mkdir -p $l_path_bin
                    chmod g+rx,o+rx $l_path_bin
                else
                    #Limpieza
                    rm -rf ${l_path_bin}/*
                fi

                #Copiando los archivos de ayuda
                #./man/man1/*.1
                #./man/man1/*.7

                #Copiando los script para el autocompletado
                #bash-completion/completions/cmake
                #bash-completion/completions/cpack
                #bash-completion/completions/ctest
                    
                #Mover todos archivos
                #rm "${l_path_temp}/${p_artifact_name_woext}.tar.gz"
                find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_bin} \;

            else
                
                l_path_bin="${g_path_programs_win}/CMake"

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


        ninja)

            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/ninja" "${l_path_bin}"
                    chmod +x "${l_path_bin}/ninja"
                    #mkdir -pm 755 "${l_path_man}"
                else
                    sudo cp "${l_path_temp}/ninja" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/ninja"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                cp "${l_path_temp}/ninja.exe" "${l_path_bin}"
                #mkdir -p "${l_path_man}"
            fi
            ;;


        rust-analyzer)

            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            l_flag_install=0
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
               
                echo "Renombrando \"${l_path_temp}/${p_artifact_name_woext}\" a \"${l_path_temp}/rust-analyzer\""
                #ls -la ${l_path_temp}
                mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_temp}/rust-analyzer"
                #ls -la ${l_path_temp}
                #id
                chmod u+x "${l_path_temp}/rust-analyzer"
                
                #1. Comparando la version instalada con la version descargada
                #l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/")
                #l_status=$?

                #if [ $l_status -ne 0 ]; then
                #    echo "Error al obtener la versión actual (Status = ${l_status})"
                #    l_flag_install=1
                #else

                #    printf 'Evaluar si el repositorio actual "%s[%s]" debe actualizarse al repositorio descargado "%s[%s]" ...\n' "$p_repo_id" "$l_repo_current_version" \
                #        "$l_repo_id" "$l_repo_download_version"
                #    m_compare_version "${l_repo_current_version}" "${l_repo_download_version}"
                #    l_status=$?

                #    if [ $l_status -eq 0 ]; then

                #        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                #        l_flag_install=1

                #    elif [ $l_status -eq 1 ]; then

                #        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                #        l_flag_install=1

                #    else
                #        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                #    fi
                #fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then
                    l_path_bin="${g_path_programs_lnx}/lsp_servers/rust_analyzer"
                    mkdir -p "${l_path_bin}"

                    echo "Copiando \"${l_path_temp}/rust-analyzer\" a \"${l_path_bin}/\""
                    cp "${l_path_temp}/rust-analyzer" "${l_path_bin}/"
                    chmod +x "${l_path_bin}/rust-analyzer"
                    #mkdir -pm 755 "${l_path_man}"

                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_bin}/rust-analyzer.info" 
                fi

            else

                #1. Comparando la version instalada con la version descargada
                l_repo_download_version=$(m_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "${l_path_temp}/")
                l_status=$?

                #if [ $l_status -ne 0 ]; then
                #    echo "Error al obtener la versión actual (Status = ${l_status})"
                #    l_flag_install=1
                #else

                #    printf 'Evaluar si el repositorio actual "%s[%s]" debe actualizarse al repositorio descargado "%s[%s]" ...\n' "$p_repo_id" "$l_repo_current_version" \
                #        "$l_repo_id" "$l_repo_download_version"
                #    m_compare_version "${l_repo_current_version}" "${l_repo_download_version}"
                #    l_status=$?

                #    if [ $l_status -eq 0 ]; then

                #        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (= "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                #        l_flag_install=1

                #    elif [ $l_status -eq 1 ]; then

                #        printf 'Repositorio "%s[%s]" (Versión Actual): Ya esta actualizado (> "%s")\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                #        l_flag_install=1

                #    else
                #        printf 'Repositorio "%s[%s]" (Versión Actual): Se actualizará a la versión "%s"\n' "$p_repo_id" "${l_repo_current_version}" "${l_repo_download_version}"
                #    fi
                #fi

                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then
                    l_path_bin="${g_path_programs_win}/LSP_Servers/Rust_Analyzer"
                    mkdir -p "${l_path_bin}"

                    echo "Copiando \"${l_path_temp}/rust-analyzer.exe\" a \"${l_path_bin}\""
                    cp "${l_path_temp}/rust-analyzer.exe" "${l_path_bin}"
                    echo "Copiando \"${l_path_temp}/rust-analyzer.pdb\" a \"${l_path_bin}\""
                    cp "${l_path_temp}/rust-analyzer.pdb" "${l_path_bin}"
                    #mkdir -p "${l_path_man}"
                    
                    #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                    echo "$p_repo_last_version_pretty" > "${l_path_bin}/rust-analyzer.info" 
                fi
            fi
            ;;


        graalvm)

            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Por ahora se instala solo las herramientas:
            # Native Image
            # VisualVM
            #No eso se instalaran los soportes a los demans lenguajes (use 'gu install [tool-name]'):
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
                
                l_path_bin="${g_path_programs_lnx}/graalvm"
                if [ $p_arti_index -ne 0 ]; then
                    l_path_bin="${l_path_bin}_${p_arti_version}"
                fi

                #Instalación de GraalVM (Core)
                if [ $p_artifact_index -eq 0 ]; then

                    l_path_temp="${l_path_temp}/graalvm-ce-java${p_arti_version}-${p_repo_last_version_pretty}"

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

                #Descargar el instalador del tool 'Native Image'
                elif [ $p_install_win_cmds -eq 1 ]; then

                    l_path_bin="${l_path_bin}/installers"
                    mkdir -p "$l_path_bin"

                    #mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_temp}/native-image"
                    #cp "${l_path_temp}/native-image" "${l_path_bin}/"
                    echo "Copiando el instalador \"${l_path_temp}/${p_artifact_name_woext}\" en \"${l_path_bin}/\""
                    mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_bin}/"
                    echo "Para instalar 'Native Image' use una de las siguientes alternativas:"
                    echo " > gu install native-image"
                    echo " > cd ${l_path_bin}"
                    echo "   gu -L install ${p_artifact_name_woext}"

                #Descargar el instalador de tool 'VisualVM'
                else

                    l_path_bin="${l_path_bin}/installers"
                    mkdir -p "$l_path_bin"

                    echo "Copiando el instalador \"${l_path_temp}/${p_artifact_name_woext}\" en \"${l_path_bin}/\""
                    mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_bin}/"
                    echo "Para instalar 'Native Image' use una de las siguientes alternativas:"
                    echo " > gu install jvisualvm"
                    echo " > cd ${l_path_bin}"
                    echo "   gu -L install ${p_artifact_name_woext}"

                fi

            else
                
                l_path_bin="${g_path_programs_win}/GraalVM"
                if [ $p_arti_index -ne 0 ]; then
                    l_path_bin="${l_path_bin}_${p_arti_version}"
                fi

                #Instalación de GraalVM (Core)
                if [ $p_artifact_index -eq 0 ]; then
                    
                    l_path_temp="${l_path_temp}/graalvm-ce-java${p_arti_version}-${p_repo_last_version_pretty}"

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
                
                #Descargar el instalador del tool 'Native Image'
                elif [ $p_install_win_cmds -eq 1 ]; then

                    l_path_bin="${l_path_bin}/installers"
                    mkdir -p "$l_path_bin"

                    #mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_temp}/native-image"
                    #cp "${l_path_temp}/native-image" "${l_path_bin}/"
                    echo "Copiando el instalador \"${l_path_temp}/${p_artifact_name_woext}\" en \"${l_path_bin}/\""
                    mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_bin}/"
                    echo "Para instalar 'Native Image' use una de las siguientes alternativas:"
                    echo " > gu install native-image"
                    echo " > cd ${l_path_bin}"
                    echo "   gu -L install ${p_artifact_name_woext}"

                #Descargar el instalador de tool 'VisualVM'
                else

                    l_path_bin="${l_path_bin}/installers"
                    mkdir -p "$l_path_bin"

                    echo "Copiando el instalador \"${l_path_temp}/${p_artifact_name_woext}\" en \"${l_path_bin}/\""
                    mv "${l_path_temp}/${p_artifact_name_woext}" "${l_path_bin}/"
                    echo "Para instalar 'Native Image' use una de las siguientes alternativas:"
                    echo " > gu install jvisualvm"
                    printf " > cd "
                    wslpath -w "${l_path_bin}"
                    echo "   gu -L install ${p_artifact_name_woext}"

                fi
            fi
            ;;

        jdtls)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            
            #Copiando el binario en una ruta del path
            if [ $p_install_win_cmds -ne 0 ]; then
                
                l_path_bin="${g_path_programs_lnx}/lsp_servers/jdt_ls"

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
                
                l_path_bin="${g_path_programs_win}/LSP_Servers/JDT_LS"

                #Limpieza del directorio del programa
                if  [ ! -d "$l_path_bin" ]; then
                    mkdir -p $l_path_bin
                else
                    #Limpieza
                    rm -rf ${l_path_bin}/*
                fi
                    
                #Mover los archivos
                #rm "${l_path_temp}/${p_artifact_name_woext}.tar.zp"
                find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tar.gz" -exec mv '{}' ${l_path_bin} \;
            fi
            ;;

        *)
           printf 'ERROR (50): No esta definido logica para el repositorio "%s" para procesar el artefacto "%s"\n' "$p_repo_id" "$l_tag"
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
        l_base_url=$(m_get_last_repo_url "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$l_artifact_name" $p_install_win_cmds)
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

function m_install_artifacts() {

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
            m_copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.tar.gz}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
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
            m_copy_artifact_files "$p_repo_id" $l_i "${l_tmp}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
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
            m_copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.zip}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            #l_status=0
            printf 'Artefacto "%s[%s]" ("%s") finalizo su configuración\n' "${l_tag}" "${l_i}" "${l_artifact_name}"

        elif [ $l_artifact_type -eq 0 ]; then

            #Copiar los archivos necesarios
            printf 'Copiando los archivos de artefacto "%s[%s]" ("%s") en las rutas especificas del SO ...\n' "${l_tag}" "${l_i}" "${l_artifact_name}"
            if [ $p_install_win_cmds -eq 0 ]; then
                m_copy_artifact_files "$p_repo_id" $l_i "${l_artifact_name%.exe}" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
                    "$p_repo_last_version_pretty" $l_is_last "$p_arti_version" $p_arti_index
            else
                m_copy_artifact_files "$p_repo_id" $l_i "$l_artifact_name" $p_install_win_cmds "$p_repo_current_version" "$p_repo_last_version" \
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

function m_intall_repository() { 

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
    m_load_artifacts "$p_repo_id" "$p_repo_last_version" "$p_repo_last_version_pretty" la_artifact_names la_artifact_types "$p_arti_version" $p_install_win_cmds
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
    if ! m_download_artifacts "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$p_repo_last_version_pretty" la_artifact_names "$p_arti_version"; then
        echo "ERROR (43): No se ha podido descargar los artefactos del repositorio \"${l_tag}\""
        m_clean_temp "$p_repo_id"
        return 23
    fi

    #6. Instalar segun el tipo de artefecto
    if ! m_install_artifacts "${p_repo_id}" "${p_repo_name}" la_artifact_names la_artifact_types "${p_repo_current_version}" "${p_repo_last_version}" \
        "$p_repo_last_version_pretty" "$p_arti_version" $p_arti_index $p_install_win_cmds; then
        echo "ERROR (44): No se ha podido instalar los artefecto de repositorio \"${l_tag}\""
        m_clean_temp "$p_repo_id"
        return 24
    fi

    m_show_final_message "$p_repo_id" "$p_repo_last_version_pretty" "$p_arti_version" $p_install_win_cmds
    m_clean_temp "$p_repo_id"
    return 0

}

#}}}

#Codigo principal del script {{{

#Todos los repositorios que se pueden instalar
declare -A gA_repositories=(
        ['bat']='sharkdp/bat'
        ['ripgrep']='BurntSushi/ripgrep'
        ['xsv']='BurntSushi/xsv'
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
        ['nerd-fonts']='ryanoasis/nerd-fonts'
        ['powershell']='PowerShell/PowerShell'
        ['roslyn']='OmniSharp/omnisharp-roslyn'
        ['netcoredbg']='Samsung/netcoredbg'
        ['neovim']='neovim/neovim'
        ['go']='golang'
        ['cmake']='Kitware/CMake'
        ['ninja']='ninja-build/ninja'
        ['clangd']='clangd/clangd'
        ['rust-analyzer']='rust-lang/rust-analyzer'
        ['graalvm']='graalvm/graalvm-ce-builds'
        ['jdtls']='jdtls'
    )


#Repositorios opcionales y su flag para configuración. Usar valores 2^n (4, 8, 16, ...)
#Sus valores debera coincider con lo que se muestra en el menu "m_show_menu_core"
declare -A gA_optional_repositories=(
        ['neovim']=8
        ['k0s']=16
        ['nerd-fonts']=32
        ['powershell']=64
        ['roslyn']=128
        ['netcoredbg']=256
        ['go']=512
        ['cmake']=1024
        ['ninja']=2048
        ['clangd']=4096
        ['rust-analyzer']=8192
        ['graalvm']=16384
        ['jdtls']=32768
    )


function m_setup_repository() {

    #1. Argumentos 
    local p_repo_id="$1"

    local p_repo_can_setup=1
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_repo_can_setup=$2
    fi

    local p_must_update_all_installed_repo=1
    if [[ "$3" =~ ^[0-9]+$ ]]; then
        p_must_update_all_installed_repo=$3
    fi

    local p_show_title=0
    if [[ "$4" =~ ^[0-9]+$ ]]; then
        p_show_title=$4
    fi

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
        l_repo_name_aux="$l_repo_id"
    else
        l_repo_name_aux="$l_repo_name"
    fi

    #3. Obtneer la ultima version del repositorio
    declare -a la_repo_versions
    declare -a la_arti_versions
    m_get_repo_latest_version "$p_repo_id" "$l_repo_name" la_repo_versions la_arti_versions
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
    l_repo_current_version=$(m_get_repo_current_version "$p_repo_id" ${l_install_win_cmds} "")
    l_repo_is_installed=$?          #(9) El repositorio unknown porque no se implemento la logica
                                    #(3) El repositorio unknown porque no se puede obtener (siempre instalarlo)
                                    #(1) El repositorio no esta instalado 
                                    #(0) El repositorio instalado, con version correcta
                                    #(2) El repositorio instalado, con version incorrecta

    #Obtener el valor inicial del flag que indica si se debe configurar el paquete
    local l_repo_must_setup_lnx=1  #(1) No debe configurarse, (0) Debe configurarse (instalarse/actualizarse)

    if [ $l_repo_can_setup -ne 0 ]; then
       #Si no se puede configurar, pero el flag de actualización de un repo existente esta habilitado: instalarlo
       if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ] && [ $p_must_update_all_installed_repo -eq 0 ]; then
           l_repo_must_setup_lnx=0
       else
           l_repo_must_setup_lnx=1
       fi
    else
       l_repo_must_setup_lnx=0
    fi

    #Repositorios especiales que no deberia instalarse segun el tipo de distribución Linux
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
    local l_aux=''
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
                 
                #m_compare_version "${p_repo_current_version}" "${l_repo_last_version_pretty}"
                m_compare_version "${l_repo_current_version}" "${l_repo_last_version_pretty}"
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
                m_intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds
            else
                for ((l_n=0; l_n<${l_arti_versions_nbr}; l_n++)); do
                    l_aux="${l_tag}[${la_arti_versions[${l_n}]}]"
                    printf "\n\nSe iniciara la configuración de los artefactos del repositorio \"${l_aux}\" ...\n"
                    m_intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
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
    l_repo_current_version=$(m_get_repo_current_version "$p_repo_id" ${l_install_win_cmds} "")
    l_repo_is_installed=$?          #(9) El repositorio unknown (no implementado la logica)
                                    #(3) El repositorio unknown porque no se puede obtener (siempre instalarlo)
                                    #(1) El repositorio no esta instalado 
                                    #(0) El repositorio instalado, con version correcta
                                    #(2) El repositorio instalado, con version incorrecta

    #Obtener el valor inicial del flag que indica si se debe configurar el paquete
    local l_repo_must_setup_win=1  #(1) No debe configurarse, (0) Debe configurarse (instalarse/actualizarse)

    if [ $l_repo_can_setup -ne 0 ]; then
       #Si no se puede configurar, pero el flag de actualización de un repo existente esta habilitado: instalarlo
       if [ $l_repo_is_installed -eq 0 -o $l_repo_is_installed -eq 2 ] && [ $p_must_update_all_installed_repo -eq 0 ]; then
           l_repo_must_setup_win=0
       else
           l_repo_must_setup_win=1
       fi
    else
       l_repo_must_setup_win=0
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
            powershell)
                #En windows se instala manualmente y luego solicita Actualización cada vez que existe nueva versión
                l_repo_must_setup_win=1;
                ;;
        esac

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
                 
                #m_compare_version "${p_repo_current_version}" "${l_repo_last_version_pretty}"
                m_compare_version "${l_repo_current_version}" "${l_repo_last_version_pretty}"
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
                m_intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" "" 0 $l_install_win_cmds
            else
                for ((l_n=0; l_n<${l_arti_versions_nbr}; l_n++)); do
                    l_aux="${l_tag}[${la_arti_versions[${l_n}]}]"
                    printf '\n\nSe iniciara la configuración de los artefactos del repositorio "%s" ...\n' "${l_aux}"
                    m_intall_repository "$p_repo_id" "$l_repo_name" "${l_repo_current_version}" "$l_repo_last_version" "$l_repo_last_version_pretty" \
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
    local l_option=1
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
        l_option=1
        l_flag=$(( $p_opciones & $l_option ))
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

    #5. Configurar (Instalar o Actualizar) los diferentes repositorios
    
    #Si un repositorio esta instalado, debe actualizarse
    local l_must_update_all_installed_repo=1
    l_flag=$(( $p_opciones & 2 ))
    if [ $l_flag -eq 2 ]; then l_must_update_all_installed_repo=0; fi

    local l_repo_id=''
    local l_repo_can_setup=1
    local l_repo_is_optional=1       #(1) repositorio basico, (0) repositorio opcional
    for l_repo_id in "${!gA_repositories[@]}"; do

        #5.1 Deteminar si el repositorio debe instalarse y su tipo
        l_option=${gA_optional_repositories[$l_repo_id]}
        l_repo_can_setup=1 #Por defecto no debe confugurarse

        #Es un repositorio basico
        if [ -z "$l_option" ]; then

            l_repo_is_optional=1

            #Si es un repositorio basico, permitir la configuración si se ingresa la opciones 4
            l_flag=$(( $p_opciones & 4 ))
            if [ $l_flag -eq 4 ]; then l_repo_can_setup=0; fi

        #Es un repositorio opcional
        else

            l_repo_is_optional=0

            #Esta habilitado para instalar el repositorio opcional
            if [[ "$l_option" =~ ^[0-9]+$ ]]; then
                if [ $l_option -ne 0 ]; then
                    #Suma binarios es igual al flag, se debe instalar el repo opcional
                    l_flag=$(( $p_opciones & $l_option ))
                    if [ $l_option -eq $l_flag ]; then l_repo_can_setup=0; fi
                fi 
            fi
        fi

        #5.2 Instalar el repositorio
        m_setup_repository "$l_repo_id" $l_repo_can_setup $l_must_update_all_installed_repo

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
    #echo "    (    0) Actualizar xxx (siempre se realizara esta opción)"
    echo "     (    1) Actualizar los paquetes existentes del sistema operativo"   
    echo "     (    2) Actualizar los binarios de los repositorios existentes"
    echo "     (    4) Instalar/Actualizar los binarios de los repositorios basicos"
    echo "     (    8) Instalar/Actualizar el editor: \"NeoVim\""
    echo "     (   16) Instalar/Actualizar la implementación de Kubernates: \"k0s\""
    echo "     (   32) Instalar/Actualizar en el server fuentes Nerd Fonts: \"ryanoasis/nerd-fonts\""
    echo "     (   64) Instalar/Actualizar 'Powershell Core' \"PowerShell/PowerShell\""
    echo "     (  128) Instalar/Actualizar el LSP Server de .Net: \"OmniSharp/omnisharp-roslyn\""
    echo "     (  256) Instalar/Actualizar el DAP Server de .Net: \"Samsung/netcoredbg\""
    echo "     (  512) Instalar/Actualizar RTE de \"Go\""
    echo "     ( 1024) Instalar/Actualizar el Build Generator C/C++ \"Kitware/CMake\""
    echo "     ( 2048) Instalar/Actualizar el Build Tool C/C++ \"ninja-build/ninja\""
    echo "     ( 4096) Instalar/Actualizar el LSP Server de C/C++: \"clangd/clangd\""
    echo "     ( 8192) Instalar/Actualizar el LSP Server de Rust: \"rust-lang/rust-analyzer\""
    echo "     (16384) Instalar/Actualizar el RTE GraalVM CE: \"graalvm/graalvm-ce-builds\""
    echo "     (32768) Instalar/Actualizar el LSP de Java 'JDT LS': \"eclipse/eclipse.jdt.ls\""
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

    m_main

#1. Instalando los repositorios especificados por las opciones indicas en '$2'
elif [ $gp_type_calling -eq 1 ]; then

    gp_opciones=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_opciones=$2
    else
        exit 98
    fi
    m_setup_repositories $gp_opciones 1

#3. Instalando un solo repostorio del ID indicao por '$2'
else

    gp_repo_id="$2"
    if [ -z "$gp_repo_id" ]; then
       echo "Parametro 3 \"$3\" debe ser un ID de repositorio valido"
       exit 99
    fi

    m_setup_repository "$gp_repo_id" 0 0 1

fi


