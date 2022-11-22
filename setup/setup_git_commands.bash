#!/bin/bash

#Si el SO es de la familia debian (por ejemplo Ubuntu), use 0
g_is_debian_os=0

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi

#variable global pero solo se usar localmente en las funciones
t_tmp=""

function m_get_artifact_name() {

    #1. Argumentos
    local l_artifact_prefix="$1"
    local l_last_version="$2"
    
    #2. Generar el nombre
    local l_artifact_name=""
    local l_artifact_type=99     #0 si es binario, 1 si es package, 2 si es un tar.gz, 3 si es un zip

    case "$l_artifact_prefix" in
        jq)
            l_artifact_name="jq-linux64"
            l_artifact_type=0
            ;;
        yq)
            l_artifact_name="yq_linux_amd64.tar.gz"
            l_artifact_type=2
            ;;
        fzf)
            l_artifact_name="fzf-${l_last_version}-linux_amd64.tar.gz"
            l_artifact_type=2
            ;;
        delta)
            if [ $g_is_debian_os -eq 0 ]; then
                l_artifact_name="git-delta_${l_last_version}_amd64.deb"
                l_artifact_type=1
            else
                l_artifact_name="delta-${l_last_version}-x86_64-unknown-linux-gnu.tar.gz"
                l_artifact_type=2
            fi
            ;;
        ripgrep)
            if [ $g_is_debian_os -eq 0 ]; then
                l_artifact_name="ripgrep_${l_last_version}_amd64.deb"
                l_artifact_type=1
            else
                l_artifact_name="ripgrep-${l_last_version}-x86_64-unknown-linux-musl.tar.gz"
                l_artifact_type=2
            fi
            ;;
        bat)
            if [ $g_is_debian_os -eq 0 ]; then
                l_artifact_name="bat_${l_last_version#*v}_amd64.deb"
                l_artifact_type=1
            else
                l_artifact_name="bat-${l_last_version}-x86_64-unknown-linux-gnu.tar.gz"
                l_artifact_type=2
            fi
            ;;
    esac

    echo "$l_artifact_name"
    return $l_artifact_type

}


function m_download_git_artifact() {

    #1. Argumentos
    local l_repo_base="$1"
    local l_artifact_prefix="$2"
    local l_artifact_name="$3"
    local l_last_version="$4"

    #2. Descargar el artifacto en la carpeta
    l_repo_releases_url="https://github.com/${l_repo_base}/releases/download/${l_last_version}"
    mkdir -p "/tmp/${l_artifact_prefix}"
    echo "Iniciando la descarga del artefacto \"${l_repo_releases_url}/${l_artifact_name}\" ..."
    curl -fLo "/tmp/${l_artifact_prefix}/${l_artifact_name}" "${l_repo_releases_url}/${l_artifact_name}"
    local l_status=$?
    if [ $l_status -eq 0 ]; then
        echo "Se descargo el artefacto \"${l_repo_releases_url}/${l_artifact_name}\" en: \"/tmp/${l_artifact_prefix}/${l_artifact_name}\""
    fi     
    return $l_status
}

 
function m_copy_artifact_files() {

    #1. Argumentos
    local l_artifact_prefix="$1"
    local l_subfolder="$2"
    
    #2. Copiar loa archivos del artefacto segun el prefijo 
    case "$l_artifact_prefix" in
        bat)
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"bat\" a \"/usr/local/bin/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/${l_subfolder}/bat /usr/local/bin/
                chmod +x /usr/local/bin/bat
                mkdir -pm 755 /usr/local/man/man1
            else
                sudo cp /tmp/${l_artifact_prefix}/${l_subfolder}/bbat /usr/local/bin/
                sudo chmod +x /usr/local/bin/bat
                sudo mkdir -pm 755 /usr/local/man/man1
            fi
            
            #Copiar los archivos de ayuda man para comando
            echo "Copiando \"bat.1\" a \"/usr/local/man/man1/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/${l_subfolder}/bat.1 /usr/local/man/man1/
            else
                sudo cp /tmp/${l_artifact_prefix}/${l_subfolder}/bat.1 /usr/local/man/man1/
            fi

            #Copiar los script de completado
            echo "Copiando \"autocomplete/bat.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            cp /tmp/${l_artifact_prefix}/${l_subfolder}/autocomplete/bat.bash ~/.files/terminal/linux/complete/bat.bash
            echo "Copiando \"autocomplete/_bat.ps1\" a \"~/.files/terminal/windows/complete/\" ..."
            cp /tmp/${l_artifact_prefix}/${l_subfolder}/autocomplete/_bat.ps1 ~/.files/terminal/windows/complete/bat.ps1
            ;;

        ripgrep)
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"rg\" a \"/usr/local/bin/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/${l_subfolder}/rg /usr/local/bin/
                chmod +x /usr/local/bin/rg
                mkdir -pm 755 /usr/local/man/man1
            else
                sudo cp /tmp/${l_artifact_prefix}/${l_subfolder}/rg /usr/local/bin/
                sudo chmod +x /usr/local/bin/rg
                sudo mkdir -pm 755 /usr/local/man/man1
            fi
            
            #Copiar los archivos de ayuda man para comando
            echo "Copiando \"doc/rg.1\" a \"/usr/local/man/man1/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/${l_subfolder}/doc/rg.1 /usr/local/man/man1/
            else
                sudo cp /tmp/${l_artifact_prefix}/${l_subfolder}/doc/rg.1 /usr/local/man/man1/
            fi

            #Copiar los script de completado
            echo "Copiando \"complete/rg.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            cp /tmp/${l_artifact_prefix}/${l_subfolder}/complete/rg.bash ~/.files/terminal/linux/complete/rg.bash
            echo "Copiando \"autocomplete/_rg.ps1\" a \"~/.files/terminal/windows/complete/\" ..."
            cp /tmp/${l_artifact_prefix}/${l_subfolder}/complete/_rg.ps1 ~/.files/terminal/windows/complete/rg.ps1
            ;;

        delta)
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"delta\" a \"/usr/local/bin/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/${l_subfolder}/delta /usr/local/bin/
                chmod +x /usr/local/bin/delta
                mkdir -pm 755 /usr/local/man/man1
            else
                sudo cp /tmp/${l_artifact_prefix}/${l_subfolder}/delta /usr/local/bin/
                sudo chmod +x /usr/local/bin/delta
                sudo mkdir -pm 755 /usr/local/man/man1
            fi
            
            #Copiar los archivos de ayuda man para comando
            #echo "Copiando \"delta.1\" a \"/usr/local/man/man1/\" ..."
            #if [ $g_is_root -eq 0 ]; then
            #    cp /tmp/${l_artifact_prefix}/${l_subfolder}/delta.1 /usr/local/man/man1/
            #else
            #    sudo cp /tmp/${l_artifact_prefix}/${l_subfolder}/delta.1 /usr/local/man/man1/
            #fi

            #Copiar los script de completado
            #echo "Copiando \"autocomplete/delta.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #cp /tmp/${l_artifact_prefix}/${l_subfolder}/autocomplete/delta.bash ~/.files/terminal/linux/complete/delta.bash
            #echo "Copiando \"autocomplete/_delta.ps1\" a \"~/.files/terminal/windows/complete/\" ..."
            #cp /tmp/${l_artifact_prefix}/${l_subfolder}/autocomplete/_delta.ps1 ~/.files/terminal/windows/complete/delta.ps1
            ;;

        fzf)
            #Copiar el comando fzf y dar permiso de ejecucion a todos los usuarios
            echo "Copiando \"fzf\" a \"/usr/local/bin/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/fzf /usr/local/bin/
                chmod +x /usr/local/bin/fzf
                mkdir -pm 755 /usr/local/man/man1
            else
                sudo cp /tmp/${l_artifact_prefix}/fzf /usr/local/bin/
                sudo chmod +x /usr/local/bin/fzf
                sudo mkdir -pm 755 /usr/local/man/man1
            fi
            
            #Descargar archivos necesarios
            echo "Descargando \"https://github.com/junegunn/fzf.git\" en el folder \"git/\" ..."
            git clone --depth 1 https://github.com/junegunn/fzf.git "/tmp/${l_artifact_prefix}/git"

            #Copiar los archivos de ayuda man para comando fzf y el script fzf-tmux
            echo "Copiando \"git/man/man1/fzf.1\" y \"git/man/man1/fzf-tmux.1\" a \"/usr/local/man/man1/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/git/man/man1/fzf.1 /usr/local/man/man1/
                cp /tmp/${l_artifact_prefix}/git/man/man1/fzf-tmux.1 /usr/local/man/man1/
            else
                sudo cp /tmp/${l_artifact_prefix}/git/man/man1/fzf.1 /usr/local/man/man1/
                sudo cp /tmp/${l_artifact_prefix}/git/man/man1/fzf-tmux.1 /usr/local/man/man1/
            fi

            #Copiar los archivos requeridos por el plugin vim base "fzf"
            mkdir -p ~/.files/vim_packages/fzf/doc
            mkdir -p ~/.files/vim_packages/fzf/plugin
            echo "Copiando \"git/doc/fzf.txt\" a \"~/.files/vim_packages/fzf/doc/\" ..."
            #echo "Copiando \"git/doc/fzf.txt\" y \"git/doc/tags\" a \"~/.files/vim_packages/fzf/doc/\" ..."
            cp /tmp/${l_artifact_prefix}/git/doc/fzf.txt ~/.files/vim_packages/fzf/doc/
            #cp /tmp/${l_artifact_prefix}/git/doc/tags ~/.files/vim_packages/fzf/doc/
            echo "Copiando \"git/doc/fzf.vim\" a \"~/.files/vim_packages/fzf/plugin/\" ..."
            cp /tmp/${l_artifact_prefix}/git/plugin/fzf.vim ~/.files/vim_packages/fzf/plugin/

            #Copiar los archivos opcionales del plugin
            echo "Copiando \"git/LICENSE\" en \"~/.files/vim_packages/fzf/\" .."
            cp /tmp/${l_artifact_prefix}/git/LICENSE ~/.files/vim_packages/fzf/LICENSE
            
            #Copiar los script de completado
            echo "Copiando \"git/shell/completion.bash\" como \"~/.files/terminal/linux/complete/fzf.bash\" ..."
            cp /tmp/${l_artifact_prefix}/git/shell/completion.bash ~/.files/terminal/linux/complete/fzf.bash
            
            #Copiar los script de keybindings
            echo "Copiando \"git/shell/key-bindings.bash\" como \"~/.files/terminal/linux/keybindings/fzf.bash\" ..."
            cp /tmp/${l_artifact_prefix}/git/shell/key-bindings.bash ~/.files/terminal/linux/keybindings/fzf.bash
            
            # Script que se usara como comando para abrir fzf en un panel popup tmux
            echo "Copiando \"git/bin/fzf-tmux\" como \"~/.files/terminal/linux/functions/fzf-tmux.bash\" y crear un enlace como comando \"~/.local/bin/fzf-tmux\"..."
            cp /tmp/${l_artifact_prefix}/git/bin/fzf-tmux ~/.files/terminal/linux/functions/fzf-tmux.bash
            ln -sfn ~/.files/terminal/linux/functions/fzf-tmux.bash ~/.local/bin/fzf-tmux
            ;;

        jq)
            #Renombrar el binario antes de copiarlo
            echo "Copiando \"jq-linux64\" como \"/usr/local/bin/jq\" ..."
            mv /tmp/${l_artifact_prefix}/jq-linux64 /tmp/${l_artifact_prefix}/jq
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/jq /usr/local/bin/
                chmod +x /usr/local/bin/jq
                #mkdir -pm 755 /usr/local/man/man1
            else
                sudo cp /tmp/${l_artifact_prefix}/jq /usr/local/bin/
                sudo chmod +x /usr/local/bin/jq
                #sudo mkdir -pm 755 /usr/local/man/man1
            fi
            
            #Copiar los archivos de ayuda man para comando
            #echo "Copiando \"jq.1\" a \"/usr/local/man/man1/\" ..."
            #if [ $g_is_root -eq 0 ]; then
            #    cp /tmp/${l_artifact_prefix}/jq.1 /usr/local/man/man1/
            #else
            #    sudo cp /tmp/${l_artifact_prefix}/jq.1 /usr/local/man/man1/
            #fi

            #Copiar los script de completado
            #echo "Copiando \"autocomplete/jq.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #cp /tmp/${l_artifact_prefix}/autocomplete/jq.bash ~/.files/terminal/linux/complete/jq.bash
            #echo "Copiando \"autocomplete/_jq.ps1\" a \"~/.files/terminal/windows/complete/\" ..."
            #cp /tmp/${l_artifact_prefix}/autocomplete/jq.ps1 ~/.files/terminal/windows/complete/jq.ps1
            ;;

        yq)
            #Renombrar el binario antes de copiarlo
            echo "Copiando \"yq_linux_amd64\" como \"/usr/local/bin/yq\" ..."
            mv /tmp/${l_artifact_prefix}/yq_linux_amd64 /tmp/${l_artifact_prefix}/yq
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/yq /usr/local/bin/
                chmod +x /usr/local/bin/yq
                mkdir -pm 755 /usr/local/man/man1
            else
                sudo cp /tmp/${l_artifact_prefix}/yq /usr/local/bin/
                sudo chmod +x /usr/local/bin/yq
                sudo mkdir -pm 755 /usr/local/man/man1
            fi
            
            #Copiar los archivos de ayuda man para comando
            echo "Copiando \"yq.1\" a \"/usr/local/man/man1/\" ..."
            if [ $g_is_root -eq 0 ]; then
                cp /tmp/${l_artifact_prefix}/yq.1 /usr/local/man/man1/
            else
                sudo cp /tmp/${l_artifact_prefix}/yq.1 /usr/local/man/man1/
            fi

            #Copiar los script de completado
            #echo "Copiando \"autocomplete/yq.bash\" a \"~/.files/terminal/linux/complete/\" ..."
            #cp /tmp/${l_artifact_prefix}/autocomplete/yq.bash ~/.files/terminal/linux/complete/yq.bash
            #echo "Copiando \"autocomplete/_yq.ps1\" a \"~/.files/terminal/windows/complete/\" ..."
            #cp /tmp/${l_artifact_prefix}/autocomplete/yq.ps1 ~/.files/terminal/windows/complete/yq.ps1
            ;;

       *)
           echo "ERROR (20): Para el prefijo del artefacto \"${l_artifact_prefix}\" no se define una logica de instalación por copiado de archivos"
           return 20
            
    esac

    return 0

}

function m_install_artifact() {
    
    #1. Argumentos
    local l_artifact_prefix="$1"
    local l_artifact_name="$2"
    local l_artifact_type="$3"

    #2. Procesar
    if [ $l_artifact_type -eq 2 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        echo "Descromprimiendo \"${l_artifact_prefix}/${l_artifact_name}\" en \"/tmp/${l_artifact_prefix}\" ..."
        tar -xvf "/tmp/${l_artifact_prefix}/${l_artifact_name}" -C /tmp/${l_artifact_prefix}
        
        #Copiar los archivos necesarios
        m_copy_artifact_files "${l_artifact_prefix}" "${l_artifact_name%.tar.gz}"

    elif [ $l_artifact_type -eq 0 ]; then

        #Copiar los archivos necesarios
        m_copy_artifact_files "${l_artifact_prefix}"

    elif [ $l_artifact_type -eq 1 ]; then

        if [ $g_is_debian_os -nq 0 ]; then
            echo "ERROR (22): No esta permitido instalar el paquete \"${l_artifact_name}\" en SO que no sean de la familia debian"
            return 22
        fi
        
        #Instalar y/o actualizar el paquete si ya existe
        echo "Instalando/Actualizando el paquete \"/tmp/${l_artifact_prefix}/${l_artifact_name}\"" 
        if [ $g_is_root -eq 0 ]; then
            dpkg -i "/tmp/${l_artifact_prefix}/${l_artifact_name}" 
        else
            sudo dpkg -i "/tmp/${l_artifact_prefix}/${l_artifact_name}" 
        fi

    else
        echo "ERROR (21): El tipo de artefacto \"${l_artifact_prefix}\" no esta habilitado para ser procesado"
        return 21
    fi

}
 
function m_setup_git_artifact() {

    #1. Argumentos
    local l_repo_base="$1"
    local l_artifact_prefix="$2"

    if [ -z "$l_repo_base" ]; then
        echo "ERROR (98): El argumento 1 (repository base) es obligatorio"
        return 98
    else
        echo "Nombre base del repositorio GitHub    : \"${l_repo_base}\""
    fi

    if [ -z "$l_artifact_prefix" ]; then
        echo "ERROR (98): El argumento 2 (artifact prefix) es obligatorio"
        return 98
    else
        echo "Artefacto a descargar - Prefijo       : \"${l_artifact_prefix}\""
    fi
    
    #2. Obtener la ultima version del los artifactos del proyecto github
    local aux=$(curl -Ls -H 'Accept: application/json' "https://github.com/${l_repo_base}/releases/latest")
    local l_last_version=""
    #Si no esta instalado 'jq' usar expresiones regulares
    if ! command -v jq &> /dev/null; then
        l_last_version=$(echo $aux | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
    else
        l_last_version=$(echo $aux | jq -r .tag_name)
    fi
    echo "Artefacto a descargar - Ultima Versión: \"${l_last_version}\""

    #3. Obtener el nombre del artefacto
    t_tmp=$(m_get_artifact_name "$l_artifact_prefix" "$l_last_version")
    local l_artifact_type=$?   #'$(..)' no es un comando, pero local es un comando, por eso se usa la variable global 't_tmp'
    local l_artifact_name="$t_tmp"

    if [ -z "$l_artifact_name" ]; then
        echo "ERROR (20): No esta configurado el nombre del artefacto para el prefijo \"${l_artifact_prefix}\""
        return 20
    fi
    
    echo "Artefacto a descargar - Nombre        : \"${l_artifact_name}\""
    echo "Artefacto a descargar - Tipo          : \"${l_artifact_type}\""


    #3. Descargar el artifacto en la carpeta
    m_download_git_artifact "$l_repo_base" "$l_artifact_prefix" "$l_artifact_name" "$l_last_version"
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        echo "ERROR (${l_status}): No se ha podido descargar el artefacto \"${l_artifact_name}\""
        return $l_status
    fi

    #4. Instalar segun el tipo de artefecto
    m_install_artifact "$l_artifact_prefix" "$l_artifact_name" "$l_artifact_type"
    l_status=$?
    if [ $l_status -ne 0 ]; then
        echo "ERROR (${l_status}): No se ha podido instalar el artefacto \"${l_artifact_name}\""
    fi

    #5. Eliminar los archivos de trabajo temporales
    echo "Eliminado archivos temporales \"/tmp/${l_artifact_prefix}\" ..."
    rm -rf "/tmp/${l_artifact_prefix}"
    return $l_status

}

function setup_git_commands() {
    
    #1. Solicitar credenciales de administrador y almacenarlas temporalmente
    if [ $g_is_root -ne 0 ]; then

        #echo "Se requiere alamcenar temporalmente su password"
        sudo -v

        if [ $? -ne 0 ]; then
            echo "ERROR(20): Se requiere \"sudo -v\" almacene temporalmente su credenciales de root"
            return 20;
        fi
    fi

    echo "-------------------------------------------------------------------------------------------------"
    echo "                                  Bat (Better Cat)"
    echo "-------------------------------------------------------------------------------------------------"
    local l_repo_base='sharkdp/bat'
    local l_artifact_prefix='bat'
    m_setup_git_artifact "${l_repo_base}" "${l_artifact_prefix}"
    printf "\n\n"

    echo "-------------------------------------------------------------------------------------------------"
    echo "                                    Rg (RIP grep)"
    echo "-------------------------------------------------------------------------------------------------"
    l_repo_base='BurntSushi/ripgrep'
    l_artifact_prefix='ripgrep'
    m_setup_git_artifact "${l_repo_base}" "${l_artifact_prefix}"
    printf "\n\n"

    echo "-------------------------------------------------------------------------------------------------"
    echo "                            Delta (Syntax highlighter for git)"
    echo "-------------------------------------------------------------------------------------------------"
    l_repo_base='dandavison/delta'
    l_artifact_prefix='delta'
    m_setup_git_artifact "${l_repo_base}" "${l_artifact_prefix}"
    printf "\n\n"

    echo "-------------------------------------------------------------------------------------------------"
    echo "                                  FZF (FuZzy Finder)"
    echo "-------------------------------------------------------------------------------------------------"
    l_repo_base='junegunn/fzf'
    l_artifact_prefix='fzf'
    #m_setup_git_artifact "${l_repo_base}" "${l_artifact_prefix}"
    printf "\n\n"

    echo "-------------------------------------------------------------------------------------------------"
    echo "                                   jq (Parser JSON)"
    echo "-------------------------------------------------------------------------------------------------"
    l_repo_base='stedolan/jq'
    l_artifact_prefix='jq'
    m_setup_git_artifact "${l_repo_base}" "${l_artifact_prefix}"
    printf "\n\n"
    
    echo "-------------------------------------------------------------------------------------------------"
    echo "                                  yq (Parser YAML)"
    echo "-------------------------------------------------------------------------------------------------"
    l_repo_base='mikefarah/yq'
    l_artifact_prefix='yq'
    #m_setup_git_artifact "${l_repo_base}" "${l_artifact_prefix}"
    printf "\n\n"

    #Incluir oh-my-posh y sus temas
    #Incluir fd
    #Incluir less.exe (lesskey.exe) en Windows


    #2. Caducar las credecinales de root almacenadas temporalmente
    echo "Caducando el cache de temporal password de su 'sudo'"
    sudo -k

}


#export -f setup_git_commands


