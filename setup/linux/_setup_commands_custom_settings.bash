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
        ['llvm']='llvm/llvm-project'
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
        ['net-sdk']='dotnet/Sdk'
        ['net-rt-core']='dotnet/Runtime'
        ['net-rt-aspnet']='dotnet/aspnetcore/Runtime'
        ['kubeadm']=''
        ['kubelet']=''
        ['crictl']='kubernetes-sigs/cri-tools'
    )
#TODO incluir maven

#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
ga_menu_options_title=(
    "Los repositorios basicos"
    "El editor 'NeoVim'"
    "Las fuentes 'Nerd Fonts'"
    "Shell 'Powershell'"
    "Tools para gRPC"
    "LL Container Runtine, comandos root-less, CNI plugins"
    "HL Container Runtime 'ContainerD', BuildKit y NerdCtl"
    "Tools para gestionar containers"
    "Tools para K8S"
    "Binarios para un nodo K8S de 'K0S'"
    "Binarios para un nodo K8S de 'KubeAdm'"
    "RTE de 'Go'"
    "RTE 'GraalVM CE' (Java)"
    "RTE Node.JS"
    "RTE .NET"
    "RTE y SDK .NET"
    "LSP y DAP server de .Net"
    "LLVM/CLang ('clang', 'clang++', 'lld', 'lldb') y tools para C/C++"
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
    "jq,yq,bat,ripgrep,xsv,delta,fzf,less,fd,oh-my-posh,jwt,step,butane"
    "neovim"
    "nerd-fonts"
    "powershell"
    "protoc,grpcurl,evans"
    "runc,crun,rootlesskit,slirp4netns,fuse-overlayfs,cni-plugins"
    "containerd,buildkit,nerdctl"
    "dive"
    "kubectl,helm,operator-sdk,3scale-toolbox,pgo"
    "k0s"
    "cni-plugins,kubectl,kubelet,crictl,kubeadm"
    "go"
    "graalvm"
    "nodejs"
    "net-rt-core,net-rt-aspnet"
    "net-sdk"
    "roslyn,netcoredbg"
    "llvm,cmake,ninja,clangd"
    "rust-analyzer"
    "jdtls"
    )

#Tipos de SO donde se puede configurar los repositorio 
# > Por defecto los repositorios son instalados en todo los tipos SO habilitados: Linux, Windows (valor por defecto es 11)
# > Las opciones puede ser uno o la suma de los siguientes valores:
#   1 (00001) Linux non-WSL2
#   2 (00010) Linux WSL2
#   8 (00100) Windows vinculado al Linux WSL2
#
declare -A gA_repo_config_os_type=(
        ['less']=8
        ['llvm']=3
        ['clangd']=8
        ['k0s']=1
        ['operator-sdk']=3
        ['nerd-fonts']=3
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
        ['kubeadm']=3
        ['kubelet']=3
        ['crictl']=3
    )


#Tipos de  donde se puede configurar los repositorio 
# > Por defecto los repositorios son instalados en todo los tipos SO habilitados: x86_64 y arm64 (valor por defecto es 3)
# > Las opciones puede ser uno o la suma de los siguientes valores:
#   1 (00001) x86_64
#   2 (00010) aarch64 (arm64)
#
declare -A gA_repo_config_proc_type=(
        ['xsv']=1
        ['jwt']=1
        ['less']=1
        ['clangd']=1
        ['neovim']=1
    )




