@echo off
setlocal enabledelayedexpansion

rem echo Argumentos recibidos: %*


rem #####################################################################
rem Configuración inicial
rem #####################################################################

rem Si se ejecuta en una terminal que soporta colores (Windows Terminal/WezTerm)
if not "%WT_SESSION%"=="" (
  set "ANSI_OK=1"
) else if /i "%TERM_PROGRAM%"=="WezTerm" (
  set "ANSI_OK=1"
) else (
  set "ANSI_OK="
)

rem if defined ANSI_OK (
rem   for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
rem   set "color_red=%ESC%[91m"
rem   set "color_green=%ESC%[92m"
rem   set "color_gray=%ESC%[90m"
rem   set "color_yellow=%ESC%[33m"
rem   set "color_reset=%ESC%[0m"
rem ) else (
  set "color_red="
  set "color_green="
  set "color_gray="
  set "color_yellow="
  set "color_reset="
rem )


goto :MAIN



rem #####################################################################
rem Funciones de utilidad
rem #####################################################################

rem ---------------------------------------------------------------------
rem Mostrar uso del script
rem ---------------------------------------------------------------------
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

rem ---------------------------------------------------------------------
rem Verificar WezTerm y dependencias
rem ---------------------------------------------------------------------
:CHECK_DEPENDENCIES
rem Verificar WezTerm
if "%TERM_PROGRAM%" neq "WezTerm" (
    echo [!color_red!ERROR!color_reset!] Este script solo funciona dentro de WezTerm.
    exit /b 1
)

rem Verificar wezterm CLI
where wezterm >nul 2>&1
if errorlevel 1 (
    echo [!color_red!ERROR!color_reset!] WezTerm CLI no está instalado o no está en el PATH.
    exit /b 1
)

rem Verificar jq
rem where jq >nul 2>&1
rem if errorlevel 1 (
rem     echo [!color_red!ERROR!color_reset!] jq.exe no encontrado. Necesario para procesar JSON.
rem     echo Instale jq o agreguelo al PATH.
rem     exit /b 1
rem )

exit /b 0



rem ---------------------------------------------------------------------
rem Obtener directorio de trabajo actual de WezTerm
rem Retorna el directorio en variable WORKDIR
rem ---------------------------------------------------------------------
:GET_WEZTERM_WORKDIR
set "WORKDIR="

rem Obtener el directorio de trabajo del panel actual de Wezterm
set "l_data="
for /f "delims=" %%a in ('wezterm cli list --format json ^| jq -r --arg pid "!WEZTERM_PANE!" ".[] | select(.pane_id == ($pid | tonumber)) | .cwd"') do (
    set "l_data=%%a"
)

rem Verificar si l_data está vacío
if "!l_data!"=="" (
    rem set "WORKDIR=%CD%"
    exit /b 2
)
echo [%color_gray%INFO%color_reset%] Current WorkingDir : !l_data!

rem Extraer la parte del directorio de la URL (similar a sed)
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

rem Verificar si l_data está vacío
if "!l_working_dir!"=="" (
    rem set "WORKDIR=%CD%"
    exit /b 2
)

set "WORKDIR=!l_working_dir!"
echo [%color_gray%INFO%color_reset%] Current WorkingDir : !l_working_dir!
exit /b 0


rem ---------------------------------------------------------------------
rem Crear nuevo panel en WezTerm
rem Parámetros: %1=directorio de trabajo (opcional)
rem Retorna: PANE_ID contiene el ID del panel creado
rem ---------------------------------------------------------------------
:CREATE_WEZTERM_PANE
set "PANEDIR=%~1"
set "PANE_ID="

if "!PANEDIR!"=="" (
    for /f "tokens=*" %%P in ('wezterm.exe cli spawn 2^>nul') do set "PANE_ID=%%P"
) else (
    for /f "tokens=*" %%P in ('wezterm.exe cli spawn --cwd "!PANEDIR!" 2^>nul') do set "PANE_ID=%%P"
)

rem Limpiar posibles retornos de carro
rem if not "!PANE_ID!"=="" (
rem     set "PANE_ID=!PANE_ID:~0,-1!"
rem )
exit /b 0

rem ---------------------------------------------------------------------
rem Enviar comando a panel de WezTerm
rem Parámetros: %1=ID del panel, Variable global 'COMMAND_TO_EXEC'
rem ---------------------------------------------------------------------
:SEND_TO_PANE
set "TARGET_PANE=%~1"
if "!TARGET_PANE!"=="" exit /b 1

echo "COMMAND: !COMMAND_TO_EXEC!"
rem El echo envian un fin de linea la cual se interpreta como enter y ejecuta el comando.
echo(!COMMAND_TO_EXEC! | wezterm.exe cli send-text --pane-id !TARGET_PANE! --no-paste

exit /b 0



rem #####################################################################
rem Codigo Principal del scrtpt
rem #####################################################################
:MAIN

rem ---------------------------------------------------------------------
rem Procesamiento de argumentos
rem ---------------------------------------------------------------------
set "OPTION_P="
set "OPTION_W="
set "WORKING_DIR="
rem Valores posibles: 0=-w, 1=-p 1, 2=-p 2, 3=ninguno
set "WORKING_DIR_SRC=3"

rem Procesar opciones
:PARSE_ARGS_LOOP

rem Copiamos los parámetros a variables normales para evitar % con bloques y SHIFT
set "ARG=%~1"
set "VAL=%~2"

echo "arg: !ARG!, val: !VAL!"
if not defined ARG goto :ARGS_DONE

rem -h / ayuda
if /I "!ARG!"=="-h" (
    call :USAGE
    exit /b 0
)

rem -p <1|2>
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

rem -w <path>
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

rem -- fin de opciones
if /I "!ARG!"=="--" (
    shift
    goto :ARGS_DONE
)

rem Opcion desconocida: primer caracter '-'
if "!ARG:~0,1!"=="-" (
    echo [ERROR] Opcion desconocida: !ARG!
    call :USAGE
    exit /b 1
)


rem Es la ruta de entrada
set "INPUT_PATH=%~1"
shift
goto :PARSE_ARGS_LOOP

:ARGS_DONE

echo "OPTION_P: !OPTION_P!"
echo "OPTION_W: !OPTION_W!"
echo "INPUT_PATH: !INPUT_PATH!"
echo "WORKING_DIR: !WORKING_DIR!"
echo "WORKING_DIR_SRC: !WORKING_DIR_SRC!"

rem Verificar que tenemos una ruta
if "!INPUT_PATH!"=="" (
    echo [!color_red!ERROR!color_reset!] Debe especificar una ruta de folder o archivo.
    call :USAGE
    exit /b 4
)

rem ---------------------------------------------------------------------
rem Validaciones iniciales
rem ---------------------------------------------------------------------
call :CHECK_DEPENDENCIES
if errorlevel 1 exit /b 1

rem ---------------------------------------------------------------------
rem Procesar la ruta de entrada
rem ---------------------------------------------------------------------
echo [!color_gray!INFO!color_reset!] Procesando ruta: !INPUT_PATH!

rem Obtener ruta absoluta
set "FULL_PATH="
for %%F in ("!INPUT_PATH!") do set "FULL_PATH=%%~fF"
echo "FULL_PATH: !FULL_PATH!"

rem Determinar si es folder o archivo
set "IS_FOLDER=1"
set "FOLDER_PATH=!FULL_PATH!"

if exist "!FULL_PATH!\" (
    set "IS_FOLDER=0"
) else if not exist "!FULL_PATH!" (
    echo [!color_red!ERROR!color_reset!] La ruta no existe: !FULL_PATH!
    exit /b 6
)

if !IS_FOLDER! equ 1 (
    rem Es archivo, obtener directorio padre
    for %%F in ("!FULL_PATH!") do set "FOLDER_PATH=%%~dpF"
    rem Quitar la barra final
    if "!FOLDER_PATH:~-1!"=="\" set "FOLDER_PATH=!FOLDER_PATH:~0,-1!"
)

echo [!color_gray!INFO!color_reset!] Ruta procesada: !FULL_PATH!
echo [!color_gray!INFO!color_reset!] Directorio base: !FOLDER_PATH!
echo [!color_gray!INFO!color_reset!] Es folder: !IS_FOLDER!

rem ---------------------------------------------------------------------
rem Determinar directorio de trabajo
rem ---------------------------------------------------------------------
if !WORKING_DIR_SRC! equ 0 (
    rem Usar directorio especificado con -w
    set "WORKING_DIR=!OPTION_W!"
    echo [!color_gray!INFO!color_reset!] Usando directorio especificado: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 1 (
    rem Obtener directorio actual de WezTerm
    call :GET_WEZTERM_WORKDIR
    set "WORKING_DIR=!WORKDIR!"
    echo [!color_gray!INFO!color_reset!] Usando directorio actual WezTerm: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 2 (
    rem Usar directorio del archivo/folder
    set "WORKING_DIR=!FOLDER_PATH!"
    echo [!color_gray!INFO!color_reset!] Usando directorio del argumento: !WORKING_DIR!
) else (
    rem No especificar directorio
    set "WORKING_DIR="
    echo [!color_gray!INFO!color_reset!] Sin directorio especifico
)

echo "WORKING_DIR: !WORKING_DIR!"
echo "FOLDER_PATH: !FOLDER_PATH!"


rem ---------------------------------------------------------------------
rem Construir comando a ejecutar siempre que sea necesario
rem ---------------------------------------------------------------------
set "COMMAND_TO_EXEC="

if "!WORKING_DIR!"=="" (

    rem Calcular ruta relativa
    set "COMMAND_TO_EXEC=cd "!FOLDER_PATH!""
    rem echo "ok2"

) else (

    rem Si el directorio de trabajo no es el mismo que FOLDER_PATH
	if /i "!WORKING_DIR!"=="!FOLDER_PATH!" (
        rem Ya estoy en el mismo directorio -> no hace falta comando
        rem echo "ok1"

	) else (
        rem echo "ok0"
        rem Calcular ruta relativa
        set "RELATIVE_PATH=!FOLDER_PATH!"
        rem set "RELATIVE_PATH=!RELATIVE_PATH:%WORKING_DIR%\=!"
        call set "RELATIVE_PATH=%%RELATIVE_PATH:%WORKING_DIR%\=%%"
	    rem echo "RELATIVE_PATH: !REL_PATH!"

        if not "!RELATIVE_PATH!"=="!FOLDER_PATH!" (
            set "COMMAND_TO_EXEC=cd "!RELATIVE_PATH!""
	    ) else (
            rem Si no es subdirectorio, usar ruta absoluta
            set "COMMAND_TO_EXEC=cd "!FOLDER_PATH!""
        )
    )

)
echo [!color_gray!INFO!color_reset!] Comando a ejecutar: !COMMAND_TO_EXEC!



rem ---------------------------------------------------------------------
rem Crear panel y ejecutar comando
rem ---------------------------------------------------------------------

rem 1. Crear nuevo panel
set "PANE_ID="
call :CREATE_WEZTERM_PANE "!WORKING_DIR!"
if "!PANE_ID!"=="" (
    echo [!color_red!ERROR!color_reset!] No se pudo crear panel en WezTerm
    exit /b 1
)

echo [!color_green!OK!color_reset!] Panel creado con ID: !PANE_ID!

rem 2. Ejecutar comando en el panel (si hay comando)
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

rem ---------------------------------------------------------------------
rem Manejo de errores
rem ---------------------------------------------------------------------
:ERROR
echo [!color_red!ERROR!color_reset!] Error inesperado en la ejecucion
exit /b 99
