#!/bin/bash

#TODO incluir maven
#TODO si se incluye .net runtime con el SDK podria actualizarse un runtime independientemente de su SDK.
#     por ello se esta desabilitando la instalacion de runtime por aqui

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
        ['rust']=''
        ['oc']=''
        ['awscli']=''
    )


#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
ga_menu_options_title=(
    "Comandos basicos"
    "Comandos alternativos"
    "Comandos para gRPC"
    "Las fuentes 'Nerd Fonts'"
    "El editor 'NeoVim'"
    "Shell 'Powershell'"
    "LL Container Runtine, comandos root-less, CNI plugins"
    "HL Container Runtime ContainerD: ContainerD, BuildKit y NerdCtl"
    "HL Container Runtime CRI-O: CriCtl"
    "Tools para gestionar containers: Dive"
    "Tools para K8S: kubectl, oc, helm, operator-sdk, ..."
    "Binarios para un nodo K8S de 'K0S'"
    "Binarios para un nodo K8S de 'KubeAdm'"
    ".NET  ${g_color_reset}>${g_color_green1} RTE y SDK"
    ".NET  ${g_color_reset}>${g_color_green1} LSP y DAP server"
    "Java  ${g_color_reset}>${g_color_green1} RTE 'GraalVM CE'"
    "Java  ${g_color_reset}>${g_color_green1} LSP y DAP server"
    "C/C++ ${g_color_reset}>${g_color_green1} Compiler LLVM/CLang: 'clang', 'clang++', 'lld', 'lldb', 'clangd'"
    "C/C++ ${g_color_reset}>${g_color_green1} Developments tools"
    "NodeJS${g_color_reset}>${g_color_green1} RTE"
    "Rust  ${g_color_reset}>${g_color_green1} Compiler"
    "Rust  ${g_color_reset}>${g_color_green1} LSP server"
    "Go    ${g_color_reset}>${g_color_green1} RTE"
    "AWS CLI v2"
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
    "jq,yq,bat,ripgrep,xsv,delta,fzf,less,fd,oh-my-posh"
    "jwt,step,butane"
    "protoc,grpcurl,evans"
    "nerd-fonts"
    "neovim"
    "powershell"
    "runc,crun,rootlesskit,slirp4netns,fuse-overlayfs,cni-plugins"
    "containerd,buildkit,nerdctl"
    "crictl"
    "dive"
    "kubectl,oc,helm,operator-sdk,3scale-toolbox,pgo"
    "k0s"
    "cni-plugins,kubectl,kubelet,kubeadm"
    "net-sdk"
    "roslyn,netcoredbg"
    "graalvm"
    "jdtls"
    "llvm"
    "clangd,cmake,ninja"
    "nodejs"
    "rust"
    "rust-analyzer"
    "go"
    "awscli"
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
        ['rust']=3
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
        ['awscli']=3
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

#URL base del repositorio por defecto es 'https://github.com'.
#Si no usan el repositorio por defecto, se debe especificarlo en este diccionario:
declare -A gA_repo_base_url=(
        ['kubectl']='https://dl.k8s.io/release'
        ['kubelet']='https://dl.k8s.io/release'
        ['kubeadm']='https://dl.k8s.io/release'
        ['net-sdk']='https://dotnetcli.azureedge.net'
        ['net-rt-core']='https://dotnetcli.azureedge.net'
        ['net-rt-aspnet']='https://dotnetcli.azureedge.net'
        ['go']='https://storage.googleapis.com'
        ['jdtls']='https://download.eclipse.org'
        ['nodejs']='https://nodejs.org/dist'
        ['rust']='https://static.rust-lang.org/dist'
        ['oc']='https://mirror.openshift.com/pub/openshift-v4'
        ['helm']='https://get.helm.sh'
        ['awscli']='https://awscli.amazonaws.com'
    )

#Si el repositorio es un paquete del SO (esto no se puede instalar si no es root o se tiene acceso a sudo)

declare -A gA_repo_is_os_package=(
        ['3scale-toolbox']=0
    )


#Solo descargar la ultima versión
declare -r g_setup_only_last_dotnet=1




