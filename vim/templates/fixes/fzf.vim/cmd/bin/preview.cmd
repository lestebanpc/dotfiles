:: Limitaciones respecto a 'preview.ps1'
:: > No soporta el formato completo FILENAME:LINENO:IGNORED como el script original
:: > No maneja expansiones de ~/ para directorios home
:: > No normaliza barras en rutas (no convierte / a )
:: > No valida si lineno es numérico
:: > No maneja rutas con unidades de disco en el formato original
:: > Parsing de argumentos muy básico comparado con el regex de PowerShell

@echo off
if "%~1"=="" (
    echo usage: %~nx0 FILENAME[:LINENO]
    exit /b 1
)

set "arg=%~1"
set "file="
set "lineno=0"
set "batcmd="

:: Intentar extraer filename y lineno (versión simplificada)
for /f "tokens=1,2 delims=:" %%a in ("%arg%") do (
    set "file=%%a"
    if not "%%b"=="" set "lineno=%%b"
)

:: Verificar si el archivo existe
if not exist "%file%" (
    echo File not found %file%
    exit /b 1
)

:: Buscar comando bat o batcat
where batcat >nul 2>&1
if %errorlevel%==0 (
    set "batcmd=batcat"
) else (
    where bat >nul 2>&1
    if %errorlevel%==0 (
        set "batcmd=bat"
    ) else (
        echo bat or batcat not found in PATH
        exit /b 1
    )
)

:: Obtener estilo de BAT_STYLE o usar default
if defined BAT_STYLE (
    set "batstyle=%BAT_STYLE%"
) else (
    set "batstyle=numbers"
)

:: Ejecutar el comando
%batcmd% --style="%batstyle%" --color=always --pager=never --highlight-line=%lineno% "%file%"
