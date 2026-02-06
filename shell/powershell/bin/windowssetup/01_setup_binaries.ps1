#------------------------------------------------------------------------------------------------
# Inicializacion
#------------------------------------------------------------------------------------------------

$g_max_length_line= 130

# Importando funciones de utilidad
#. "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/lib/setup_profile_utility.ps1"


#------------------------------------------------------------------------------------------------
# Funciones de Utilidad Genericas
#------------------------------------------------------------------------------------------------

# Compara 2 versiones.
# > Parametro salida> Valor de retorno:
#   -1 : Version 1 < Version 2
#    0 : Version 1 = Version 2
#    1 : Version 1 > Version 2
function m_compare_versions1 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Version1,

        [Parameter(Mandatory=$true)]
        [string]$Version2
    )

    try {
        # Limpiar las versiones
        $Version1 = $Version1 -replace '^[^\d]+|[^\d\.]+$', ''
        $Version2 = $Version2 -replace '^[^\d]+|[^\d\.]+$', ''

        # Convertir a objetos Version
        $v1 = [Version]$Version1
        $v2 = [Version]$Version2

        # Comparar usando el método CompareTo
        return $v1.CompareTo($v2)
    }
    catch {
        Write-Error "Error al comparar versiones: $($_.Exception.Message)"
        return $null
    }
}

# Compara 2 versiones.
# > Parametro salida> Valor de retorno:
#   -1 : Version 1 < Version 2
#    0 : Version 1 = Version 2
#    1 : Version 1 > Version 2
function m_compare_versions2 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Version1,

        [Parameter(Mandatory=$true)]
        [string]$Version2
    )

    # Limpiar las versiones eliminando caracteres no numéricos al inicio o final
    $Version1 = $Version1 -replace '^[^\d]+|[^\d]+$', ''
    $Version2 = $Version2 -replace '^[^\d]+|[^\d]+$', ''

    # Dividir las versiones en partes numéricas
    $v1Parts = $Version1 -split '\.'
    $v2Parts = $Version2 -split '\.'

    # Determinar el máximo número de partes para comparar
    $maxParts = [Math]::Max($v1Parts.Count, $v2Parts.Count)

    # Comparar cada parte de la versión
    for ($i = 0; $i -lt $maxParts; $i++) {
        # Obtener la parte actual, o 0 si no existe
        $part1 = if ($i -lt $v1Parts.Count) { [int]$v1Parts[$i] } else { 0 }
        $part2 = if ($i -lt $v2Parts.Count) { [int]$v2Parts[$i] } else { 0 }

        # Comparar las partes
        if ($part1 -gt $part2) {
            return 1  # Version1 es mayor
        }
        elseif ($part1 -lt $part2) {
            return -1 # Version2 es mayor
        }
        # Si son iguales, continuar con la siguiente parte
    }

    # Si llegamos aquí, las versiones son iguales
    return 0
}



#------------------------------------------------------------------------------------------------
# Funciones de Utilidad para la Instalacion
#------------------------------------------------------------------------------------------------

# Función para obtener la versión actual instalada
function m_get_current_version($p_repo_id) {

    $l_current_version= $null
    try {

	    switch ($p_repo_id)
	    {

		    'wezterm' {

                #$versionInfo = "$(wezterm --version 2>$null)"
                #if ($LASTEXITCODE -eq 0 -and $versionInfo) {
                #    # Extraer la versión del formato "wezterm 20230712-072601-f4abf8fd"
                #    if ($versionInfo -match '.* ([0-9]+)_.*') {
                #        return $matches[1]
                #    }
                #}

		        if (-not (Test-Path "${g_win_base_path}\wezterm.info")) {
		        	return $null
	            }

		        $l_current_version = Get-Content -Path "${g_win_base_path}\wezterm.info" -TotalCount 1

            }

            # nvim --version | head -n 1
            #NVIM v0.11.5

            # vim --version | head -n 1
            #VIM - Vi IMproved 9.1 (2024 Jan 02, compiled Jan 30 2026 00:00:00)

        }

        return $l_current_version

    }
    catch {
        Write-Warning "No se pudo obtener la versión actual instalada"
    }

    return $null

}

# Función para obtener la última versión nightly de GitHub
function m_get_latest_version($p_repo_id) {

    $l_last_version= $null

    try {


	    switch ($p_repo_id)
	    {

		    'wezterm' {

                Write-Host "Obteniendo información de la última versión nightly..."

                $l_last_version="$(curl -Ls -H 'Accept: application/vnd.github+json' 'https://api.github.com/repos/wezterm/wezterm/releases/tags/nightly' | jq -r '.updated_at')"
                if($null -eq $l_last_version) {
                    return $null
                }

                $l_date_obj = [datetime]::Parse($l_repo_last_version)
                $l_last_version = $l_date_obj.ToString('yyyyMMdd')

            }

        }

        return $l_last_version

    }
    catch {
        Write-Error "Error al obtener la información de la versión nightly: $($_.Exception.Message)"
        return $null
    }
}


# Compara 2 versiones.
# > Parametro salida> Valor de retorno:
#   True si se debe instalar. Caso contrario no instalar.
function m_should_setup_repo_version($p_repo_id, $p_curent_version, $p_lastest_version, $p_tag) {


    # Si no se tiene version previamente instalada
    if ($null -eq $l_current_version) {
        Write-Host "${p_tag} - No se encontró una versión instalada previamente. Se procederá a descargar." -ForegroundColor Yellow
        return $true
	}

    try {

        # Comparar versiones
        $l_status = 0
	    if ($p_repo_id -eq "wezterm") {
            $l_status = m_compare_versions1 "${l_current_version}.0" "${l_latest_version}.0"
        }
        else {
            $l_status = m_compare_versions1 "${l_current_version}" "${l_latest_version}"
        }

        # Solo actualizar
        if($l_status -lt 0) {
            return $true
        }

        Write-Host "${l_tag} - No es necesario actualizar. El proceso ha finalizado." -ForegroundColor Green
        return $false

    }
    catch {
        Write-Warning "${p_tag} - No se pudo camparar versiones del artefactos del repositorio '${p_repo_id}'"
        return $false
    }

}


function m_get_repo_info($p_repo_id, $p_pretty_version, $p_flag_use_arm, $p_tag) {

    $l_artifact_url= $null
    $l_type_file = 0
    $l_file_name = "${p_repo_id}.zip"

    try {

	    switch ($p_repo_id)
	    {

		    'wezterm' {
                $l_artifact_url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-windows-nightly.zip'
            }

		    'nvim' {

                #https://github.com/neovim/neovim/releases/download/v0.11.6/nvim-win-arm64.zip
                #https://github.com/neovim/neovim/releases/download/v0.11.6/nvim-win64.zip
                $l_artifact_url = "https://github.com/neovim/neovim/releases/download/v${l_latest_version}/nvim-win64.zip"
                if( $p_flag_use_arm ) {
                    $l_artifact_url = "https://github.com/neovim/neovim/releases/download/v${l_latest_version}/nvim-win-arm64.zip"
                }

            }

		    'vim' {
                #https://github.com/vim/vim-win32-installer/releases/download/v9.1.2132/gvim_9.1.2132_arm64.zip
                #https://github.com/vim/vim-win32-installer/releases/download/v9.1.2132/gvim_9.1.2132_x64.zip
                $l_artifact_url = "https://github.com/vim/vim-win32-installer/releases/download/v${l_latest_version}/gvim_${l_latest_version}_x64.zip"
                if( $p_flag_use_arm ) {
                    $l_artifact_url = "https://github.com/vim/vim-win32-installer/releases/download/v${l_latest_version}/gvim_${l_latest_version}_arm64.zip"
                }
            }

        }

        return @($l_repo_url, $l_type_file, $l_file_name)

    }
    catch {
        Write-Warning "${p_tag} - No se pudo obtener la información del repositorio '${p_repo_id}'"
    }

    return $null

}

function m_setup_repo_info($p_repo_id, $p_file_type, $p_download_file, $p_pretty_version, $p_flag_use_arm, $p_tag) {

    $l_install_path = ''

    switch ($p_repo_id)
	{

	    'wezterm' {

            # Instalar y/o Configurar los artefeacto
            $l_install_path = "${g_win_base_path}\wezterm"

            # Eliminar contenido anterior si existe
            if (Test-Path "$l_install_path") {
                Write-Host "${p_tag} - Eliminando contenido anterior..." -ForegroundColor Cyan
                Remove-Item $l_install_path -Recurse -Force
                Write-Host "${p_tag} - Contenido anterior eliminado." -ForegroundColor Green
            }

            # Descomprimir el archivo
            Write-Host "${p_tag} - Descomprimiendo archivo..." -ForegroundColor Cyan
            Expand-Archive -Path $p_download_file -DestinationPath $g_win_base_path -Force -ErrorAction Stop
            Write-Host "${p_tag} - Descompresión completada." -ForegroundColor Green

            # Buscar el primer subfolder que cumpla la condición
            $l_folder = Get-ChildItem -Path $g_win_base_path -Directory |
                Where-Object { $_.Name -like 'WezTerm-windows-*' } | Select-Object -First 1

            # Si se encontró, renombrar
            if ($l_folder) {
                Rename-Item -Path $l_folder.FullName -NewName 'wezterm'
                Write-Host "${p_tag} - Renombrado '$($l_folder.Name)' a 'wezterm'"
            }
            else {
                Write-Host "${p_tag} - No se encontró carpeta que empiece con 'WezTerm-windows-'"
            }

            # Limpiar archivo temporal
            if (Test-Path $p_download_file) {
                Remove-Item $p_download_file -Force
                Write-Host "${p_tag} - Archivo temporal eliminado." -ForegroundColor Green
            }

            # Crea o sobrescribe el archivo de version
            Set-Content -Path "${g_win_base_path}\wezterm.info" -Value "$l_latest_version"

            Write-Host "${p_tag} - ¡Actualización completada exitosamente!"
            Write-Host "${p_tag} - WezTerm ha sido instalado en: $l_install_path"

        }


	    'nvim' {

            $l_install_path = "${g_win_base_path}\tools"

            # Eliminar contenido anterior si existe
            if (Test-Path "$l_install_path\neovim") {
                Write-Host "${p_tag} - Eliminando contenido anterior..." -ForegroundColor Cyan
                Remove-Item "$l_install_path\neovim" -Recurse -Force
                Write-Host "${p_tag} - Contenido anterior eliminado." -ForegroundColor Green
            }

            # Descomprimir el archivo
            Write-Host "${p_tag} - Descomprimiendo archivo..." -ForegroundColor Cyan
            Expand-Archive -Path $p_download_file -DestinationPath "${l_install_path}" -Force -ErrorAction Stop
            Write-Host "${p_tag} - Descompresión completada." -ForegroundColor Green

            # Buscar el primer subfolder que cumpla la condición
            $l_folder = Get-ChildItem -Path "${l_install_path}" -Directory |
                Where-Object { $_.Name -like 'nvim-*' } | Select-Object -First 1

            # Si se encontró, renombrar
            if ($l_folder) {
                Rename-Item -Path $l_folder.FullName -NewName 'neovim'
                Write-Host "${p_tag} - Renombrado '$($l_folder.Name)' a 'neovim'"
            }
            else {
                Write-Host "${p_tag} - No se encontró carpeta que empiece con 'nvim-'"
            }

            # Limpiar archivo temporal
            if (Test-Path $p_download_file) {
                Remove-Item $p_download_file -Force
                Write-Host "${p_tag} - Archivo temporal eliminado." -ForegroundColor Green
            }

        }


	    'vim' {

            $l_install_path = "${g_win_base_path}\tools"

            # Eliminar contenido anterior si existe
            if (Test-Path "$l_install_path\vim") {
                Write-Host "${p_tag} - Eliminando contenido anterior..." -ForegroundColor Cyan
                Remove-Item "$l_install_path\vim" -Recurse -Force
                Write-Host "${p_tag} - Contenido anterior eliminado." -ForegroundColor Green
            }

            # Descomprimir el archivo
            Write-Host "${p_tag} - Descomprimiendo archivo..." -ForegroundColor Cyan
            Expand-Archive -Path $p_download_file -DestinationPath "${l_install_path}" -Force -ErrorAction Stop
            Write-Host "${p_tag} - Descompresión completada." -ForegroundColor Green

            # Buscar el primer subfolder que cumpla la condición
            $l_folder = Get-ChildItem -Path "${l_install_path}" -Directory |
                Where-Object { $_.Name -like 'vim*' } | Select-Object -First 1

            # Si se encontró, renombrar
            if ($l_folder) {
                Rename-Item -Path $l_folder.FullName -NewName 'vim'
                Write-Host "${p_tag} - Renombrado '$($l_folder.Name)' a 'vim'"
            }
            else {
                Write-Host "${p_tag} - No se encontró carpeta que empiece con 'vim'"
            }

            # Limpiar archivo temporal
            if (Test-Path $p_download_file) {
                Remove-Item $p_download_file -Force
                Write-Host "${p_tag} - Archivo temporal eliminado." -ForegroundColor Green
            }

        }

    }

    return 0

}


#------------------------------------------------------------------------------------------------
# Funciones de Instalacion
#------------------------------------------------------------------------------------------------

function m_setup_repo($p_repo_id, $p_flag_use_arm) {

    $l_status = 0
    $l_tag = "${p_repo_id}"

    # Obtener versiones
    Write-Host "${l_tag} - Verificando versiones..."
    $l_current_version = m_get_current_version $p_repo_id
    $l_latest_version = m_get_latest_version $p_repo_id

    if (!$l_latest_version) {
        Write-Error "${l_tag} - No se pudo obtener la información de la última versión"
        return 3
    }

    Write-Host "${l_tag} - Versión actual instalada: $($l_current_version)"
    Write-Host "${l_tag} - Última versión nightly  : $($l_latest_version)"

    # Verificar si es necesario actualizar
    $l_should_download = m_should_setup_repo_version $p_repo_id $l_current_version $l_latest_version $l_tag

    # Si no es neceario Descargar
    if (-not $l_should_download) {
        return 1
    }

    # Obtener la informacion del repositorio
    $l_tag = "${p_repo_id}[${l_latest_version}]"
    $la_repo_info = m_get_repo_info $p_repo_id $l_last_version $p_flag_use_arm $p_tag
    if ( $null -eq $la_repo_info ) {
        Write-Host "${l_tag} - No es se puede obtener informacion del repositorio '${p_repo_id}'." -ForegroundColor Red
        return 1
    }

    # Descargar los artefactos del repositorio
    $l_file_url = $la_repo_info[0]
    $l_file_type = $la_repo_info[1]
    $l_download_file = "${g_temp_path}\$la_repo_info[2]"

    try {

        Write-Host "${l_tag} - Descargando la última versión nightly..." -ForegroundColor Cyan
        Write-Host "${l_tag} - URL: ${l_file_url}" -ForegroundColor Gray
        Write-Host "${l_tag} - Destino: $l_download_file" -ForegroundColor Gray

        # Descargar el archivo
        Invoke-WebRequest -Uri $l_file_url -OutFile $l_download_file -ErrorAction Stop
        Write-Host "${l_tag} - Descarga completada exitosamente." -ForegroundColor Green

    }
    catch {

        Write-Error "${l_tag} - Error durante el proceso de actualización: $($_.Exception.Message)"

        # Limpiar archivo temporal en caso de error
        if (Test-Path $l_download_file) {
            Remove-Item $l_download_file -Force -ErrorAction SilentlyContinue
        }
        return 2
    }


    # Configurar el repositorio
    try {
        $l_status= m_setup_repo_info $p_repo_id $l_file_type $l_download_file $l_latest_version $p_flag_use_arm $p_tag
    }
    catch {

        Write-Error "${l_tag} - Error durante el proceso de actualización: $($_.Exception.Message)"
        # Limpiar archivo temporal en caso de error
        if (Test-Path $l_download_file) {
            Remove-Item $l_download_file -Force -ErrorAction SilentlyContinue
        }
        return 2
    }

    #Write-Host "Script finalizado." -ForegroundColor Green
    return 0

}


#------------------------------------------------------------------------------------------------
# Funciones principal de instalacion
#------------------------------------------------------------------------------------------------

function m_setup($p_input_options) {

    if ($p_input_options -le 0) {
        return
    }

    $l_status= 0

	# (   1) Descargar/Actualizar WezTerm nightly version
	# (   2) Descargar/Actualizar VIM
	# (   4) Descargar/Actualizar NeoVIM
    $l_option = 1
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_status= m_setup_repo 'wezterm' $false
    }

    $l_option = 2
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_status= m_setup_repo 'vim' $false
    }

    $l_option = 4
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_status= m_setup_repo 'nvim' $false
    }


}


#------------------------------------------------------------------------------------------------
# Funciones Menu
#------------------------------------------------------------------------------------------------

function m_show_menu_core() {

	Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu";

	Write-Host " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:"
	Write-Host "    (   1) Descargar/Actualizar WezTerm nightly version"
	Write-Host "    (   2) Descargar/Actualizar VIM"
	Write-Host "    (   4) Descargar/Actualizar NeoVIM"
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
}

function show_menu() {

	Write-Host ""
	m_show_menu_core

	$l_continue= $true
	$l_read_option= ""
    $l_options=0

	while($l_continue)
	{
			Write-Host "Ingrese la opción (" -NoNewline
			Write-Host "no ingrese los ceros a la izquierda" -NoNewline -ForegroundColor DarkGray
			$l_read_option= Read-Host ")"

			switch -Regex ($l_read_option)
			{

				'^\d+$' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

                    $l_options = [int]$l_read_option
					m_setup $l_options
				}


				'^q$' {
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


# Cargar la información:
if(Test-Path "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1") {

    . "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"
    Write-Host "Config File                    : ${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1" -ForegroundColor DarkGray

    #Fix the bad entry values

}

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
if((-not ${g_win_base_path}) -or -not (Test-Path "$g_win_base_path")) {
    $g_win_base_path='C:\apps'
}
Write-Host "Base Folder Path               : ${g_win_base_path}" -ForegroundColor DarkGray

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "get_temp_path" asignara segun orden de prioridad a '$env:TEMP'.
if((-not ${g_temp_path}) -or -not (Test-Path "$g_temp_path")) {
    $g_temp_path= 'C:\Windows\Temp'
}
Write-Host "Temporary Path                 : ${g_temp_path}" -ForegroundColor DarkGray

# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
#Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
if(-not (Get-Variable g_setup_only_last_version -ErrorAction SilentlyContinue) ) {
    $g_setup_only_last_version=1
}

# Determinar si se esta ejecutando la terminal con privilegios administratrivos
$g_shell_with_admin_privileges = $false

$t_principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($t_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $g_shell_with_admin_privileges = $true
    Write-Host "Administrator Privileges       : ${g_shell_with_admin_privileges}" -ForegroundColor DarkGray
}
else {
    Write-Host "Administrator Privileges       : ${g_shell_with_admin_privileges}" -ForegroundColor DarkGray
}

show_menu
