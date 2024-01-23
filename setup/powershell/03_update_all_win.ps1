$g_max_length_line= 130

$g_is_nodejs_installed= $true

#La version 'x.y.z' esta la inicio o despues de caracteres no numericos
$g_regexp_sust_version1='[^0-9]*([0-9]+.[0-9.]+).*'
#La version 'x.y.z' o 'x-y-z' esta la inicio o despues de caracteres no numericos
$g_regexp_sust_version2='[^0-9]*([0-9]+.[0-9.-]+).*'
#La version '.y.z' esta la inicio o despues de caracteres no numericos
$g_regexp_sust_version3='[^0-9]*([0-9.]+).*'
#La version 'xyz' (solo un entero sin puntos)  esta la inicio o despues de caracteres no numericos
$g_regexp_sust_version4='[^0-9]*([0-9]+).*'
#La version 'x.y.z' esta despues de un caracter vacio
$g_regexp_sust_version5='.*\s+([0-9]+.[0-9.]+).*'

#Parametros de salida (SDTOUT): Version de NodeJS instalado
#Parametros de salida (valores de retorno):
# 0 > Se obtuvo la version
# 1 > No se obtuvo la version
function m_get_nodejs_version() {

    $l_version= node --version 2> $null
    $l_status=$?
    if ($l_status) {
        #$l_version= $l_version[0]
        $l_version= $l_version -creplace "$g_regexp_sust_version1", '$1'
    }
    else {
        $l_version=""
    }

    return "$l_version"
}


#Parametros de salida (valores de retorno):
#  0 > Si es esta configurado en modo editor
#  1 > Si es esta configurado en modo developer
#  2 > Si NO esta configurado
function m_is_developer_vim_profile($p_is_neovim) {

    #1. Argumentos

    #2. Ruta base donde se instala el plugins/paquete
    $l_real_path
    $l_profile_path="${env:USERPROFILE}\.vimrc"
    if ($p_is_neovim) {
        $l_profile_path="${env:LOCALAPPDATA}\nvim\init.vim"
    }

    #'vimrc_ide_linux_xxxx.vim'
    #'vimrc_basic_linux.vim'
    #'init_ide_linux_xxxx.vim'
    #'init_basic_linux.vim'
	if(! (Test-Path "$l_profile_path")) {
		return 2
	}
	
	$l_info= Get-Item "$l_profile_path" | Select-Object LinkType, LinkTarget
    if ( $l_info.LinkType -ne "SymbolicLink" ) {
        return 2
    }

    $l_real_filename = Split-Path $l_info.LinkTarget -Leaf

    #Si es NeoVIM
    if ($p_is_neovim) {
        if ($l_real_filename -match '^init_ide_.*$') {
            return 1 
        }
        return 0
    }

    #Si es VIM
    if ($l_real_filename -match '^vimrc_ide_.*$') {
        return 1 
    }
    return 0

}


function m_update_repository($p_path, $p_repo_name, $p_is_neovim) 
{
    if(!(Test-Path $p_path)) {
        Write-Host "Folder `"${p_path}`" not exists"
        return 9
    }

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
	if(${p_is_neovim})
	{		
		Write-Host "- Repository Git para NeoVIM: `"${p_repo_name}`" " -NoNewline
		Write-Host "(`"${p_path}`")" -ForegroundColor DarkGray
	}
	else
	{
		Write-Host "- Repository Git para    VIM: `"${p_repo_name}`" " -NoNewline
		Write-Host "(`"${p_path}`")" -ForegroundColor DarkGray
	}
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

    cd $p_path
    
    #2. Validar si el directorio .git del repositorio es valido 
    git rev-parse --git-dir > $null 2>&1
    if (! $?)
    {
        #Si no es un repositorio valido salir
        Write-Host 'Invalid git repository'
        return 8
    }

    $l_local_branch="$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)"
    $l_remote="$(git config branch.${l_local_branch}.remote)"
    $l_remote_branch="$(git rev-parse --abbrev-ref --symbolic-full-name `@`{u`})"

    #3. Actualizando la rama remota del repositorio local desde el repositorio remoto
    Write-Host "> Fetching from remote repository `"${l_remote}`" to remote branch `"${l_remote_branch}`"..."
    git fetch $l_remote
	if (! $?) {
		Write-Host "Error ($?) on Fetching from remote repository `"${l_remote}`" to remote branch `"${l_remote_branch}`""
		return 3
	}

    #4. Si la rama local es igual a la rama remota
    Write-Host "> Updating local branch `"${l_local_branch}`" from remote branch `"${l_remote_branch}`"..."
    git merge-base --is-ancestor ${l_remote_branch} HEAD
    if ($?) {
        Write-Host '> Already up-to-date'
        return 0
    }
	
    #5. Si la rama local es diferente al rama remota

    #¿Es posible realizar 'merging'?
	git merge-base --is-ancestor HEAD ${l_remote_branch}
	if ($?) {
		Write-Host '> Fast-forward possible. Merging...'
		git merge --ff-only --stat ${l_remote_branch}
		
		if (! $?) {
			Write-Host "Error ($?) on Merging from remote repository `"${l_remote}`" to remote branch `"${l_remote_branch}`""
			return 4
		}
		return 1
	}
	
	Write-Host '> Fast-forward not possible. Rebasing...'
	git rebase --preserve-merges --stat ${l_remote_branch}
    #git rebase --rebase-merges --stat ${l_remote_branch}
    #git rebase --stat ${l_remote_branch}
	
	if (! $?) {
		Write-Host "Error ($?) on Rebasing from remote repository `"${l_remote}`" to remote branch `"${l_remote_branch}`""
		return 5
	}
	
	return 2	

}

function m_update_vim_repository($p_is_neovim, $p_is_coc_installed)
{

	$l_show_title= $false
	$l_tag= ""
	$l_path_plugins= ""
	if(${p_is_neovim})
	{
		$l_tag= "NeoVIM"
		$l_path_plugins= "${env:LOCALAPPDATA}\nvim-data\site\pack\"
	}
	else
	{
		$l_tag= "VIM"
		$l_path_plugins= "${env:USERPROFILE}\vimfiles\pack\"
	}
	
    #3. Buscar los repositorios git existentes en la carpeta plugin y actualizarlos	
	$l_status=0
	$la_doc_paths= New-Object System.Collections.Generic.List[System.String]
	$la_doc_repos= New-Object System.Collections.Generic.List[System.String]
	$l_repo_path= ""
	$l_repo_name= ""
	$folders = Get-ChildItem "$l_path_plugins" -Attributes Directory+Hidden -ErrorAction SilentlyContinue -Filter ".git" -Recurse | Select-Object "FullName"	
    foreach ( $folder in $folders ) {
		
		if(!${l_show_title}) 
		{
			#Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor DarkGray
			#Write-Host "                                                    ${l_tag}" -ForegroundColor DarkGray
			#Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor DarkGray
			$l_show_title= $true
		}

        Write-Host ""
        $l_repo_path = Split-Path -Parent $folder.FullName
		$l_repo_name = Split-Path "$l_repo_path" -Leaf
        $l_status= m_update_repository $l_repo_path $l_repo_name $p_is_neovim
		if(($l_status -eq 1) || ($l_status -eq 2))
		{
			if(Test-Path "${l_repo_path}/doc") {
				$la_doc_paths.Add("${l_repo_path}/doc")
				$la_doc_repos.Add("${l_repo_name}")
			}
		}
    }
	

    #4. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
	$l_n= $la_doc_paths.Count
	if( $l_n -gt 0 )
	{
		Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
		if(${p_is_neovim})
		{		
			Write-Host "- NeoVIM> Indexando la documentación de los plugin"
		}
		else
		{
			Write-Host "-    VIM> Indexando la documentación de los plugin"
		}
		Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
		
		$l_j= 0
		for ($i=0; $i -lt $l_n; $i++) {
			$l_repo_path= $la_doc_paths[$i]
			$l_repo_name= $la_doc_repos[$i]
			$l_j= $i + 1
			Write-Host "(${l_j}/${l_n}) Indexando la documentación del plugin `"${l_repo_name}`" en `"${l_tag}`": `"helptags ${l_repo_path}`"\n"
			if(${p_is_neovim})
			{
                nvim --headless -c "helptags ${l_repo_path}" -c qa
			}
			else
			{
                vim -u NONE -esc "helptags ${l_repo_path}" -c qa
			}

			
		}
	}
	
    Write-Host ""
    #6. Inicializar los paquetes/plugin de VIM/NeoVIM que lo requieren.
    if (!$p_is_coc_installed) {
        Write-Host "Se ha instalando los plugin/paquetes de ${l_tag} como Editor."
        return 0
    }

    Write-Host ""
    Write-Host "Se ha instalando los plugin/paquetes de ${l_tag} como Developer."
    if (!$g_is_nodejs_installed)  {

        Write-Host "Recomendaciones:"
        Write-Host "    > Si desea usar como editor (no cargar plugins de IDE), use: `"USE_EDITOR=1 vim`""
        if ($p_is_neovim -eq 0) {
            Write-Host "    > NeoVIM como developer por defecto usa el adaptador LSP y autocompletado nativo. No esta habilitado el uso de CoC"
        }
		else {
            Write-Host "    > VIM esta como developer pero NO puede usar CoC  (requiere que NodeJS este instalando)"
        }
        return 0

	}
        
    Write-Host "Los plugins del IDE CoC de ${l_tag} tiene componentes que requieren inicialización para su uso. Inicializando dichas componentes del plugins..."	

    #Instalando los parseadores de lenguaje de 'nvim-treesitter'
    if ($p_is_neovim) {

        #Requiere un compilador C/C++ y NodeJS: https://tree-sitter.github.io/tree-sitter/creating-parsers#installation
		#TODO Obtener la version del compilador C/C++
        $l_version="xxxx"
        if(! $l_version ) {
            Write-Host "  Instalando `"language parsers`" de TreeSitter `":TSInstall html css javascript jq json yaml xml toml typescript proto make sql bash`""
            nvim --headless -c  "TSInstall html css javascript jq json yaml xml toml typescript proto make sql bash" -c "qa"

            Write-Host "  Instalando `"language parsers`" de TreeSitter `":TSInstall java kotlin llvm lua rust swift c cpp go c_sharp`""
            nvim --headless -c "TSInstall java kotlin llvm lua rust swift c cpp go c_sharp" -c "qa"
        }
	}

    #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
    Write-Host "  Instalando extensiones de CoC (Adaptador de LSP server basicos) `":CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh`""
    if ($p_is_neovim) {       
		${env:USE_COC}=1
		nvim --headless -c "CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh" -c "qa"
	}
    else {
        vim -esc "CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh" -c "qa"
    }

    #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
    Write-Host "  Instalando extensiones de CoC (Motor de snippets `"UtilSnips`") `":CocInstall coc-ultisnips`" (no se esta usando el nativo de CoC)"
    if ($p_is_neovim) {        
		nvim --headless -c "CocInstall coc-ultisnips" -c "qa"
	}
    else {
        vim -esc "CocInstall coc-ultisnips" -c "qa"
    }

    #Actualizar las extensiones de CoC
    Write-Host "  Actualizando los extensiones existentes de CoC, ejecutando el comando `":CocUpdate`""
    if ($p_is_neovim) {
        nvim --headless -c "CocUpdate" -c "qa"
		${env:USE_COC}=0
	}
    else {        
		vim -esc "CocUpdate" -c "qa"
    }

    #Actualizando los gadgets de 'VimSpector'
    if (!$p_is_neovim) {
        Write-Host "  Actualizando los gadgets de `"VimSpector`", ejecutando el comando `":VimspectorUpdate`""
        vim -esc "VimspectorUpdate" -c "qa"
    }
	
	Write-Host ""
    Write-Host "Recomendaciones:"
    if (!$p_is_neovim) {

        Write-Host "    > Si desea usar como editor (no cargar plugins de IDE), use: `"`${env:USE_EDITOR}=1`" y luego `"vim`""
        Write-Host "    > Se recomienda que configure su IDE CoC segun su necesidad:"
	}
    else {

        Write-Host "  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM."
        Write-Host "    > Si desea usar CoC, use: `"`${env:USE_COC}=1`" y luego `"nvim`""
        Write-Host "    > Si desea usar como editor (no cargar plugins de IDE), use: `"`${env:USE_EDITOR}=1`" y luego `"nvim`""

        Write-Host "  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:"

    }

    Write-Host "        1> Instalar extensiones de COC segun su necesidad (Listar existentes `":CocList extensions`")"
    Write-Host "        2> Revisar la Configuracion de COC `":CocConfig`":"
    Write-Host "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
    Write-Host "               { `"diagnostic.displayByAle`": true }"
    Write-Host "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
    Write-Host "               Si esta instalando esta extension, desintalarlo."


    return 0

    #~\vimfiles\pack\ui\opt\fzf.vim
    #Restaurar el archivo 
    #comprar con lo que se tiene en y actualizar el repo 

}

function m_main_update($p_input_options) {


    #Obtener la version de NodeJS
    $l_nodejs_version= m_get_nodejs_version

    #4. Actualizar paquetes VIM instalados
    $l_version
    $l_aux=""
    $l_is_coc_installed=1

    $l_opcion=4
    $l_flag= $l_opcion

    if ($l_flag -eq $l_opcion) {

        #Obtener la version actual de VIM
        $l_version= vim --version 2> $null
        $l_status=$?
        if ($l_status) {
            $l_version= $l_version[0]
            #Write-Host "VIM Version: ${l_version}"
            $l_version= $l_version -creplace "$g_regexp_sust_version1", '$1'
        }
        else {
            $l_version=""
        }

        #Write-Host "VIM Version: ${l_version}"

        #Solo actualizar si esta instalado
        if ($l_version) {

            #Mostrar el titulo
            $l_title= ">> Actualizar los paquetes de VIM (${l_version})"

            Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
            Write-Host "$l_title" -ForegroundColor Blue
            Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue

            #Determinar si esta instalado en modo developer
            $l_is_coc_installed= $false
            $l_status= m_is_developer_vim_profile $false
            if ($l_status -eq 1) {
                if ($l_nodejs_version) {
                    Write-Host "Se actualizará los paquetes/plugins de VIM ${l_version} (Modo developer, NodeJS `"${l_nodejs_version}`") ..."
                    $l_is_coc_installed= $true
                }
                else {
                    Write-Host "Se actualizará los paquetes/plugins de VIM ${l_version} (Modo developer, NodeJS no intalado) ..."
                }
            }
            else {
                Write-Host "Se actualizará los paquetes/plugins de VIM ${l_version} ..."
            }
            #Write-Host ""

            #Actualizar los plugins
            m_update_vim_repository $false $l_is_coc_installed
       }

    }

    #5. Actualizar paquetes NeoVIM instalados
    $l_opcion=8
    $l_flag= $l_opcion

    if ($l_flag -eq $l_opcion) {

        #Obtener la version actual de VIM
        $l_version= nvim --version 2> $null
        $l_status=$?
        if ($l_status) {
            $l_version= $l_version[0]
            #Write-Host "NeoVIM Version: ${l_version}"
            $l_version= $l_version -creplace "$g_regexp_sust_version1", '$1'
        }
        else {
            $l_version=""
        }

        #Write-Host "NeoVIM Version: ${l_version}"

        #Solo actualizar si esta instalado
        if ($l_version) {

            Write-Host ""
            Write-Host ""

            #Mostrar el titulo
            $l_title= ">> Actualizar los paquetes de NeoVIM (${l_version})"
            Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
            Write-Host "$l_title" -ForegroundColor Blue
            Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue

            #Determinar si esta instalado en modo developer
            $l_is_coc_installed= $false
            $l_status= m_is_developer_vim_profile $true
            if ($l_status -eq 1) {
                if ($l_nodejs_version) {
                    Write-Host "Se actualizará los paquetes/plugins de NeoVIM ${l_version} (Modo developer, NodeJS `"${l_nodejs_version}`") ..."
                    $l_is_coc_installed= $true
                }
                else {
                    Write-Host "Se actualizará los paquetes/plugins de NeoVIM ${l_version} (Modo developer, NodeJS no intalado) ..."
                }
            }
            else {
                Write-Host "Se actualizará los paquetes/plugins de NeoVIM ${l_version} ..."
            }
            #Write-Host ""

            #Actualizar los plugins
            m_update_vim_repository $true $l_is_coc_installed
       }

    }


}

function m_rollback_changes_plugins_fzf() 
{
	Write-Host ""
	
	Write-Host ""
    Write-Host ">   VIM> Restaurando las modificaciones realizada al plugin 'fzf': " -NoNewline	
	Write-Host "${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf" -ForegroundColor DarkGray -NoNewline
	Write-Host "\plugin\fzf.vim" -ForegroundColor Blue
    cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf
	Write-Host "git pull origin master" -ForegroundColor DarkGray
    git pull origin master
	Write-Host "git restore autoload\fzf\vim.vim" -ForegroundColor DarkGray
    git restore plugin\fzf.vim

	Write-Host ""
	Write-Host ">   VIM> Restaurando las modificaciones realizada al plugin 'fzf.vim': " -NoNewline	
	Write-Host "${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim" -ForegroundColor DarkGray -NoNewline
	Write-Host "\autoload\fzf\vim.vim" -ForegroundColor Blue
    cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim
	Write-Host "git pull origin master" -ForegroundColor DarkGray
    git pull origin master
	Write-Host "git restore autoload\fzf\vim.vim" -ForegroundColor DarkGray
    git restore autoload\fzf\vim.vim
		
	Write-Host ""
    Write-Host ">NeoVIM> Restaurando las modificaciones realizada al plugin 'fzf': " -NoNewline	
	Write-Host "${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf" -ForegroundColor DarkGray -NoNewline
	Write-Host "\plugin\fzf.vim" -ForegroundColor Blue
    cd ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf
	Write-Host "git pull origin master" -ForegroundColor DarkGray
    git pull origin master
	Write-Host "git restore autoload\fzf\vim.vim" -ForegroundColor DarkGray
    git restore plugin\fzf.vim

	Write-Host ""
	Write-Host ">NeoVIM> Restaurando las modificaciones realizada al plugin 'fzf.vim': " -NoNewline	
	Write-Host "${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim" -ForegroundColor DarkGray -NoNewline
	Write-Host "\autoload\fzf\vim.vim" -ForegroundColor Blue
    cd ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim
	Write-Host "git pull origin master" -ForegroundColor DarkGray
    git pull origin master
	Write-Host "git restore autoload\fzf\vim.vim" -ForegroundColor DarkGray
    git restore autoload\fzf\vim.vim
	
	Write-Host ""
	Write-Host ""
    Write-Host "Intrucciones siguientes para corregir FZF:"
	
	Write-Host ""
    Write-Host "1> Buscar hay cambios que obligen a corregir las fuentes" -ForegroundColor Green
	Write-Host "   Comparando la ultima version (plugin de VIM) vs la fuente (${env:USERPROFILE}\.files\vim\packages\fixes\)" -ForegroundColor DarkGray
	Write-Host "   No cambie la lineas comentado con el comentario `"CHANGE ..." -ForegroundColor DarkGray
	Write-Host "   > Inicie la comparacion de '.\fzf\plugin\fzf.vim':" -ForegroundColor DarkGray
	Write-Host "     vim -d `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\fzf.vim `${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim"    
	Write-Host "     - Use 'diffput' para subir cambios a la fuente." -ForegroundColor DarkGray
	Write-Host "     - Use '[c' y ']c' para navegar en las diferencias de un split." -ForegroundColor DarkGray
	Write-Host "     - Use 'windo diffoff' para ingresar al modo normal." -ForegroundColor DarkGray
	Write-Host "     - Use 'CTRL + l' y 'CTRL + h' para navegar en entre los split (si lo requiere)" -ForegroundColor DarkGray
	Write-Host "     - Guarde los cambios con ':w'." -ForegroundColor DarkGray
	Write-Host "   > Cierre e de la misma forma, inicie la comparacion de '.\fzf.vim\autoload\fzf\vim.vim':" -ForegroundColor DarkGray
	Write-Host "     vim -d `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim"
	
    
    Write-Host ""
    Write-Host "2> Si la fuente tiene cambios (fue corregido), copie y remplaze los archivos desde la fuente (corregido) a los plugins" -ForegroundColor Green
	Write-Host "   > Reparando VIM:" -ForegroundColor DarkGray
    Write-Host "     cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\"
    Write-Host "     cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\"
	Write-Host "     cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1 `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\bin\"
	Write-Host "   > Reparando NeoVIM:" -ForegroundColor DarkGray
	Write-Host "     cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf\plugin\"
    Write-Host "     cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\autoload\fzf\"
	Write-Host "     cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1 `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\bin\"
	
	Write-Host ""
    Write-Host "3> Opcional: subir los cambios de la fuentes corregida al repositorio remoto" -ForegroundColor Green
	Write-Host "   cd `${env:USERPROFILE}\.files"
	Write-Host "   git add vim\packages\fixes\fzf\plugin\fzf.vim"
	Write-Host "   git add vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim"
	Write-Host "   git push origin main"
	Write-Host ""
    
	cd ${env:USERPROFILE}
}


function m_changes_plugins_fzf() 
{
	Write-Host ""
	Write-Host "Copiando los archivos de la fuente corregida " -ForegroundColor Blue -NoNewline
	Write-Host "(${env:USERPROFILE}\.files\vim\packages\fixes\)" -ForegroundColor DarkGray -NoNewline
	Write-Host " a los plugins 'fzf' y 'fzf.vim'..." -ForegroundColor Blue
	
	Write-Host ""
    Write-Host ">   VIM> Copiando los archivos de la fuente corregida al plugin 'fzf' y 'fzf.vim': "
    Write-Host "cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\" -ForegroundColor DarkGray
    cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\
    Write-Host "cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\" -ForegroundColor DarkGray
    cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\
	Write-Host "cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1 `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\bin\" -ForegroundColor DarkGray
	cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1 ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\bin\

	Write-Host ""
    Write-Host ">NeoVIM> Copiando los archivos de la fuente corregida al plugin 'fzf' y 'fzf.vim': "
	Write-Host "cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf\plugin\" -ForegroundColor DarkGray
	cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf\plugin\fzf.vim ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf\plugin\
    Write-Host "cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\autoload\fzf\" -ForegroundColor DarkGray
    cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\autoload\fzf\
	Write-Host "cp `${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1 `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\bin\" -ForegroundColor DarkGray
	cp ${env:USERPROFILE}\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1 ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\bin\

	Write-Host ""
	Write-Host ""
    Write-Host "Intrucciones siguientes:"
	
	
	Write-Host ""
    Write-Host "1> Opcional: subir los cambios de la fuentes corregida al repositorio remoto" -ForegroundColor Green
	Write-Host "   cd `${env:USERPROFILE}\.files"
	Write-Host "   git add vim\packages\fixes\fzf\plugin\fzf.vim"
	Write-Host "   git add vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim"
	Write-Host "   git push origin main"
	Write-Host ""
    
	cd ${env:USERPROFILE}
}



function m_setup($p_input_options)
{
	if($p_input_options -eq 2) {
		
		m_rollback_changes_plugins_fzf
		return
	}
	
	if($p_input_options -eq 3) {
		
		m_changes_plugins_fzf
		return
	}

    $l_status= m_main_update $p_input_options
}


function m_show_menu_core() 
{
	Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu"
	Write-Host " (a) Actualizar los plugins VIM/NeoVIM"
	Write-Host " (b) Rollback las modificaciones realizadas de los plugins 'fzf' y 'fzf.vim'"
	Write-Host " (c) Cambiar los plugins 'fzf' y 'fzf.vim' usando la fuente corregida"	
	Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
}

function show_menu() 
{
	Write-Host ""
	m_show_menu_core
	
	$l_continue= $true
	$l_read_option= ""
	while($l_continue)
	{
			Write-Host "Ingrese la opción (" -NoNewline
			Write-Host "no ingrese los ceros a la izquierda" -NoNewline -ForegroundColor DarkGray
			$l_read_option= Read-Host ")"
			switch ($l_read_option)
			{
				'a' {
					$l_continue= $false
					Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
					Write-Host ""
					m_setup 1
				}
				
				'b' {
					$l_continue= $false
					Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
					Write-Host ""
					m_setup 2
				}
				
				'c' {
					$l_continue= $false
					Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
					Write-Host ""
					m_setup 3
				}
				
				'q' {
					$l_continue= $false
					Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
					Write-Host ""
				}
				
				default {
					$l_continue= $true
					Write-Host "opción incorrecta"
					Write-Host "----------------------------------------------------------------------------------------------------------------------------------"	 -ForegroundColor DarkGray
				}
				
			}	
		
	}
	
	
}
	

$g_fix_fzf=0
if($args.count -ge 1) {
    if($args[0] -eq "1") {
        $g_fix_fzf=1
    }
}

show_menu

