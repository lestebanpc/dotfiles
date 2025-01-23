#!/bin/bash

#Consideraciones:
# - Los archivos '.info' donde se almacenan las versiones de programas (que no se puede obtener una version comparable con
#   la almacenada en su repositorio donde se descarga) siempre deben ir en un folder superior de donde se ubican.
#   Esto debido a que muchas veces durante la instalacion se elimina todo el contido existen dentro del programas y no se desea
#   eliminar este archivos durante la instalacion.

#------------------------------------------------------------------------------------------------------------------
#> Variables globales de inicialización y constantes {{{
#------------------------------------------------------------------------------------------------------------------

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
        ['zoxide']='ajeetdsouza/zoxide'
        ['eza']='eza-community/eza'
        ['yazi']='sxyazi/yazi'
        ['step']='smallstep/cli'
        ['jwt']='mike-engel/jwt-cli'
        ['butane']='coreos/butane'
        ['grpcurl']='fullstorydev/grpcurl'
        ['evans']='ktr0731/evans'
        ['protoc']='protocolbuffers/protobuf'
        ['oh-my-posh']='JanDeDobbeleer/oh-my-posh'
        ['neovim']='neovim/neovim'
        ['kubectl']="$g_empty_str"
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
        ['nodejs']="$g_empty_str"
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
        ['kubeadm']="$g_empty_str"
        ['kubelet']="$g_empty_str"
        ['crictl']='kubernetes-sigs/cri-tools'
        ['rust']="$g_empty_str"
        ['oc']="$g_empty_str"
        ['awscli']="$g_empty_str"
        ['hadolint']='hadolint/hadolint'
        ['trivy']='aquasecurity/trivy'
        ['ctags-win']='universal-ctags/ctags-win32'
        ['ctags-nowin']='universal-ctags/ctags-nightly-build'
        ['tmux-fingers']='Morantron/tmux-fingers'
        ['sesh']='joshmedeski/sesh'
        ['gum']='charmbracelet/gum'
        ['tmux-thumbs']='fcsonline/tmux-thumbs'
        ['wezterm']='wez/wezterm'
        ['cilium']='cilium/cilium-cli'
        ['rclone']="$g_empty_str"
        ['marksman']='artempyanykh/marksman'
        ['biome']='biomejs/biome'
    )


#WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
ga_menu_options_title=(
    "Comandos basicos"
    "Comandos alternativos 1"
    "Comandos alternativos 2"
    "Las fuentes 'Nerd Fonts'"
    "El editor 'NeoVim'"
    "Shell 'Powershell'"
    "LL Container Runtine, comandos root-less, CNI plugins"
    "HL Container Runtime ContainerD: ContainerD, BuildKit y NerdCtl"
    "Binarios para gestionar imagenes: Dive, HadoLint, Trivy"
    "Binarios basicos para K8S: CriCtl, KubeCtl, Cilium, Helm"
    "Binarios adicionales para K8S: oc, operator-sdk, ..."
    "Binarios para un nodo K8S de 'K0S'"
    "Binarios para un nodo K8S de 'KubeAdm'"
    ".NET  ${g_color_reset}>${g_color_green1} SDK, LSP y DAP server"
    "Java  ${g_color_reset}>${g_color_green1} RTE/SDK 'GraalVM CE', LSP/DAP server"
    "C/C++ ${g_color_reset}>${g_color_green1} Compiler LLVM/CLang: 'clang', 'clang++', 'lld', 'lldb', 'clangd'"
    "C/C++ ${g_color_reset}>${g_color_green1} Developments tools"
    "NodeJS${g_color_reset}>${g_color_green1} RTE"
    "Rust  ${g_color_reset}>${g_color_green1} Compiler, LSP server"
    "Go    ${g_color_reset}>${g_color_green1} RTE"
    "AWS CLI v2"
    "CTags (indexador de archivos lenguajes de programacion)"
    "LSP otros: Markdown"
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
    "jq,yq,bat,ripgrep,delta,fzf,less,fd,oh-my-posh,zoxide,eza"
    "tmux-thumbs,tmux-fingers,sesh,protoc,grpcurl,xsv,jwt"
    "rclone,biome,step,evans,yazi,gum,butane,wezterm"
    "nerd-fonts"
    "neovim"
    "powershell"
    "runc,crun,rootlesskit,slirp4netns,fuse-overlayfs,cni-plugins"
    "containerd,buildkit,nerdctl"
    "dive,hadolint,trivy"
    "crictl,kubectl,cilium,helm"
    "oc,operator-sdk,3scale-toolbox,pgo"
    "k0s"
    "cni-plugins,kubectl,kubelet,kubeadm"
    "net-sdk,roslyn,netcoredbg"
    "graalvm,jdtls"
    "llvm"
    "clangd,cmake,ninja"
    "nodejs"
    "rust,rust-analyzer"
    "go"
    "awscli"
    "ctags-win,ctags-nowin"
    "marksman"
    )

#Tipos de SO donde se puede configurar los repositorio 
# > Por defecto los repositorios son instalados en todo los tipos SO habilitados: Linux, Windows (valor por defecto es 15)
# > Las opciones puede ser uno o la suma de los siguientes valores:
#   1 (00001) Windows vinculado al Linux WSL2.
#   2 (00010) Linux WSL     con 'libc' (opcional tienen 'musl' por lo que se puede instalar estos programas).
#   4 (00100) Linux Non-WSL con 'libc' (opcional tienen 'musl' por lo que se puede instalar estos programas).
#   8 (01000) Linux Non-WSL solo con 'musl' (Ejemplo: Alpine).
#
declare -A gA_repo_config_os_type=(
        ['less']=1
        ['wezterm']=1
        ['k0s']=4
        ['fzf']=7
        ['llvm']=14
        ['rust']=14
        ['butane']=14
        ['awscli']=14
        ['hadolint']=14
        ['trivy']=14
        ['3scale-toolbox']=14
        ['runc']=6
        ['crun']=6
        ['cni-plugins']=6
        ['containerd']=6
        ['crictl']=6
        ['buildkit']=6
        ['nerdctl']=6
        ['rootlesskit']=6
        ['slirp4netns']=6
        ['fuse-overlayfs']=6
        ['operator-sdk']=6
        ['dive']=6
        ['kubeadm']=6
        ['kubelet']=6
        ['ctags-win']=1
        ['ctags-nowin']=14
        ['tmux-fingers']=14
        ['tmux-thumbs']=14
        ['cilium']=14
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
        ['tmux-fingers']=1
        ['tmux-thumbs']=1
        ['wezterm']=1
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
        ['rclone']='https://downloads.rclone.org'
    )

#Si el repositorio es un paquete del SO (esto no se puede instalar si no es root o se tiene acceso a sudo)
declare -A gA_repo_is_os_package=(
        ['3scale-toolbox']=0
    )


#}}}


#------------------------------------------------------------------------------------------------------------------
#> Funciones de utilidad para la instalación/actualización
#------------------------------------------------------------------------------------------------------------------

#Funciones modificables de nivel 1 {{{


#Validar si una subversion de un repositorio esta instalada
#Parametros de salida:
#  > Valor de retorno:
#    0 - Esta instalado (Existe)
#    1 - NO esta instalado (No existe)
function is_installed_repo_subversion()
{
    local p_repo_id="$1"
    local p_arti_subversion_version="$2"
    local p_install_win_cmds=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #Por defecto las subversiones de un repositorio no esta intalado
    local l_is_instelled=1
    local l_status

    #Indicar si alguna subversion ya esta instalado
    case "$p_repo_id" in

        net-sdk|net-rt-core|net-rt-aspnet)

            #Validar que existe la version no esta instalado
            _dotnet_exist_version "$p_repo_id" "$p_arti_subversion_version" $p_install_win_cmds
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_is_instelled=0
            fi
            ;;
    
    esac

    return $l_is_instelled

}


#Obtiene la ultima version de realease obtenido en un repositorio
# > Los argumentos de entrada son:
#   1ro  - El ID del repositorio
#   2do  - El nombre del repositorio
# > Los parametros de salida> STDOUT se envia la version obtenida.
# > Los valores de retorno es 0 si es OK, caso contrario ocurrio un error. Los errores devueltos son
#   0    - OK
#   1    - Se requiere tener habilitado el comando jq
#   2    - Ocurrio un error al obtener la version.
#   3    - No esta definido la logica de obtener la version para el repostorio
function get_repo_last_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    
    #2. Obtener la version
    local l_base_url_fixed="${gA_repo_base_url[${p_repo_id}]:-https://github.com}"
    local l_repo_last_version=""
    local l_aux0=""
    local l_aux1=""
    local l_aux2=""
    local l_status=0

    #printf 'RepoID: "%s", URL base: "%s", RepoName: "%s"\n' "$p_repo_id" "$l_base_url_fixed" "$p_repo_name"

    case "$p_repo_id" in

        kubectl|kubelet|kubeadm)
            #El artefacto se obtiene del repositorio de Kubernates
            l_repo_last_version=$(curl -Ls ${l_base_url_fixed}/stable.txt)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            ;;

        oc)

            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_aux0=$(curl -Ls ${l_base_url_fixed}/aarch64/clients/ocp/stable/release.txt | grep '^Name: ')
                l_status=$?
            else
                l_aux0=$(curl -Ls ${l_base_url_fixed}/x86_64/clients/ocp/stable/release.txt | grep '^Name: ')
                l_status=$?
            fi

            if [ $l_status -ne 0 ]; then
                return 2
            fi
            l_repo_last_version=$(echo "$l_aux0" | sed -e "$g_regexp_sust_version1")
            ;;

        net-sdk|net-rt-core|net-rt-aspnet)

            #El artefacto se obtiene del repositorio de Microsoft

            #1. Obtener la maximo version encontrada, ya sea STS (standar term support) o LTS (long term support)
            l_repo_last_version=$(curl -Ls "${l_base_url_fixed}/${p_repo_name}/STS/latest.version")
            if [ $? -ne 0 ]; then
                return 2
            fi
            l_aux0=$(echo "$l_repo_last_version" | sed -e "$g_regexp_sust_version1")

            l_aux1=$(curl -Ls "${l_base_url_fixed}/${p_repo_name}/LTS/latest.version")
            if [ $? -ne 0 ]; then
                return 2
            fi
            l_aux2=$(echo "$l_aux1" | sed -e "$g_regexp_sust_version1")


            compare_version "${l_aux0}" "${l_aux2}"
            l_status=$?

            #Si es 1ro es < que el 2do
            if [ $l_status -eq 2 ]; then
                l_repo_last_version="$l_aux1"
            fi
            ;;
        

        jdtls)
            l_aux0=$(curl -Ls ${l_base_url_fixed}/jdtls/snapshots/latest.txt)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_aux0=${l_aux0%.tar.gz}
            l_repo_last_version=$(echo "$l_aux0" | head -n 1 | sed -e "$g_regexp_sust_version2")
            ;;

        rclone)
            l_aux0=$(curl -fLs ${l_base_url_fixed}/version.txt)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_repo_last_version=$(echo "$l_aux0" | sed -e "$g_regexp_sust_version1")
            ;;

        go)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi

            l_aux0=$(curl -Ls -H 'Accept: application/json' "https://go.dev/dl/?mode=json" | ${g_bin_cmdpath}/jq -r '.[0].version')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_repo_last_version=$(echo "$l_aux0" | sed -e "$g_regexp_sust_version1")
            ;;

        awscli)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi

            l_aux0=$(curl -LsH "Accept: application/json" "https://api.github.com/repos/aws/aws-cli/tags" | ${g_bin_cmdpath}/jq -r '.[0].name')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_repo_last_version=$(echo "$l_aux0" | sed -e "$g_regexp_sust_version1")
            ;;

        jq)
            #Si no esta instalado 'jq' usar expresiones regulares
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | \
                                      sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
                l_status=$?
            else
                l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_bin_cmdpath}/jq -r '.tag_name')
                l_status=$?
            fi

            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;

        neovim)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi
            
            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_bin_cmdpath}/jq -r '.tag_name')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;

        nodejs)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi

            #Si es Alpine: Usar el repositorio alternativos de NodeJS (https://github.com/nodejs/unofficial-builds/)
            if [ $g_os_subtype_id -eq 1 ]; then
                l_base_url_fixed='https://unofficial-builds.nodejs.org/download/release'
            fi
            
            #Usando JSON para obtener la ultima version
            l_aux0=$(curl -Ls "${l_base_url_fixed}/index.json" | ${g_bin_cmdpath}/jq -r 'first(.[] | select(.lts != false)) | "\(.version)"' 2> /dev/null)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_repo_last_version="$l_aux0"
            ;;

       less)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_bin_cmdpath}/jq -r '.tag_name')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;

        graalvm)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_bin_cmdpath}/jq -r '.tag_name')
            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            #l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | \
            #                     ${g_bin_cmdpath}/jq -r '.tag_name')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;


        rust)
            
            l_repo_last_version=$(curl -Ls "${l_base_url_fixed}/channel-rust-stable.toml" | grep -A 2 '\[pkg.rust\]' | \
                                  grep "^version =" | sed -e "$g_regexp_sust_version1")
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;

        #wezterm)

            #No se obtiene la version de la metadata. Solo el hash, el cual no tiene comparacion > o <, solo =
            #curl -LsH "Accept: application/json" "https://api.github.com/repos/wez/wezterm/tags"
            #curl -LsH "Accept: application/json" "https://api.github.com/repos/wez/wezterm/tags" | jq '.[] | select(.name == "nightly")'
            #curl -LsH "Accept: application/json" "https://api.github.com/repos/wez/wezterm/commits/c53ca64c33d1658602b9a3aaa412eca9c6544294"
            #;;

        *)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi

            #Caso especial: La etiquetas y las fuente se encuentran en 'github.com', pero los binarios estan en su propia pagina
            if [ "$p_repo_id" = "helm" ]; then
                l_base_url_fixed="https://github.com"
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_bin_cmdpath}/jq -r '.tag_name')
            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            #l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | \
            #                      ${g_bin_cmdpath}/jq -r '.tag_name')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;


    esac

    if [ -z "$l_repo_last_version" ]; then
        return 3
    fi
    
    echo "$l_repo_last_version"
    return 0
}


#Obtener la version normalizada (comparable) de la version actual/instalada.
#Los argumentos de entrada son:
#   1 - El ID del repositorio.
#   2 - El nombre del repositorio
#   3 - Version a normalizar.
#Parametros salida> STDOUT
#   La version normalizada.
#Parametros salida> Valor de retorno:
#   0 - Se normalizo la versión con exito.
#   1 - No se normalizo la versión (formato invalido).
function get_repo_last_pretty_version() {

    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_version="$3"

    #Calcular la parte comparable de la version
    local l_version
    local l_status
    local l_aux

    case "$p_repo_id" in

        awscli|net-sdk|net-rt-core|net-rt-aspnet|oc|rust)

            l_version="$p_version"
            ;;


        jdtls|rust-analyzer|marksman)

            l_version="${p_version//-/.}"
            ;;


       less)

            l_aux=$(echo "$p_version" | sed -e "$g_regexp_sust_version4")
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;


        netcoredbg)

            l_aux="${p_version//-/.}"
            l_aux=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;

        ctags-win)

            #Ejemplo de versiones:
            #  v6.1.0         
            #  v6.0.0         
            #  p6.1.20240707.0
            #  p6.1.20240630.0
            #  p6.1.20240623.0
            #Obteniendo los 3 primeros enteros.
            l_aux=$(echo $p_version | sed -E 's/[vp]([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;
    

        ctags-nowin)

            #Ejemplo de versiones:
            #  2024.07.11+e79e67dc64805a616725c3668ad7ec284de053ed
            #  2024.07.10+ac6c14ca616048b5b137e08ed60bee47b563305c
            #Obteniendo los 3 primeros enteros.
            l_aux=$(echo $p_version | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\+.*/\1/')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;

        wezterm)

            #Ejemplo de versiones: solo obtener la fecha
            #   wezterm 20240805_014059_9d285fa6
            l_aux=$(echo $p_version | sed -e 's/[^0-9]*\([0-9]\+\).*/\1/')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;


        #neovim)

            #l_version=$(echo "$p_version" | sed -e "$g_regexp_sust_version1")
            #;;


        *)
            l_aux=$(echo "$p_version" | sed -e "$g_regexp_sust_version1")
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;


    esac

    #Validar si son versiones validas
    if ! echo "$l_version" | grep '^[0-9.]\+$' &> /dev/null; then
        return 2
    fi

    #Mostrar la version normalizada
    echo "$l_version"
    return 0

}


#Obtener las subversiones que tiene disponible la ultima version del repositorio.
#Los argumentos de entrada son:
#   1 - El ID del repositorio.
#   2 - El nombre del repositorio
#   3 - Version del respositorio a obtener las subversiones.
#   4 - Version amigable del respositorio a obtener las subversiones.
#Parametros salida> STDOUT
#   Una cadena con las subversiones separadas por espacios.
#Parametros salida> Valor de retorno:
#   0 - Tiene subversiones.
#   1 - No tiene subversiones
function get_repo_last_subversions() {

    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
    local p_repo_last_pretty_version="$4"

    #Calcular la parte comparable de la version
    local l_base_url_fixed="${gA_repo_base_url[${p_repo_id}]:-https://github.com}"
    local l_status
    local l_arti_subversions=""

    case "$p_repo_id" in

        net-sdk|net-rt-core|net-rt-aspnet)

            #El artefacto se obtiene del repositorio de Microsoft
            if [ ! -z "$g_setup_only_last_version" ] && [ $g_setup_only_last_version -eq 0 ]; then
                l_arti_subversions=""
            else

                #printf 'RepoID: "%s", RepoName: "%s", LastVersion: "%s"\n' "$p_repo_id" "$p_repo_name" "$l_repo_last_pretty_version"
                #Obtener las subversiones: estara formado por la ultima version y 2 versiones inferiores 
                l_arti_subversions=$(_dotnet_get_subversions "$p_repo_name" "$l_repo_last_pretty_version")
                #printf 'LastVersion: "%s", Subversiones: "%s"\n' "$l_repo_last_pretty_version" "${l_arti_subversions[@]}"

                #Si solo tiene uns subversion y es la misma que la version, no existe subversiones
                if [ "$p_repo_last_pretty_version" = "$l_arti_subversions" ]; then
                    l_arti_subversions=""
                fi

            fi
            ;;
        


        graalvm)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_bin_cmdpath}/jq --version &> /dev/null; then
                return 1
            fi

            l_arti_subversions=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | \
                ${g_bin_cmdpath}/jq -r '.assets[].name' | grep -e '^graalvm-community-jdk-.*_linux-x64_bin\.tar\.gz$' | \
                sed -e 's/graalvm-community-jdk-\(.*\)_linux-x64_bin.*/\1/' | sort -r)

            #l_arti_subversions=$(curl -Ls -H 'Accept: application/json' "https://api.github.com/repos/${p_repo_name}/releases/latest" | \
            #   ${g_bin_cmdpath}/jq -r '.assets[].name' | grep -e '^graalvm-ce-java.*-linux-amd64-.*\.tar\.gz$' | \
            #   sed -e 's/graalvm-ce-java\(.*\)-linux-amd64-.*/\1/' | sort -r)

            #Si solo tiene uns subversion y es la misma que la version, no existe subversiones
            if [ "$l_repo_last_pretty_version" = "$l_arti_subversions" ]; then
                l_arti_subversions=""
            fi

            ;;

    esac

    #Mostrar la version normalizada
    if [  -z "$l_arti_subversions" ]; then
        return 1
    fi

    echo "$l_arti_subversions"
    return 0

}

#Determinar la version actual del repositorio usado para instalar los comandos instalados.
#Parametros de salida> STDOUT
#  Versión normalizada o 'pretty version' de la versión instalizada.
#Parametros de salida> Valor de retorno:
#  0 - Si existe y se obtiene un valor
#  1 - El comando no existe o existe un error en el comando para obtener la versión
#  2 - La version obtenida no tiene formato valido
#  3 - No existe forma de calcular la version actual (siempre se instala y/o actualizar)
#  9 - No esta implementado un metodo de obtener la version
function _get_repo_current_pretty_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_install_win_cmds=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$2" = "0" ]; then
        p_install_win_cmds=0
    fi

    local p_path_file="$3"              #Ruta donde se obtendra el comando para obtener la versión
                                        #es usado para programas que deben ser descargados para recien obtener la ultima versión.

    #Calcular la ruta de archivo/comando donde se obtiene la version (esta ruta termina en "/")
    local l_path_file="" 
    if [ -z "$p_path_file" ]; then
        if [ $p_install_win_cmds -eq 0 ]; then
            l_path_file="${g_win_bin_path}/"
        else
            l_path_file="${g_bin_cmdpath}/"
        fi
    else
        l_path_file="${p_path_file}/"
    fi



    #2. Obtener la version actual
    local l_sustitution_regexp="$g_regexp_sust_version1"
    local l_repo_current_version=""
    local l_tmp=""
    local l_status=0
    #local l_aux=""


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

        zoxide)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}zoxide.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}zoxide --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        eza)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}eza.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}eza --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | tail -n 2 | head -n 1)
                #l_sustitution_regexp="$g_regexp_sust_version3"
            fi
            ;;

        yazi)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}yazi.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}yazi --version 2> /dev/null)
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
           
        jwt)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}jwt.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}jwt --version 2> /dev/null)
                l_status=$?
            fi
            ;;
           
        biome)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}biome.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}biome --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        step)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}step.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}step --version 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                #l_sustitution_regexp="$g_regexp_sust_version3"
            fi
            ;;

        protoc)
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/protoc/bin/"
               else
                  l_path_file="${g_programs_path}/protoc/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}protoc.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}protoc --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        grpcurl)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}grpcurl.exe --version 2>&1)
                l_status=$?
            else
                l_tmp=$(${l_path_file}grpcurl --version 2>&1)
                l_status=$?
            fi

            if [ $l_status -ne 0 ]; then
                l_tmp=""
            fi
            ;;

        evans)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}evans.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}evans --version 2> /dev/null)
                l_status=$?
            fi
            ;;


        rclone)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}rclone.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}rclone --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;

        awscli)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}aws --version 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;

        hadolint)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}hadolint --version 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;

        trivy)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}trivy --version 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
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
                l_tmp=$(echo "$l_tmp" | ${g_bin_cmdpath}/jq -r '.clientVersion.gitVersion' 2> /dev/null)
                if [ $? -ne 0 ]; then
                    return 9;
                fi
            fi
            ;;

        oc)
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}oc.exe version --client=true -o json 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}oc version --client=true -o json 2> /dev/null)
                l_status=$?
            fi
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | ${g_bin_cmdpath}/jq -r '.releaseClientVersion' 2> /dev/null)
                if [ $? -ne 0 ]; then
                    return 9;
                fi
            fi
            ;;

        kubelet)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}kubelet --version 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
                #l_sustitution_regexp="$g_regexp_sust_version3"
            fi
            ;;

        kubeadm)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}kubeadm version -o json 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | ${g_bin_cmdpath}/jq -r '.clientVersion.gitVersion' 2> /dev/null)
                if [ $? -ne 0 ]; then
                    return 9;
                fi
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

        3scale-toolbox)
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            else
                l_tmp=$(${l_path_file}3scale --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        pgo)

            if [ $p_install_win_cmds -eq 0 ]; then
                if [ -f "${g_win_programs_path}/pgo.info" ]; then
                    l_tmp=$(cat "${g_win_programs_path}/pgo.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
            else
                if [ -f "${g_programs_path}/pgo.info" ]; then
                    l_tmp=$(cat "${g_programs_path}/pgo.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
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
                  l_path_file="${g_win_programs_path}/lsp_servers/omnisharp_roslyn/"
               else
                  l_path_file="${g_programs_path}/lsp_servers/omnisharp_roslyn/"
               fi
            fi

            #Obtener la version
            if [ -f "${l_path_file}OmniSharp.deps.json" ]; then
                l_tmp=$(${g_bin_cmdpath}/jq -r '.targets[][].dependencies."OmniSharp.Stdio"' "${l_path_file}OmniSharp.deps.json" | grep -v "null" | \
                      head -n 1 2> /dev/null)
                l_status=$?
            else
                l_status=1
            fi
            ;;

        netcoredbg)
            
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/dap_servers/"
               else
                  l_path_file="${g_programs_path}/dap_servers/"
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
                  l_path_file="${g_win_programs_path}/neovim/bin/"
               else
                  l_path_file="${g_programs_path}/neovim/bin/"
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

        nodejs)
           
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/nodejs/"
               else
                  l_path_file="${g_programs_path}/nodejs/bin/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}node.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}node --version 2> /dev/null)
                l_status=$?
            fi
            ;;

        nerd-fonts)
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ -f "${g_win_programs_path}/nerd-fonts.info" ]; then
                    l_tmp=$(cat "${g_win_programs_path}/nerd-fonts.info" | head -n 1)
                else
                    #Siempre se actualizara la fuentes, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi
            else
                if [ -f "${g_programs_path}/nerd-fonts.info" ]; then
                    l_tmp=$(cat "${g_programs_path}/nerd-fonts.info" | head -n 1)
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
                  l_path_file="${g_win_programs_path}/go/bin/"
               else
                  l_path_file="${g_programs_path}/go/bin/"
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


        rust)

            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #Obtener la version
            l_tmp=$(${l_path_file}cargo --version 2> /dev/null)
            l_status=$?

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;

       net-sdk)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/dotnet/"
               else
                  l_path_file="${g_programs_path}/dotnet/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}dotnet.exe --list-sdks version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}dotnet --list-sdks version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then
                l_tmp=$(echo "$l_tmp" | sort -r | head -n 1)
            fi
            ;;


       net-rt-core|net-rt-aspnet)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/dotnet/"
               else
                  l_path_file="${g_programs_path}/dotnet/"
               fi
            fi

            #Si esta instalado SDK, no instalarlo
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}dotnet.exe --list-sdks version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}dotnet --list-sdks version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -ne 0 ] || [ -z "$l_tmp" ]; then
                return 9
            fi


            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}dotnet.exe --list-runtimes version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}dotnet --list-runtimes version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ] && [ ! -z "$l_tmp" ]; then

                if [ "$p_repo_id" = "net-rt-core" ]; then

                    l_tmp=$(echo "$l_tmp" | grep 'Microsoft.NETCore.App' | sort -r | head -n 1)
                    l_status=$?
                    if [ $l_status -ne 0 ]; then
                        l_tmp=""
                    fi

                else
                    l_tmp=$(echo "$l_tmp" | grep 'Microsoft.AspNetCore.App' | sort -r | head -n 1)
                    l_status=$?
                    if [ $l_status -ne 0 ]; then
                        l_tmp=""
                    fi

                fi

            fi
            ;;


        llvm)

            #No habilitado para Windows
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               l_path_file="${g_programs_path}/llvm/bin/"
            fi

            #Obtener la version
            l_tmp=$(${l_path_file}clang --version 2> /dev/null)
            l_status=$?

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;


        clangd)

            #Solo habilitado para Windows, en Linux esta incluido en LLVM
            #if [ $p_install_win_cmds -ne 0 ]; then
            #    return 9
            #fi

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/lsp_servers/clangd/bin/"
               else
                  l_path_file="${g_programs_path}/lsp_servers/clangd/bin/"
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
            else
                l_tmp=""
            fi
            ;;

        cmake)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/cmake/bin/"
               else
                  l_path_file="${g_programs_path}/cmake/bin/"
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
            
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/powershell/"
               else
                  l_path_file="${g_programs_path}/powershell/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}pwsh.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}pwsh --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        rust-analyzer)

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then

                if [ -f "${g_win_programs_path}/rust-analyzer.info" ]; then
                    l_tmp=$(cat "${g_win_programs_path}/rust-analyzer.info" | head -n 1)
                    l_status=$?
                else
                    l_tmp=$(${l_path_file}rust-analyzer.exe --version 2> /dev/null)
                    l_status=$?
                fi

            else

                if [ -f "${g_programs_path}/rust-analyzer.info" ]; then
                    l_tmp=$(cat "${g_programs_path}/rust-analyzer.info" | head -n 1)
                    l_status=$?
                else
                    l_tmp=$(${l_path_file}rust-analyzer --version 2> /dev/null)
                    l_status=$?
                fi

            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            else
                l_tmp=""
            fi
            ;;

        graalvm)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/graalvm/bin/"
               else
                  l_path_file="${g_programs_path}/graalvm/bin/"
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
                  l_path_file="${g_win_programs_path}/lsp_servers/jdtls/"
               else
                  l_path_file="${g_programs_path}/lsp_servers/jdtls/"
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

        butane)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}butane --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
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

        crun)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}crun --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        fuse-overlayfs)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}fuse-overlayfs --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | grep fuse-overlayfs)
            fi
            ;;


        cni-plugins)
            
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            if [ -f "${g_programs_path}/cni-plugins.info" ]; then
                l_tmp=$(cat "${g_programs_path}/cni-plugins.info" | head -n 1)
            else

                #Calcular la ruta de archivo/comando donde se obtiene la version
                if [ -z "$p_path_file" ]; then
                    l_path_file="${g_programs_path}/cni_plugins/"
                fi

                #CNI vlan plugin v1.2.0
                l_tmp=$(${l_path_file}vlan --version 2>&1)
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

        crictl)
            
            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}crictl --version 2> /dev/null)
            l_status=$?
            
            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;

        ctags-win)

            if [ $p_install_win_cmds -ne 0 ]; then
                return 9
            fi

            if [ -f "${g_win_programs_path}/ctags.info" ]; then
                l_tmp=$(cat "${g_win_programs_path}/ctags.info" | head -n 1)
            else
                #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                echo "$g_version_none"
                return 3
            fi
            ;;

        ctags-nowin)

            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            if [ -f "${g_programs_path}/ctags.info" ]; then
                l_tmp=$(cat "${g_programs_path}/ctags.info" | head -n 1)
            else
                #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                echo "$g_version_none"
                return 3
            fi
            ;;


        cilium)

            if [ $p_install_win_cmds -eq 0 ]; then

                if [ -f "${g_win_programs_path}/cilium.info" ]; then
                    l_tmp=$(cat "${g_win_programs_path}/cilium.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi

            else

                if [ -f "${g_programs_path}/cilium.info" ]; then
                    l_tmp=$(cat "${g_programs_path}/cilium.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi

            fi
            ;;


        marksman)

            if [ $p_install_win_cmds -eq 0 ]; then

                if [ -f "${g_win_programs_path}/marksman.info" ]; then
                    l_tmp=$(cat "${g_win_programs_path}/marksman.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi

            else

                if [ -f "${g_programs_path}/marksman.info" ]; then
                    l_tmp=$(cat "${g_programs_path}/marksman.info" | head -n 1)
                else
                    #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                    echo "$g_version_none"
                    return 3
                fi

            fi
            ;;


        tmux-fingers)

            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            #Obtener la version
            if [ -f "${g_programs_path}/tmux-fingers.info" ]; then
                l_tmp=$(cat "${g_programs_path}/tmux-fingers.info" | head -n 1)
            else
                #Siempre se actualizara el binario, por ahora no se puede determinar la version instalada
                echo "$g_version_none"
                return 3
            fi
            ;;


        tmux-thumbs)

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                return 9
            fi

            l_tmp=$(${l_path_file}tmux-fingers --version 2> /dev/null)
            l_status=$?

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;



        sesh)

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}sesh.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}sesh --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        gum)

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}gum.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}gum --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | head -n 1)
            fi
            ;;


        wezterm)
            
            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ -z "$p_path_file" ]; then
               if [ $p_install_win_cmds -eq 0 ]; then
                  l_path_file="${g_win_programs_path}/wezterm/"
               else
                  l_path_file="${g_programs_path}/wezterm/"
               fi
            fi

            #Obtener la version
            if [ $p_install_win_cmds -eq 0 ]; then
                l_tmp=$(${l_path_file}wezterm.exe --version 2> /dev/null)
                l_status=$?
            else
                l_tmp=$(${l_path_file}wezterm --version 2> /dev/null)
                l_status=$?
            fi

            if [ $l_status -eq 0 ]; then
                l_tmp=$(echo "$l_tmp" | sed -e 's/[^0-9]*\([0-9]\+\).*/\1/')
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


#Usado durante la instalacion para comparar si la version instalada y la descargada son diferentes.
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

    #1. Argumentos
    local p_repo_id=$1
    local p_path="$2/"
    local p_install_win_cmds=1
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    printf "Comparando versiones de '%s': \"Versión actual\" vs \"Versión ubica en '%s'\"...\n" "$p_repo_id" "$p_path"

    #2. Obteniendo la versión actual
    local l_current_version
    l_current_version=$(_get_repo_current_pretty_version "$p_repo_id" ${p_install_win_cmds})

    local l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '   No se puede obtener la versión actual de "%s" (status: %s)\n' "$p_repo_id" "$l_status"
        return 9
    fi

    #3. Obteniendo la versión de lo especificado como parametro
    local l_other_version
    l_other_version=$(_get_repo_current_pretty_version "$p_repo_id" ${p_install_win_cmds} "$p_path")

    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '   No se puede obtener la versión de "%s" ubicada en "%s" (status: %s)\n' "$p_repo_id" "$p_path" "$l_status"
        return 8
    fi

    #4. Comparando ambas versiones
    compare_version "$l_current_version" "$l_other_version"
    l_status=$?

    if [ $l_status -eq 0 ]; then

        printf '   La versión actual "%s" ya esta actualizado %b(= "%s" que es la versión ubicada en "%s")%b\n' "$l_current_version" "$g_color_gray1" \
               "$l_other_version" "$p_path" "$g_color_reset"

    elif [ $l_status -eq 1 ]; then

        printf '   La versión actual "%s" ya esta actualizado %b(> "%s" que es la versión ubicada en "%s")%b\n' "$l_current_version" "$g_color_gray1" \
               "$l_other_version" "$p_path" "$g_color_reset"


    else

        printf '   La versión actual "%s" requiere ser actualizado %b(= "%s" que es la versión ubicada en "%s")%b\n' "$l_current_version" "$g_color_gray1" \
               "$l_other_version" "$p_path" "$g_color_reset"

    fi

    return $l_status


}


#}}}


#Funciones modificables (Nive 2) {{{


#Devuelve un arreglo de artefectos, usando los argumentos 3 y 4 como de referencia:
#  5> Un arrego de bases URL del los artefactos. 
#     Si el repositorio tiene muchos artefactos pero todos tiene la misma URL base, solo se puede indicar
#     solo una URL, la misma URL se replicara para los demas se repitira el mismo valor
#  6> Un arreglo de tipo de artefacto donde cada item puede ser:
#     Un archivo no comprimido
#       >  0 si es un binario (no empaquetado o comprimido)
#       >  1 si es un package
#     Comprimidos no tan pesados (se descomprimen y copian en el lugar deseado)
#       > 10 si es un .tar.gz
#       > 11 si es un .zip
#       > 12 si es un .gz
#       > 13 si es un .tgz
#       > 14 si es un .tar.xz
#     Comprimidos muy pesados (se descomprimen directamente en el lugar deseado)
#       > 20 si es un .tar.gz
#       > 21 si es un .zip
#       > 22 si es un .gz
#       > 23 si es un .tgz
#       > 24 si es un .tar.xz
#     No definido
#       > 99 si no se define el artefacto para el prefijo
#  7> Un arreglo de nombre de los artectos a descargar
#En el argumento 2 se debe pasar la version pura quitando, sin contener "v" u otras letras iniciales
function get_repo_artifacts() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
    local p_repo_last_pretty_version="$4"
    declare -n pna_artifact_baseurl=$5   #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_artifact_names=$6     #Parametro por referencia: Se devuelve un arreglo de los nombres de los artefactos
    declare -n pna_artifact_types=$7     #Parametro por referencia: Se devuelve un arreglo de los tipos de los artefactos
    local p_arti_subversion_version="$8"

    local p_install_win_cmds=1         #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                       #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$9" = "0" ]; then
        p_install_win_cmds=0
    fi
    
    #Si se estan instalando (la primera vez) es '0', caso contrario es otro valor (se actualiza o se desconoce el estado)
    local p_flag_install=1
    if [ "${10}" = "0" ]; then
        p_flag_install=0
    fi

    #2. Generar el nombre
    local l_artifact_name=""
    local l_artifact_type=99
    local l_status
    local l_aux1
    local l_aux2

    #1. Obtener la URL base por defecto (se considera que el repositorio es de GitHub)

    #URL base fijo     :  Usualmente "https://github.com"
    local l_base_url_fixed="${gA_repo_base_url[${p_repo_id}]:-https://github.com}"

    #URL base variable :
    local l_base_url_variable="${p_repo_name}/releases/download/${p_repo_last_version}"
    #URL base para un repositorio GitHub
    pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

    #2. Segun el repositorio obtener los nombres de los artefactos (y su URL base, si no esta en GitHub)
    case "$p_repo_id" in

        net-sdk|net-rt-core|net-rt-aspnet)

            #Prefijo del nombre del artefacto
            local l_prefix_repo='dotnet-sdk'
            if [ "$p_repo_id" = "net-rt-core" ]; then
                l_prefix_repo='dotnet-runtime'
            elif [ "$p_repo_id" = "net-rt-aspnet" ]; then
                l_prefix_repo='aspnetcore-runtime'
            fi

            #Si no existe subversiones un repositorio
            if [ -z "$p_arti_subversion_version" ]; then

                #URL base fijo     : "https://dotnetcli.azureedge.net"
                #URL base variable :
                l_base_url_variable="${p_repo_name}/${p_repo_last_version}"

                #Generar la URL con el artefactado:
                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
                if [ $p_install_win_cmds -eq 0 ]; then

                    pna_artifact_names=("${l_prefix_repo}-${p_repo_last_pretty_version}-win-x64.zip")

                    #Si se instala, no se descomprime el archivo automaticamente en '/tmp'. Si se actualiza, se usara 'rsync' para actualizar.
                    if [ $p_flag_install -eq 0 ]; then
                        pna_artifact_types=(21)
                    else
                        pna_artifact_types=(11)
                    fi

                else
                    #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                    if [ $g_os_subtype_id -eq 1 ]; then
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_pretty_version}-linux-musl-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_pretty_version}-linux-musl-x64.tar.gz")
                        fi
                    else
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_pretty_version}-linux-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_repo_last_pretty_version}-linux-x64.tar.gz")
                        fi
                    fi

                    #Si se instala, no se descomprime el archivo automaticamente en '/tmp'. Si se actualiza, se usara 'rsync' para actualizar.
                    if [ $p_flag_install -eq 0 ]; then
                        pna_artifact_types=(20)
                    else
                        pna_artifact_types=(10)
                    fi
                fi

            #Si existe subversiones en un repositorios
            else

                #URL base fijo     : "https://dotnetcli.azureedge.net"
                #URL base variable :
                l_base_url_variable="${p_repo_name}/${p_arti_subversion_version}"

                #Generar la URL con el artefactado:
                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
                if [ $p_install_win_cmds -eq 0 ]; then
                    pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-win-x64.zip")

                    #Si se instala, no se descomprime el archivo automaticamente en '/tmp'. Si se actualiza, se usara 'rsync' para actualizar.
                    if [ $p_flag_install -eq 0 ]; then
                        pna_artifact_types=(21)
                    else
                        pna_artifact_types=(11)
                    fi

                else
                    #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                    if [ $g_os_subtype_id -eq 1 ]; then
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-musl-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-musl-x64.tar.gz")
                        fi
                    else
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-arm64.tar.gz")
                        else
                            pna_artifact_names=("${l_prefix_repo}-${p_arti_subversion_version}-linux-x64.tar.gz")
                        fi
                    fi

                    #Si se instala, no se descomprime el archivo automaticamente en '/tmp'. Si se actualiza, se usara 'rsync' para actualizar.
                    if [ $p_flag_install -eq 0 ]; then
                        pna_artifact_types=(20)
                    else
                        pna_artifact_types=(10)
                    fi

                fi

            fi
            ;;


        crictl)
            
            #No soportado para Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("crictl-v${p_repo_last_pretty_version}-linux-arm64.tar.gz" "critest-v${p_repo_last_pretty_version}-linux-arm64.tar.gz")
                pna_artifact_types=(10 10)
            else
                pna_artifact_names=("crictl-v${p_repo_last_pretty_version}-linux-amd64.tar.gz" "critest-v${p_repo_last_pretty_version}-linux-amd64.tar.gz")
                pna_artifact_types=(10 10)
            fi
            ;;


        zoxide)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("zoxide-${p_repo_last_pretty_version}-aarch64-pc-windows-msvc.zip")
                else
                    pna_artifact_names=("zoxide-${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("zoxide-${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz")
                    else
                        pna_artifact_names=("zoxide-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("zoxide-${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz")
                    else
                        pna_artifact_names=("zoxide-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;


        eza)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("eza.exe_x86_64-pc-windows-gnu.tar.gz")
                pna_artifact_types=(10)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        #No hay soporte Alpine para aarch64
                        pna_artifact_names=("eza_x86_64-unknown-linux-musl.tar.gz" "completions-${p_repo_last_pretty_version}.tar.gz" "man-${p_repo_last_pretty_version}.tar.gz")
                    else
                        pna_artifact_names=("eza_x86_64-unknown-linux-musl.tar.gz" "completions-${p_repo_last_pretty_version}.tar.gz" "man-${p_repo_last_pretty_version}.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("eza_aarch64-unknown-linux-gnu.tar.gz" "completions-${p_repo_last_pretty_version}.tar.gz" "man-${p_repo_last_pretty_version}.tar.gz")
                    else
                        pna_artifact_names=("eza_x86_64-unknown-linux-gnu.tar.gz" "completions-${p_repo_last_pretty_version}.tar.gz" "man-${p_repo_last_pretty_version}.tar.gz")
                    fi
                fi
                pna_artifact_types=(10 10 10)
            fi
            ;;


        yazi)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("yazi-aarch64-pc-windows-msvc.zip")
                else
                    pna_artifact_names=("yazi-x86_64-pc-windows-msvc.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("yazi-aarch64-unknown-linux-musl.zip")
                    else
                        pna_artifact_names=("yazi-x86_64-unknown-linux-musl.zip")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("yazi-aarch64-unknown-linux-gnu.zip")
                    else
                        pna_artifact_names=("yazi-x86_64-unknown-linux-gnu.zip")
                    fi
                fi
                pna_artifact_types=(11)
            fi
            ;;


        rclone)
            #URL base fijo     : "https://downloads.rclone.org"
            #URL base variable :
            l_base_url_variable="v${p_repo_last_pretty_version}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("rclone-v${p_repo_last_pretty_version}-windows-arm64.zip")
                else
                    pna_artifact_names=("rclone-v${p_repo_last_pretty_version}-windows-amd64.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("rclone-v${p_repo_last_pretty_version}-linux-arm64.zip")
                    else
                        pna_artifact_names=("rclone-v${p_repo_last_pretty_version}-linux-amd64.zip")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("rclone-v${p_repo_last_pretty_version}-linux-arm64.zip")
                    else
                        pna_artifact_names=("rclone-v${p_repo_last_pretty_version}-linux-amd64.zip")
                    fi
                fi
                pna_artifact_types=(11)
            fi
            ;;


        jq)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("jq-windows-amd64.exe")
                pna_artifact_types=(0)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("jq-linux-arm64")
                    else
                        pna_artifact_names=("jq-linux-amd64")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("jq-linux-arm64")
                    else
                        pna_artifact_names=("jq-linux-amd64")
                    fi
                fi
                pna_artifact_types=(0)
            fi
            ;;


        yq)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("yq_windows_amd64.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("yq_linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("yq_linux_amd64.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("yq_linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("yq_linux_amd64.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;


        cilium)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("cilium-windows-arm64.zip")
                else
                    pna_artifact_names=("cilium-windows-amd64.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("cilium-linux-arm64.tar.gz")
                    else
                        pna_artifact_names=("cilium-linux-amd64.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("cilium-linux-arm64.tar.gz")
                    else
                        pna_artifact_names=("cilium-linux-amd64.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;


        fzf)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("fzf-${p_repo_last_pretty_version}-windows_arm64.zip")
                else
                    pna_artifact_names=("fzf-${p_repo_last_pretty_version}-windows_amd64.zip")
                fi
                pna_artifact_types=(11)
            else
                #Las rutas de 2 artectactos difieren
                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}" "${l_base_url_fixed}/${p_repo_name}/archive/refs/tags")

                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("fzf-${p_repo_last_pretty_version}-linux_arm64.tar.gz" "v${p_repo_last_pretty_version}.tar.gz")
                    else
                        pna_artifact_names=("fzf-${p_repo_last_pretty_version}-linux_amd64.tar.gz" "v${p_repo_last_pretty_version}.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("fzf-${p_repo_last_pretty_version}-linux_arm64.tar.gz" "v${p_repo_last_pretty_version}.tar.gz")
                    else
                        pna_artifact_names=("fzf-${p_repo_last_pretty_version}-linux_amd64.tar.gz" "v${p_repo_last_pretty_version}.tar.gz")
                    fi
                fi
                pna_artifact_types=(10 10)
            fi
            ;;


        helm)

            #Caso especial: en github, se encuentra casi todos menos lo binarios
            #URL base fijo     : "https://get.helm.sh"
            #URL base variable : None

            pna_artifact_baseurl=("${l_base_url_fixed}")
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("helm-v${p_repo_last_pretty_version}-windows-amd64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("helm-v${p_repo_last_pretty_version}-linux-arm64.tar.gz")
                else
                    pna_artifact_names=("helm-v${p_repo_last_pretty_version}-linux-amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        delta)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("delta-${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        #pna_artifact_names=("delta-${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz")
                        pna_artifact_names=("delta-${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("delta-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("delta-${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("delta-${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;

        ripgrep)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("ripgrep-${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("ripgrep-${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                        #pna_artifact_names=("ripgrep-${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz")
                    else
                        pna_artifact_names=("ripgrep-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("ripgrep-${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("ripgrep-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                        #pna_artifact_names=("ripgrep-${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;

        xsv)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                else
                    pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                    #pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        bat)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("bat-v${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        #pna_artifact_names=("bat-v${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz")
                        pna_artifact_names=("bat-v${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("bat-v${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("bat-v${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("bat-v${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;


        biome)

            #URL base fijo     :  "https://github.com"
            #l_base_url_fixed="${gA_repo_base_url[${p_repo_id}]:-https://github.com}"
            #URL base variable :
            l_base_url_variable="${p_repo_name}/releases/download/cli%2Fv${p_repo_last_pretty_version}"

            #URL base para un repositorio GitHub
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("biome-win32-arm64.exe")
                else
                    pna_artifact_names=("biome-win32-x64.exe")
                fi
                pna_artifact_types=(0)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("biome-linux-arm64-musl")
                    else
                        pna_artifact_names=("biome-linux-x64-musl")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("biome-linux-arm64")
                    else
                        pna_artifact_names=("biome-linux-x64")
                    fi
                fi
                pna_artifact_types=(0)
            fi
            ;;


        oh-my-posh)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("posh-windows-amd64.exe" "themes.zip")
                pna_artifact_types=(0 11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("posh-linux-arm64" "themes.zip")
                else
                    pna_artifact_names=("posh-linux-amd64" "themes.zip")
                fi
                pna_artifact_types=(0 11)
            fi
            ;;

        fd)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("fd-v${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        #pna_artifact_names=("fd-v${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz")
                        pna_artifact_names=("fd-v${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("fd-v${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("fd-v${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("fd-v${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;

        jwt)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("jwt-windows.tar.gz")
                pna_artifact_types=(10)
            else
                pna_artifact_names=("jwt-linux.tar.gz")
                pna_artifact_types=(10)
            fi
            ;;

        step)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("step_windows_${p_repo_last_pretty_version}_amd64.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No se soporta musl, solo libc
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("step_linux_${p_repo_last_pretty_version}_arm64.tar.gz")
                    else
                        pna_artifact_names=("step_linux_${p_repo_last_pretty_version}_amd64.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("step_linux_${p_repo_last_pretty_version}_arm64.tar.gz")
                    else
                        pna_artifact_names=("step_linux_${p_repo_last_pretty_version}_amd64.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;

        protoc)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("protoc-${p_repo_last_pretty_version}-win64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("protoc-${p_repo_last_pretty_version}-linux-aarch_64.zip")
                else
                    pna_artifact_names=("protoc-${p_repo_last_pretty_version}-linux-x86_64.zip")
                fi
                pna_artifact_types=(11)
            fi
            ;;

        grpcurl)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("grpcurl_${p_repo_last_pretty_version}_windows_x86_64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("grpcurl_${p_repo_last_pretty_version}_linux_arm64.tar.gz")
                else
                    pna_artifact_names=("grpcurl_${p_repo_last_pretty_version}_linux_x86_64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        nodejs)
            #URL base fijo     : "https://nodejs.org/dist"
            if [ $g_os_subtype_id -eq 1 ]; then
                #Si es Alpine: Usar el repositorio alternativos de NodeJS (https://github.com/nodejs/unofficial-builds/)
                l_base_url_fixed='https://unofficial-builds.nodejs.org/download/release'
            fi

            #URL base variable :
            l_base_url_variable="${p_repo_last_version}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("node-v${p_repo_last_pretty_version}-win-x64.zip")
                pna_artifact_types=(21)
                #pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("node-v${p_repo_last_pretty_version}-linux-arm64.tar.xz")
                        #pna_artifact_names=("node-v${p_repo_last_pretty_version}-linux-arm64-musl.tar.xz")
                        pna_artifact_types=(24)
                    else
                        pna_artifact_names=("node-v${p_repo_last_pretty_version}-linux-x64-musl.tar.xz")
                        pna_artifact_types=(24)
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("node-v${p_repo_last_pretty_version}-linux-arm64.tar.xz")
                        pna_artifact_types=(24)
                    else
                        pna_artifact_names=("node-v${p_repo_last_pretty_version}-linux-x64.tar.gz")
                        pna_artifact_types=(20)
                    fi
                fi
            fi
            ;;

        evans)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("evans_windows_amd64.tar.gz")
                pna_artifact_types=(10)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("evans_linux_arm64.tar.gz")
                else
                    pna_artifact_names=("evans_linux_amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        awscli)
            #URL base fijo     : "https://awscli.amazonaws.com"
            #URL base variable : <none>

            #No soportado para Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}")
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("awscli-exe-linux-aarch64.zip")
            else
                pna_artifact_names=("awscli-exe-linux-x86_64.zip")
            fi
            pna_artifact_types=(11)
            ;;

        oc)
            #URL base fijo     : "https://mirror.openshift.com"
            #URL base variable :
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_base_url_variable="aarch64/clients/ocp/stable"
            else
                l_base_url_variable="x86_64/clients/ocp/stable"
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("openshift-client-windows.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("openshift-client-linux.tar.gz")
                else
                    pna_artifact_names=("openshift-client-linux.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        kubectl)
            #URL base fijo     : "https://dl.k8s.io/release"
            #URL base variable :
            if [ $p_install_win_cmds -eq 0 ]; then
                l_base_url_variable="${p_repo_last_version}/bin/windows/amd64"
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    l_base_url_variable="${p_repo_last_version}/bin/linux/arm64"
                else
                    l_base_url_variable="${p_repo_last_version}/bin/linux/amd64"
                fi
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("kubectl.exe")
                pna_artifact_types=(0)
            else
                pna_artifact_names=("kubectl")
                pna_artifact_types=(0)
            fi
            ;;

        kubelet)
            #URL base fijo     : "https://dl.k8s.io/release"
            #URL base variable :
            if [ $p_install_win_cmds -eq 0 ]; then
                l_base_url_variable="${p_repo_last_version}/bin/windows/amd64"
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    l_base_url_variable="${p_repo_last_version}/bin/linux/arm64"
                else
                    l_base_url_variable="${p_repo_last_version}/bin/linux/amd64"
                fi
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            else
                pna_artifact_names=("kubelet")
                pna_artifact_types=(0)
            fi
            ;;

        kubeadm)
            #URL base fijo     : "https://dl.k8s.io/release"
            #URL base variable :
            if [ $p_install_win_cmds -eq 0 ]; then
                l_base_url_variable="${p_repo_last_version}/bin/windows/amd64"
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    l_base_url_variable="${p_repo_last_version}/bin/linux/arm64"
                else
                    l_base_url_variable="${p_repo_last_version}/bin/linux/amd64"
                fi
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                return 1
            else
                pna_artifact_names=("kubeadm")
                pna_artifact_types=(0)
            fi
            ;;

        pgo)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("kubectl-pgo-windows-386")
                pna_artifact_types=(0)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("kubectl-pgo-linux-arm64")
                else
                    pna_artifact_names=("kubectl-pgo-linux-amd64")
                fi
                pna_artifact_types=(0)
            fi
            ;;

        less)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #No soportado para Linux
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("less-x64.zip")
            pna_artifact_types=(11)
            ;;

        k0s)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("k0s-v${p_repo_last_pretty_version}+k0s.0-amd64.exe")
                pna_artifact_types=(0)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("k0s-v${p_repo_last_pretty_version}+k0s.0-arm64")
                else
                    pna_artifact_names=("k0s-v${p_repo_last_pretty_version}+k0s.0-amd64")
                fi
                pna_artifact_types=(0)
            fi
            ;;

        operator-sdk)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("operator-sdk_linux_arm64" "helm-operator_linux_arm64")
            else
                pna_artifact_names=("operator-sdk_linux_amd64" "helm-operator_linux_amd64")
            fi
            pna_artifact_types=(0 0)
            ;;

        roslyn)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("omnisharp-win-x64-net6.0.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("omnisharp-linux-musl-arm64-net6.0.tar.gz")
                    else
                        pna_artifact_names=("omnisharp-linux-musl-x64-net6.0.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("omnisharp-linux-arm64-net6.0.tar.gz")
                    else
                        pna_artifact_names=("omnisharp-linux-x64-net6.0.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;

        netcoredbg)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("netcoredbg-win64.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("netcoredbg-linux-arm64.tar.gz")
                else
                    pna_artifact_names=("netcoredbg-linux-amd64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;

        neovim)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("nvim-win64.zip")
                pna_artifact_types=(21)
            else
                pna_artifact_names=("nvim-linux64.tar.gz")
                #Si se instala, no se descomprime, se realizara la logica de descomprención.
                pna_artifact_types=(20)
            fi
            ;;

        nerd-fonts)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("JetBrainsMono.tar.xz" "CascadiaCode.tar.xz" "DroidSansMono.tar.xz"
                                "InconsolataLGC.tar.xz" "UbuntuMono.tar.xz" "3270.tar.xz")
            pna_artifact_types=(14 14 14 14 14 14)
            ;;

        go)
            #URL base fijo     : "https://storage.googleapis.com"
            #URL base variable :
            l_base_url_variable="${p_repo_name}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("go${p_repo_last_pretty_version}.windows-amd64.zip")
                pna_artifact_types=(21)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("go${p_repo_last_pretty_version}.linux-arm64.tar.gz")
                else
                    pna_artifact_names=("go${p_repo_last_pretty_version}.linux-amd64.tar.gz")
                fi
                pna_artifact_types=(20)
            fi
            ;;

        rust)
            #Solo para Linux
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #URL base fijo     : "https://static.rust-lang.org/dist"
            #URL base variable : <emtpy>

            #URL completo del componente 'rust-src'
            l_aux1=$(curl -Ls "https://static.rust-lang.org/dist/channel-rust-stable.toml" | grep -A 5 '\[pkg.rust-src.target."\*"\]' | \
                     grep '^url =' | sed -e 's/^url = "\(.*\)".*/\1/')
            #URL base del componente 'rust-src'
            l_aux2="${l_aux1%/*}"
            #Nombre del componente 'rust-src'
            l_aux1="${l_aux1##*/}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}" "$l_aux2")

            #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
            if [ $g_os_subtype_id -eq 1 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("rust-${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz" "$l_aux1")
                else
                    pna_artifact_names=("rust-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz" "$l_aux1")
                fi
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("rust-${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz" "$l_aux1")
                else
                    pna_artifact_names=("rust-${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz" "$l_aux1")
                fi
            fi
            pna_artifact_types=(10 10)
            ;;

        llvm)

            #Solo para Linux
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("clang+llvm-${p_repo_last_pretty_version}-aarch64-linux-gnu.tar.xz")
                #pna_artifact_types=(14)
                pna_artifact_types=(24)
            else
                #TODO obtener el nombre dinamicamente
                pna_artifact_names=("clang+llvm-${p_repo_last_pretty_version}-x86_64-linux-gnu-ubuntu-22.04.tar.xz")
                #pna_artifact_types=(14)
                pna_artifact_types=(24)
            fi
            ;;

        clangd)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("clangd-windows-${p_repo_last_pretty_version}.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("clangd-linux-${p_repo_last_pretty_version}.zip")
                pna_artifact_types=(11)
            fi
            ;;

        cmake)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("cmake-${p_repo_last_version#v}-windows-x86_64.zip")
                pna_artifact_types=(21)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("cmake-${p_repo_last_version#v}-linux-aarch64.tar.gz")
                else
                    pna_artifact_names=("cmake-${p_repo_last_version#v}-linux-x86_64.tar.gz")
                fi
                pna_artifact_types=(20)
            fi
            ;;

        ninja)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("ninja-win.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("ninja-linux.zip")
                pna_artifact_types=(11)
            fi
            ;;

        powershell)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("PowerShell-${p_repo_last_pretty_version}-win-x64.zip")
                pna_artifact_types=(21)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("powershell-${p_repo_last_pretty_version}-linux-arm64.tar.gz")
                else
                    pna_artifact_names=("powershell-${p_repo_last_pretty_version}-linux-x64.tar.gz")
                fi
                pna_artifact_types=(20)
            fi
            ;;

        3scale-toolbox)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -ne 0 ]; then
                #Si es de la familia Debian
                if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
                    pna_artifact_names=("3scale-toolbox_${p_repo_last_pretty_version}-1_amd64.deb")
                    pna_artifact_types=(1)
                #Si es de la familia Fedora
                elif [ $g_os_subtype_id -ge 10 ] && [ $g_os_subtype_id -lt 30 ]; then
                    pna_artifact_names=("3scale-toolbox_${p_repo_last_pretty_version}-1.el8.x86_64.rpm")
                    pna_artifact_types=(1)
                else
                    #No soportato en esta distribución Linux
                    return 1
                fi
            else
                #No se instala nada en Windows
                return 1
            fi
            ;;

        rust-analyzer)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("rust-analyzer-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("rust-analyzer-aarch64-unknown-linux-gnu.gz")
                else
                    pna_artifact_names=("rust-analyzer-x86_64-unknown-linux-gnu.gz")
                fi
                pna_artifact_types=(12)
            fi
            ;;

        graalvm)
            #Generar los datos de artefactado requeridos para su configuración:
            #JDK 21, esta diseñando una nueva forma de instalar plugins a GraalVM, dejando de usar 'GraalVM Updater'

            #Si no existe subversiones un repositorio
            if [ -z "$p_arti_subversion_version" ]; then
                if [ $p_install_win_cmds -eq 0 ]; then
                    pna_artifact_names=("graalvm-community-jdk-${p_repo_last_pretty_version}_windows-x64_bin.zip")
                    pna_artifact_types=(21)
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("graalvm-community-jdk-${p_repo_last_pretty_version}_linux-aarch64_bin.tar.gz")
                    else
                        pna_artifact_names=("graalvm-community-jdk-${p_repo_last_pretty_version}_linux-x64_bin.tar.gz")
                    fi
                    pna_artifact_types=(20)
                fi
            #Si existe subversiones en el repositorio
            #TODO Corregir las URLs
            else
                if [ $p_install_win_cmds -eq 0 ]; then
                    pna_artifact_names=("graalvm-ce-java${p_arti_subversion_version}-windows-amd64-${p_repo_last_pretty_version}.zip")
                    pna_artifact_types=(21)
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("graalvm-ce-java${p_arti_subversion_version}-linux-aarch64-${p_repo_last_pretty_version}.tar.gz")
                    else
                        pna_artifact_names=("graalvm-ce-java${p_arti_subversion_version}-linux-amd64-${p_repo_last_pretty_version}.tar.gz")
                    fi
                    pna_artifact_types=(20)
                fi
            fi
            ;;
        
        jdtls)
            #URL base fijo     : "https://download.eclipse.org"
            #URL base variable :
            l_base_url_variable="${p_repo_name}/snapshots"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            pna_artifact_names=("jdt-language-server-${p_repo_last_version}.tar.gz")
            pna_artifact_types=(10)
            ;;

        butane)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("butane-aarch64-unknown-linux-gnu")
            else
                pna_artifact_names=("butane-x86_64-unknown-linux-gnu")
            fi
            pna_artifact_types=(0)
            ;;

        runc)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("runc.arm64")
            else
                pna_artifact_names=("runc.amd64")
            fi
            pna_artifact_types=(0)
            ;;

        crun)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("crun-${p_repo_last_version}-linux-arm64")
            else
                pna_artifact_names=("crun-${p_repo_last_version}-linux-amd64")
            fi
            pna_artifact_types=(0)
            ;;

        fuse-overlayfs)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("fuse-overlayfs-aarch64")
            else
                pna_artifact_names=("fuse-overlayfs-x86_64")
            fi
            pna_artifact_types=(0)
            ;;

        cni-plugins)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("cni-plugins-linux-arm64-${p_repo_last_version}.tgz")
            else
                pna_artifact_names=("cni-plugins-linux-amd64-${p_repo_last_version}.tgz")
            fi
            pna_artifact_types=(13)
            ;;

        slirp4netns)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("slirp4netns-aarch64")
            else
                pna_artifact_names=("slirp4netns-x86_64")
            fi
            pna_artifact_types=(0)
            ;;

        rootlesskit)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("rootlesskit-aarch64.tar.gz")
            else
                pna_artifact_names=("rootlesskit-x86_64.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;

        containerd)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("containerd-${p_repo_last_pretty_version}-linux-arm64.tar.gz")
            else
                pna_artifact_names=("containerd-${p_repo_last_pretty_version}-linux-amd64.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;

        buildkit)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("buildkit-${p_repo_last_version}.linux-amd64.tar.gz")
            pna_artifact_types=(10)
            ;;

        nerdctl)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("nerdctl-${p_repo_last_pretty_version}-linux-arm64.tar.gz" "nerdctl-full-${p_repo_last_pretty_version}-linux-arm64.tar.gz")
            else
                pna_artifact_names=("nerdctl-${p_repo_last_pretty_version}-linux-amd64.tar.gz" "nerdctl-full-${p_repo_last_pretty_version}-linux-amd64.tar.gz")
            fi
            pna_artifact_types=(10 10)
            ;;


        dive)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("dive_${p_repo_last_pretty_version}_linux_arm64.tar.gz")
            else
                pna_artifact_names=("dive_${p_repo_last_pretty_version}_linux_amd64.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;


        hadolint)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("hadolint-Linux-arm64")
            else
                pna_artifact_names=("hadolint-Linux-x86_64")
            fi
            pna_artifact_types=(0)
            ;;


        trivy)
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("trivy_${p_repo_last_pretty_version}_Linux-ARM64.tar.gz")
            else
                pna_artifact_names=("trivy_${p_repo_last_pretty_version}_Linux-64bit.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;


        ctags-win)

            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("ctags-${p_repo_last_version}-x64.zip")
            pna_artifact_types=(11)
            ;;


        ctags-nowin)

            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("uctags-${p_repo_last_pretty_version}-linux-aarch64.tar.gz")
            else
                pna_artifact_names=("uctags-${p_repo_last_pretty_version}-linux-x86_64.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;


        tmux-fingers)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #No soportado para Windows
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
            if [ $g_os_subtype_id -eq 1 ]; then
                pna_artifact_names=("tmux-fingers-${p_repo_last_pretty_version}-linux-x86_64")
            else
                pna_artifact_names=("tmux-fingers-${p_repo_last_pretty_version}-linux-x86_64")
            fi
            pna_artifact_types=(0)
            ;;


        tmux-thumbs)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #No soportado para Windows
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
            if [ $g_os_subtype_id -eq 1 ]; then
                pna_artifact_names=("tmux-thumbs_${p_repo_last_pretty_version}_x86_64-unknown-linux-musl.tar.gz")
            else
                pna_artifact_names=("tmux-thumbs_${p_repo_last_pretty_version}_x86_64-unknown-linux-musl.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;




        sesh)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("sesh_Windows_arm64.zip")
                else
                    pna_artifact_names=("sesh_Windows_x86_64.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("sesh_Linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("sesh_Linux_x86_64.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("sesh_Linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("sesh_Linux_x86_64.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;



        marksman)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("marksman.exe")
                else
                    pna_artifact_names=("marksman.exe")
                fi
                pna_artifact_types=(0)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("marksman-linux-arm64")
                    else
                        pna_artifact_names=("marksman-linux-x64")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("marksman-linux-arm64")
                    else
                        pna_artifact_names=("marksman-linux-x64")
                    fi
                fi
                pna_artifact_types=(0)
            fi
            ;;


        gum)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_install_win_cmds -eq 0 ]; then
                pna_artifact_names=("gum_${p_repo_last_pretty_version}_Windows_x86_64.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("gum_${p_repo_last_pretty_version}_Linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("gum_${p_repo_last_pretty_version}_Linux_x86_64.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("gum_${p_repo_last_pretty_version}_Linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("gum_${p_repo_last_pretty_version}_Linux_x86_64.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;


        wezterm)

            #No soportado para Linux
            if [ $p_install_win_cmds -ne 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 1
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("WezTerm-windows-${p_repo_last_version}.zip")
            pna_artifact_types=(21)
            ;;


        *)
           pna_artifact_baseurl=()
           pna_artifact_names=()
           return 1
           ;;
    esac

    return 0
}


#}}}


#Funciones modificables (Nivel 3) {{{



function _copy_artifact_files() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_artifact_index="$2"
    local p_artifact_filename="$3"
    local p_artifact_filename_woext="$4"
    local p_artifact_type=$5

    local p_install_win_cmds=1      #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                    #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$6" = "0" ]; then
        p_install_win_cmds=0
    fi

    local p_repo_current_pretty_version="$7"
    local p_repo_last_version="$8"
    local p_repo_last_pretty_version="$9"
    local p_artifact_is_last=${10}

    local p_arti_subversion_version="${11}"
    local p_arti_subversion_index=0
    if [[ "${12}" =~ ^[0-9]+$ ]]; then
        p_arti_subversion_index=${12}
    fi

    local p_flag_install=1          #Si se estan instalando (la primera vez) es '0', caso contrario es otro valor (se actualiza o se desconoce el estado)
    if [ "${13}" = "0" ]; then
        p_flag_install=0
    fi

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 3 ] || [ $gp_type_calling -eq 4 ]; then
        l_is_noninteractive=0
    fi

    #2. Inicializaciones

    #Tag usuado para imprimir un identificador del artefacto en un log
    local l_tag="${p_repo_id}${g_color_gray1}[${p_repo_last_pretty_version}]"
    if [ ! -z "${p_arti_subversion_version}" ]; then
        l_tag="${l_tag}[${p_arti_subversion_version}]${g_color_reset}"
    else
        l_tag="${l_tag}${g_color_reset}"
    fi

    local l_source_path=""
    local l_target_path=""
    #printf 'Temporal: %b\n' "$l_tag"

    #3. Copiar loa archivos del artefactos segun el prefijo
    local l_status=0
    local l_aux=''

    case "$p_repo_id" in

        bat)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            if [ $p_install_win_cmds -ne 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                copy_binary_on_command "${l_source_path}" "bat" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1

                #Copiar los archivos de autocompletado
                echo "Copiando \"autocomplete/bat.bash\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/autocomplete/bat.bash" ${g_repo_path}/shell/bash/login/autocomplete/bat.bash
                echo "Copiando \"autocomplete/_bat.ps1\" a \"~/.files/shell/powershell/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/autocomplete/_bat.ps1" ${g_repo_path}/shell/powershell/login/autocomplete/bat.ps1

                #Si se ejecuta un usuario (es root) y es diferente al usuario owner del home de instalación
                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${g_repo_path}/shell/bash/login/autocomplete/bat.bash"
                    chown "${g_targethome_owner}:${g_targethome_group}" "${g_repo_path}/shell/powershell/login/autocomplete/bat.ps1"
                fi

            else

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "bat.exe" 1 1

            fi
            ;;

        ripgrep)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"
            
            if [ $p_install_win_cmds -ne 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                copy_binary_on_command "${l_source_path}" "rg" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}/doc" 1

                #Copiar los script de completado
                echo "Copiando \"complete/rg.bash\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/complete/rg.bash" ${g_repo_path}/shell/bash/login/autocomplete/rg.bash
                echo "Copiando \"complete/_rg.ps1\" a \"~/.files/shell/powershell/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/complete/_rg.ps1" ${g_repo_path}/shell/powershell/login/autocomplete/rg.ps1

                #Si se ejecuta un usuario (es root) y es diferente al usuario owner del home de instalación
                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/rg.bash
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/powershell/login/autocomplete/rg.ps1
                fi
                
            else
                  
                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "rg.exe" 1 1

            fi
            ;;

        xsv)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_install_win_cmds -ne 0 ]; then

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "xsv" 0 1

            else

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "xsv.exe" 1 1

            fi
            ;;


        biome)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            
            #Si es WSL Linux
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_install_win_cmds -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/biome.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/biome.exe"

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "biome.exe" 1 1

                return 0
            fi

            #Si es Linux non-WSL

            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/biome\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/biome"

            #Copiar el comando
            copy_binary_on_command "${l_source_path}" "biome" 0 1
            return 0
            ;;



        delta)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_install_win_cmds -ne 0 ]; then


                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "delta" 0 1

            else

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "delta.exe" 1 1

            fi
            ;;

        less)

            if [ $p_install_win_cmds -ne 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Windows" "$g_color_reset" 
                return 40
            fi            

            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"
            l_source_path="${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "less.exe" 1 1
            copy_binary_on_command "${l_source_path}" "lesskey.exe" 1 1
            ;;

        butane)

            #Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi            

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            
            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/butane\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/butane"

            #Copiar el comando
            copy_binary_on_command "${l_source_path}" "butane" 0 1
            ;;


        fzf)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "fzf.exe" 1 1

                return 0
            fi

            #B. Si es Linux que no sea WSL
            
            #Copiar el comando
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando fzf y dar permiso de ejecucion a todos los usuarios
                copy_binary_on_command "${l_source_path}" "fzf" 0 1

            #Descargar archivos opcionales del comando fzf desde la ultima version de la rama master de su repositorio 'junegunn/fzf' 
            elif [ $p_artifact_index -eq 1 ]; then

                l_source_path="${l_source_path}/fzf-${p_repo_last_pretty_version}"
                printf 'Copiando archivos adicionales del comando fzf desde "%b%s%b"...\n' "$g_color_gray1" "$l_source_path" "$g_color_reset"

                #Copiar los archivos de ayuda man para comando fzf y el script fzf-tmux
                copy_man_files "${g_temp_path}/${l_source_path}/man/man1" 1
            
                #Copiar los script de completado
                echo "Copiando el script \"./shell/completion.bash\" como \"~/.files/shell/bash/login/autocomplete/fzf.bash\" ..."
                cp "${g_temp_path}/${l_source_path}/shell/completion.bash" "${g_repo_path}/shell/bash/login/autocomplete/fzf.bash"
            
                echo "Copiando el script \"./shell/completion.zsh\" como \"~/.files/shell/zsh/login/autocomplete/fzf.zsh\" ..."
                cp "${g_temp_path}/${l_source_path}/shell/completion.zsh" "${g_repo_path}/shell/zsh/login/autocomplete/fzf.zsh"

                #Copiar los script de keybindings
                echo "Copiando el script \"./shell/key-bindings.bash\" como \"~/.files/shell/bash/login/keybindings/fzf.bash\" ..."
                cp "${g_temp_path}/${l_source_path}/shell/key-bindings.bash" "${g_repo_path}/shell/bash/login/keybindings/fzf.bash"
            
                echo "Copiando el script \"./shell/key-bindings.fish\" como \"~/.files/shell/fish/login/keybindings/fzf.fish\" ..."
                cp "${g_temp_path}/${l_source_path}/shell/key-bindings.fish" "${g_repo_path}/shell/fish/login/keybindings/fzf.fish"
            
                echo "Copiando el script \"./shell/key-bindings.zsh\" como \"~/.files/shell/zsh/login/keybindings/fzf.zsh\" ..."
                cp "${g_temp_path}/${l_source_path}/shell/key-bindings.zsh" "${g_repo_path}/shell/zsh/login/keybindings/fzf.zsh"
           
                echo "Copiando \"./bin/fzf-preview.sh\" como \"~/.files/shell/bash/bin/cmds/fzf-preview.bash\"..."
                cp "${g_temp_path}/${l_source_path}/bin/fzf-preview.sh" "${g_repo_path}/shell/bash/bin/cmds/fzf-preview.bash"

                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/login/autocomplete/fzf.bash 
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/login/autocomplete/fzf.zsh
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/login/keybindings/fzf.bash
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/login/keybindings/fzf.fish
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/login/keybindings/fzf.zsh
                    #chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/bin/cmds/fzf-tmux.bash
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/bin/cmds/fzf-preview.bash
                fi

            fi
            ;;

        jq)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/jq\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/jq"

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "jq" 0 1

            else

                echo "Renombrando \"jq-windows-amd64.exe\" como \"${g_temp_path}/${l_source_path}/jq.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/jq-windows-amd64.exe" "${g_temp_path}/${l_source_path}/jq.exe"

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "jq.exe" 1 1

            fi
            ;;
            

        yq)
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then

                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    echo "Renombrando \"yq_linux_arm64\" como \"${g_temp_path}/${l_source_path}/yq\" ..."
                    mv "${g_temp_path}/${l_source_path}/yq_linux_arm64" "${g_temp_path}/${l_source_path}/yq"
                else
                    echo "Renombrando \"yq_linux_amd64\" como \"${g_temp_path}/${l_source_path}/yq\" ..."
                    mv "${g_temp_path}/${l_source_path}/yq_linux_amd64" "${g_temp_path}/${l_source_path}/yq"
                fi
                
                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "yq" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1

            else
                echo "Renombrando \"yq_windows_amd64.exe\" como \"${g_temp_path}/${l_source_path}/yq.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/yq_windows_amd64.exe" "${g_temp_path}/${l_source_path}/yq.exe"

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "yq.exe" 1 1
            fi
            ;;


        rclone)
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Renombrar el binario antes de copiarlo
            if [ $p_install_win_cmds -ne 0 ]; then
                
                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "rclone" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1

            else

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "rclone.exe" 1 1
            fi
            ;;

        
        oh-my-posh)
            
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #En Linux
            if [ $p_install_win_cmds -ne 0 ]; then

                #Instalación de binario 'oh-my-posh'
                if [ $p_artifact_index -eq 0 ]; then

                    echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/oh-my-posh\" ..."
                    mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/oh-my-posh"
                
                    #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                    copy_binary_on_command "${l_source_path}" "oh-my-posh" 0 1

                #Instalación del tema
                else

                    mkdir -p ${g_repo_path}/etc/oh-my-posh/default
                    cp -f ${g_temp_path}/${l_source_path}/*.json ${g_repo_path}/etc/oh-my-posh/default

                    if [ $g_runner_is_target_user -ne 0 ]; then
                        chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/oh-my-posh/default
                    fi

                fi

            #B. Si es WSL de Windows y se copia binarios de windows
            else

                #Instalación de binario 'oh-my-posh'
                if [ $p_artifact_index -eq 0 ]; then

                    echo "Renombrando \"posh-windows-amd64.exe\" como \"${g_temp_path}/${l_source_path}/oh-my-posh.exe\" ..."
                    mv "${g_temp_path}/${l_source_path}/posh-windows-amd64.exe" "${g_temp_path}/${l_source_path}/oh-my-posh.exe"

                    #Copiar el comando
                    copy_binary_on_command "${l_source_path}" "oh-my-posh.exe" 1 1

                #Instalación del tema
                else
                    mkdir -p "${g_win_etc_path}/oh-my-posh/default"
                    cp -f ${g_temp_path}/${l_source_path}/*.json "${g_win_etc_path}/oh-my-posh/default"
                fi
            fi
            ;;


        zoxide)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "zoxide.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando
            copy_binary_on_command "${l_source_path}" "zoxide" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}/man/man1" 1

            #Copiar los script de completado
            echo "Copiando \"./completions/zoxide.bash\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/zoxide.bash" ${g_repo_path}/shell/bash/login/autocomplete/zoxide.bash

            echo "Copiando \"./completions/zoxide.fish\" a \"~/.files/shell/fish/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/zoxide.fish" ${g_repo_path}/shell/fish/login/autocomplete/zoxide.fish
            
            echo "Copiando \"./completions/_zoxide\" a \"~/.files/shell/zsh/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/_zoxide" ${g_repo_path}/shell/zsh/login/autocomplete/zoxide.zsh

            echo "Copiando \"./completions/zoxide.elv\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/zoxide.elv" ${g_repo_path}/shell/others/login/autocomplete/zoxide.elv

            echo "Copiando \"./completions/zoxide.ts\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/zoxide.ts" ${g_repo_path}/shell/others/login/autocomplete/zoxide.ts

            echo "Copiando \"./completions/_zoxide.ps1\" a \"~/.files/shell/powershell/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/_zoxide.ps1" ${g_repo_path}/shell/powershell/login/autocomplete/zoxide.ps1

            if [ $g_runner_is_target_user -ne 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/zoxide.bash
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/fish/login/autocomplete/zoxide.fish
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/zsh/login/autocomplete/zoxide.zsh
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/zoxide.elv
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/zoxide.ts
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/powershell/login/autocomplete/zoxide.ps1
            fi
            ;;



        eza)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                #Binarios
                if [ $p_artifact_index -eq 0 ]; then

                    #Copiar el comando
                    copy_binary_on_command "${l_source_path}" "eza.exe" 1 1

                fi
                return 0
            fi

            #B. Si es Linux (no WSL)

            #Binarios
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "eza" 0 1


            #Copiar los archivos de autocompletado
            elif [ $p_artifact_index -eq 1 ]; then

                l_source_path="${l_source_path}/target/completions-${p_repo_last_pretty_version}"

                echo "Copiando \"${l_source_path}/eza\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/eza" ${g_repo_path}/shell/bash/login/autocomplete/eza.bash

                echo "Copiando \"${l_source_path}/_eza\" a \"~/.files/shell/zsh/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/_eza" ${g_repo_path}/shell/zsh/login/autocomplete/eza.zsh

                echo "Copiando \"${l_source_path}/eza.nu\" a \"~/.files/shell/others/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/eza.nu" ${g_repo_path}/shell/others/login/autocomplete/eza.nu

                echo "Copiando \"${l_source_path}/eza.fish\" a \"~/.files/shell/fish/login/autocomplete/\" ..."
                cp "${g_temp_path}/${l_source_path}/eza.fish" ${g_repo_path}/shell/fish/login/autocomplete/eza.fish

                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/eza.bash
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/fish/login/autocomplete/eza.fish
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/zsh/login/autocomplete/eza.zsh
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/eza.nu
                fi


            #Copiar los archivos de ayuda (man)
            elif [ $p_artifact_index -eq 2 ]; then

                l_source_path="${l_source_path}/target/man-${p_repo_last_pretty_version}"

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1
                copy_man_files "${g_temp_path}/${l_source_path}" 5

            fi
            ;;
        


        tmux-fingers)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi


            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/tmux-fingers\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/tmux-fingers"

            #Copiar el comando
            copy_binary_on_command "${l_source_path}" "tmux-fingers" 0 1

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_program "" "tmux-fingers.info" "$p_repo_last_pretty_version" 0
            ;;
            


        tmux-thumbs)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi


            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando
            copy_binary_on_command "${l_source_path}" "tmux-thumbs" 0 1
            copy_binary_on_command "${l_source_path}" "thumbs" 0 1
            ;;
            


        yazi)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "yazi.exe" 1 1
                copy_binary_on_command "${l_source_path}" "ya.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "yazi" 0 1
            copy_binary_on_command "${l_source_path}" "ya" 0 1


            #Copiar los archivos de autocompletado
            echo "Copiando \"./completions/yazi.bash\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/yazi.bash" ${g_repo_path}/shell/bash/login/autocomplete/yazi.bash

            echo "Copiando \"./completions/_yazi\" a \"~/.files/shell/zsh/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/_yazi" ${g_repo_path}/shell/zsh/login/autocomplete/yazi.zsh

            echo "Copiando \"./completions/yazi.elv\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/yazi.elv" ${g_repo_path}/shell/others/login/autocomplete/yazi.elv

            echo "Copiando \"./completions/yazi.fish\" a \"~/.files/shell/fish/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/yazi.fish" ${g_repo_path}/shell/fish/login/autocomplete/yazi.fish

            echo "Copiando \"./completions/yazi.nu\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/yazi.nu" ${g_repo_path}/shell/others/login/autocomplete/yazi.nu

            echo "Copiando \"./completions/yazi.ts\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/yazi.ts" ${g_repo_path}/shell/others/login/autocomplete/yazi.ts

            echo "Copiando \"./completions/_yazi.ps1\" a \"~/.files/shell/powershell/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/_yazi.ps1" ${g_repo_path}/shell/powershell/login/autocomplete/yazi.ps1


            echo "Copiando \"./completions/ya.bash\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/ya.bash" ${g_repo_path}/shell/bash/login/autocomplete/ya.bash

            echo "Copiando \"./completions/_ya\" a \"~/.files/shell/zsh/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/_ya" ${g_repo_path}/shell/zsh/login/autocomplete/ya.zsh

            echo "Copiando \"./completions/ya.elv\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/ya.elv" ${g_repo_path}/shell/others/login/autocomplete/ya.elv

            echo "Copiando \"./completions/ya.fish\" a \"~/.files/shell/fish/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/ya.fish" ${g_repo_path}/shell/fish/login/autocomplete/ya.fish

            echo "Copiando \"./completions/ya.nu\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/ya.nu" ${g_repo_path}/shell/others/login/autocomplete/ya.nu

            echo "Copiando \"./completions/ya.ts\" a \"~/.files/shell/others/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/ya.ts" ${g_repo_path}/shell/others/login/autocomplete/ya.ts

            echo "Copiando \"./completions/_ya.ps1\" a \"~/.files/shell/powershell/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/_ya.ps1" ${g_repo_path}/shell/powershell/login/autocomplete/ya.ps1


            if [ $g_runner_is_target_user -ne 0 ]; then

                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/yazi.bash
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/fish/login/autocomplete/yazi.fish
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/zsh/login/autocomplete/yazi.zsh
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/yazi.nu
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/yazi.elv
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/yazi.ts
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/powershell/login/autocomplete/yazi.ps1


                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/ya.bash
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/fish/login/autocomplete/ya.fish
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/zsh/login/autocomplete/ya.zsh
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/ya.nu
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/ya.elv
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/others/login/autocomplete/ya.ts
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/powershell/login/autocomplete/ya.ps1

            fi
            ;;


        fd)
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "fd.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "fd" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}" 1

            #Copiar los script de completado
            echo "Copiando \"autocomplete/fd.bash\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/autocomplete/fd.bash" ${g_repo_path}/shell/bash/login/autocomplete/fd.bash
            echo "Copiando \"autocomplete/fd.ps1\" a \"~/.files/shell/powershell/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/autocomplete/fd.ps1" ${g_repo_path}/shell/powershell/login/autocomplete/fd.ps1

            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/fd.bash
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/powershell/login/autocomplete/fd.ps1
            fi

            ;;


        jwt)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "jwt.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "jwt" 0 1
            ;;
            
        grpcurl)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "grpcurl.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "grpcurl" 0 1
            ;;

            
        evans)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "evans.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "evans" 0 1
            ;;

            
        dive)

            #A. No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #B. Si es Linux (no WSL)
            
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "dive" 0 1
            ;;


        crictl)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40

            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            if [ $p_artifact_index -eq 0 ]; then
                copy_binary_on_command "${l_source_path}" "crictl" 0 1
            else
                copy_binary_on_command "${l_source_path}" "critest" 0 1
            fi
            ;;

            
            
        marksman)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            if [ $p_install_win_cmds -ne 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/marksman\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/marksman"

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                copy_binary_on_command "${l_source_path}" "marksman" 0 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_program "" "marksman.info" "$p_repo_last_pretty_version" 0

            else

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "marksman.exe" 1 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_program "" "marksman.info" "$p_repo_last_pretty_version" 1

            fi
            ;;
            
            
        cilium)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_install_win_cmds -ne 0 ]; then


                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "cilium" 0 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_program "" "cilium.info" "$p_repo_last_pretty_version" 0

            else

                #Copiar el comando
                copy_binary_on_command "${l_source_path}" "cilium.exe" 1 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_program "" "cilium.info" "$p_repo_last_pretty_version" 1
            fi
            ;;

            
        kubelet)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi


            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "kubelet" 0 1

            #Desacargar archivos adicionales para su configuración
            mkdir -p ${g_repo_path}/etc/kubelet/systemd
            l_aux=$(curl -sL https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubelet/kubelet.service 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                printf 'Creando el archivo "%b~/.files/etc/kubelet/systemd/kubelet.service%b" ... \n' "$g_color_gray1" "$g_color_reset"
                echo "$l_aux" | sed "s:/usr/bin:${g_bin_cmdpath}:g" > ${g_repo_path}/etc/kubelet/systemd/kubelet.service

                #Fix permisos
                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/kubelet/
                fi

            fi
            ;;

            
        kubeadm)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "kubeadm" 0 1

            #Desacargar archivos adicionales para su configuración
            mkdir -p ${g_repo_path}/etc/kubeadm
            l_aux=$(curl -sL https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                printf 'Creando el archivo "%b~/.files/etc/kubeadm/10-kubeadm.conf%b" ... \n' "$g_color_gray1" "$g_color_reset"
                echo "$l_aux" | sed "s:/usr/bin:${g_bin_cmdpath}:g" > ${g_repo_path}/etc/kubeadm/10-kubeadm.conf

                #Fix permisos
                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/kubeadm/10-kubeadm.conf
                fi
            fi

            ;;

            
        kubectl)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "kubectl.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)
            
            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "kubectl" 0 1
            ;;
        
        oc)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "oc.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "oc" 0 1
            ;;

        pgo)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}\" en \"${g_temp_path}/${l_source_path}/kubectl-pgo.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/kubectl-pgo.exe"

                copy_binary_on_command "${l_source_path}" "kubectl-pgo.exe" 1 1
                
                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_program "" "pgo.info" "$p_repo_last_pretty_version" 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            echo "Renombrando \"${p_artifact_filename_woext}\" en \"${g_temp_path}/${l_source_path}/kubectl-pgo\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/kubectl-pgo"

            copy_binary_on_command "${l_source_path}" "kubectl-pgo" 0 1
            
            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_program "" "pgo.info" "$p_repo_last_pretty_version" 0
            ;;
            
        helm)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                l_source_path="${l_source_path}/windows-amd64"
                copy_binary_on_command "${l_source_path}" "helm.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            l_source_path="${l_source_path}/linux-amd64"
            copy_binary_on_command "${l_source_path}" "helm" 0 1
            ;;

        operator-sdk)

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40

            fi

            #B. Si es Linux (no WSL)
            
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #Instalacion del SDK para construir el operador
            if [ $p_artifact_index -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}\" en \"${g_temp_path}/${l_source_path}/operator-sdk\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/operator-sdk"

                copy_binary_on_command "${l_source_path}" "operator-sdk" 0 1

            #Instalacion del SDK para construir el operador usando Helm
            else

                echo "Renombrando \"${p_artifact_filename_woext}\" en \"${g_temp_path}/${l_source_path}/helm-operator\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/helm-operator"

                copy_binary_on_command "${l_source_path}" "helm-operator" 0 1

            fi
            ;;



        step)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/step_${p_repo_last_pretty_version}"
            

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}/bin" "step.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}/bin" "step" 0 1

            #Copiando los script para el autocompletado
            echo "Copiando \"autocomplete/bash_autocomplete\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/autocomplete/bash_autocomplete" ${g_repo_path}/shell/bash/login/autocomplete/step.bash
            echo "Copiando \"autocomplete/zsh_autocomplete\" a \"~/.files/shell/zsh/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/autocomplete/zsh_autocomplete" ${g_repo_path}/shell/zsh/login/autocomplete/step.zsh

            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/step.bash
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/zsh/login/autocomplete/step.zsh
            fi

            ;;



        ninja)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "ninja.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "ninja" 0 1
            ;;


        rust-analyzer)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "rust-analyzer.exe" 1 1 
                
                #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                save_prettyversion_on_program "" "rust-analyzer.info" "$p_repo_last_pretty_version" 1

                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "rust-analyzer" 0 1 
            
            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_program "" "rust-analyzer.info" "$p_repo_last_pretty_version" 0
            ;;


        sesh)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "sesh.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "sesh" 0 1
            ;;


        gum)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                copy_binary_on_command "${l_source_path}" "gum.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_on_command "${l_source_path}" "gum" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}/manpages" 1

            #Copiando los script para el autocompletado
            echo "Copiando \"completions/gum.bash\" a \"~/.files/shell/bash/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/gum.bash" ${g_repo_path}/shell/bash/login/autocomplete/gum.bash

            echo "Copiando \"completions/gum.zsh\" a \"~/.files/shell/zsh/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/gum.zsh" ${g_repo_path}/shell/zsh/login/autocomplete/gum.zsh

            echo "Copiando \"completions/gum.fish\" a \"~/.files/shell/fish/login/autocomplete/\" ..."
            cp "${g_temp_path}/${l_source_path}/completions/gum.fish" ${g_repo_path}/shell/fish/login/autocomplete/gum.fish

            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/bash/login/autocomplete/gum.bash
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/zsh/login/autocomplete/gum.zsh
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/fish/login/autocomplete/gum.fish
            fi

            ;;


        hadolint)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Windows" "$g_color_reset" 
                return 40
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" NO esta habilitado para Windows"
                return 40
            fi


            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Renombrando 
            echo "Renombrando \"${p_artifact_filename_woext}\" a \"${g_temp_path}/${l_source_path}/hadolint\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/hadolint"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "hadolint" 0 1
            ;;



        trivy)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "trivy" 0 1

            mkdir -p ${g_repo_path}/etc/trivy/templates
            echo "Copiando templates de \"contrib/*.tpl\" a \"~/.files/etc/trivy/templates/\" ..."
            cp ${g_temp_path}/${l_source_path}/contrib/*.tpl ${g_repo_path}/etc/trivy/templates/

            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/trivy/
            fi
            ;;



        runc)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                

            #B. Si es Linux (no WSL)

            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" \
                       "$g_color_red1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${p_artifact_filename_woext}\" a \"${g_temp_path}/${l_source_path}/runc\""
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/runc"

            copy_binary_on_command "${l_source_path}" "runc" 0 1

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;



        crun)

            #A. No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                
            #B. Si es Linux (no WSL)

            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'podman' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "podman" "$g_color_reset" \
                       "$g_color_red1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'podman.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${p_artifact_filename_woext}\" a \"${g_temp_path}/${l_source_path}/crun\""
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/crun"

            copy_binary_on_command "${l_source_path}" "crun" 0 1

            #4. Desacargar el archivo de configuracion requerido por podman, el cual algunas instalaciones de podman no se encuentra ...
            mkdir -p ${g_repo_path}/etc/podman
            
            #/etc/containers/storage.conf (default: overlayfs)
            printf 'Descargando el archivo de configuracion requerido para "%s" con soporte a "Overlay" en "~/%s"\n' "/etc/containers/storage.conf" \
                   ".files/etc/podman/storage_overlay_default.toml"
            curl -fLo ${g_repo_path}/etc/podman/storage_overlay_default.toml \
                 https://raw.githubusercontent.com/containers/podman/main/vendor/github.com/containers/storage/storage.conf
           
            #/etc/containers/storage.conf (btrfs)
            # cambiando 'driver = "overlay"' por 'driver = "btrfs"'

            #/etc/containers/containers.conf
            #/etc/containers/registries.conf

            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/podman/
            fi

            #5. Si la unidad servicio 'podman' estaba iniciando y se detuvo, iniciarlo
            #if [ $l_status -eq 3 ]; then
            if [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'podman.service'
                if [ $g_runner_id -eq 0 ]; then
                    systemctl start podman.service 
                else
                    sudo systemctl start podman.service 
                fi
            fi
            ;;


        slirp4netns)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                
            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd.io' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" \
                       "$g_color_red1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${p_artifact_filename_woext}\" a \"${g_temp_path}/${l_source_path}/slirp4netns\""
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/slirp4netns"

            copy_binary_on_command "${l_source_path}" "slirp4netns" 0 1

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_runner_id -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        fuse-overlayfs)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                
            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd.io' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" \
                       "$g_color_red1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Renombrando \"${p_artifact_filename_woext}\" a \"${g_temp_path}/${l_source_path}/fuse-overlayfs\""
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/fuse-overlayfs"

            copy_binary_on_command "${l_source_path}" "fuse-overlayfs" 0 1

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_runner_id -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        rootlesskit)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                
            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" \
                       "$g_color_red1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "rootlesskit-docker-proxy" 0 1
            copy_binary_on_command "${l_source_path}" "rootlesskit" 0 1
            copy_binary_on_command "${l_source_path}" "rootlessctl" 0 1


            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_runner_id -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;


        containerd)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                
            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/bin"

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" \
                       "$g_color_red1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi


            #3. Configurar: Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "containerd-shim" 0 1
            copy_binary_on_command "${l_source_path}" "containerd-shim-runc-v1" 0 1
            copy_binary_on_command "${l_source_path}" "containerd-shim-runc-v2" 0 1
            copy_binary_on_command "${l_source_path}" "containerd-stress" 0 1
            copy_binary_on_command "${l_source_path}" "ctr" 0 1
            copy_binary_on_command "${l_source_path}" "containerd" 0 1

            #Descargar archivo de configuracion como servicio a nivel system:
            mkdir -p ${g_repo_path}/etc/containerd/systemd_root
            
            printf 'Descargando el archivo de configuracion de "%s" a nivel system en "%s"\n' "containerd.service" "~/.files/etc/containerd/systemd_root/"
            curl -fLo ${g_repo_path}/etc/containerd/systemd_root/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
            #Descargar archivo de configuracion como servicio a nivel usuario: no se requiere.
            #debio a que al ejecutar crea el arcivo 'containerd-rootless-setuptool.sh install' lo crea

            #4. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 2 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 3 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_runner_id -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi

            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/containerd/
            fi

            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:
            if [ $l_status -eq 0 ]; then

                printf 'El artefacto de "%s" aun no esta aun esta instalada. Se recomiendo crear una unidad systemd "%s" para gestionar su inicio y detención.\n' \
                       "$p_repo_id" "containerd.service"
                printf 'Para instalar "%s" tiene 2 opciones:\n' "$p_repo_id"
                printf '%b1> Instalar en modo rootless%b (la unidad "%s" se ejecutara en modo user)%b:%b\n' "$g_color_yellow1" "$g_color_gray1" "containerd.service" \
                       "$g_color_yellow1" "$g_color_reset"
                printf '%b   export PATH="$PATH:$HOME/.files/shell/sh/cmds"%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   ~/.files/shell/sh/bin/containerd/containerd-rootless-setuptool.sh install%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   Opcional:%b\n' "$g_color_gray1" "$g_color_reset"
                printf '%b      > Para ingresar al user-namespace creado use:%b ~/.files/shell/sh/bin/containerd/containerd-rootless-setuptool.sh nsenter bash%b\n' "$g_color_gray1" \
                       "$g_color_yellow1" "$g_color_reset"
                printf '%b      > Establezca el servicio containerd para inicio manual:%b systemctl --user disable containerd.service%b\n' "$g_color_gray1" \
                       "$g_color_yellow1" "$g_color_reset"
                printf '%b2> Instalar en modo root%b (la unidad "%s" se ejecutara en modo system)%b:%b\n' "$g_color_yellow1" "$g_color_gray1" \
                       "containerd.service" "$g_color_yellow1" "$g_color_reset"
                printf '%b   sudo cp ~/.files/etc/containerd/systemd_root/containerd.service /usr/lib/systemd/system/%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   sudo systemctl daemon-reload%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   sudo systemctl start containerd%b\n' "$g_color_yellow1" "$g_color_reset"                 

            fi
            ;;


        buildkit)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/bin"

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            request_stop_systemd_unit 'buildkit.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Configurar: Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_on_command "${l_source_path}" "buildkit-runc" 0 1
            copy_binary_on_command "${l_source_path}" "buildkitd" 0 1
            copy_binary_on_command "${l_source_path}" "buildkit-qemu" 0 0
            copy_binary_on_command "${l_source_path}" "buildctl" 0 1

            #Descargar archivo de configuracion como servicio a nivel system:
            mkdir -p ${g_repo_path}/etc/buildkit/systemd_root
            mkdir -p ${g_repo_path}/etc/buildkit/systemd_user
            
            printf 'Descargando el archivo de configuracion de "%s" a nivel usuario en "%s"\n' "buildkit.service" "~/.files/etc/buildkit/systemd_user/"
            #curl -fLo ${g_repo_path}/.files/etc/buildkit/systemd_user/buildkit.service https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/user/buildkit-proxy.service
            curl -fLo ${g_repo_path}/etc/buildkit/systemd_user/buildkit.service https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/user/buildkit.service
            printf 'Descargando el archivo de configuracion de "%s" a nivel usuario en "%s"\n' "buildkit.socket" "~/.files/etc/buildkit/systemd_user/"
            curl -fLo ${g_repo_path}/etc/buildkit/systemd_user/buildkit.socket https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/user/buildkit-proxy.socket

            printf 'Descargando el archivo de configuracion de "%s" a nivel sistema en "%s"\n' "buildkit.service" "~/.files/etc/buildkit/systemd_root/"
            curl -fLo ${g_repo_path}/etc/buildkit/systemd_root/buildkit.service https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.service
            printf 'Descargando el archivo de configuracion de "%s" a nivel sistema en "%s"\n' "buildkit.socket" "~/.files/etc/buildkit/systemd_root/"
            curl -fLo ${g_repo_path}/etc/buildkit/systemd_root/buildkit.socket https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.socket


            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/buildkit/
            fi


            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:            
            if [ $l_status -eq 0 ]; then

                printf 'El artefacto de "%s" aun no esta aun esta instalada. Se recomiendo crear una unidad systemd "%s" para gestionar su inicio y detención.\n' \
                       "$p_repo_id" "buildkit.service"
                printf 'Para instalar "%s" tiene 2 opciones:\n' "$p_repo_id"
                printf '%b1> Instalar en modo rootless%b (la unidad "%s" se ejecutara en modo user)%b:%b\n' "$g_color_yellow1" "$g_color_gray1" "buildkit.service" \
                       "$g_color_yellow1" "$g_color_reset"
                printf '%b   export PATH="$PATH:$HOME/.files/shell/sh/bin/cmds"%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   ~/.files/shell/sh/bin/containerd/containerd-rootless-setuptool.sh install-buildkit%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   Opcional:%b\n' "$g_color_gray1" "$g_color_reset"
                printf '%b      > Para ingresar al user-namespace creado use:%b ~/.files/shell/sh/bin/containerd/containerd-rootless-setuptool.sh nsenter bash%b\n' "$g_color_gray1" "$g_color_yellow1" \
                       "$g_color_reset"
                printf '%b      > Establezca el servicio buildkit para inicio manual:%b systemctl --user disable buildkit.service%b\n' "$g_color_gray1" \
                       "$g_color_yellow1" "$g_color_reset"
                printf '%b2> Instalar en modo root%b (la unidad "%s" se ejecutara en modo system)%b:%b\n' "$g_color_yellow1" "$g_color_gray1" "buildkit.service" \
                       "$g_color_yellow1" "$g_color_reset"
                printf '%b   sudo cp ~/.files/etc/buildkit/systemd_root/buildkit.socket /usr/lib/systemd/system/%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   sudo cp ~/.files/etc/buildkit/systemd_root/buildkit.service /usr/lib/systemd/system/%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   sudo systemctl daemon-reload%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   sudo systemctl start buildkit.service%b\n' "$g_color_yellow1" "$g_color_reset"                 

            fi
            ;;


        nerdctl)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            local l_status_stop=-1
          

            #2. Configuración: Instalación de binario basico
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                copy_binary_on_command "${l_source_path}" "nerdctl" 0 1

                #Archivos para instalar 'containerd' de modo rootless
                echo "Copiando \"${l_source_path}/containerd-rootless.sh\" (tool gestión del ContainerD en modo rootless) a \"~/.files/shell/sh/bin/cmds\" ..."
                cp "${g_temp_path}/${l_source_path}/containerd-rootless.sh" ${g_repo_path}/shell/sh/bin/cmds/
                chmod u+x ${g_repo_path}/shell/sh/bin/cmds/containerd-rootless.sh

                echo "Copiando \"${l_source_path}/containerd-rootless-setuptool.sh\" (instalador de ContainerD en modo rootless)  a \"~/.files/shell/sh/bin/containerd\" ..."
                cp "${g_temp_path}/${l_source_path}/containerd-rootless-setuptool.sh" ${g_repo_path}/shell/sh/bin/containerd/
                chmod u+x ${g_repo_path}/shell/sh/bin/containerd/containerd-rootless-setuptool.sh

                #Fix permisos
                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/sh/bin/containerd/
                    chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/shell/sh/bin/cmds/
                fi

                #Crear el enlace simbolico de comandos basicos
                create_folderpath_on_home "" ".local/bin"
                create_filelink_on_home "${g_repo_name}/shell/sh/bin/cmds" "containerd-rootless.sh" ".local/bin" "containerd-rootless" "" 0

            #3. Configuración: Instalación de binarios de complementos que su reposotrio no ofrece el compilado (solo la fuente). Para ello se usa el full
            else

                #3.1. Rutas de los artectos 
                l_source_path="${p_repo_id}/${p_artifact_index}/bin"

                #3.2. Configurar 'rootless-containers/bypass4netns' usado para accelar 'Slirp4netns' (NAT o port-forwading de llamadas del exterior al contenedor)

                #Comparar la versión actual con la versión descargada
                _compare_version_current_with "bypass4netns" "${g_temp_path}/$l_source_path" $p_install_win_cmds
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then

                    #Instalar este artefacto requiere solicitar detener el servicio solo la versión actual existe
                    #Solo solicitarlo una vez
                    if [ $l_status_stop -ge 0 ]; then

                        is_package_installed 'containerd' $g_os_subtype_id
                        l_status_stop=$?

                        if [ $l_status_stop -eq 0 ]; then
                            printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" \
                                   "$g_color_red1" "$g_color_reset"
                        fi

                        request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
                        l_status_stop=$?
                    fi

                    #Si no esta iniciado o si esta iniciado se acepta detenerlo, instalarlo
                    if [ $l_status_stop -ne 2 ]; then

                        printf 'Instalando el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s ...\n' "$p_artifact_index" \
                               "$p_repo_id"
                        copy_binary_on_command "${l_source_path}" "bypass4netns" 0 1
                        copy_binary_on_command "${l_source_path}" "bypass4netnsd" 0 1

                    else

                        printf 'No se instalará el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s.\n' "$p_artifact_index" \
                               "$p_repo_id"

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
                    if [ $g_runner_id -eq 0 ]; then
                        systemctl start containerd.service 
                    else
                        sudo systemctl start containerd.service 
                    fi
                fi

            fi
            ;;



        k0s)

            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #1. Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #2. Si la nodo k0s esta iniciado, solicitar su detención
            request_stop_k0s_node 1 "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 1 ]; then
                return 41
            fi

            #3. Renombrar el binario antes de copiarlo
            echo "Moviendo \"${p_artifact_filename_woext}\" como \"${l_target_path}/k0s\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/k0s"

            copy_binary_on_command "${l_source_path}" "k0s" 0 1


            #4. Si el nodo k0s estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 2 ]; then

                printf 'Iniciando el nodo k0s...\n'
                if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then
                    k0s start
                else
                    sudo k0s start
                fi
            fi
            ;;


            
        awscli)

            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #Si root esta instalando el profile de otro usuario, no permitir (debe ejecutar el script con el usuario owner del home)
            #if [ $g_runner_is_target_user -ne 0 ]; then

            #    printf '%b  > Warning: El artefacto[%b%s%b] del respositorio "%b%s%b" solo lo puede instalar con su usuario "%b%s%b" owner\n' \
            #           "$g_color_yellow1" "$g_color_gray1" "$p_artifact_index" "$g_color_yellow1" "$g_color_gray1" "$p_repo_id" "$g_color_yellow1" \
            #           "$g_color_gray1" "$g_targethome_owner" "$g_color_yellow1"
            #    printf '             Luego de esta configuracion, realize nuevamente la configuracion usando el usuario "%b%s%b"%b\n' \
            #           "$g_color_gray1" "$g_targethome_owner" "$g_color_yellow1" "$g_color_reset"

            #    return 0
            #fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Creando el folder si no existe y no limpiarlo si existe
            create_or_clean_folder_on_program "aws-cli" "" 0 0

            #Instalando 
            if [ $p_flag_install -eq 0 ]; then

                #Ejecutando los script de instalación
                exec_setupscript_to_program "${l_source_path}/aws" "install" "aws-cli" "-i " "-b ${g_programs_path}/aws-cli"

            #Actualizando
            else

                #Ejecutando los script de instalación
                exec_setupscript_to_program "${l_source_path}/aws" "install" "aws-cli" "-i " "-b ${g_programs_path}/aws-cli --update"

            fi
            ;;


        rust)

            #No habilitado para Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #Crear el folder de programa si no existe pero NO Limpiar el contenido si existe (el 'install.sh' puede eliminar versiones anteriores)
            create_or_clean_folder_on_program "rust" "" 0 0

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Las componente por defecto del instalador 'standalone' (no incluye 'rust-src')
            if [ $p_artifact_index -eq 0 ]; then

                #Ejecutando los script de instalación
                printf '> Copiando los archivos a la ruta "%b%s%b", usando el instalador "%b%s%b" ...\n' "$g_color_gray1" \
                       "${g_temp_path}/${l_source_path}" "$g_color_reset" "$g_color_gray1" "install.sh" "$g_color_reset"
                exec_setupscript_to_program "${l_source_path}" "install.sh" "rust" "--prefix=" \
                    "--without='rust-analyzer-preview,llvm-tools-preview' --disable-ldconfig"

                #Registrando las librerias del rust "${g_programs_path}/rust/lib"

                #Copiando los archivos ayudas a la carpeta de ayuda del sistema
                copy_man_files "${g_programs_path}/rust/share/man/man1" 1

                register_dynamiclibrary_to_system "rust/lib" "rust"


            #Las componente por defecto de 'rust-src'
            else
            
                #Ejecutando los script de instalación
                exec_setupscript_to_program "${l_source_path}" "install.sh" "rust" "--prefix=" "--disable-ldconfig"

            fi

            #Validar si 'DotNet' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/rust/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "Rust"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/rust/bin:$PATH\n' "${g_programs_path}"

                PATH="${g_programs_path}/rust/bin:$PATH"
                export PATH
            fi
            ;;



        nerd-fonts)
            
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            
            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                #Copiando los archivos de fuente '*.otf' y '*.ttf' a la ruta de fuentes (nunca actualizar el cache si es la ultima fuente instalada)
                copy_font_files "$l_source_path" 1 "${p_artifact_filename_woext}" 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_program "" "nerd-fonts.info" "$p_repo_last_pretty_version" 1

                printf '%bDeberá instalar (copiar) manualmente los archivos%b de "%s" en "%s".\n' "$g_color_yellow1" \
                       "$g_color_reset" "$g_win_font_path" "C:/Windows/Fonts"

                return 0

            fi

            #B. Si es Linux

            #Copiando los archivos de fuente '*.otf' y '*.ttf' a la ruta de fuentes (solo actualizar el cache si es la ultima fuente instalada)
            copy_font_files "$l_source_path" 0 "${p_artifact_filename_woext}" $p_artifact_is_last

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_program "" "nerd-fonts.info" "$p_repo_last_pretty_version" 0
            ;;
        


        protoc)
            
            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_program "protoc" "" 1 1

                #Moviendo el cotenido del folder source al folder de programa
                move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 1 "protoc" ""
                #move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 1 "protoc" "-not -name '${p_artifact_filename_woext}.zip'"
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "protoc" "" 0 1

            #Moviendo el cotenido del folder source al folder de programa
            move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 0 "protoc" ""
            #move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 0 "protoc" "-not -name '${p_artifact_filename_woext}.tar.gz'"


            #Validar si 'protoc' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/protoc/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "ProtoC"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/protoc/bin:$PATH\n' "${g_programs_path}"
                export PATH=${g_programs_path}/protoc/bin:$PATH
            fi
            ;;


        roslyn)
            
            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_program "lsp_servers" "omnisharp_roslyn" 1 1

                move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 1 "lsp_servers/omnisharp_Roslyn" ""
                #move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 1 "LSP_Servers/Omnisharp_Roslyn" "-not -name '${p_artifact_filename_woext}.zip'"
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "lsp_servers" "omnisharp_roslyn" 0 1

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 0 "lsp_servers/omnisharp_roslyn" ""
            #move_tempfoldercontent_on_program "${p_repo_id}/${p_artifact_index}" 0 "lsp_servers/omnisharp_roslyn" "-not -name '${p_artifact_filename_woext}.tar.gz'"
            ;;


        netcoredbg)
            
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/netcoredbg"

            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_program "dap_servers" "netcoredbg" 1 1

                move_tempfoldercontent_on_program "$l_source_path" 1 "dap_servers/netcoredbg" ""
                #move_tempfoldercontent_on_program "$l_source_path" 1 "dap_servers/netcoredbg" "-not -name '${p_artifact_filename_woext}.zip'"
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "dap_servers" "netcoredbg" 0 1

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_program "$l_source_path" 0 "dap_servers/netcoredbg" ""
            #move_tempfoldercontent_on_program "$l_source_path" 0 "dap_servers/netcoredbg" "-not -name '${p_artifact_filename_woext}.tar.gz'"
            ;;



        clangd)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/clangd_${p_repo_last_version}"


            #A. Si es WSL de Windows
            if [ $p_install_win_cmds -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_program "lsp_servers" "clangd" 1 1

                move_tempfoldercontent_on_program "$l_source_path" 1 "lsp_servers/clangd" ""
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "lsp_servers" "clangd" 0 1

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_program "$l_source_path" 0 "lsp_servers/clangd" ""
            ;;



        jdtls)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_program "lsp_servers" "jdtls" 1 1

                move_tempfoldercontent_on_program "$l_source_path" 1 "lsp_servers/jdtls" ""
                return 0

            fi


            #B. Si son binarios Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "lsp_servers" "jdtls" 0 1

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_program "$l_source_path" 0 "lsp_servers/jdtls" ""
            ;;



        cni-plugins)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                

            #1. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" \
                       "$g_color_red1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #2. Realizando la configuración
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "cni_plugins" "" 0 1

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_program "$l_source_path" 0 "cni_plugins" ""

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_program "" "cni-plugins.info" "$p_repo_last_pretty_version" 0

            #3. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo
            if [ $l_status -eq 3 ]; then

                #Iniciar a nivel usuario
                printf 'Iniciando la unidad "%s" a nivel usuario ...\n' 'containerd.service'
                systemctl --user start containerd.service

            elif [ $l_status -eq 4 ]; then

                #Iniciar a nivel system
                printf 'Iniciando la unidad "%s" a nivel sistema ...\n' 'containerd.service'
                if [ $g_runner_id -eq 0 ]; then
                    systemctl start containerd.service 
                else
                    sudo systemctl start containerd.service 
                fi
            fi
            ;;



        ctags-nowin)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi

            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}"
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "ctags" "bin" 0 1

            #Copiando los binarios
            copy_binary_on_program "${l_source_path}/bin" "ctags" 0 "ctags/bin" 1 
            copy_binary_on_program "${l_source_path}/bin" "optscript" 0 "ctags/bin" 1 
            copy_binary_on_program "${l_source_path}/bin" "readtags" 0 "ctags/bin" 1 

            #Adicionar los archivos ayudas a la carpeta de ayuda del sistema
            copy_man_files "${g_temp_path}/${l_source_path}/man/man1" 1
            copy_man_files "${g_temp_path}/${l_source_path}/man/man5" 5
            copy_man_files "${g_temp_path}/${l_source_path}/man/man7" 7

            #Debido que no existe relacion entre la version actual y la version de github, se almacenara la version github que se esta instalando
            save_prettyversion_on_program "" "ctags.info" "$p_repo_last_pretty_version" 0
            ;;


        ctags-win)

            #No se soportado por Windows 
            if [ $p_install_win_cmds -ne 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Windows" "$g_color_reset" 
                return 40
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "ctags" "bin" 1 1
                    
            #Copiando los binarios
            copy_binary_on_program "${l_source_path}" "ctags.exe" 1 "ctags/bin" 1 
            copy_binary_on_program "${l_source_path}" "readtags.exe" 1 "ctags/bin" 1 

            #Mover folderes a la carpeta del programa
            move_tempfolder_on_program "${l_source_path}" "man" 1 "ctags"
            move_tempfolder_on_program "${l_source_path}" "docs" 1 "ctags"

            #Debido que no existe relacion entre la version actual y la version de github, se almacenara la version github que se esta instalando
            save_prettyversion_on_program "" "ctags.info" "$p_repo_last_pretty_version" 1
            ;;




        powershell)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_program "powershell" "" 1 2

                #Descomprimir
                uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "powershell" 0 "" ""
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0
            fi


            #B. Si son binarios Linux
            
            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "powershell" "" 0 2

            #Descomprimir
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "powershell" 0 "" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Creando los enlaces simbolicos
            create_binarylink_to_command "powershell" "pwsh" "pwsh"
            ;;


        wezterm)
            
            #A. Si son binarios Linux
            if [ $p_install_win_cmds -eq 0 ]; then
                return 0
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_program "wezterm" "" 1 2

            #Descomprimir
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "wezterm" 0 "" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi
            ;;



        neovim)
            
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                #Descomprimir
                uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "" 0 "neovim" "$p_artifact_filename_woext"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0
            fi


            #B. Si son binarios Linux
            
            #Descomprimir
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "" 0 "neovim" "$p_artifact_filename_woext"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi
            
            #Validar si 'nvim' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/neovim/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "NeoVIM"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/neovim/bin:$PATH\n' "${g_programs_path}"
                export PATH=${g_programs_path}/neovim/bin:$PATH
            fi

            ;;



        llvm)
           
            #No se soportado por Windows 
            if [ $p_install_win_cmds -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset" 
                return 40
            fi
                
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Descomprimir
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "" 0 "llvm" "clang+llvm"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'LLVM' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/llvm/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "Go"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/llvm/bin:$PATH\n' "${g_programs_path}"
                export PATH=${g_programs_path}/llvm/bin:$PATH
            fi
            ;;


        net-sdk|net-rt-core|net-rt-aspnet)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                #Creando el folder si no existe y no limpiarlo si existe
                create_or_clean_folder_on_program "dotnet" "" 1 0

                #Si se instala (no existe version anterior instalado del respositorio)
                if [ $p_flag_install -eq 0  ]; then

                    #Descomprimiendo el archivo sin eliminar el contenido existente
                    uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "dotnet" 1 "" ""
                    l_status=$?
                    if [ $l_status -ne 0 ]; then
                        return 40
                    fi

                else

                    #Sincronizando los archivos descomprimidos con el path
                    syncronize_folders "$l_source_path" 1 "dotnet"
                    l_status=$?
                    if [ $l_status -ne 0 ]; then
                        return 40
                    fi


                fi

                return 0

            fi

            #B. Si son binarios Linux

            #Creando el folder si no existe y no limpiarlo si existe
            create_or_clean_folder_on_program "dotnet" "" 0 0

            #Si se instala (no existe version anterior instalado del respositorio)
            if [ $p_flag_install -eq 0  ]; then

                #Descomprimiendo el archivo
                uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "dotnet" 1 "" ""
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi


            else


                #Sincronizando los archivos descomprimidos con el path
                syncronize_folders "$l_source_path" 0 "dotnet"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

            fi

            #Validando si dotnet esta registrado en el PATH del usuario
            echo "$PATH" | grep "${g_programs_path}/dotnet" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "DotNet"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/dotnet:$PATH\n' "${g_programs_path}"

                export DOTNET_ROOT=${g_programs_path}/dotnet
                PATH=${g_programs_path}/dotnet:$PATH                    
                if [ "$p_repo_id" = "net-sdk" ]; then
                    PATH=${g_programs_path}/dotnet/tools:$PATH
                fi
                export PATH
            fi
            ;;



        go)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                #Descomprimiendo el archivo
                uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "" 0 "go" ""
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                printf 'Instalé/actualizé el modulo go %s ejecutando:  %b%s%b\n' 'LSP "gopls"' "$g_color_yellow1" \
                       'go install golang.org/x/tools/gopls@latest' "$g_color_reset"
                printf 'Instalé/actualizé el modulo go %s ejecutando:  %b%s%b\n' 'DAP "delve"' "$g_color_yellow1" \
                       'go install github.com/go-delve/delve/cmd/dlv@latest' "$g_color_reset"
                
                return 0
            fi

            #B. Si son binarios Linux

            #Descomprimiendo el archivo
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "" 0 "go" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'Go' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/go/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "Go"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/go/bin:$PATH\n' "${g_programs_path}"
                PATH=${g_programs_path}/go/bin:$PATH
                export PATH=$PATH:~/go/bin
            fi

            #Dentro del home del usuario objetivo, crear '~/go/bin' si no existe
            create_folderpath_on_home "" "go/bin"

            #Solo instalar paquete basicos, solo si runner es el usuario objetivo
            if [ $g_runner_is_target_user -eq 0 ]; then

                #Instalar o actualizar el modulo go: LSP 'gopls'
                printf 'Instalando/actualizando el modulo go %s %b(en "~/go/bin")%b...\n' 'LSP "gopls"' "$g_color_gray1" "$g_color_reset"
                go install golang.org/x/tools/gopls@latest
                l_aux=$(gopls version | grep 'gopls v' | sed "$g_regexp_sust_version1" 2> /dev/null)
                printf 'Modulo go %s con la version "%b%s%b" esta instalado.\n' 'LSP "gopls"' "$g_color_gray1" "$l_aux" "$g_color_reset" 

                #Instalar o actualizar el modulo go: DAP 'delve'
                printf 'Instalando/actualizando el modulo go %s %b(en "~/go/bin")%b...\n' 'DAP "delve"' "$g_color_gray1" "$g_color_reset"
                go install github.com/go-delve/delve/cmd/dlv@latest
                l_aux=$(dlv version | grep 'Version:' | sed "$g_regexp_sust_version1" 2> /dev/null)
                printf 'Modulo go %s con la version "%b%s%b" esta instalado.\n' 'DAP "delve"' "$g_color_gray1" "$l_aux" "$g_color_reset"

            else

                printf 'Instalé/actualizé el modulo go %s ejecutando:  %b%s%b\n' 'LSP "gopls"' "$g_color_yellow1" \
                       'go install golang.org/x/tools/gopls@latest' "$g_color_reset"
                printf 'Instalé/actualizé el modulo go %s ejecutando:  %b%s%b\n' 'DAP "delve"' "$g_color_yellow1" \
                       'go install github.com/go-delve/delve/cmd/dlv@latest' "$g_color_reset"

            fi
            ;;



        nodejs)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                #Descomprimiendo el archivo
                uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "" 0 "nodejs" "${p_artifact_filename_woext}"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0

            fi


            #B. Si son binarios Linux

            #Descomprimiendo el archivo
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "" 0 "nodejs" "${p_artifact_filename_woext}"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi


            #Validar si 'Node.JS' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/nodejs/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "Node.JS"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_programs_path}"
                export PATH=${g_programs_path}/nodejs/bin:$PATH
            fi
            ;;


        cmake)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                #Descomprimiendo el archivo
                uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "" 0 "cmake" "${p_artifact_filename_woext}"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0

            fi


            #B. Si son binarios Linux

            #Descomprimiendo el archivo
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "" 0 "cmake" "${p_artifact_filename_woext}"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'CMake' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/cmake/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "CMake"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/cmake/bin:$PATH\n' "${g_programs_path}"
                export PATH=${g_programs_path}/cmake/bin:$PATH
            fi
            ;;



        graalvm)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"
            
            #No eso se instalaran los plugins (use 'gu install [tool-name]'):
            # Native Image
            # VisualVM
            # LLVM
            # JavaScript (GraalJS)
            # Node.js
            # Python (GraalPy)
            # Ruby (TruffleRuby)
            # R (FastR)
            # WebAssembly (Wasm)
            # Java on Truffle (Espresso)

            #A. Si son binarios Windows 
            if [ $p_install_win_cmds -eq 0 ]; then

                l_target_path="graalvm"
                if [ $p_arti_subversion_index -ne 0 ]; then
                    l_target_path="${l_target_path}_${p_arti_subversion_version}"
                fi

                #Descomprimiendo el archivo
                uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 2 "" 0 "$l_target_path" "graalvm-community-"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0

            fi


            #B. Si son binarios Linux
            l_target_path="graalvm"
            if [ $p_arti_subversion_index -ne 0 ]; then
                l_target_path="${l_target_path}_${p_arti_subversion_version}"
            fi

            #Descomprimiendo el archivo
            uncompress_on_folder "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) 1 "" 0 "$l_target_path" "graalvm-community-"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'GraalVM' esta en el PATH
            echo "$PATH" | grep "${g_programs_path}/graalvm/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_red1" "GraalVM"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/graalvm/bin:$PATH\n' "${g_programs_path}"
                export PATH=${g_programs_path}/graalvm/bin:$PATH
                GRAALVM_HOME=${g_programs_path}/graalvm
                JAVA_HOME=${GRAALVM_HOME}
                export GRAALVM_HOME JAVA_HOME
            fi
            ;;




        *)
           printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" no tiene un logica definida para su setup%b.\n' \
                  "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                  "$g_color_gray1" "$p_repo_id" "$g_color_red1" "$g_color_reset" 
           return 50
           ;;
            
    esac

    return 0

}


#}}}


#Funciones modificables (Nivel 5) {{{



#
#La inicialización del menú opcion de instalación (codigo que se ejecuta antes de instalar los repositorios de la opcion menú)
#Solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index (inicia en 0) de la opcion de menu elegista para instalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si inicializo con exito.
#  1 > No se inicializo por opcion del usuario.
#  2 > Hubo un error en la inicialización.
#
install_initialize_menu_option() {

    #1. Argumentos
    local p_option_relative_idx=$1

    #2. Inicialización
    local l_status
    local l_repo_id
    local l_artifact_index

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 3 ] || [ $gp_type_calling -eq 4 ]; then
        l_is_noninteractive=0
    fi

    #local l_aux
    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))

    #3. Realizar validaciones segun la opcion de menu escogida
    case "$p_option_relative_idx" in

        #Container Runtime 'ContainerD'
        7)
            #Los valores son solo para logs, pero se calcular manualmente
            l_repo_id='containerd'
            
            #1. Determinar si el paquete 'containerd.io' esta instalado en el sistema operativo
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            #Si existe el paquete no instalar nada
            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" "$g_color_red1" "$g_color_reset"
                printf 'Solo se puede instalar si no se instalo usando el repositorio de github. No se puede desintalar si se instalo usando repositorio de paquetes del SO.\n'
                return 2
            fi
            ;;

        #Instalacion de DotNet (runtime o SDK o ambos)
        13)

            #Solo soportado para los que tenga acceso a root
            if [ $g_runner_sudo_support -ne 2 ] && [ $g_runner_sudo_support -ne 3 ]; then

                #print_line '─' $g_max_length_line  "$g_color_blue1"
                printf "> Instalando las %blibrerias%b requeridas por %b.NET%b...\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
                #print_line '─' $g_max_length_line "$g_color_blue1"

                #Parametros:
                # 1> Tipo de ejecución: 2/4 (ejecución sin menu, para instalar/actualizar un grupo paquetes)
                # 2> Paquetes a instalar 
                # 3> El estado de la credencial almacenada para el sudo
                # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
                if [ $l_is_noninteractive -eq 1 ]; then
                    ${g_repo_path}/shell/bash/bin/linuxsetup/03_setup_repo_packages.bash 2 'dotnetlib' $g_status_crendential_storage 1
                    l_status=$?
                else
                    ${g_repo_path}/shell/bash/bin/linuxsetup/03_setup_repo_packages.bash 4 'dotnetlib' $g_status_crendential_storage 1
                    l_status=$?
                fi

                #Si no se acepto almacenar credenciales
                if [ $l_status -eq 120 ]; then
                    return 120
                #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
                elif [ $l_status -eq 119 ]; then
                    g_status_crendential_storage=0
                fi

            fi
            
            #OK
            return 0
            ;;        

        *)
            return 0
            ;;
    esac

    #Por defecto, se debe continuar con la instalación
    return 0


}

#
#La finalización del menú opcion de instalación (codigo que se ejecuta despues de instalar todos los repositorios de la opcion de menú)
#Solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para instalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
install_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #Realizar validaciones segun la opcion de menu escogida

    #Por defecto, se debe continuar con la instalación
    return 0

}

#}}}



#------------------------------------------------------------------------------------------------------------------
#> Funciones de utilidad para la desinstalación {{{
#------------------------------------------------------------------------------------------------------------------

#Codigo que se ejecuta cuando se inicializa la opcion de menu de desinstalación.
#La inicialización solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si inicializo con exito.
#  1 > No se inicializo por opcion del usuario.
#  2 > Hubo un error en la inicialización.
#
uninstall_initialize_menu_option() {

    #1. Argumentos
    local p_option_relative_idx=$1

    #2. Inicialización
    local l_status
    #local l_artifact_index
    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 3 ] || [ $gp_type_calling -eq 4 ]; then
        l_is_noninteractive=0
    fi
    
    #3. Preguntar antes de eliminar los archivos
    printf 'Se va ha iniciar con la desinstalación de los siguientes repositorios: '
    
    #Obtener los repositorios a configurar
    local l_aux="${ga_menu_options_packages[$l_i]}"
    local IFS=','
    local la_repos=(${l_aux})
    IFS=$' \t\n'

    local l_n=${#la_repos[@]}
    local l_repo_names=''
    local l_repo_id
    for((l_j=0; l_j < ${l_n}; l_j++)); do

        l_repo_id="${la_repos[${l_j}]}"
        l_aux="${gA_packages[${l_repo_id}]}"
        if [ -z "$l_aux" ] || [ "$l_aux" = "$g_empty_str" ]; then
            l_aux="$l_repo_id"
        fi

        if [ $l_j -eq 0 ]; then
            l_repo_names="'${g_color_gray1}${l_aux}${g_color_reset}'" 
        else
            l_repo_names="${l_repo_names}, '${g_color_gray1}${l_aux}${g_color_reset}'"
        fi

    done
    printf '%b\n' "$l_repo_names"

    if [ $l_is_noninteractive -ne 0 ]; then
        printf "%b¿Desea continuar con la desinstalación de estos repositorios?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_red1" "$g_color_gray1" "$g_color_reset"
        read -rei 's' -p ': ' l_option
        if [ "$l_option" != "s" ]; then
            printf 'Se cancela la desinstalación de los repositorios\n'
            return 1
        fi
    fi
    

    #4. Realizar validaciones segun la opcion de menu escogida
    case "$p_option_relative_idx" in

        #Container Runtime 'ContainerD'
        7)
            #Los valores son solo para logs
            l_repo_id='containerd'
            
            #1. Determinar si el paquete 'containerd.io' esta instalado en el sistema operativo
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            #Si existe el paquete no desintalar nada
            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" "$g_color_red1" "$g_color_reset"
                printf 'Solo se puede desinstalar si no se instalo usando el repositorio de github. No se puede desintalar si se instalo usando repositorio de paquetes del SO.\n'
                return 2
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            request_stop_systemd_unit 'containerd.service' 0 $l_is_noninteractive "$l_repo_id"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 1
            fi
        
            #"Tools para cualquier Container Runtime": BuildKit
            #Los valores son solo para logs
            l_repo_id='buildkit'
            
            #1. Determinar si el paquete 'containerd.io' esta instalado en el sistema operativo
            is_package_installed 'buildkit' $g_os_subtype_id
            l_status=$?

            #Si existe el paquete no desintalar nada
            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "buildkit" "$g_color_reset" "$g_color_red1" "$g_color_reset"
                printf 'Solo se puede desinstalar si no se instalo usando el repositorio de github. No se puede desintalar si se instalo usando repositorio de paquetes del SO.\n'
                return 2
            fi

            #2. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            request_stop_systemd_unit 'buildkit.service' 0 $l_is_noninteractive "$l_repo_id"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 1
            fi
            ;;

        *)
            return 0
            ;;
    esac

    #Por defecto, se debe continuar con la instalación
    return 0

}

#Codigo que se ejecuta cuando se finaliza la opcion de menu de desinstalación.
#La finalización solo se hara en Linux (en Windows la configuración es basica que no lo requiere y solo se copia los binarios)
#
#Los argumentos de entrada son:
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menu_options_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
uninstall_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menu_options_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))


    #Realizar validaciones segun la opcion de menu escogida

    #Por defecto, se debe continuar con la instalación
    return 0

}




#Only for test
_uninstall_repository2() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_current_pretty_version="$2"
    local p_install_win_cmds=1
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #2. Inicialización de variables
    local l_repo_name="${gA_packages[$p_repo_id]}"
    #local l_repo_name_aux="${l_repo_name:-$p_repo_id}"
    if [ "$l_repo_name" = "$g_empty_str" ]; then
        l_repo_name=''
    fi
    
    #Tag usuado para imprimir un identificador del artefacto en un log
    local l_tag="${p_repo_id}[${p_repo_current_pretty_version}]"

    printf 'No esta definido logica para desintalar los artectactos del repositorio "%s"\n' "$l_tag"
}

#
#Los argumentos de entrada son:
#  1 > ID del repositorio
#  2 > Nombre del repostorio
#  3 > Version del repositorio
#  4 > Flag '0' si es artefacto instalado en Windows (asociado a WSL2)
_uninstall_repository() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_current_pretty_version="$2"
    local p_install_win_cmds=1
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #2. Inicialización de variables
    local l_repo_name="${gA_packages[$p_repo_id]}"
    if [ "$l_repo_name" = "$g_empty_str" ]; then
        l_repo_name=''
    fi

    #local l_repo_name_aux="${l_repo_name:-$p_repo_id}"

    local l_source_path=""
    local l_target_path=""
    if [ $p_install_win_cmds -ne 0 ]; then
        l_target_path="$g_bin_cmdpath"
    else
        l_target_path="$g_win_bin_path"
    fi

    local l_status
    local l_flag_uninstall
    local l_aux

    case "$p_repo_id" in


        runc)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux"
                return 40
            fi

            #2. Eliminando los archivos
            echo "Eliminado \"runc\" de \"${l_target_path}\" ..."
            if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then
                rm "${l_target_path}/runc"
            else
                sudo rm "${l_target_path}/runc"
            fi
            ;;


        slirp4netns)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos 
            echo "Eliminando \"slirp4netns\" de \"${l_target_path}\" ..."
            if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then
                if [ -f "${l_target_path}/slirp4netns" ]; then
                    rm "${l_target_path}/slirp4netns"
                fi
            else
                if [ -f "${l_target_path}/slirp4netns" ]; then
                    sudo rm "${l_target_path}/slirp4netns"
                fi
            fi
            ;;


        rootlesskit)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos 
            if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then

                if [ -f "${l_target_path}/rootlesskit-docker-proxy" ]; then
                    echo "Eliminando \"rootlesskit-docker-proxy\" a \"${l_target_path}\" ..."
                    rm "${l_target_path}/rootlesskit-docker-proxy"
                fi

                if [ -f "${l_target_path}/rootlesskit" ]; then
                    echo "Eliminando \"rootlesskit\" a \"${l_target_path}\" ..."
                    rm "${l_target_path}/rootlesskit"
                fi

                if [ -f "${l_target_path}/rootlessctl" ]; then
                    echo "Eliminando \"rootlessctl\" a \"${l_target_path}\" ..."
                    rm "${l_target_path}/rootlessctl"
                fi

            else

                if [ -f "${l_target_path}/rootlesskit-docker-proxy" ]; then
                    echo "Eliminando \"rootlesskit-docker-proxy\" a \"${l_target_path}\" ..."
                    sudo rm "${l_target_path}/rootlesskit-docker-proxy"
                fi

                if [ -f "${l_target_path}/rootlesskit" ]; then
                    echo "Eliminando\"rootlesskit\" a \"${l_target_path}\" ..."
                    sudo rm "${l_target_path}/rootlesskit"
                fi

                if [ -f "${l_target_path}/rootlessctl" ]; then
                    echo "Eliminando \"rootlessctl\" a \"${l_target_path}\" ..."
                    sudo rm "${l_target_path}/rootlessctl"
                fi

            fi
            ;;



        cni-plugins)

            #1. Ruta local de los artefactos
            l_target_path="${g_programs_path}/cni_plugins"

            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos
            if  [ -d "$l_target_path" ]; then

                #Elimimiando los binarios
                echo "Eliminando los binarios de \"${l_target_path}\" ..."
                if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then
                    rm ${l_target_path}/*
                else
                    sudo rm ${l_target_path}/*
                fi

            fi

            #3. Eliminado el archivo para determinar la version actual
            rm "${g_programs_path}/cni-plugins.info" 
            ;;


        containerd)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi


            #2. Eliminando archivos 
            if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then

                if [ -f "${l_target_path}/containerd-shim" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-shim\"..."
                    rm "${l_target_path}/containerd-shim"
                fi

                if [ -f "${l_target_path}/containerd-shim-runc-v1" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-shim-runc-v1\"..."
                    rm "${l_target_path}/containerd-shim-runc-v1"
                fi

                if [ -f "${l_target_path}/containerd-shim-runc-v2" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-shim-runc-v2\"..."
                    rm "${l_target_path}/containerd-shim-runc-v2"
                fi

                if [ -f "${l_target_path}/containerd-stress" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-stress\"..."
                    rm "${l_target_path}/containerd-stress"
                fi

                if [ -f "${l_target_path}/ctr" ]; then
                    echo "Eliminando \"${l_target_path}/ctr\"..."
                    rm "${l_target_path}/ctr"
                fi

                if [ -f "${l_target_path}/containerd" ]; then
                    echo "Eliminando \"${l_target_path}/containerd\"..."
                    rm "${l_target_path}/containerd"
                fi

            else

                if [ -f "${l_target_path}/containerd-shim" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-shim\"..."
                    sudo rm "${l_target_path}/containerd-shim"
                fi

                if [ -f "${l_target_path}/containerd-shim-runc-v1" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-shim-runc-v1\"..."
                    sudo rm "${l_target_path}/containerd-shim-runc-v1"
                fi

                if [ -f "${l_target_path}/containerd-shim-runc-v2" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-shim-runc-v2\"..."
                    sudo rm "${l_target_path}/containerd-shim-runc-v2"
                fi

                if [ -f "${l_target_path}/containerd-stress" ]; then
                    echo "Eliminando \"${l_target_path}/containerd-stress\"..."
                    sudo rm "${l_target_path}/containerd-stress"
                fi

                if [ -f "${l_target_path}/ctr" ]; then
                    echo "Eliminando \"${l_target_path}/ctr\" ..."
                    sudo rm "${l_target_path}/ctr"
                fi

                if [ -f "${l_target_path}/containerd" ]; then
                    echo "Eliminando \"${l_target_path}/containerd\"..."
                    sudo rm "${l_target_path}/containerd"
                fi

            fi

            #3. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo

            #Buscar si esta instalado a nive usuario
            local l_is_user=0
            exist_systemd_unit "containerd.service" $l_is_user
            l_status=$?   #  0 > La unidad no esta instalada (no tiene archivo de configuracion): 
                          #  1 > La unidad instalada pero aun no esta en cache (no ha sido ejecutada desde el inicio del SO)
                          #  2 > La unidad instalada, en cache, pero marcada para no iniciarse ('unmask', 'inactive').
                          #  3 > La unidad instalada, en cache, pero no iniciado ('loaded', 'inactive').
                          #  4 > La unidad instalada, en cache, iniciado y aun ejecutandose ('loaded', 'active'/'running').
                          #  5 > La unidad instalada, en cache, iniciado y esperando peticionese ('loaded', 'active'/'waiting').
                          #  6 > La unidad instalada, en cache, iniciado y terminado ('loaded', 'active'/'exited' or 'dead').
                          #  7 > La unidad instalada, en cache, iniciado pero se desconoce su subestado.
                          # 99 > La unidad instalada, en cache, pero no se puede leer su información.
        
            if [ $l_status -eq 0 ]; then
        
                #Averiguar si esta instalado a nivel system
                l_is_user=1
                exist_systemd_unit "containerd.service" $l_is_user
                l_status=$?
       
               #Si no esta instalado en nivel user ni system 
                if [ $l_status -eq 0 ]; then
                    return 0
                fi
            fi

            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:
            l_aux="containerd.service"

            if [ $l_status -ne 0 ]; then

                if [ $l_is_user -eq 0 ]; then

                    if [ -f ${g_targethome_path}/.config/systemd/user/${l_aux} ]; then

                        #Si esta configurado para inicio automatico desactivarlo
                        printf "Disable la unidad systemd '%s'" "$l_aux"
                        systemctl --user disable $l_aux

                        echo "Eliminando la configuración '~/.config/systemd/user/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                        rm ${g_targethome_path}/.config/systemd/user/${l_aux}

                        #Recargar el arbol de dependencies cargados por systemd
                        printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                        systemctl --user daemon-reload
                    fi

                else

                    if [ -f /usr/lib/systemd/system/${l_aux} ]; then

                        if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            systemctl daemon-reload

                        else

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            sudo systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            sudo rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            sudo systemctl daemon-reload

                        fi
                    fi

                fi
            fi
            ;;


        buildkit)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando archivos 
            if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then

                if [ -f "${l_target_path}/buildkit-runc" ]; then
                    echo "Eliminando \"${l_target_path}/buildkit-runc\"..."
                    rm "${l_target_path}/buildkit-runc"
                fi

                if [ -f "${l_target_path}/buildkitd" ]; then
                    echo "Eliminando \"${l_target_path}/buildkitd\"..."
                    rm "${l_target_path}/buildkitd"
                fi

                if [ -f "${l_target_path}/buildkit-qemu-*" ]; then
                    echo "Eliminando \"${l_target_path}/buildkit-qemu-*\"..."
                    rm ${l_target_path}/buildkit-qemu-*
                fi

                if [ -f "${l_target_path}/buildctl" ]; then
                    echo "Eliminando \"${l_target_path}/buildctl\"..."
                    rm "${l_target_path}/buildctl"
                fi

            else

                if [ -f "${l_target_path}/buildkit-runc" ]; then
                    echo "Eliminando \"${l_target_path}/buildkit-runc\"..."
                    sudo rm "${l_target_path}/buildkit-runc"
                fi

                if [ -f "${l_target_path}/buildkitd" ]; then
                    echo "Eliminando \"${l_target_path}/buildkitd\"..."
                    sudo rm "${l_target_path}/buildkitd"
                fi

                if [ -f "${l_target_path}/buildkit-qemu-*" ]; then
                    echo "Eliminando \"${l_target_path}/buildkit-qemu-*\"..."
                    sudo rm ${l_target_path}/buildkit-qemu-*
                fi

                if [ -f "${l_target_path}/buildctl" ]; then
                    echo "Eliminando \"${l_target_path}/buildctl\"..."
                    sudo rm "${l_target_path}/buildctl"
                fi

            fi

            #3. Si la unidad servicio 'containerd' estaba iniciando y se detuvo, iniciarlo

            #Buscar si esta instalado a nive usuario
            local l_is_user=0
            exist_systemd_unit "buildkit.service" $l_is_user
            l_status=$?   #  1 > La unidad instalada pero aun no esta en cache (no ha sido ejecutada desde el inicio del SO)
                          #  2 > La unidad instalada, en cache, pero marcada para no iniciarse ('unmask', 'inactive').
                          #  3 > La unidad instalada, en cache, pero no iniciado ('loaded', 'inactive').
                          #  4 > La unidad instalada, en cache, iniciado y aun ejecutandose ('loaded', 'active'/'running').
                          #  5 > La unidad instalada, en cache, iniciado y esperando peticionese ('loaded', 'active'/'waiting').
                          #  6 > La unidad instalada, en cache, iniciado y terminado ('loaded', 'active'/'exited' or 'dead').
                          #  7 > La unidad instalada, en cache, iniciado pero se desconoce su subestado.
                          # 99 > La unidad instalada, en cache, pero no se puede leer su información.
        
            if [ $l_status -eq 0 ]; then
        
                #Averiguar si esta instalado a nivel system
                l_is_user=1
                exist_systemd_unit "buildkit.service" $l_is_user
                l_status=$?
        
               #Si no esta instalado en nivel user ni system 
                if [ $l_status -eq 0 ]; then
                    return 0
                fi
            fi

            #5. Si no esta instalado como unidad de systemd, indicar el procedimiento:
            l_aux="buildkit.service"

            if [ $l_status -ne 0 ]; then

                if [ $l_is_user -eq 0 ]; then

                    if [ -f ${g_targethome_path}/.config/systemd/user/${l_aux} ]; then

                        #Si esta configurado para inicio automatico desactivarlo
                        printf "Disable la unidad systemd '%s'" "$l_aux"
                        systemctl --user disable $l_aux

                        echo "Eliminando la configuración '~/.config/systemd/user/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                        rm ${g_targethome_path}/.config/systemd/user/${l_aux}

                        #Recargar el arbol de dependencies cargados por systemd
                        printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                        systemctl --user daemon-reload
                    fi

                else

                    if [ -f /usr/lib/systemd/system/${l_aux} ]; then

                        if [ $g_runner_id -eq 0 ]; then

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            systemctl daemon-reload

                        else

                            #Si esta configurado para inicio automatico desactivarlo
                            printf "Disable la unidad systemd '%s'" "$l_aux"
                            sudo systemctl disable $l_aux

                            echo "Eliminando la configuración '/usr/lib/systemd/system/%s' de la unidad systemd '%s'" "$l_aux" "$l_aux"
                            sudo rm /usr/lib/systemd/system/${l_aux}

                            #Recargar el arbol de dependencies cargados por systemd
                            printf "Actualizar el arbol de configuraciones de unidad systemd '%s'" "$l_aux"
                            sudo systemctl daemon-reload

                        fi
                    fi

                fi
            fi
            ;;


        nerdctl)

            #1. Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #2. Eliminando los archivos
            if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then

                if [ -f "${l_target_path}/nerdctl" ]; then
                    echo "Eliminando \"${l_target_path}/nerdctl\"..."
                    rm "${l_target_path}/nerdctl"
                fi

            else

                if [ -f "${l_target_path}/nerdctl" ]; then
                    echo "Eliminando \"${l_target_path}/nerdctl\"..."
                    sudo rm "${l_target_path}/nerdctl"
                fi

            fi

            #3. Eliminando archivos del programa "bypass4netns" (acelerador de "Slirp4netns")
            #is_package_installed 'containerd' $g_os_subtype_id
            #l_status=$?

            #if [ $l_status -eq 0 ]; then

            #    printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_red1" "containerd.io" "$g_color_reset" "$g_color_red1" "$g_color_reset"
            #    printf 'No se desinstalará el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s.\n' "$p_artifact_index" "$p_repo_id"
            #    return 0

            #else

            #    printf 'Desinstalando el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s ...\n' "$p_artifact_index" "$p_repo_id"

            #    #Instalando
            #    if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then

            #        echo "Eliminando \"${l_target_path}/bypass4netns\"..."
            #        rm "${l_target_path}/bypass4netns"

            #        echo "Eliminando \"${l_target_path}/bypass4netnsd\"..."
            #        rm "${l_target_path}/bypass4netnsd"

            #    else

            #        echo "Eliminando \"${l_target_path}/bypass4netns\"..."
            #        sudo rm "${l_target_path}/bypass4netns"

            #        echo "Eliminando \"${l_target_path}/bypass4netnsd\"..."
            #        sudo rm "${l_target_path}/bypass4netnsd"

            #    fi

            #fi
            ;;


        dive)

            #Ruta local de los artefactos
            if [ $p_install_win_cmds -eq 0 ]; then
                echo "ERROR: El artefacto[${p_artifact_index}] del repositorio \"${p_repo_id}\" solo esta habilitado para Linux."
                return 40
            fi

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            echo "Eliminando \"${l_target_path}/dive\"..."
            if [ $g_runner_sudo_support -ne 0 ] && [ $g_runner_sudo_support -ne 1 ]; then

                if [ -f "${l_target_path}/dive" ]; then
                    echo "Eliminando \"${l_target_path}/dive\"..."
                    rm "${l_target_path}/dive"
                fi

            else

                if [ -f "${l_target_path}/dive" ]; then
                    echo "Eliminando \"${l_target_path}/dive\"..."
                    sudo rm "${l_target_path}/dive"
                fi

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









