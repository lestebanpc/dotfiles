#------------------------------------------------------------------------------------------------
# Inicializacion
#------------------------------------------------------------------------------------------------

$g_max_length_line= 130

# Importando funciones de utilidad
#. "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/lib/setup_profile_utility.ps1"


#------------------------------------------------------------------------------------------------
# Funciones Menu
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


# Función para obtener la versión actual instalada
function m_get_current_version() {

    try {

        $versionInfo = "$(wezterm --version 2>$null)"
        if ($LASTEXITCODE -eq 0 -and $versionInfo) {
            # Extraer la versión del formato "wezterm 20230712-072601-f4abf8fd"
            if ($versionInfo -match '.* ([0-9]+)_.*') {
                return $matches[1]
            }
        }

    }
    catch {
        Write-Warning "No se pudo obtener la versión actual instalada"
    }

    return $null

}

# Función para obtener la última versión nightly de GitHub
function m_get_latest_version() {

    try {

        Write-Host "Obteniendo información de la última versión nightly..." -ForegroundColor Cyan

        $l_repo_last_version="$(curl -Ls -H 'Accept: application/vnd.github+json' 'https://api.github.com/repos/wezterm/wezterm/releases/tags/nightly' | jq -r '.updated_at')"
        if($null -eq $l_repo_last_version) {
            return $null
        }

        $l_date_obj = [datetime]::Parse($l_repo_last_version)
        $l_repo_last_version = $l_date_obj.ToString('yyyyMMdd')
        return $l_repo_last_version

    }
    catch {
        Write-Error "Error al obtener la información de la versión nightly: $($_.Exception.Message)"
        return $null
    }
}


function m_setup_wezterm() {

    # Obtener versiones
    Write-Host "Verificando versiones..." -ForegroundColor Cyan
    $l_current_version = m_get_current_version()
    $l_latest_version_info = m_get_latest_version()

    if (!$l_latest_version_info) {
        Write-Error "No se pudo obtener la información de la última versión"
        return 3
    }

    Write-Host "Versión actual instalada: $($l_current_version)" -ForegroundColor Cyan
    Write-Host "Última versión nightly  : $($l_latest_version_info)" -ForegroundColor Cyan

    # Verificar si es necesario actualizar
    $l_should_download = $false

    if ($null -eq $l_current_version) {
        Write-Host "No se encontró una versión instalada previamente. Se procederá a descargar." -ForegroundColor Yellow
        $l_should_download = $true
    else {

        $l_status = m_compare_versions1 "$l_current_version" "$l_latest_version_info"
        if($l_status -lt 0) {
            $l_should_download = $true
        }

    }

    # Descargar si es necesario
    if (-not $l_should_download) {
        Write-Host "No es necesario actualizar. El proceso ha finalizado." -ForegroundColor Green
        return 1
    }

    $l_url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-windows-nightly.zip'
    $l_download_path = 'C:\Temp\wezterm.zip'
    $l_install_path = "${g_win_base_path}\wezterm"
    try {

        Write-Host "Descargando la última versión nightly..." -ForegroundColor Cyan
        Write-Host "URL: ${l_url}" -ForegroundColor Gray
        Write-Host "Destino: $l_download_path" -ForegroundColor Gray

        # Descargar el archivo
        Invoke-WebRequest -Uri $l_url -OutFile $l_download_path -ErrorAction Stop
        Write-Host "Descarga completada exitosamente." -ForegroundColor Green

        # Eliminar contenido anterior si existe
        if (Test-Path "$l_install_path") {
            Write-Host "Eliminando contenido anterior..." -ForegroundColor Cyan
            Remove-Item $l_install_path -Recurse -Force
            Write-Host "Contenido anterior eliminado." -ForegroundColor Green
        }

        # Descomprimir el archivo
        Write-Host "Descomprimiendo archivo..." -ForegroundColor Cyan
        Expand-Archive -Path $l_download_path -DestinationPath $g_win_base_path -Force -ErrorAction Stop
        Write-Host "Descompresión completada." -ForegroundColor Green

        # Buscar el primer subfolder que cumpla la condición
        $l_folder = Get-ChildItem -Path $g_win_base_path -Directory |
            Where-Object { $_.Name -like 'WezTerm-windows-*' } | Select-Object -First 1

        # Si se encontró, renombrar
        if ($l_folder) {
            Rename-Item -Path $l_folder.FullName -NewName 'wezterm'
            Write-Host "Renombrado '$($l_folder.Name)' a 'wezterm'"
        }
        else {
            Write-Host "No se encontró carpeta que empiece con 'WezTerm-windows-'"
        }

        # Limpiar archivo temporal
        if (Test-Path $l_download_path) {
            Remove-Item $l_download_path -Force
            Write-Host "Archivo temporal eliminado." -ForegroundColor Green
        }

        Write-Host "¡Actualización completada exitosamente!" -ForegroundColor Green
        Write-Host "WezTerm ha sido instalado en: $l_install_path" -ForegroundColor Green

    }
    catch {

        Write-Error "Error durante el proceso de actualización: $($_.Exception.Message)"
        # Limpiar archivo temporal en caso de error
        if (Test-Path $l_download_path) {
            Remove-Item $l_download_path -Force -ErrorAction SilentlyContinue
        }
        return 2
    }

    Write-Host "Script finalizado." -ForegroundColor Green

}


#------------------------------------------------------------------------------------------------
# Funciones Menu
#------------------------------------------------------------------------------------------------

function m_setup($p_options) {

    if($p_input_options -eq "a") {

        m_setup_wezterm()
        return
    }

}

function m_show_menu_core() {

	Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu";
	Write-Host " (a) Descargar/Actualizar WezTerm nightly version"
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
}

function show_menu() {

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
					m_setup $l_read_option
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
