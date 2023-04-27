#!/bin/bash


#Colores principales usados para presentar información (menu,...)
g_color_opaque="\x1b[90m"
g_color_reset="\x1b[0m"
g_color_title="\x1b[32m"
g_color_subtitle="\x1b[36m"
g_color_info="\x1b[33m"
g_color_warning="\x1b[31m"

#ID de los repositorios y sus rutas bases
declare -A gA_repositories=(
        ['bat']='sharkdp/bat'
        ['ripgrep']='BurntSushi/ripgrep'
        ['xsv']='BurntSushi/xsv'
        ['delta']='dandavison/delta'
        ['fzf']='junegunn/fzf'
        ['jq']='stedolan/jq'
        ['yq']='mikefarah/yq'
        ['less']='jftuga/less-Windows'
        ['fd']='sharkdp/fd'
        ['oh-my-posh']='JanDeDobbeleer/oh-my-posh'
        ['kubectl']=''
        ['helm']='helm/helm'
        ['kustomize']='kubernetes-sigs/kustomize'
        ['operator-sdk']='operator-framework/operator-sdk'
        ['neovim']='neovim/neovim'
        ['k0s']='k0sproject/k0s'
        ['nerd-fonts']='ryanoasis/nerd-fonts'
        ['powershell']='PowerShell/PowerShell'
        ['roslyn']='OmniSharp/omnisharp-roslyn'
        ['netcoredbg']='Samsung/netcoredbg'
        ['go']='golang'
        ['cmake']='Kitware/CMake'
        ['ninja']='ninja-build/ninja'
        ['clangd']='clangd/clangd'
        ['rust-analyzer']='rust-lang/rust-analyzer'
        ['graalvm']='graalvm/graalvm-ce-builds'
        ['jdtls']='jdtls'
        ['runc']='opencontainers/runc'
        ['cni-plugins']='containernetworking/plugins'
        ['rootlesskit']='rootless-containers/rootlesskit'
        ['slirp4netns']='rootless-containers/slirp4netns'
        ['containerd']='containerd/containerd'
        ['buildkit']='moby/buildkit'
        ['nerdctl']='containerd/nerdctl'
        ['dive']='wagoodman/dive'
    )


#Menu dinamico: Titulos de las opciones del menú.
declare -a ga_menu_options_title=(
    "Los repositorios basicos"
    "El editor 'NeoVim'"
    "Las fuentes 'Nerd Fonts'"
    "Shell 'Powershell Core'"
    "Container Runtime 'ContainerD''"
    "Tools para 'ContainerD'"
    "Tools para cualquier Container Runtime"
    "Tools para Kubernates"
    "Implementación de Kubernates 'K0S'"
    "RTE de 'Go'"
    "RTE 'GraalVM CE'"
    "LSP y DAP server de .Net"
    "LSP y building tools de C/C++"
    "LSP server de Rust"
    "LSP y DAP server de Java"
    )

#Menu dinamico: Repositorios de programas asociados asociados a una opciones del menu.
#Notas:
#  > En la opción de 'ContainerD', se deberia incluir opcionalmente 'bypass4netns' pero su repo no presenta el binario.
#    El binario se puede encontrar en nerdctl-full.
declare -a ga_menu_options_repos=(
    "bat,ripgrep,xsv,delta,fzf,jq,yq,less,fd,oh-my-posh"
    "neovim"
    "nerd-fonts"
    "powershell"
    "runc,cni-plugins,rootlesskit,slirp4netns,containerd"
    "cni-plugins,nerdctl"
    "runc,buildkit,dive"
    "kubectl,kustomize,helm,operator-sdk"
    "k0s"
    "go"
    "graalvm"
    "roslyn,netcoredbg"
    "clangd,cmake,ninja"
    "rust-analyzer"
    "jdtls"
    )


#Parametros:
# 1 > Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
_get_length_menu_option() {
    
    local p_offset_option_index=$1

    local l_nbr_options=${#ga_menu_options_repos[@]}
    local l_max_digits_aux="$((1 << (p_offset_option_index + l_nbr_options)))"

    return ${#l_max_digits_aux}
}

#Parametros:
# 1 > Etiqueta que aparece al constado del opción ('Instalar o actualizar' o 'Desintalar')
# 2 > Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
# 3 > Numero maximo de digitos de una opción del menu personalizado.
_show_dynamic_menu() {

    #Argumentos
    local p_option_tag=$1
    local p_offset_option_index=$2
    local p_max_digits=$3


    #Recorreger las opciones dinamicas del menu personalizado
    local l_i=0
    local l_j=0
    local IFS=','
    local la_repos
    local l_option_value
    local l_aux
    local l_n
    local l_repo_names
    local l_repo_id


    for((l_i=0; l_i < ${#ga_menu_options_repos[@]}; l_i++)); do

        #Si no tiene repositorios a instalar, omitirlos
        l_option_value=$((1 << (p_offset_option_index + l_i)))

        l_aux="${ga_menu_options_repos[$l_i]}"
        #if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
        #    printf "     (%b%0${p_max_digits}d%b) %s\n" "$g_color_subtitle" "$l_option_value" "$g_color_reset" "${ga_menu_options_title[$l_i]}"
        #    continue
        #fi

        #Obtener los repositorios a configurar
        IFS=','
        la_repos=(${l_aux})
        IFS=$' \t\n'

        printf "     (%b%0${p_max_digits}d%b) %s \"%b%s%b\": " "$g_color_subtitle" "$l_option_value" "$g_color_reset" \
               "$p_option_tag" "$g_color_subtitle" "${ga_menu_options_title[$l_i]}" "$g_color_reset"

        l_n=${#la_repos[@]}
        if [ $l_n -gt 3 ]; then
            printf '\n'
            l_aux=$((8 + p_max_digits))
            printf ' %.0s' $(seq $l_aux)
        fi

        l_repo_names=''
        for((l_j=0; l_j < ${l_n}; l_j++)); do

            l_repo_id="${la_repos[${l_j}]}"
            l_aux="${gA_repositories[${l_repo_id}]}"
            if [ -z "$l_aux" ]; then
                l_aux="$l_repo_id"
            fi

            if [ $l_j -eq 0 ]; then
                #l_repo_names="'${l_aux}'" 
                l_repo_names="'${g_color_opaque}${l_aux}${g_color_reset}'" 
            else
                #l_repo_names="${l_repo_names}, '${l_aux}'"
                l_repo_names="${l_repo_names}, '${g_color_opaque}${l_aux}${g_color_reset}'"
            fi

        done

        printf '%b\n' "$l_repo_names"

    done


}





