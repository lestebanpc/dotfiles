
function m_update_repository($p_path, $p_repo_name, $p_flag_nvim) 
{
    if(!(Test-Path $p_path)) {
        Write-Host "Folder `"${p_path}`" not exists"
        return 9
    }

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
	if(${p_flag_nvim})
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

function m_update_vim_repository($p_flag_nvim, $p_is_coc_installed)
{

	$l_show_title= $false
	$l_tag= ""
	$l_path_plugins= ""
	if(${p_flag_nvim})
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
			Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Blue
			Write-Host "                                                    ${l_tag}" -ForegroundColor Blue
			Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Blue    
			$l_show_title= $true
		}
        $l_repo_path = Split-Path -Parent $folder.FullName
		$l_repo_name = Split-Path "$l_repo_path" -Leaf
        $l_status= m_update_repository $l_repo_path $l_repo_name $p_flag_nvim
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
		Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
		if(${p_flag_nvim})
		{		
			Write-Host "- NeoVIM> Indexando la documentación de los plugin"
		}
		else
		{
			Write-Host "-    VIM> Indexando la documentación de los plugin"
		}
		Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
		
		$l_j
		for ($i=0; $i -lt $l_n; $i++) {
			$l_repo_path= $la_doc_paths[$i]
			$l_repo_name= $la_doc_repos[$i]
			$l_j= $i + 1
			Write-Host "(${l_j}/(l_n)) Indexando la documentación del plugin `"${l_repo_name}`" en `"${l_tag}`": `"helptags ${l_repo_path}`"\n"
			if(${p_flag_nvim})
			{
                nvim --headless -c "helptags ${l_repo_path}" -c qa
			}
			else
			{
                vim -u NONE -esc "helptags ${l_repo_path}" -c qa
			}

			
		}
	}
	

    #Si se actualizo de paquete de fzf seguir los siguientes pasos en Vim y NeoVim
    #en fzf descargar el repositorio temporalmente y traer los archivos, comprararlo y actualizar ~/files/vim/plugin/fzf
    
    #~\vimfiles\pack\ui\opt\fzf.vim
    #Restaurar el archivo 
    #comprar con lo que se tiene en y actualizar el repo 

}


function m_fix_fzf() 
{
    Write-Host "Restaurando las version del archivos desde repositorio git ..."
    cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf
    git pull origin master
    git restore plugin\fzf.vim

    cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim
    git pull origin master
    git restore autoload\fzf\vim.vim

    cd ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf
    git pull origin master
    git restore plugin\fzf.vim

    cd ${env:LOCALAPPDATA}\nvim-data\site\pack\ui\opt\fzf.vim
    git pull origin master
    git restore autoload\fzf\vim.vim

    Write-Host ""
    Write-Host "Fixing Vim ..."
    Write-Host "Last vs Fixed (fzf)     : Use 'diffget' para corregir la version ultima, 'windo diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:USERPROFILE`}\vimfiles\pack\ui\opt\fzf\plugin\fzf.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf\plugin\fzf.vim"
    Write-Host "Last vs Fixed (fzf.vim) : Use 'diffget' para corregir la version ultima, windo 'diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:USERPROFILE`}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim"
    Write-Host ""
    Write-Host ""
    Write-Host "Fixing NeoVim ..."
    Write-Host "Last vs Fixed (fzf)     : Use 'diffget' para corregir la version ultima, 'windo diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:LOCALAPPDATA`}\nvim-data\site\pack\ui\opt\fzf\plugin\fzf.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf\plugin\fzf.vim"
    Write-Host "Last vs Fixed (fzf.vim) : Use 'diffget' para corregir la version ultima, 'windo diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:LOCALAPPDATA`}\nvim-data\site\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim"
    
    Write-Host ""
    Write-Host "Revise los singuientes enlaces simbolicos al script '%USERPROFILE%\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1':"
    Write-Host "En Vim   : dir `$`{env:USERPROFILE`}\vimfiles\pack\ui\opt\fzf.vim\bin\preview.ps1"
    Write-Host "     MKLINK %USERPROFILE%\vimfiles\pack\ui\opt\fzf.vim\bin\preview.ps1 %USERPROFILE%\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1"
    Write-Host "En NeoVim: dir %LOCALAPPDATA%\nvim-data\site\pack\ui\opt\fzf.vim\bin\preview.ps1"
    Write-Host "     MKLINK %LOCALAPPDATA%\nvim-data\site\pack\ui\opt\fzf.vim\bin\preview.ps1 %USERPROFILE%\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1"

}

function m_setup($p_input_options)
{
	if ($p_input_options -eq 1)
	{
		#Actualizar plugins de VIM		
		m_update_vim_repository $false $true
		
		#Actualizar plugins de NeoVIM		
		m_update_vim_repository $true $true
		return
	}
	
	#m_fix_fzf
	#return 0
}


function m_show_menu_core() 
{
	Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu";
	Write-Host " (a) Actualizar los plugins VIM/NeoVIM";
	Write-Host " (b) Reparar FZF";	
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

