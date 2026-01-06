<#
.SYNOPSIS
    Ejecuta comandos en paneles WezTerm disponibles o crea nuevos paneles según sea necesario.

.DESCRIPTION
    Este módulo permite ejecutar comandos en paneles WezTerm de manera inteligente:
    - Busca paneles disponibles en la ventana actual (que no ejecuten programas como btop, htop, etc.)
    - Si no encuentra paneles disponibles, crea un nuevo panel horizontal con el porcentaje de altura especificado
    - Siempre mantiene el foco en el panel original después de ejecutar el comando
    - Requiere WezTerm, jq.exe y curl.exe instalados en el sistema

.PARAMETER Command
    Comando a ejecutar en el panel objetivo. Puede ser una cadena o un array de argumentos.

.PARAMETER HeightPercent
    Porcentaje de altura para el nuevo panel horizontal (por defecto: 20).
    Debe estar entre 10 y 90.

.PARAMETER WorkingDirectory
    Directorio de trabajo para el nuevo panel (solo aplica si se crea un nuevo panel).

.PARAMETER ForceNewPanel
    Fuerza la creación de un nuevo panel incluso si hay paneles disponibles.

.PARAMETER VerboseOutput
    Muestra información detallada sobre el proceso de ejecución.

.EXAMPLE
    Invoke-WezTermCommand -Command 'echo "Hola mundo"'
    Ejecuta el comando en un panel disponible o crea uno nuevo con 20% de altura.

.EXAMPLE
    Invoke-WezTermCommand -Command 'dir' -HeightPercent 30 -WorkingDirectory 'C:\Users'
    Crea un panel de 30% de altura en el directorio C:\Users y ejecuta 'dir'.

.EXAMPLE
    'ls -la', '-lh' | Invoke-WezTermCommand
    Ejecuta el comando 'ls -la -lh' usando el pipeline.

.NOTES
    Autor: Asistente IA
    Versión: 1.0
    Requiere: WezTerm, jq.exe, PowerShell 5.1+
    Fecha: 2026-01-05
#>
function Invoke-WezTermCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object[]]$Command,

        [Parameter()]
        [ValidateRange(10, 90)]
        [int]$HeightPercent = 20,

        [Parameter()]
        [string]$WorkingDirectory,

        [Parameter()]
        [switch]$ForceNewPanel,

        [Parameter()]
        [switch]$VerboseOutput
    )

    begin {
        # Configurar colores para la salida
        $script:ColorReset = "`e[0m"
        $script:ColorGreen = "`e[32m"
        $script:ColorYellow = "`e[33m"
        $script:ColorRed = "`e[31m"
        $script:ColorBlue = "`e[34m"
        $script:ColorGray = "`e[90m"

        # Verificar dependencias
        $dependencies = @('wezterm.exe', 'jq.exe')
        foreach ($dep in $dependencies) {
            if (-not (Get-Command $dep -ErrorAction SilentlyContinue)) {
                Write-Host "[$($script:ColorRed)ERROR$($script:ColorReset)] El comando '$dep' no está instalado o no está en PATH."
                Write-Host "[$($script:ColorYellow)INFO$($script:ColorReset)] Por favor instala WezTerm y jq.exe para usar este módulo."
                exit 1
            }
        }

        $commandParts = @()
    }

    process {
        # Acumular los comandos del pipeline
        foreach ($item in $Command) {
            $commandParts += $item
        }
    }

    end {
        try {
            # Construir el comando completo
            $fullCommand = if ($commandParts.Count -eq 1) {
                $commandParts[0]
            } else {
                $commandParts -join ' '
            }

            if ([string]::IsNullOrWhiteSpace($fullCommand)) {
                Write-Host "[$($script:ColorRed)ERROR$($script:ColorReset)] El comando no puede estar vacío."
                return
            }

            Write-Verbose "Comando a ejecutar: $fullCommand"

            # Obtener el panel actual para mantener el foco
            $currentPaneId = & wezterm.exe cli get-active-pane-id 2>$null
            if (-not $currentPaneId) {
                Write-Host "[$($script:ColorRed)ERROR$($script:ColorReset)] No se pudo obtener el ID del panel actual."
                Write-Host "[$($script:ColorYellow)INFO$($script:ColorReset)] Asegúrate de ejecutar este comando dentro de WezTerm."
                return
            }

            Write-Verbose "Panel actual: $currentPaneId"

            # Buscar un panel disponible si no se fuerza un nuevo panel
            $targetPaneId = $null
            if (-not $ForceNewPanel) {
                $targetPaneId = Get-AvailableWezTermPane -CurrentPaneId $currentPaneId -Verbose:($VerbosePreference -eq 'Continue')
            }

            # Si no hay panel disponible o se fuerza un nuevo panel, crear uno
            if (-not $targetPaneId) {
                Write-Host "[$($script:ColorBlue)INFO$($script:ColorReset)] No se encontró panel disponible. Creando nuevo panel horizontal con $($HeightPercent)% de altura..."
                $targetPaneId = New-WezTermHorizontalPane -HeightPercent $HeightPercent -WorkingDirectory $WorkingDirectory -Verbose:($VerbosePreference -eq 'Continue')

                if (-not $targetPaneId) {
                    Write-Host "[$($script:ColorRed)ERROR$($script:ColorReset)] No se pudo crear el nuevo panel."
                    return
                }
            } else {
                Write-Host "[$($script:ColorGreen)INFO$($script:ColorReset)] Usando panel disponible: $targetPaneId"
            }

            # Ejecutar el comando en el panel objetivo
            Write-Verbose "Ejecutando comando en panel $targetPaneId: $fullCommand"
            Execute-CommandInWezTermPane -PaneId $targetPaneId -Command $fullCommand -Verbose:($VerbosePreference -eq 'Continue')

            # Mantener enfocado el panel original
            Write-Verbose "Volviendo al panel original: $currentPaneId"
            & wezterm.exe cli activate-pane --pane-id $currentPaneId 2>$null

            Write-Host "[$($script:ColorGreen)ÉXITO$($script:ColorReset)] Comando ejecutado en el panel $targetPaneId"
        }
        catch {
            Write-Host "[$($script:ColorRed)ERROR$($script:ColorReset)] Error durante la ejecución: $($_.Exception.Message)"
            Write-Debug $_.ScriptStackTrace
        }
    }
}

<#
.SYNOPSIS
    Obtiene un panel WezTerm disponible en la ventana actual.

.DESCRIPTION
    Busca paneles en la ventana actual que no estén ejecutando programas considerados "ocupados"
    como btop, htop, vim, etc. Excluye el panel actual.

.PARAMETER CurrentPaneId
    ID del panel actual para excluirlo de la búsqueda.

.OUTPUTS
    System.String - ID del panel disponible o $null si no hay ninguno.
#>
function Get-AvailableWezTermPane {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CurrentPaneId
    )

    try {
        # Obtener información de todos los paneles en formato JSON
        $paneInfoJson = & wezterm.exe cli list --format json 2>$null
        if (-not $paneInfoJson) {
            Write-Verbose "No se pudo obtener información de los paneles."
            return $null
        }

        $paneInfo = $paneInfoJson | ConvertFrom-Json
        $windowId = $paneInfo.active_window_id

        # Programas que consideramos "ocupados"
        $busyPrograms = @('btop', 'htop', 'nvim', 'vim', 'tmux', 'ssh', 'docker', 'python', 'node', 'less', 'more', 'man', 'top', 'powershell', 'cmd.exe', 'explorer.exe')

        # Buscar paneles en la misma ventana
        foreach ($pane in $paneInfo.panes) {
            if ($pane.window_id -ne $windowId) { continue }
            if ($pane.pane_id -eq $CurrentPaneId) { continue }

            $isAvailable = $true

            # Verificar procesos en primer plano
            foreach ($process in $pane.foreground_processes) {
                $processName = $process.name.ToLower()

                foreach ($busyProgram in $busyPrograms) {
                    if ($processName -like "*$busyProgram*") {
                        Write-Verbose "Panel $($pane.pane_id) está ocupado ejecutando: $processName"
                        $isAvailable = $false
                        break
                    }
                }
                if (-not $isAvailable) { break }
            }

            if ($isAvailable) {
                Write-Verbose "Panel disponible encontrado: $($pane.pane_id)"
                return $pane.pane_id
            }
        }

        Write-Verbose "No se encontraron paneles disponibles."
        return $null
    }
    catch {
        Write-Verbose "Error al buscar paneles disponibles: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Crea un nuevo panel horizontal en WezTerm.

.DESCRIPTION
    Crea un panel horizontal en la parte superior de la ventana actual con el porcentaje de altura especificado.

.PARAMETER HeightPercent
    Porcentaje de altura para el nuevo panel (10-90).

.PARAMETER WorkingDirectory
    Directorio de trabajo para el nuevo panel.

.OUTPUTS
    System.String - ID del nuevo panel creado o $null si falla.
#>
function New-WezTermHorizontalPane {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(10, 90)]
        [int]$HeightPercent,

        [Parameter()]
        [string]$WorkingDirectory
    )

    try {
        # Crear el panel horizontal
        $splitArgs = @('cli', 'split-pane', '--top', '--percent', $HeightPercent.ToString())

        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
            $splitArgs += @('--cwd', $WorkingDirectory)
        }

        $null = & wezterm.exe @splitArgs 2>$null

        # Obtener el ID del nuevo panel (el último en la lista)
        $paneInfoJson = & wezterm.exe cli list --format json 2>$null
        if (-not $paneInfoJson) {
            return $null
        }

        $paneInfo = $paneInfoJson | ConvertFrom-Json
        $newPaneId = $paneInfo.panes[-1].pane_id

        Write-Verbose "Nuevo panel creado con ID: $newPaneId"
        return $newPaneId
    }
    catch {
        Write-Verbose "Error al crear panel: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Ejecuta un comando en un panel WezTerm específico.

.DESCRIPTION
    Envía un comando a un panel WezTerm específico y lo ejecuta.

.PARAMETER PaneId
    ID del panel donde se ejecutará el comando.

.PARAMETER Command
    Comando a ejecutar.

.OUTPUTS
    None
#>
function Execute-CommandInWezTermPane {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PaneId,

        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    try {
        # Enviar el comando al panel
        $null = & wezterm.exe cli send-text --pane-id $PaneId $Command 2>$null

        # Enviar Enter para ejecutar el comando
        $null = & wezterm.exe cli send-text --pane-id $PaneId "`n" 2>$null

        Write-Verbose "Comando enviado al panel $PaneId: $Command"
    }
    catch {
        Write-Verbose "Error al ejecutar comando en panel $PaneId: $($_.Exception.Message)"
    }
}

# Exportar las funciones públicas
#Export-ModuleMember -Function Invoke-WezTermCommand
