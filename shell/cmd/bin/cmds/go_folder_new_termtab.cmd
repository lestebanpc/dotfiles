@echo off
setlocal enabledelayedexpansion

::echo Argumentos recibidos: %*


:: #####################################################################
:: Configuración inicial
:: #####################################################################

:: Si se ejecuta en una terminal que soporta colores (Windows Terminal/WezTerm)
if not "%WT_SESSION%"=="" (
    for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
    set "color_red=%ESC%[91m"
    set "color_green=%ESC%[92m"
    set "color_gray=%ESC%[90m"
	set "color_yellow=%ESC%[33m"
    set "color_reset=%ESC%[0m"
) else (
    set "color_red="
    set "color_green="
	set "color_green="
    set "color_yellow="
    set "color_reset="
)


goto :MAIN



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
echo   - Calculado por '-p' ^(1: directorio actual, 2: directorio del archivo/folder^)
echo   - Si no se especifica, no se establece directorio
echo.
echo Solo soporta WezTerm en Windows.
echo.
echo OPCIONES:
echo   -p 1^|2        Calcula directorio automaticamente:
echo                  1: Usa directorio actual del panel de WezTerm
echo                  2: Usa directorio del archivo/folder especificado
echo.
echo   -w ^<path^>    Directorio de trabajo especifico ^(prioridad sobre -p^)
echo.
echo   -h             Muestra esta ayuda
echo.
echo ARGUMENTO:
echo   ruta           Ruta de un folder o archivo ^(absoluta o relativa^)
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
    echo [!color_red!ERROR!color_reset!] Este script solo funciona dentro de WezTerm.
    exit /b 1
)

:: Verificar wezterm CLI
where wezterm >nul 2>&1
if errorlevel 1 (
    echo [!color_red!ERROR!color_reset!] WezTerm CLI no está instalado o no está en el PATH.
    exit /b 1
)

:: Verificar jq
::where jq >nul 2>&1
::if errorlevel 1 (
::    echo [!color_red!ERROR!color_reset!] jq.exe no encontrado. Necesario para procesar JSON.
::    echo Instale jq o agreguelo al PATH.
::    exit /b 1
::)

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
::if not "!PANE_ID!"=="" (
::    set "PANE_ID=!PANE_ID:~0,-1!"
::)
exit /b 0

:: ---------------------------------------------------------------------
:: Enviar comando a panel de WezTerm
:: Parámetros: %1=ID del panel, Variable global 'COMMAND_TO_EXEC'
:: ---------------------------------------------------------------------
:SEND_TO_PANE
set "TARGET_PANE=%~1"
if "!TARGET_PANE!"=="" exit /b 1

echo "COMMAND: !COMMAND_TO_EXEC!"
:: El echo envian un fin de linea la cual se interpreta como enter y ejecuta el comando.
echo(%COMMAND_TO_EXEC% | wezterm.exe cli send-text --pane-id !TARGET_PANE! --no-paste

exit /b 0



:: #####################################################################
:: Codigo Principal del scrtpt
:: #####################################################################
:MAIN

:: ---------------------------------------------------------------------
:: Procesamiento de argumentos
:: ---------------------------------------------------------------------
set "OPTION_P="
set "OPTION_W="
set "WORKING_DIR="
set "WORKING_DIR_SRC=3"  :: 0=-w, 1=-p 1, 2=-p 2, 3=ninguno

echo "ok1"

:: Procesar opciones
:PARSE_ARGS_LOOP

:: Copiamos los parámetros a variables normales para evitar % con bloques y SHIFT
set "ARG=%~1"
set "VAL=%~2"

echo "arg: !ARG!, val: !VAL!"
if not defined ARG goto :ARGS_DONE

:: -h / ayuda
if /I "!ARG!"=="-h" (
    call :USAGE
    exit /b 0
)

:: -p <1|2>
if /I "!ARG!"=="-p" (
    echo "ok2"
    if "!VAL!"=="" (
        echo [ERROR] Opcion -p requiere un valor ^(1 o 2^)
        exit /b 1
    )
    if /I not "!VAL!"=="1" if /I not "!VAL!"=="2" (
        echo [ERROR] Valor invalido para -p: !VAL! ^(debe ser 1 o 2^)
        exit /b 1
    )
    if /I "!VAL!"=="1" set "OPTION_P=1" & set "WORKING_DIR_SRC=1"
    if /I "!VAL!"=="2" set "OPTION_P=2" & set "WORKING_DIR_SRC=2"
    shift & shift
    goto :PARSE_ARGS_LOOP
)

:: -w <path>
if /I "!ARG!"=="-w" (
    if "!VAL!"=="" (
        echo [ERROR] Opcion -w requiere un directorio
        exit /b 1
    )
    if not exist "!VAL!\\" (
        echo [ERROR] Directorio no existe: !VAL!
        exit /b 1
    )
    set "OPTION_W=!VAL!"
    set "WORKING_DIR_SRC=0"
    shift & shift
    goto :PARSE_ARGS_LOOP
)

:: -- fin de opciones
if /I "!ARG!"=="--" (
    shift
    goto :ARGS_DONE
)

:: Opcion desconocida: primer caracter '-'
if "!ARG:~0,1!"=="-" (
    echo [ERROR] Opcion desconocida: !ARG!
    call :USAGE
    exit /b 1
)


:: Es la ruta de entrada
set "INPUT_PATH=%~1"
shift
goto :PARSE_ARGS_LOOP

:ARGS_DONE

echo "OPTION_P: !OPTION_P!"
echo "OPTION_W: !OPTION_W!"
echo "INPUT_PATH: !INPUT_PATH!"
echo "WORKING_DIR: !WORKING_DIR!"
echo "WORKING_DIR_SRC: !WORKING_DIR_SRC!"

:: Verificar que tenemos una ruta
if "!INPUT_PATH!"=="" (
    echo [!color_red!ERROR!color_reset!] Debe especificar una ruta de folder o archivo.
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
echo [!color_gray!INFO!color_reset!] Procesando ruta: !INPUT_PATH!

:: Obtener ruta absoluta
set "FULL_PATH="
for %%F in ("!INPUT_PATH!") do set "FULL_PATH=%%~fF"
echo "FULL_PATH: !FULL_PATH!"

:: Determinar si es folder o archivo
set "IS_FOLDER=1"
set "FOLDER_PATH=!FULL_PATH!"

if exist "!FULL_PATH!\" (
    set "IS_FOLDER=0"
) else if not exist "!FULL_PATH!" (
    echo [!color_red!ERROR!color_reset!] La ruta no existe: !FULL_PATH!
    exit /b 6
)

if !IS_FOLDER! equ 1 (
    :: Es archivo, obtener directorio padre
    for %%F in ("!FULL_PATH!") do set "FOLDER_PATH=%%~dpF"
    :: Quitar la barra final
    if "!FOLDER_PATH:~-1!"=="\" set "FOLDER_PATH=!FOLDER_PATH:~0,-1!"
)

echo [!color_gray!INFO!color_reset!] Ruta procesada: !FULL_PATH!
echo [!color_gray!INFO!color_reset!] Directorio base: !FOLDER_PATH!
echo [!color_gray!INFO!color_reset!] Es folder: !IS_FOLDER!

:: ---------------------------------------------------------------------
:: Determinar directorio de trabajo
:: ---------------------------------------------------------------------
if !WORKING_DIR_SRC! equ 0 (
    :: Usar directorio especificado con -w
    set "WORKING_DIR=!OPTION_W!"
    echo [!color_gray!INFO!color_reset!] Usando directorio especificado: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 1 (
    :: Obtener directorio actual de WezTerm
    call :GET_WEZTERM_WORKDIR "WORKING_DIR"
    echo [!color_gray!INFO!color_reset!] Usando directorio actual WezTerm: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 2 (
    :: Usar directorio del archivo/folder
    set "WORKING_DIR=!FOLDER_PATH!"
    echo [!color_gray!INFO!color_reset!] Usando directorio del argumento: !WORKING_DIR!
) else (
    :: No especificar directorio
    set "WORKING_DIR="
    echo [!color_gray!INFO!color_reset!] Sin directorio especifico
)

echo "WORKING_DIR: !WORKING_DIR!"

:: ---------------------------------------------------------------------
:: Construir comando a ejecutar siempre que sea necesario
:: ---------------------------------------------------------------------
set "COMMAND_TO_EXEC="

:: Si el directorio de trabajo no es el mismo que FOLDER_PATH
if not "!WORKING_DIR!"=="" (

	if /i not "!WORKING_DIR!"=="!FOLDER_PATH!" (
       :: Calcular ruta relativa
       set "REL_PATH=!FOLDER_PATH!"
       set "REL_PATH=!REL_PATH:%WORKING_DIR%\=!"
	   echo "REL_PATH: !REL_PATH!"

       if not "!REL_PATH!"=="!FOLDER_PATH!" (
           set "COMMAND_TO_EXEC=cd "!REL_PATH!""
	   )
       else (
           :: Si no es subdirectorio, usar ruta absoluta
           set "COMMAND_TO_EXEC=cd "!FOLDER_PATH!""
       )

	)

) else (

    :: Calcular ruta relativa
    set "COMMAND_TO_EXEC=cd "!FOLDER_PATH!""
)

echo [!color_gray!INFO!color_reset!] Comando a ejecutar: !COMMAND_TO_EXEC!

:: ---------------------------------------------------------------------
:: Crear panel y ejecutar comando
:: ---------------------------------------------------------------------

:: 1. Crear nuevo panel
set "PANE_ID="
call :CREATE_WEZTERM_PANE "!WORKING_DIR!"
if "!PANE_ID!"=="" (
    echo [!color_red!ERROR!color_reset!] No se pudo crear panel en WezTerm
    exit /b 1
)

echo [!color_green!OK!color_reset!] Panel creado con ID: !PANE_ID!

:: 2. Ejecutar comando en el panel (si hay comando)
if not "!COMMAND_TO_EXEC!"=="" (
    call :SEND_TO_PANE "!PANE_ID!"
    if errorlevel 1 (
        echo [!color_yellow!WARN!color_reset!] No se pudo ejecutar comando en el panel
    ) else (
        echo [!color_green!OK!color_reset!] Comando ejecutado: !COMMAND_TO_EXEC!
    )
) else (
    echo [!color_gray!INFO!color_reset!] No se requiere comando adicional
)

echo [!color_green!OK!color_reset!] Proceso completado exitosamente
exit /b 0

:: ---------------------------------------------------------------------
:: Manejo de errores
:: ---------------------------------------------------------------------
:ERROR
echo [!color_red!ERROR!color_reset!] Error inesperado en la ejecucion
exit /b 99
