#!/bin/bash

#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/setup/basic_functions.bash

#Variable global pero solo se usar localmente en las funciones
t_tmp=""

#Determinar la clase del SO
m_get_os_type
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
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

#Variable global ruta de los binarios en Windows segun WSL2
declare -r g_path_win_commands='/mnt/d/Tools/Cmds/Common'

#}}}

#Funciones especificas {{{

#Solo se invoca cuando se instala con exito un repositorio y sus artefactos
function m_show_final_message() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_install_win_cmds=1       #Solo si es WSL2 y desea actualizar los comandos en Windows
    if [ "$2" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    case "$p_repo_id" in
        fzf)

            if [ $p_install_win_cmds -eq 0 ]; then
                echo "En Windows, debe homologar los plugins de \"FZF\" de VIM y NeoVim para tener soporte a powershell:"
                echo "   1. Homologar el plugin \"FZF base\" tanto en VIM como NeoVim:"
                echo '      Ultimo vs Fixed  > vim -d ${env:USERPROFILE}\.files\vim_packages\fzf\plugin\fzf.vim ${env:USERPROFILE}\.files\vim_packages\fixes\fzf\plugin\fzf.vim'
                echo '      Validar Soft-Link> dir ${env:USERPROFILE}\vimfiles\pack\ui\opt\'
                echo '                       > MKLINK /D %USERPROFILE%\vimfiles\pack\ui\opt\fzf %USERPROFILE%\.files\vim_packages\fzf'
                echo '      Validar Soft-Link> dir ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\'
                echo '                       > MKLINK /D %LOCALAPPDATA%\nvim-data\site\pack\ui\opt\fzf %USERPROFILE%\.files\vim_packages\fzf'
                echo "   2. Homologar el plugin \"FZF vim\" para VIM:"
                echo '      Obtener ultimo   > . ${env:USERPROFILE}\.files\setup\update_vim_packages.ps1'
                echo '                       > cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\'
                echo '                       > git restore autoload/fzf/vim.vim'
                echo '      Ultimo ->  Fixed > vim -d ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\.files\vim_packages\fixes\fzf.vim\autoload\fzf\vim.vim'
                echo '      Fixed  ->  Vim   > cp ${env:USERPROFILE}\.files\vim_packages\fixes\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim'
                echo '      Fixed  ->  NeoVim> cp ${env:USERPROFILE}\.files\vim_packages\fixes\fzf.vim\autoload\fzf\vim.vim ${env:LOCALAPPDATA}\nvim-data\site\pack\packer\opt\fzf.vim\autoload\fzf\vim.vim' 
            fi
            ;;
        *)
            ;;
    esac
    
    echo "Los artefactos del repositorio \"${p_repo_id}\" fueron instalado sin problemas"

}

#Determinar la version actual del repositorio usado para instalar los comandos instalados:
#  0 - Si existe y se obtiene un valor
#  1 - El comando no existe o existe un error en el comando para obtener la versión
#  2 - La version obtenida no tiene formato valido
#  9 - No esta implementado un metodo de obtener la version
function m_get_repo_current_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_install_win_cmds=1       #Solo si es WSL2 y desea actualizar los comandos en Windows
    if [ "$2" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    #2. Obtener la version actual
    local l_repo_current_version=""
    local l_tmp=""
    local l_status=0

    #El resultado sera la 1ra subcadena que inicie con enteros 0-9 y continue con . y luego continue con
    #cualquier caracter que solo sea 0-9 o un .
    local l_sustitution_regexp='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
    case "$p_repo_id" in
        jq)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/jq.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(jq --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        yq)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/yq.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(yq --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        fzf)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/fzf.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(fzf --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        delta)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/delta.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(delta --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                #l_tmp=$(echo "$l_tmp" | tr '\n' '' | cut -d ' ' -f 2)
                l_tmp=$(echo "$l_tmp" | cut -d ' ' -f 2 | head -n 1)
            fi
            ;;
        ripgrep)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/rg.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(rg --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;
        bat)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/bat.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(bat --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        oh-my-posh)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/oh-my-posh.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(oh-my-posh --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        fd)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/fd.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(fd --version 2> /dev/null)
                l_status=$?
            fi
            ;;
        less)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/less.exe --version 2> /dev/null)
                l_status=$?
            else
                return 9;
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                l_sustitution_regexp='s/[^0-9]*\([0-9.]\+\).*/\1/'
            fi
            ;;
        kubectl)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/kubectl.exe version --client=true -o json 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(kubectl version --client=true -o json 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | jq -r '.clientVersion.gitVersion' 2> /dev/null)
                if [ $? -ne 0 ]; then
                    return 9;
                fi
            fi
            ;;
        k0s)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${g_path_win_commands}/bin/k0s.exe version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(k0s version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | cut -d ' ' -f 2 | head -n 1)
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
#    0 si es binario, 1 si es package, 2 si es un tar.gz, 3 si es un zip
#    99 si no se define el artefacto para el prefijo
#  - Argumento 3, un arreglo de nombre de los artectos a descargar
#En el argumento 2 se debe pasar la version pura quitando, sin contener "v" u otras letras iniciales
function m_get_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_last_version="$2"
    declare -n pna_artifact_names=$3   #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_artifact_types=$4   #Parametro por referencia: Se devuelve un arreglo de los tipos de los artefactos
    local p_install_win_cmds=1           #Solo si es WSL2 y desea actualizar los comandos en Windows
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
        delta)
            if [ $p_install_win_cmds -ne 0 ]; then
                if [ $g_os_subtype -eq 1 ]; then
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
                if [ $g_os_subtype -eq 1 ]; then
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
                if [ $g_os_subtype -eq 1 ]; then
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
                if [ $g_os_subtype -eq 1 ]; then
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
    
    #2. Obtener la version
    local l_repo_last_version=""
    local l_aux=""
    case "$p_repo_id" in

        kubectl)
            #El artefacto se obtiene del repositorio de Kubernates
            l_repo_last_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
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
    local p_install_win_cmds=1       #Solo si es WSL2 y desea actualizar los comandos en Windows
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
    local p_subfolder="$3"
    local p_exe_name_without_ext="$4"
    local p_install_win_cmds=1       #Solo si es WSL2 y desea actualizar los comandos en Windows
    if [ "$5" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    #3. Copiar loa archivos del artefacto segun el prefijo
    local l_path_bin=""
    local l_path_man=""
    if [ $p_install_win_cmds -ne 0 ]; then
        l_path_bin='/usr/local/bin'
        l_path_man='/usr/local/man/man1'
    else
        l_path_bin="${g_path_win_commands}/bin"
        l_path_man="${g_path_win_commands}/man"
    fi
    local l_path_temp=""

    case "$p_repo_id" in

        bat)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_subfolder}"

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
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_subfolder}"
            
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
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_subfolder}"
            
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
                l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_subfolder}"
                
                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                echo "Copiando \"less\" a \"${l_path_bin}\" ..."
                if [ $p_artifact_id -eq 0 ]; then
                    cp "${l_path_temp}/less.exe" "${l_path_bin}"
                else
                    cp "${l_path_temp}/lesskey.exe" "${l_path_bin}"
                fi

            else
                echo "ERROR (40): El artefacto[${p_artifact_id}] del repositorio \"${p_repo_id}\" solo esta habilitado para Windows"
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
                mkdir -p ~/.files/vim_packages/fzf/doc
                mkdir -p ~/.files/vim_packages/fzf/plugin
                echo "Copiando \"git/doc/fzf.txt\" a \"~/.files/vim_packages/fzf/doc/\" ..."
                cp "${l_path_temp}/git/doc/fzf.txt" ~/.files/vim_packages/fzf/doc/
                echo "Copiando \"git/doc/fzf.vim\" a \"~/.files/vim_packages/fzf/plugin/\" ..."
                cp "${l_path_temp}/git/plugin/fzf.vim" ~/.files/vim_packages/fzf/plugin/

                #Copiar los archivos opcionales del plugin
                echo "Copiando \"git/LICENSE\" en \"~/.files/vim_packages/fzf/\" .."
                cp "${l_path_temp}/git/LICENSE" ~/.files/vim_packages/fzf/LICENSE
            
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
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}/${p_subfolder}"

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

        k0s)
            #Ruta local de los artefactos
            l_path_temp="/tmp/${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then

                echo "Copiando \"${p_exe_name_without_ext}\" como \"${l_path_bin}/k0s\" ..."
                mv "${l_path_temp}/${p_exe_name_without_ext}" "${l_path_temp}/k0s"

                if [ $g_is_root -eq 0 ]; then
                    cp "${l_path_temp}/k0s" "${l_path_bin}"
                    chmod +x "${l_path_bin}/k0s"
                else
                    sudo cp "${l_path_temp}/k0s" "${l_path_bin}"
                    sudo chmod +x "${l_path_bin}/k0s"
                    #sudo mkdir -pm 755 "${l_path_man}"
                fi
            else
                echo "Copiando \"${p_exe_name_without_ext}.exe\" como \"${l_path_bin}/k0s.exe\" ..."
                mv "${l_path_temp}/${p_exe_name_without_ext}.exe" "${l_path_temp}/k0s.exe"
                cp "${l_path_temp}/k0s.exe" "${l_path_bin}"
            fi
            ;;

       *)
           echo "ERROR (40): El artefacto[${p_artifact_id}] del repositorio \"${p_repo_id}\" no implementa logica de copiado de archivos"
           return 40
            
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

    for ((l_i=0; l_i < $l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_artifact_url=$(m_get_artifact_url "$p_repo_id" "$p_repo_name" "$p_repo_last_version" "$l_artifact_name" $p_install_win_cmds)
        echo "Artefecto[${l_i}] a descargar - Name    : ${l_artifact_name}"
        echo "Artefecto[${l_i}] a descargar - URL     : ${l_artifact_url}"
        
        #Descargar la artefacto
        mkdir -p "/tmp/${p_repo_id}/${l_i}"
        curl -fLo "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" "$l_artifact_url"
        l_status=$?
        if [ $l_status -eq 0 ]; then
            echo "Artefacto[${l_i}] descargado en         : \"/tmp/${p_repo_id}/${l_i}/${l_artifact_name}\""
        else
            echo "ERROR (${l_status}): Error en descargar el artefacto[${l_i}]"
            return $l_status
        fi

    done

    return 0
}

function m_setup_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    declare -nr pnra_artifact_names=$3   #Parametro por referencia: Arreglo de los nombres de los artefactos
    declare -nr pnra_artifact_types=$4   #Parametro por referencia: Arreglo de los tipos de los artefactos
    local p_install_win_cmds=1            #Solo si es WSL2 y desea actualizar los comandos en Windows
    if [ "$5" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    #2. Descargar los artectos del repositorio
    local l_n=${#pnra_artifact_names[@]}

    local l_artifact_name
    local l_artifact_type
    local l_i=0

    mkdir -p "/tmp/${p_repo_id}"

    for ((l_i=0; l_i < $l_n; l_i++)); do

        l_artifact_name="${pnra_artifact_names[$l_i]}"
        l_artifact_type="${pnra_artifact_types[$l_i]}"
        echo "Artefecto[${l_i}] a configurar - Name   : ${l_artifact_name}"
        echo "Artefecto[${l_i}] a configurar - Type   : ${l_artifact_type}"

        if [ $l_artifact_type -eq 2 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            echo "Descomprimiendo el artefacto[${l_i}] \"${l_artifact_name}\" en \"/tmp/${p_repo_id}/${l_i}\" ..."
            tar -xvf "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -C "/tmp/${p_repo_id}/${l_i}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            m_copy_artifact_files "$p_repo_id" "$l_i" "${l_artifact_name%.tar.gz}" "" $p_install_win_cmds


        elif [ $l_artifact_type -eq 3 ]; then

            #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
            echo "Descomprimiendo el artefacto[${l_i}] \"${l_artifact_name}\" en \"/tmp/${p_repo_id}/${l_i}\" ..."
            unzip "/tmp/${p_repo_id}/${l_i}/${l_artifact_name}" -d "/tmp/${p_repo_id}/${l_i}"
            chmod u+rw /tmp/${p_repo_id}/${l_i}/*

            #Copiar los archivos necesarios
            m_copy_artifact_files "$p_repo_id" "$l_i" "${l_artifact_name%.zip}" ""  $p_install_win_cmds

        elif [ $l_artifact_type -eq 0 ]; then

            #Copiar los archivos necesarios
            if [ $p_install_win_cmds -eq 0 ]; then
                m_copy_artifact_files "$p_repo_id" "$l_i" "" "${l_artifact_name%.exe}" $p_install_win_cmds
            else
                m_copy_artifact_files "$p_repo_id" "$l_i" "" "$l_artifact_name" $p_install_win_cmds
            fi

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

        else
            echo "ERROR (21): Configure la logica del tipo de artefacto \"${l_artifact_type}\" para que puede ser configurado"
            return 21
        fi

    done

    return 0
}

function m_setup_repository() { 

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_install_win_cmds=1       #Solo si es WSL2 y desea actualizar los comandos en Windows
    if [ "$3" -eq 0 2> /dev/null ]; then
        p_install_win_cmds=0
    fi

    if [ ! -z "$p_repo_name" ]; then
        echo "Repositorio - Name           : \"${p_repo_name}\""
    fi

    if [ -z "$p_repo_id" ]; then
        echo "ERROR (98): El argumento 2 (repository id) es obligatorio"
        return 98
    else
        echo "Repositorio - ID             : \"${p_repo_id}\""
    fi
   
    #2. Obtener la ultima version del repositorio
    local l_repo_last_version=$(m_get_repo_latest_version "$p_repo_id" "$p_repo_name")
    local l_repo_last_version_pretty=$(echo "$l_repo_last_version" | sed 's/[^0-9]*\([0-9.]*\).*/\1/')
   
    if [ -z "$l_repo_last_version" ]; then
        echo "ERROR (20): La ultima version del repositorio es invalido \"${l_repo_last_version}\""
        return 20
    fi
    echo "Repositorio - Ultima Versión : \"${l_repo_last_version_pretty}\" (${l_repo_last_version})"
 
    #3. Validar si se debe instalar (ya esta instalado la ultima version)
    t_tmp=$(m_get_repo_current_version "$p_repo_id" $p_install_win_cmds) 
    local l_status=$?   #'$(..)' no es un comando, pero local es un comando, por eso se usa la variable global 't_tmp'
    local l_repo_current_version="$t_tmp"

    if [ $l_status -eq 1 ]; then
        echo "Los artefactos del repositorio \"${p_repo_id}\" no esta instalado o la logica de obtener versión es incorrecta"
        echo "Se continua con la instalación"
    elif [ $l_status -eq 9 ]; then
        echo "Los artefactos del repositorio \"${p_repo_id}\" no tiene implementado la logica obtener su versión actual"
        echo "Se continua con la instalación"
    elif [ $l_status -eq 2 ]; then
        echo "Los artefactos del repositorio \"${p_repo_id}\" estan instalado pero no tiene una versión \"${l_repo_current_version}\" valida"
        echo "Se continua con la instalación"
    else
        echo "Repositorio - Versión Actual : \"${l_repo_current_version}\""

        #Comparando las versiones
        m_compare_version "${l_repo_current_version}" "${l_repo_last_version_pretty}"
        l_status=$?
        if [ $l_status -eq 0 ]; then
            echo "WARNING (80): Los artefactos del repositorio \"${p_repo_id}\" estan actualizados (Actual \"${l_repo_current_version}\" = Ultima \"${l_repo_last_version_pretty}\")"
            echo "No se instalará este repositorio"
            return 80
        elif [ $l_status -eq 1 ]; then
            echo "WARNING (80): Los artefactos del repositorio \"${p_repo_id}\" estan actualizados (Actual \"${l_repo_current_version}\" > Ultima \"${l_repo_last_version_pretty}\")"
            echo "No se instalará este repositorio"
            return 81
        fi

        echo "Los artefactos del repositorio \"${p_repo_id}\" requieren ser actualizado (Actual \"${l_repo_current_version}\" < Ultima \"${l_repo_last_version_pretty}\")"
    fi
    

    #4. Obtener el los artefacto que se instalaran del repositorio
    declare -a la_artifact_names
    declare -a la_artifact_types
    m_get_artifacts "$p_repo_id" "$l_repo_last_version_pretty" la_artifact_names la_artifact_types $p_install_win_cmds
    l_status=$?    
    if [ $l_status -ne 0 ]; then
        echo "ERROR (22): No esta configurado los artefactos para el repositorio \"${p_repo_id}\""
        return 22
    fi

    #si el arreglo es vacio
    local l_n=${#la_artifact_names[@]}
    if [ $l_n -le 0 ]; then
        echo "ERROR (98): No esta configurado los artefactos para el repositorio \"${p_repo_id}\""
        return 98
    fi
    echo "Repositorio - Nro Artefactos : \"${l_n}\""

    #si el tamano del los arrgelos no son iguales
    if [ $l_n -ne ${#la_artifact_types[@]} ]; then
        echo "ERROR (97): No se ha definido todos los tipo de artefactos en el repositorio \"${p_repo_id}\""
        return 97
    fi    

    #5. Descargar el artifacto en la carpeta
    if ! m_download_artifacts "$p_repo_id" "$p_repo_name" "$l_repo_last_version" la_artifact_names; then
        echo "ERROR (23): No se ha podido descargar los artefactos del repositorio \"${p_repo_id}\""
        m_clean_temp "$p_repo_id"
        return 23
    fi

    #6. Instalar segun el tipo de artefecto
    if ! m_setup_artifacts "$p_repo_id" "$p_repo_name" la_artifact_names la_artifact_types $p_install_win_cmds; then
        echo "ERROR (24): No se ha podido instalar los artefecto de repositorio \"${p_repo_id}\""
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
        ['k0s']='k0sproject/k0s'
    )


#Repositorios opcionales y su flag para configuración. Usar valores 2^n (4, 8, 16, ...)
declare -A gA_optional_repositories=(
        ['k0s']=4
    )

# Argunentos:
# - Repositorios opcionales que se se instalaran (flag en binario. entero que es suma de 2^n).
# - Si es invocado desde otro script, su valor es 1 y no se solicita las credenciales sudo. Si el script se invoca directamente, es 0
function setup_commands() {
    
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
        echo "Debe obtener los archivos basicos:"
        echo "   1> git clone https://github.com/lestebanpc/dotfiles.git ~/.files"
        echo "   2> chmod u+x ~/.files/setup/01_setup_init.bash"
        echo "   3> . ~/.files/setup/01_setup_init.bash"
        echo "   4> . ~/.files/setup/02_setup_commands.bash (instala y actuliza comandos)"
        echo "   5> . ~/.files/setup/03_setup_profile.bash"
        return 0
    fi
    
    #3. Otras validaciones
    if [ $p_is_direct_calling -eq 0 ]; then

        #Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_is_root -ne 0 ]; then

            #echo "Se requiere alamcenar temporalmente su password"
            sudo -v

            if [ $? -ne 0 ]; then
                echo "ERROR(20): Se requiere \"sudo -v\" almacene temporalmente su credenciales de root"
                return 20;
            fi
        fi
    fi

    #5. Instalar los comandos de los diferentes repositorios
    local l_repo_id
    local l_repo_name_aux
    local l_repo_name

    local l_repo_is_optional=1      #(1) repositorio basico, (0) repositorio opcional
    local l_repo_must_install=1     #(1) No debe instalarse, (0) Debe instalarse
    local l_repo_option=0
    local l_option=0
    for l_repo_id in "${!gA_repositories[@]}"; do

        #Nombre a mostrar el respositorio
        l_repo_name="${gA_repositories[$l_repo_id]}"
        if [ -z "$l_repo_name" ]; then
            l_repo_name_aux="$l_repo_id"
        else
            l_repo_name_aux="$l_repo_name"
        fi

        #Identificar el tipo de repositorios y si se debe intalar
        l_repo_option=${gA_optional_repositories[$l_repo_id]}

        if [ -z "$l_repo_option" ]; then

            l_repo_is_optional=1
            l_option=$(( $p_opciones & 2 ))
            if [ $l_option -eq 2 ]; then l_repo_must_install=0; fi

        else

            l_repo_is_optional=0

            if [[ ! "$l_repo_eption" =~ ^[0-9]+$ ]]; then
                l_repo_must_install=1
            else
                if [ $l_repo_option -eq 0 ]; then
                   l_repo_must_install=1
                else
                    #Suma binarios es igual al flag, se debe instalar el repo opcional
                    l_option=$(( $p_opciones & $l_repo_option ))
                    if [ $l_repo_option -eq $l_option ]; then l_repo_must_install=0; else l_repo_must_install=1; fi
                fi 
            fi

        fi

        #Instalar los repositorios
        if [ $l_repo_must_install -eq 0 ]; then
       
            #Personalizar la logica segun el repositorio
            case "$l_repo_id" in
                less)
                    #Solo si es WSL2
                    if [ $g_os_type -eq 1 ]; then
                        echo "-------------------------------------------------------------------------------------------------"
                        if [ $l_repo_is_optional -eq 0 ]; then
                            echo "- Repositorio Git opcional \"${l_repo_name_aux}\""                            
                        else
                            echo "- Repositorio Git basico \"${l_repo_name_aux}\""
                        fi
                        echo "-------------------------------------------------------------------------------------------------"

                        echo "Iniciando la instalación de los artefactos del repositorio \"${l_repo_name_aux}\" en el Windows donde esta su WSL2"
                        m_setup_repository "$l_repo_id" "$l_repo_name" 0
                        printf "\n\n"
                    fi
                    ;;
                k0s)

                    #Solo si es Linux que no es WSL2                
                    if [ $g_os_type -ne 1 ]; then

                        #Validando si el servicio esta detenido si esta instalado                    
                        echo "-------------------------------------------------------------------------------------------------"
                        if [ $l_repo_is_optional -eq 0 ]; then
                            echo "- Repositorio Git opcional \"${l_repo_name_aux}\""
                        else
                            echo "- Repositorio Git basico \"${l_repo_name_aux}\""
                        fi
                        echo "-------------------------------------------------------------------------------------------------"

                        if k0s status 2> /dev/null 1>&2; then
                           echo "el servicio k0s esta intalado y ejecutandose, debe detener para instalarlo. NO se instalara el repo."
                       else
                            echo "Iniciando la instalación de los artefactos del repositorio \"${l_repo_name_aux}\" en Linux \"${g_os_subtype_name}\""
                            m_setup_repository "$l_repo_id" "$l_repo_name" 1
                            printf "\n\n"
                        fi
                        
                    fi
                    ;;
                *)
                    echo "-------------------------------------------------------------------------------------------------"
                    if [ $l_repo_is_optional -eq 0 ]; then
                        echo "- Repositorio Git opcional \"${l_repo_name_aux}\""
                    else
                        echo "- Repositorio Git basico \"${l_repo_name_aux}\""
                    fi
                    echo "-------------------------------------------------------------------------------------------------"
                    
                    echo "Iniciando la instalación de los artefactos del repositorio \"${l_repo_name_aux}\" en Linux \"${g_os_subtype_name}\""
                    m_setup_repository "$l_repo_id" "$l_repo_name" 1
                    printf "\n\n"

                    if [ $g_os_type -eq 1 ]; then
                        echo "Iniciando la instalación de los artefactos del repositorio \"${l_repo_name_aux}\" en el Windows donde esta su WSL2"
                        m_setup_repository "$l_repo_id" "$l_repo_name" 0
                        printf "\n\n"
                    fi
                    ;;
            esac
        
        fi
        
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
    echo " (a) Actualizar solo los binarios de los repositorios basicos"
    echo " ( ) Actualizar las opciones que desea. Ingrese la suma de las opciones que desea instalar:"
    #echo "    (  0) Actualizar xxx (siempre se realizara esta opción)"
    #echo "    (  1) Actualizar xxx"
    echo "     (  2) Actualizar binarios de los repositorios basicos"
    echo "     (  4) Actualizar binarios del    repositorio  opcionales \"k0s\""
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
    local l_opcion=""
    while [ $l_flag_continue -eq 0 ]; do

        m_show_menu_core
        read l_opcion

        case "$l_opcion" in
            a)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                setup_commands 2 0
                ;;

            q)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                ;;


            [0-1])
                l_flag_continue=0
                echo "Opción incorrecta"
                echo "-------------------------------------------------------------------------------------------------"
                ;;

            [1-9]*)
                if [[ "$l_opcion" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    echo "#################################################################################################"$'\n'
                    setup_commands $l_opcion 0
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
gp_is_direct_calling=0
if [[ "$2" =~ ^[0-9]+$ ]]; then
   gp_is_direct_calling=$2
fi

if [ $gp_is_direct_calling -eq 0 ]; then
    m_main
else
    gp_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        gp_opciones=$1
    fi
    setup_commands $gp_opciones 1
fi


