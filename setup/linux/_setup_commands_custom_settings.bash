#!/bin/bash

#ID de los repositorios y sus rutas bases
#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
#  - Cada repositorio tiene un ID interno del un repositorios y un identifificador realizar: 
#    ['internal-id']='external-id'
#  - Por ejemplo para el repositorio GitHub 'stedolan/jq', el item se tendria:
#    ['jq']='stedolan/jq'
gA_packages=(
        ['bat']='sharkdp/bat'
        ['ripgrep']='BurntSushi/ripgrep'
        ['xsv']='BurntSushi/xsv'
        ['delta']='dandavison/delta'
        ['fzf']='junegunn/fzf'
        ['jq']='stedolan/jq'
        ['yq']='mikefarah/yq'
        ['less']='jftuga/less-Windows'
        ['fd']='sharkdp/fd'
        ['step']='smallstep/cli'
        ['jwt']='mike-engel/jwt-cli'
        ['butane']='coreos/butane'
        ['grpcurl']='fullstorydev/grpcurl'
        ['evans']='ktr0731/evans'
        ['protoc']='protocolbuffers/protobuf'
        ['oh-my-posh']='JanDeDobbeleer/oh-my-posh'
        ['neovim']='neovim/neovim'
        ['kubectl']=''
        ['pgo']='CrunchyData/postgres-operator-client'
        ['helm']='helm/helm'
        ['kustomize']='kubernetes-sigs/kustomize'
        ['operator-sdk']='operator-framework/operator-sdk'
        ['k0s']='k0sproject/k0s'
        ['3scale-toolbox']='3scale-labs/3scale_toolbox_packaging'
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
        ['nodejs']=''
        ['jdtls']='jdtls'
        ['runc']='opencontainers/runc'
        ['crun']='containers/crun'
        ['fuse-overlayfs']='containers/fuse-overlayfs'
        ['cni-plugins']='containernetworking/plugins'
        ['rootlesskit']='rootless-containers/rootlesskit'
        ['slirp4netns']='rootless-containers/slirp4netns'
        ['containerd']='containerd/containerd'
        ['buildkit']='moby/buildkit'
        ['nerdctl']='containerd/nerdctl'
        ['dive']='wagoodman/dive'
    )

#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
ga_menu_options_title=(
    "Los repositorios basicos"
    "El editor 'NeoVim'"
    "Las fuentes 'Nerd Fonts'"
    "Shell 'Powershell Core'"
    "Tools para gRPC"
    "LL Container Runtine, comandos root-less, CNI plugins"
    "HL Container Runtime 'ContainerD', BuildKit y NerdCtl"
    "Tools para gestionar containers"
    "Tools para Kubernates"
    "Implementación de Kubernates 'K0S'"
    "RTE de 'Go'"
    "RTE 'GraalVM CE' (Java)"
    "RTE Node.JS"
    "LSP y DAP server de .Net"
    "LSP y building tools de C/C++"
    "LSP server de Rust"
    "LSP y DAP server de Java"
    )

#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Repositorios de programas asociados asociados a una opciones del menu.
#  - Cada entrada define un opcion de menú. 
#  - Su valor es un cadena con ID de repositorios separados por comas.
#Notas:
#  > En la opción de 'ContainerD', se deberia incluir opcionalmente 'bypass4netns' pero su repo no presenta el binario.
#    El binario se puede encontrar en nerdctl-full.
ga_menu_options_packages=(
    "bat,ripgrep,xsv,delta,fzf,jq,yq,less,fd,oh-my-posh,jwt,step,butane"
    "neovim"
    "nerd-fonts"
    "powershell"
    "protoc,grpcurl,evans"
    "runc,crun,rootlesskit,slirp4netns,fuse-overlayfs,cni-plugins"
    "containerd,buildkit,nerdctl"
    "dive"
    "kubectl,helm,operator-sdk,3scale-toolbox,pgo"
    "k0s"
    "go"
    "graalvm"
    "nodejs"
    "roslyn,netcoredbg"
    "clangd,cmake,ninja"
    "rust-analyzer"
    "jdtls"
    )

#Opciones de configuración de los repositorio 
# > Por defecto los repositorios son instalados en todo los permitido (valor por defecto es 11)
# > Las opciones puede ser uno o la suma de los siguientes valores:
#   1 (00001) Linux que no WSL2
#   2 (00010) Linux WSL2
#   8 (00100) Windows vinculado al Linux WSL2
#
declare -A gA_repo_config=(
        ['less']=8
        ['k0s']=1
        ['operator-sdk']=3
        ['nerd-fonts']=3
        ['powershell']=3
        ['runc']=3
        ['crun']=3
        ['cni-plugins']=3
        ['3scale-toolbox']=3
        ['rootlesskit']=3
        ['slirp4netns']=3
        ['fuse-overlayfs']=3
        ['containerd']=3
        ['buildkit']=3
        ['nerdctl']=3
        ['dive']=3
        ['butane']=3
    )



#Variable global ruta de los programas CLI y/o binarios en Windows desde su WSL2
if [ $g_os_type -eq 1 ]; then
   declare -r g_path_programs_win='/mnt/d/CLI'
   declare -r g_path_commands_win="${g_path_programs_win}/Cmds"
fi


