#!/bin/bash


#Expresiones regulares de sustitucion mas usuadas para las versiones
#La version 'x.y.z' esta la inicio o despues de caracteres no numericos
declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
#La version 'x.y.z' o 'x-y-z' esta la inicio o despues de caracteres no numericos
declare -r g_regexp_sust_version2='s/[^0-9]*\([0-9]\+\.[0-9.-]\+\).*/\1/'
#La version '.y.z' esta la inicio o despues de caracteres no numericos
declare -r g_regexp_sust_version3='s/[^0-9]*\([0-9.]\+\).*/\1/'
#La version 'xyz' (solo un entero sin puntos)  esta la inicio o despues de caracteres no numericos
declare -r g_regexp_sust_version4='s/[^0-9]*\([0-9]\+\).*/\1/'
#La version 'x.y.z' esta despues de un caracter vacio
declare -r g_regexp_sust_version5='s/.*\s\+\([0-9]\+\.[0-9.]\+\).*/\1/'


#Cuando no se puede determinar la version actual (siempre se instalara)
declare -r g_version_none='0.0.0'

#Variable global de la ruta donde se instalaran los programas CLI (mas complejos que un simple comando).
declare -r g_path_programs_lnx='/opt/tools'

#Variable global ruta de los programas CLI y/o binarios en Windows desde su WSL2
if [ $g_os_type -eq 1 ]; then
   declare -r g_path_programs_win='/mnt/d/CLI'
   declare -r g_path_commands_win="${g_path_programs_win}/Cmds"
fi

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


        cni-plugins)
            
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            if [ -f "${g_path_programs_lnx}/cni-plugins.info" ]; then
                l_tmp=$(cat "${g_path_programs_lnx}/cni-plugins.info" | head -n 1)
            else

                #Calcular la ruta de archivo/comando donde se obtiene la version
                if [ -z "$p_path_file" ]; then
                    l_path_file="${g_path_programs_lnx}/cni_plugins/"
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
#       >  2 si es un .tar.gz
#       >  3 si es un .zip
#       >  4 si es un .gz
#       >  5 si es un .tgz
#       > 99 si no se define el artefacto para el prefijo
#  - Argumento 3, un arreglo de nombre de los artectos a descargar
#En el argumento 2 se debe pasar la version pura quitando, sin contener "v" u otras letras iniciales
function _load_artifacts() {

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

        runc)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("runc.amd64")
            pna_artifact_types=(0)
            ;;


        cni-plugins)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("cni-plugins-linux-amd64-${p_repo_last_version}.tgz")
            pna_artifact_types=(5)
            ;;

        slirp4netns)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("slirp4netns-x86_64")
            pna_artifact_types=(0)
            ;;

        rootlesskit)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("rootlesskit-x86_64.tar.gz")
            pna_artifact_types=(2)
            ;;

        containerd)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("containerd-${p_repo_last_version_pretty}-linux-amd64.tar.gz")
            pna_artifact_types=(2)
            ;;

        buildkit)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("buildkit-${p_repo_last_version}.linux-amd64.tar.gz")
            pna_artifact_types=(2)
            ;;

        nerdctl)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("nerdctl-${p_repo_last_version_pretty}-linux-amd64.tar.gz" "nerdctl-full-${p_repo_last_version_pretty}-linux-amd64.tar.gz")
            pna_artifact_types=(2 2)
            ;;


        dive)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            fi

            pna_artifact_names=("dive_${p_repo_last_version_pretty}_linux_amd64.tar.gz")
            pna_artifact_types=(2)
            ;;



        *)
           return 1
           ;;
    esac

    return 0
}


#Si un nodo k0s esta iniciado solicitar su detención y deternerlo
#Parametros de entrada (argumentos y opciones):
#   1 > ID del repositorio
#   2 > Indice del artefato del repositorio que se desea instalar
#Parametros de salida (valor de retorno):
#   0 > El nodo no esta iniciado (no esta instalado o esta detenido).
#   1 > El nodo está iniciado pero NO se acepto deternerlo.
#   2 > El nodo esta iniciado y se acepto detenerlo.
function _request_stop_k0s_node() {

    #1. Argumentos
    p_repo_id="$1"
    p_artifact_index=$2
    
    #2. Logica
    local l_option

    #Averigur si esta instalado a nivel usuario
    local l_status
    local l_info

    #Si se no esta instalado o esta detenenido
    l_info=$(sudo k0s status 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_info" ]; then
        return 0
    fi

    #Si esta detenido
    local l_aux
    l_aux=$(echo "$l_info" | grep -e '^Process ID' 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        return 0
    fi
    local l_node_process_id=$(echo "$l_aux" | sed 's/.*: \(.*\)/\1/' 2> /dev/null)

    local l_nodo_type=$(echo "$l_info" | grep -e '^Role' | sed 's/.*: \(.*\)/\1/' 2> /dev/null)

    #Solicitar la detención del servicio
    printf "%bEl nodo k0s '%s' (PID: %s) esta iniciado y requiere detenerse para instalar el artefacto[%s] del repositorio '%s'\n" \
           "$g_color_warning" "$l_nodo_type" "$l_node_process_id" "$p_artifact_index" "$p_repo_id"

    printf "¿Desea detener la nodo k0s?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_opaque" "$g_color_reset"
    read -rei 's' -p ': ' l_option
    if [ ! "$l_option" = "s" ]; then
        printf '%bNo se instalará el artefacto[%s] del repositorio "%s".\nDetenga el nodo k0s %s o acepte su detención para su instalación%b\n' \
               "$g_color_opaque" "$p_artifact_index" "$p_repo_id" "$l_nodo_type" "$g_color_reset"
        return 1
    fi

    #Detener el nodo k0s
    printf 'Deteniendo el nodo k0s %s ...\n' "$l_nodo_type"
    if [ $g_is_root -eq 0 ]; then
        k0s stop
    else
        sudo k0s stop
    fi
    return 2
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

    #Argumentos
    local p_repo_id=$1
    local p_path="$2/"
    local p_install_win_cmds=1
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    printf "Comparando versiones de '%s': \"Versión actual\" vs \"Versión ubica en '%s'\"...\n" "$p_repo_id" "$p_path"

    #Obteniendo la versión actual
    local l_current_version
    l_current_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds})

    local l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '   No se puede obtener la versión actual de "%s" (status: %s)\n' "$p_repo_id" "$l_status"
        return 9
    fi

    #Obteniendo la versión de lo especificado como parametro
    local l_other_version
    l_other_version=$(_get_repo_current_version "$p_repo_id" ${p_install_win_cmds} "$p_path")

    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '   No se puede obtener la versión de "%s" ubicada en "%s" (status: %s)\n' "$p_repo_id" "$p_path" "$l_status"
        return 8
    fi

    #Comparando ambas versiones
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


#Si la unidad servicio 'containerd' esta iniciado, solicitar su detención y deternerlo
#Parametros de entrada (argumentos y opciones):
#   1 > Nombre completo de la unidad de systemd
#   2 > ID del repositorio
#   3 > Indice del artefato del repositorio que se desea instalar
#Parametros de salida (valor de retorno):
#   0 > La unidad systemd NO esta instalado y NO esta iniciado
#   1 > La unidad systemd esta instalado pero NO esta iniciado (esta detenido)
#   2 > La unidad systemd esta iniciado pero NO se acepto deternerlo
#   3 > La unidad systemd iniciado se acepto detenerlo a nivel usuario
#   4 > La unidad systemd iniciado se acepto detenerlo a nivel system
function _request_stop_systemd_unit() {

    #1. Argumentos
    p_unit_name="$1"
    p_repo_id="$2"
    p_artifact_index=$3
    
    #2. Logica
    local l_option
    local l_status

    #Averigur si esta instalado a nivel usuario
    local l_is_user=0
    exist_systemd_unit "$p_unit_name" $l_is_user
    l_status=$?

    if [ $l_status -eq 0 ]; then

        #Averiguar si esta instalado a nivel system
        l_is_user=1
        exist_systemd_unit "$p_unit_name" $l_is_user
        l_status=$?

        if [ $l_status -eq 0 ]; then
            return 0
        fi
    fi

    #Si se no esta iniciado
    if [ $l_status -lt 4 ] && [ $l_status -gt 7 ]; then
        return 1
    fi

    #Solicitar la detención del servicio
    printf "%bLa unidad systemd '%s' esta iniciado y requiere detenerse para instalar el artefacto[%s] del repositorio '%s'\n" \
           "$g_color_warning" "$p_unit_name" "$p_artifact_index" "$p_repo_id"

    printf "¿Desea detener la unidad systemd?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_opaque" "$g_color_reset"
    read -rei 's' -p ': ' l_option
    if [ ! "$l_option" = "s" ]; then
        printf '%bNo se instalará el artefacto[%s] del repositorio "%s".\nDetenga el servicio "%s" o acepte su detención para su instalación%b\n' \
               "$g_color_opaque" "$p_artifact_index" "$p_repo_id" "$p_unit_name" "$g_color_reset"
        return 2
    fi

    #Si la unidad systemd esta a nivel usuario
    if [ $l_is_user -eq 0 ]; then
        printf 'Deteniendo la unidad "%s" a nivel usuario ...\n' "$p_unit_name"
        systemctl --user stop "$p_unit_name"
        return 3
    fi


    printf 'Deteniendo la unidad "%s" a nivel sistema ...\n' "$p_unit_name"
    if [ $g_is_root -eq 0 ]; then
        systemctl stop "$p_unit_name"
    else
        sudo systemctl stop "$p_unit_name"
    fi
    return 4
}


function _copy_artifact_files() {

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

    local l_status=0
    local l_flag_install=1
    local l_aux

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
                if [ $p_artifact_index -eq 0 ]; then
                    cp "${l_path_temp}/less.exe" "${l_path_bin}"
                else
                    cp "${l_path_temp}/lesskey.exe" "${l_path_bin}"
                fi

            else
                echo "ERROR (50): El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Windows"
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

            #Instalación de binario 'oh-my-posh'
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

            #Instalación de los temas de 'oh-my-posh'
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

                #Instalacion del SDK para construir el operador
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

                #Instalacion del SDK para construir el operador usando Ansible
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

                #Instalacion del SDK para construir el operador usando Helm
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

            #1. Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi

            #2. Si la nodo k0s esta iniciado, solicitar su detención
            _request_stop_k0s_node "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 1 ]; then
                return 41
            fi


            #3. Renombrar el binario antes de copiarlo
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


            #4. Si el nodo k0s estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 2 ]; then

                printf 'Iniciando el nodo k0s...\n'
                if [ $g_is_root -eq 0 ]; then
                    k0s start
                else
                    sudo k0s start
                fi
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
                _compare_version_current_with "$p_repo_id" "$l_path_temp" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    $l_flag_install=0
                else
                    $l_flag_install=1
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
                _compare_version_current_with "$p_repo_id" "$l_path_temp" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    $l_flag_install=0
                else
                    $l_flag_install=1
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
                _compare_version_current_with "$p_repo_id" "$l_path_temp/bin" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    $l_flag_install=0
                else
                    $l_flag_install=1
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
                _compare_version_current_with "$p_repo_id" "$l_path_temp/bin" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                    $l_flag_install=0
                else
                    $l_flag_install=1
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
                #_compare_version_current_with "$p_repo_id" "$l_path_temp" $p_install_win_cmds
                #l_status=$?

                ##Actualizar solo no esta configurado o tiene una version menor a la actual
                #if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                #    $l_flag_install=0
                #else
                #    $l_flag_install=1
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
                #_compare_version_current_with "$p_repo_id" "$l_path_temp" $p_install_win_cmds
                #l_status=$?

                ##Actualizar solo no esta configurado o tiene una version menor a la actual
                #if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then
                #    $l_flag_install=0
                #else
                #    $l_flag_install=1
                #fi


                #2. Instalación
                if [ $l_flag_install -eq 0 ]; then
                    l_path_bin="${g_path_programs_win}/LSP_Servers/Rust_Analyzer"
                    mkdir -p "${l_path_bin}"

                    echo "Copiando \"${l_path_temp}/rust-analyzer.exe\" a \"${l_path_bin}\""
                    cp "${l_path_temp}/rust-analyzer.exe" "${l_path_bin}"
                    #echo "Copiando \"${l_path_temp}/rust-analyzer.pdb\" a \"${l_path_bin}\""
                    #cp "${l_path_temp}/rust-analyzer.pdb" "${l_path_bin}"
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

                #Instalación del tool 'Native Image'
                elif [ $p_artifact_index -eq 1 ]; then

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

                #Instalación de tool 'VisualVM'
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
                
                #Instalación del tool 'Native Image'
                elif [ $p_artifact_index -eq 1 ]; then

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

                #Instalación de tool 'VisualVM'
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


        runc)

            #1. Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${l_path_temp}/runc.amd64\" a \"${l_path_temp}/runc\""
            mv "${l_path_temp}/runc.amd64" "${l_path_temp}/runc"

            echo "Copiando \"runc\" a \"${l_path_bin}\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp "${l_path_temp}/runc" "${l_path_bin}"
                chmod +x "${l_path_bin}/runc"
            else
                sudo cp "${l_path_temp}/runc" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/runc"
            fi

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;



        slirp4netns)

            #1. Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${l_path_temp}/slirp4netns-x86_64\" a \"${l_path_temp}/slirp4netns\""
            mv "${l_path_temp}/slirp4netns-x86_64" "${l_path_temp}/slirp4netns"

            echo "Copiando \"${l_path_temp}/slirp4netns\" a \"${l_path_bin}\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp "${l_path_temp}/slirp4netns" "${l_path_bin}"
                chmod +x "${l_path_bin}/slirp4netns"
            else
                sudo cp "${l_path_temp}/slirp4netns" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/slirp4netns"
            fi

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        rootlesskit)

            #1. Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_is_root -eq 0 ]; then

                echo "Copiando \"${l_path_temp}/rootlesskit-docker-proxy\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/rootlesskit-docker-proxy" "${l_path_bin}"
                chmod +x "${l_path_bin}/rootlesskit-docker-proxy"

                echo "Copiando \"${l_path_temp}/rootlesskit\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/rootlesskit" "${l_path_bin}"
                chmod +x "${l_path_bin}/rootlesskit"

                echo "Copiando \"${l_path_temp}/rootlessctl\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/rootlessctl" "${l_path_bin}"
                chmod +x "${l_path_bin}/rootlessctl"

            else

                echo "Copiando \"${l_path_temp}/rootlesskit-docker-proxy\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/rootlesskit-docker-proxy" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/rootlesskit-docker-proxy"

                echo "Copiando \"${l_path_temp}/rootlesskit\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/rootlesskit" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/rootlesskit"

                echo "Copiando \"${l_path_temp}/rootlessctl\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/rootlessctl" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/rootlessctl"

            fi

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;



        cni-plugins)

            #1. Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            l_path_bin="${g_path_programs_lnx}/cni_plugins"

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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Configurar: Si no existe el directorio
            if  [ ! -d "$l_path_bin" ]; then

                #Crear las carpeta
                echo "Creando la carpeta \"${l_path_bin}\" ..."
                if [ $g_is_root -eq 0 ]; then
                    mkdir -pm 755 $l_path_bin
                else
                    sudo mkdir -pm 755 $l_path_bin
                fi

                #Copiando los binarios
                echo "Copiando los binarios de \"${l_path_temp}\" a \"${l_path_bin}\" ..."
                if [ $g_is_root -eq 0 ]; then
                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_bin} \;
                    chmod +x ${l_path_bin}/*
                else
                    sudo find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_bin} \;
                    sudo chmod +x ${l_path_bin}/*
                fi

            #4. Configurar: Si existe el directorio: actualizar
            else

                #Elimimiando los binarios
                echo "Eliminando los binarios de \"${l_path_bin}\" ..."
                if [ $g_is_root -eq 0 ]; then
                    rm ${l_path_bin}/*
                else
                    sudo rm ${l_path_bin}/*
                fi

                #Copiando los binarios
                echo "Copiando los nuevos binarios de \"${l_path_temp}\" a \"${l_path_bin}\" ..."
                if [ $g_is_root -eq 0 ]; then
                    find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_bin} \;
                    chmod +x ${l_path_bin}/*
                else
                    sudo find "${l_path_temp}" -maxdepth 1 -mindepth 1 -not -name "${p_artifact_name_woext}.tgz" -exec cp '{}' ${l_path_bin} \;
                    sudo chmod +x ${l_path_bin}/*
                fi

            fi

            #5. Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            echo "$p_repo_last_version_pretty" > "${g_path_programs_lnx}/cni-plugins.info" 

            #6. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_is_root -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        containerd)

            #1. Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/bin"
            
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi


            #3. Configurar: Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_is_root -eq 0 ]; then

                echo "Copiando \"${l_path_temp}/containerd-shim\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-shim" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-shim"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v1\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-shim-runc-v1" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-shim-runc-v1"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v2\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-shim-runc-v2" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-shim-runc-v2"

                echo "Copiando \"${l_path_temp}/containerd-stress\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-stress" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-stress"

                echo "Copiando \"${l_path_temp}/ctr\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/ctr" "${l_path_bin}"
                chmod +x "${l_path_bin}/ctr"

                echo "Copiando \"${l_path_temp}/containerd\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd"

            else

                echo "Copiando \"${l_path_temp}/containerd-shim\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-shim" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-shim"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v1\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-shim-runc-v1" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-shim-runc-v1"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v2\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-shim-runc-v2" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-shim-runc-v2"

                echo "Copiando \"${l_path_temp}/containerd-stress\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-stress" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-stress"

                echo "Copiando \"${l_path_temp}/ctr\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/ctr" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/ctr"

                echo "Copiando \"${l_path_temp}/containerd\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd"

            fi

            #Descargar archivo de configuracion como servicio a nivel system:
            mkdir -p ~/.files/setup/programs/nerdctl/systemd/user
            
            printf 'Descargando el archivo de configuracion de "%s" a nivel system en "%s"\n' "containerd.service" "~/.files/setup/programs/nerdctl/systemd/user/"
            curl -fLo ~/.files/setup/programs/nerdctl/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 2 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 3 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_is_root -eq 0 ]; then
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
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/bin"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            _request_stop_systemd_unit 'buildkit.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Configurar: Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_is_root -eq 0 ]; then

                echo "Copiando \"${l_path_temp}/buildkit-runc\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/buildkit-runc" "${l_path_bin}"
                chmod +x "${l_path_bin}/buildkit-runc"

                echo "Copiando \"${l_path_temp}/buildkitd\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/buildkitd" "${l_path_bin}"
                chmod +x "${l_path_bin}/buildkitd"

                echo "Copiando \"${l_path_temp}/buildkit-qemu-*\" a \"${l_path_bin}\" ..."
                cp ${l_path_temp}/buildkit-qemu-* "${l_path_bin}"
                chmod +x ${l_path_bin}/buildkit-qemu-*

                echo "Copiando \"${l_path_temp}/buildctl\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/buildctl" "${l_path_bin}"
                chmod +x "${l_path_bin}/buildctl"

            else

                echo "Copiando \"${l_path_temp}/buildkit-runc\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/buildkit-runc" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/buildkit-runc"

                echo "Copiando \"${l_path_temp}/buildkitd\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/buildkitd" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/buildkitd"

                echo "Copiando \"${l_path_temp}/buildkit-qemu-*\" a \"${l_path_bin}\" ..."
                sudo cp ${l_path_temp}/buildkit-qemu-* "${l_path_bin}"
                sudo chmod +x ${l_path_bin}/buildkit-qemu-*

                echo "Copiando \"${l_path_temp}/buildctl\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/buildctl" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/buildctl"

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
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            local l_status_stop=-1
          
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi


            #2. Configuración: Instalación de binario basico
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_is_root -eq 0 ]; then

                    echo "Copiando \"${l_path_temp}/nerdctl\" a \"${l_path_bin}\" ..."
                    cp "${l_path_temp}/nerdctl" "${l_path_bin}"
                    chmod +x "${l_path_bin}/nerdctl"

                else

                    echo "Copiando \"${l_path_temp}/nerdctl\" a \"${l_path_bin}\" ..."
                    sudo cp "${l_path_temp}/nerdctl" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/nerdctl"

                fi

                mkdir -p ~/.files/setup/programs/containerd

                #Archivos para instalar 'containerd' de modo rootless
                echo "Copiando \"${l_path_temp}/containerd-rootless.sh\" (tool gestión del ContainerD en modo rootless) a \"~/.files/setup/programs/containerd\" ..."
                cp "${l_path_temp}/containerd-rootless.sh" ~/.files/setup/programs/containerd
                chmod u+x ~/.files/setup/programs/containerd/containerd-rootless.sh

                echo "Copiando \"${l_path_temp}/containerd-rootless-setuptool.sh\" (instalador de ContainerD en modo rootless)  a \"~/.files/setup/programs/containerd\" ..."
                cp "${l_path_temp}/containerd-rootless-setuptool.sh" ~/.files/setup/programs/containerd
                chmod u+x ~/.files/setup/programs/containerd/containerd-rootless-setuptool.sh

            #3. Configuración: Instalación de binarios de complementos que su reposotrio no ofrece el compilado (solo la fuente). Para ello se usa el full
            else

                #3.1. Rutas de los artectos 
                l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/bin"

                #3.2. Configurar 'rootless-containers/bypass4netns' usado para accelar 'Slirp4netns' (NAT o port-forwading de llamadas del exterior al contenedor)

                #Comparar la versión actual con la versión descargada
                _compare_version_current_with "bypass4netns" "$l_path_temp" $p_install_win_cmds
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

                        _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
                        l_status_stop=$?
                    fi

                    #Si no esta iniciado o si esta iniciado se acepta detenerlo, instalarlo
                    if [ $l_status_stop -ne 2 ]; then

                        printf 'Instalando el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s ...\n' "$p_artifact_index" "$p_repo_id"
                        #Instalando
                        if [ $g_is_root -eq 0 ]; then

                            echo "Copiando \"${l_path_temp}/bypass4netns\" a \"${l_path_bin}\" ..."
                            cp "${l_path_temp}/bypass4netns" "${l_path_bin}"
                            chmod +x "${l_path_bin}/bypass4netns"

                            echo "Copiando \"${l_path_temp}/bypass4netnsd\" a \"${l_path_bin}\" ..."
                            cp "${l_path_temp}/bypass4netnsd" "${l_path_bin}"
                            chmod +x "${l_path_bin}/bypass4netnsd"

                        else

                            echo "Copiando \"${l_path_temp}/bypass4netns\" a \"${l_path_bin}\" ..."
                            sudo cp "${l_path_temp}/bypass4netns" "${l_path_bin}"
                            sudo chmod +x "${l_path_bin}/bypass4netns"

                            echo "Copiando \"${l_path_temp}/bypass4netnsd\" a \"${l_path_bin}\" ..."
                            sudo cp "${l_path_temp}/bypass4netnsd" "${l_path_bin}"
                            sudo chmod +x "${l_path_bin}/bypass4netnsd"

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
                    if [ $g_is_root -eq 0 ]; then
                        systemctl start containerd.service 
                    else
                        sudo systemctl start containerd.service 
                    fi
                fi

            fi

            ;;


        dive)

            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"
            
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"${l_path_temp}/dive\" a \"${l_path_bin}\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp "${l_path_temp}/dive" "${l_path_bin}"
                chmod +x "${l_path_bin}/dive"
            else
                sudo cp "${l_path_temp}/dive" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/dive"
            fi
            ;;



        *)
           printf 'ERROR (50): No esta definido logica para el repositorio "%s" para procesar el artefacto "%s"\n' "$p_repo_id" "$l_tag"
           return 50
            
    esac

    return 0

}


#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para instalar
#  2 > Flag '0' si es artefacto instalado en Windows (asociado a WSL2)
#  3 > Flag '0' si se muestra el titulo, caso contrario no se muestra.
#El valor de retorno puede ser:
#  0 > Se debe continuar con la instalación, cualquier otro caso no se debe continuar con la instalación
_precondition_to_intall_menu_option() {

    #Argumentos
    local p_option_idx=$1

    local p_install_win_cmds=1
    if [ "$2" = "0" ]; then
        p_install_win_cmds=0
    fi

    local p_show_title=1
    if [ "$3" = "0" ]; then
        p_show_title=1
    fi

    local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    local l_option_value=$((1 << p_option_idx))


    #Realizar validaciones segun la opcion de menu escogida

    #Por defecto, se debe continuar con la instalación
    return 0

}


#Only for test
_uninstall_repository() {

    #Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_current_version="$3"
    local p_install_win_cmds=1
    if [ "$4" = "0" ]; then
        p_install_win_cmds=0
    fi

    #Inicialización de variables
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
_uninstall_repository2() {

    #Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_current_version="$3"
    local p_install_win_cmds=1
    if [ "$4" = "0" ]; then
        p_install_win_cmds=0
    fi

    #Inicialización de variables
    #Tag usuado para imprimir un identificador del artefacto en un log
    local l_tag="${p_repo_id}[${p_repo_current_version}]"
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

    local l_status=0
    local l_flag_uninstall=1
    local l_aux

    case "$p_repo_id" in


        runc)

            #1. Ruta local de los artefactos
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Eliminando los archivos

            echo "Eliminado \"runc\" de \"${l_path_bin}\" ..."
            if [ $g_is_root -eq 0 ]; then
                rm "${l_path_bin}/runc"
            else
                sudo cp "${l_path_bin}/runc"
            fi
            ;;


        slirp4netns)

            #1. Ruta local de los artefactos
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Eliminando los archivos 
            echo "Eliminando \"slirp4netns\" de \"${l_path_bin}\" ..."
            if [ $g_is_root -eq 0 ]; then
                rm "${l_path_bin}/slirp4netns"
            else
                sudo rm "${l_path_bin}/slirp4netns"
            fi
            ;;


        rootlesskit)

            #1. Ruta local de los artefactos
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Eliminando los archivos 
            if [ $g_is_root -eq 0 ]; then

                echo "Eliminando \"rootlesskit-docker-proxy\" a \"${l_path_bin}\" ..."
                cp "${l_path_bin}/rootlesskit-docker-proxy"

                echo "Eliminando \"rootlesskit\" a \"${l_path_bin}\" ..."
                cp "${l_path_bin}/rootlesskit"

                echo "Eliminando \"rootlessctl\" a \"${l_path_bin}\" ..."
                cp "${l_path_bin}/rootlessctl"

            else

                echo "Eliminando \"rootlesskit-docker-proxy\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_bin}/rootlesskit-docker-proxy"

                echo "Eliminando\"rootlesskit\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_bin}/rootlesskit"

                echo "Eliminando \"rootlessctl\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_bin}/rootlessctl"

            fi
            ;;



        cni-plugins)

            #1. Ruta local de los artefactos
            l_path_bin="${g_path_programs_lnx}/cni_plugins"

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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Configurar: Si no existe el directorio
            if  [ ! -d "$l_path_bin" ]; then

                #Crear las carpeta
                echo "Creando la carpeta \"${l_path_bin}\" ..."
                if [ $g_is_root -eq 0 ]; then
                    mkdir -pm 755 $l_path_bin
                else
                    sudo mkdir -pm 755 $l_path_bin
                fi


            #4. Configurar: Si existe el directorio: actualizar
            else

                #Elimimiando los binarios
                echo "Eliminando los binarios de \"${l_path_bin}\" ..."
                if [ $g_is_root -eq 0 ]; then
                    rm ${l_path_bin}/*
                else
                    sudo rm ${l_path_bin}/*
                fi


            fi

            #5. Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            rm "${g_path_programs_lnx}/cni-plugins.info" 

            ;;


        containerd)

            #1. Ruta local de los artefactos
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

            _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi


            #3. Eliminando archivos 
            if [ $g_is_root -eq 0 ]; then

                echo "Copiando \"${l_path_temp}/containerd-shim\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-shim" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-shim"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v1\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-shim-runc-v1" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-shim-runc-v1"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v2\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-shim-runc-v2" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-shim-runc-v2"

                echo "Copiando \"${l_path_temp}/containerd-stress\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd-stress" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd-stress"

                echo "Copiando \"${l_path_temp}/ctr\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/ctr" "${l_path_bin}"
                chmod +x "${l_path_bin}/ctr"

                echo "Copiando \"${l_path_temp}/containerd\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/containerd" "${l_path_bin}"
                chmod +x "${l_path_bin}/containerd"

            else

                echo "Copiando \"${l_path_temp}/containerd-shim\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-shim" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-shim"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v1\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-shim-runc-v1" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-shim-runc-v1"

                echo "Copiando \"${l_path_temp}/containerd-shim-runc-v2\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-shim-runc-v2" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-shim-runc-v2"

                echo "Copiando \"${l_path_temp}/containerd-stress\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd-stress" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd-stress"

                echo "Copiando \"${l_path_temp}/ctr\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/ctr" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/ctr"

                echo "Copiando \"${l_path_temp}/containerd\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/containerd" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/containerd"

            fi

            #Descargar archivo de configuracion como servicio a nivel system:
            mkdir -p ~/.files/setup/programs/nerdctl/systemd/user
            
            printf 'Descargando el archivo de configuracion de "%s" a nivel system en "%s"\n' "containerd.service" "~/.files/setup/programs/nerdctl/systemd/user/"
            curl -fLo ~/.files/setup/programs/nerdctl/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo

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
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            _request_stop_systemd_unit 'buildkit.service' "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. 
            if [ $g_is_root -eq 0 ]; then

                echo "Copiando \"${l_path_temp}/buildkit-runc\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/buildkit-runc" "${l_path_bin}"
                chmod +x "${l_path_bin}/buildkit-runc"

                echo "Copiando \"${l_path_temp}/buildkitd\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/buildkitd" "${l_path_bin}"
                chmod +x "${l_path_bin}/buildkitd"

                echo "Copiando \"${l_path_temp}/buildkit-qemu-*\" a \"${l_path_bin}\" ..."
                cp ${l_path_temp}/buildkit-qemu-* "${l_path_bin}"
                chmod +x ${l_path_bin}/buildkit-qemu-*

                echo "Copiando \"${l_path_temp}/buildctl\" a \"${l_path_bin}\" ..."
                cp "${l_path_temp}/buildctl" "${l_path_bin}"
                chmod +x "${l_path_bin}/buildctl"

            else

                echo "Copiando \"${l_path_temp}/buildkit-runc\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/buildkit-runc" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/buildkit-runc"

                echo "Copiando \"${l_path_temp}/buildkitd\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/buildkitd" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/buildkitd"

                echo "Copiando \"${l_path_temp}/buildkit-qemu-*\" a \"${l_path_bin}\" ..."
                sudo cp ${l_path_temp}/buildkit-qemu-* "${l_path_bin}"
                sudo chmod +x ${l_path_bin}/buildkit-qemu-*

                echo "Copiando \"${l_path_temp}/buildctl\" a \"${l_path_bin}\" ..."
                sudo cp "${l_path_temp}/buildctl" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/buildctl"

            fi

            #Descargar archivo de configuracion como servicio a nivel system:


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
            local l_status_stop=-1
          
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi


            #2. Configuración: Instalación de binario basico
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                if [ $g_is_root -eq 0 ]; then

                    echo "Copiando \"${l_path_temp}/nerdctl\" a \"${l_path_bin}\" ..."
                    cp "${l_path_temp}/nerdctl" "${l_path_bin}"
                    chmod +x "${l_path_bin}/nerdctl"

                else

                    echo "Copiando \"${l_path_temp}/nerdctl\" a \"${l_path_bin}\" ..."
                    sudo cp "${l_path_temp}/nerdctl" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/nerdctl"

                fi

                mkdir -p ~/.files/setup/programs/containerd

                #Archivos para instalar 'containerd' de modo rootless
                echo "Copiando \"${l_path_temp}/containerd-rootless.sh\" (tool gestión del ContainerD en modo rootless) a \"~/.files/setup/programs/containerd\" ..."
                cp "${l_path_temp}/containerd-rootless.sh" ~/.files/setup/programs/containerd
                chmod u+x ~/.files/setup/programs/containerd/containerd-rootless.sh

                echo "Copiando \"${l_path_temp}/containerd-rootless-setuptool.sh\" (instalador de ContainerD en modo rootless)  a \"~/.files/setup/programs/containerd\" ..."
                cp "${l_path_temp}/containerd-rootless-setuptool.sh" ~/.files/setup/programs/containerd
                chmod u+x ~/.files/setup/programs/containerd/containerd-rootless-setuptool.sh

            #3. Configuración: Instalación de binarios de complementos que su reposotrio no ofrece el compilado (solo la fuente). Para ello se usa el full
            else

                #3.1. Rutas de los artectos 
                l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/bin"

                #3.2. Configurar 'rootless-containers/bypass4netns' usado para accelar 'Slirp4netns' (NAT o port-forwading de llamadas del exterior al contenedor)

                #Comparar la versión actual con la versión descargada
                _compare_version_current_with "bypass4netns" "$l_path_temp" $p_install_win_cmds
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

                        _request_stop_systemd_unit 'containerd.service' "$p_repo_id" "$p_artifact_index"
                        l_status_stop=$?
                    fi

                    #Si no esta iniciado o si esta iniciado se acepta detenerlo, instalarlo
                    if [ $l_status_stop -ne 2 ]; then

                        printf 'Instalando el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s ...\n' "$p_artifact_index" "$p_repo_id"
                        #Instalando
                        if [ $g_is_root -eq 0 ]; then

                            echo "Copiando \"${l_path_temp}/bypass4netns\" a \"${l_path_bin}\" ..."
                            cp "${l_path_temp}/bypass4netns" "${l_path_bin}"
                            chmod +x "${l_path_bin}/bypass4netns"

                            echo "Copiando \"${l_path_temp}/bypass4netnsd\" a \"${l_path_bin}\" ..."
                            cp "${l_path_temp}/bypass4netnsd" "${l_path_bin}"
                            chmod +x "${l_path_bin}/bypass4netnsd"

                        else

                            echo "Copiando \"${l_path_temp}/bypass4netns\" a \"${l_path_bin}\" ..."
                            sudo cp "${l_path_temp}/bypass4netns" "${l_path_bin}"
                            sudo chmod +x "${l_path_bin}/bypass4netns"

                            echo "Copiando \"${l_path_temp}/bypass4netnsd\" a \"${l_path_bin}\" ..."
                            sudo cp "${l_path_temp}/bypass4netnsd" "${l_path_bin}"
                            sudo chmod +x "${l_path_bin}/bypass4netnsd"

                        fi

                    else

                        printf 'No se instalará el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s.\n' "$p_artifact_index" "$p_repo_id"

                    fi

                fi

                #3.3. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo

            fi

            ;;


        dive)

            #Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"${l_path_temp}/dive\" a \"${l_path_bin}\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp "${l_path_temp}/dive" "${l_path_bin}"
                chmod +x "${l_path_bin}/dive"
            else
                sudo cp "${l_path_temp}/dive" "${l_path_bin}"
                sudo chmod +x "${l_path_bin}/dive"
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


#Funciones modificables (Nive 2) {{{


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
    l_aux=$(url_encode "$l_repo_last_version")
    pna_repo_versions=("$l_aux" "$l_repo_last_version_pretty")
    pna_arti_versions=(${l_arti_versions})
    return 0
}



function _get_last_repo_url() {

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




#}}}








