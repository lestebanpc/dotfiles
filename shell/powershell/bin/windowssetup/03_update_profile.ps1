#------------------------------------------------------------------------------------------------
# Inicializacion
#------------------------------------------------------------------------------------------------

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


# Repositorios Git que tiene submodulos y requieren obtener/actualizar en conjunto al modulo principal
# > Por defecto no se tiene submodulos (valor 0)
# > Valores :
#   (0) El repositorio solo tiene un modulo principal y no tiene submodulos.
#   (1) El repositorio tiene un modulo principal y submodulos de 1er nivel.
#   (2) El repositorio tiene un modulo principal y submodulos de varios niveles.
$gd_repos_with_submmodules= @{
        'kulala.nvim' = 1
    }


# Importando funciones de utilidad
. "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/lib/setup_profile_utility.ps1"



#------------------------------------------------------------------------------------------------
# Funciones
#------------------------------------------------------------------------------------------------

#Parametros de salida (SDTOUT): Version de NodeJS instalado
#Parametros de salida (valores de retorno):
# 0 > Se obtuvo la version
# 1 > No se obtuvo la version
function m_get_nodejs_version() {

    $l_version=$(node --version 2> $null)
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


    #2. Mostrar el titulo
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
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
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray

    # Validar si el directorio .git del repositorio es valido
    Set-Location "$p_path"

    git rev-parse --git-dir > $null 2>&1
    if (! $?)
    {
        # Si no es un repositorio valido salir
        Write-Host 'Invalid git repository'
        return 8
    }


    #3. Obtener datos del repositorio actual

    # Ejemplo : 'main'
    $l_local_branch="$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)"
    if ($l_local_branch -eq "HEAD") {
        Write-Host "Invalid current branch name of repository `"${p_repo_name}`""
        return 6
    }

    # Ejemplo : 'origin'
    $l_remote="$(git config branch.${l_local_branch}.remote)"

    # Ejemplo : 'origin/main'
    $l_remote_branch="$(git rev-parse --abbrev-ref --symbolic-full-name `@`{u`})"

    # El repositorio tiene submodulos git
    $l_submodules_types= $gd_repos_with_submmodules[$p_repo_name]

    #4. Actualizando la rama remota del repositorio local desde el repositorio remoto
    Write-Host "> Fetching from remote repository `"${l_remote}`" to remote branch `"${l_remote_branch}`" (git fetch --depth=1 ${l_remote} ${l_local_branch})..."
    git fetch --depth=1 ${l_remote} ${l_local_branch}
	if (-not $?) {
		Write-Host "Error ($?) on Fetching from remote repository `"${l_remote}`" to remote branch `"${l_remote_branch}`""
		return 3
	}


    #5. Verificar si esta actualizado las ramas local y la de sigimiento
    $l_hash_head="$(git rev-parse HEAD)"
    $l_hash_remote="$(git rev-parse FETCH_HEAD)"

    if ($l_hash_head -eq $l_hash_remote) {

        # Si tiene submodulos, actualizar los submoduos
        if ($l_submodules_types -eq 1 -or $l_submodules_types -eq 2) {

            Write-Host 'Main module is already up-to-date.'

            # Actualizar los submodulos definidos en '.gitmodules' y lo hace de manera superficial

            if ($l_submodules_types -eq 1) {
                Write-Host "> Updating submodules of repository `"${p_repo_name}`" (git submodule update --remote --depth 1 --force)..."
                git submodule update --remote --depth 1 --force
            }
            else {
                Write-Host "> Updating submodules of repository `"${p_repo_name}`" (git submodule update --remote --recursive --depth 1 --force)..."
                git submodule update --remote --recursive --depth 1 --force
            }

            if (-not $?) {
                Write-Host "Error ($?) on Updating submodules of repository `"${p_repo_name}`""
                return 3
            }

            Write-Host '> Submodules updated successfully.'
            return 0

        }

        # Si no tiene submodulos
        Write-Host '> Already up-to-date'
        return 0
    }


    #6. Si la rama local es diferente al rama remota

    # Del modulo principal, realizar una actualizacion destructiva y para quedar solo con el ultimo nodo de la rama remota
    write-host "> Updating local branch `"${l_remote_branch}`" from remote branch `"${l_remote}`" (git reset --hard ${l_remote_branch})..."

    git reset --hard ${l_remote_branch}

    if (-not $?) {
        Write-Host "Error ($?) on Updating local branch `"${l_remote_branch}`" from remote branch `"${l_remote}`""
        return 3
    }

    # Si tiene submodulos, actualizarlo
    if ($l_submodules_types -eq 1 -or $l_submodules_types -eq 2) {

        Write-Host '> Main module updated successfully.'

        # Actualizar los submodulos definidos en '.gitmodules' y lo hace de manera superficial
        if ($l_submodules_types -eq 1) {
            Write-Host "> Updating submodules of repository `"${p_repo_name}`" (git submodule update --remote --depth 1 --force)..."
            git submodule update --remote --depth 1 --force
        }
        else {
            Write-Host "> Updating submodules of repository `"${p_repo_name}`" (git submodule update --remote --recursive --depth 1 --force)..."
            git submodule update --remote --recursive --depth 1 --force
        }

        if (-not $?) {
            Write-Host "Error ($?) on Updating submodules of repository `"${p_repo_name}`""
            return 3
        }

        Write-Host '> Submodules updated successfully.'
        return 0
    }

    # Si no tiene submodulos
    Write-Host '> Repository updated successfully.'
    return 0


}

function m_update_vim_packages($p_is_neovim)
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
		if(($l_status -eq 1) -or ($l_status -eq 2))
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

    return 0

}


function m_update_vim($p_options, $p_is_neovim)
{

    #1. Inicializacion

    $l_tag= "VIM"
    if ($p_is_neovim) {
        $l_tag= "NeoVIM"
    }

    #2. Prerequisito: La opcion de actualizar VIM/NeoVIM esta habilitada
    if ($p_options -le 0) {
        return 1
    }

    $l_option = 1
    if ($p_is_neovim) {
        $l_option = 2
    }

    # Si no se debe actualizar
    if (($p_options -band $l_option) -ne $l_option) {
        return 1
    }


    #3. Prerequisito: Git debe estar instalado
    $l_version= $(git --version 2> $null)
    if (-not $?) {
        #No esta instalado Git, No configurarlo
        Write-Host "Se requiere que Git este instalado para actualizar los plugins de ${l_tag}."
        return 1
    }

    #4. Prerequisito: VIM/Neovim debe esta instalado
    $l_version=$(vim --version 2> $null)
    if (-not $?) {
        $l_version= $l_version[0]
        #Write-Host "VIM Version: ${l_version}"
        $l_version= $l_version -creplace "$g_regexp_sust_version1", '$1'
    }
    else {
        $l_version=""
    }

    if ($l_version -eq "") {
        #No esta instalado VIM/NeoVIM, No configurarlo
        Write-Host "Se requiere que ${l_tag} este instalado para actualizar sus paquetes."
        return 1
    }

    #Write-Host "VIM Version: ${l_version}"

    #5. Actualizar los paquetes

    #Mostrar el titulo
    $l_title= ">> Actualizar los paquetes de ${l_tag} (${l_version})"

    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
    Write-Host "$l_title" -ForegroundColor Blue
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue


    # Actualizar los plugins
    m_update_vim_packages $p_is_neovim

    # Mostrar la informacion de lo instalado
    show_vim_config_report $p_is_neovim

    return 0

}

function m_update_all($p_input_options) {


    #1. Actualizar paquetes VIM instalados
    m_update_vim $p_input_options $false

    #2. Actaulizar paquetes de NeoVIM
    m_update_vim $p_input_options $true

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

	#Write-Host ""
    #Write-Host ">NeoVIM> Restaurando las modificaciones realizada al plugin 'fzf': " -NoNewline
	#Write-Host "${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf" -ForegroundColor DarkGray -NoNewline
	#Write-Host "\plugin\fzf.vim" -ForegroundColor Blue
    #cd ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf
	#Write-Host "git pull origin master" -ForegroundColor DarkGray
    #git pull origin master
	#Write-Host "git restore autoload\fzf\vim.vim" -ForegroundColor DarkGray
    #git restore plugin\fzf.vim

	#Write-Host ""
	#Write-Host ">NeoVIM> Restaurando las modificaciones realizada al plugin 'fzf.vim': " -NoNewline
	#Write-Host "${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim" -ForegroundColor DarkGray -NoNewline
	#Write-Host "\autoload\fzf\vim.vim" -ForegroundColor Blue
    #cd ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim
	#Write-Host "git pull origin master" -ForegroundColor DarkGray
    #git pull origin master
	#Write-Host "git restore autoload\fzf\vim.vim" -ForegroundColor DarkGray
    #git restore autoload\fzf\vim.vim

	Write-Host ""
	Write-Host ""
    Write-Host "Intrucciones siguientes para corregir FZF:"

	Write-Host ""
    Write-Host "1> Buscar hay cambios que obligen a corregir las fuentes" -ForegroundColor Green
	Write-Host "   Comparando la ultima version (plugin de VIM) vs la fuente (${env:USERPROFILE}\.files\vim\templates\fixes\)" -ForegroundColor DarkGray
	Write-Host "   No cambie la lineas comentado con el comentario `"CHANGE ..." -ForegroundColor DarkGray
	Write-Host "   > Inicie la comparacion de '.\fzf\plugin\fzf.vim':" -ForegroundColor DarkGray
	Write-Host "     vim -d `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\fzf.vim `${env:USERPROFILE}\.files\vim\templates\fixes\fzf\plugin\fzf.vim"
	Write-Host "     - Use 'diffput' para subir cambios a la fuente." -ForegroundColor DarkGray
	Write-Host "     - Use '[c' y ']c' para navegar en las diferencias de un split." -ForegroundColor DarkGray
	Write-Host "     - Use 'windo diffoff' para ingresar al modo normal." -ForegroundColor DarkGray
	Write-Host "     - Use 'CTRL + l' y 'CTRL + h' para navegar en entre los split (si lo requiere)" -ForegroundColor DarkGray
	Write-Host "     - Guarde los cambios con ':w'." -ForegroundColor DarkGray
	Write-Host "   > Cierre e de la misma forma, inicie la comparacion de '.\fzf.vim\autoload\fzf\vim.vim':" -ForegroundColor DarkGray
	Write-Host "     vim -d `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim"


    Write-Host ""
    Write-Host "2> Si la fuente tiene cambios (fue corregido), copie y remplaze los archivos desde la fuente (corregido) a los plugins" -ForegroundColor Green
	Write-Host "   > Reparando VIM:" -ForegroundColor DarkGray
    Write-Host "     cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf\plugin\fzf.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\"
    Write-Host "     cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\"
	Write-Host "     cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\bin\"
	#Write-Host "   > Reparando NeoVIM:" -ForegroundColor DarkGray
	#Write-Host "     cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf\plugin\fzf.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf\plugin\"
    #Write-Host "     cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\autoload\fzf\"
	#Write-Host "     cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\bin\"

	Write-Host ""
    Write-Host "3> Opcional: subir los cambios de la fuentes corregida al repositorio remoto" -ForegroundColor Green
	Write-Host "   cd `${env:USERPROFILE}\.files"
	Write-Host "   git add vim\templates\fixes\fzf\plugin\fzf.vim"
	Write-Host "   git add vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim"
	Write-Host "   git push origin main"
	Write-Host ""

	cd ${env:USERPROFILE}
}


function m_changes_plugins_fzf()
{
	Write-Host ""
	Write-Host "Copiando los archivos de la fuente corregida " -ForegroundColor Blue -NoNewline
	Write-Host "(${env:USERPROFILE}\.files\vim\templates\fixes\)" -ForegroundColor DarkGray -NoNewline
	Write-Host " a los plugins 'fzf' y 'fzf.vim'..." -ForegroundColor Blue

	Write-Host ""
    Write-Host ">   VIM> Copiando los archivos de la fuente corregida al plugin 'fzf' y 'fzf.vim': "
    Write-Host "cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf\plugin\fzf.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\" -ForegroundColor DarkGray
    cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf\plugin\fzf.vim ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf\plugin\
    Write-Host "cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\" -ForegroundColor DarkGray
    cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\
	Write-Host "cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 `${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\bin\" -ForegroundColor DarkGray
	cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim\bin\

	#Write-Host ""
    #Write-Host ">NeoVIM> Copiando los archivos de la fuente corregida al plugin 'fzf' y 'fzf.vim': "
	#Write-Host "cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf\plugin\fzf.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf\plugin\" -ForegroundColor DarkGray
	#cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf\plugin\fzf.vim ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf\plugin\
    #Write-Host "cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\autoload\fzf\" -ForegroundColor DarkGray
    #cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\autoload\fzf\
	#Write-Host "cp `${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 `${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\bin\" -ForegroundColor DarkGray
	#cp ${env:USERPROFILE}\.files\vim\templates\fixes\fzf.vim\bin\preview.ps1 ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim\bin\

	Write-Host ""
	Write-Host ""
    Write-Host "Intrucciones siguientes:"


	Write-Host ""
    Write-Host "1> Opcional: Si ha realizado cambios, subir estos cambios de la fuentes corregida al repositorio remoto" -ForegroundColor Green
	Write-Host "   cd `${env:USERPROFILE}\.files"
	Write-Host "   git add vim\templates\fixes\fzf\plugin\fzf.vim"
	Write-Host "   git add vim\templates\fixes\fzf.vim\autoload\fzf\vim.vim"
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

    $l_status= m_update_all $p_input_options
}


function m_show_menu_core()
{
	Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu"
	Write-Host " (a) Actualizar los plugins VIM/NeoVIM"
	Write-Host " (b) Rollback las modificaciones realizadas de los plugins 'fzf' y 'fzf.vim'"
	Write-Host " (c) Cambiar los plugins 'fzf' y 'fzf.vim' usando la fuente corregida"
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
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
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup 1
				}

				'b' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup 2
				}

				'c' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup 3
				}

				'q' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
				}

				default {
					$l_continue= $true
					Write-Host "opción incorrecta"
	                Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
				}

			}

	}


}




#------------------------------------------------------------------------------------------------
# Main Code
#------------------------------------------------------------------------------------------------

#Procesar los argumentos
#$g_fix_fzf=0
#if($args.count -ge 1) {
#    if($args[0] -eq "1") {
#        $g_fix_fzf=1
#    }
#}

# Folder base donde se almacena el programas, comando y afines usados por Windows.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, se asignara "C:\apps"
# - En este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_win_base_path}/tools"    : subfolder donde se almacena los subfolder de los programas.
#     > "${g_win_base_path}/cmds/bin" : subfolder donde se almacena los comandos.
#     > "${g_win_base_path}/cmds/man" : subfolder donde se almacena los archivos de ayuda man1 del comando.
#     > "${g_win_base_path}/cmds/doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_win_base_path}/cmds/etc" : subfolder donde se almacena archivos adicionales del comando.
#     > "${g_win_base_path}/fonts" : subfolder donde se almacena los archivos de fuentes tipograficas.
$g_win_base_path=''

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "get_temp_path" asignara segun orden de prioridad a '$env:TEMP'.
$g_temp_path=''

# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
#Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
$g_setup_only_last_version=1

# Cargar la información:
if(Test-Path "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1") {

    . "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"

    #Fix the bad entry values
    if( "$g_setup_only_last_version" -eq "0" ) {
        $g_setup_only_last_version=0
    }
    else {
        $g_setup_only_last_version=1
    }

}

# Valor por defecto del folder base de  programas, comando y afines usados por Windows.
if((-not ${g_win_base_path}) -and (Test-Path "$g_win_base_path")) {
    $g_win_base_path='C:\apps'
}

# Ruta del folder base donde estan los subfolderes del los programas (1 o mas comandos y otros archivos).
if((-not ${g_temp_path}) -and (Test-Path "$g_temp_path")) {
    $g_temp_path= 'C:\Windows\Temp'
}


show_menu
