
#Variables globales externo usuados:

# Package Python que se pueden instalar.
# - El key, es el nemonico del paquete usado en la busqueda para identificar si el paquete esta instalado o no.
# - El value, es el nombre del paquete a instalar.
$gd_python_pckgs_name= @{
    'jtbl' = 'jtbl'
    'pynvim' = 'pynvim'
    'urlscan' = 'urlscan'
    'basedpyright' = 'basedpyright'
    'pyright' = 'pyright'
    'ansible-lint' = 'ansible-lint'
    'ansible' = 'ansible'
    'debugpy' = 'debugpy'
    'compiledb' = 'compiledb'
}

# Grupo de paquete python usado para ordenar los paquetes en grupos de instalacion diferentes.
# (0) Paquete basico
# (1) Paquete sobre LSP, DAP, Linter y Fixers (incluyendo formatter).
# (2) Otros paquetes usandos para development (valor por defecto).
$gd_python_pckgs_group= @{
    'jtbl' = 0
    'pynvim' = 0
    'urlscan' = 0
    'basedpyright' = 1
    'pyright' = 1
    'ansible-lint' = 1
    'debugpy' = 1
    'ansible' = 2
    'compiledb' = 2
}

# Descripcion del paquete que se mostrara en lo logs
$gd_python_pckgs_description= @{
    'jtbl' = 'CLI para mostrar arreglos JSON en forma tabular'
    'pynvim' = 'Libreria para integrar plugin en Python con NeoVIM'
    'urlscan' = 'CLI para buscar URLs en un bloque de texto'
    'basedpyright' = 'LSP server para Python'
    'pyright' = 'LSP server para Ptyhon'
    'ansible-lint' = 'Linter usado para arcivos Ansible'
    'ansible' = 'Grupo de paquetes completo para Ansible'
    'debugpy' = 'DAP server para Python'
    'compiledb' = 'CLI usado para ... en CMake'
    'rope' = 'Libreria usado por Python para ...'
    }

# Identifica si el paquete es una libreria o un programa ejecutable (CLI tools).
# (0) Es una libreria (valor por defecto)
# (1) Es un programa ejecutable (CLI tools) cuyas dependencias no son CLI tools.
# (2) Es un programa ejecutable (CLI tools) que tiene dependecias que son CLI tools.
$gd_python_pckgs_type= @{
    'jtbl' = 1
    'urlscan' = 1
    'basedpyright' = 1
    'pyright' = 1
    'ansible-lint' = 1
    'compiledb' = 1
    'ansible' = 2
    }

# Opciones especiales que se usara durante la instalación del paquete.
# Su valor por defecto es '0'. Se puede colocar la suma logica de todas las opciones que se desea especificar.
# (0) Por defecto (se dejan las opciones por defecto)
# (1) Incluir
# (2) Incluir
# (4) Incluir
#$gd_python_pckgs_options= @{
#    'ansible' = 0
#    }


# Package NodeJS que se pueden instalar.
# - El key, es el nemonico del paquete usado en la busqueda para identificar si el paquete esta instalado o no.
# - El value, es el nombre del paquete a instalar.
$gd_nodejs_pckgs_name= @{
    'neovim' = 'neovim'
    'tree-sitter-cli' = 'tree-sitter-cli'
    'prettier' = 'prettier'
    'bash-language-server' = 'bash-language-server'
    'vim-language-server' = 'vim-language-server'
    '@ansible/ansible-language-server' = '@ansible/ansible-language-server'
    'yaml-language-server' = 'yaml-language-server'
    'vscode-langservers-extracted' = 'vscode-langservers-extracted'
    'dockerfile-language-server-nodejs' = 'dockerfile-language-server-nodejs'
    '@mistweaverco/kulala-ls' = '@mistweaverco/kulala-ls'
    '@mistweaverco/kulala-fmt' = '@mistweaverco/kulala-fmt'
}

# Grupo de paquete nodejs usado para ordenar los paquetes en grupos de instalacion diferentes.
# (0) Paquete basico
# (1) Paquete sobre LSP, DAP, Linter y Fixers (incluyendo formatter).
# (2) Otros paquetes usandos para development (valor por defecto).
$gd_nodejs_pckgs_group= @{
    'neovim' = 0
    'tree-sitter-cli' = 0
    'prettier' = 0
    'bash-language-server' = 1
    'vim-language-server' = 1
    '@ansible/ansible-language-server' = 1
    'yaml-language-server' = 1
    'vscode-langservers-extracted' = 1
    'dockerfile-language-server-nodejs' = 1
    '@mistweaverco/kulala-ls' = 1
    '@mistweaverco/kulala-fmt' = 1
    }

# Descripcion del paquete que se mostrara en lo logs
$gd_nodejs_pckgs_description = @{
    'neovim' = 'CLI para integrar plugin en NodeJS con Python'
    'tree-sitter-cli' = 'CLI para soporte a TreeSitter'
    'prettier' = 'Formatter de varios archivos'
    'bash-language-server' = 'LSP server para Bash'
    'vim-language-server' = 'LSP server para VimScript'
    '@ansible/ansible-language-server' = 'LSP server para archivos Ansible'
    'yaml-language-server' = 'LSP server para archivos YAML'
    'vscode-langservers-extracted' = 'LSP server para archivos JSON, HTML, CSS'
    'dockerfile-language-server-nodejs' = 'LSP server para archivos Dockerfile'
    '@mistweaverco/kulala-ls' = 'LSP server para archivos .http de kulala.nvim'
    '@mistweaverco/kulala-fmt' = 'Formatter de archivos .http de kulala.nvim'
    }

# Identifica si el paquete es una libreria o un programa ejecutable (CLI tools).
# (0) Es una libreria (valor por defecto)
# (1) Es un programa ejecutable (CLI tools)
# (2) Es un programa ejecutable (CLI tools) que tiene dependecias que son CLI tools.
#$gd_nodejs_pckgs_type= @{
#    '' = 1
#    '' = 2
#    }

# Opciones especiales que se usara durante la instalación del paquete.
# Su valor por defecto es '0'. Se puede colocar la suma logica de todas las opciones que se desea especificar.
# (0) Por defecto (se dejan las opciones por defecto)
# (1) Incluir
# (2) Incluir
# (4) Incluir
#$gd_nodejs_pckgs_options= @{
#    '' = 1
#    }






# Valida los requisitos para instalar treesitter (https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support)
# Parametros de salida (valores de retorno):
#  0 > Se tiene lo necesario para ejectuar nvim-treesitter
#  1 > No se tiene lo necesario para ejecutar nvim=treesiter
#function _validate_treesitter_requirements() {
#
#    local l_tag="$1"
#
#    local l_version
#    local l_status
#
#    # Requisitos para descargar paquetes (fuentes) de los parser treesitter
#    l_version=$(curl --version 2> /dev/null)
#    l_status=$?
#    if [ $l_status -ne 0 ]; then
#        printf '%s > El comando %b%s%b es requerido para descargar "%b%s%b" pero %bNO esta instalado%b.\n' "$l_tag" \
#               "$g_color_yellow1" "curl" "$g_color_reset" "$g_color_gray1" "treesiter parser" "$g_color_reset" "$g_color_yellow1" "$g_color_reset"
#    else
#        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
#        printf '%s > El comando %b%s%b usado para descargar "%b%s%b" esta instalado (%b%s%b).\n' "$l_tag" \
#               "$g_color_gray1" "curl" "$g_color_reset" "$g_color_gray1" "treesiter parser" "$g_color_reset" "$g_color_gray1" "$l_version" "$g_color_reset"
#    fi
#
#    l_version=$(tar --version 2> /dev/null)
#    l_status=$?
#    if [ $l_status -ne 0 ]; then
#        printf '%s > El comando %b%s%b es requerido para descomprimir "%b%s%b" pero %bNO esta instalado%b.\n' "$l_tag" \
#               "$g_color_yellow1" "tar" "$g_color_reset" "$g_color_gray1" "treesiter parser" "$g_color_reset" "$g_color_yellow1" "$g_color_reset"
#    else
#        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
#        printf '%s > El comando %b%s%b usado para descomprimir "%b%s%b" esta instalado (%b%s%b).\n' "$l_tag" \
#               "$g_color_gray1" "tar" "$g_color_reset" "$g_color_gray1" "treesiter parser" "$g_color_reset" "$g_color_gray1" "$l_version" "$g_color_reset"
#    fi
#
#    # Requisitos para compilar del paquetes (fuentes) de los parser treesitter
#    l_version=$(gcc --version 2> /dev/null)
#    l_status=$?
#
#    if [ $l_status -ne 0 ]; then
#
#        l_version=$(clang --version 2> /dev/null)
#        l_status=$?
#        if [ $l_status -ne 0 ]; then
#            printf '%s > El compilador %b%s%b ni el compilador %b%s%b, que son requeridos para compilar "%b%s%b", %bNO esta instalado%b.\n' "$l_tag" \
#                   "$g_color_yellow1" "gcc" "$g_color_reset" "$g_color_yellow1" "clang" "$g_color_reset" "$g_color_gray1" "treesiter parser" "$g_color_reset" \
#                   "$g_color_gray1" "$g_color_reset"
#        else
#            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
#            printf '%s > El compilador %b%s%b usado para compilar "%b%s%b" esta instalado (%b%s%b).\n' "$l_tag" \
#                   "$g_color_gray1" "clang" "$g_color_reset" "$g_color_gray1" "treesiter parser" "$g_color_reset" "$g_color_gray1" "$l_version" "$g_color_reset"
#        fi
#
#    else
#
#        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
#        printf '%s > El compilador %b%s%b usado para compilar "%b%s%b" esta instalado (%b%s%b).\n' "$l_tag" \
#               "$g_color_gray1" "gcc" "$g_color_reset" "$g_color_gray1" "treesiter parser" "$g_color_reset" "$g_color_gray1" "$l_version" "$g_color_reset"
#
#    fi
#
#    return 0
#
#}


# Parametros de entrada:
#  1> Flag '0' si es NeoVIM.
#  2> Flag configurar como Developer (si es '0'. Si no se especifica es -1)
# Parametros de salida:
#  > Valores de retorno
#      00> Se instalo correctamente.
#      01> No se instalo correctamente.
function show_vim_config_report($p_is_neovim, $p_flag_developer) {

    ##1. Argumentos
    $l_tag="VIM"
    $l_empty_space='   '

    if ($p_is_neovim -eq 0) {
        $l_tag="NeoVIM"
        $l_empty_space='     '
    }


    $l_flag_developer=-1
    if ( $p_flag_developer -eq 0 ) {
        $l_flag_developer=0
    } elseif ( $p_flag_developer -eq 1 ) {
        $l_flag_developer=1
    }

    Write-Host "Reporte de ${l_tag} (${l_flag_developer}) ..."

    #printf '\n'
    #printf '%s > %bResumen%b:\n' "$l_tag" "$g_color_cian1" "$g_color_reset"

    ##2. Validar si esta instalado VIM/NeoVIM
    #local l_status
    #local l_version

    #if [ $p_is_neovim -eq 0 ]; then

    #    l_version=$(get_neovim_version "")
    #    l_status=$?    #Retorna 3 si no esta instalado

    #    #Si no esta instalado NeoVIM
    #    if [ $l_status -eq 3 ]; then
    #        printf '%s > %s %bNO esta instalado%b.\n' "$l_tag" "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    else
    #        printf '%s > %s esta instalado (version: %b%s%b).\n' "$l_tag" "$l_tag" "$g_color_gray1" "$l_version" "$g_color_reset"
    #    fi

    #else

    #    l_version=$(get_vim_version)
    #    l_status=$?    #Retorna 3 si no esta instalado

    #    #Si no esta instalado VIM
    #    if [ -z "$l_version" ]; then
    #        printf '%s > %s %bNO esta instalado%b.\n' "$l_tag" "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    else
    #        printf '%s > %s esta instalado (version: %b%s%b).\n' "$l_tag" "$l_tag" "$g_color_gray1" "$l_version" "$g_color_reset"
    #    fi

    #fi


    ##3. Validar si se ha creado los archivos de configuración para VIM/NeoVIM
    #check_vim_profile $p_is_neovim
    #l_status=$?

    ##printf 'l_status=%s, p_flag_developer=%s\n' "$l_status" "$p_flag_developer"

    ## No esta configura sus archivos, No configurarlo.
    #if [ $l_status -eq 2 ]; then

    #    printf '%s > NO se han creado los %barchivos de configuración%b de %s.\n' "$l_tag" "$g_color_gray1" "$g_color_reset" "$l_tag"

    ## Esta configura solo como Editor.
    #elif [ $l_status -eq 0 ]; then

    #    if [ $p_flag_developer -eq 0 ]; then
    #        printf '%s > %bERROR%b: Los %barchivos de configuración%b de %s estan creados son de modo basico pero indica que debe ser como developer.\n' \
    #               "$l_tag" "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #        return 1
    #    elif [ $p_flag_developer -eq 1 ]; then
    #        printf '%s > Los %barchivos de configuración%b de %b esta configurado en modo basico.\n' "$l_tag" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #    else
    #        p_flag_developer=1
    #    fi

    ## Esta configura solo como Developer.
    #else

    #    if [ $p_flag_developer -eq 1 ]; then
    #        printf '%s > %bERROR%b: Los %barchivos de configuración%b de %s estan creados son de modo developer pero indica que debe ser como editor.\n' \
    #               "$l_tag" "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #        return 1
    #    elif [ $p_flag_developer -eq 0 ]; then
    #        printf '%s > Los %barchivos de configuración%b de %b esta configurado en modo developer.\n' "$l_tag" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #    else
    #        p_flag_developer=0
    #    fi

    #fi


    ##4. Validar si los plugin estan desacargados
    #check_vim_plugins 1
    #l_status=$?

    ## No esta configura sus archivos, No configurarlo.
    #if [ $l_status -eq 2 ]; then

    #    printf '%s > NO se estan instalados los %plugin%b requeridos por %s.\n' "$l_tag" "$g_color_gray1" "$g_color_reset" "$l_tag"

    ## Esta configura solo como Editor.
    #elif [ $l_status -eq 0 ]; then

    #    if [ $p_flag_developer -eq 0 ]; then
    #        printf '%s > %bERROR%b: Los %bplugins%b de %s estan de modo basico pero indica que debe ser como modo developer.\n' \
    #               "$l_tag" "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #        return 1
    #    else
    #        printf '%s > Los %bplugins%b de %s esta configurado en modo basico.\n' "$l_tag" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #    fi

    ## Esta configura solo como Developer.
    #else

    #    if [ $p_flag_developer -ne 0 ]; then
    #        printf '%s > %bERROR%b: Los %bplugins%b de %s estan de modo developer pero indica que debe ser como modo editor.\n' \
    #               "$l_tag" "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #        return 1
    #    else
    #        printf '%s > Los %bplugins%b de %s esta configurado en modo developer.\n' "$l_tag" "$g_color_gray1" "$g_color_reset" "$l_tag"
    #    fi

    #fi

    ##5. Si es NeoVIM, validar si se tiene lo minimo para usar 'Treesitter Parser'
    #if [ $p_is_neovim -eq 0 ]; then

    #    printf '%s > Requisitos minimos para generar %bTreesitter Parser%b.\n' "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    _validate_treesitter_requirements "$l_empty_space"

    #fi


    ##5. Si esta en el modo basico de VIM/NeoVIM
    #if [ $p_flag_developer -ne 0  ]; then

    #    # Mostrar ....
    #    return 0
    #fi


    ##6. Si esta en el modo developer > Validar que esta NodeJS instalado
    #l_version=$(get_nodejs_version "")
    #l_status=$?    #Retorna 3 si no esta instalado

    ##Si no esta instalado NodeJS
    #if [ -z "$l_version" ]; then

    #    printf '%s > NodeJS %bNO esta instalado%b.\n' "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    if [ $p_is_neovim -eq 0 ]; then
    #        printf '%s > %s en modo developer, algunos servidores LSP, %brequieren que NodeJS este instalado%b.\n' "$l_empty_space" \
    #               "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    else
    #        printf '%s > %s en modo developer, CoC y algunos servidores LSP, %brequieren que NodeJS este instalado%b.\n' "$l_empty_space" \
    #               "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    fi

    #else
    #    printf '%s > NodeJS esta instalado (%b%s%b).\n' "$l_tag" "$g_color_gray1" "$l_version" "$g_color_reset"
    #fi

    ##7. Si esta en el modo developer > Validar que esta NodeJS instalado
    #local l_aux
    #l_aux=$(get_python_versions)
    #l_status=$?
    #local -a la_versions=(${l_aux})

    ##Si no esta instalado NodeJS
    #if [ $l_status -eq 0 ]; then

    #    printf '%s > Python %bNO esta instalado%b.\n' "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    if [ $p_is_neovim -eq 0 ]; then
    #        printf '%s > %s en modo developer, el motor de snippets, %brequieren que Python este instalado%b.\n' "$l_empty_space" \
    #               "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    else
    #        printf '%s > %s en modo developer, el motor de snippets y servidores LSP, %brequieren que Python este instalado%b.\n' "$l_empty_space" \
    #               "$l_tag" "$g_color_gray1" "$g_color_reset"
    #    fi

    #else
    #    printf '%s > Python esta instalado (%b%s%b).\n' "$l_tag" "$g_color_gray1" "${la_versions[0]}" "$g_color_reset"
    #fi



    ##9. Recomendaciones de uso
    #printf '\n'
    #printf '%s > %bRecomendaciones de uso:%b\n' "$l_tag" "$g_color_cian1" "$g_color_reset"


    ##Mostrar la Recomendaciones
    #if [ $p_is_neovim -ne 0  ]; then

    #    printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_cian1" "$g_color_reset"
    #    printf '    > Se recomienda que configure su IDE CoC segun su necesidad:\n'

    #else

    #    printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
    #    printf '    > Si desea usar CoC, use: "%bUSE_COC=1 nvim%b"\n' "$g_color_cian1" "$g_color_reset"
    #    printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_cian1" "$g_color_reset"

    #    printf '  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:\n'

    #fi

    #return 0

}
