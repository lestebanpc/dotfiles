#!/bin/bash


#Codigo respuesta con exito:
#    0  - OK (si se ejecuta directamente y o en caso de no hacerlo, no requiere alamcenar las credenciales de SUDO).
#  119  - OK (en caso que NO se ejecute directamente o interactivamente y se requiera credenciales de SUDO).
#         Las credenciales de SUDO se almaceno en este script (localmente). avisar para que lo cierre el caller
#Codigo respuesta con error:
#  110  - Argumentos invalidos.
#  111  - No se cumple los requisitos para ejecutar la logica principal del script.
#  120  - Se require permisos de root y se nego almacenar las credenciales de SUDO.
#  otro - Error en el procesamiento de la logica del script



#------------------------------------------------------------------------------------------------------------------
#> Logica de inicialización {{{
#------------------------------------------------------------------------------------------------------------------
# Incluye variables globales constantes y variables globales que requieren ser calculados al iniciar el script.
#

#Variable cuyo valor esta CALCULADO por '_get_current_script_info':
#Representa la ruta base donde estan todos los script, incluyendo los script instalación:
#  > 'g_shell_path' tiene la estructura de subfolderes:
#     ./bash/
#         ./lib/
#             ./linuxsetup/
#                 ./00_setup_summary.bash
#                 ./01_setup_binaries.bash
#                 ./04_install_profile.bash
#                 ./05_update_profile.bash
#                 ./03_setup_repo_os_pkgs.bash
#                 ........................
#                 ........................
#                 ........................
#         ./lib/
#             ./mod_common.bash
#             ........................
#             ........................
#     ./sh/
#         ........................
#         ........................
#     ........................
#     ........................
#  > 'g_shell_path' usualmente es '$HOME/.file/shell'.
g_shell_path=''


#Permite obtener  'g_shell_path' es cual es la ruta donde estan solo script, incluyendo los script instalacion.
#Parametros de entrada: Ninguno
#Parametros de salida> Variables globales: 'g_shell_path'
#Parametros de salida> Valor de retorno
#  0> Script valido (el script esta en la estructura de folderes de 'g_shell_path')
#  1> Script invalido
function _get_current_script_info() {

    #Obteniendo la ruta base de todos los script bash
    local l_aux=''
    local l_script_path="${BASH_SOURCE[0]}"
    l_script_path=$(realpath "$l_script_path" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then

        printf 'Error al obtener la ruta absoluta del script "%s" actual.\n' "$l_script_path"
        return 1

    fi

    if [[ "$l_script_path" == */bash/bin/linuxsetup/* ]]; then
        g_shell_path="${l_script_path%/bash/bin/linuxsetup/*}"
    else
        printf 'El script "%s" actual debe de estar en el folder padre ".../bash/bin/linuxsetup/".\n' "$l_script_path"
        return 1
    fi


    return 0

}

_get_current_script_info
_g_status=$?
if [ $_g_status -ne 0 ]; then
    exit 111
fi



#Funciones generales, determinar el tipo del SO y si es root
# shellcheck source=/home/lucianoepc/.files/shell/bash/lib/mod_common.bash
. ${g_shell_path}/bash/lib/mod_common.bash

#Obtener informacion basica del SO
if [ -z "$g_os_type" ]; then

    #Determinar el tipo de SO compatible con interprete shell POSIX.
    #  00 > Si es Linux no-WSL
    #  01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
    #  02 > Si es Unix
    #  03 > Si es MacOS
    #  04 > Compatible en Linux en Windows: CYGWIN
    #  05 > Compatible en Linux en Windows: MINGW
    #  06 > Emulador Bash Termux para Linux Android
    #  09 > No identificado
    get_os_type
    declare -r g_os_type=$?

    #Obtener información de la distribución Linux
    # > 'g_os_subtype_id'             : Tipo de distribucion Linux
    #    > 0000000 : Distribución de Linux desconocidos
    #    > 0000001 : Alpine Linux
    #    > 10 - 29 : Familia Fedora
    #           10 : Fedora
    #           11 : CoreOS Stream
    #           12 : Red Hat Enterprise Linux
    #           19 : Amazon Linux
    #    > 30 - 49 : Familia Debian
    #           30 : Debian
    #           31 : Ubuntu
    #    > 50 - 59 : Familia Arch
    #           50 : Arch Linux
    # > 'g_os_subtype_name'           : Nombre de distribucion Linux
    # > 'g_os_subtype_version'        : Version extendida de la distribucion Linux
    # > 'g_os_subtype_version_pretty' : Version corta de la distribucion Linux
    # > 'g_os_architecture_type'      : Tipo de la arquitectura del procesador
    if [ $g_os_type -le 1 ]; then
        get_linux_type_info
    fi

fi

#Obtener informacion basica del usuario
if [ -z "$g_runner_id" ]; then

    #Determinar si es root y el soporte de sudo
    # > 'g_runner_id'                     : ID del usuario actual (UID).
    # > 'g_runner_user'                   : Nombre del usuario actual.
    # > 'g_runner_sudo_support'           : Si el so y el usuario soportan el comando 'sudo'
    #    > 0 : se soporta el comando sudo con password
    #    > 1 : se soporta el comando sudo sin password
    #    > 2 : El SO no implementa el comando sudo
    #    > 3 : El usuario no tiene permisos para ejecutar sudo
    #    > 4 : El usuario es root (no requiere sudo)
    get_runner_options
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pueden obtener la información del usuario actual de ejecución del script: Name="%s", UID="%s".\n' "$g_runner_user" "$g_runner_id"
        exit 111
    fi

fi

if [ $g_runner_id -lt 0 ] || [ -z "$g_runner_user" ]; then
    printf 'No se pueden obtener la información del usuario actual de ejecución del script: Name="%s", UID="%s".\n' "$g_runner_user" "$g_runner_id"
    exit 111
fi


#Cuando no se puede determinar la version actual (siempre se instalara)
declare -r g_version_none='0.0.0'

#Funciones de utilidad generalees para los instaladores:
# shellcheck source=/home/lucianoepc/.files/shell/bash/bin/linuxsetup/lib/common_utility.bash
. ${g_shell_path}/bash/bin/linuxsetup/lib/common_utility.bash

#Funciones de utilidad usados cuando se configura el profile:
# shellcheck source=/home/lucianoepc/.files/shell/bash/bin/linuxsetup/lib/setup_profile_utility.bash
. ${g_shell_path}/bash/bin/linuxsetup/lib/setup_profile_utility.bash


# Grupo de plugins de VIM/NeoVIM :
# (00) Grupo Basic > Themes             - Temas
# (01) Grupo Basic > Core               - StatusLine, TabLine, FZF, TMUX utilities, Files Tree
# (02) Grupo Basic > Extended           - Highlighting Sintax, Autocompletion para linea de comandos.
# (03) Grupo IDE > Utils                - Libreries, Typing utilities.
# (04) Grupo IDE > Development > Common - Plugin comunes de soporte independiente de tipo LSP usado (nativa o CoC).
# (05) Grupo IDE > Development > Native - LSP, Snippets, Compeletion  ... usando la implementacion nativa.
# (06) Grupo IDE > Development > CoC    - LSP, Snippets, Completion ... usando CoC.
# (07) Grupo IDE > Testing              - Unit Testing y Debugging.
# (08) Grupo IDE > Extended > Common    - Plugin de tools independiente del tipo de LSP usado (nativa o CoC).
# (09) Grupo IDE > Extended > Native    - Tools: Git, Rest Client, AI Completion/Chatbot, AI Agent, etc.
# (10) Grupo IDE > Extended > CoC       - Tools: Git, Rest Client, AI Completin/Chatbot, AI Agent, etc.
declare -A gA_repos_type=(
        ['morhetz/gruvbox']=0
        ['joshdick/onedark.vim']=0
        ['vim-airline/vim-airline']=1
        ['vim-airline/vim-airline-themes']=1
        ['preservim/nerdtree']=1
        ['ryanoasis/vim-devicons']=1
        ['preservim/vimux']=1
        ['christoomey/vim-tmux-navigator']=1
        ['junegunn/fzf']=1
        ['junegunn/fzf.vim']=1
        ['ibhagwan/fzf-lua']=1
        ['girishji/vimsuggest']=2
        ['tpope/vim-surround']=3
        ['mg979/vim-visual-multi']=3
        ['mattn/emmet-vim']=3
        ['dense-analysis/ale']=4
        ['liuchengxu/vista.vim']=4
        ['neoclide/coc.nvim']=6
        ['antoinemadec/coc-fzf']=6
        ['SirVer/ultisnips']=6
        ['OmniSharp/omnisharp-vim']=6
        ['honza/vim-snippets']=6
        ['puremourning/vimspector']=7
        ['folke/tokyonight.nvim']=0
        ['catppuccin/nvim']=0
        ['kyazdani42/nvim-web-devicons']=1
        ['nvim-lualine/lualine.nvim']=1
        ['akinsho/bufferline.nvim']=1
        ['nvim-tree/nvim-tree.lua']=1
        ['nvim-treesitter/nvim-treesitter']=2
        ['nvim-treesitter/nvim-treesitter-textobjects']=2
        ['hrsh7th/nvim-cmp']=2
        ['hrsh7th/cmp-buffer']=2
        ['hrsh7th/cmp-path']=2
        ['hrsh7th/cmp-cmdline']=2
        ['nvim-lua/plenary.nvim']=3
        ['nvim-treesitter/nvim-treesitter-context']=4
        ['stevearc/aerial.nvim']=4
        ['neovim/nvim-lspconfig']=5
        ['ray-x/lsp_signature.nvim']=5
        ['hrsh7th/cmp-nvim-lsp']=5
        ['L3MON4D3/LuaSnip']=5
        ['rafamadriz/friendly-snippets']=5
        ['saadparwaiz1/cmp_luasnip']=5
        ['b0o/SchemaStore.nvim']=5
        ['kosayoda/nvim-lightbulb']=5
        ['doxnit/cmp-luasnip-choice']=5
        ['mfussenegger/nvim-jdtls']=5
        ['mfussenegger/nvim-dap']=7
        ['rcarriga/nvim-dap-ui']=7
        ['theHamsta/nvim-dap-virtual-text']=7
        ['nvim-neotest/nvim-nio']=7
        ['vim-test/vim-test']=7
        ['mistweaverco/kulala.nvim']=8
        ['lewis6991/gitsigns.nvim']=8
        ['sindrets/diffview.nvim']=8
        ['zbirenbaum/copilot.lua']=9
        ['zbirenbaum/copilot-cmp']=9
        ['stevearc/dressing.nvim']=9
        ['MunifTanjim/nui.nvim']=9
        ['MeanderingProgrammer/render-markdown.nvim']=9
        ['HakonHarnes/img-clip.nvim']=9
        ['yetone/avante.nvim']=9
        ['github/copilot.vim']=10
    )

# Repositorios Git - para VIM/NeoVIM. Por defecto es 3 (para ambos)
#  1 - Para VIM
#  2 - Para NeoVIM
declare -A gA_repos_scope=(
        ['morhetz/gruvbox']=1
        ['joshdick/onedark.vim']=1
        ['vim-airline/vim-airline']=1
        ['vim-airline/vim-airline-themes']=1
        ['ryanoasis/vim-devicons']=1
        ['preservim/nerdtree']=1
        ['girishji/vimsuggest']=1
        ['liuchengxu/vista.vim']=1
        ['puremourning/vimspector']=1
        ['folke/tokyonight.nvim']=2
        ['catppuccin/nvim']=2
        ['kyazdani42/nvim-web-devicons']=2
        ['ibhagwan/fzf-lua']=2
        ['nvim-lualine/lualine.nvim']=2
        ['akinsho/bufferline.nvim']=2
        ['nvim-lua/plenary.nvim']=2
        ['nvim-tree/nvim-tree.lua']=2
        ['stevearc/aerial.nvim']=2
        ['nvim-treesitter/nvim-treesitter']=2
        ['nvim-treesitter/nvim-treesitter-textobjects']=2
        ['nvim-treesitter/nvim-treesitter-context']=2
        ['mistweaverco/kulala.nvim']=2
        ['sindrets/diffview.nvim']=2
        ['lewis6991/gitsigns.nvim']=2
        ['neovim/nvim-lspconfig']=2
        ['hrsh7th/nvim-cmp']=2
        ['hrsh7th/cmp-nvim-lsp']=2
        ['hrsh7th/cmp-buffer']=2
        ['hrsh7th/cmp-path']=2
        ['hrsh7th/cmp-cmdline']=2
        ['ray-x/lsp_signature.nvim']=2
        ['L3MON4D3/LuaSnip']=2
        ['rafamadriz/friendly-snippets']=2
        ['saadparwaiz1/cmp_luasnip']=2
        ['doxnit/cmp-luasnip-choice']=2
        ['b0o/SchemaStore.nvim']=2
        ['kosayoda/nvim-lightbulb']=2
        ['mfussenegger/nvim-dap']=2
        ['theHamsta/nvim-dap-virtual-text']=2
        ['rcarriga/nvim-dap-ui']=2
        ['nvim-neotest/nvim-nio']=2
        ['mfussenegger/nvim-jdtls']=2
        ['zbirenbaum/copilot.lua']=2
        ['zbirenbaum/copilot-cmp']=2
        ['stevearc/dressing.nvim']=2
        ['MunifTanjim/nui.nvim']=2
        ['MeanderingProgrammer/render-markdown.nvim']=2
        ['HakonHarnes/img-clip.nvim']=2
        ['yetone/avante.nvim']=2
    )


# Repositorios Git - Branch donde esta el plugin no es el por defecto
declare -A gA_repos_branch=(
        ['neoclide/coc.nvim']='release'
    )


# Repositorios Git que tiene submodulos y requieren obtener/actualizar en conjunto al modulo principal
# > Por defecto no se tiene submodulos (valor 0)
# > Valores :
#   (0) El repositorio solo tiene un modulo principal y no tiene submodulos.
#   (1) El repositorio tiene un modulo principal y submodulos de 1er nivel.
#   (2) El repositorio tiene un modulo principal y submodulos de varios niveles.
declare -A gA_repos_with_submmodules=(
        ['mistweaverco/kulala.nvim']=1
    )


# Permite definir el nombre del folder donde se guardaran los plugins segun el grupo al que pertenecen.
declare -a ga_group_plugin_folder=(
    "basic_themes"
    "basic_core"
    "basic_extended"
    "ide_utils"
    "ide_dev_common"
    "ide_dev_native"
    "ide_dev_coc"
    "ide_testing"
    "ide_ext_common"
    "ide_ext_native"
    "ide_ext_coc"
    )


#}}}



#------------------------------------------------------------------------------------------------------------------
#> Funciones usadas durante configuración del profile {{{
#------------------------------------------------------------------------------------------------------------------
#
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#




# Parametros:
#  1> Flag '0' si es NeoVIM. Por defecto es 1.
function _index_doc_of_vim_packages() {

    #1. Argumentos
    local p_is_neovim=1
    local l_tag="VIM"
    if [ "$1" = "0" ]; then
        p_is_neovim=0
        l_tag="NeoVIM"
    fi

    #2. Ruta base donde se instala el plugins/paquete
    local l_base_plugins_path="${g_targethome_path}/.vim/pack"
    if [ $p_is_neovim -eq 0  ]; then
        l_base_plugins_path="${g_targethome_path}/.local/share/nvim/site/pack"
    fi

    #Validar si existe directorio
    if [ ! -d "$l_base_plugins_path" ]; then
        printf '%s > Folder "%s" not exists.\n' "$l_tag" "$l_base_plugins_path"
        return 9
    fi

    #3. Buscar los repositorios git existentes en la carpeta plugin y actualizarlos
    local l_folder
    local l_plugin_path
    local l_repo_type
    local l_repo_name
    local l_flag_title=1
    local l_i=0

    cd $l_base_plugins_path
    for l_folder  in $(find . -mindepth 4 -maxdepth 4 -type d -name .git); do

        l_plugin_path="${l_folder%/.git}"
        l_plugin_path="${l_plugin_path#./}"

        l_repo_name="${l_plugin_path##*/}"
        l_repo_type="${l_plugin_path%%/*}"

        l_plugin_path="${l_base_plugins_path}/${l_plugin_path}"

        #_update_repository $p_is_neovim "$l_folder" "$l_repo_name" "$l_repo_type"

        #Almacenando las ruta de documentacion a indexar
        if [ -d "${l_plugin_path}/doc" ]; then

            #Mostrar el titulo si aun no ha mostrado
            if [ $l_flag_title -ne 0 ]; then

                printf '\n'
                printf '%s > %bIndexar la documentacion de sus plugins%b existentes %b(en "%s")%b:\n' "$l_tag" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
                       "$l_base_plugins_path" "$g_color_reset"
                l_flag_title=0

            fi

            #Indexar la documentación
            l_i=$((l_i + 1))
            printf '(%s) Indexando la documentación del plugin %b%s%b en %s: "%bhelptags %s%b"\n' "$l_i" "$g_color_gray1" "$l_repo_name" \
                   "$g_color_reset" "$l_tag" "$g_color_gray1" "$l_plugin_path/doc" "$g_color_reset"
            if [ $p_is_neovim -eq 0  ]; then
                nvim --headless -c "helptags ${l_plugin_path}/doc" -c qa
            else
                vim -u NONE -esc "helptags ${l_plugin_path}/doc" -c qa
            fi

        fi

    done

    return 0

}



# Parametros:
#  1> Flag '0' si es NeoVIM. Por defecto es 1.
#  2> Flag configurar como Developer (si es '0'). Por defecto es 1.
#  3> Flag '0' si no se indexa la documentacion de VIM. Por defecto, es '1' (se indexa la documentacion)
function _download_vim_packages() {

    #1. Argumentos
    local l_tag="VIM"
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
        l_tag="NeoVIM"
    fi

    local l_mode="Editor"
    local p_flag_developer=1
    if [ "$2" = "0" ]; then
        p_flag_developer=0
        l_mode="IDE"
    fi

    local p_flag_non_index_doc=1
    if [ "$3" = "0" ]; then
        p_flag_non_index_doc=0
    fi

    #Precondiciones obligatorios: Se requiere tener Git instalado
    if ! git --version 1> /dev/null 2>&1; then

        #No esta instalado Git, No configurarlo
        printf '%s > %bGit NO esta instalado%b. Es requerido para descargar los plugins.\n' "$l_tag" "$g_color_red1" "$g_color_reset"
        return 111

    fi

    #2. Ruta base donde se instala el plugins/paquete
    local l_current_scope=1
    local l_folder_packages=".vim/pack"
    if [ $p_is_neovim -eq 0  ]; then
        l_folder_packages=".local/share/nvim/site/pack"
        l_current_scope=2
    fi
    local l_base_plugins="${g_targethome_path}/${l_folder_packages}"



    #3. Crear las carpetas de basicas
    printf '\n'
    printf "%s > %bDescargando los plugins%b de modo %b%s%b %b(%s)%b:\n" "$l_tag" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" \
           "$l_mode" "$g_color_reset" "$g_color_gray1" "$l_base_plugins" "$g_color_reset"

    #Creando los folderes requeridos del home si estos no existe
    create_folderpath_on_home "" "${l_folder_packages}"

    local l_foldername=''
    local l_i=0
    for (( l_i = 0; l_i < ${#ga_group_plugin_folder[@]}; l_i++ )); do

        l_foldername="${ga_group_plugin_folder[${l_i}]}"

        if [ -z "$l_foldername" ]; then
            continue
        fi

        # Si esta en modo basico/editor y estan en el indice para folder de IDE
        if [ $p_flag_developer -ne 0 ] && [ $l_i -ge 3 ]; then
            break
        fi

        create_folderpath_on_home "${l_folder_packages}" "${l_foldername}/opt"
        create_folderpath_on_home "${l_folder_packages}/${l_foldername}" "start"

    done


    #4. Instalar el plugins que se instalan manualmente
    local l_path_base
    local l_repo_git
    local l_repo_name
    local l_repo_type=1
    local l_repo_url
    local l_repo_branch
    local l_repo_depth
    local l_repo_scope
    local l_aux
    local l_submodules_types

    local la_doc_paths=()
    local la_doc_repos=()

    for l_repo_git in "${!gA_repos_type[@]}"; do

        #4.1 Configurar el repositorio
        l_repo_scope="${gA_repos_scope[${l_repo_git}]:-3}"
        l_repo_type=${gA_repos_type[$l_repo_git]}
        l_repo_name=${l_repo_git#*/}

        #Si el repositorio no esta habilitido para su scope, continuar con el siguiente
        if [ $((l_repo_scope & l_current_scope)) -ne $l_current_scope ]; then
            continue
        fi

        #4.2 Obtener la ruta base donde se clonara el paquete (todos los paquetes son opcionale, se inicia bajo configuración)
        l_foldername="${ga_group_plugin_folder[${l_repo_type}]}"

        if [ -z "$l_foldername" ]; then
            printf '%s > Paquete (%s) "%s": No tiene tipo valido\n' "$l_tag" "${l_repo_type}" "${l_repo_git}"
            continue
        fi

        l_path_base="${l_base_plugins}/${l_foldername}/opt"

        #Si es un repositorio para developer no debe instalarse en el perfil basico
        if [ $p_flag_developer -ne 0 ] && [ $l_repo_type -ge 3 ]; then
            continue
        fi

        #echo "${l_path_base}/${l_repo_name}/.git"

        #4.3 Validar si el paquete ya esta instalando
        if [ -d ${l_path_base}/${l_repo_name}/.git ]; then
             printf '%s > Paquete (%s) "%b%s%b": Ya esta instalando\n' "$l_tag" "${l_repo_type}" "$g_color_gray1" "${l_repo_git}" "$g_color_reset"
             continue
        fi

        #4.5 Instalando el paquete
        cd ${l_path_base}
        printf '\n'
        print_line '.' $g_max_length_line  "$g_color_gray1"
        #print_line '- ' $((g_max_length_line/2)) "$g_color_gray1"
        printf '%s > Plugin (%b%s%b) "%b%s%b": Se esta instalando\n' "$l_tag" "$g_color_cian1" "$l_repo_type" "$g_color_reset" "$g_color_cian1" \
               "$l_repo_git" "$g_color_reset"
        #print_line '- ' $((g_max_length_line/2)) "$g_color_gray1"
        print_line '.' $g_max_length_line  "$g_color_gray1"

        printf 'Ruta a usar es "%b%s%b"\n' "$g_color_gray1" "${l_path_base}/${l_repo_name}" "$g_color_reset"

        #Siempre realizar una clonacion superficial (obtener solo el ultimo commit)
        l_aux="--depth 1"

        # ¿El repositorio tiene submodulos?
        l_submodules_types=${gA_repos_with_submmodules[${l_repo_git}]:-0}
        if [ $l_submodules_types -eq 1 ] || [ $l_submodules_types -eq 2 ]; then

            # Clona los submodulos definidos en '.gitmodules' y lo hace de manera superficial
            l_aux="${l_aux} --recurse-submodules --shallow-submodules"

        fi

        # La rama a clonar
        l_repo_branch=${gA_repos_branch[$l_repo_git]}
        if [ ! -z "$l_repo_branch" ]; then
            l_aux="${l_aux} --branch ${l_repo_branch}"
        fi


        # Clonar la rama
        printf 'Ejecutando "%bgit clone %s https://github.com/%s.git%b"\n' "$g_color_gray1" "$l_aux" "$l_repo_git" "$g_color_reset"
        printf '%b' "$g_color_gray1"
        git clone ${l_aux} https://github.com/${l_repo_git}.git
        printf '%b' "$g_color_reset"


        #Si se ejecuta como root en modo de suplantacion del usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ]; then
            chown -R "${g_targethome_owner}:${g_targethome_group}" "${l_path_base}/${l_repo_name}"
        fi

        #4.6 Almacenando las ruta de documentacion a indexar
        if [ $p_flag_non_index_doc -ne 0 ] && [ -d "${l_path_base}/${l_repo_name}/doc" ]; then

            #Indexar la documentación de plugins
            la_doc_paths+=("${l_path_base}/${l_repo_name}/doc")
            la_doc_repos+=("${l_repo_name}")

        fi

        #printf '\n'

    done

    #5. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
    local l_doc_path
    local l_n=${#la_doc_paths[@]}
    local l_i

    if [ $p_flag_non_index_doc -ne 0 ] && [ $l_n -gt 0 ]; then

        printf '\n'
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf '%s > %bIndexar%b la documentacion de sus plugins existentes %b(en "%s")%b\n' "$l_tag" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
               "$l_base_plugins" "$g_color_reset"
        print_line '-' $g_max_length_line  "$g_color_gray1"


        for ((l_i=0; l_i< ${l_n}; l_i++)); do

            l_doc_path="${la_doc_paths[${l_i}]}"
            l_repo_name="${la_doc_repos[${l_i}]}"
            printf '(%s/%s) Indexando la documentación del plugin %b%s%b en %s: "%bhelptags %s%b"\n' "$((l_i + 1))" "$l_n" "$g_color_gray1" "$l_repo_name" \
                   "$g_color_reset" "$l_tag" "$g_color_gray1" "$l_doc_path" "$g_color_reset"
            if [ $p_is_neovim -eq 0  ]; then
                nvim --headless -c "helptags ${l_doc_path}" -c qa
            else
                vim -u NONE -esc "helptags ${l_doc_path}" -c qa
            fi

        done

        printf '\n'

    fi

    return 0

}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _setup_nvim_files() {

    #1. Argumentos
    local l_mode="Editor"
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
        l_mode="IDE"
    fi

    local p_flag_overwrite_link=1
    if [ "$2" = "0" ]; then
        p_flag_overwrite_link=0
    fi

    #Sobrescribir los enlaces simbolicos
    printf '\n'
    printf 'NeoVIM > %bConfiguración de archivos basicos%b de NeoVIM como %b%s%b:\n' "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_mode" "$g_color_reset"

    #Creando el folder "~/.config/nvim/"
    create_folderpath_on_home "" ".config/nvim"
    #Creando el folder "~/.config/nvim/runtime_coc"
    create_folderpath_on_home ".config/nvim" "rte_cocide"
    #Creando el folder "~/.config/nvim/runtime_nococ"
    create_folderpath_on_home ".config/nvim" "rte_nativeide"



    #2. Creando los enalces simbolicos
    local l_source_path
    local l_source_filename
    local l_target_path
    local l_target_link

    #Configurar NeoVIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then

        #Creando la carpeta base para los metadata de los proyecto usados por el LSP JDTLS
        create_folderpath_on_home "" ".local/share/eclipse/jdtls"

        l_target_path=".config/nvim"
        l_target_link="coc-settings.json"
        l_source_path="${g_repo_name}/nvim"
        l_source_filename='coc-settings_linux.json'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link


        l_target_path=".config/nvim"
        l_target_link="init.vim"
        l_source_path="${g_repo_name}/nvim"
        l_source_filename='init_ide.vim'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link

        l_target_path=".config/nvim"
        l_target_link="lua"
        l_source_path="${g_repo_name}/nvim/lua"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link

        l_target_path=".config/nvim"
        l_target_link="setting"
        l_source_path="${g_repo_name}/vim/setting"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link

        #El codigo open/close asociado a los 'file types'
        l_target_path=".config/nvim"
        l_target_link="ftplugin"
        l_source_path="${g_repo_name}/nvim/ftplugin/commonide"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link


        #Para el codigo open/close asociado a los 'file types' de CoC
        l_target_path=".config/nvim/rte_cocide"
        l_target_link="ftplugin"
        l_source_path="${g_repo_name}/nvim/ftplugin/cocide"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link


        #Para el codigo open/close asociado a los 'file types' que no sean CoC
        l_target_path=".config/nvim/rte_nativeide"
        l_target_link="ftplugin"
        l_source_path="${g_repo_name}/nvim/ftplugin/nativeide"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link

    #Configurar NeoVIM como Editor
    else

        l_target_path=".config/nvim"
        l_target_link="init.vim"
        l_source_path="${g_repo_name}/nvim"
        l_source_filename='init_editor.vim'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link

        l_target_path=".config/nvim"
        l_target_link="setting"
        l_source_path="${g_repo_name}/vim/setting"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link

        l_target_path=".config/nvim"
        l_target_link="lua"
        l_source_path="${g_repo_name}/nvim/lua"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link


        #El codigo open/close asociado a los 'file types' como Editor
        l_target_path=".config/nvim"
        l_target_link="ftplugin"
        l_source_path="${g_repo_name}/nvim/ftplugin/editor"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_link

    fi

    return 0

}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _setup_vim_files() {

    #1. Argumentos
    local l_mode="Editor"
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
        l_mode="IDE"
    fi

    local p_flag_overwrite_link=1
    if [ "$2" = "0" ]; then
        p_flag_overwrite_link=0
    fi


    #2. Crear el subtitulo
    printf '\n'
    printf 'VIM > %bConfiguración de archivos basicos%b de VIM como %b%s%b:\n' "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_mode" "$g_color_reset"


    #Creando el folder "~/.vim/"
    create_folderpath_on_home "" ".vim"


    #3. Crear los enlaces simbolicos de VIM
    local l_source_path
    local l_source_filename
    local l_target_path
    local l_target_link

    #Configurar VIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then

        #Creando enlaces simbolicos
        l_target_path=".vim"
        l_target_link="coc-settings.json"
        l_source_path="${g_repo_name}/vim"
        l_source_filename='coc-settings_linux.json'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "VIM > " $p_flag_overwrite_link

        l_target_path=".vim"
        l_target_link="setting"
        l_source_path="${g_repo_name}/vim/setting"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "VIM > " $p_flag_overwrite_link

        l_target_path=".vim"
        l_target_link="ftplugin"
        l_source_path="${g_repo_name}/vim/ftplugin/cocide"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "VIM > " $p_flag_overwrite_link


        l_target_path=""
        l_target_link=".vimrc"
        l_source_path="${g_repo_name}/vim"
        l_source_filename='vimrc_ide.vim'

        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "VIM > " $p_flag_overwrite_link


    #Configurar VIM como Editor basico
    else

        l_target_path=".vim"
        l_target_link="setting"
        l_source_path="${g_repo_name}/vim/setting"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "VIM > " $p_flag_overwrite_link

        l_target_path=".vim"
        l_target_link="ftplugin"
        l_source_path="${g_repo_name}/vim/ftplugin/editor"
        create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "VIM > " $p_flag_overwrite_link

        l_target_path=""
        l_target_link=".vimrc"
        l_source_path="${g_repo_name}/vim"
        l_source_filename='vimrc_editor.vim'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "VIM > " $p_flag_overwrite_link


    fi

    return 0

}




# Parametros:
# > Opcion ingresada por el usuario.
function _setup_user_profile() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi


    #¿Esta habilitado la creacion de los archivos de perfil del usuario?
    local l_option=1
    if [ $(( $p_opciones & $l_option )) -ne $l_option ]; then
        return 99
    fi

    #¿Se puede recrear los enlaces simbolicos en caso existir?
    l_option=2
    local l_flag_overwrite_link=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_overwrite_link=0
    fi

    #¿Se puede recrear los enlaces simbolicos en caso existir?
    l_option=4
    local l_flag_overwrite_file=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_overwrite_file=0
    fi


    #2. Mostrar el titulo
    printf '\n'
    print_line '-' $g_max_length_line "$g_color_gray1"
    #print_line '─' $g_max_length_line  "$g_color_blue1"

    if [ $l_flag_overwrite_link -eq 0 ]; then
        printf "OS > Creando los %benlaces simbolicos%b del perfil %b(sobrescribir lo existente)%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    else
        printf "OS > Creando los %benlaces simbolicos%b del perfil %b(solo crar si no existe)%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    fi

    #print_line '─' $g_max_length_line "$g_color_blue1"
    print_line '-' $g_max_length_line  "$g_color_gray1"


    #3. Crear algunos carpetas basicas (no es obligatorios, pero es deseado)

    #Folderes para almacenar las claves secretas y compartidas (por ejemplo claves SSH y TLS)
    create_folderpath_on_home "${g_repo_name}" "keys/shared"
    create_folderpath_on_home "${g_repo_name}/keys" "secret"
    create_folderpath_on_home "${g_repo_name}/keys/secret" "ssh"
    create_folderpath_on_home "${g_repo_name}/keys/secret" "tls"
    create_folderpath_on_home "${g_repo_name}/keys/shared" "ssh"
    create_folderpath_on_home "${g_repo_name}/keys/shared" "tls"

    #4. Creando enlaces simbolico dependientes del tipo de distribución Linux
    local l_target_path
    local l_target_link
    local l_source_path
    local l_source_filename
    local l_status

    #Archivo de colores de la terminal usado por comandos basicos
    l_target_path=""
    l_target_link=".dircolors"
    l_source_path="${g_repo_name}/etc/dircolors"

    l_source_filename=''
    if [ $g_os_type -eq 1 ]; then
        #Si es WSL Linux
        if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
            l_source_filename='dircolors_wsl_debian1.conf'
        elif [ $g_os_subtype_id -ge 10 ] && [ $g_os_subtype_id -lt 30 ]; then
            l_source_filename='dircolors_wsl_fedora1.conf'
        fi
    else
        if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
            l_source_filename='dircolors_debian1.conf'
        elif [ $g_os_subtype_id -ge 10 ] && [ $g_os_subtype_id -lt 30 ]; then
            l_source_filename='dircolors_fedora1.conf'
        fi
    fi

    if [ ! -z "$l_source_filename" ]; then
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?
    fi

    #Archivos de configuración de PowerShell
    l_target_path=".config/powershell"
    create_folderpath_on_home "" "$l_target_path"
    l_target_link="Microsoft.PowerShell_profile.ps1"
    l_source_path="${g_repo_name}/shell/powershell/login/linuxprofile"
    if [ $g_os_subtype_id -eq 1 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='alphine_aarch64.ps1'
        else
            l_source_filename='alphine_x64.ps1'
        fi
    elif [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='debian_aarch64.ps1'
        else
            l_source_filename='debian_x64.ps1'
        fi
    elif [ $g_os_subtype_id -ge 50 ] && [ $g_os_subtype_id -lt 60 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='arch_aarch64.ps1'
        else
            l_source_filename='arch_x64.ps1'
        fi
    elif [ $g_os_subtype_id -ge 60 ] && [ $g_os_subtype_id -lt 70 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='suse_aarch64.ps1'
        else
            l_source_filename='suse_x64.ps1'
        fi
    else
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='fedora_aarch64.ps1'
        else
            l_source_filename='fedora_x64.ps1'
        fi
    fi

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    #Creando el profile del interprete shell
    l_target_path=""
    l_target_link=".bashrc"
    l_source_path="${g_repo_name}/shell/bash/login/profile"

    if [ $g_os_subtype_id -eq 1 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='alphine_aarch64.bash'
        else
            l_source_filename='alphine_x64.bash'
        fi
    elif [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='debian_aarch64.bash'
        else
            l_source_filename='debian_x64.bash'
        fi
    elif [ $g_os_subtype_id -ge 50 ] && [ $g_os_subtype_id -lt 60 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='arch_aarch64.bash'
        else
            l_source_filename='arch_x64.bash'
        fi
    elif [ $g_os_subtype_id -ge 60 ] && [ $g_os_subtype_id -lt 70 ]; then
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='suse_aarch64.bash'
        else
            l_source_filename='suse_x64.bash'
        fi
    else
        if [ "$g_os_architecture_type" = "aarch64" ]; then
            l_source_filename='fedora_aarch64.bash'
        else
            l_source_filename='fedora_x64.bash'
        fi
    fi

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    # Para WSL copiar el archivo de configuracion del profile
    if [ $g_os_type -eq 1 ]; then

        copy_file_on_home "${g_repo_path}/shell/bash/login/profile" "profile_config_template_wsl.bash" "" ".custom_profile.bash" $l_flag_overwrite_file "        > "
        l_status=$?
        printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de profile bash de la distribución WSL\n' \
              "$g_color_yellow1" "~/.custom_profile.bash" "$g_color_reset"

    # Si es contenedor distrobox
    elif [ ! -z "$CONTAINER_ID" ]; then

        copy_file_on_home "${g_repo_path}/shell/bash/login/profile" "profile_config_template_distrobox.bash" "" ".custom_profile.bash" $l_flag_overwrite_file "        > "
        l_status=$?
        printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de profile bash de la distribución WSL\n' \
              "$g_color_yellow1" "~/.custom_profile.bash" "$g_color_reset"

    else

        # Si el distro tiene acceos a los dispositivos como GPU, ...
        if [ $g_profile_type -eq 0 ]; then

            printf 'Profile > Si desea restablecer los valores por defecto, use: "%bcp ~/.files/shell/bash/login/profile/profile_config_template_basic_local.bash %b~/.custom_profile.bash%b"\n' \
                  "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"

        else

            copy_file_on_home "${g_repo_path}/shell/bash/login/profile" "profile_config_template_basic_remote.bash" "" ".custom_profile.bash" $l_flag_overwrite_file "        > "
            l_status=$?
            printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de profile bash de la distribución WSL\n' \
                  "$g_color_yellow1" "~/.custom_profile.bash" "$g_color_reset"

        fi

    fi


    #5. Creando enlaces simbolico independiente del tipo de distribución Linux

    #Archivo de configuración del GNU ReadLine
    l_target_path=""
    l_target_link=".inputrc"
    l_source_path="${g_repo_name}/etc/readline"
    l_source_filename='inputrc'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?


    #Archivo de configuración para LFTP
    l_target_path=""
    l_target_link=".lftprc"
    l_source_path="${g_repo_name}/etc/lftp"
    l_source_filename='lftprc_default.conf'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?


    #Crear el enlace de TMUX (no usaramos '~/.tmux.conf', usaramos '~/.config/tmux/tmux.conf')
    create_folderpath_on_home ".config" "tmux"
    l_target_path=".config/tmux"
    l_target_link="tmux.conf"
    l_source_path="${g_repo_name}/etc/tmux"
    l_source_filename='tmux.conf'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    l_source_filename='custom_config_template_1.conf'
    copy_file_on_home "${g_repo_path}/etc/tmux" "$l_source_filename" ".config/tmux" "custom_config.conf" $l_flag_overwrite_file "        > "
    l_status=$?
    printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de tmux.\n' \
           "$g_color_yellow1" "~/.config/tmux/custom_config.conf" "$g_color_reset"


    # Archivo de configuracion de 'sesh' (comando que gestiona sesiones para TMUX)
    create_folderpath_on_home ".config" "sesh"
    create_folderpath_on_home ".config/sesh" "shell"
    l_target_path=".config/sesh"
    l_target_link="sesh.toml"
    l_source_path="${g_repo_name}/etc/sesh"
    l_source_filename='sesh_default.toml'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    copy_file_on_home "${g_repo_path}/etc/sesh" "custom_config_template_1.toml" ".config/sesh" "custom_config.toml" $l_flag_overwrite_file "        > "
    l_status=$?
    printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar sesh.\n' \
           "$g_color_yellow1" "~/.config/sesh/custom_config.toml" "$g_color_reset"

    #l_target_path=".config/sesh/shell"
    #l_target_link="tmx_upload_movies.bash"
    #l_source_path="${g_repo_name}/shell/bash/bin/tmux_layout"
    #l_source_filename='tmx_upload_movies.bash'

    #create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "        > " $l_flag_overwrite_link
    #l_status=$?


    #Archivo de configuración para el emulador de terminal wezterm

    # Es WSL (es un local espacial: diseñado para ser accedido solo desde el windows local)
    if [ $g_os_type -eq 1 ]; then

        create_folderpath_on_home ".config" "wezterm"

        #l_target_path=".config/wezterm"
        #l_target_link="utils"
        #l_source_path="${g_repo_name}/wezterm/remote/utils"
        #create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "Profile > " $p_flag_overwrite_link

        copy_file_on_home "${g_repo_path}/wezterm/remote" "wezterm_template_wsl_1.lua" ".config/wezterm" "wezterm.lua" $l_flag_overwrite_file "        > "
        l_status=$?
        printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de Wezterm\n' \
               "$g_color_yellow1" "~/.config/wezterm/wezterm.lua" "$g_color_reset"

    # Si es contenedor distrobox
    elif [ ! -z "$CONTAINER_ID" ]; then

        printf 'Profile > No se realizara configuraciones para Wezterm.\n'

    # Linux clasico (No es WSL)
    else

        create_folderpath_on_home ".config" "wezterm"

        if [ $g_profile_type -eq 0 ]; then

            l_target_path=".config/wezterm"
            l_target_link="wezterm.lua"
            l_source_path="${g_repo_name}/wezterm/local"
            l_source_filename='wezterm.lua'

            create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
            l_status=$?

            l_target_path=".config/wezterm"
            l_target_link="utils"
            l_source_path="${g_repo_name}/wezterm/local/utils"
            create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "Profile > " $p_flag_overwrite_link

            copy_file_on_home "${g_repo_path}/wezterm/local" "custom_config_template_lnx.lua" ".config/wezterm" "custom_config.lua" $l_flag_overwrite_file "        > "
            l_status=$?
            printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de Wezterm\n' \
                   "$g_color_yellow1" "~/.config/wezterm/custom_config.lua" "$g_color_reset"

        else

            #l_target_path=".config/wezterm"
            #l_target_link="utils"
            #l_source_path="${g_repo_name}/wezterm/remote/utils"
            #create_folderlink_on_home "$l_source_path" "$l_target_path" "$l_target_link" "Profile > " $p_flag_overwrite_link

            copy_file_on_home "${g_repo_path}/wezterm/remote" "wezterm_template_lnx_1.lua" ".config/wezterm" "wezterm.lua" $l_flag_overwrite_file "        > "
            l_status=$?
            printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de Wezterm\n' \
                   "$g_color_yellow1" "~/.config/wezterm/wezterm.lua" "$g_color_reset"

        fi
    fi

    #Archivo de configuración para el emulador de terminal foot
    if [ -z "$CONTAINER_ID" ] && [ $g_os_type -ne 1 ]; then

        l_target_path=".config/foot"
        create_folderpath_on_home ".config" "foot"
        l_target_link="foot.ini"
        l_source_path="${g_repo_name}/etc/foot"
        l_source_filename='foot_default.ini'

        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?

    else
        printf 'Profile > No se realizara configuraciones para Foot.\n'
    fi


    #Archivo de configuración para Lazygit
    l_target_path=".config/lazygit"
    create_folderpath_on_home ".config" "lazygit"
    l_target_link="config.yml"
    l_source_path="${g_repo_name}/etc/lazygit"
    l_source_filename='config_default.yaml'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?


    #Archivo de configuración para Yazi
    l_target_path=".config/yazi"
    create_folderpath_on_home ".config" "yazi"

    l_target_link="yazi.toml"
    l_source_path="${g_repo_name}/etc/yazi"
    l_source_filename='yazi_default.toml'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    l_target_link="keymap.toml"
    l_source_path="${g_repo_name}/etc/yazi"
    l_source_filename='keymap_default.toml'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    l_target_link="theme.toml"
    l_source_path="${g_repo_name}/etc/yazi"
    l_source_filename='theme_default.toml'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    create_folderpath_on_home ".config" "yazi/flavors/catppuccin-mocha.yazi"
    copy_file_on_home "${g_repo_path}/etc/yazi/catppuccin-mocha" "flavor.toml" ".config/yazi/flavors/catppuccin-mocha.yazi" "flavor.toml" $l_flag_overwrite_file "        > "
    l_status=$?
    copy_file_on_home "${g_repo_path}/etc/yazi/catppuccin-mocha" "tmtheme.xml" ".config/yazi/flavors/catppuccin-mocha.yazi" "tmtheme.xml" $l_flag_overwrite_file "        > "
    l_status=$?


    #Archivo de configuración para cliente MDP 'rmpc'
    if [ -z "$CONTAINER_ID" ] && [ $g_os_type -ne 1 ]; then

        l_target_path=".config/rmpc"
        create_folderpath_on_home ".config" "rmpc"

        l_target_link="config.ron"
        l_source_path="${g_repo_name}/etc/rmpc"
        l_source_filename='config_default.ron'

        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?

        create_folderpath_on_home ".config/rmpc" "themes"

        l_target_path=".config/rmpc/themes"
        l_target_link="theme_default.ron"
        l_source_path="${g_repo_name}/etc/rmpc/themes"
        l_source_filename='theme_default.ron'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "        > " $l_flag_overwrite_link
        l_status=$?

    else
        printf 'Profile > No se realizara configuraciones para rmpc.\n'
    fi

    #Crear el enlace simbolico de comandos basicos
    create_folderpath_on_home "" ".local/bin"
    l_target_path=".local/bin"
    l_target_link="osc52"
    l_source_path="${g_repo_name}/shell/bash/bin/cmds"
    l_source_filename='osc52.bash'
    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    #Crear el enlace simbolico de comandos basicos
    l_target_path=".local/bin"
    l_target_link="tmux_run_cmd"
    l_source_path="${g_repo_name}/shell/bash/bin/cmds"
    l_source_filename='tmux_run_cmd.bash'
    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?


    #Crear el enlace simbolico de comandos basicos
    if [ -z "$CONTAINER_ID" ] && [ $g_os_type -ne 1 ]; then

        l_target_path=".local/bin"
        l_target_link="sync_vault"
        l_source_path="${g_repo_name}/shell/bash/bin/cmds"
        l_source_filename='sync_vault.bash'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?

    else
        printf 'Profile > No se establece en enlace simbolico asociado al comando "%bsync_vault%b".\n' "$g_color_gray1" "$g_color_reset"
    fi



    #Crear el enlace simbolico de comandos basicos
    if [ -z "$CONTAINER_ID" ] && [ $g_os_type -ne 1 ]; then

        l_target_path=".local/bin"
        l_target_link="mymusic"
        l_source_path="${g_repo_name}/shell/bash/bin/cmds"
        l_source_filename='mymusic.bash'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?

    else
        printf 'Profile > No se establece en enlace simbolico asociado al comando "%bmymusic%b".\n' "$g_color_gray1" "$g_color_reset"
    fi


    #Archivo de configuración de Git y sus archivo de connfiguracion personalzida.
    l_target_path=""
    l_target_link=".gitconfig"
    l_source_path="${g_repo_name}/etc/git"
    l_source_filename='gitconfig_lnx.toml'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?

    create_folderpath_on_home ".config" "git"
    copy_file_on_home "${g_repo_path}/etc/git" "user_main_template_lnx.toml" ".config/git" "user_main.toml" $l_flag_overwrite_file "        > "
    l_status=$?

    copy_file_on_home "${g_repo_path}/etc/git" "user_work_template_lnx.toml" ".config/git" "user_mywork.toml" $l_flag_overwrite_file "        > "
    l_status=$?
    printf 'Profile > Edite los archivos "%b%s%b" y "%b%s%b" si desea personalizar las opciones a nivel global del usuario ("%b~/.gitconfig%b")\n' \
           "$g_color_yellow1" "~/.config/git/user_main.toml" "$g_color_reset" "$g_color_yellow1" "~/.config/git/user_mywork.toml" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset"


    #Archivo de configuración de Oh-My-Posh

    # Es WSL (es un local espacial: diseñado para ser accedido solo desde el windows local)
    if [ $g_os_type -eq 1 ]; then

        # Si el que instala es el usuario root
        if [ $g_runner_id -eq 0 ] && [ $g_runner_is_target_user -eq 0 ]; then
            l_source_filename='lepc-montys-orange1.json'
        # Si el que instala es el usuario no-root
        else
            l_source_filename='lepc-montys-blue1.json'
        fi

    # Si es contenedor distrobox
    elif [ ! -z "$CONTAINER_ID" ]; then

        # Si el que instala es el usuario root
        if [ $g_runner_id -eq 0 ] && [ $g_runner_is_target_user -eq 0 ]; then
            l_source_filename='lepc-montys-orange1.json'
        # Si el que instala es el usuario no-root
        else
            l_source_filename='lepc-montys-blue1.json'
        fi

    # Linux clasico (No es WSL)
    else

        if [ $g_profile_type -eq 0 ]; then

            # Si el que instala es el usuario root
            if [ $g_runner_id -eq 0 ] && [ $g_runner_is_target_user -eq 0 ]; then
                l_source_filename='lepc-montys-purple1.json'
            # Si el que instala es el usuario no-root
            else
                l_source_filename='lepc-montys-cyan1.json'
            fi

        else

            # Si el que instala es el usuario root
            if [ $g_runner_id -eq 0 ] && [ $g_runner_is_target_user -eq 0 ]; then
                l_source_filename='lepc-montys-yellow1.json'
            # Si el que instala es el usuario no-root
            else
                l_source_filename='lepc-montys-green1.json'
            fi

        fi

    fi

    copy_file_on_home "${g_repo_path}/etc/oh-my-posh" "$l_source_filename" "${g_repo_name}/etc/oh-my-posh" "default_settings.json" $l_flag_overwrite_file "        > "
    l_status=$?
    printf 'Profile > Edite el archivo "%b%s%b" si desea personalizar las opciones de oh-my-posh\n' \
           "$g_color_yellow1" "~/.config/etc/oh-my-posh/defaut_settings.json" "$g_color_reset"

    #Archivo de configuración para el comando UrlScan (hecho en python)
    l_target_path=".config/urlscan"
    create_folderpath_on_home ".config" "urlscan"
    l_target_link="config.json"
    l_source_path="${g_repo_name}/etc/urlscan"
    l_source_filename='default_config.json'

    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?
    #NerdCtl: Configuración de un CLI de alto nivel del 'Container Runtime' 'ContainerD'
    l_target_path=".config/nerdctl"
    create_folderpath_on_home ".config" "nerdctl"
    l_target_link="nerdctl.toml"
    l_source_path="${g_repo_name}/etc/nerdctl"
    l_source_filename='config_default.toml'
    create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
    l_status=$?


    #NerdCtl/ContainerD y Podman para el usuario root, no almacena su configuración en su home, lo almacena en '/etc'
    #Para usuario root, la configuracion es manual. Solo e configura automaticamente para modo rootless.
    #Permitir solo cuando el runner no es root o es root pero en modo suplantacion del usuario objetivo.
    if [ $g_runner_id -ne 0 ] || [ $g_runner_is_target_user -ne 0 ]; then

        #Podman: Configuración principal de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless')
        l_target_path=".config/containers"
        create_folderpath_on_home ".config" "containers"
        l_target_link="containers.conf"
        l_source_path="${g_repo_name}/etc/podman"
        l_source_filename='containers_default.toml'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?

        #Podman: Configuración de los registros de imagenes de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless')
        l_target_path=".config/containers"
        l_target_link="registries.conf"
        l_source_path="${g_repo_name}/etc/podman"
        l_source_filename='registries_default.toml'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?

        #ContainerD: Configuración de un 'Container Runtime' 'ContainerD' (en modo 'rootless')
        #l_target_path=".config/containerd"
        #l_target_link="config.toml"
        #l_source_path="${g_repo_name}/etc/containerd"
        #l_source_filename='config_overlay_default.toml'
        #create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        #l_status=$?


        #ContainerD: Configuración del backend de compilacion de imagenes 'BuildKit' (en modo 'rootless')
        l_target_path=".config/buildkit"
        create_folderpath_on_home ".config" "buildkit"
        l_target_link="buildkitd.toml"
        l_source_path="${g_repo_name}/etc/buildkit"
        l_source_filename='config_default.toml'
        create_filelink_on_home "$l_source_path" "$l_source_filename" "$l_target_path" "$l_target_link" "Profile > " $l_flag_overwrite_link
        l_status=$?

    fi

    #6. Creando el archivo de configuracion basado en un template

    #Configuracion por defecto para un Cluster de Kubernates
    create_folderpath_on_home "" ".kube"
    copy_file_on_home "${g_repo_path}/etc/kubectl" "template_config.yaml" ".kube" "lepc_clusters.yaml" $l_flag_overwrite_file "Profile > "
    l_status=$?

    #Archivo de configuración de SSH
    create_folderpath_on_home "" ".ssh"
    copy_file_on_home "${g_repo_path}/etc/ssh" "template_linux_withpublickey.conf" ".ssh" "config" $l_flag_overwrite_file "Profile > "
    l_status=$?



    return 0

}


#
# Parametros de salids
# > Valor de retorno
#   0 > Ok. Ya esta instalado
#   1 > Ok. Se instalo sin problemas
#   2 > Error. Ocurrio un error en la instalacion del paquete.
#   3 > Error. Python no esta instalado correctamente (no esta instalado el gestor de paquetes 'pip' o 'pipx'
function _install_python_package() {

    # Paquetes
    local p_pkg_nemonic="$1"
    local p_pkg_name="$2"
    local p_pkg_group=$3
    local p_pkg_type=$4
    local p_pkg_description="$5"

    #1. Validar si fue instalado como libreria
    #   Ejemplo: nodejs-wheel-binaries 22.15.0
    local l_aux
    l_aux=$(pip3 list --user 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
        return 3
    fi

    l_aux=$(echo "$l_aux" | grep "${p_pkg_nemonic} ")
    l_status=$?

    local l_version=''
    if [ ! -z "$l_aux" ]; then
        l_version=$(echo "$l_aux" | head -n 1 | sed "$g_regexp_sust_version1")
    fi

    #echo "l_aux=${l_aux}, l_status=${l_status}, p_pkg_nemonic=${p_pkg_nemonic}"

    #2. Si el paquete es una libreria
    if [ $p_pkg_type -eq 0 ]; then

        # Si ya esta instalado
        if [ ! -z "$l_version" ]; then
            printf 'Python > El paquete "%b%s%b" (%b%s%b) ya esta instalado a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
                   "$g_color_gray1" "$l_version" "$g_color_reset" "$g_color_gray1" "$p_pkg_description" "$g_color_reset"
            return 0
        fi


        printf 'Python > Instalando paquete "%b%s%b" a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
               "$g_color_gray1" "$p_pkg_description" "$g_color_reset"

        #Se instalar a nivel usuario
        if [ $g_os_type -eq 19 ]; then

            printf '       > Ejecutando %b%s%b.\n' "$g_color_gray1" "pip3 install --user ${p_pkg_name}" "$g_color_reset"
            printf '%b' "$g_color_gray1"
            pip3 install --user ${p_pkg_name}
            l_status=$?
            printf '%b' "$g_color_reset"

        else

            printf '       > Ejecutando %b%s%b.\n' "$g_color_gray1" "pip3 install --user --break-system-packages ${p_pkg_name}" "$g_color_reset"
            printf '%b' "$g_color_gray1"
            pip3 install --user --break-system-packages ${p_pkg_name}
            l_status=$?
            printf '%b' "$g_color_reset"

        fi

        if [ $l_status -ne 0 ]; then
            return 2
        fi
        return 1

    fi

    #3. Si el paquete CLI es un programa ejecutable (CLI tools)

    # Si fuen instalado como libreria, deseintalarlo
    if [ ! -z "$l_version" ]; then

        if [ $g_os_type -eq 19 ]; then

            printf 'Python > El programa CLI "%b%s%b" se instalo como una libreria a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
                   "$g_color_gray1" "pip3 install --user ${p_pkg_name}" "$g_color_reset"

            printf '       > Se realizará su desinstalacion %b%s%b.\n' "$g_color_gray1" "pip3 uninstall -y ${p_pkg_name}" "$g_color_reset"
            printf '%b' "$g_color_gray1"
            pip3 uninstall -y ${p_pkg_name}
            l_status=$?
            printf '%b' "$g_color_reset"

        else

            printf 'Python > El programa CLI "%b%s%b" se instalo como una libreria a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
                   "$g_color_gray1" "pip3 install --user --break-system-packages ${p_pkg_name}" "$g_color_reset"

            printf '       > Se realizará su desinstalacion %b%s%b.\n' "$g_color_gray1" "pip3 uninstal --break-system-packagesl -y ${p_pkg_name}" "$g_color_reset"
            printf '%b' "$g_color_gray1"
            pip3 uninstall --break-system-packages -y ${p_pkg_name}
            l_status=$?
            printf '%b' "$g_color_reset"

        fi
    fi

    # Verificar si esta instalado como tool CLI
    # Ejemplo: package ansible 11.5.0, installed using Python 3.13.3
    l_aux=$(pipx list | grep "package ${p_pkg_nemonic} " 2> /dev/null)
    l_status=$?

    l_version=''
    if [ ! -z "$l_aux" ]; then
        l_version=$(echo "$l_aux" | head -n 1 | sed "$g_regexp_sust_version1")
    fi

    # Instalar el paquete como tool CLI

    # Si ya esta instalado
    if [ ! -z "$l_version" ]; then
        printf 'Python > El programa CLI "%b%s%b" (%b%s%b) ya esta instalado a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
               "$g_color_gray1" "$l_version" "$g_color_reset" "$g_color_gray1" "$p_pkg_description" "$g_color_reset"
        return 0
    fi


    printf 'Python > Instalando programa CLI "%b%s%b" a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
           "$g_color_gray1" "$p_pkg_description" "$g_color_reset"

    #Se instalar a nivel usuario
    if [ $p_pkg_type -eq 2 ]; then

        # (2) Es un programa ejecutable (CLI tools) que tiene dependecias que son CLI tools.
        printf '       > Ejecutando %b%s%b.\n' "$g_color_gray1" "pipx install --include-deps ${p_pkg_name}" "$g_color_reset"
        printf '%b' "$g_color_gray1"
        pipx install --include-deps ${p_pkg_name}
        l_status=$?
        printf '%b' "$g_color_reset"

    else

        # (1) Es un programa ejecutable (CLI tools) cuyas dependencias no son CLI tools.
        printf '       > Ejecutando %b%s%b.\n' "$g_color_gray1" "pipx install ${p_pkg_name}" "$g_color_reset"
        printf '%b' "$g_color_gray1"
        pipx install ${p_pkg_name}
        l_status=$?
        printf '%b' "$g_color_reset"

    fi

    if [ $l_status -ne 0 ]; then
        return 2
    fi

    return 1

}



# Instala un grupo de paquetes python a nivel usuario.
# Parametros de entrada:
#  1> Opción de menu a ejecutar
# Parametros de salida:
#    0> OK. Se instalaron los paquetes.
#    1> OK. El grupo no tiene paquetes asociados.
#    2> Error. Ocurrio un error durante la instalacion
function _install_python_package_group() {

    local p_pkg_group=$1

    # Obtener los nemonicos de los paquetes que pertenecen al grupo
    local l_pkg_nemonic
    local -a la_pkg_nemonics=()
    local l_pkg_name
    local l_ok=0
    local l_aux=''

    for l_pkg_nemonic in "${!gA_python_pckgs_name[@]}"; do

        l_pkg_name="${gA_python_pckgs_name[$l_pkg_nemonic]}"
        if [ -z "$l_pkg_name" ]; then
            continue
        fi

        # Por defecto es grupo otros
        l_pkg_group=${gA_python_pckgs_group[$l_pkg_nemonic]:-2}

        if [ $l_pkg_group -ne $p_pkg_group ]; then
            continue
        fi

        if [ -z "$l_aux" ]; then
            printf -v l_aux '"%b%s%b"' "$g_color_gray1" "$l_pkg_name" "$g_color_reset"
        else
            printf -v l_aux '%b, "%b%s%b"' "$l_aux" "$g_color_gray1" "$l_pkg_name" "$g_color_reset"
        fi

        la_pkg_nemonics[$l_ok]="$l_pkg_nemonic"
        (( l_ok++ ))

    done

    if [ $l_ok -le 0 ]; then
        return 1
    fi

    printf '\n'
    printf 'Package Group "%b%s%b"> Instalando %b\n' "$g_color_cian1" "$p_pkg_group" "$g_color_reset" "$l_aux"

    # Obtener el lo paquetes de grupo e instalarlo
    local l_pkg_description
    local l_pkg_type
    local l_status
    local l_ok_not_installed=0
    local l_error=0
    l_ok=0

    for l_pkg_nemonic in "${la_pkg_nemonics[@]}"; do

        l_pkg_name="${gA_python_pckgs_name[$l_pkg_nemonic]}"

        # Por defectro es una libreria
        l_pkg_type=${gA_python_pckgs_type[$l_pkg_nemonic]:-0}
        l_pkg_description="${gA_python_pckgs_description[$l_pkg_nemonic]}"

        _install_python_package "$l_pkg_nemonic" "$l_pkg_name" $l_pkg_group $l_pkg_type "$l_pkg_description"
        l_status=$?

        if [ $l_status -eq 0 ]; then
            (( l_ok_not_installed++ ))
        elif [ $l_status -eq 1 ]; then
            (( l_ok++ ))
        else
            (( l_error++ ))
        fi

    done

    printf 'Package Group "%b%s%b"> %s installed, %s is already installed, %s has error.\n' "$g_color_cian1" "$p_pkg_group" "$g_color_reset" \
           "$l_ok" "$l_ok_not_installed" "$l_error"

    return 0

}



# Instalar Python, sus gestores de paquetes 'pip' y 'pipx' y otros paquetes a nivel usuario.
# Parametros de entrada:
#  1> Opción de menu a ejecutar
# Parametros de salida:
#  111> No se cumplio con requesitos obligatorios. Detener el proceso.
#  120> No se almaceno el password para sudo (solo cuando se requiere).
function _setup_python_enviroment() {

    #0. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #1. Validar las opciones a usar
    local l_flag_setup=1
    local l_flag_setup_1=1
    local l_flag_setup_2=1
    local l_flag_setup_3=1

    # ¿Instalar python y sus gestores de paquetes?
    local l_option=524288
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup=0
    fi

    # ¿Instalar paquetes de usuario basicos?
    l_option=1048576
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_1=0
    fi

    # ¿Instalar paquetes de usuario asociados a LSP, DAP, formatter y linter basicos requiridos?
    l_option=2097152
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_2=0
    fi

    # ¿Instalar paquetes de usuario otros necesarios para development?
    local l_option=4194304
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_3=0
    fi

    # Si no se requiere instalar ninguna opcion en python
    if [ $l_flag_setup -ne 0 ] && [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ]; then
        return 0
    fi

    #Mostrar el titulo
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf 'Python > Configurando el entorno %bPython%b para development\n' "$g_color_cian1" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"


    #2. Instalar Python y su gestor de paquetes 'pip' y 'pipx'
    local l_status
    local l_is_python_installed=-1   #(-1) No determinado, (0) Instalado, (1) Solo instalado Python pero no pip o pipx, (2) No instalado ni Python ni Pip

    if [ $l_flag_setup -eq 0 ]; then

        #Instalar Python
        install_python
        l_status=$?

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Si no se acepto almacenar credenciales
        elif [ $l_status -eq 120 ]; then
            return 120
        elif [ $l_status -eq 0 ]; then
            l_is_python_installed=0
        elif [ $l_status -eq 1 ]; then
            l_is_python_installed=1
        else
            l_is_python_installed=2
        fi

    fi


    #3. Instalar paquetes de python

    # Si no se requiere instalar ninguna paquete python
    if [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ]; then
        return 0
    fi

    #Si aun no se ha revisado si se ha instalado python y sus gestores de paquetes pip y pipx
    local l_aux
    if [ $l_is_python_installed -eq -1 ]; then

        l_aux=$(get_python_versions)
        l_status=$?

        # Si NO estan instalados python, pip y pipx
        if [ $l_status -eq 0 ]; then
            l_is_python_installed=2

        # Si estan instalados python, pip y pipx
        elif [ $l_status -eq 7 ]; then
            l_is_python_installed=0

        # Si falta instalar o pip o pipx
        else
            l_is_python_installed=1

        fi

    fi

    # Se requiere temer instalado Python y sus gestores de paquetes pip y pipx
    if [ $l_is_python_installed -eq 2 ]; then
        printf 'Python > %bEl gestor de paquetes de Python "Pip" o "Pipx" NO esta instalado%b. Es requerido para instalar los paquetes:\n'  "$g_color_red1" "$g_color_reset"
        return 1
    fi

    if [ $l_is_python_installed -eq 1 ]; then
        printf 'Python > %bPython3 NO esta instalado%b. Es requerido para instalar los paquetes:\n'  "$g_color_red1" "$g_color_reset"
        return 1
    fi

    #Si el runner es root el modo suplantacion del usuario objetivo
    if [ $g_runner_is_target_user -ne 0 ]; then

        printf '%b       > Warning: La instalación de paquetes de usuario python lo tiene que ejecutar con el usuario "%b%s%b"\n' \
               "$g_color_yellow1" "$g_color_gray1" "$g_targethome_owner" "$g_color_yellow1"
        printf '                  Luego de esta configuracion, realize nuevamente la configuracion usando el usuario "%b%s%b"%b\n' \
               "$g_color_gray1" "$g_targethome_owner" "$g_color_yellow1" "$g_color_reset"

        return 1
    fi

    # Instalar los paquetes python basicos
    if [ $l_flag_setup_1 -eq 0 ]; then

        _install_python_package_group 0
        l_status=$?

    fi

    # Instalar los paquetes python asociados a LSP/DAP, Fixers y Linter basicos
    if [ $l_flag_setup_2 -eq 0 ]; then

        _install_python_package_group 1
        l_status=$?

    fi


    # Instalar los paquetes python otros para development
    if [ $l_flag_setup_3 -eq 0 ]; then

        _install_python_package_group 2
        l_status=$?

    fi

    return 0

}



#
# Parametros de salids
# > Valor de retorno
#   0 > Ok. Ya esta instalado
#   1 > Ok. Se instalo sin problemas
#   2 > Error. Ocurrio un error en la instalacion del paquete.
#   3 > Error. NodeJS no esta instalado correctamente.
function _install_nodejs_package() {

    # Paquetes
    local p_pkg_nemonic="$1"
    local p_pkg_name="$2"
    local p_pkg_group=$3
    local p_pkg_description="$4"

    #1. Validar si fue instalado como libreria
    #   Ejemplo: nodejs-wheel-binaries 22.15.0
    local l_aux
    l_aux=$(npm list -g 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
        return 3
    fi


    l_aux=$(echo "$l_aux" | grep "${p_pkg_nemonic}@")
    local l_version=''
    if [ ! -z "$l_aux" ]; then
        l_version=$(echo "$l_aux" | head -n 1 | sed "$g_regexp_sust_version1")
    fi

    #2. Instalar el paquete

    # Si ya esta instalado
    if [ ! -z "$l_version" ]; then
        printf 'NodeJS > El paquete "%b%s%b" (%b%s%b) ya esta instalado a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
               "$g_color_gray1" "$l_version" "$g_color_reset" "$g_color_gray1" "$p_pkg_description" "$g_color_reset"
        return 0
    fi


    printf 'NodeJS > Instalando paquete "%b%s%b" a nivel usuario (%b%s%b).\n' "$g_color_gray1" "$p_pkg_name" "$g_color_reset" \
           "$g_color_gray1" "$p_pkg_description" "$g_color_reset"

    # Se instalar el paquete a nivel global
    printf '       > Ejecutando %b%s%b.\n' "$g_color_gray1" "npm install -g ${p_pkg_name}" "$g_color_reset"
    printf '%b' "$g_color_gray1"
    npm install -g ${p_pkg_name}
    l_status=$?
    printf '%b' "$g_color_reset"

    if [ $l_status -ne 0 ]; then
        return 2
    fi

    return 1


}



# Instala un grupo de paquetes python a nivel usuario.
# Parametros de entrada:
#  1> Opción de menu a ejecutar
# Parametros de salida:
#    0> OK. Se instalaron los paquetes.
#    1> OK. El grupo no tiene paquetes asociados.
#    2> Error. Ocurrio un error durante la instalacion
function _install_nodejs_package_group() {

    local p_pkg_group=$1

    # Obtener los nemonicos de los paquetes que pertenecen al grupo
    local l_pkg_nemonic
    local -a la_pkg_nemonics=()
    local l_pkg_name
    local l_ok=0
    local l_aux=''

    for l_pkg_nemonic in "${!gA_nodejs_pckgs_name[@]}"; do

        l_pkg_name="${gA_nodejs_pckgs_name[$l_pkg_nemonic]}"
        if [ -z "$l_pkg_name" ]; then
            continue
        fi

        # Por defecto es grupo otros
        l_pkg_group=${gA_nodejs_pckgs_group[$l_pkg_nemonic]:-2}

        if [ $l_pkg_group -ne $p_pkg_group ]; then
            continue
        fi

        if [ -z "$l_aux" ]; then
            printf -v l_aux '"%b%s%b"' "$g_color_gray1" "$l_pkg_name" "$g_color_reset"
        else
            printf -v l_aux '%b, "%b%s%b"' "$l_aux" "$g_color_gray1" "$l_pkg_name" "$g_color_reset"
        fi

        la_pkg_nemonics[$l_ok]="$l_pkg_nemonic"
        (( l_ok++ ))

    done

    if [ $l_ok -le 0 ]; then
        return 1
    fi

    printf '\n'
    printf 'Package Group "%b%s%b"> Instalando %b\n' "$g_color_cian1" "$p_pkg_group" "$g_color_reset" "$l_aux"

    # Obtener el lo paquetes de grupo e instalarlo
    local l_pkg_description
    local l_pkg_type
    local l_status
    local l_ok_not_installed=0
    local l_error=0
    l_ok=0

    for l_pkg_nemonic in "${la_pkg_nemonics[@]}"; do

        l_pkg_name="${gA_nodejs_pckgs_name[$l_pkg_nemonic]}"

        # Por defectro es una libreria
        l_pkg_description="${gA_nodejs_pckgs_description[$l_pkg_nemonic]}"

        _install_nodejs_package "$l_pkg_nemonic" "$l_pkg_name" $l_pkg_group "$l_pkg_description"
        l_status=$?

        if [ $l_status -eq 0 ]; then
            (( l_ok_not_installed++ ))
        elif [ $l_status -eq 1 ]; then
            (( l_ok++ ))
        else
            (( l_error++ ))
        fi

    done

    printf 'Package Group "%b%s%b"> %s installed, %s is already installed, %s has error.\n' "$g_color_cian1" "$p_pkg_group" "$g_color_reset" \
           "$l_ok" "$l_ok_not_installed" "$l_error"

    return 0

}





# Instalar NodeJS y algunos paquetes a nivel usuarios
# Parametros de entrada:
#  1> Opción de menu a ejecutar
# Parametros de salida:
#  111> No se cumplio con requesitos obligatorios. Detener el proceso.
#  120> No se almaceno el password para sudo (solo cuando se requiere).
function _setup_nodejs_enviroment() {

    #0. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi


    #1. Validar las opciones a usar
    local l_flag_setup=1
    local l_flag_setup_1=1
    local l_flag_setup_2=1
    local l_flag_setup_3=1

    # ¿Instalar nodejs?
    local l_option=32768
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup=0
    fi

    # ¿Instalar paquetes de usuario basicos?
    l_option=65536
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_1=0
    fi

    # ¿Instalar paquetes de usuario asociados a LSP, DAP, formatter y linter basicos requiridos?
    l_option=131072
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_2=0
    fi

    # ¿Instalar paquetes de usuario otros necesarios para development?
    local l_option=262144
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_3=0
    fi

    # Si no se requiere instalar ninguna opcion en python
    if [ $l_flag_setup -ne 0 ] && [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ]; then
        return 0
    fi

    #Mostrar el titulo
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf 'NodeJS > Configurando el entorno %bNodeJS%b para development\n' "$g_color_cian1" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"


    #2. Instalar NodeJS
    local l_status
    local l_is_nodejs_installed=-1   #(-1) No determinado, (0) Instalado, (1) No instalado

    if [ $l_flag_setup -eq 0 ]; then

        #Instalar NodeJS
        install_nodejs
        l_status=$?

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Si no se acepto almacenar credenciales
        elif [ $l_status -eq 120 ]; then
            return 120
        elif [ $l_status -eq 0 ]; then
            l_is_nodejs_installed=0
        else
            l_is_nodejs_installed=1
        fi

    fi

    #3. Instalar paquetes de python

    # Si no se requiere instalar ninguna paquete python
    if [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ]; then
        return 0
    fi

    #Si aun no se ha revisado si se ha instalado python y sus gestores de paquetes pip y pipx
    local l_version
    if [ $l_is_nodejs_installed -eq -1 ]; then

        #Validar si 'node' esta instalado (puede no esta en el PATH)
        l_version=$(get_nodejs_version)
        l_status=$?

        if [ $l_status -eq 3 ]; then
            l_is_nodejs_installed=1
        else
            l_is_nodejs_installed=0
        fi

    fi

    if [ $l_is_nodejs_installed -eq 1 ]; then
        printf 'NodeJS > %bNodeJS%b NO esta instalado o NO esta el PATH del usuario. Ello es requerido para instalar los paquetes.\n' \
               "$g_color_red1" "$g_color_reset"
        return 1
    fi

    #Si el runner es root el modo suplantacion del usuario objetivo
    if [ $g_runner_is_target_user -ne 0 ]; then

        printf 'NodeJS > La instalación de paquetes de NodeJS globales lo tiene que ejecutar con el usuario "%b%s%b".\n' \
               "$g_color_gray1" "$g_targethome_owner" "$g_color_yellow1"

        return 1
    fi

    # Validar que el owner del folder de nodejs puede instalar paquetes globales para no generar problemas en los permisos.
    local l_owner_nodejs
    l_owner_nodejs=$(get_owner_of_nodejs)
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'NodeJS > No se pueden obtener el owner del folder de "%bNodeJS%b".\n' "$g_color_gray1" "$g_color_reset"
        return 1
    fi

    if [ "$g_runner_user" != "$l_owner_nodejs" ]; then
        printf 'NodeJS > No se debe instalar paquetes globales en "%b%s%b" usando como usuario "%b%s%b". Lo debe realizar el owner "%b%s%b".\n' \
               "$g_color_gray1" "$l_nodejs_bin_path" "$g_color_reset" "$g_color_gray1" "$g_runner_user" "$g_color_reset" \
               "$g_color_gray1" "$l_owner_nodejs" "$g_color_reset"
        return 1
    fi


    # Instalar los paquetes python basicos
    if [ $l_flag_setup_1 -eq 0 ]; then

        _install_nodejs_package_group 0
        l_status=$?

    fi

    # Instalar los paquetes python asociados a LSP/DAP, Fixers y Linter basicos
    if [ $l_flag_setup_2 -eq 0 ]; then

        _install_nodejs_package_group 1
        l_status=$?

    fi


    # Instalar los paquetes python otros para development
    if [ $l_flag_setup_3 -eq 0 ]; then

        _install_nodejs_package_group 2
        l_status=$?

    fi

    return 0


}



# Instalar VIM/NeoVIM y luego configurarlo para que sea Editor/IDE.
#  - Crear archivos/folderes de configuración,
#  - Descargar Plugin,
#  - Indexar la documentación de los plugin.
# Parametros de entrada:
#  1> Opción de menu a ejecutar
# Parametros de salida:
#  111> No se cumplio con requesitos obligatorios. Detener el proceso.
#  120> No se almaceno el password para sudo (solo cuando se requiere).
function _setup_vim_environment() {

    #00. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local p_is_vim=0
    if [ "$2" = "1" ]; then
        p_is_vim=1
    fi

    #1. Validar las opciones a usar
    local l_option
    local l_status


    # Instalar el programa 'vim'
    local l_flag_install=1
    # Flag para configurar modo developer (si no usa, se configura el modo basico)
    local l_flag_developer=1
    # Configuración: Crear los archivos de configuración
    local l_flag_setup_1=1
    # Configuración: Descargar los plugins e indexar su documentación
    local l_flag_setup_2=1
    # Configuración: Descargar los plugins sin indexar la documentación
    local l_flag_setup_3=1
    # Indexar la documentación de los plugins existentes
    local l_flag_setup_4=1


    # ¿Instalar el programa VIM/NeoVIM?
    l_option=8
    if [ $p_is_vim -ne 0 ]; then
        l_option=512
    fi

    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_install=0
    fi

    # ¿Configurar como modo developer?
    l_option=16
    if [ $p_is_vim -ne 0 ]; then
        l_option=1024
    fi

    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_developer=0
    fi

    # Configuración: ¿Crear los archivos de configuración?
    l_option=32
    if [ $p_is_vim -ne 0 ]; then
        l_option=2048
    fi

    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_1=0
    fi

    # Configuración: ¿Descargar los plugins e indexar su documentación?
    l_option=64
    if [ $p_is_vim -ne 0 ]; then
        l_option=4096
    fi

    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_2=0
    fi

    # Configuración: ¿Descargar los plugins sin indexar la documentación?
    l_option=128
    if [ $p_is_vim -ne 0 ]; then
        l_option=8192
    fi

    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_3=0
    fi

    # ¿Indexar la documentación de los plugins existentes?
    l_option=256
    if [ $p_is_vim -ne 0 ]; then
        l_option=16384
    fi

    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_4=0
    fi


    # Si no se requiere instalar ni configurar ninguna opcion de VIM/NeoVIM
    if [ $l_flag_install -ne 0 ] && [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ] && [ $l_flag_setup_4 -ne 0 ]; then
        return 0
    fi


    #3. Instalando VIM/NeoVIM
    local l_status
    local l_tag='VIM'
    if [ $p_is_vim -ne 0 ]; then
        l_tag='NeoVIM'
    fi

    local l_aux='modo basico'
    if [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ] && [ $l_flag_setup_4 -ne 0 ]; then
        l_aux='solo instalación'
    elif [ $l_flag_developer -eq 0 ]; then
        l_aux='modo developer'
    fi

    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf '%s > Configuración %b%s%b %b(%s)%b\n' "$l_tag" "$g_color_cian1" "$l_tag" "$g_color_reset" "$g_color_gray1" "$l_aux" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    local l_is_vim_installed=-1   #(-1) No determinado, (0) Instalado, (1) No instalado
    if [ $l_flag_install -eq 0 ]; then

        if [ $p_is_vim -eq 0 ]; then
            install_vim
            l_status=$?
        else
            install_neovim
            l_status=$?
        fi

         #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Se requiere almacenar las credenciales para realizar cambiso con sudo.
        elif [ $l_status -eq 120 ]; then
            return 120
        elif [ $l_status -eq 0 ]; then
            l_is_vim_installed=0
        else
            l_is_vim_installed=1
        fi
    fi


    # Si no se requiere configurar a un VIM/NeoVIM instalado
    if [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ] && [ $l_flag_setup_4 -ne 0 ]; then
        return 0
    fi


    #4. Configuración: Crear los archivos de configuración (No requiere que VIM/NeoVIM este instalado)
    if [ $l_flag_setup_1 -eq 0 ]; then

        # Flag de sobrescribir un symbolic link existente
        local l_flag_overwrite_link=1

        l_option=2
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_overwrite_link=0
        fi

        # Flag de sobrescribir un file existente
        #local l_flag_overwrite_file=1

        #l_option=4
        #if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        #    l_flag_overwrite_file=0
        #fi

        # Crear los archivos de configuracion requiridos
        if [ $p_is_vim -eq 0 ]; then
            _setup_vim_files $l_flag_developer $l_flag_overwrite_link
            #_setup_vim_files $l_flag_developer $l_flag_overwrite_link $l_flag_overwrite_file
            l_status=$?
        else
            _setup_nvim_files $l_flag_developer $l_flag_overwrite_link
            #_setup_nvim_files $l_flag_developer $l_flag_overwrite_link $l_flag_overwrite_file
            l_status=$?
        fi

    fi

    #5. Validar si VIM/NeoVIM esta instalado
    local l_version=''
    if [ $l_is_vim_installed -eq -1 ]; then

        if [ $p_is_vim -eq 0 ]; then
            l_version=$(get_vim_version)
        else
            l_version=$(get_neovim_version)
        fi

        if [ -z "$l_version" ]; then
            l_is_vim_installed=1
        else
            l_is_vim_installed=0
        fi

    fi

    #6. Configuración: Descargar plugins

    # Determinar si se indexa la documentacion considerando
    # > Si se indica que indexar la documentacion y no indexarlo, 'indexar' tiene mayor prioridad.
    # > Si no esta instalado VIM/NeoVIM, no se indexa la documentacion.
    # > Si el runner es root el modo suplantacion del usuario objetivo, no se indexara la documentacion.
    local l_flag_non_index_docs=0    # (0) No indexar la documentacion, (1) Indexar la documentacion

    if [ $l_is_vim_installed -ne 0 ]; then

        if [ $l_flag_setup_2 -eq 0 ]; then
            printf '%s > %bSe omitira la indexacion de la documentación%b de los plugins a instalar debido a que %b%s no esta instalado%b.\n' \
                   "$l_tag" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_tag" "$g_color_reset"
        fi

    else

        if [ $l_flag_setup_2 -eq 0 ] && [ $l_flag_setup_3 -eq 0 ]; then
            printf '%s > %bSe indexara la documentación%b de los plugins a instalar, aun cuando se indique que no se indexe ello.\n' \
                   "$l_tag" "$g_color_gray1" "$g_color_reset"
        fi

        if [ $l_flag_setup_2 -eq 0 ]; then

            #Si el runner es root el modo suplantacion del usuario objetivo
            if [ $g_runner_is_target_user -ne 0 ]; then
                printf '%s > %bSe omitira la indexacion de la documentación%b de los plugins a instalar debido a que no se ejecuta con el usuario "%b%s%b".\n' \
                    "$l_tag" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
            else
                l_flag_non_index_docs=1
            fi
        fi

    fi

    # Descargar los plugins
    if [ $l_flag_setup_2 -eq 0 ] || [ $l_flag_setup_3 -eq 0 ]; then

        if [ $p_is_vim -eq 0 ]; then
            _download_vim_packages 1 $l_flag_developer $l_flag_non_index_docs
            l_status=$?
        else
            _download_vim_packages 0 $l_flag_developer $l_flag_non_index_docs
            l_status=$?
        fi

    fi


    #7. Indexar la documentación de los plugins existentes
    l_status=1

    if [ $l_flag_setup_4 -eq 0 ]; then

        if [ $l_is_vim_installed -ne 0 ]; then

            printf '%s > %bSe omitira la indexacion de la documentación%b de los plugins existentes debido a que %b%s% no esta instalado%b.\n' \
                   "$l_tag" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_tag" "$g_color_reset"

        else

            #Si el runner es root el modo suplantacion del usuario objetivo
            if [ $g_runner_is_target_user -ne 0 ]; then
                printf '%s > %bSe omitira la indexacion de la documentación%b de los plugins existentes debido a que no se ejecuta con el usuario "%b%s%b".\n' \
                    "$l_tag" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
            else

                #Indecar la documentacion de los plugins existentes
                if [ $p_is_vim -eq 0 ]; then
                    _index_doc_of_vim_packages 1
                    l_status=$?
                else
                    _index_doc_of_vim_packages 0
                    l_status=$?
                fi

            fi

        fi

    fi


    #8. Mostrar informacion y recomendaciones de la configuracion de VIM

    # Si solo se descarga plugins, no mostrar el reporte
    if [ $l_flag_setup_2 -eq 0 ] && [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ] && [ $l_flag_setup_4 -ne 0 ]; then
        return 0
    fi

    # Si solo se indexa los plugin existentes, no mostrar el reporte
    if [ $l_flag_setup_4 -eq 0 ] && [ $l_flag_setup_1 -ne 0 ] && [ $l_flag_setup_2 -ne 0 ] && [ $l_flag_setup_3 -ne 0 ]; then
        return 0
    fi

    # En otros casps mostrar el reporte
    if [ $p_is_vim -eq 0 ]; then
        show_vim_config_report 1 $l_flag_developer
        l_status=$?
    else
        show_vim_config_report 0 $l_flag_developer
        l_status=$?
    fi

    return 0


}



# Parametros de entrada:
#  1> Opción de menu a ejecutar
#
function _setup() {


    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi
    g_status_crendential_storage=-1


    #2. La configuracion de Python3
    _setup_python_enviroment $p_opciones
    l_status=$?
    if [ $l_status -eq 111 ]; then
        #No se cumplen las precondiciones obligatorios
        return 111
    elif [ $l_status -eq 120 ]; then
        #No se acepto almacenar las credenciales para usar sudo.
        return 120
    fi


    #3. La configuracion de NodeJS
    _setup_nodejs_enviroment $p_opciones
    l_status=$?
    if [ $l_status -eq 111 ]; then
        #No se cumplen las precondiciones obligatorios
        return 111
    elif [ $l_status -eq 120 ]; then
        #No se acepto almacenar las credenciales para usar sudo.
        return 120
    fi


    #4. La configuracion de VIM
    _setup_vim_environment $p_opciones 0
    l_status=$?
    if [ $l_status -eq 111 ]; then
        #No se cumplen las precondiciones obligatorios
        return 111
    elif [ $l_status -eq 120 ]; then
        #No se acepto almacenar las credenciales para usar sudo.
        return 120
    fi


    #5. La configuracion de NeoVIM
    _setup_vim_environment $p_opciones 1
    l_status=$?
    if [ $l_status -eq 111 ]; then
        #No se cumplen las precondiciones obligatorios
        return 111
    elif [ $l_status -eq 120 ]; then
        #No se acepto almacenar las credenciales para usar sudo.
        return 120
    fi


    #6. Configuracion el SO: Crear enlaces simbolicos y folderes basicos
    _setup_user_profile $p_opciones
    l_status=$?
    if [ $l_status -eq 111 ]; then
        #No se cumplen las precondiciones obligatorios
        return 111
    elif [ $l_status -eq 120 ]; then
        #No se acepto almacenar las credenciales para usar sudo.
        return 120
    fi


    #7. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #    Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

}


function _show_menu_core() {


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"

    printf " (%ba%b) Indexar la documentación de los plugins de %bVIM%b/%bNeoVIM%b existentes %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "16640" "$g_color_reset"
    printf " (%bb%b) %bModo basico%b > Descargar plugins de %bVIM%b/%bNeoVIM%b como editor %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "8320" "$g_color_reset"
    printf " (%bc%b) %bModo basico%b > Descargar plugins de %bVIM%b/%bNeoVIM%b e indexar su documentación %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "4160" "$g_color_reset"
    printf " (%bd%b) %bModo basico%b > Instalar y configurar %bVIM%b como editor basico %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "104" "$g_color_reset"
    printf " (%be%b) %bModo basico%b > Instalar y configurar %bNeoVIM%b como editor basico %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "6656" "$g_color_reset"
    printf " (%bf%b) %bModo basico%b > Instalar y configurar %bVIM%b/%bNeoVIM%b como editor basico %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "6760" "$g_color_reset"
    printf " (%bg%b) %bModo basico%b > Setup %bVIM%b/%bNeoVIM%b y %bProfile%b como editor %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "6761" "$g_color_reset"

    printf " (%bh%b) %bModo developer%b > Descargar plugins de %bVIM%b/%bNeoVIM%b para development %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "9360" "$g_color_reset"
    printf " (%bi%b) %bModo developer%b > Descargar plugins de %bVIM%b/%bNeoVIM%b e indexar su documentación %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "5200" "$g_color_reset"
    printf " (%bj%b) %bModo developer%b > Instalar y configurar %bPython%b para development %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "7864320" "$g_color_reset"
    printf " (%bk%b) %bModo developer%b > Instalar y configurar %bNodeJS%b para development %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "491520" "$g_color_reset"
    printf " (%bl%b) %bModo developer%b > Instalar y configurar %bVIM%b como IDE %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "120" "$g_color_reset"
    printf " (%bm%b) %bModo developer%b > Instalar y configurar %bNeoVIM%b como IDE %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "7680" "$g_color_reset"
    printf " (%bn%b) %bModo developer%b > Instalar y configurar %bVIM%b/%bNeoVIM%b como IDE %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "7800" "$g_color_reset"
    printf " (%bo%b) %bModo developer%b > Instalar y configurar %bVIM%b/%bNeoVIM%b (sin indexar la documentación) como IDE %b(opcion %s)%b\n" "$g_color_green1" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "11960" "$g_color_reset"
    printf " (%bp%b) %bModo developer%b > Setup %bVIM%b/%bNeoVIM%b, %bProfile%b como IDE %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "7801" "$g_color_reset"
    printf " (%br%b) %bModo developer%b > Setup %bPython%b, %bNodeJS%b, %bVIM%b/%bNeoVIM%b y %bProfile%b como IDE %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "8363641" "$g_color_reset"
    printf " (%bs%b) %bModo developer%b > Setup %bPython%b, %bNodeJS%b, %bVIM%b/%bNeoVIM%b (sin indexar la documentación) y %bProfile%b como IDE %b(opcion %s)%b\n" "$g_color_green1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "8367801" "$g_color_reset"

    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=7

    printf "     (%b%${l_max_digits}d%b) Configurar archivos del %bprofile del usuario%b actual\n" "$g_color_green1" "1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) Flag para %boverwrite symbolic link%b en caso de existir\n" "$g_color_green1" "2" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) Flag para %boverwrite file%b en caso de existir\n" "$g_color_green1" "4" "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    printf "     (%b%${l_max_digits}d%b) %bVIM%b    > Instalar el programa '%bvim%b'\n" "$g_color_green1" "8" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bVIM%b    > Flag para configurar el modo %bdeveloper%b %b(si no se usa, se configura el modo basico)%b\n" "$g_color_green1" "16" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bVIM%b    > Configuración: Crear los %barchivos de configuración%b\n" "$g_color_green1" "32" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bVIM%b    > Configuración: %bDescargar los plugins%b e %bindexar%b su documentación\n" "$g_color_green1" "64" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bVIM%b    > Configuración: %bDescargar los plugins%b sin indexar su documentación\n" "$g_color_green1" "128" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bVIM%b    > %bIndexar%b la documentación de los plugins existentes\n" "$g_color_green1" "256" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    printf "     (%b%${l_max_digits}d%b) %bNeoVIM%b > Instalar el programa '%bnvim%b'\n" "$g_color_green1" "512" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNeoVIM%b > Flag para configurar el modo %bdeveloper%b %b(si no se usa, se configura el modo basico)%b\n" "$g_color_green1" "1024" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNeoVIM%b > Configuración: Crear los %barchivos de configuración%b\n" "$g_color_green1" "2048" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNeoVIM%b > Configuración: %bDescargar los plugins%b e %bindexar%b su documentación\n" "$g_color_green1" "4096" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNeoVIM%b > Configuración: %bDescargar los plugins%b sin indexar su documentación\n" "$g_color_green1" "8192" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNeoVIM%b > %bIndexar%b la documentación de los plugins existentes\n" "$g_color_green1" "16384" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    printf "     (%b%${l_max_digits}d%b) %bNodeJS%b > Instalar %bNodeJS%b\n" "$g_color_green1" "32768" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNodeJS%b > Instalar %bpaquetes globales basicos%b:\n" "$g_color_green1" "65536" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNodeJS%b > Instalar %bpaquetes globales sobre LSP/DAP%b:\n" "$g_color_green1" "131072" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bNodeJS%b > Instalar %bpaquetes globales otros%b:\n" "$g_color_green1" "262144" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    printf "     (%b%${l_max_digits}d%b) %bPython%b > Instalar %bPython%b y los gestores 'pip' y 'pipx'\n" "$g_color_green1" "524288" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bPython%b > Instalar %bpaquetes de usuario basicos%b:\n" "$g_color_green1" "1048576" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bPython%b > Instalar %bpaquetes de usuario sobre LSP/DAP%b:\n" "$g_color_green1" "2097152" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bPython%b > Instalar %bpaquetes de usuario otros%b:\n" "$g_color_green1" "4194304" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    print_line '-' $g_max_length_line "$g_color_gray1"

}

function g_main() {

    #1. Pre-requisitos

    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1"
    _show_menu_core

    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -re l_options

        case "$l_options" in

            # Indexar la documentación de los plugins de VIM y NeoVIM existentes
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(    256) VIM    > Indexar la documentación de los plugins existentes
                #(  16384) NeoVIM > Indexar la documentación de los plugins existentes
                _setup 16640
                ;;


            # Modo developer > Descargar plugins de VIM y NeoVIM para development
            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(    128) VIM    > Configuración: Descargar los plugins sin indexar su documentación
                #(   8192) NeoVIM > Configuración: Descargar los plugins sin indexar su documentación
                _setup 8320
                ;;


            # Modo developer > Descargar plugin de VIM y NeoVIM como IDE e indexar su documentación
            c)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(     64) VIM    > Configuración: Descargar los plugins e indexar su documentación
                #(   4096) NeoVIM > Configuración: Descargar los plugins e indexar su documentación
                _setup 4160
                ;;


            # Modo basico > Instalar y configurar VIM como editor basico
            d)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(      8) VIM    > Instalar el programa 'vim'
                #(     32) VIM    > Configuración: Crear los archivos de configuración
                #(     64) VIM    > Configuración: Descargar los plugins e indexar su documentación
                _setup 104
                ;;


            # Modo basico > Instalar y configurar NeoVIM como editor basico
            e)
                l_flag_continue=1

                #(    512) NeoVIM > Instalar el programa 'nvim'
                #(   2048) NeoVIM > Configuración: Crear los archivos de configuración
                #(   4096) NeoVIM > Configuración: Descargar los plugins e indexar su documentación
                print_line '─' $g_max_length_line "$g_color_green1"
                _setup 6656
                ;;

            # Modo basico > Instalar y configurar VIM y NeoVIM como editor basico
            f)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                # Opcion (d)
                # Opcion (e)
                _setup 6760
                ;;

            # Modo basico > Configurar todo el profile en modo basico
            g)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(      1) Configurar archivos del profile del usuario actual
                # Opcion (f)
                _setup 6761
                ;;


            # Modo developer > Descargar plugins de VIM y NeoVIM para development
            h)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(     16) VIM    > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(    128) VIM    > Configuración: Descargar los plugins sin indexar su documentación
                #(   1024) NeoVIM > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(   8192) NeoVIM > Configuración: Descargar los plugins sin indexar su documentación
                _setup 9360
                ;;


            # Modo developer > Descargar plugin de VIM y NeoVIM como IDE e indexar su documentación
            i)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(     16) VIM    > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(     64) VIM    > Configuración: Descargar los plugins e indexar su documentación
                #(   1024) NeoVIM > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(   4096) NeoVIM > Configuración: Descargar los plugins e indexar su documentación
                _setup 5200
                ;;

            # Modo developer > Instalar y configurar Python para development
            j)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #( 524288) Python > Instalar Python y los gestores 'pip' y 'pipx'
                #(1048576) Python > Instalar paquetes de usuario basicos:
                #(2097152) Python > Instalar paquetes de usuario sobre LSP/DAP:
                #(4194304) Python > Instalar paquetes de usuario otros:
                _setup 7864320
                ;;

            # Modo developer > Instalar y configurar NodeJS para development
            k)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(  32768) NodeJS > Instalar NodeJS
                #(  65536) NodeJS > Instalar paquetes globales basicos:
                #( 131072) NodeJS > Instalar paquetes globales sobre LSP/DAP:
                #( 262144) NodeJS > Instalar paquetes globales otros:
                _setup 491520
                ;;

            # Modo developer > Instalar y configurar VIM como IDE
            l)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(      8) VIM    > Instalar el programa 'vim'
                #(     16) VIM    > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(     32) VIM    > Configuración: Crear los archivos de configuración
                #(     64) VIM    > Configuración: Descargar los plugins e indexar su documentación
                _setup 120
                ;;

            # Modo developer > Instalar y configurar NeoVIM como IDE
            m)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(    512) NeoVIM > Instalar el programa 'nvim'
                #(   1024) NeoVIM > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(   2048) NeoVIM > Configuración: Crear los archivos de configuración
                #(   4096) NeoVIM > Configuración: Descargar los plugins e indexar su documentación
                _setup 7680
                ;;

            # Modo developer > Instalar y configurar VIM/NeoVIM como IDE
            n)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                # Opcion (m)
                # Opcion (n)
                _setup 7800
                ;;


            # Modo developer > Instalar y configurar VIM/NeoVIM (sin indexar la documentacion) como IDE
            o)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(      8) VIM    > Instalar el programa 'vim'
                #(     16) VIM    > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(     32) VIM    > Configuración: Crear los archivos de configuración
                #(    128) VIM    > Configuración: Descargar los plugins sin indexar su documentación
                # -> 184

                #(    512) NeoVIM > Instalar el programa 'nvim'
                #(   1024) NeoVIM > Flag para configurar el modo developer (si no se usa, se configura el modo basico)
                #(   2048) NeoVIM > Configuración: Crear los archivos de configuración
                #(   8192) NeoVIM > Configuración: Descargar los plugins sin indexar su documentación
                # -> 11776
                _setup 11960
                ;;


            # Modo developer > Setup VIM/NeoVIM, Profile como IDE
            p)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(      1) Configurar archivos del profile del usuario actual
                # Opcion (n)
                _setup 7801
                ;;


            # Modo developer > Setup Python, NodeJS, VIM/NeoVIM, Profile como IDE
            r)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                # Opcion (j)
                # Opcion (k)
                # Opcion (p)
                _setup 8363641
                ;;


            # Modo developer > Setup Python, NodeJS, VIM/NeoVIM (sin indexar la documentacíon), Profile como IDE
            s)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"

                #(      1) Configurar archivos del profile del usuario actual
                # Opcion (j)
                # Opcion (k)
                # Opcion (o)
                _setup 8367801
                ;;



            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"
                ;;


            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1"
                    _setup $l_options
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_gray1"
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1"
                ;;
        esac

    done

}

g_usage() {

    printf 'Usage:\n'
    printf '  > %bConfigurando el profile del usuario/VIM/NeoVIM escogidos del menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/04_install_profile.bash\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/04_install_profile.bash 0 TARGET_HOME_PATH REPO_NAME\n%b' "$g_color_yellow1" \
           "$g_shell_path" "$g_color_reset"
    printf '  > %bConfigurando el profile del usuario/VIM/NeoVIM segun un grupo de opciones de menú indicados%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/04_install_profile.bash CALLING_TYPE MENU-OPTIONS TARGET_HOME_PATH REPO_NAME\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/04_install_profile.bash CALLING_TYPE MENU-OPTIONS TARGET_HOME_PATH REPO_NAME SUDO-STORAGE-OPTIONS\n\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bTARGET_HOME_PATH %bRuta base donde el home del usuario OBJETIVO al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio "g_repo_name".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bREPO_NAME %bNombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario. Este valor se obtendra segun orden prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si ninguno de los anteriores se establece, se usara el valor ".files".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bCALLING_TYPE%b Es 0 si se muestra un menu, caso contrario es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n\n' \
           "$g_color_gray1" "$g_color_reset"


}



#}}}



#------------------------------------------------------------------------------------------------------------------
#> Logica principal del script {{{
#------------------------------------------------------------------------------------------------------------------

#1. Variables de los argumentos del script

#Parametros (argumentos) basicos del script
gp_uninstall=1          #(0) Para instalar/actualizar
                        #(1) Para desintalar

#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo    - configurar un conjunto de opciones del menú
                        #(2) Ejecución sin el menu de opciones, no-interactivo - configurar un conjunto de opciones del menú


#Argumento 1: el modo de ejecución del script
if [ -z "$1" ]; then
    gp_type_calling=0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
else
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi

#printf 'Parametro 1: %s\n' "$1"
#printf 'Parametro 2: %s\n' "$2"
#printf 'Parametro 3: %s\n' "$3"
#printf 'Parametro 4: %s\n' "$4"
#printf 'Parametro 5: %s\n' "$5"
#printf 'Parametro 6: %s\n' "$6"
#printf 'Parametro 7: %s\n' "$7"
#printf 'Parametro 8: %s\n' "$8"
#printf 'Parametro 9: %s\n' "$9"



#2. Variables globales cuyos valor puede ser modificados el usuario

# Ruta del home del usuario OBJETIVO al cual se configurara su profile y donde esta el repositorio git.
# Este valor se obtendra segun orden prioridad:
# - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
# - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
# - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
g_targethome_path=''

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al home de usuario OBJETIVO (al cual se desea configurar el profile del usuario).
# Este valor se obtendra segun orden prioridad:
# - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
# - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se usara el valor '.files'.
g_repo_name=''

# Definir el tipo de profile del shell del usuario que se va a configurar (usando '04_install_profile.bash').
# Su valores son:
#  > 0 (Profile de un shell local)
#    > El shell se ejecuta directamente en un emulador de terminal GUI (usa GUI Desktop) por lo cual tiene acceso a
#      recursos como: clipboard, dispostivos de hardware como tarjeta de video, tarjeta de sonido, etc.
#      Puede ser:
#      > Un equipo local con GUI Desktop.
#      > Un equipo remoto pero que se accede usando su GUI Desktop.
#      > Una distribucion WSL2 es una VM linux especial que esta diseñada para acceso local desde su Windows, que se
#        integra con el emulador de terminal GUI de Windows como local y con acceso al clipboard de Windows.
#  > 1 (Profile de un shell remoto donde se es owner)
#    > Por ejemplo, una VM accedido por comando ssh, cuyo owner soy yo.
#  > 2 (Profile de un shell remote donde no se es ownwer)
#    > Por ejemplo, una VM accedido por comando ssh, cuyo owner NO soy yo.
# Si no se define el valor por defecto es '0' (Local).
# Actualmente, es usado para definir valores por defecto en algunos archivos de configuracion (modificables) del profile:
#  > El tema usado por 'oh-my-posh': '~/.files/etc/oh-my-posh/default_settings.json'
#  > El archivo de parametros usados por el profile del usuario: '~/.profile.config'
g_profile_type=0

#Obtener los parametros del archivos de configuración
if [ -f "${g_shell_path}/bash/bin/linuxsetup/.setup_config.bash" ]; then

    #Obtener los valores por defecto de las variables
    . ${g_shell_path}/bash/bin/linuxsetup/.setup_config.bash

    #Corregir algunos valores
    #...
fi



#3. Variables globales cuyos valor son AUTOGENERADOS internamente por el script

#Usuario OBJETIVO al cual se desa configurar su profile. Su valor es calcuado por 'get_targethome_info'.
g_targethome_owner=''

#Grupo de acceso que tiene el home del usuario OBJETIVO (al cual se desea configurar su profile). Su valor es calcuado por 'get_targethome_info'.
g_targethome_group=''

#Ruta base del respositorio git del usuario donde se instalar el profile del usuario. Su valor es calculado por 'get_targethome_info'.
g_repo_path=''

#Flag que determina si el usuario runner (el usuario que ejecuta este script de instalación) es el usuario objetivo o no.
#Su valor es calculado por 'get_targethome_info'.
# - Si es '0', el runner es el usuario objetivo (onwer del "target home").
# - Si no es '0', el runner es NO es usuario objetivo, SOLO puede ser el usuario root.
#   Este caso, el root realizará la configuracion requerida para el usuario objetivo (usando sudo), nunca realizara configuración para el propio usuario root.
g_runner_is_target_user=0


#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1

#Si la credenciales de sudo es abierto externamente.
#  1 - No se abrio externamente
#  0 - Se abrio externamente (solo se puede dar en una ejecución no-interactiva)
g_is_credential_storage_externally=1




#4. LOGICA: Configuración del profile
_g_result=0
_g_status=0


#4.1. Mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Parametros usados por el script:
    # 1> Tipo de configuración: 0 (instalación con un menu interactivo).
    # 2> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
    #    - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
    # 3> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #    Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se usara el valor '.files'.


    #Calcular el valor efectivo de 'g_repo_name'.
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_repo_name="$3"
    fi

    if [ -z "$g_repo_name" ]; then
        g_repo_name='.files'
    fi

    #Obtener los valores efectivo de la variable 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group'
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_targethome_path="$2"
    fi

    get_targethome_info "$g_repo_name" "$g_targethome_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        exit 111
    fi

    #Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info')
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    fulfill_preconditions 0 1 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_main
    else
        _g_result=111
    fi

#4.2. No mostrar el menu, la opcion del menu a ejecutar se envia como parametro
else

    #Parametros usados por el script:
    # 1> Tipo de configuración: 1/2 (instalación sin un menu interactivo/no-interactivo).
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
    #    - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
    # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #    Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se usara el valor '.files'.
    # 5> El estado de la credencial almacenada para el sudo.
    _gp_menu_options=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        _gp_menu_options=$2
    else
        echo "Parametro 2 \"$2\" debe ser una opción valida."
        exit 110
    fi

    if [ $_gp_menu_options -le 0 ]; then
        echo "Parametro 2 \"$2\" debe ser un entero positivo."
        exit 110
    fi

    if [[ "$5" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$5

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi


    #Calcular el valor efectivo de 'g_repo_name'.
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_repo_name="$4"
    fi

    if [ -z "$g_repo_name" ]; then
        g_repo_name='.files'
    fi

    #Obtener los valores efectivo de la variable 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group'
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_targethome_path="$3"
    fi

    get_targethome_info "$g_repo_name" "$g_targethome_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        exit 111
    fi


    #Validar los requisitos
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info')
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    fulfill_preconditions 1 1 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        _setup $_gp_menu_options
        _g_status=$?

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            _g_result=111
        #Informar si se nego almacenar las credencial cuando es requirido
        elif [ $_g_status -eq 120 ]; then
            _g_result=120
        #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
        elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
            _g_result=119
        fi
    else
        _g_result=111
    fi

fi


exit $_g_result


#}}}
