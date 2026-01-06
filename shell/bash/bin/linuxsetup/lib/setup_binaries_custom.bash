#!/bin/bash

# Consideraciones:
# - Los archivos '.info' donde se almacenan las versiones de programas (que no se puede obtener una version comparable con
#   la almacenada en su repositorio donde se descarga) siempre deben ir en un folder superior de donde se ubican.
#   Esto debido a que muchas veces durante la instalacion se elimina todo el contido existen dentro del programas y no se desea
#   eliminar este archivos durante la instalacion.

#------------------------------------------------------------------------------------------------------------------
#> Variables globales de inicialización y constantes {{{
#------------------------------------------------------------------------------------------------------------------
#
# TODO > Si se incluye .net runtime con el SDK podria actualizarse un runtime independientemente de su SDK.
#       por ello se esta desabilitando la instalacion de runtime por aqui

# Tipo de repositorio que se puede usar
# > Define la URL base del repositorio y puede ser, entre otros en:
#   'github'      : Representa al github publico 'https://github.com' (valor por defecto).
#   'gitlab'      : Representa al gitlab publico 'https://gitlab.com'.
declare -A gA_repotypes=(
        ['github']='https://github.com'
        ['gitlab']='https://gitlab.com'
        ['k8s']='https://dl.k8s.io/release'
        ['dotnetcli']='https://dotnetcli.azureedge.net'
        ['googleapis']='https://storage.googleapis.com'
        ['eclipse']='https://download.eclipse.org'
        ['nodejs']='https://nodejs.org/dist'
        ['rust-lang']='https://static.rust-lang.org/dist'
        ['openshift']='https://mirror.openshift.com/pub/openshift-v4'
        ['helm']='https://get.helm.sh'
        ['awscli']='https://awscli.amazonaws.com'
        ['rclone']='https://downloads.rclone.org'
        ['apache']='https://dlcdn.apache.org'
    )

# Diccionario de todos los repositorios y su respecto identificadores del repositorio de artefactos
# > Cada elemento tiene como key un ID interno del repositorios y cuyo valor es un identificador del repositorio de artefactos.
# > El repositorio de artefactos es el repositorio de donde se descargan sus artefactos.
# > El repositorio de versiones el repositorio de donde se obtienen las versiones (tag) publicadas.
# > Por ejemplo para el repositorio 'jq' esta asociado a un repositorio GitHub 'stedolan/jq' donde se descargaran sus artefactos.
declare -A gA_repos_artifact=(
        ['bat']='sharkdp/bat'
        ['ripgrep']='BurntSushi/ripgrep'
        ['delta']='dandavison/delta'
        ['fzf']='junegunn/fzf'
        ['jq']='stedolan/jq'
        ['yq']='mikefarah/yq'
        ['less']='jftuga/less-Windows'
        ['fd']='sharkdp/fd'
        ['zoxide']='ajeetdsouza/zoxide'
        ['eza']='eza-community/eza'
        ['tailspin']='bensadeh/tailspin'
        ['qsv']='dathere/qsv'
        ['xan']='medialab/xan'
        ['glow']='charmbracelet/glow'
        ['gum']='charmbracelet/gum'
        ['yazi']='sxyazi/yazi'
        ['lazygit']='jesseduffield/lazygit'
        ['rmpc']='mierak/rmpc'
        ['grpcurl']='fullstorydev/grpcurl'
        ['websocat']='vi/websocat'
        ['jwt']='mike-engel/jwt-cli'
        ['step']='smallstep/cli'
        ['butane']='coreos/butane'
        ['evans']='ktr0731/evans'
        ['protoc']='protocolbuffers/protobuf'
        ['oh-my-posh']='JanDeDobbeleer/oh-my-posh'
        ['tree-sitter']='tree-sitter/tree-sitter'
        ['neovim']='neovim/neovim'
        ['kubectl']="$g_empty_str"
        ['pgo']='CrunchyData/postgres-operator-client'
        ['helm']='helm/helm'
        ['operator-sdk']='operator-framework/operator-sdk'
        ['k0s']='k0sproject/k0s'
        ['3scale-toolbox']='3scale-labs/3scale_toolbox_packaging'
        ['nerd-fonts']='ryanoasis/nerd-fonts'
        ['powershell']='PowerShell/PowerShell'
        ['omnisharp-ls']='OmniSharp/omnisharp-roslyn'
        ['netcoredbg']='Samsung/netcoredbg'
        ['go']='golang'
        ['shfmt']='mvdan/sh'
        ['shellcheck']='koalaman/shellcheck'
        ['cmake']='Kitware/CMake'
        ['ninja']='ninja-build/ninja'
        ['llvm']='llvm/llvm-project'
        ['clangd']='clangd/clangd'
        ['codelldb']='vadimcn/codelldb'
        ['vscode-cpptools']='microsoft/vscode-cpptools'
        ['rust-analyzer']='rust-lang/rust-analyzer'
        ['vscode-go']='golang/vscode-go'
        ['vscode-pde']='testforstephen/vscode-pde'
        ['vscode-js-debug']='microsoft/vscode-js-debug'
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
        ['tmux-thumbs']='fcsonline/tmux-thumbs'
        ['wezterm']='wez/wezterm'
        ['cilium']='cilium/cilium-cli'
        ['rclone']="$g_empty_str"
        ['biome']='biomejs/biome'
        ['uv']='astral-sh/uv'
        ['jbang']='jbangdev/jbang'
        ['maven']="$g_empty_str"
        ['async-profiler']='async-profiler/async-profiler'
        ['vscode-java']="$g_empty_str"
        ['vscode-java-test']="$g_empty_str"
        ['vscode-java-debug']="$g_empty_str"
        ['vscode-maven']="$g_empty_str"
        ['vscode-gradle']="$g_empty_str"
        ['vscode-microprofile']="$g_empty_str"
        ['vscode-quarkus']="$g_empty_str"
        ['vscode-jdecompiler']="$g_empty_str"
        ['vscode-springboot']="$g_empty_str"
        ['roslyn-ls-lnx']="$g_empty_str"
        ['roslyn-ls-win']="$g_empty_str"
        ['luals']='LuaLS/lua-language-server'
        ['marksman']='artempyanykh/marksman'
        ['taplo']='tamasfe/taplo'
        ['lemminx']='redhat-developer/vscode-xml'
        ['flamelens']='YS-L/flamelens'
        ['opencode']='sst/opencode'
        ['powershell_es']='PowerShell/PowerShellEditorServices'
        ['distrobox']='89luca89/distrobox'
        ['llama-swap']='mostlygeek/llama-swap'
        ['github-cli']='cli/cli'
        ['gitlab-cli']='gitlab-org/cli'
        ['resvg']='linebender/resvg'
    )

# Diccionario de los repositorios que tiene un repositorio de versiones diferente al repositorio de artefactos.
# > Cada elemento tiene como key un ID interno del repositorios y cuyo valor es un identificador del repositorio de versiones.
# > El repositorio de artefactos es el repositorio de donde se descargan sus artefactos.
# > El repositorio de versiones el repositorio de donde se obtienen las versiones (tag) publicadas.
# > Por ejemplo para el repositorio 'helm' esta asociado a un repositorio GitHub 'helm/heml' donde se obtendra las versiones (tag) publicados.
declare -A gA_repos_version=(
        ['helm']='helm/helm'
    )

# Tipo de repositorio usado por descargar los artefactos de un repositorio
# > Valores solo pueden ser los definidos por 'gA_repotypes'.
declare -A gA_repo_artifact_repotype=(
        ['kubectl']='k8s'
        ['kubelet']='k8s'
        ['kubeadm']='k8s'
        ['net-sdk']='dotnetcli'
        ['net-rt-core']='dotnetcli'
        ['net-rt-aspnet']='dotnetcli'
        ['go']='googleapis'
        ['jdtls']='eclipse'
        ['nodejs']='nodejs'
        ['rust']='rust-lang'
        ['oc']='openshift'
        ['helm']='helm'
        ['awscli']='awscli'
        ['rclone']='rclone'
        ['maven']='apache'
        ['vscode-java']='vscode-marketplace'
        ['vscode-java-test']='vscode-marketplace'
        ['vscode-java-debug']='vscode-marketplace'
        ['vscode-maven']='vscode-marketplace'
        ['vscode-gradle']='vscode-marketplace'
        ['vscode-microprofile']='vscode-marketplace'
        ['vscode-quarkus']='vscode-marketplace'
        ['vscode-jdecompiler']='vscode-marketplace'
        ['vscode-springboot']='vscode-marketplace'
        ['gitlab-cli']='gitlab'
    )


# Tipo de repositorio usado para obtener la ultima version del repositorio.
# > Valores solo pueden ser los definidos por 'gA_repotypes'.
# > Si no se define se considera el valor definido por 'gA_repo_artifact_repotype'.
# > Casos de uso:
#   > Helm los realeasas lo tiene dentro de su propio site, pero la version del ultimo releasae esta en github.
declare -A gA_repo_version_repotype=(
        ['helm']='github'
)

# WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
# Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
declare -a ga_menuoption_title=(
    "Comandos del sistema basicos"
    "Comandos del sistema alternativos 1"
    "Comandos del sistema alternativos 2"
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
    "Java  ${g_color_reset}>${g_color_green1} RTE/SDK 'GraalVM CE', LSP/DAP server, otros"
    "C/C++ ${g_color_reset}>${g_color_green1} Tools"
    "NodeJS${g_color_reset}>${g_color_green1} RTE"
    "Rust  ${g_color_reset}>${g_color_green1} Compiler, LSP server"
    "Go    ${g_color_reset}>${g_color_green1} RTE"
    "Python${g_color_reset}>${g_color_green1} Tools"
    "Formatter, Linter y LSP: Bash linter, Markdown LS, Lua LS, Taplo (Toml LS), Lemmix (XML LS), ..."
    "CTags (indexador de archivos lenguajes de programacion)"
    "Tools de IA para Linux"
    "Tools adicionales de Linux"
    )


# WARNING: Un cambio en el orden implica modificar los indices de los eventos:
#         'install_initialize_menu_option', 'install_finalize_menu_option', 'uninstall_initialize_menu_option' y 'uninstall_finalize_menu_option'
# Menu dinamico: Repositorios de programas asociados asociados a una opciones del menu.
#  - Cada entrada define un opcion de menú.
#  - Su valor es un cadena con ID de repositorios separados por comas.
# Notas:
#  > En la opción de 'ContainerD', se deberia incluir opcionalmente 'bypass4netns' pero su repo no presenta el binario.
#    El binario se puede encontrar en nerdctl-full.
declare -a ga_menuoption_repos=(
    "jq,yq,bat,ripgrep,delta,fzf,less,fd,oh-my-posh,zoxide,eza"
    "tmux-thumbs,tmux-fingers,sesh,grpcurl,websocat,protoc,jwt"
    "rclone,tailspin,qsv,xan,evans,glow,gum,butane,biome,step,yazi,lazygit,rmpc,resvg"
    "nerd-fonts"
    "neovim,tree-sitter"
    "powershell"
    "runc,crun,rootlesskit,slirp4netns,fuse-overlayfs,cni-plugins"
    "containerd,buildkit,nerdctl"
    "dive,hadolint,trivy"
    "crictl,kubectl,cilium,helm"
    "oc,operator-sdk,3scale-toolbox,pgo"
    "k0s"
    "cni-plugins,kubectl,kubelet,kubeadm"
    "net-sdk,omnisharp-ls,roslyn-ls-lnx,roslyn-ls-win,netcoredbg"
    "graalvm,maven,jbang,jdtls,async-profiler,vscode-java,vscode-java-debug,vscode-java-test,vscode-maven,vscode-gradle,vscode-microprofile,vscode-quarkus,vscode-jdecompiler,vscode-springboot"
    "clangd,codelldb,cmake,ninja"
    "nodejs"
    "rust,rust-analyzer"
    "go"
    "uv"
    "shellcheck,shfmt,marksman,luals,taplo,lemminx,flamelens,powershell_es"
    "ctags-win,ctags-nowin"
    "llama-swap"
    "awscli,distrobox,github-cli,gitlab-cli,opencode"
    )

# Tipos de archivos (usualmente binarios), que estan en el repositorio, segun el tipo de SO al cual pueden ser usados/ejecutados.
# > El valor por defecto es 15, el cual, indica que el repositorios incluye archivos (usualmente binarios) para todos los SO
#   soportados por este instalador.
# > Las archivos binarios, que pertenecen en el repositorio, puede ser uno o la suma de los siguientes valores:
#   1 (00001) Archivo Windows (solo si el instalador se ejecuta en Linux WSL2).
#   2 (00010) Archivo Linux     WSL con 'libc' (opcional tienen 'musl' por lo que se puede instalar estos programas).
#   4 (00100) Archivo Linux Non-WSL con 'libc' (opcional tienen 'musl' por lo que se puede instalar estos programas).
#   8 (01000) Archivo Linux Non-WSL solo con 'musl' (Ejemplo: Alpine).
declare -A gA_repo_config_os_type=(
        ['less']=1
        ['llvm']=1
        ['ctags-win']=1
        ['ctags-nowin']=14
        ['roslyn-ls-win']=1
        ['roslyn-ls-lnx']=14
        ['wezterm']=1
        ['k0s']=4
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
        ['fzf']=7
        ['distrobox']=12
        ['rust']=14
        ['butane']=14
        ['awscli']=14
        ['hadolint']=14
        ['trivy']=14
        ['3scale-toolbox']=14
        ['tmux-fingers']=14
        ['tmux-thumbs']=14
        ['cilium']=14
        ['async-profiler']=14
        ['rmpc']=14
    )


# Tipos de archivos binarios, que estan en el repositorio, segun el tipo de arquitectura de procesador donde puede ser usados/ejecutados.
# > Por defecto los repositorios incluye binarios para todos las arquitecturas de procesodor: x86_64 y arm64
#   Valor por defecto es 3.
# > Las archivos binarios, que pertenecen en el repositorio, puede ser uno o la suma de los siguientes valores:
#   1 (00001) x86_64
#   2 (00010) aarch64 (arm64)
declare -A gA_repo_config_proc_type=(
        ['jwt']=1
        ['less']=1
        ['clangd']=1
        ['tmux-fingers']=1
        ['tmux-thumbs']=1
        ['wezterm']=1
    )

# Rempresenta el tipo de artefacto principal asociado al repositorio.
# > Un repositorio tiene un artefacto principal y otros artecfactos adicionales (archivos comprimidos de documentacion, ...)
# > Actualmente no se usa mucho, pero en un futuro permitiza generalizar el codigo a instalar
# Puede ser:
# > (0) Un programa del sistema. Es el valor por defecto.
#       > Usualmente es un binario ejecutable que es considerado un comandos del sistema.
#       > Los archivos usan se ubican en rutas predeterminadas del SO:
#         > Sus binarios ejecutables estan ubicado principalmente en '/usr/local/bin' o '~/.local/bin'.
#         > Sus archivo de ayuda en '/usr/local/share/man/man1', '/usr/local/share/man/man5' y '/usr/local/share/man/man7'.
#         > Sus archivos de fuentes que se almacena en '/usr/local/share/fonts' y '~/.local/share/fonts'.
#       > No requiere configurar su ubicacion para usarse (por ejemplo, no requiere adicionarse en el PATH del usuario).
# > (1) Un programa (tools) del usuario.
#       > Es conjunto de binarios (ejecutables o libreria) junto a otros archivos que NO estan ubicadados en rutas predeterminadas
#         del SO.
#       > No usan archivos del sistema (ayuda y fuentes), debido a que intentan ser independendiente de la distribucion Linux o SO.
#       > Ubicado principalmente en  '/var/opt/tools' o '/opt/tools' o '~/tools'.
#       > Incluye diferentes tipos de archivos adicionales que almacenan en el mismo subfolder.
# > (2) Es un paquete del SO
#       > Son descargable de un repositorio que no es el del SO y se instala usando el gestor de paquetes.
# > (3) Archivos de fuente del sistema
#       > Son archivos que se almacena en rutas predeterminadas del SO '/usr/local/share/fonts' y '~/.local/share/fonts'.
#       > No llegan a tener binarios.
# > (4) Custom
#       > Almacena tanto archivos en rutas reservadas del sistema como folderes creados por el usuario.
declare -A gA_main_arti_type=(
        ['3scale-toolbox']=2
        ['nerd-fonts']=3
        ['protoc']=1
        ['awscli']=1
        ['omnisharp-ls']=1
        ['roslyn-ls-lnx']=1
        ['roslyn-ls-win']=1
        ['netcoredbg']=1
        ['neovim']=1
        ['nodejs']=1
        ['go']=1
        ['rust']=1
        ['net-sdk']=1
        ['net-rt-core']=1
        ['net-rt-aspnet']=1
        ['llvm']=1
        ['clangd']=1
        ['cmake']=1
        ['powershell']=1
        ['rust-analyzer']=1
        ['luals']=1
        ['taplo']=1
        ['graalvm']=1
        ['jdtls']=1
        ['jbang']=1
        ['maven']=1
        ['async-profiler']=1
        ['vscode-java']=1
        ['vscode-java-debug']=1
        ['vscode-java-test']=1
        ['vscode-maven']=1
        ['vscode-gradle']=1
        ['vscode-microprofile']=1
        ['vscode-quarkus']=1
        ['vscode-jdecompiler']=1
        ['vscode-springboot']=1
        ['codelldb']=1
        ['vscode-cpptools']=1
        ['vscode-go']=1
        ['vscode-pde']=1
        ['vscode-js-debug']=1
        ['lemminx']=1
        ['cni-plugins']=1
        ['ctags-win']=1
        ['ctags-nowin']=1
        ['marksman']=1
        ['wezterm']=1
        ['qsv']=1
        ['powershell_es']=1
    )

# Define las formas de obtener la version actual (version amigable del repositorio instalada) de un repositorio
# Puede ser:
# > (0) Obteniendo la version usando el comando principal del programa usando logica estandar.
#       > Valor por defecto para 'programa del sistema' y 'programa del usuario'.
#       > El bloque de texto donde se obtiene la version se usara algo similar a '<repo-id> --version 2> /dev/null'.
#         De dicho bloque de texto se obtendra la version actual y amigable:
#         > Solo se considera la 1ra linea.
#         > Se filtrara usando sed con 'g_regexp_sust_version1'.
#       > Puede ser usado para repositorios cuyo artefacto principal sea programa de sistema/usuario o paquete de SO.
#       > NO puede ser usado para repositorios cuyo artefacto principal sea custom.
# > (1) Obteniendo la version usando el comando principal del programa pero requiere usar logica persalizada para extreaerlo.
#       > Se debe modificar la funcion '_get_repo_current_pretty_version2' para implementar su logica.
#       > El bloque de texto donde se obtiene la version se usara algo similar a '<repo-id> --version 2> /dev/null'.
#         > Todo el bloque de texto se enviara a una funcion personalzida para generar la logica para obtener la version.
#       > Puede ser usado para repositorios cuyo artefacto principal sea programa de sistema/usuario o paquete de SO.
#       > NO puede ser usado para repositorios cuyo artefacto principal sea custom.
# > (2) Obteniendo la version desde un archivo de texto en el folder de programas de usuario.
#       > Siempre es usado para repositorio cuyo artefacto principal es la fuentes del sistema.
#       > Puede ser usado para repositorios cuyo artefacto principal sea custom.
#       > Si no especifica el nombre del archivo esto sera '<repo-id>.info'
#       > Duranta la instalacion del respositorio se crea y/o actualiza el archivo el cual tendra como primera linea la version amigable.
# > (3) Custom.
#       > Se debe modificar la funcion '_get_repo_current_pretty_version1' para implementar su logica
#       > Se especifica la logica en una funcion bash.
#       > Puede ser usado para repositorios cuyo artefacto principal sea custom.
declare -A gA_current_version_method_type=(
    ['delta']=1
    ['eza']=1
    ['lazygit']=1
    ['less']=1
    ['kubectl']=1
    ['oc']=1
    ['kubeadm']=1
    ['shellcheck']=1
    ['pgo']=2
    ['k0s']=1
    ['omnisharp-ls']=3
    ['roslyn-ls-lnx']=2
    ['roslyn-ls-win']=2
    ['netcoredbg']=1
    ['nerd-fonts']=2
    ['net-sdk']=1
    ['net-rt-core']=1
    ['net-rt-aspnet']=1
    ['rust-analyzer']=2
    ['graalvm']=3
    ['jdtls']=2
    ['jbang']=2
    ['maven']=3
    ['vscode-java']=2
    ['vscode-java-debug']=2
    ['vscode-java-test']=2
    ['vscode-maven']=2
    ['vscode-gradle']=2
    ['vscode-microprofile']=2
    ['vscode-quarkus']=2
    ['vscode-jdecompiler']=2
    ['vscode-springboot']=2
    ['codelldb']=2
    ['vscode-cpptools']=2
    ['vscode-go']=2
    ['vscode-pde']=2
    ['vscode-js-debug']=2
    ['lemminx']=2
    ['fuse-overlayfs']=1
    ['cni-plugins']=2
    ['slirp4netns']=1
    ['bypass4netns']=1
    ['containerd']=1
    ['ctags-win']=2
    ['ctags-nowin']=2
    ['cilium']=2
    ['marksman']=2
    ['tmux-fingers']=2
    ['wezterm']=2
    ['powershell_es']=2
    ['llama-swap']=1
    )


# Parametros usasdos para calcular la versiopn actual (instalada) del repositorio.
# Su valor depdende el metodo usado para obtener la version actual.
# > Si es '3', no usa parametros.
# > Si es '2', es el nombre del archivo donde se almacena la version del programa.
#   > Si no especifica el nombre del archivo esto sera '<repo-id>.info'
# > Si es '0' y '1', es nombre del comando usado para obtener el texto donde esta la version deseada.
#   > No debe incluir la extension del binario (si es binario windows es '.exe', en otro caso es '').
#   > Si no se especifica el '<repo-id>'
declare -A gA_current_version_parameter1=(
    ['ripgrep']='rg'
    ['awscli']='aws'
    ['3scale-toolbox']='3scale'
    ['roslyn-ls-lnx']='roslyn_ls.info'
    ['roslyn-ls-win']='roslyn_ls.info'
    ['neovim']='nvim'
    ['nodejs']='node'
    ['nerd-fonts']='nerd-fonts.info'
    ['net-sdk']='dotnet'
    ['net-rt-core']='dotnet'
    ['net-rt-aspnet']='dotnet'
    ['llvm']='clang'
    ['powershell']='pwsh'
    ['luals']='lua-language-server'
    ['rust']='cargo'
    ['jdtls']='eclipse_jdtls.info'
    ['async-profiler']='jfrconv'
    ['buildkit']='buildkitd'
    ['ctags-win']='ctags.info'
    ['ctags-nowin']='ctags.info'
    ['tailspin']='tspin'
    ['github-cli']='gh'
    )


# Parametros usasdos para calcular la versiopn actual (instalada) del repositorio.
# Su valor depdende el metodo usado para obtener la version actual.
# > Si es '3' y '2', no usa estos parametros.
# > Si es '0' y '1', son los argumentos/opciones usados al comando para obtener el texto donde esta la version deseada.
#   > Si no se especifica es '--version'
declare -A gA_current_version_parameter2=(
    ['helm']='version --short'
    ['kubectl']='version --client=true -o json'
    ['oc']='version --client=true -o json'
    ['kubeadm']='version -o json'
    ['operator-sdk']='version'
    ['k0s']='version'
    ['go']='version'
    ['net-sdk']='--list-sdks version'
    ['net-rt-core']='--list-runtimes version'
    ['net-rt-aspnet']='--list-runtimes version'
    ['rmpc']='version'
    )


# Parametros usasdos para calcular la versiopn actual (instalada) del repositorio.
# Su valor depdende el metodo usado para obtener la version actual.
# > Si es '3' y '2', no usa estos parametros.
# > Si es '0' y '1', indica la redireccion que se usara al ejecutar el comando:
#   > (0) Rederige el STDERR a /dev/null ('2> /dev/null'). Es el valor por defecto,
#   > (1) Redirige el STDERR al STDOUT ('2>&1')
declare -A gA_current_version_parameter3=(
    ['grpcurl']=1
    )


# Parametros usasdos para calcular la versiopn actual (instalada) del repositorio.
# Su valor depdende el metodo usado para obtener la version actual.
# > Si es '3' y '2', no usa estos parametros.
# > Si es '0' y '1', solo es usado para 'programas de usuario' y define la ruta relativa del comando respecto a la ruta
#   base de archivos de programa.
declare -A gA_current_version_parameter4=(
    ['protoc']='protoc/bin'
    ['netcoredbg']='dap_servers/netcoredbg'
    ['neovim']='neovim/bin'
    ['nodejs']='nodejs/bin'
    ['net-sdk']='dotnet'
    ['net-rt-core']='dotnet'
    ['net-rt-aspnet']='dotnet'
    ['llvm']='llvm/bin'
    ['wezterm']='wezterm'
    ['clangd']='lsp_servers/clangd/bin'
    ['cmake']='cmake/bin'
    ['powershell']='powershell'
    ['rust']='rust'
    ['luals']='lsp_servers/luals/bin'
    ['taplo']='lsp_servers/toml_ls'
    ['async-profiler']='async_profiler/bin'
    ['qsv']='qsv'
    )


#}}}




#------------------------------------------------------------------------------------------------------------------
#> Funciones de utilidad para la instalación/actualización
#------------------------------------------------------------------------------------------------------------------

#Funciones modificables de nivel 1 {{{


# Obtener informacion de un paquete del marketplace de VSCode
# > Parametro de retorno
#   > Valor de reotorna
#     0 - Se ejecuto de manera exitosa.
#     1 - No existe comando jq requerido para obtener la información.
#     2 - Error al ejecutar el comando de obtener la información.
function get_extension_info_vscode() {

    #Parametros
    local p_package_id="$1"

    local l_filter='.results[0].extensions[0].versions[0].version'        #Obtener la ultima version del paquete.
    if [ "$2" = "2" ]; then
        l_filter='.results[0].extensions[0].versions[0].files[0].source'  #Obtener la URL de la ultima version del paquete.
    fi

    #Si no esta instalado 'jq' no continuar
    if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
        return 1
    fi

    #Usando el API resumido del repositorio de GitHub
    local l_result
    local l_status
    l_result=$(curl -s -X POST "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" \
       -H "Content-Type: application/json" \
       -H "Accept: application/json;api-version=3.0-preview.1" \
       -d "{
             \"filters\": [{
               \"criteria\": [{
                 \"filterType\": 7,
                 \"value\": \"${p_package_id}\"
               }]
             }],
             \"assetTypes\": [\"Microsoft.VisualStudio.Services.VSIXPackage\"],
             \"flags\": 0x402
           }" | ${g_lnx_bin_path}/jq -r "$l_filter")

    l_status=$?
    if [ $l_status -ne 0 ]; then
        return 2
    fi

    echo "$l_result"
    return 0

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
#   3    - No esta definido la logica de obtener la version para el repositorio
#   4    - No esta configurado correctamente el repositorio
function get_repo_last_version() {

    #1. Argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"

    #2. Obtener la informacion del repositorio de versiones
    local l_repotype="${gA_repo_version_repotype[${p_repo_id}]}"
    local l_repodata="${gA_repos_version[${p_repo_id}]}"

    # Si el repositorio de artefactos es el mismo que el repositorio de versiones
    if [ -z "$l_repotype" ]; then

        if [ ! -z "$l_repodata" ]; then
            return 4
        fi

        l_repodata="${gA_repos_artifact[${p_repo_id}]}"
        if [ "$l_repodata" = "$g_empty_str" ]; then
            l_repodata=""
        fi

        l_repotype="${gA_repo_artifact_repotype[${p_repo_id}]:-github}"

    # Si el repositorio de artefactos es diferente al del repositorio de versiones.
    else

        if [ -z "$l_repodata" ]; then
            return 4
        fi

        if [ "$l_repodata" = "$g_empty_str" ]; then
            l_repodata=""
        fi

    fi

    # Obtener la URl base del repositorio de versiones
    local l_base_url_fixed="${gA_repotypes[${l_repotype}]:-https://github.com}"


    #3. Obtener la version
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

            l_aux0=$(curl -s https://download.eclipse.org/jdtls/milestones/ | grep -oP "(?<=/jdtls/milestones/)[0-9]+\.[0-9]+\.[0-9]+" | sort -V | tail -n 1)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_aux1=$(curl -Ls ${l_base_url_fixed}/jdtls/milestones/${l_aux0}/latest.txt)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_aux1=${l_aux1%.tar.gz}
            l_repo_last_version=$(echo "$l_aux1" | head -n 1 | sed -e "$g_regexp_sust_version2")
            ;;



        maven)

            #Busqueda en el repositorio maven por defecto:
            # Grupo ID    (g): org.apache.maven
            # Artifact ID (a): apache-maven
            l_aux0=$(curl -s "https://search.maven.org/solrsearch/select?q=g:org.apache.maven+a:apache-maven&core=gav&rows=20&wt=json")
            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return 2
            fi

            # Si devuelve un html con codigo de error
            if [[ "$l_aux0" == *"<html>"* ]]; then
                l_repo_last_version=''
                return 2
            fi

            l_aux1=$(echo "$l_aux0" | jq -r '.response.docs[].v' | grep -v -E "alpha|beta|rc|M" | head -n 1)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return 2
            fi

            l_repo_last_version="$l_aux1"
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
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                return 1
            fi

            l_aux0=$(curl -Ls -H 'Accept: application/json' "https://go.dev/dl/?mode=json" | ${g_lnx_bin_path}/jq -r '.[0].version')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_repo_last_version=$(echo "$l_aux0" | sed -e "$g_regexp_sust_version1")
            ;;

        awscli)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                return 1
            fi

            l_aux0=$(curl -LsH "Accept: application/json" "https://api.github.com/repos/aws/aws-cli/tags" | ${g_lnx_bin_path}/jq -r '.[0].name')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_repo_last_version=$(echo "$l_aux0" | sed -e "$g_regexp_sust_version1")
            ;;

        jq)
            #Si no esta instalado 'jq' usar expresiones regulares
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | \
                                      sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
                l_status=$?
            else
                l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_lnx_bin_path}/jq -r '.tag_name')
                l_status=$?
            fi

            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;

        neovim)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                return 1
            fi

            #Usando el API completo del repositorio de GitHub (Vease https://docs.github.com/en/rest/releases/releases)
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_lnx_bin_path}/jq -r '.tag_name')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;

        nodejs)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                return 1
            fi

            #Si es Alpine: Usar el repositorio alternativos de NodeJS (https://github.com/nodejs/unofficial-builds/)
            if [ $g_os_subtype_id -eq 1 ]; then
                l_base_url_fixed='https://unofficial-builds.nodejs.org/download/release'
            fi

            #Usando JSON para obtener la ultima version
            l_aux0=$(curl -Ls "${l_base_url_fixed}/index.json" | ${g_lnx_bin_path}/jq -r 'first(.[] | select(.lts != false)) | "\(.version)"' 2> /dev/null)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            l_repo_last_version="$l_aux0"
            ;;

       less)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                return 1
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_lnx_bin_path}/jq -r '.tag_name')
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

        roslyn-ls-lnx)

            #Prefijo usadas para Linux:
            #  alpine-arm64
            #  alpine-x64
            #  linux-arm64
            #  linux-musl-arm64
            #  linux-musl-x64
            #  linux-x64

            #Obtener el prefijo
            l_aux0=''
            if [ $g_os_type -le 1 ]; then  #Si es Linux

                #Alpine Linux
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ $g_os_architecture_type = "x86_64" ]; then
                        l_aux0='alpine-x64'
                    elif [ $g_os_architecture_type = "aarch64" ]; then
                        l_aux0='alpine-arm64'
                    fi
                #Otra distribucion
                else
                    if [ $g_os_architecture_type = "x86_64" ]; then
                        l_aux0='linux-x64'
                    elif [ $g_os_architecture_type = "aarch64" ]; then
                        l_aux0='linux-arm64'
                    fi
                fi

            fi

            if [ -z "$l_aux0" ]; then
                return 2
            fi

            #Obtener la ultima version
            l_repo_last_version=$(curl -Ls "https://feeds.dev.azure.com/azure-public/vside/_apis/packaging/feeds/vs-impl/packages?packageNameQuery=Microsoft.CodeAnalysis.LanguageServer.${l_aux0}&packageType=nuget" | jq -r '.value[].versions[].version' | grep -vE '(preview|beta|rc)' | sort -V | tail -n 1)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;


        roslyn-ls-win)

            #Prefijo usadas por MacOS
            #  osx-arm64
            #  osx-x64
            #Prefijo usadas por Windows
            #  win-arm64
            #  win-x64
            #  win-x86

            #Obtener el prefijo
            l_aux0=''
            if [ $g_os_type -eq 1 ]; then  #Si es Linux WSL2

                if [ $g_os_architecture_type = "x86_64" ]; then
                    l_aux0='win-x64'
                elif [ $g_os_architecture_type = "aarch64" ]; then
                    l_aux0='win-arm64'
                fi

            fi

            if [ -z "$l_aux0" ]; then
                return 2
            fi

            #Obtener la ultima version
            l_repo_last_version=$(curl -Ls "https://feeds.dev.azure.com/azure-public/vside/_apis/packaging/feeds/vs-impl/packages?packageNameQuery=Microsoft.CodeAnalysis.LanguageServer.${l_aux0}&packageType=nuget" | jq -r '.value[].versions[].version' | grep -vE '(preview|beta|rc)' | sort -V | tail -n 1)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi
            ;;


        vscode-java)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'redhat.java' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;



        vscode-java-test)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'vscjava.vscode-java-test' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;


        vscode-java-debug)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'vscjava.vscode-java-debug' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;


        vscode-maven)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'vscjava.vscode-maven' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;



        vscode-gradle)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'vscjava.vscode-gradle' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;


        vscode-microprofile)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'redhat.vscode-microprofile' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;


        vscode-quarkus)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'redhat.vscode-quarkus' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;


        vscode-jdecompiler)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'dgileadi.java-decompiler' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;


        vscode-springboot)

            #Obtener la version
            l_repo_last_version=$(get_extension_info_vscode 'vmware.vscode-spring-boot' 1)

            l_status=$?
            if [ $l_status -ne 0 ]; then
                l_repo_last_version=''
                return $l_status
            fi
            ;;


        wezterm)

            #curl -LsH "Accept: application/json" "https://api.github.com/repos/wez/wezterm/tags"
            #curl -LsH "Accept: application/json" "https://api.github.com/repos/wez/wezterm/tags" | jq '.[] | select(.name == "nightly")'
            #curl -LsH "Accept: application/json" "https://api.github.com/repos/wez/wezterm/commits/c53ca64c33d1658602b9a3aaa412eca9c6544294"
            l_repo_last_version=$(curl -Ls -H "Accept: application/vnd.github+json" https://api.github.com/repos/wezterm/wezterm/releases/tags/nightly | jq -r '.updated_at')

            #Obtener el dia, por ejemplo de '2025-08-15T04:18:28Z' a '20250815'
            l_repo_last_version=$(date -u -d "$l_repo_last_version" +"%Y%m%d")

            ;;

        *)
            #Si no esta instalado 'jq' no continuar
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                return 1
            fi

            #Caso especial: La etiquetas y las fuente se encuentran en 'github.com', pero los binarios estan en su propia pagina
            if [ "$p_repo_id" = "helm" ]; then
                l_base_url_fixed="https://github.com"
            fi

            #Usando el API resumido del repositorio de GitHub
            l_repo_last_version=$(curl -Ls -H 'Accept: application/json' "${l_base_url_fixed}/${p_repo_name}/releases/latest" | ${g_lnx_bin_path}/jq -r '.tag_name')
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


        jdtls)

            #Ejemplo de version
            #  File: jdt-language-server-1.46.1-202504011455.tar.gz
            #  Version:
            #     1.46.1-202504011455   -> 1.46.1
            l_version="${p_version%-*}"
            ;;

        rust-analyzer|marksman|roslyn-ls-lnx|roslyn-ls-win)

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
            l_aux=$(echo "$p_version" | sed -E 's/[vp]([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
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
            l_aux=$(echo "$p_version" | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\+.*/\1/')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;

        wezterm)

            #Ejemplo de versiones: solo obtener la fecha
            #   wezterm 20240805_014059_9d285fa6
            l_aux=$(echo "$p_version" | sed -E 's/.* ([0-9]+)_.*/\1/')
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 1
            fi

            l_version="$l_aux"
            ;;


        llama-swap)

            l_aux=$(echo "$p_version" | sed -e 's/[^0-9]*\([0-9][0-9.]\+\).*/\1/')
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
#   > Una cadena con las subversiones separadas por espacios. Las subversion puede ser una version amigable (solo numeros comprables o texto),
#     o no amigable, ello dependera como se usan en las funciones 'is_installed_repo_subversion', 'get_repo_artifacts' y '_copy_artifact_files'
#Parametros salida> Valor de retorno:
#   0 - Tiene subversiones.
#   1 - No tiene subversiones
#   4 - No esta configurado correctamente el repositorio
function get_repo_last_subversions() {

    #1. Leer los argumentos
    local p_repo_id="$1"
    local p_repo_name="$2"
    local p_repo_last_version="$3"
    local p_repo_last_pretty_version="$4"

    #2. Obtener la informacion del repositorio de versiones
    local l_repotype="${gA_repo_version_repotype[${p_repo_id}]}"
    local l_repodata="${gA_repos_version[${p_repo_id}]}"

    # Si el repositorio de artefactos es el mismo que el repositorio de versiones
    if [ -z "$l_repotype" ]; then

        if [ ! -z "$l_repodata" ]; then
            return 4
        fi

        l_repodata="${gA_repos_artifact[${p_repo_id}]}"
        if [ "$l_repodata" = "$g_empty_str" ]; then
            l_repodata=""
        fi

        l_repotype="${gA_repo_artifact_repotype[${p_repo_id}]:-github}"

    # Si el repositorio de artefactos es diferente al del repositorio de versiones.
    else

        if [ -z "$l_repodata" ]; then
            return 4
        fi

        if [ "$l_repodata" = "$g_empty_str" ]; then
            l_repodata=""
        fi

    fi

    # Obtener la URl base del repositorio de versiones
    local l_base_url_fixed="${gA_repotypes[${l_repotype}]:-https://github.com}"


    #3. Calcular la parte comparable de la version
    local l_status
    local l_arti_subversions=""
    local l_aux=''

    case "$p_repo_id" in

        net-sdk|net-rt-core|net-rt-aspnet)

            #El artefacto se obtiene del repositorio de Microsoft
            if [ ! -z "$g_setup_only_last_version" ] && [ $g_setup_only_last_version -eq 0 ]; then
                l_arti_subversions=""
            else

                #printf 'RepoID: "%s", RepoName: "%s", LastVersion: "%s"\n' "$p_repo_id" "$p_repo_name" "$l_repo_last_pretty_version"

                #Obtener las subversiones: estara formado por la ultima version y 2 versiones inferiores
                #Devulve la version ingresada y 2 versiones menores a la ingresada separados por ' '
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
            if ! ${g_lnx_bin_path}/jq --version &> /dev/null; then
                return 1
            fi


            #Obtener las subversiones: estara formado por la ultima version y 3 versiones inferiores
            #Devulve la version no amigable y 2 versiones menores no amigable separados por ' '
            #Ejemplo del formato de la subversion 'jdk-24.0.1'
            l_aux=$(curl -s "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases?per_page=15" | jq -r '.[] | select(.prerelease == false) | .tag_name' | grep 'jdk-' | sort -V -r | awk -F'[.-]' '!seen[$2]++' | head -n 3)
            #l_aux=$(curl -s "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases?per_page=15" | jq -r '.[] | select(.prerelease == false) | .tag_name' | grep 'jdk-' | sort -V -r | awk -F'[.-]' '!seen[$2]++' | sed 's/^jdk-//' | head -n 3)

            #Si solo tiene uns subversion y es la misma que la version, no existe subversiones
            if [ "$l_repo_last_version" = "$l_aux" ]; then
                l_arti_subversions=""
            else
                l_arti_subversions=$(echo "$l_aux" | tr '\n' ' ')
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    return 1
                fi
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



#Validar si una subversion de un repositorio esta instalada
#Parametros de salida:
#  > Valor de retorno:
#    0 - Esta instalado (Existe)
#    1 - NO esta instalado (No existe)
function is_installed_repo_subversion()
{
    local p_repo_id="$1"
    local p_arti_subversion_version="$2"
    local p_is_win_binary=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                     #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$3" = "0" ]; then
        p_is_win_binary=0
    fi

    #Por defecto las subversiones de un repositorio no esta intalado
    local l_is_instelled=1
    local l_status=1
    local l_aux1=''
    local l_aux2=''

    #Indicar si alguna subversion ya esta instalado
    case "$p_repo_id" in


        net-sdk|net-rt-core|net-rt-aspnet)

            #Validar que existe la version no esta instalado
            _dotnet_exist_version "$p_repo_id" "$p_arti_subversion_version" $p_is_win_binary
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_is_instelled=0
            fi
            ;;


        graalvm)

            #Ejemplo del formato de la subversion 'jdk-24.0.1'
            #Obtener el 1er numero de la version
            l_aux1=$(echo "$p_arti_subversion_version" | sed -n 's/^jdk-\([0-9]*\)\..*/\1/p')

            #Obtener el folder donde se almacena esta subversion
            l_aux2="${g_tools_path}/graalvm_${l_aux1}"
            if [ $p_is_win_binary -eq 0 ]; then
                l_aux2="${g_win_tools_path}/graalvm_${l_aux1}"
            fi

            if [ -d "${g_win_tools_path}/graalvm_${l_aux1}" ]; then

                #Obtener la version pretty de la version indicada
                l_aux2=$(_g_repo_current_pretty_version "graalvm" $p_is_win_binary "${l_aux2}")
                l_status=$?

                if [ $l_status -eq 0 ]; then

                    #Obteniendo la version amigable del artecto
                    l_aux1=$(echo "$p_arti_subversion_version" | sed 's/^jdk-//')
                    if [ "$l_aux1" = "$l_aux2" ]; then
                        l_is_instelled=0
                    fi

               fi

            fi
            ;;


    esac

    return $l_is_instelled

}



# Determinar la version actual (la version instalada y amigable) del repositorio.
# > Solo aplica para repositorios cuyo artefacto principal sea un programa de usuario/sistema y cuya version no puede ser
#   obtenida usando la logica por defecto.
# Parametros de entrada
#   3 - Texto obtenido por el comando asociado al repositorio donde se encuentra la version actual de este.
# Parametros de salida> STDOUT
#   Versión normalizada o 'pretty version' de la versión instalizada.
# Parametros de salida> Valor de retorno:
#   0 - OK. El repositorio esta instalado y tiene una version valida.
#   1 - OK. Siempre instalar/actualizar (en casos excepcionales, donde no determinar la version actaul del repositorio).
#   2 - OK. El repositorio no esta instalado, por lo que la version devuelva es ''.
#   3 - Error. El repositorio esta instalado pero tiene una version invalida.
#   4 - Error. El metodo para obtener la version no esta configurado de forma correcta.
#   5 - Error. El metodo para obtener la version arrojo error.
#   9 - Error. El repositorio no implementado artefactos del para ser usado para el SO indicado en el paremetro 2.
function _get_repo_current_pretty_version2() {

    #1. Argumentos
    local p_repo_id="$1"

    local p_is_win_binary=1
    if [ "$2" = "0" ]; then
        p_is_win_binary=0
    fi

    local p_data="$3"
    local p_executable="$4"

    #2. Obtener la version actual
    local l_result=""
    local l_status=4


    case "$p_repo_id" in

        delta)

            # Solo para Windows
            #l_result=$(echo "$l_result" | tr '\n' '' | cut -d ' ' -f 2)
            l_result=$(echo "$p_data" | cut -d ' ' -f 2 | head -n 1)
            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            l_status=0
            ;;


        shellcheck)
            l_result=$(echo "$p_data" | head -n 2 | tail -n 1)
            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            l_status=0
            ;;


        eza)
            l_result=$(echo "$p_data" | tail -n 2 | head -n 1)
            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            l_status=0
            ;;


        lazygit)
            l_result=$(echo "$p_data" | sed -e 's/.*, version=\([0-9]\+\.[0-9.]\+\).*/\1/')
            l_status=0
            ;;


        less)
            l_result=$(echo "$p_data" | head -n 1 | sed "$g_regexp_sust_version3")
            l_status=0
            ;;


        kubectl|oc|kubeadm)
            l_result=$(echo "$p_data" | ${g_lnx_bin_path}/jq -r '.clientVersion.gitVersion' 2> /dev/null)
            if [ $? -ne 0 ]; then
                return 5
            fi

            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            l_status=0
            ;;

        k0s)
            l_result=$(echo "$p_data" | cut -d ' ' -f 2 | head -n 1)
            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            l_status=0
            ;;


        netcoredbg)

            l_result=$(echo "$p_data" | head -n 1)
            l_result=${l_result//-/.}
            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version2")
            l_status=0
            ;;


        net-sdk)

            l_result=$(echo "$p_data" | sort -r | head -n 1)
            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            l_status=0
            ;;


       net-rt-core|net-rt-aspnet)

            # No instalar si esta instalado el SDK
            l_result=$(${p_executable} --list-sdks version 2> /dev/null)
            l_status=$?
            if [ $l_status -ne 0 ] || [ -z "$l_result" ]; then
                return 4
            fi

            #Obtener la version
            if [ "$p_repo_id" = "net-rt-core" ]; then

                l_result=$(echo "$p_data" | grep 'Microsoft.NETCore.App' | sort -r | head -n 1)
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    l_result=""
                    return 5
                fi

            else

                l_result=$(echo "$p_data" | grep 'Microsoft.AspNetCore.App' | sort -r | head -n 1)
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    l_result=""
                    return 5
                fi

            fi

            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            ;;


        fuse-overlayfs)

            l_result=$(echo "$p_data" | grep 'fuse-overlayfs' | sed "$g_regexp_sust_version1")
            l_status=0
            ;;

        slirp4netns|bypass4netns)

            l_result=$(echo "$p_data" | head -n 1 | sed "$g_regexp_sust_version5")
            l_status=0
            ;;

        containerd)

            l_result=$(echo "$p_data" | head -n 1 | sed 's/.*\sv\([0-9.]\+\).*/\1/')
            l_status=0
            ;;

       llama-swap)
            l_result=$(echo "$p_data" | sed -e 's/[^0-9]*\([0-9][0-9.]\+\).*/\1/')
            l_status=0
            ;;

       wezterm)
            #   wezterm 20240805_014059_9d285fa6
            l_result=$(echo "$p_data" | sed -E 's/.* ([0-9]+)_.*/\1/')
            l_status=0
            ;;


       *)
           return 4
           ;;

    esac


    echo "$l_result"
    return $l_status


}



# Determinar la version actual (la version instalada y amigable) del repositorio.
# > Solo aplica cuando el metodo para obtener la version se define como custom
# Parametros de entrada
#   3 - Ruta donde ubicar al comando. Opcional y solo para repositorio donde su artefacto principal es un programa de usuario/sistema.
#       Si el artecfacto principal es usado es un paquete del SO la ruta es del sistema, pero no se necesamiente es '/usr/local/bin'.
# Parametros de salida> STDOUT
#   Versión normalizada o 'pretty version' de la versión instalizada.
# Parametros de salida> Valor de retorno:
#   0 - OK. El repositorio esta instalado y tiene una version valida.
#   1 - OK. Siempre instalar/actualizar (en casos excepcionales, donde no determinar la version actaul del repositorio).
#   2 - OK. El repositorio no esta instalado, por lo que la version devuelva es ''.
#   3 - Error. El repositorio esta instalado pero tiene una version invalida.
#   4 - Error. El metodo para obtener la version no esta configurado de forma correcta.
#   5 - Error. El metodo para obtener la version arrojo error.
#   9 - Error. El repositorio no implementado artefactos del para ser usado para el SO indicado en el paremetro 2.
function _get_repo_current_pretty_version1() {

    #1. Argumentos
    local p_repo_id="$1"

    local p_is_win_binary=1
    if [ "$2" = "0" ]; then
        p_is_win_binary=0
    fi

    local p_executable_base_path="$3"


    #2. Obtener la version actual
    local l_result=""
    local l_status=4
    local l_path_file=''


    case "$p_repo_id" in


        omnisharp-ls)

            #Calcular la ruta de archivo/comando donde se obtiene la version
            if [ $p_is_win_binary -eq 0 ]; then
               l_path_file="${g_win_tools_path}/lsp_servers/omnisharp_ls/OmniSharp.deps.json"
            else
               l_path_file="${g_tools_path}/lsp_servers/omnisharp_ls/OmniSharp.deps.json"
            fi

            #Si no se encuentra el archivo, se considera no instalado
            if [ ! -f "${l_path_file}" ]; then
                return 2
            fi

            l_result=$(${g_lnx_bin_path}/jq -r '.targets[][].dependencies."OmniSharp.Stdio"' "${l_path_file}" | grep -v "null" | \
                       head -n 1 2> /dev/null)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 5
            fi

            l_result=$(echo "$l_result" | sed "$g_regexp_sust_version1")
            ;;



        graalvm)

            # Calcular la ruta de archivo/comando donde se obtiene la version
            if [ $p_is_win_binary -eq 0 ]; then

                if [ -z "$p_executable_base_path" ]; then

                    #Si no se encuentra el archivo, se considera no instalado
                    if [ -f "${g_win_tools_path}/graalvm.info" ]; then
                        return 2
                    fi

                    #Para binarios windows, el instaaldor no crea el enlace simbolo, asi que debe irse a la carpeta de la ultima version.
                    l_result=$(cat "${g_win_tools_path}/graalvm.info" | head -n 1)
                    l_path_file="${g_win_tools_path}/graalvm_${l_result}/bin/java.exe"

                else
                    l_path_file="$p_executable_base_path/java.exe"
                fi

            else

                if [ -z "$p_executable_base_path" ]; then
                    l_path_file="${g_tools_path}/graalvm/bin/java"
                else
                    l_path_file="$p_executable_base_path/java"
                fi

            fi

            # Si no se encuentra el archivo, se considera no instalado
            if [ ! -f "${l_path_file}" ]; then
                return 2
            fi

            # Obtener la version
            l_result=$(${l_path_file} --version 2> /dev/null)
            l_status=$?

            if [ $l_status -ne 0 ]; then
                return 5
            fi

            l_result=$(echo "$l_result" | head -n 1 | sed "$g_regexp_sust_version1")
            ;;



        maven)

            # Calcular la ruta de archivo/comando donde se obtiene la version
            if [ $p_is_win_binary -eq 0 ]; then

                if [ -z "$p_executable_base_path" ]; then

                    #Si no se encuentra el archivo, se considera no instalado
                    if [ -f "${g_win_tools_path}/maven.info" ]; then
                        return 2
                    fi

                    #Para binarios windows, el instaaldor no crea el enlace simbolo, asi que debe irse a la carpeta de la ultima version.
                    l_result=$(cat "${g_win_tools_path}/maven.info" | head -n 1)
                    l_path_file="${g_win_tools_path}/maven_${l_result}/bin/mvn.cmd"

                else
                    l_path_file="$p_executable_base_path/mvn.cmd"
                fi

            else

                if [ -z "$p_executable_base_path" ]; then
                    l_path_file="${g_tools_path}/maven/bin/mvn"
                else
                    l_path_file="$p_executable_base_path/mvn"
                fi

            fi

            # Si no se encuentra el archivo, se considera no instalado
            if [ ! -f "${l_path_file}" ]; then
                return 2
            fi

            # Obtener la version
            l_result=$(${l_path_file} --version 2> /dev/null)
            l_status=$?

            if [ $l_status -ne 0 ]; then
                return 5
            fi

            l_result=$(echo "$l_result" | head -n 1 | sed "$g_regexp_sust_version1")
            ;;

        *)
            return 4
            ;;

    esac


    echo "$l_result"

    # Solo obtiene la 1ra cadena que este formado por caracteres 0-9 y .
    if [[ ! "$l_result" == [0-9]* ]]; then
        return 3
    fi

    return 0

}


#}}}


#Funciones modificables (Nive 2) {{{

#Parametros de salida:
#  Devuelve un arreglo de artefectos, usando los argumentos 3 y 4 como de referencia:
#  5> Un arrego de bases URL del los artefactos.
#     Si el repositorio tiene muchos artefactos pero todos tiene la misma URL base, solo se puede indicar
#     solo una URL, la misma URL se replicara para los demas se repitira el mismo valor
#  6> Un arreglo de tipo de artefacto donde cada item puede ser:
#     Un archivo no comprimido
#       >  0 si es un archivo que no no esta comprimido (binario, archivo, etc)
#       >  1 si es un package del SO
#     Comprimidos no tan pesados (se descomprimen en un temporal y luego copian en el lugar deseado)
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
#  En el argumento 2 se debe pasar la version pura quitando, sin contener "v" u otras letras iniciales
#
#Valor de retorno:
#  0 - OK. La URL base (parametro 5 o 'pna_artifact_baseurl') no incluye el nombre del artefacto a descargar.
#          El parametro 6 ('pna_artifact_names') es el nombre del artectado a descargar y el nombre del archivo con la que se descargara en el temporal.
#  1 - OK. La URL base (parametro 5 o 'pna_artifact_baseurl') incluye el nombre del artefacto a descargar.
#          El parametro 6 ('pna_artifact_names') NO el nombre del artectado a descargar, pero es el nombre del archivo con la que se descargara en el temporal.
#  2 - NOOK
#
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

    local p_is_win_binary=1         #(0) Los binarios son para Windows (Linux WSL2)
                                       #(1) Los binarios son para Linux
    if [ "$9" = "0" ]; then
        p_is_win_binary=0
    fi

    #Si se estan instalando (la primera vez) es '0', caso contrario es otro valor (se actualiza o se desconoce el estado)
    local p_flag_install=1
    if [ "${10}" = "0" ]; then
        p_flag_install=0
    fi

    #2. Generar el nombre
    local l_artifact_name=""
    local l_artifact_type=99
    local l_result=0  #(0) si 'pnra_artifact_baseurl' no incluye el nombre del artefacto a descargar
                      #(1) si 'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
    local l_status
    local l_aux1
    local l_aux2

    #1. Obtener la URL base por defecto (se considera que el repositorio es de GitHub)

    #URL base fijo     :  Usualmente "https://github.com"
    local l_repotype="${gA_repo_artifact_repotype[${p_repo_id}]:-github}"
    local l_base_url_fixed="${gA_repotypes[${l_repotype}]:-https://github.com}"

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
                if [ $p_is_win_binary -eq 0 ]; then

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
                if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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


        websocat)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("websocat.x86_64-pc-windows-gnu.exe")
                else
                    pna_artifact_names=("websocat.x86_64-pc-windows-gnu.exe")
                fi
                pna_artifact_types=(0)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("websocat.x86_64-unknown-linux-musl")
                    else
                        pna_artifact_names=("websocat.x86_64-unknown-linux-musl")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("websocat.x86_64-unknown-linux-musl")
                    else
                        pna_artifact_names=("websocat.x86_64-unknown-linux-musl")
                    fi
                fi
                pna_artifact_types=(0)
            fi
            ;;


        yazi)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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



        lazygit)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("lazygit_${p_repo_last_pretty_version}_Windows_arm64.zip")
                else
                    pna_artifact_names=("lazygit_${p_repo_last_pretty_version}_Windows_x86_64.zip")
                fi
                pna_artifact_types=(11)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("lazygit_${p_repo_last_pretty_version}_Linux_arm64.tar.gz")
                else
                    pna_artifact_names=("lazygit_${p_repo_last_pretty_version}_Linux_x86_64.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;



        shfmt)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("shfmt_v${p_repo_last_pretty_version}_windows_amd64.exe")
                else
                    pna_artifact_names=("shfmt_v${p_repo_last_pretty_version}_windows_amd64.exe")
                fi
                pna_artifact_types=(0)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("shfmt_v${p_repo_last_pretty_version}_linux_arm64")
                    else
                        pna_artifact_names=("shfmt_v${p_repo_last_pretty_version}_linux_amd64")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("shfmt_v${p_repo_last_pretty_version}_linux_arm64")
                    else
                        pna_artifact_names=("shfmt_v${p_repo_last_pretty_version}_linux_amd64")
                    fi
                fi
                pna_artifact_types=(0)
            fi
            ;;



        shellcheck)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("shellcheck-v${p_repo_last_pretty_version}.zip")
                else
                    pna_artifact_names=("shellcheck-v${p_repo_last_pretty_version}.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("shellcheck-v${p_repo_last_pretty_version}.linux.aarch64.tar.xz")
                    else
                        pna_artifact_names=("shellcheck-v${p_repo_last_pretty_version}.linux.x86_64.tar.xz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("shellcheck-v${p_repo_last_pretty_version}.linux.aarch64.tar.xz")
                    else
                        pna_artifact_names=("shellcheck-v${p_repo_last_pretty_version}.linux.x86_64.tar.xz")
                    fi
                fi
                pna_artifact_types=(14)
            fi
            ;;



        tree-sitter)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("tree-sitter-windows-arm64.gz")
                else
                    pna_artifact_names=("tree-sitter-windows-x64.gz")
                fi
                pna_artifact_types=(12)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("tree-sitter-linux-arm64.gz")
                    else
                        pna_artifact_names=("tree-sitter-linux-x64.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("tree-sitter-linux-arm64.gz")
                    else
                        pna_artifact_names=("tree-sitter-linux-x64.gz")
                    fi
                fi
                pna_artifact_types=(12)
            fi
            ;;


        distrobox)

            #No soportado para Windows
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #URL base fijo     : https://github.com
            #URL base variable :
            l_base_url_variable="${p_repo_name}/archive/refs/tags/${p_repo_last_pretty_version}.tar.gz"

            #Parametro requeridos:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

            pna_artifact_names=("${p_repo_id}.tar.gz")
            pna_artifact_types=(10)
            ;;



        rmpc)

            #No soportado para Windows
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
            if [ $g_os_subtype_id -eq 1 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    rna_artifact_names=("rmpc-v${p_repo_last_pretty_version}-aarch64-unknown-linux-musl.tar.gz")
                else
                    pna_artifact_names=("rmpc-v${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
                fi
                pna_artifact_types=(10)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("rmpc-v${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.tar.gz")
                else
                    pna_artifact_names=("rmpc-v${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz")
                fi
                pna_artifact_types=(10)
            fi
            ;;



        llama-swap)

            #Si es un binario para Windows
            if [ $p_is_win_binary -eq 0 ]; then

                pna_artifact_names=("llama-swap_${p_repo_last_pretty_version}_windows_amd64.zip")
                pna_artifact_types=(11)

            else

                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        rna_artifact_names=("llama-swap_${p_repo_last_pretty_version}_linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("llama-swap_${p_repo_last_pretty_version}_linux_amd64.tar.gz")
                    fi
                    pna_artifact_types=(10)
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("llama-swap_${p_repo_last_pretty_version}_linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("llama-swap_${p_repo_last_pretty_version}_linux_amd64.tar.gz")
                    fi
                    pna_artifact_types=(10)
                fi

            fi
            ;;



        opencode)

            #Si es un binario para Windows
            if [ $p_is_win_binary -eq 0 ]; then

                pna_artifact_names=("opencode-windows-x64.zip")
                pna_artifact_types=(11)

            else

                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        rna_artifact_names=("opencode-linux-arm64-musl.tar.gz")
                    else
                        pna_artifact_names=("opencode-linux-x64-musl.tar.gz")
                    fi
                    pna_artifact_types=(10)
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("opencode-linux-arm64.tar.gz")
                    else
                        pna_artifact_names=("opencode-linux-x64.tar.gz")
                    fi
                    pna_artifact_types=(10)
                fi

            fi
            ;;



        powershell_es)

            #Si es un binario para Windows
            pna_artifact_names=("PowerShellEditorServices.zip")
            pna_artifact_types=(21)
            ;;


        rclone)
            #URL base fijo     : "https://downloads.rclone.org"
            #URL base variable :
            l_base_url_variable="v${p_repo_last_pretty_version}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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



        #xsv)
        #    #No soportado para architecture ARM de 64 bits
        #    if [ "$g_os_architecture_type" = "aarch64" ]; then
        #        pna_artifact_baseurl=()
        #        pna_artifact_names=()
        #        return 2
        #    fi

        #    #Generar los datos de artefactado requeridos para su configuración:
        #    if [ $p_is_win_binary -eq 0 ]; then
        #        pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
        #        pna_artifact_types=(11)
        #    else
        #        #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
        #        if [ $g_os_subtype_id -eq 1 ]; then
        #            pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
        #        else
        #            pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.tar.gz")
        #            #pna_artifact_names=("xsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.tar.gz")
        #        fi
        #        pna_artifact_types=(10)
        #    fi
        #    ;;



        tailspin)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("tailspin-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("tailspin-aarch64-unknown-linux-musl.tar.gz")
                    else
                        pna_artifact_names=("tailspin-x86_64-unknown-linux-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("tailspin-aarch64-unknown-linux-musl.tar.gz")
                    else
                        pna_artifact_names=("tailspin-x86_64-unknown-linux-musl.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;


        qsv)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("qsv-${p_repo_last_pretty_version}-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(21)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("qsv-${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.zip")
                    else
                        pna_artifact_names=("qsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-musl.zip")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("qsv-${p_repo_last_pretty_version}-aarch64-unknown-linux-gnu.zip")
                    else
                        pna_artifact_names=("qsv-${p_repo_last_pretty_version}-x86_64-unknown-linux-gnu.zip")
                    fi
                fi
                pna_artifact_types=(21)
            fi
            ;;


        xan)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("xan-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("xan-x86_64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("xan-x86_64-unknown-linux-gnu.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("xan-x86_64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("xan-x86_64-unknown-linux-gnu.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;




        bat)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
            #l_base_url_fixed="${gA_repotypes[${l_repotype}]:-https://github.com}"
            #URL base variable :
            l_base_url_variable="${p_repo_name}/releases/download/%40biomejs%2Fbiome%40${p_repo_last_pretty_version}"

            #URL base para un repositorio GitHub
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("jwt-windows.tar.gz")
                pna_artifact_types=(10)
            else
                pna_artifact_names=("jwt-linux.tar.gz")
                pna_artifact_types=(10)
            fi
            ;;

        step)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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


        flamelens)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("flamelens-x86_64-pc-windows-msvc.zip")
                else
                    pna_artifact_names=("flamelens-x86_64-pc-windows-msvc.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("flamelens-x86_64-unknown-linux-musl.tar.xz")
                    else
                        pna_artifact_names=("flamelens-x86_64-unknown-linux-musl.tar.xz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("flamelens-x86_64-unknown-linux-gnu.tar.xz")
                    else
                        pna_artifact_names=("flamelens-x86_64-unknown-linux-gnu.tar.xz")
                    fi
                fi
                pna_artifact_types=(14)
            fi
            ;;



        github-cli)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("gh_${p_repo_last_pretty_version}_windows_arm64.tar.zip")
                else
                    pna_artifact_names=("gh_${p_repo_last_pretty_version}_windows_amd64.tar.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("gh_${p_repo_last_pretty_version}_linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("gh_${p_repo_last_pretty_version}_linux_amd64.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("gh_${p_repo_last_pretty_version}_linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("gh_${p_repo_last_pretty_version}_linux_amd64.tar.gz")
                    fi
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
                return 2
            else
                pna_artifact_names=("kubelet")
                pna_artifact_types=(0)
            fi
            ;;

        kubeadm)
            #URL base fijo     : "https://dl.k8s.io/release"
            #URL base variable :
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
                return 2
            else
                pna_artifact_names=("kubeadm")
                pna_artifact_types=(0)
            fi
            ;;

        pgo)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
                return 2
            fi

            #No soportado para Linux
            if [ $p_is_win_binary -ne 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("less-x64.zip")
            pna_artifact_types=(11)
            ;;

        k0s)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("operator-sdk_linux_arm64" "helm-operator_linux_arm64")
            else
                pna_artifact_names=("operator-sdk_linux_amd64" "helm-operator_linux_amd64")
            fi
            pna_artifact_types=(0 0)
            ;;

        omnisharp-ls)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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



        codelldb)

            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_names=("codelldb.zip")

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then

                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/codelldb-win32-x64.vsix")
                pna_artifact_types=(11)

            else

                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/codelldb-linux-arm64.vsix")
                else
                    pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/codelldb-linux-x64.vsix")
                fi
                pna_artifact_types=(11)

            fi
            ;;




        vscode-cpptools)

            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_names=("vscode_cpptools.zip")

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then

                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/cpptools-windows-arm64.vsix")
                else
                    pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/cpptools-windows-x64.vsix")
                fi
                pna_artifact_types=(11)

            else

                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then

                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/cpptools-alpine-arm64.vsix")
                    else
                        pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/cpptools-alpine-x64.vsix")
                    fi

                else

                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/cpptools-linux-arm64.vsix")
                    else
                        pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/cpptools-linux-x64.vsix")
                    fi

                fi
                pna_artifact_types=(11)

            fi
            ;;



        vscode-go)

            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_names=("vscode_go.zip")

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/go-${p_repo_last_pretty_version}.vsix")
            pna_artifact_types=(11)
            ;;



        vscode-pde)

            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_names=("vscode_pde.zip")

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}/vscode-pde-${p_repo_last_pretty_version}.vsix")
            pna_artifact_types=(11)
            ;;



        vscode-js-debug)

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("js-debug-dap-v${p_repo_last_pretty_version}.tar.gz")
            pna_artifact_types=(20)
            ;;



        luals)

            #TODO incluir 'lua-language-server-3.14.0-submodules.zip'
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("lua-language-server-${p_repo_last_pretty_version}-win32-x64.zip")
                pna_artifact_types=(21)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("lua-language-server-${p_repo_last_pretty_version}-linux-x64-musl.tar.gz")
                    else
                        pna_artifact_names=("lua-language-server-${p_repo_last_pretty_version}-linux-x64-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("lua-language-server-${p_repo_last_pretty_version}-linux-arm64.tar.gz")
                    else
                        pna_artifact_names=("lua-language-server-${p_repo_last_pretty_version}-linux-x64.tar.gz")
                    fi
                fi
                pna_artifact_types=(20)
            fi
            ;;



        taplo)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("taplo-windows-aarch64.zip")
                else
                    pna_artifact_names=("taplo-windows-x86_64.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("taplo-linux-aarch64.gz")
                    else
                        pna_artifact_names=("taplo-linux-x86_64.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("taplo-linux-aarch64.gz")
                    else
                        pna_artifact_names=("taplo-linux-x86_64.gz")
                    fi
                fi
                pna_artifact_types=(12)
            fi
            ;;



        lemminx)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("lemminx-win32.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("lemminx-linux.zip")
                    else
                        pna_artifact_names=("lemminx-linux.zip")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("lemminx-linux.zip")
                    else
                        pna_artifact_names=("lemminx-linux.zip")
                    fi
                fi
                pna_artifact_types=(11)
            fi
            ;;


        async-profiler)

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
            if [ $g_os_subtype_id -eq 1 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("async-profiler-${p_repo_last_pretty_version}-linux-arm64.tar.gz" "async-profiler.jar" "jfr-converter.jar")
                else
                    pna_artifact_names=("async-profiler-${p_repo_last_pretty_version}-linux-musl-x64.tar.gz" "async-profiler.jar" "jfr-converter.jar")
                fi
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("async-profiler-${p_repo_last_pretty_version}-linux-arm64.tar.gz" "async-profiler.jar" "jfr-converter.jar")
                else
                    pna_artifact_names=("async-profiler-${p_repo_last_pretty_version}-linux-x64.tar.gz" "async-profiler.jar" "jfr-converter.jar")
                fi
            fi
            pna_artifact_types=(20 0 0)
            ;;



        roslyn-ls-lnx)

            #Solo binarios linux
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Prefijo usadas para Linux:
            #  alpine-arm64
            #  alpine-x64
            #  linux-arm64
            #  linux-musl-arm64
            #  linux-musl-x64
            #  linux-x64

            #Obtener el prefijo
            l_aux1=''
            if [ $g_os_type -le 1 ]; then  #Si es Linux

                #Alpine Linux
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ $g_os_architecture_type = "x86_64" ]; then
                        l_aux1='alpine-x64'
                    elif [ $g_os_architecture_type = "aarch64" ]; then
                        l_aux1='alpine-arm64'
                    fi
                #Otra distribucion
                else
                    if [ $g_os_architecture_type = "x86_64" ]; then
                        l_aux1='linux-x64'
                    elif [ $g_os_architecture_type = "aarch64" ]; then
                        l_aux1='linux-arm64'
                    fi
                fi

            fi

            if [ -z "$l_aux1" ]; then
                #No implementado para la plataforma actual
                return 2
            fi

            #URL base fijo     : "https://pkgs.dev.azure.com/azure-public"
            #  Organization ID : 3ccf6661-f8ce-4e8a-bb2e-eff943ddd3c7
            #          Feed ID : 3c18fd2c-cc7c-4cef-8ed7-20227ab3275b
            l_base_url_fixed="https://pkgs.dev.azure.com/azure-public/3ccf6661-f8ce-4e8a-bb2e-eff943ddd3c7/_apis/packaging/feeds/3c18fd2c-cc7c-4cef-8ed7-20227ab3275b/nuget/packages"


            #Parametro requeridos:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("${l_base_url_fixed}/Microsoft.CodeAnalysis.LanguageServer.${l_aux1}/versions/${p_repo_last_version}/content?api-version=6.0-preview.1")
            pna_artifact_names=("${p_repo_id}.zip")  #No se usara la extensión '.nupkg'
            pna_artifact_types=(11)
            ;;


        roslyn-ls-win)

            #Solo binarios windows
            if [ $p_is_win_binary -ne 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Prefijo usadas por MacOS
            #  osx-arm64
            #  osx-x64
            #Prefijo usadas por Windows
            #  win-arm64
            #  win-x64
            #  win-x86

            #Obtener el prefijo
            l_aux1=''
            if [ $g_os_type -eq 1 ]; then  #Si es Linux WSL2

                if [ $g_os_architecture_type = "x86_64" ]; then
                    l_aux1='win-x64'
                elif [ $g_os_architecture_type = "aarch64" ]; then
                    l_aux1='win-arm64'
                fi

            fi

            if [ -z "$l_aux1" ]; then
                #No implementado para la plataforma actual
                return 2
            fi

            #URL base fijo     : "https://pkgs.dev.azure.com/azure-public"
            #  Organization ID : 3ccf6661-f8ce-4e8a-bb2e-eff943ddd3c7
            #          Feed ID : 3c18fd2c-cc7c-4cef-8ed7-20227ab3275b
            l_base_url_fixed="https://pkgs.dev.azure.com/azure-public/3ccf6661-f8ce-4e8a-bb2e-eff943ddd3c7/_apis/packaging/feeds/3c18fd2c-cc7c-4cef-8ed7-20227ab3275b/nuget/packages"


            #Parametro requeridos:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("${l_base_url_fixed}/Microsoft.CodeAnalysis.LanguageServer.${l_aux1}/versions/${p_repo_last_version}/content?api-version=6.0-preview.1")
            pna_artifact_names=("${p_repo_id}.zip")  #No se usara la extensión '.nupkg'
            pna_artifact_types=(11)
            ;;


        netcoredbg)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("nvim-win64.zip")
                pna_artifact_types=(21)
            else
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("nvim-linux-arm64.tar.gz")
                    pna_artifact_types=(20)
                else
                    pna_artifact_names=("nvim-linux-x86_64.tar.gz")
                    pna_artifact_types=(20)
                fi
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("clangd-windows-${p_repo_last_pretty_version}.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("clangd-linux-${p_repo_last_pretty_version}.zip")
                pna_artifact_types=(11)
            fi
            ;;

        cmake)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("ninja-win.zip")
                pna_artifact_types=(11)
            else
                pna_artifact_names=("ninja-linux.zip")
                pna_artifact_types=(11)
            fi
            ;;

        powershell)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -ne 0 ]; then
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
                    return 2
                fi
            else
                #No se instala nada en Windows
                return 2
            fi
            ;;

        rust-analyzer)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("rust-analyzer-x86_64-pc-windows-msvc.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("rust-analyzer-aarch64-unknown-linux-gnu.gz")
                    else
                        pna_artifact_names=("rust-analyzer-x86_64-unknown-linux-musl.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("rust-analyzer-aarch64-unknown-linux-gnu.gz")
                    else
                        pna_artifact_names=("rust-analyzer-x86_64-unknown-linux-gnu.gz")
                    fi
                fi
                pna_artifact_types=(12)
            fi
            ;;

        graalvm)

            #Si no existe subversiones un repositorio
            if [ -z "$p_arti_subversion_version" ]; then

                #URL base fijo     : "https://github.com"
                #URL base variable : "graalvm/graalvm-ce-builds/releases/download/<tag_name>"
                l_base_url_variable="${p_repo_name}/releases/download/${p_repo_last_version}"

                #Generar la URL con el artefactado:
                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
                if [ $p_is_win_binary -eq 0 ]; then

                    pna_artifact_names=("graalvm-community-${p_repo_last_version}_windows-x64_bin.zip")

                    #No se descomprim
                    pna_artifact_types=(21)

                else
                    #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                    if [ $g_os_subtype_id -eq 1 ]; then
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("graalvm-community-${p_repo_last_version}_linux-aarch64_bin.tar.gz")
                        else
                            pna_artifact_names=("graalvm-community-${p_repo_last_version}_linux-x64_bin.tar.gz")
                        fi
                    else
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("graalvm-community-${p_repo_last_version}_linux-aarch64_bin.tar.gz")
                        else
                            pna_artifact_names=("graalvm-community-${p_repo_last_version}_linux-x64_bin.tar.gz")
                        fi
                    fi

                    #No se descomprim
                    pna_artifact_types=(20)

                fi

            #Si existe subversiones en un repositorios
            else

                #URL base fijo     : "https://github.com"
                #URL base variable : "graalvm/graalvm-ce-builds/releases/<tag_name>"
                l_base_url_variable="${p_repo_name}/releases/download/${p_arti_subversion_version}"


                #Generar la URL con el artefactado:
                pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
                if [ $p_is_win_binary -eq 0 ]; then

                    pna_artifact_names=("graalvm-community-${p_arti_subversion_version}_windows-x64_bin.zip")

                    #No se descomprim
                    pna_artifact_types=(21)

                else
                    #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                    if [ $g_os_subtype_id -eq 1 ]; then
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("graalvm-community-${p_arti_subversion_version}_linux-aarch64_bin.tar.gz")
                        else
                            pna_artifact_names=("graalvm-community-${p_arti_subversion_version}_linux-x64_bin.tar.gz")
                        fi
                    else
                        if [ "$g_os_architecture_type" = "aarch64" ]; then
                            pna_artifact_names=("graalvm-community-${p_arti_subversion_version}_linux-aarch64_bin.tar.gz")
                        else
                            pna_artifact_names=("graalvm-community-${p_arti_subversion_version}_linux-x64_bin.tar.gz")
                        fi
                    fi

                    #No se descomprim
                    pna_artifact_types=(20)

                fi


            fi
            ;;



        jdtls)
            #URL base fijo     : "https://download.eclipse.org"
            #URL base variable :
            l_base_url_variable="jdtls/milestones/${p_repo_last_pretty_version}"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            pna_artifact_names=("jdt-language-server-${p_repo_last_version}.tar.gz")
            pna_artifact_types=(10)
            ;;


        jbang)
            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("jbang-${p_repo_last_pretty_version}.zip")
            pna_artifact_types=(21)
            ;;


        maven)
            #URL base fijo     : "https://dlcdn.apache.org"
            #URL base variable :
            l_base_url_variable="maven/maven-${p_repo_last_pretty_version%%.*}/${p_repo_last_pretty_version}/binaries"

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")
            pna_artifact_names=("apache-maven-${p_repo_last_pretty_version}-bin.tar.gz")
            pna_artifact_types=(20)
            ;;


        vscode-java)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'redhat.java' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;



        vscode-java-debug)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'vscjava.vscode-java-debug' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;


        vscode-java-test)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'vscjava.vscode-java-test' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;


        vscode-maven)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'vscjava.vscode-maven' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;




        vscode-gradle)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'vscjava.vscode-gradle' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;



        vscode-microprofile)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'redhat.vscode-microprofile' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;



        vscode-quarkus)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'redhat.vscode-quarkus' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;




        vscode-jdecompiler)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'dgileadi.java-decompiler' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;



        vscode-springboot)

            #Obtener la URL del artefacto a descargar
            l_aux=$(get_extension_info_vscode 'vmware.vscode-spring-boot' 2)
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            l_result=1   #'pnra_artifact_baseurl' incluye el nombre del artecto a descargar
            pna_artifact_baseurl=("$l_aux")
            pna_artifact_names=("${p_repo_id}.zip") #No se usara la extensión '.vsix'
            pna_artifact_types=(11)
            ;;




        butane)
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("buildkit-${p_repo_last_version}.linux-amd64.tar.gz")
            pna_artifact_types=(10)
            ;;

        nerdctl)
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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

            if [ $p_is_win_binary -ne 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("ctags-${p_repo_last_version}-x64.zip")
            pna_artifact_types=(11)
            ;;


        ctags-nowin)

            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_names=("uctags-${p_repo_last_pretty_version}-linux-aarch64.release.tar.gz")
            else
                pna_artifact_names=("uctags-${p_repo_last_pretty_version}-linux-x86_64.release.tar.gz")
            fi
            pna_artifact_types=(10)
            ;;


        tmux-fingers)
            #No soportado para architecture ARM de 64 bits
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #No soportado para Windows
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
                return 2
            fi

            #No soportado para Windows
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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


        glow)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                pna_artifact_names=("glow_${p_repo_last_pretty_version}_Windows_x86_64.zip")
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("glow_${p_repo_last_pretty_version}_Linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("glow_${p_repo_last_pretty_version}_Linux_x86_64.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("glow_${p_repo_last_pretty_version}_Linux_arm64.tar.gz")
                    else
                        pna_artifact_names=("glow_${p_repo_last_pretty_version}_Linux_x86_64.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;


        gum)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
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

            #URL base fijo     :  "https://github.com"
            #l_base_url_fixed="${gA_repotypes[${l_repotype}]:-https://github.com}"
            #URL base variable :
            l_base_url_variable="${p_repo_name}/releases/download/nightly"

            #URL base para un repositorio GitHub
            pna_artifact_baseurl=("${l_base_url_fixed}/${l_base_url_variable}")

            #No soportado para Linux
            if [ $p_is_win_binary -ne 0 ]; then
                pna_artifact_baseurl=()
                pna_artifact_names=()
                return 2
            fi

            #Generar los datos de artefactado requeridos para su configuración:
            pna_artifact_names=("WezTerm-windows-nightly.zip")
            pna_artifact_types=(21)
            ;;


        uv)
            #Generar los datos de artefactado requeridos para su configuración:
            if [ $p_is_win_binary -eq 0 ]; then
                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    pna_artifact_names=("uv-aarch64-pc-windows-msvc.zip")
                else
                    pna_artifact_names=("uv-x86_64-pc-windows-msvc.zip")
                fi
                pna_artifact_types=(11)
            else
                #Si el SO es Linux Alpine (solo tiene soporta al runtime c++ 'musl')
                if [ $g_os_subtype_id -eq 1 ]; then
                    #No hay soporte para libc, solo musl
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("uv-aarch64-unknown-linux-musl.tar.gz")
                    else
                        pna_artifact_names=("uv-x86_64-unknown-linux-musl.tar.gz")
                    fi
                else
                    if [ "$g_os_architecture_type" = "aarch64" ]; then
                        pna_artifact_names=("uv-aarch64-unknown-linux-gnu.tar.gz")
                    else
                        pna_artifact_names=("uv-x86_64-unknown-linux-gnu.tar.gz")
                    fi
                fi
                pna_artifact_types=(10)
            fi
            ;;



        *)
           pna_artifact_baseurl=()
           pna_artifact_names=()
           return 2
           ;;
    esac

    return $l_result
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

    local p_is_win_binary=1      #(1) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                    #(0) Los binarios de los comandos se estan instalando en Linux
    if [ "$6" = "0" ]; then
        p_is_win_binary=0
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
    local l_runner_is_program_owner=1

    case "$p_repo_id" in

        bat)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                copy_binary_file "${l_source_path}" "bat" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1

                #Copiar los archivos de autocompletado
                create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
                create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'others'

                #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
                #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
                #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
                #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
                #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
                #create_folderpath_on_tools 0 'shell/keybindings' 'others'

                copy_file_on_tools "${l_source_path}/autocomplete" "bat.bash" 0 "shell/autocomplete/bash"       "bat.bash" 0
                copy_file_on_tools "${l_source_path}/autocomplete" "_bat.ps1" 0 "shell/autocomplete/powershell" "bat.ps1"  0


            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "bat.exe" 1 1

            fi
            ;;

        ripgrep)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                copy_binary_file "${l_source_path}" "rg" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}/doc" 1

                #Copiar los archivos de autocompletado
                create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
                create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'others'

                #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
                #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
                #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
                #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
                #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
                #create_folderpath_on_tools 0 'shell/keybindings' 'others'

                copy_file_on_tools "${l_source_path}/complete" "rg.bash" 0 "shell/autocomplete/bash"       "rg.bash" 0
                copy_file_on_tools "${l_source_path}/complete" "_rg.ps1" 0 "shell/autocomplete/powershell" "rg.ps1"  0

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "rg.exe" 1 1

            fi
            ;;


        #xsv)

        #    #Ruta local de los artefactos
        #    l_source_path="${p_repo_id}/${p_artifact_index}"

        #    #Copiar el comando y dar permiso de ejecucion a todos los usuarios
        #    if [ $p_is_win_binary -ne 0 ]; then

        #        #Copiar el comando
        #        copy_binary_file "${l_source_path}" "xsv" 0 1

        #    else

        #        #Copiar el comando
        #        copy_binary_file "${l_source_path}" "xsv.exe" 1 1

        #    fi
        #    ;;



        tailspin)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando
                copy_binary_file "${l_source_path}" "tspin" 0 1

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "tspin.exe" 1 1

            fi
            ;;




        xan)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando
                copy_binary_file "${l_source_path}" "xan" 0 1

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "xan.exe" 1 1

            fi
            ;;


        opencode)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando
                copy_binary_file "${l_source_path}" "opencode" 0 1

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "opencode.exe" 1 1

            fi
            ;;





        biome)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Si es WSL Linux
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}.exe\" como \"${g_temp_path}/${l_source_path}/biome.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}.exe" "${g_temp_path}/${l_source_path}/biome.exe"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "biome.exe" 1 1

                return 0
            fi

            #Si es Linux non-WSL

            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/biome\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/biome"

            #Copiar el comando
            copy_binary_file "${l_source_path}" "biome" 0 1
            return 0
            ;;



        delta)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -ne 0 ]; then


                #Copiar el comando
                copy_binary_file "${l_source_path}" "delta" 0 1

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "delta.exe" 1 1

            fi
            ;;

        less)

            if [ $p_is_win_binary -ne 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Windows" "$g_color_reset"
                return 40
            fi

            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "less.exe" 1 1
            copy_binary_file "${l_source_path}" "lesskey.exe" 1 1
            ;;

        butane)

            #Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then
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
            copy_binary_file "${l_source_path}" "butane" 0 1
            ;;


        fzf)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Copiar el comando
                copy_binary_file "${l_source_path}" "fzf.exe" 1 1

                return 0
            fi

            #B. Si es Linux que no sea WSL

            #Copiar el comando
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando fzf y dar permiso de ejecucion a todos los usuarios
                copy_binary_file "${l_source_path}" "fzf" 0 1

            #Descargar archivos opcionales del comando fzf desde la ultima version de la rama master de su repositorio 'junegunn/fzf'
            elif [ $p_artifact_index -eq 1 ]; then

                l_source_path="${l_source_path}/fzf-${p_repo_last_pretty_version}"
                printf 'Copiando archivos adicionales del comando fzf desde "%b%s%b"...\n' "$g_color_gray1" "$l_source_path" "$g_color_reset"

                #Copiar los archivos de ayuda man para comando fzf y el script fzf-tmux
                copy_man_files "${g_temp_path}/${l_source_path}/man/man1" 1


                #Copiar los archivos de autocompletado
                create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
                create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'others'

                copy_file_on_tools "${l_source_path}/shell" "completion.bash"  0 "shell/autocomplete/bash" "fzf.bash"  0
                copy_file_on_tools "${l_source_path}/shell" "completion.zsh"   0 "shell/autocomplete/zsh"  "fzf.zsh"   0


                #Copiar los script de keybindings
                create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
                #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
                create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
                create_folderpath_on_tools 0 'shell/keybindings' 'fish'
                #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
                #create_folderpath_on_tools 0 'shell/keybindings' 'others'

                copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash"  0 "shell/keybindings/bash"  "fzf.bash" 0
                copy_file_on_tools "${l_source_path}/shell" "key-bindings.zsh"   0 "shell/keybindings/zsh"   "fzf.zsh"  0
                copy_file_on_tools "${l_source_path}/shell" "key-bindings.fish"  0 "shell/keybindings/fish"  "fzf.fish" 0

                #Copiar otros script
                echo "Copiando \"./bin/fzf-preview.sh\" como \"~/.files/shell/bash/bin/cmds/fzf-preview.bash\"..."
                cp "${g_temp_path}/${l_source_path}/bin/fzf-preview.sh" "${g_repo_path}/shell/bash/bin/cmds/fzf-preview.bash"

                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" ${g_targethome_path}/shell/bash/bin/cmds/fzf-preview.bash
                fi

            fi
            ;;

        jq)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_is_win_binary -ne 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/jq\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/jq"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "jq" 0 1

            else

                echo "Renombrando \"jq-windows-amd64.exe\" como \"${g_temp_path}/${l_source_path}/jq.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/jq-windows-amd64.exe" "${g_temp_path}/${l_source_path}/jq.exe"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "jq.exe" 1 1

            fi
            ;;


        yq)
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Renombrar el binario antes de copiarlo
            if [ $p_is_win_binary -ne 0 ]; then

                if [ "$g_os_architecture_type" = "aarch64" ]; then
                    echo "Renombrando \"yq_linux_arm64\" como \"${g_temp_path}/${l_source_path}/yq\" ..."
                    mv "${g_temp_path}/${l_source_path}/yq_linux_arm64" "${g_temp_path}/${l_source_path}/yq"
                else
                    echo "Renombrando \"yq_linux_amd64\" como \"${g_temp_path}/${l_source_path}/yq\" ..."
                    mv "${g_temp_path}/${l_source_path}/yq_linux_amd64" "${g_temp_path}/${l_source_path}/yq"
                fi

                #Copiar el comando
                copy_binary_file "${l_source_path}" "yq" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1

            else
                echo "Renombrando \"yq_windows_amd64.exe\" como \"${g_temp_path}/${l_source_path}/yq.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/yq_windows_amd64.exe" "${g_temp_path}/${l_source_path}/yq.exe"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "yq.exe" 1 1
            fi
            ;;


        rclone)
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Renombrar el binario antes de copiarlo
            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando
                copy_binary_file "${l_source_path}" "rclone" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "rclone.exe" 1 1
            fi
            ;;


        oh-my-posh)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #En Linux
            if [ $p_is_win_binary -ne 0 ]; then

                #Instalación de binario 'oh-my-posh'
                if [ $p_artifact_index -eq 0 ]; then

                    echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/oh-my-posh\" ..."
                    mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/oh-my-posh"

                    #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                    copy_binary_file "${l_source_path}" "oh-my-posh" 0 1

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
                    copy_binary_file "${l_source_path}" "oh-my-posh.exe" 1 1

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
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "zoxide.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando
            copy_binary_file "${l_source_path}" "zoxide" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}/man/man1" 1


            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            create_folderpath_on_tools 0 'shell/autocomplete' 'others'

            copy_file_on_tools "${l_source_path}/completions" "zoxide.bash" 0 "shell/autocomplete/bash"       "zoxide.bash" 0
            copy_file_on_tools "${l_source_path}/completions" "_zoxide"     0 "shell/autocomplete/zsh"        "zoxide.zsh"  0
            copy_file_on_tools "${l_source_path}/completions" "zoxide.fish" 0 "shell/autocomplete/fish"       "zoxide.fish" 0
            copy_file_on_tools "${l_source_path}/completions" "zoxide.ps1"  0 "shell/autocomplete/powershell" "zoxide.ps1"  0
            copy_file_on_tools "${l_source_path}/completions" "zoxide.ts"   0 "shell/autocomplete/others"     "zoxide.ts"   0
            copy_file_on_tools "${l_source_path}/completions" "_zoxide.elv" 0 "shell/autocomplete/others"     "zoxide.elv"  0


            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0
            ;;



        eza)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Binarios
                if [ $p_artifact_index -eq 0 ]; then

                    #Copiar el comando
                    copy_binary_file "${l_source_path}" "eza.exe" 1 1

                fi
                return 0
            fi

            #B. Si es Linux (no WSL)

            #Binarios
            if [ $p_artifact_index -eq 0 ]; then

                #Copiar el comando
                copy_binary_file "${l_source_path}" "eza" 0 1


            #Copiar los archivos de autocompletado
            elif [ $p_artifact_index -eq 1 ]; then

                l_source_path="${l_source_path}/target/completions-${p_repo_last_pretty_version}"

                #Copiar los archivos de autocompletado
                create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
                create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
                create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
                #create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
                create_folderpath_on_tools 0 'shell/autocomplete' 'others'

                copy_file_on_tools "${l_source_path}" "eza"      0 "shell/autocomplete/bash"   "eza.bash" 0
                copy_file_on_tools "${l_source_path}" "_eza"     0 "shell/autocomplete/zsh"    "eza.zsh"  0
                copy_file_on_tools "${l_source_path}" "eza.fish" 0 "shell/autocomplete/fish"   "eza.fish" 0
                copy_file_on_tools "${l_source_path}" "eza.nu"   0 "shell/autocomplete/others" "eza.nu"   0


                #Copiar los script de keybindings
                #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
                #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
                #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
                #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
                #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
                #create_folderpath_on_tools 0 'shell/keybindings' 'others'

                #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0


            #Copiar los archivos de ayuda (man)
            elif [ $p_artifact_index -eq 2 ]; then

                l_source_path="${l_source_path}/target/man-${p_repo_last_pretty_version}"

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}" 1
                copy_man_files "${g_temp_path}/${l_source_path}" 5

            fi
            ;;


        github-cli)
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Renombrar el binario antes de copiarlo
            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando
                copy_binary_file "${l_source_path}/bin" "gh" 0 1

                #Copiar los archivos de ayuda man para comando
                copy_man_files "${g_temp_path}/${l_source_path}/share/man/man1" 1

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}/bin" "gh.exe" 1 1

            fi
            ;;


        shfmt)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}.exe\" como \"${g_temp_path}/${l_source_path}/shfmt.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}.exe" "${g_temp_path}/${l_source_path}/shfmt.exe"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "shfmt.exe" 1 1

                return 0

            fi

            #Si es Linux non-WSL
            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/shfmt\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/shfmt"

            #Copiar el comando
            copy_binary_file "${l_source_path}" "shfmt" 0 1

            ;;




        shellcheck)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -eq 0 ]; then

                #Ruta local de los artefactos
                l_source_path="${p_repo_id}/${p_artifact_index}"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "shellcheck.exe" 1 1

                return 0

            fi

            #Si es Linux non-WSL

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/shellcheck-v${p_repo_last_pretty_version}"

            #Copiar el comando
            copy_binary_file "${l_source_path}" "shellcheck" 0 1

            ;;



        websocat)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Si es WSL Linux
            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}.exe\" como \"${g_temp_path}/${l_source_path}/websocat.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}.exe" "${g_temp_path}/${l_source_path}/websocat.exe"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "websocat.exe" 1 1

                return 0
            fi

            #Si es Linux non-WSL

            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/websocat\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/websocat"

            #Copiar el comando
            copy_binary_file "${l_source_path}" "websocat" 0 1
            return 0
            ;;




        tmux-fingers)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then
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
            copy_binary_file "${l_source_path}" "tmux-fingers" 0 1

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "tmux-fingers.info" "$p_repo_last_pretty_version" 0
            ;;



        tmux-thumbs)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi


            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando
            copy_binary_file "${l_source_path}" "tmux-thumbs" 0 1
            copy_binary_file "${l_source_path}" "thumbs" 0 1
            ;;



        yazi)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "yazi.exe" 1 1
                copy_binary_file "${l_source_path}" "ya.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "yazi" 0 1
            copy_binary_file "${l_source_path}" "ya" 0 1


            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            create_folderpath_on_tools 0 'shell/autocomplete' 'others'

            copy_file_on_tools "${l_source_path}/completions" "yazi.bash"   0 "shell/autocomplete/bash"       "yazi.bash"  0
            copy_file_on_tools "${l_source_path}/completions" "_yazi"       0 "shell/autocomplete/zsh"        "yazi.zsh"   0
            copy_file_on_tools "${l_source_path}/completions" "yazi.fish"   0 "shell/autocomplete/fish"       "yazi.fish"  0
            copy_file_on_tools "${l_source_path}/completions" "_yazi.ps1"   0 "shell/autocomplete/powershell" "yazi.ps1"   0
            copy_file_on_tools "${l_source_path}/completions" "yazi.ts"     0 "shell/autocomplete/others"     "yazi.ts"    0
            copy_file_on_tools "${l_source_path}/completions" "yazi.elv"    0 "shell/autocomplete/others"     "yazi.elv"   0
            copy_file_on_tools "${l_source_path}/completions" "yazi.nu"     0 "shell/autocomplete/others"     "yazi.nu"    0


            copy_file_on_tools "${l_source_path}/completions" "ya.bash"   0 "shell/autocomplete/bash"       "ya.bash"   0
            copy_file_on_tools "${l_source_path}/completions" "_ya"       0 "shell/autocomplete/zsh"        "ya.zsh"    0
            copy_file_on_tools "${l_source_path}/completions" "ya.fish"   0 "shell/autocomplete/fish"       "ya.fish"   0
            copy_file_on_tools "${l_source_path}/completions" "_ya.ps1"   0 "shell/autocomplete/powershell" "ya.ps1"    0
            copy_file_on_tools "${l_source_path}/completions" "ya.ts"     0 "shell/autocomplete/others"     "ya.ts"     0
            copy_file_on_tools "${l_source_path}/completions" "ya.elv"    0 "shell/autocomplete/others"     "ya.elv"    0
            copy_file_on_tools "${l_source_path}/completions" "ya.nu"     0 "shell/autocomplete/others"     "ya.nu"     0


            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0

            # Copiando/descargado otros archivos
            printf 'Descargando el archivo de configuracion de "%s" a nivel usuario en "%s"\n' "flavor.toml" "~/.cofig/yazi/flavors/catppuccin-mocha.yazi/"
            curl -fLo ${g_repo_path}/etc/yazi/catppuccin-mocha/flavor.toml https://raw.githubusercontent.com/yazi-rs/flavors/main/catppuccin-mocha.yazi/flavor.toml

            printf 'Descargando el archivo de configuracion de "%s" a nivel usuario en "%s"\n' "flavor.toml" "~/.cofig/yazi/flavors/catppuccin-mocha.yazi/"
            curl -fLo ${g_repo_path}/etc/yazi/catppuccin-mocha/tmtheme.xml  https://raw.githubusercontent.com/yazi-rs/flavors/main/catppuccin-mocha.yazi/tmtheme.xml

            if [ $g_runner_is_target_user -ne 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/yazi/catppuccin-mocha/flavor.toml
                chown "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/yazi/catppuccin-mocha/tmtheme.xml
            fi
            ;;


        lazygit)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "lazygit.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "lazygit" 0 1
            ;;


        rmpc)

            #Si es un binario de Windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi


            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "rmpc" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}/man" 1

            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'others'

            copy_file_on_tools "${l_source_path}/completions" "rmpc.bash"     0 "shell/autocomplete/bash"       "rmpc.bash"  0
            copy_file_on_tools "${l_source_path}/completions" "_rmpc"         0 "shell/autocomplete/zsh"        "rmpc.zsh"   0
            copy_file_on_tools "${l_source_path}/completions" "rmpc.fish"     0 "shell/autocomplete/fish"       "rmpc.fish"  0


            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0
            ;;



        fd)
            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "fd.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "fd" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}" 1

            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'others'

            copy_file_on_tools "${l_source_path}/completions" "fd.bash"     0 "shell/autocomplete/bash"       "fd.bash"  0
            copy_file_on_tools "${l_source_path}/completions" "fd.ps1"      0 "shell/autocomplete/powershell" "fd.ps1"   0


            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0
            ;;


        jwt)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "jwt.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "jwt" 0 1
            ;;

        grpcurl)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "grpcurl.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "grpcurl" 0 1
            ;;


        evans)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "evans.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "evans" 0 1
            ;;


        dive)

            #A. No se soportado por Windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi

            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "dive" 0 1
            ;;


        crictl)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

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
                copy_binary_file "${l_source_path}" "crictl" 0 1
            else
                copy_binary_file "${l_source_path}" "critest" 0 1
            fi
            ;;


        llama-swap)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es binario Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "llama-swap.exe" 1 1
                return 0

            fi

            #B. Si es binario Linux

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "llama-swap" 0 1
            ;;



        flamelens)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es binario Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "flamelens.exe" 1 1
                return 0

            fi

            #B. Si es binario Linux

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}/${p_artifact_filename_woext}" "flamelens" 0 1
            ;;



        qsv)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "qsv" 2 ""

                #Descomprimir
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "qsv" "" ""
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0
            fi


            #B. Si son binarios Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "qsv" 2 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "qsv" "" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            ;;



        tree-sitter)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/tree-sitter.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/tree-sitter.exe"

                #Copiar el comando
                copy_binary_file "${l_source_path}" "tree-sitter.exe" 1 1

                return 0

            fi

            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/tree-sitter\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/tree-sitter"

            #Copiar el comando
            copy_binary_file "${l_source_path}" "tree-sitter" 0 1
            ;;



        distrobox)

            #A. Si es un binario Windows
            if [ $p_is_win_binary -eq 0 ]; then

                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40

            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/distrobox-${p_repo_last_pretty_version}"

            #B. Si es binario Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "distrobox"                0 1
            copy_binary_file "${l_source_path}" "distrobox-assemble"       0 1
            copy_binary_file "${l_source_path}" "distrobox-create"         0 1
            copy_binary_file "${l_source_path}" "distrobox-enter"          0 1
            copy_binary_file "${l_source_path}" "distrobox-ephemeral"      0 1
            copy_binary_file "${l_source_path}" "distrobox-export"         0 1
            copy_binary_file "${l_source_path}" "distrobox-generate-entry" 0 1
            copy_binary_file "${l_source_path}" "distrobox-host-exec"      0 1
            copy_binary_file "${l_source_path}" "distrobox-init"           0 1
            copy_binary_file "${l_source_path}" "distrobox-list"           0 1
            copy_binary_file "${l_source_path}" "distrobox-rm"             0 1
            copy_binary_file "${l_source_path}" "distrobox-stop"           0 1
            copy_binary_file "${l_source_path}" "distrobox-upgrade"        0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}/man" 1

            #Copiando los iconos de la aplicacion
            local la_app_icons=(
                'terminal-distrobox-icon.svg'
                'hicolor/16x16/apps/terminal-distrobox-icon.png'
                'hicolor/22x22/apps/terminal-distrobox-icon.png'
                'hicolor/24x24/apps/terminal-distrobox-icon.png'
                'hicolor/32x32/apps/terminal-distrobox-icon.png'
                'hicolor/36x36/apps/terminal-distrobox-icon.png'
                'hicolor/48x48/apps/terminal-distrobox-icon.png'
                'hicolor/64x64/apps/terminal-distrobox-icon.png'
                'hicolor/72x72/apps/terminal-distrobox-icon.png'
                'hicolor/96x96/apps/terminal-distrobox-icon.png'
                'hicolor/128x128/apps/terminal-distrobox-icon.png'
                'hicolor/256x256/apps/terminal-distrobox-icon.png'
                )
                copy_app_icon_files "${l_source_path}/icons" "la_app_icons"

            #Copiando los archivos de al folder de tools:
            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'others'


            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox"                 0 "shell/autocomplete/bash" "distrobox.bash"                 0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-assemble"        0 "shell/autocomplete/bash" "distrobox-assemble.bash"        0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-create"          0 "shell/autocomplete/bash" "distrobox-create.bash"          0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-enter"           0 "shell/autocomplete/bash" "distrobox-enter.bash"           0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-ephemeral"       0 "shell/autocomplete/bash" "distrobox-ephemeral.bash"       0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-generate-entry"  0 "shell/autocomplete/bash" "distrobox-generate-entry.bash"  0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-list"            0 "shell/autocomplete/bash" "distrobox-list.bash"            0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-rm"              0 "shell/autocomplete/bash" "distrobox-rm.bash"              0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-stop"            0 "shell/autocomplete/bash" "distrobox-stop.bash"            0
            copy_file_on_tools "${l_source_path}/completions/bash" "distrobox-upgrade"         0 "shell/autocomplete/bash" "distrobox-upgrade.bash"         0

            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox"                0 "shell/autocomplete/zsh" "distrobox.zsh"                   0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-assemble"       0 "shell/autocomplete/zsh" "distrobox-assemble.zsh"          0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-create"         0 "shell/autocomplete/zsh" "distrobox-create.zsh"            0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-enter"          0 "shell/autocomplete/zsh" "distrobox-enter.zsh"             0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-ephemeral"      0 "shell/autocomplete/zsh" "distrobox-ephemeral.zsh"         0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-generate-entry" 0 "shell/autocomplete/zsh" "distrobox-generate-entry.zsh"    0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-list"           0 "shell/autocomplete/zsh" "distrobox-list.zsh"              0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-rm"             0 "shell/autocomplete/zsh" "distrobox-rm.zsh"                0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-stop"           0 "shell/autocomplete/zsh" "distrobox-stop.zsh"              0
            copy_file_on_tools "${l_source_path}/completions/zsh"  "_distrobox-upgrade"        0 "shell/autocomplete/zsh" "distrobox-upgrade.zsh"           0

            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0


            #Copiar otros archivos
            create_folderpath_on_tools 0 '' 'distrobox/docs/icons'
            copy_file_on_tools "${l_source_path}" "uninstall" 0 "distrobox" "uninstall.bash" 0
            copy_files_on_tools "${l_source_path}/docs/assets/png/distros" "" 0 "distrobox/docs/icons" 0 0
            ;;



        powershell_es)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/powershell_es" 2 ""

                #Descomprimir
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "lsp_servers/powershell_es" "" ""
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "$p_repo_id" "$p_repo_last_pretty_version" 1

                return 0
            fi


            #B. Si son binarios Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/powershell_es" 2 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "lsp_servers/powershell_es" "" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "$p_repo_id" "$p_repo_last_pretty_version" 0
            ;;



        marksman)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/markdown_ls" 2 ""

                #Copiar el comando
                copy_files_on_tools "${l_source_path}" "marksman.exe" 1 "lsp_servers/markdown_ls" 1 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "marksman.info" "$p_repo_last_pretty_version" 1

                return 0
            fi

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/markdown_ls" 2 ""


            echo "Renombrando \"${p_artifact_filename}\" como \"${g_temp_path}/${l_source_path}/marksman\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename}" "${g_temp_path}/${l_source_path}/marksman"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_files_on_tools "${l_source_path}" "marksman" 0 "lsp_servers/markdown_ls" 1 1

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "marksman.info" "$p_repo_last_pretty_version" 0
            ;;



        taplo)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/toml_ls" 2 ""

                #Copiar el comando
                copy_files_on_tools "${l_source_path}" "taplo.exe" 1 "lsp_servers/toml_ls" 1 1

                return 0

            fi

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/toml_ls" 2 ""


            echo "Renombrando \"${p_artifact_filename}\" como \"${g_temp_path}/${l_source_path}/taplo\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename}" "${g_temp_path}/${l_source_path}/taplo"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_files_on_tools "${l_source_path}" "taplo" 0 "lsp_servers/toml_ls" 1 1
            ;;



        lemminx)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/xml_ls" 2 ""

                echo "Renombrando \"${p_artifact_filename_woext}.exe\" como \"${g_temp_path}/${l_source_path}/lemminx.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}.exe" "${g_temp_path}/${l_source_path}/lemminx.exe"

                #Copiar el comando
                copy_files_on_tools "${l_source_path}" "lemminx.exe" 1 "lsp_servers/xml_ls" 1 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "lemminx.info" "$p_repo_last_pretty_version" 1

                return 0
            fi

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/xml_ls" 2 ""


            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/lemminx\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/lemminx"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_files_on_tools "${l_source_path}" "lemminx" 0 "lsp_servers/xml_ls" 1 1

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "lemminx.info" "$p_repo_last_pretty_version" 0
            ;;


        cilium)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            if [ $p_is_win_binary -ne 0 ]; then


                #Copiar el comando
                copy_binary_file "${l_source_path}" "cilium" 0 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "cilium.info" "$p_repo_last_pretty_version" 0

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "cilium.exe" 1 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "cilium.info" "$p_repo_last_pretty_version" 1
            fi
            ;;


        kubelet)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi


            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "kubelet" 0 1

            #Desacargar archivos adicionales para su configuración
            mkdir -p ${g_repo_path}/etc/kubelet/systemd
            l_aux=$(curl -sL https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubelet/kubelet.service 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                printf 'Creando el archivo "%b~/.files/etc/kubelet/systemd/kubelet.service%b" ... \n' "$g_color_gray1" "$g_color_reset"
                echo "$l_aux" | sed "s:/usr/bin:${g_lnx_bin_path}:g" > ${g_repo_path}/etc/kubelet/systemd/kubelet.service

                #Fix permisos
                if [ $g_runner_is_target_user -ne 0 ]; then
                    chown -R "${g_targethome_owner}:${g_targethome_group}" ${g_repo_path}/etc/kubelet/
                fi

            fi
            ;;


        kubeadm)

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi

            #B. Si es Linux (no WSL)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "kubeadm" 0 1

            #Desacargar archivos adicionales para su configuración
            mkdir -p ${g_repo_path}/etc/kubeadm
            l_aux=$(curl -sL https://raw.githubusercontent.com/kubernetes/release/v0.16.2/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                printf 'Creando el archivo "%b~/.files/etc/kubeadm/10-kubeadm.conf%b" ... \n' "$g_color_gray1" "$g_color_reset"
                echo "$l_aux" | sed "s:/usr/bin:${g_lnx_bin_path}:g" > ${g_repo_path}/etc/kubeadm/10-kubeadm.conf

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
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "kubectl.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "kubectl" 0 1
            ;;

        oc)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows y se copia binarios de windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "oc.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "oc" 0 1
            ;;

        pgo)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                echo "Renombrando \"${p_artifact_filename_woext}.exe\" en \"${g_temp_path}/${l_source_path}/kubectl-pgo.exe\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}.exe" "${g_temp_path}/${l_source_path}/kubectl-pgo.exe"

                copy_binary_file "${l_source_path}" "kubectl-pgo.exe" 1 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "pgo.info" "$p_repo_last_pretty_version" 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            echo "Renombrando \"${p_artifact_filename_woext}\" en \"${g_temp_path}/${l_source_path}/kubectl-pgo\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/kubectl-pgo"

            copy_binary_file "${l_source_path}" "kubectl-pgo" 0 1

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "pgo.info" "$p_repo_last_pretty_version" 0
            ;;

        helm)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                l_source_path="${l_source_path}/windows-amd64"
                copy_binary_file "${l_source_path}" "helm.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            l_source_path="${l_source_path}/linux-amd64"
            copy_binary_file "${l_source_path}" "helm" 0 1
            ;;

        operator-sdk)

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

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

                copy_binary_file "${l_source_path}" "operator-sdk" 0 1

            #Instalacion del SDK para construir el operador usando Helm
            else

                echo "Renombrando \"${p_artifact_filename_woext}\" en \"${g_temp_path}/${l_source_path}/helm-operator\" ..."
                mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/helm-operator"

                copy_binary_file "${l_source_path}" "helm-operator" 0 1

            fi
            ;;



        step)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/step_${p_repo_last_pretty_version}"


            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}/bin" "step.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}/bin" "step" 0 1

            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'others'

            copy_file_on_tools "${l_source_path}/autocomplete" "bash_autocomplete"   0 "shell/autocomplete/bash"  "step.bash"   0
            copy_file_on_tools "${l_source_path}/autocomplete" "zsh_autocomplete"    0 "shell/autocomplete/zsh"   "step.zsh"    0


            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0

            ;;



        ninja)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "ninja.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "ninja" 0 1
            ;;


        rust-analyzer)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es un binario Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/rust_ls" 2 ""

                #echo "Renombrando \"${p_artifact_filename_woext}.exe\" como \"${g_temp_path}/${l_source_path}/rust-analyzer.exe\" ..."
                #mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}.exe" "${g_temp_path}/${l_source_path}/rust-analyzer.exe"

                #Copiando el binario en una ruta del path
                copy_files_on_tools "${l_source_path}" "rust-analyzer.exe" 1 "lsp_servers/rust_ls" 1 1

                #Debido que el comando y github usan versiones diferentes, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "rust-analyzer.info" "$p_repo_last_pretty_version" 1

                return 0

            fi

            #B. Si es binario Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/rust_ls" 2 ""

            echo "Renombrando \"${p_artifact_filename_woext}\" como \"${g_temp_path}/${l_source_path}/rust-analyzer\" ..."
            mv "${g_temp_path}/${l_source_path}/${p_artifact_filename_woext}" "${g_temp_path}/${l_source_path}/rust-analyzer"

            #Copiando el binario en una ruta del path
            copy_files_on_tools "${l_source_path}" "rust-analyzer" 0 "lsp_servers/rust_ls" 1 1

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "rust-analyzer.info" "$p_repo_last_pretty_version" 0
            ;;


        sesh)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "sesh.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "sesh" 0 1
            ;;



        glow)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "glow.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "glow" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}/manpages" 1

            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'others'


            copy_file_on_tools "${l_source_path}/completions" "glow.bash"     0 "shell/autocomplete/bash"       "glow.bash"  0
            copy_file_on_tools "${l_source_path}/completions" "glow.zsh"      0 "shell/autocomplete/zsh"        "glow.zsh"   0
            copy_file_on_tools "${l_source_path}/completions" "glow.fish"     0 "shell/autocomplete/fish"       "glow.fish"  0


            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash" 0
            ;;



        gum)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                copy_binary_file "${l_source_path}" "gum.exe" 1 1
                return 0

            fi

            #B. Si es Linux (no WSL)

            #Copiando el binario en una ruta del path
            copy_binary_file "${l_source_path}" "gum" 0 1

            #Copiar los archivos de ayuda man para comando
            copy_man_files "${g_temp_path}/${l_source_path}/manpages" 1

            #Copiar los archivos de autocompletado
            create_folderpath_on_tools 0 '' 'shell/autocomplete/bash'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'sh'
            create_folderpath_on_tools 0 'shell/autocomplete' 'zsh'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'fish'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'powershell'
            #create_folderpath_on_tools 0 'shell/autocomplete' 'others'

            copy_file_on_tools "${l_source_path}/completions" "gum.bash"   0 "shell/autocomplete/bash"  "gum.bash"   0
            copy_file_on_tools "${l_source_path}/completions" "gim.zsh"    0 "shell/autocomplete/zsh"   "gum.zsh"    0
            copy_file_on_tools "${l_source_path}/completions" "gum.fish"   0 "shell/autocomplete/fish"  "gum.fish"   0


            #Copiar los script de keybindings
            #create_folderpath_on_tools 0 '' 'shell/keybindings/bash'
            #create_folderpath_on_tools 0 'shell/keybindings' 'sh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'zsh'
            #create_folderpath_on_tools 0 'shell/keybindings' 'fish'
            #create_folderpath_on_tools 0 'shell/keybindings' 'powershell'
            #create_folderpath_on_tools 0 'shell/keybindings' 'others'

            #copy_file_on_tools "${l_source_path}/shell" "key-bindings.bash" 0 "shell/keybindings/bash" "fzf.bash"  0

            ;;


        hadolint)

            #No se soportado por Windows
            if [ $p_is_win_binary -eq 0 ]; then
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
            copy_binary_file "${l_source_path}" "hadolint" 0 1
            ;;



        trivy)

            #No se soportado por Windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "trivy" 0 1

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
            if [ $p_is_win_binary -eq 0 ]; then
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
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "containerd.io" "$g_color_reset" \
                       "$g_color_yellow1" "$g_color_reset"
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

            copy_binary_file "${l_source_path}" "runc" 0 1

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
            if [ $p_is_win_binary -eq 0 ]; then
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
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "podman" "$g_color_reset" \
                       "$g_color_yellow1" "$g_color_reset"
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

            copy_binary_file "${l_source_path}" "crun" 0 1

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
            if [ $p_is_win_binary -eq 0 ]; then
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
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "containerd.io" "$g_color_reset" \
                       "$g_color_yellow1" "$g_color_reset"
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

            copy_binary_file "${l_source_path}" "slirp4netns" 0 1

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
            if [ $p_is_win_binary -eq 0 ]; then
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
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "containerd.io" "$g_color_reset" \
                       "$g_color_yellow1" "$g_color_reset"
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

            copy_binary_file "${l_source_path}" "fuse-overlayfs" 0 1

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
            if [ $p_is_win_binary -eq 0 ]; then
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
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "containerd.io" "$g_color_reset" \
                       "$g_color_yellow1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi

            #3. Copiar el comando y dar permiso de ejecucion a todos los usuarios
            copy_binary_file "${l_source_path}" "rootlesskit-docker-proxy" 0 1
            copy_binary_file "${l_source_path}" "rootlesskit" 0 1
            copy_binary_file "${l_source_path}" "rootlessctl" 0 1


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
            if [ $p_is_win_binary -eq 0 ]; then
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
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "containerd.io" "$g_color_reset" \
                       "$g_color_yellow1" "$g_color_reset"
            fi

            request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
            l_status=$?

            #Si esta iniciado pero no acepta detenerlo
            if [ $l_status -eq 2 ]; then
                return 41
            fi


            #3. Configurar: Copiar el comando y dar permiso de ejecucion a todos los usuarios
            #copy_binary_file "${l_source_path}" "containerd-shim" 0 1
            #copy_binary_file "${l_source_path}" "containerd-shim-runc-v1" 0 1
            copy_binary_file "${l_source_path}" "containerd-shim-runc-v2" 0 1
            copy_binary_file "${l_source_path}" "containerd-stress" 0 1
            copy_binary_file "${l_source_path}" "ctr" 0 1
            copy_binary_file "${l_source_path}" "containerd" 0 1

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
                printf '%b   ~/.files/shell/sh/bin/cmds/containerd-rootless-setuptool.sh install%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   Opcional:%b\n' "$g_color_gray1" "$g_color_reset"
                printf '%b      > Para ingresar al user-namespace creado use:%b ~/.files/shell/sh/bin/cmds/containerd-rootless-setuptool.sh nsenter bash%b\n' "$g_color_gray1" \
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            copy_binary_file "${l_source_path}" "buildkit-runc" 0 1
            copy_binary_file "${l_source_path}" "buildkitd" 0 1
            copy_binary_file "${l_source_path}" "buildkit-qemu" 0 0
            copy_binary_file "${l_source_path}" "buildctl" 0 1

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
                printf '%b   ~/.files/shell/sh/bin/cmds/containerd-rootless-setuptool.sh install-buildkit%b\n' "$g_color_yellow1" "$g_color_reset"
                printf '%b   Opcional:%b\n' "$g_color_gray1" "$g_color_reset"
                printf '%b      > Para ingresar al user-namespace creado use:%b ~/.files/shell/sh/bin/cmds/containerd-rootless-setuptool.sh nsenter bash%b\n' "$g_color_gray1" "$g_color_yellow1" \
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
            if [ $p_is_win_binary -eq 0 ]; then
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
                copy_binary_file "${l_source_path}" "nerdctl" 0 1

                #Archivos para instalar 'containerd' de modo rootless
                echo "Copiando \"${l_source_path}/containerd-rootless.sh\" (tool gestión del ContainerD en modo rootless) a \"~/.files/shell/sh/bin/cmds\" ..."
                cp "${g_temp_path}/${l_source_path}/containerd-rootless.sh" ${g_repo_path}/shell/sh/bin/cmds/
                chmod u+x ${g_repo_path}/shell/sh/bin/cmds/containerd-rootless.sh

                echo "Copiando \"${l_source_path}/containerd-rootless-setuptool.sh\" (instalador de ContainerD en modo rootless)  a \"~/.files/shell/sh/bin/cmds\" ..."
                cp "${g_temp_path}/${l_source_path}/containerd-rootless-setuptool.sh" ${g_repo_path}/shell/sh/bin/cmds/
                chmod u+x ${g_repo_path}/shell/sh/bin/cmds/containerd-rootless-setuptool.sh

                #Fix permisos
                if [ $g_runner_is_target_user -ne 0 ]; then
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
                compare_version_current_with "bypass4netns" "${g_temp_path}/$l_source_path" $p_is_win_binary
                l_status=$?

                #Actualizar solo no esta configurado o tiene una version menor a la actual
                if [ $l_status -eq 9 ] || [ $l_status -eq 2 ]; then

                    #Instalar este artefacto requiere solicitar detener el servicio solo la versión actual existe
                    #Solo solicitarlo una vez
                    if [ $l_status_stop -ge 0 ]; then

                        is_package_installed 'containerd' $g_os_subtype_id
                        l_status_stop=$?

                        if [ $l_status_stop -eq 0 ]; then
                            printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "containerd.io" "$g_color_reset" \
                                   "$g_color_yellow1" "$g_color_reset"
                        fi

                        request_stop_systemd_unit 'containerd.service' 1 $l_is_noninteractive "$p_repo_id" "$p_artifact_index"
                        l_status_stop=$?
                    fi

                    #Si no esta iniciado o si esta iniciado se acepta detenerlo, instalarlo
                    if [ $l_status_stop -ne 2 ]; then

                        printf 'Instalando el programa "bypass4netns" (acelerador de "Slirp4netns") artefacto[%s] del repositorio %s ...\n' "$p_artifact_index" \
                               "$p_repo_id"
                        copy_binary_file "${l_source_path}" "bypass4netns" 0 1
                        copy_binary_file "${l_source_path}" "bypass4netnsd" 0 1

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

            if [ $p_is_win_binary -eq 0 ]; then
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

            copy_binary_file "${l_source_path}" "k0s" 0 1


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

            if [ $p_is_win_binary -eq 0 ]; then
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
            create_or_clean_folder_on_tools 0 "aws-cli" 0 ""

            #Instalando
            if [ $p_flag_install -eq 0 ]; then

                #Ejecutando los script de instalación
                exec_script_on_tools "${l_source_path}/aws" "install" "aws-cli" "-i " "-b ${g_tools_path}/aws-cli"

            #Actualizando
            else

                #Ejecutando los script de instalación
                exec_script_on_tools "${l_source_path}/aws" "install" "aws-cli" "-i " "-b ${g_tools_path}/aws-cli --update"

            fi
            ;;


        rust)

            #No habilitado para Windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi

            #Crear el folder de programa si no existe pero NO Limpiar el contenido si existe (el 'install.sh' puede eliminar versiones anteriores)
            create_or_clean_folder_on_tools 0 "rust" 0 ""

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Las componente por defecto del instalador 'standalone' (no incluye 'rust-src')
            if [ $p_artifact_index -eq 0 ]; then

                #Ejecutando los script de instalación
                printf '> Copiando los archivos a la ruta "%b%s%b", usando el instalador "%b%s%b" ...\n' "$g_color_gray1" \
                       "${g_temp_path}/${l_source_path}" "$g_color_reset" "$g_color_gray1" "install.sh" "$g_color_reset"
                exec_script_on_tools "${l_source_path}" "install.sh" "rust" "--prefix=" \
                    "--without='rust-analyzer-preview,llvm-tools-preview' --disable-ldconfig"

                #Registrando las librerias del rust "${g_tools_path}/rust/lib"

                #Copiando los archivos ayudas a la carpeta de ayuda del sistema
                copy_man_files "${g_tools_path}/rust/share/man/man1" 1

                register_dynamiclibrary_to_system "rust/lib" "rust"


            #Las componente por defecto de 'rust-src'
            else

                #Ejecutando los script de instalación
                exec_script_on_tools "${l_source_path}" "install.sh" "rust" "--prefix=" "--disable-ldconfig"

            fi

            #Validar si 'DotNet' esta en el PATH
            echo "$PATH" | grep "${g_tools_path}/rust/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "Rust"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/rust/bin:$PATH\n' "${g_tools_path}"

                PATH="${g_tools_path}/rust/bin:$PATH"
                export PATH
            fi
            ;;



        nerd-fonts)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Copiando los archivos de fuente '*.otf' y '*.ttf' a la ruta de fuentes (nunca actualizar el cache si es la ultima fuente instalada)
                copy_font_files "$l_source_path" 1 "${p_artifact_filename_woext}" 1

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "nerd-fonts.info" "$p_repo_last_pretty_version" 1

                printf '%bDeberá instalar (copiar) manualmente los archivos%b de "%s" en "%s".\n' "$g_color_yellow1" \
                       "$g_color_reset" "$g_win_fonts_path" "C:/Windows/Fonts"

                return 0

            fi

            #B. Si es Linux

            #Copiando los archivos de fuente '*.otf' y '*.ttf' a la ruta de fuentes (solo actualizar el cache si es la ultima fuente instalada)
            copy_font_files "$l_source_path" 0 "${p_artifact_filename_woext}" $p_artifact_is_last

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "nerd-fonts.info" "$p_repo_last_pretty_version" 0
            ;;



        protoc)

            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "protoc" 1 ""

                #Moviendo el cotenido del folder source al folder de programa
                move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 1 "protoc" ""
                #move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 1 "protoc" "-not -name '${p_artifact_filename_woext}.zip'"
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "protoc" 1 ""

            #Moviendo el cotenido del folder source al folder de programa
            move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 0 "protoc" ""
            #move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 0 "protoc" "-not -name '${p_artifact_filename_woext}.tar.gz'"


            #Validar si 'protoc' esta en el PATH
            echo "$PATH" | grep "${g_tools_path}/protoc/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "ProtoC"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/protoc/bin:$PATH\n' "${g_tools_path}"
                export PATH=${g_tools_path}/protoc/bin:$PATH
            fi
            ;;


        omnisharp-ls)

            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/omnisharp_ls" 1 ""

                move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 1 "lsp_servers/omnisharp_ls" ""
                #move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 1 "LSP_Servers/omnisharp_ls" "-not -name '${p_artifact_filename_woext}.zip'"
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/omnisharp_ls" 1 ""

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 0 "lsp_servers/omnisharp_ls" ""
            #move_tempfoldercontent_on_tools "${p_repo_id}/${p_artifact_index}" 0 "lsp_servers/omnisharp_ls" "-not -name '${p_artifact_filename_woext}.tar.gz'"
            ;;


        netcoredbg)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/netcoredbg"

            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "dap_servers/netcoredbg" 1 ""

                move_tempfoldercontent_on_tools "$l_source_path" 1 "dap_servers/netcoredbg" ""
                #move_tempfoldercontent_on_tools "$l_source_path" 1 "dap_servers/netcoredbg" "-not -name '${p_artifact_filename_woext}.zip'"
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "dap_servers/netcoredbg" 1 ""

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_tools "$l_source_path" 0 "dap_servers/netcoredbg" ""
            #move_tempfoldercontent_on_tools "$l_source_path" 0 "dap_servers/netcoredbg" "-not -name '${p_artifact_filename_woext}.tar.gz'"
            ;;



        clangd)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/clangd_${p_repo_last_version}"


            #A. Si es WSL de Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/clangd" 1 ""

                move_tempfoldercontent_on_tools "$l_source_path" 1 "lsp_servers/clangd" ""
                return 0

            fi

            #B. Si es Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/clangd" 1 ""

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_tools "$l_source_path" 0 "lsp_servers/clangd" ""
            ;;



        jdtls)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/jdtls" 1 ""

                move_tempfoldercontent_on_tools "$l_source_path" 1 "lsp_servers/jdtls" ""


                printf 'Descargando el archivo "%s" (para no mostrar errores cuando se usa sus anotaciones) en "%s"\n' "lombok.jar" \
                       "${g_win_tools_path}/lsp_servers/jdtls"
                curl -fLo "${g_win_tools_path}/lsp_servers/jdtls/lombok.jar" https://projectlombok.org/downloads/lombok.jar

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "eclipse_jdtls.info" "$p_repo_last_pretty_version" 1
                return 0

            fi


            #B. Si son binarios Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/jdtls" 1 ""

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_tools "$l_source_path" 0 "lsp_servers/jdtls" ""

            printf 'Descargando el archivo "%s" (para no mostrar errores cuando se usa sus anotaciones) en "%s"\n' "lombok.jar" \
                   "${g_tools_path}/lsp_servers/jdtls"
            curl -fLo "${g_tools_path}/lsp_servers/jdtls/lombok.jar" https://projectlombok.org/downloads/lombok.jar

            #Fix permisos
            if [ $g_runner_is_target_user -ne 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${g_tools_path}/lsp_servers/jdtls/lombok.jar"
            fi

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "eclipse_jdtls.info" "$p_repo_last_pretty_version" 0
            ;;



        luals)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "lsp_servers/luals" 2 ""

                #Descomprimir
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "lsp_servers/luals" "" ""
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0
            fi


            #B. Si son binarios Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "lsp_servers/luals" 2 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "lsp_servers/luals" "" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi
            ;;


        async-profiler)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then
                return 40
            fi


            #B. Si son binarios Linux
            if [ $p_artifact_index -eq 0 ]; then

                #Limpiarlo si existe
                clean_folder_on_tools 0 "" "async_profiler" 0 ""

                #Descomprimir
                uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "async_profiler" "$p_artifact_filename_woext"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

            elif [ $p_artifact_index -eq 1 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 0 "async_profiler/tools" 2 ""

                #Moviendo el contenido del folder source al folder de programa
                move_tempfoldercontent_on_tools "$l_source_path" 0 "async_profiler/tools" ""

            else

                #Moviendo el contenido del folder source al folder de programa
                move_tempfoldercontent_on_tools "$l_source_path" 0 "async_profiler/tools" ""

            fi
            ;;


        jbang)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "jbang" 2 ""

                #Descomprimir
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "jbang" "jbang-"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "jbang.info" "$p_repo_last_pretty_version" 1
                return 0
            fi


            #B. Si son binarios Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "jbang" 2 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "jbang" "jbang-"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "jbang.info" "$p_repo_last_pretty_version" 0
            ;;




        maven)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Determinar el prefijo del folder a renombrar (solo si existe una version ya instalada y hay cambio de version)
            #Se considera que en el cambio de version, la version sera la ultima estable (no hay upgrade para esta)
            l_target_path="maven_${p_repo_last_pretty_version%%.*}"


            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "" "$l_target_path" 0 ""

                #Descomprimir
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "$l_target_path" "apache-maven-"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                printf '%bValide que existe un enlace simbolo de "%s" a "%s" a en Windows%b.\n' \
                    "$g_color_yellow1" "./maven/"  "./${l_target_path}/" "$g_color_reset"

                #Debido no es practivo crear un enlace simbolo en Windows desde linux, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "maven.info" "${p_repo_current_pretty_version%%.*}" 1

                return 0
            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "" "$l_target_path" 0 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "$l_target_path" "apache-maven-"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Crear el enlace simbolico del la ultima version
            create_folderlink_on_tools "$l_target_path" "" "maven" ""

            ;;



        vscode-java)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "rh_java" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/rh_java"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "rh_java" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/rh_java"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;




        vscode-java-test)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "ms_java_test" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/ms_java_test"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "ms_java_test" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/ms_java_test"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;




        vscode-java-debug)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "ms_java_debug" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/ms_java_debug"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "ms_java_debug" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/ms_java_debug"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;



        vscode-maven)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "ms_java_maven" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/ms_java_maven"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "ms_java_maven" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/ms_java_maven"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;





        vscode-gradle)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "ms_java_gradle" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/ms_java_gradle"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "ms_java_gradle" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/ms_java_gradle"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;



        vscode-microprofile)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "m4_java_microprofile" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/m4_java_microprofile"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "m4_java_microprofile" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/m4_java_microprofile"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;






        vscode-quarkus)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "rh_java_quarkus" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/rh_java_quarkus"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "rh_java_quarkus" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/rh_java_quarkus"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;





        vscode-jdecompiler)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "dg_java_decompiler" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/dg_java_decompiler"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "dg_java_decompiler" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/dg_java_decompiler"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;




        vscode-springboot)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "vm_spring_boot" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/vm_spring_boot"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "vm_spring_boot" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/vm_spring_boot"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;






        codelldb)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "codelldb" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/codelldb"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "codelldb" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/codelldb"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;



        vscode-cpptools)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "ms_cpptools" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/ms_cpptools"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "ms_cpptools" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/ms_cpptools"

            #Estableciendo el permiso de ejecución del dap adapter
            printf 'Se establecera permiso de ejecucion del archivo "%b%s%b" de la carpeta "%b%s%b" ...\n' "$g_color_gray1" "OpenDebugAD7"  \
                   "$g_color_reset" "$g_color_gray1" "${g_tools_path}/vsc_extensions/ms_cpptools/debugAdapters/bin" "$g_color_reset"

            l_runner_is_program_owner=1
            if [ $(( g_tools_options & 1 )) -eq 1 ]; then
                l_runner_is_program_owner=0
            fi

            if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
                chmod +x "${g_tools_path}/vsc_extensions/ms_cpptools/debugAdapters/bin/OpenDebugAD7"
            else
                sudo chmod +x "${g_tools_path}/vsc_extensions/ms_cpptools/debugAdapters/bin/OpenDebugAD7"
            fi

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;



        vscode-go)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "go_tools" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/go_tools"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "go_tools" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/go_tools"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;



        vscode-pde)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "tf_eclipse_pde" 0 ""

                #Mover la extension en su carpeta
                move_tempfolder_on_tools "${l_source_path}" "extension" 1 "vsc_extensions/tf_eclipse_pde"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "tf_eclipse_pde" 0 ""

            #Mover la extension en su carpeta
            move_tempfolder_on_tools "${l_source_path}" "extension" 0 "vsc_extensions/tf_eclipse_pde"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;



        vscode-js-debug)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (si no existe la ruta base lo crea)
                clean_folder_on_tools 1 "vsc_extensions" "ms_js_debug" 0 ""

                #Descomprimir
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "vsc_extensions" "ms_js_debug" "js-debug"

                #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
                save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 1

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "vsc_extensions" "ms_js_debug" 0 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "vsc_extensions" "ms_js_debug" "js-debug"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "${p_repo_id}.info" "$p_repo_last_pretty_version" 0
            ;;



        roslyn-ls-lnx)

            #No se soportado para binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 0 "lsp_servers" "roslyn_ls" 0 ""

            #Mover la extension en su carpeta
            l_aux=''
            if [ $g_os_type -le 1 ]; then  #Si es Linux

                #Alpine Linux
                if [ $g_os_subtype_id -eq 1 ]; then
                    if [ $g_os_architecture_type = "x86_64" ]; then
                        l_aux='alpine-x64'
                    elif [ $g_os_architecture_type = "aarch64" ]; then
                        l_aux='alpine-arm64'
                    fi
                #Otra distribucion
                else
                    if [ $g_os_architecture_type = "x86_64" ]; then
                        l_aux='linux-x64'
                    elif [ $g_os_architecture_type = "aarch64" ]; then
                        l_aux='linux-arm64'
                    fi
                fi

            fi

            if [ -z "$l_aux" ]; then
                #No implementado para la plataforma actual
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" no define binarios para la plataforma actual %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "$g_os_architecture_type" "$g_color_reset"
                return 41
            fi

            move_tempfolder_on_tools "${l_source_path}" "content/LanguageServer/${l_aux}" 0 "lsp_servers/roslyn_ls"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "roslyn_ls.info" "$p_repo_last_pretty_version" 0
            ;;




        roslyn-ls-win)

            #No se soportado para binarios Linux
            if [ $p_is_win_binary -ne 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Windows" "$g_color_reset"
                return 40
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #Limpiando el folder si existe (si no existe la ruta base lo crea)
            clean_folder_on_tools 1 "lsp_servers" "roslyn_ls" 0 ""

            #Mover la extension en su carpeta
            l_aux=''
            if [ $g_os_type -eq 1 ]; then  #Si es Linux WSL2

                if [ $g_os_architecture_type = "x86_64" ]; then
                    l_aux='win-x64'
                elif [ $g_os_architecture_type = "aarch64" ]; then
                    l_aux='win-arm64'
                fi

            fi

            if [ -z "$l_aux" ]; then
                #No implementado para la plataforma actual
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" no define binarios para la plataforma actual %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "$g_os_architecture_type" "$g_color_reset"
                return 41
            fi

            move_tempfolder_on_tools "${l_source_path}" "content/LanguageServer/${l_aux}" 1 "lsp_servers/roslyn_ls"

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "roslyn_ls.info" "$p_repo_last_pretty_version" 1
            ;;



        cni-plugins)

            #No se soportado para binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi


            #1. Si la unidad servicio 'containerd' esta iniciado, solicitar su detención
            is_package_installed 'containerd' $g_os_subtype_id
            l_status=$?

            if [ $l_status -eq 0 ]; then
                printf 'El paquete "%b%s%b" ya %besta instalado%b en el sistema operativo.\n' "$g_color_yellow1" "containerd.io" "$g_color_reset" \
                       "$g_color_yellow1" "$g_color_reset"
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
            create_or_clean_folder_on_tools 0 "cni_plugins" 1 ""

            #Moviendo el contenido del folder source al folder de programa
            move_tempfoldercontent_on_tools "$l_source_path" 0 "cni_plugins" ""

            #Debido que no existe forma determinar la version actual, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "cni-plugins.info" "$p_repo_last_pretty_version" 0

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
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi

            #Ruta local de los artefactos
            #l_source_path="${p_repo_id}/${p_artifact_index}"
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "ctags/bin" 1 ""

            #Copiando los binarios
            copy_files_on_tools "${l_source_path}/bin" "ctags" 0 "ctags/bin" 1 1
            copy_files_on_tools "${l_source_path}/bin" "optscript" 0 "ctags/bin" 1 1
            copy_files_on_tools "${l_source_path}/bin" "readtags" 0 "ctags/bin" 1 1

            #Adicionar los archivos ayudas a la carpeta de ayuda del sistema
            copy_man_files "${g_temp_path}/${l_source_path}/man/man1" 1
            copy_man_files "${g_temp_path}/${l_source_path}/man/man5" 5
            copy_man_files "${g_temp_path}/${l_source_path}/man/man7" 7

            #Debido que no existe relacion entre la version actual y la version de github, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "ctags.info" "$p_repo_last_pretty_version" 0
            ;;


        ctags-win)

            #No se soportado por Windows
            if [ $p_is_win_binary -ne 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Windows" "$g_color_reset"
                return 40
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 1 "ctags/bin" 1 ""

            #Copiando los binarios
            copy_files_on_tools "${l_source_path}" "ctags.exe" 1 "ctags/bin" 1 1
            copy_files_on_tools "${l_source_path}" "readtags.exe" 1 "ctags/bin" 1 1

            #Mover folderes a la carpeta del programa
            move_tempfolder_on_tools "${l_source_path}" "man" 1 "ctags"
            move_tempfolder_on_tools "${l_source_path}" "docs" 1 "ctags"

            #Debido que no existe relacion entre la version actual y la version de github, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "ctags.info" "$p_repo_last_pretty_version" 1
            ;;




        powershell)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y limpiarlo si existe
                create_or_clean_folder_on_tools 1 "powershell" 2 ""

                #Descomprimir
                #TODO
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "powershell" "" ""
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0
            fi


            #B. Si son binarios Linux

            #Creando el folder si no existe y limpiarlo si existe
            create_or_clean_folder_on_tools 0 "powershell" 2 ""

            #Descomprimir
            #TODO
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "powershell" "" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Creando los enlaces simbolicos
            create_link_binary_file "powershell" "pwsh" "pwsh"
            ;;


        wezterm)

            #A. Si son binarios Linux
            if [ $p_is_win_binary -ne 0 ]; then
                return 0
            fi

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Eliminar el folder si existe
            clean_folder_on_tools 1 "" "wezterm" 1 ""

            #Descomprimir en un subfolder 'wezterm' durante la descromprension
            uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "wezterm" "WezTerm-windows-"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Debido que no existe relacion entre la version actual y la version de github, se almacenara la version github que se esta instalando
            save_prettyversion_on_tools "" "wezterm.info" "$p_repo_last_pretty_version" 1
            ;;



        neovim)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (crear la ruta base si no existe)
                clean_folder_on_tools 1 "" "neovim" 0 ""

                #Descomprimir
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "neovim" "$p_artifact_filename_woext"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0
            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (crear la ruta base si no existe)
            clean_folder_on_tools 0 "" "neovim" 0 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "neovim" "$p_artifact_filename_woext"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'nvim' esta en el PATH
            echo "$PATH" | grep "${g_tools_path}/neovim/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "NeoVIM"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/neovim/bin:$PATH\n' "${g_tools_path}"
                export PATH=${g_tools_path}/neovim/bin:$PATH
            fi

            ;;



        llvm)

            #No se soportado por Windows
            if [ $p_is_win_binary -eq 0 ]; then
                printf 'El %bartefacto[%b%s%b] "%b%s%b" del repositorio "%b%s%b" solo esta habilitado para configurar binarios %s%b.\n' \
                       "$g_color_red1" "$g_color_gray1" "$p_artifact_index" "$g_color_red1" "$g_color_gray1" "$p_artifact_filename" "$g_color_red1" \
                       "$g_color_gray1" "$p_repo_id" "$g_color_red1" "Linux" "$g_color_reset"
                return 40
            fi

            l_source_path="${p_repo_id}/${p_artifact_index}"

            #Limpiando el folder si existe (crear la ruta base si no existe)
            clean_folder_on_tools 0 "" "llvm" 0 ""

            #Descomprimir
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "llvm" "clang+llvm"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'LLVM' esta en el PATH
            echo "$PATH" | grep "${g_tools_path}/llvm/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "Go"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/llvm/bin:$PATH\n' "${g_tools_path}"
                export PATH=${g_tools_path}/llvm/bin:$PATH
            fi
            ;;


        net-sdk|net-rt-core|net-rt-aspnet)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Creando el folder si no existe y no limpiarlo si existe
                create_or_clean_folder_on_tools 1 "dotnet" 0 ""

                #Si se instala (no existe version anterior instalado del respositorio)
                if [ $p_flag_install -eq 0  ]; then

                    #Descomprimiendo el archivo sin eliminar el contenido existente
                    uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "dotnet" "" ""
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

            #Creando el folder si no existe y NO limpiarlo si existe
            create_or_clean_folder_on_tools 0 "dotnet" 0 ""

            #Si se instala (no existe version anterior instalado del respositorio)
            if [ $p_flag_install -eq 0  ]; then

                #Descomprimiendo el archivo
                uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "dotnet" "" ""
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
            echo "$PATH" | grep "${g_tools_path}/dotnet" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "DotNet"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/dotnet:$PATH\n' "${g_tools_path}"

                export DOTNET_ROOT=${g_tools_path}/dotnet
                PATH=${g_tools_path}/dotnet:$PATH
                if [ "$p_repo_id" = "net-sdk" ]; then
                    PATH=${g_tools_path}/dotnet/tools:$PATH
                fi
                export PATH
            fi
            ;;



        go)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (crear la ruta base si no existe)
                clean_folder_on_tools 1 "" "go" 0 ""

                #Descomprimiendo el archivo
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "" ""
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

            #Limpiando el folder si existe (crear la ruta base si no existe)
            clean_folder_on_tools 0 "" "go" 0 ""

            #Descomprimiendo el archivo
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "" ""
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'Go' esta en el PATH
            echo "$PATH" | grep "${g_tools_path}/go/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "Go"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/go/bin:$PATH\n' "${g_tools_path}"
                PATH=${g_tools_path}/go/bin:$PATH
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
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (crear la ruta base si no existe)
                clean_folder_on_tools 1 "" "nodejs" 0 ""

                #Descomprimiendo el archivo
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "nodejs" "${p_artifact_filename_woext}"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (crear la ruta base si no existe)
            clean_folder_on_tools 0 "" "nodejs" 0 ""

            #Descomprimiendo el archivo
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "nodejs" "${p_artifact_filename_woext}"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi


            #Validar si 'Node.JS' esta en el PATH
            echo "$PATH" | grep "${g_tools_path}/nodejs/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "Node.JS"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_tools_path}"
                export PATH=${g_tools_path}/nodejs/bin:$PATH
            fi
            ;;


        cmake)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"


            #A. Si son binarios Windows
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (crear la ruta base si no existe)
                clean_folder_on_tools 1 "" "cmake" 0 ""

                #Descomprimiendo el archivo
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "cmake" "${p_artifact_filename_woext}"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (crear la ruta base si no existe)
            clean_folder_on_tools 0 "" "cmake" 0 ""

            #Descomprimiendo el archivo
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "cmake" "${p_artifact_filename_woext}"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            #Validar si 'CMake' esta en el PATH
            echo "$PATH" | grep "${g_tools_path}/cmake/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                    "$g_color_yellow1" "CMake"  "$p_repo_last_pretty_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/cmake/bin:$PATH\n' "${g_tools_path}"
                export PATH=${g_tools_path}/cmake/bin:$PATH
            fi
            ;;



        graalvm)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}"

            #La version a instalar
            #Ejemplo del formato de la subversion 'jdk-24.0.1'
            local l_version="$p_arti_subversion_version"
            if [ -z "$l_version" ]; then
                l_version="$p_repo_last_version"
            fi

            #primer numero de la version a instalar
            l_aux=$(echo "$l_version" | sed -n 's/^jdk-\([0-9]*\)\..*/\1/p')
            l_target_path="graalvm_${l_aux}"

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
            if [ $p_is_win_binary -eq 0 ]; then

                #Limpiando el folder si existe (crear la ruta base si no existe)
                clean_folder_on_tools 1 "" "$l_target_path" 0 ""

                #Descomprimiendo el archivo
                uncompress_on_folder 1 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "$l_target_path" "graalvm-community-"
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    return 40
                fi

                if [ $p_arti_subversion_index -eq 0 ]; then

                    printf '%bValide que existe un enlace simbolo de "%s" a "%s" a en Windows%b.\n' \
                        "$g_color_yellow1" "./graalvm/"  "./${l_target_path}/" "$g_color_reset"

                    #Debido no es practivo crear un enlace simbolo en Windows desde linux, se almacenara la version github que se esta instalando
                    save_prettyversion_on_tools "" "graalvm.info" "$l_aux" 1
                fi

                return 0

            fi


            #B. Si son binarios Linux

            #Limpiando el folder si existe (crear la ruta base si no existe)
            clean_folder_on_tools 0 "" "$l_target_path" 0 ""

            #Descomprimiendo el archivo
            uncompress_on_folder 0 "$l_source_path" "$p_artifact_filename" $((p_artifact_type - 20)) "" "$l_target_path" "graalvm-community-"
            l_status=$?
            if [ $l_status -ne 0 ]; then
                return 40
            fi

            if [ $p_arti_subversion_index -eq 0 ]; then

                #Crear el enlace simbolico del la ultima version
                create_folderlink_on_tools "$l_target_path" "" "graalvm" ""

                #Validar si 'GraalVM' esta en el PATH
                echo "$PATH" | grep "${g_tools_path}/graalvm/bin" &> /dev/null
                l_status=$?
                if [ $l_status -ne 0 ]; then
                    printf '%b%s %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                        "$g_color_yellow1" "GraalVM"  "$p_repo_last_pretty_version" "$g_color_reset"
                    #printf 'Adicionando a la sesion actual: PATH=%s/graalvm/bin:$PATH\n' "${g_tools_path}"
                    #export PATH=${g_tools_path}/graalvm/bin:$PATH
                    #GRAALVM_HOME=${g_tools_path}/graalvm
                    #JAVA_HOME=${GRAALVM_HOME}
                    #export GRAALVM_HOME JAVA_HOME
                fi

            fi
            ;;


        uv)

            #Ruta local de los artefactos
            l_source_path="${p_repo_id}/${p_artifact_index}/${p_artifact_filename_woext}"

            if [ $p_is_win_binary -ne 0 ]; then

                #Copiar el comando y dar permiso de ejecucion a todos los usuarios
                copy_binary_file "${l_source_path}" "uv" 0 1
                copy_binary_file "${l_source_path}" "uvx" 0 1

            else

                #Copiar el comando
                copy_binary_file "${l_source_path}" "uv.exe" 1 1
                copy_binary_file "${l_source_path}" "uvx.exe" 1 1

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
#  1 > Index (inicia en 0) de la opcion de menu elegista para instalar (ver el arreglo 'ga_menuoption_title').
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
    #local l_option_name="${ga_menuoption_title[${p_option_idx}]}"
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
#  1 > Index de la opcion de menu elegista para instalar (ver el arreglo 'ga_menuoption_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
install_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menuoption_title[${p_option_idx}]}"
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
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menuoption_title').
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
    #local l_option_name="${ga_menuoption_title[${p_option_idx}]}"
    #local l_option_value=$((1 << p_option_idx))

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 3 ] || [ $gp_type_calling -eq 4 ]; then
        l_is_noninteractive=0
    fi

    #3. Preguntar antes de eliminar los archivos
    printf 'Se va ha iniciar con la desinstalación de los siguientes repositorios: '

    #Obtener los repositorios a configurar
    local l_aux="${ga_menuoption_repos[$l_i]}"
    local IFS=','
    local la_repos=(${l_aux})
    IFS=$' \t\n'

    local l_n=${#la_repos[@]}
    local l_repo_names=''
    local l_repo_id
    for((l_j=0; l_j < ${l_n}; l_j++)); do

        l_repo_id="${la_repos[${l_j}]}"
        l_aux="${gA_repos_artifact[${l_repo_id}]}"
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
        printf "%b¿Desea continuar con la desinstalación de estos repositorios?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
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
#  1 > Index de la opcion de menu elegista para desinstalar (ver el arreglo 'ga_menuoption_title').
#
#El valor de retorno puede ser:
#  0 > Si finalizo con exito.
#  1 > No se finalizo por opcion del usuario.
#  2 > Hubo un error en la finalización.
#
uninstall_finalize_menu_option() {

    #Argumentos
    local p_option_relative_idx=$1

    #local l_option_name="${ga_menuoption_title[${p_option_idx}]}"
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
    local p_is_win_binary=1
    if [ "$3" = "0" ]; then
        p_is_win_binary=0
    fi

    #2. Inicialización de variables
    local l_repo_name="${gA_repos_artifact[$p_repo_id]}"
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
    local p_is_win_binary=1
    if [ "$3" = "0" ]; then
        p_is_win_binary=0
    fi

    #2. Inicialización de variables
    local l_repo_name="${gA_repos_artifact[$p_repo_id]}"
    if [ "$l_repo_name" = "$g_empty_str" ]; then
        l_repo_name=''
    fi

    #local l_repo_name_aux="${l_repo_name:-$p_repo_id}"

    local l_source_path=""
    local l_target_path=""
    if [ $p_is_win_binary -ne 0 ]; then
        l_target_path="$g_lnx_bin_path"
    else
        l_target_path="$g_win_bin_path"
    fi

    local l_status
    local l_flag_uninstall
    local l_aux

    case "$p_repo_id" in


        runc)

            #1. Ruta local de los artefactos
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            l_target_path="${g_tools_path}/cni_plugins"

            if [ $p_is_win_binary -eq 0 ]; then
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
            rm "${g_tools_path}/cni-plugins.info"
            ;;


        containerd)

            #1. Ruta local de los artefactos
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
            if [ $p_is_win_binary -eq 0 ]; then
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
