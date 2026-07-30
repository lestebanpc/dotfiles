# Open-NewTerminalTab.psm1

<#
.SYNOPSIS
    Crea una nueva pestaña en WezTerm con el directorio de trabajo especificado.

.DESCRIPTION
    Este módulo permite abrir una nueva pestaña en WezTerm con un directorio de trabajo específico.
    Si se especifica un archivo, puede abrirlo en un editor o mostrar información sobre él.

.PARAMETER Path
    Ruta del archivo o directorio.

.PARAMETER UseDefaultWorkingDirectory
    Si se especifica un archivo, usa el directorio de trabajo actual en lugar del directorio del archivo.

.PARAMETER EditFile
    Si es un archivo, lo abre con el editor configurado ($env:EDITOR) si es de texto,
    o muestra información del archivo si es binario.

.EXAMPLE
    Open-NewTerminalTab "C:\Users\usuario\proyectos"

.EXAMPLE
    Open-NewTerminalTab -Path "C:\Users\usuario\documento.txt" -EditFile

.EXAMPLE
    Open-NewTerminalTab -Path "C:\Users\usuario\archivo.exe" -EditFile

.NOTES
    Requiere WezTerm instalado y disponible en el PATH.
    Para determinar el tipo de archivo, requiere file.exe (disponible en Git for Windows).
#>

using namespace System.Management.Automation

function Open-NewTerminalTab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName", "FilePath")]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$UseDefaultWorkingDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$EditFile
    )

    begin {
        # Colores para mensajes de consola (opcional, para mantener consistencia con el script bash)
        $ColorReset = "`e[0m"
        $ColorRed = "`e[31m"
        $ColorGreen = "`e[32m"
        $ColorYellow = "`e[33m"
        $ColorBlue = "`e[34m"
        $ColorCyan = "`e[36m"
        $ColorGray = "`e[90m"

        # Verificar si estamos en WezTerm
        if ($env:TERM_PROGRAM -ne "WezTerm") {
            Write-Warning "Este comando solo funciona en WezTerm. TERM_PROGRAM actual: $($env:TERM_PROGRAM)"
            return
        }

        # Verificar si WezTerm CLI está disponible
        if (-not (Get-Command "wezterm" -ErrorAction SilentlyContinue)) {
            Write-Error "WezTerm CLI no encontrado. Asegúrate de que WezTerm esté instalado y en el PATH." -Category ResourceUnavailable
            return
        }

        # Verificar si file.exe está disponible (para determinar tipo de archivo)
        if (-not (Get-Command "file.exe" -ErrorAction SilentlyContinue)) {
            Write-Warning "file.exe no encontrado. Se necesita Git for Windows instalado para determinar tipos de archivo."
        }
    }

    process {
        try {
            # Resolver la ruta completa
            $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
            $fullPath = $resolvedPath.Path

            # Determinar si es directorio o archivo
            $item = Get-Item -Path $fullPath -ErrorAction Stop

            if ($item.PSIsContainer) {
                # Es un directorio
                $workingDirectory = $fullPath
                $isFile = $false
                $filePath = $null
                $isTextFile = $false
            }
            else {
                # Es un archivo
                $isFile = $true
                $parentDirectory = $item.DirectoryName
                $fileName = $item.Name

                # Determinar directorio de trabajo
                if ($UseDefaultWorkingDirectory) {
                    # Usar el directorio de trabajo actual del proceso
                    $workingDirectory = (Get-Location).Path
                    $filePath = $fullPath
                }
                else {
                    # Usar el directorio del archivo
                    $workingDirectory = $parentDirectory
                    $filePath = $fileName
                }

                # Determinar si es archivo de texto si se especificó -EditFile
                if ($EditFile) {
                    if (Get-Command "file.exe" -ErrorAction SilentlyContinue) {
                        $fileInfo = file.exe -b -i $fullPath

                        # Verificar si es archivo de texto
                        $isTextFile = ($fileInfo -like "text/*") -or
                                      ($fileInfo -like "application/json*") -or
                                      ($fileInfo -like "inode/x-empty*")

                        Write-Verbose "Tipo MIME del archivo: $fileInfo (Es texto: $isTextFile)"
                    }
                    else {
                        # Si no tenemos file.exe, usar extensión como aproximación
                        $textExtensions = @('.txt', '.ps1', '.py', '.js', '.json', '.xml', '.html', '.css', '.md', '.csv', '.log', '.cfg', '.conf', '.ini')
                        $extension = [System.IO.Path]::GetExtension($fullPath).ToLower()
                        $isTextFile = $textExtensions -contains $extension

                        Write-Verbose "Usando extensión para determinar tipo: $extension (Es texto: $isTextFile)"
                    }
                }
            }

            # Crear nueva pestaña en WezTerm
            Write-Verbose "Creando nueva pestaña en WezTerm con directorio: $workingDirectory"

            # Obtener el directorio de trabajo actual si se solicita (aunque en Windows/WezTerm esto es diferente)
            # WezTerm en Windows no tiene una forma directa de obtener el cwd del panel actual como en Linux
            # Simplemente usamos el directorio determinado arriba

            # Crear nuevo panel/tab
            $newPaneResult = wezterm cli spawn --cwd $workingDirectory 2>$null

            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($newPaneResult)) {
                Write-Error "No se pudo crear la nueva pestaña en WezTerm." -Category OpenError
                return
            }

            # Extraer el ID del panel desde la salida
            # La salida típica es algo como "pane_id:123"
            $paneId = $newPaneResult -replace '.*pane_id:(\d+).*', '$1'

            Write-Verbose "Nuevo panel creado con ID: $paneId"

            # Si es un archivo y se especificó -EditFile, enviar comando
            if ($isFile -and $EditFile) {
                Start-Sleep -Milliseconds 500  # Esperar un momento para que el panel se inicialice

                if ($isTextFile) {
                    # Usar editor configurado o vim por defecto
                    $editor = if ($env:EDITOR) { $env:EDITOR } else { "vim" }
                    $command = "$editor `"$filePath`""
                }
                else {
                    # Para archivos binarios, mostrar información con dir
                    $command = "dir `"$filePath`""
                }

                Write-Verbose "Enviando comando al nuevo panel: $command"
                wezterm cli send-text --pane-id $paneId --no-paste "$command`n"
            }

            Write-Host "${ColorGreen}Nueva pestaña creada exitosamente${ColorReset}" -ForegroundColor Green

        }
        catch [System.Management.Automation.ItemNotFoundException] {
            Write-Error "La ruta '$Path' no existe." -Category ObjectNotFound
        }
        catch {
            Write-Error "Error: $_" -Category OperationStopped
        }
    }

    end {
        # Limpieza si es necesaria
    }
}

function Test-WezTerm {
    <#
    .SYNOPSIS
        Verifica si el entorno actual es WezTerm.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return $env:TERM_PROGRAM -eq "WezTerm" -and (Get-Command "wezterm" -ErrorAction SilentlyContinue)
}

# Exportar funciones públicas
#Export-ModuleMember -Function Open-NewTerminalTab, Test-WezTerm

# Alias para compatibilidad con el script bash
#Set-Alias -Name open_new_termtab -Value Open-NewTerminalTab -Scope Global -ErrorAction SilentlyContinue
#Export-ModuleMember -Alias open_new_termtab
