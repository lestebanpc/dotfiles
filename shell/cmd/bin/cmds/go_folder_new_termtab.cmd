@echo off
setlocal enabledelayedexpansion



:: #####################################################################
:: Configuración inicial y colores
:: #####################################################################

:: Inicializar variables de color
set "COLOR_RESET="
set "COLOR_GREEN="
set "COLOR_GRAY="
set "COLOR_CYAN="
set "COLOR_YELLOW="
set "COLOR_RED="
set "COLOR_BLUE="

:: Detectar terminal con soporte de colores (Windows Terminal/WezTerm)
if not "%WT_SESSION%"=="" (
    for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
    set "COLOR_RESET=!ESC![0m"
    set "COLOR_GREEN=!ESC![32m"
    set "COLOR_GRAY=!ESC![90m"
    set "COLOR_CYAN=!ESC![36m"
    set "COLOR_YELLOW=!ESC![33m"
    set "COLOR_RED=!ESC![31m"
    set "COLOR_BLUE=!ESC![34m"
)




:: #####################################################################
:: Funciones de utilidad
:: #####################################################################

:: ---------------------------------------------------------------------
:: Mostrar uso del script
:: ---------------------------------------------------------------------
:USAGE
echo.
echo USO: go_folder_new_termtab.cmd [opciones] ruta
echo.
echo Crea una nueva ventana/tab en WezTerm con un nuevo panel cuyo directorio
echo de trabajo se calcula segun prioridad:
echo   - Directorio especificado por '-w'
echo   - Calculado por '-p' (1: directorio actual, 2: directorio del archivo/folder)
echo   - Si no se especifica, no se establece directorio
echo.
echo Solo soporta WezTerm en Windows.
echo.
echo OPCIONES:
echo   -p 1^|2        Calcula directorio automaticamente:
echo                  1: Usa directorio actual del panel de WezTerm
echo                  2: Usa directorio del archivo/folder especificado
echo.
echo   -w ^<path^>    Directorio de trabajo especifico (prioridad sobre -p)
echo.
echo   -h             Muestra esta ayuda
echo.
echo ARGUMENTO:
echo   ruta           Ruta de un folder o archivo (absoluta o relativa)
echo.
echo EJEMPLOS:
echo   go_folder_new_termtab.cmd ..
echo   go_folder_new_termtab.cmd C:\code
echo   go_folder_new_termtab.cmd C:\code\mynote.txt
echo   go_folder_new_termtab.cmd -p 1 C:\code
echo   go_folder_new_termtab.cmd -w "C:\work" "C:\work\project"
echo.
exit /b 0

:: ---------------------------------------------------------------------
:: Verificar WezTerm y dependencias
:: ---------------------------------------------------------------------
:CHECK_DEPENDENCIES
:: Verificar WezTerm
if "%TERM_PROGRAM%" neq "WezTerm" (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] Este script solo funciona dentro de WezTerm.
    exit /b 1
)

:: Verificar wezterm CLI
where wezterm >nul 2>&1
if errorlevel 1 (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] WezTerm CLI no está instalado o no está en el PATH.
    exit /b 1
)

:: Verificar jq
where jq >nul 2>&1
if errorlevel 1 (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] jq.exe no encontrado. Necesario para procesar JSON.
    echo Instale jq o agreguelo al PATH.
    exit /b 1
)

exit /b 0


:: ---------------------------------------------------------------------
:: Obtener directorio de trabajo actual de WezTerm
:: Retorna el directorio en variable WORKDIR
:: ---------------------------------------------------------------------
:GET_WEZTERM_WORKDIR
set "WORKDIR="

:: Obtener el directorio de trabajo del panel actual de Wezterm
set "l_data="
for /f "delims=" %%a in ('wezterm cli list --format json ^| jq -r --arg pid "!WEZTERM_PANE!" ".[] | select(.pane_id == ($pid | tonumber)) | .cwd"') do (
    set "l_data=%%a"
)

:: Verificar si l_data está vacío
if "!l_data!"=="" (
    ::set "WORKDIR=%CD%"
    exit /b 2
)
echo [%color_gray%INFO%color_reset%] Current WorkingDir : !l_data!

:: Extraer la parte del directorio de la URL (similar a sed)
set "l_str="
set "l_working_dir="
if "!l_data:~0,7!"=="file://" (

    set "l_str=!l_data:file://=!"
    if "!l_str:~0,1!"=="/" (
        set "l_working_dir=!l_str:~1!"
    ) else (
        for /f "delims=/ tokens=1*" %%a in ("!l_str!") do (
            set "l_working_dir=%%b"
        )
    )

)

:: Verificar si l_data está vacío
if "!l_working_dir!"=="" (
    ::set "WORKDIR=%CD%"
    exit /b 2
)

set "WORKDIR=!l_working_dir!"
echo [%color_gray%INFO%color_reset%] Current WorkingDir : !l_working_dir!
exit /b 0


:: ---------------------------------------------------------------------
:: Crear nuevo panel en WezTerm
:: Parámetros: %1=directorio de trabajo (opcional)
:: Retorna: PANE_ID contiene el ID del panel creado
:: ---------------------------------------------------------------------
:CREATE_WEZTERM_PANE
set "PANEDIR=%~1"
set "PANE_ID="

if "!PANEDIR!"=="" (
    for /f "tokens=*" %%P in ('wezterm.exe cli spawn 2^>nul') do set "PANE_ID=%%P"
) else (
    for /f "tokens=*" %%P in ('wezterm.exe cli spawn --cwd "!PANEDIR!" 2^>nul') do set "PANE_ID=%%P"
)

:: Limpiar posibles retornos de carro
if not "!PANE_ID!"=="" (
    set "PANE_ID=!PANE_ID:~0,-1!"
)
exit /b 0

:: ---------------------------------------------------------------------
:: Enviar comando a panel de WezTerm
:: Parámetros: %1=ID del panel, %2=comando a ejecutar
:: ---------------------------------------------------------------------
:SEND_TO_PANE
set "TARGET_PANE=%~1"
set "COMMAND=%~2"

if "!TARGET_PANE!"=="" exit /b 1

:: Limpiar pantalla primero
wezterm.exe cli send-text --pane-id !TARGET_PANE! --no-paste "clear"
wezterm.exe cli send-text --pane-id !TARGET_PANE! --no-paste "!COMMAND!"
exit /b 0

:: ---------------------------------------------------------------------
:: Obtener ruta absoluta (simulación de realpath)
:: Parámetros: %1=ruta de entrada, %2=variable para retornar ruta absoluta
:: ---------------------------------------------------------------------
:GET_ABSOLUTE_PATH
set "INPUT_PATH=%~1"
set "RETURN_VAR=%~2"
set "ABS_PATH="

:: Si la ruta ya es absoluta (comienza con letra de unidad o \)
echo !INPUT_PATH! | findstr /r "^[A-Za-z]:\\" >nul
if not errorlevel 1 (
    set "ABS_PATH=!INPUT_PATH!"
    goto :RETURN_ABS_PATH
)

echo !INPUT_PATH! | findstr /r "^\\\\" >nul
if not errorlevel 1 (
    set "ABS_PATH=!INPUT_PATH!"
    goto :RETURN_ABS_PATH
)

:: Convertir ruta relativa a absoluta
pushd .
cd /d "!INPUT_PATH!" >nul 2>&1
if not errorlevel 1 (
    set "ABS_PATH=!CD!"
    popd
) else (
    popd
    :: Intentar otra estrategia
    for %%F in ("!INPUT_PATH!") do (
        set "ABS_PATH=%%~fF"
    )
)

:RETURN_ABS_PATH
if "!ABS_PATH!"=="" set "ABS_PATH=!INPUT_PATH!"
set "!RETURN_VAR!=!ABS_PATH!"
exit /b 0



:: #####################################################################
:: Código Principal
:: #####################################################################

:: ---------------------------------------------------------------------
:: Procesamiento de argumentos
:: ---------------------------------------------------------------------
set "OPTION_P="
set "OPTION_W="
set "WORKING_DIR="
set "WORKING_DIR_SRC=3"  :: 0=-w, 1=-p 1, 2=-p 2, 3=ninguno
set "INPUT_PATH="

:: Procesar opciones
:PARSE_ARGS_LOOP
if "%1"=="" goto :ARGS_DONE

if /i "%1"=="-h" (
    call :USAGE
    exit /b 0
)

if /i "%1"=="-p" (
    if "%2"=="1" set "OPTION_P=1" & set "WORKING_DIR_SRC=1"
    if "%2"=="2" set "OPTION_P=2" & set "WORKING_DIR_SRC=2"
    if "%2"=="" (
        echo [!COLOR_RED!ERROR!COLOR_RESET!] Opcion -p requiere un valor (1 o 2)
        exit /b 1
    )
    if not "%2"=="1" if not "%2"=="2" (
        echo [!COLOR_RED!ERROR!COLOR_RESET!] Valor invalido para -p: %2 (debe ser 1 o 2)
        exit /b 1
    )
    shift & shift
    goto :PARSE_ARGS_LOOP
)

if /i "%1"=="-w" (
    if "%2"=="" (
        echo [!COLOR_RED!ERROR!COLOR_RESET!] Opcion -w requiere un directorio
        exit /b 1
    )
    if not exist "%2\" (
        echo [!COLOR_RED!ERROR!COLOR_RESET!] Directorio no existe: %2
        exit /b 1
    )
    set "OPTION_W=%~2"
    set "WORKING_DIR_SRC=0"
    shift & shift
    goto :PARSE_ARGS_LOOP
)

if "%1:~0,1%"=="-" (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] Opcion desconocida: %1
    call :USAGE
    exit /b 1
)

:: Es la ruta de entrada
set "INPUT_PATH=%~1"
shift
goto :PARSE_ARGS_LOOP

:ARGS_DONE

:: Verificar que tenemos una ruta
if "!INPUT_PATH!"=="" (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] Debe especificar una ruta de folder o archivo.
    call :USAGE
    exit /b 4
)

:: ---------------------------------------------------------------------
:: Validaciones iniciales
:: ---------------------------------------------------------------------
call :CHECK_DEPENDENCIES
if errorlevel 1 exit /b 1

:: ---------------------------------------------------------------------
:: Procesar la ruta de entrada
:: ---------------------------------------------------------------------
echo [!COLOR_GRAY!INFO!COLOR_RESET!] Procesando ruta: !INPUT_PATH!

:: Obtener ruta absoluta
call :GET_ABSOLUTE_PATH "!INPUT_PATH!" "FULL_PATH"
if "!FULL_PATH!"=="" (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] No se pudo obtener ruta absoluta: !INPUT_PATH!
    exit /b 5
)

:: Determinar si es folder o archivo
set "IS_FOLDER=1"
set "FOLDER_PATH=!FULL_PATH!"

if exist "!FULL_PATH!\" (
    set "IS_FOLDER=0"
) else if not exist "!FULL_PATH!" (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] La ruta no existe: !FULL_PATH!
    exit /b 6
)

if !IS_FOLDER! equ 1 (
    :: Es archivo, obtener directorio padre
    for %%F in ("!FULL_PATH!") do set "FOLDER_PATH=%%~dpF"
    :: Quitar la barra final
    if "!FOLDER_PATH:~-1!"=="\" set "FOLDER_PATH=!FOLDER_PATH:~0,-1!"
)

echo [!COLOR_GRAY!INFO!COLOR_RESET!] Ruta procesada: !FULL_PATH!
echo [!COLOR_GRAY!INFO!COLOR_RESET!] Directorio base: !FOLDER_PATH!
echo [!COLOR_GRAY!INFO!COLOR_RESET!] Es folder: !IS_FOLDER!

:: ---------------------------------------------------------------------
:: Determinar directorio de trabajo
:: ---------------------------------------------------------------------
if !WORKING_DIR_SRC! equ 0 (
    :: Usar directorio especificado con -w
    set "WORKING_DIR=!OPTION_W!"
    echo [!COLOR_GRAY!INFO!COLOR_RESET!] Usando directorio especificado: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 1 (
    :: Obtener directorio actual de WezTerm
    call :GET_WEZTERM_WORKDIR "WORKING_DIR"
    echo [!COLOR_GRAY!INFO!COLOR_RESET!] Usando directorio actual WezTerm: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 2 (
    :: Usar directorio del archivo/folder
    set "WORKING_DIR=!FOLDER_PATH!"
    echo [!COLOR_GRAY!INFO!COLOR_RESET!] Usando directorio del argumento: !WORKING_DIR!
) else (
    :: No especificar directorio
    set "WORKING_DIR="
    echo [!COLOR_GRAY!INFO!COLOR_RESET!] Sin directorio especifico
)

:: ---------------------------------------------------------------------
:: Construir comando CD si es necesario
:: ---------------------------------------------------------------------
set "CD_COMMAND="

if not "!WORKING_DIR!"=="" (
    :: Si el directorio de trabajo no es el mismo que FOLDER_PATH
    if /i not "!WORKING_DIR!"=="!FOLDER_PATH!" (
        :: Calcular ruta relativa
        set "REL_PATH=!FOLDER_PATH!"
        set "REL_PATH=!REL_PATH:%WORKING_DIR%\=!"

        if not "!REL_PATH!"=="!FOLDER_PATH!" (
            set "CD_COMMAND=cd /d "!REL_PATH!""
        else (
            :: Si no es subdirectorio, usar ruta absoluta
            set "CD_COMMAND=cd /d "!FOLDER_PATH!""
        )
    )
)

echo [!COLOR_GRAY!INFO!COLOR_RESET!] Comando a ejecutar: !CD_COMMAND!

:: ---------------------------------------------------------------------
:: Crear panel y ejecutar comando
:: ---------------------------------------------------------------------

:: 1. Crear nuevo panel
call :CREATE_WEZTERM_PANE "!WORKING_DIR!" "NEW_PANE_ID"
if "!NEW_PANE_ID!"=="" (
    echo [!COLOR_RED!ERROR!COLOR_RESET!] No se pudo crear panel en WezTerm
    exit /b 1
)

echo [!COLOR_GREEN!OK!COLOR_RESET!] Panel creado con ID: !NEW_PANE_ID!

:: 2. Ejecutar comando en el panel (si hay comando)
if not "!CD_COMMAND!"=="" (
    call :SEND_TO_PANE "!NEW_PANE_ID!" "!CD_COMMAND!"
    if errorlevel 1 (
        echo [!COLOR_YELLOW!WARN!COLOR_RESET!] No se pudo ejecutar comando en el panel
    ) else (
        echo [!COLOR_GREEN!OK!COLOR_RESET!] Comando ejecutado: !CD_COMMAND!
    )
) else (
    echo [!COLOR_GRAY!INFO!COLOR_RESET!] No se requiere comando adicional
)

:: 3. Enviar Enter para asegurar ejecución
wezterm cli send-text --pane-id !NEW_PANE_ID! --no-paste "" >nul 2>&1

echo [!COLOR_GREEN!OK!COLOR_RESET!] Proceso completado exitosamente
exit /b 0

:: ---------------------------------------------------------------------
:: Manejo de errores
:: ---------------------------------------------------------------------
:ERROR
echo [!COLOR_RED!ERROR!COLOR_RESET!] Error inesperado en la ejecucion
exit /b 99
