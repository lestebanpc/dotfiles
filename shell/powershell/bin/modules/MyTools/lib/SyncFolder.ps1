# Módulo de sincronización de folder local con Google Drive y OneDrive


# Rutas locales y remotas configuradas
$script:LocalPaths = @{
    'gnote_it'         = "D:\vaults\notes\it_disiplines"
    'gnote_management' = "D:\vaults\notes\management_disiplines"
    'gnote_sciences'   = "D:\vaults\notes\sciences_and_disiplines"
    'gnote_personal'   = "D:\vaults\notes\personal"
    'gsecret_personal' = "D:\vaults\secrets\personal"
    'onote_it'         = "D:\vaults\notes\it_disiplines"
    'onote_management' = "D:\vaults\notes\management_disiplines"
    'onote_sciences'   = "D:\vaults\notes\sciences_and_disiplines"
    'onote_personal'   = "D:\vaults\notes\personal"
    'osecret_personal' = "D:\vaults\secrets\personal"
    'owork_bp_tasks'   = "D:\work\tasks"
    'owork_bp_info'    = "D:\work\info"
}

$script:RemotePaths = @{
    'gnote_it'         = "/vaults/notes/it_disiplines"
    'gnote_management' = "/vaults/notes/management_disiplines"
    'gnote_sciences'   = "/vaults/notes/sciences_and_disiplines"
    'gnote_personal'   = "/vaults/notes/personal"
    'gsecret_personal' = "/vaults/secrets/personal"
    'onote_it'         = "/vaults/notes/it_disiplines"
    'onote_management' = "/vaults/notes/management_disiplines"
    'onote_sciences'   = "/vaults/notes/sciences_and_disiplines"
    'onote_personal'   = "/vaults/notes/personal"
    'osecret_personal' = "/vaults/secrets/personal"
    'owork_bp_tasks'   = "/works/bp/tasks"
    'owork_bp_info'    = "/works/bp/info"
}


# Definir colores para la consola
$script:Colors = @{
    Reset      = "`e[0m"
    Green      = "`e[32m"
    Gray       = "`e[90m"
    Cyan       = "`e[36m"
    Yellow     = "`e[33m"
    Red        = "`e[31m"
    Blue       = "`e[34m"
    BrightCyan = "`e[96m"
}


function Write-ColoredMessage {
    param(
        [string]$Message,
        [string]$Color = "Gray"
    )

    if ($script:Colors.ContainsKey($Color)) {
        $colorCode = $script:Colors[$Color]
        $resetCode = $script:Colors["Reset"]
        Write-Host "${colorCode}${Message}${resetCode}"
    } else {
        Write-Host $Message
    }
}

function Get-RcloneVersion {
    try {
        $versionOutput = rclone --version 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($versionOutput)) {
            Write-ColoredMessage "El binario rclone no está instalado o configurado." "Red"
            return $null
        }

        $versionLine = $versionOutput | Select-Object -First 1
        $versionMatch = [regex]::Match($versionLine, 'rclone v([\d\.]+)')
        if ($versionMatch.Success) {
            return $versionMatch.Groups[1].Value
        }

        Write-ColoredMessage "No se puede determinar la versión del rclone instalado." "Red"
        return $null
    } catch {
        Write-ColoredMessage "Error al obtener la versión de rclone: $_" "Red"
        return $null
    }
}

function Get-JqVersion {
    try {
        $versionOutput = jq --version 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($versionOutput)) {
            Write-ColoredMessage "El binario jq no está instalado o configurado." "Red"
            return $null
        }
        return $versionOutput.Trim()
    } catch {
        Write-ColoredMessage "Error al obtener la versión de jq: $_" "Red"
        return $null
    }
}

function Get-RcloneRemoteInfo {
    param(
        [string]$RemoteName
    )

    try {
        $configDump = rclone config dump | ConvertFrom-Json
        if (-not $configDump.PSObject.Properties.Name.Contains($RemoteName)) {
            Write-ColoredMessage "No se encuentra la configuración para el remote '$RemoteName'." "Red"
            return $null
        }

        $remoteConfig = $configDump.$RemoteName
        $remoteType = $remoteConfig.type

        $result = @{
            RemoteType = $remoteType
            RemoteName = $RemoteName
        }

        if ($remoteType -eq 'drive') {
            $rootFolderId = $remoteConfig.root_folder_id
            if ([string]::IsNullOrEmpty($rootFolderId) -or $rootFolderId -eq 'null') {
                Write-ColoredMessage "No se encuentra la configuración del 'drive_id' para '$RemoteName'." "Red"
                return $null
            }
            $result.RootFolderId = $rootFolderId
        }

        return $result
    } catch {
        Write-ColoredMessage "Error al obtener información de rclone remote: $_" "Red"
        return $null
    }
}

function Invoke-RcloneSync {
    param(
        [string]$RemoteName,
        [string]$LocalPath,
        [string]$RemotePath,
        [int]$OperationType,  # 0=Bidireccional, 1=Homologación, 2=Unidireccional
        [int]$PathPosition = 0,  # 0=remote->local, 1=local->remote
        [switch]$DryRun,
        [string]$ConflictWinner = "none",
        [string]$LosserAction = "num",
        [switch]$Force,
        [string]$HomologationMode = "path1"
    )

    # Validar instalación de rclone y jq
    $rcloneVersion = Get-RcloneVersion
    if (-not $rcloneVersion) { return $false }

    $jqVersion = Get-JqVersion
    if (-not $jqVersion) { return $false }

    Write-ColoredMessage "Comando rclone : Version '$rcloneVersion'." "Gray"

    # Obtener información del remote
    $remoteInfo = Get-RcloneRemoteInfo -RemoteName $RemoteName
    if (-not $remoteInfo) { return $false }

    # Construir descripción del remote
    $remoteDesc = ""
    if ($remoteInfo.RemoteType -eq 'drive') {
        $remoteDesc = "Type '$($remoteInfo.RemoteType)', Name '$($remoteInfo.RemoteName)', Folder ID '$($remoteInfo.RootFolderId)', Path '$RemotePath'"
    } else {
        $remoteDesc = "Type '$($remoteInfo.RemoteType)', Name '$($remoteInfo.RemoteName)', Path '$RemotePath'"
    }

    # Mostrar información de rutas
    if ($PathPosition -ne 0) {
        Write-ColoredMessage "Path1 is local : Path '$LocalPath'." "Cyan"
        Write-ColoredMessage "Path2 is remote: $remoteDesc" "Cyan"
    } else {
        Write-ColoredMessage "Path1 is remote: $remoteDesc" "Cyan"
        Write-ColoredMessage "Path2 is local : Path '$LocalPath'." "Cyan"
    }

    # Construir opciones de rclone
    $options = @("-MvP", "--modify-window", "2s")

    if ($remoteInfo.RemoteType -eq 'drive') {
        $options += "--drive-skip-gdocs"
    }

    if ($DryRun) {
        $options += "--dry-run"
    }

    $operationDesc = ""
    switch ($OperationType) {
        0 { # Sincronización bidireccional
            $operationDesc = "sincronización bidireccional"
            $options += "--compare", "size,modtime,checksum"

            if ($Force) {
                $options += "--force"
            }

            if (-not [string]::IsNullOrEmpty($ConflictWinner)) {
                $options += "--conflict-resolve", $ConflictWinner
            }

            if (-not [string]::IsNullOrEmpty($LosserAction)) {
                $options += "--conflict-loser", $LosserAction
            }
        }
        1 { # Homologación
            $operationDesc = "homologación"
            $options += "--compare", "size,modtime,checksum", "--resync"

            if (-not [string]::IsNullOrEmpty($HomologationMode)) {
                $options += "--resync-mode", $HomologationMode
            }
        }
        2 { # Sincronización unidireccional
            $operationDesc = "sincronización unidireccional"
        }
    }

    # Construir parámetros de rclone
    $realRemotePath = if ($remoteInfo.RemoteType -eq 'drive') {
        "${RemoteName}:/"
    } else {
        "${RemoteName}:${RemotePath}"
    }

    $parameters = @()
    switch ($OperationType) {
        0 { # bidireccional
            if ($PathPosition -ne 0) {
                $parameters = @("bisync", $LocalPath, $realRemotePath)
            } else {
                $parameters = @("bisync", $realRemotePath, $LocalPath)
            }
        }
        1 { # homologación
            if ($PathPosition -ne 0) {
                $parameters = @("bisync", $LocalPath, $realRemotePath)
            } else {
                $parameters = @("bisync", $realRemotePath, $LocalPath)
            }
        }
        2 { # unidireccional
            if ($PathPosition -ne 0) {
                $parameters = @("sync", $LocalPath, $realRemotePath)
            } else {
                $parameters = @("sync", $realRemotePath, $LocalPath)
            }
        }
    }

    # Mostrar información de la operación
    Write-Host ""
    Write-ColoredMessage "Iniciando la $operationDesc entre Path1" "Cyan" -NoNewline
    if ($PathPosition -ne 0) {
        if ($OperationType -eq 2) {
            Write-ColoredMessage " ('$LocalPath') -> Path2 ($RemotePath) donde solo se modifica el path2." "Gray"
        } else {
            Write-ColoredMessage " ('$LocalPath') <-> Path2 ($RemotePath)" "Gray"
        }
    } else {
        if ($OperationType -eq 2) {
            Write-ColoredMessage " ('$RemotePath') -> Path2 ('$LocalPath') donde solo se modifica el path2." "Gray"
        } else {
            Write-ColoredMessage " ('$RemotePath') <-> Path2 ('$LocalPath')" "Gray"
        }
    }

    $commandLine = "rclone $($parameters -join ' ') $($options -join ' ')"
    Write-ColoredMessage "Ejecutando '$commandLine'" "Gray"

    # Ejecutar el comando
    try {
		& rclone @parameters @options
		#$result = & rclone @parameters @options
        if ($LASTEXITCODE -ne 0) {
            Write-ColoredMessage "Error durante la sincronización. Código de salida: $LASTEXITCODE" "Red"
            return $false
        }
        return $true
    } catch {
        Write-ColoredMessage "Error al ejecutar rclone: $_" "Red"
        return $false
    }
}

function Sync-Folder {
    <#
    .SYNOPSIS
        Sincroniza carpetas locales con Google Drive y OneDrive usando rclone.

    .DESCRIPTION
        Este comando permite realizar sincronización bidireccional, homologación y sincronización unidireccional
        entre carpetas locales y remotos configurados en rclone.

    .PARAMETER VaultSuffix
        Sufijo del vault a sincronizar. Valores válidos: gnote_it, gnote_sciences, etc.

    .PARAMETER OperationType
        Tipo de operación a realizar:
        0 = Sincronización bidireccional (valor por defecto)
        1 = Homologación (previo a sincronización bidireccional)
        2 = Sincronización unidireccional

    .PARAMETER PathPosition
        Posición de las rutas:
        0 = remote -> local (valor por defecto)
        1 = local -> remote

    .PARAMETER DryRun
        Ejecuta en modo test sin realizar cambios reales.

    .PARAMETER Force
        Fuerza los cambios cuando hay muchos archivos modificados (solo para sincronización bidireccional).

    .PARAMETER ConflictWinner
        Determina el ganador en conflictos durante sincronización bidireccional:
        none, newer, older, larger, smaller, path1, path2

    .PARAMETER LosserAction
        Acción para el perdedor en conflictos:
        num, pathname, delete

    .PARAMETER HomologationMode
        Modo de homologación cuando hay archivos en ambas rutas:
        path1, path2, newer, older, larger, smaller

    .EXAMPLE
        Sync-Folder -VaultSuffix "gnote_personal" -OperationType 0

        Realiza sincronización bidireccional para el vault personal de Google Drive.

    .EXAMPLE
        Sync-Folder -VaultSuffix "onote_it" -OperationType 1 -PathPosition 1 -DryRun

        Realiza homologación en modo test desde local a OneDrive para notas de IT.

    .EXAMPLE
        Sync-Folder -VaultSuffix "owork_bp_tasks" -OperationType 2 -PathPosition 0

        Realiza sincronización unidireccional desde OneDrive a local para tareas de trabajo.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if (-not $script:LocalPaths.ContainsKey($_)) {
                throw "VaultSuffix '$_' no válido. Valores válidos: $($script:LocalPaths.Keys -join ', ')"
            }
            return $true
        })]
        [string]$VaultSuffix,

        [Parameter(Position = 1)]
        [ValidateSet(0, 1, 2)]
        [int]$OperationType = 0,

        [Parameter()]
        [ValidateSet(0, 1)]
        [int]$PathPosition = 0,

        [Parameter()]
        [switch]$DryRun,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [ValidateSet("none", "newer", "older", "larger", "smaller", "path1", "path2")]
        [string]$ConflictWinner = "none",

        [Parameter()]
        [ValidateSet("num", "pathname", "delete")]
        [string]$LosserAction = "num",

        [Parameter()]
        [ValidateSet("path1", "path2", "newer", "older", "larger", "smaller")]
        [string]$HomologationMode = "path1"
    )

    # Obtener rutas
    $localPath = $script:LocalPaths[$VaultSuffix]
    $remotePath = $script:RemotePaths[$VaultSuffix]

    if (-not (Test-Path $localPath -PathType Container)) {
        Write-ColoredMessage "El directorio local '$localPath' no existe." "Red"
        return
    }

    # Validar opciones según el tipo de operación
    switch ($OperationType) {
        0 { # Bidireccional
            if ($DryRun -and $Force) {
                Write-ColoredMessage "Advertencia: La opción -Force se ignora en modo test (-DryRun) para sincronización bidireccional." "Yellow"
                $Force = $false
            }
        }
        1 { # Homologación
            if ($Force) {
                Write-ColoredMessage "Advertencia: La opción -Force se ignora para homologación." "Yellow"
                $Force = $false
            }
        }
        2 { # Unidireccional
            if ($Force) {
                Write-ColoredMessage "Advertencia: La opción -Force se ignora para sincronización unidireccional." "Yellow"
                $Force = $false
            }
            if (-not [string]::IsNullOrEmpty($ConflictWinner)) {
                Write-ColoredMessage "Advertencia: La opción -ConflictWinner se ignora para sincronización unidireccional." "Yellow"
                $ConflictWinner = ""
            }
            if (-not [string]::IsNullOrEmpty($LosserAction)) {
                Write-ColoredMessage "Advertencia: La opción -LosserAction se ignora para sincronización unidireccional." "Yellow"
                $LosserAction = ""
            }
        }
    }

    # Ejecutar la sincronización
    $result = Invoke-RcloneSync `
        -RemoteName $VaultSuffix `
        -LocalPath $localPath `
        -RemotePath $remotePath `
        -OperationType $OperationType `
        -PathPosition $PathPosition `
        -DryRun:$DryRun `
        -ConflictWinner $ConflictWinner `
        -LosserAction $LosserAction `
        -Force:$Force `
        -HomologationMode $HomologationMode

    if ($result) {
        Write-ColoredMessage "Sincronización completada exitosamente." "Green"
    } else {
        Write-ColoredMessage "Sincronización fallida. Verifique los errores anteriores." "Red"
    }
}

function Get-SyncFolderHelp {
    Write-ColoredMessage "Usage:" "Yellow"
    Write-ColoredMessage "    Sync-Folder -VaultSuffix <VAULT_SUFIX> [-OperationType <0|1|2>] [options]" "Yellow"
    Write-Host ""
    Write-ColoredMessage "  > Sincronización unidireccional:" "Gray"
    Write-ColoredMessage "    Sync-Folder -VaultSuffix VAULT_SUFIX -OperationType 2 [-PathPosition 0|1] [-DryRun]" "Yellow"
    Write-Host ""
    Write-ColoredMessage "  > Homologación (previo a las sincronización bidireccional):" "Gray"
    Write-ColoredMessage "    Sync-Folder -VaultSuffix VAULT_SUFIX -OperationType 1 [-PathPosition 0|1] [-HomologationMode <mode>] [-DryRun]" "Yellow"
    Write-Host ""
    Write-ColoredMessage "  > Sincronización bidireccional:" "Gray"
    Write-ColoredMessage "    Sync-Folder -VaultSuffix VAULT_SUFIX -OperationType 0 [-PathPosition 0|1] [-ConflictWinner <winner>] [-LosserAction <action>] [-Force] [-DryRun]" "Yellow"
    Write-Host ""
    Write-ColoredMessage "Parámetros:" "Cyan"
    Write-ColoredMessage "  -VaultSuffix     Sufijo de vault a sincronizar/homologar (requerido)" "Gray"
    Write-ColoredMessage "  -OperationType   Tipo de operación: 0=bidireccional (defecto), 1=homologación, 2=unidireccional" "Gray"
    Write-ColoredMessage "  -PathPosition    Dirección de sincronización: 0=remote->local (defecto), 1=local->remote" "Gray"
    Write-ColoredMessage "  -DryRun          Modo test (sin realizar cambios reales)" "Gray"
    Write-ColoredMessage "  -Force           Fuerza cambios cuando hay muchos archivos modificados (solo bidireccional)" "Gray"
    Write-ColoredMessage "  -ConflictWinner  Ganador en conflictos: none, newer, older, larger, smaller, path1, path2" "Gray"
    Write-ColoredMessage "  -LosserAction    Acción para perdedor: num, pathname, delete" "Gray"
    Write-ColoredMessage "  -HomologationMode Modo de homologación: path1, path2, newer, older, larger, smaller" "Gray"
    Write-Host ""
    Write-ColoredMessage "Valores válidos para VaultSuffix:" "Cyan"
    $validVaults = $script:LocalPaths.Keys | Sort-Object
    foreach ($vault in $validVaults) {
        Write-ColoredMessage "  - $vault" "Gray"
    }
}

# Exportar funciones públicas
#Export-ModuleMember -Function Sync-Folder, Get-SyncFolderHelp
