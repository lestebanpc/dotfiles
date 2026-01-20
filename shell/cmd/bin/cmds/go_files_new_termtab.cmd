@echo off
setlocal enabledelayedexpansion

:: #####################################################################
:: Configuración inicial
:: #####################################################################

:: Si se ejecuta en una terminal que soporta colores (Windows Terminal/WezTerm)
if not "%WT_SESSION%"=="" (
    for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
    set "color_red=%ESC%[91m"
    set "color_green=%ESC%[92m"
    set "color_gray=%ESC%[90m"
    set "color_reset=%ESC%[0m"
) else (
    set "color_red="
    set "color_green="
    set "color_gray="
    set "color_reset="
)


:: Estableces valor inicia de las variables de entorno
if "%EDITOR%"=="" (
    set "EDITOR=nvim.exe"
    ::set "EDITOR=vim.exe"
    ::set "EDITOR=code.exe"
    ::set "EDITOR=notepad++.exe"
    ::set "EDITOR=notepad.exe"
)

:: Buscar file.exe en varios lugares posibles
set "git_file_exe="

:: 1. Intentar usar la variable YAZI_FILE_ONE si está definida
if defined YAZI_FILE_ONE (
    if exist "%YAZI_FILE_ONE%" (
        set "git_file_exe=%YAZI_FILE_ONE%"
    ) else (
        echo [%color_gray%INFO%color_reset%] La variable YAZI_FILE_ONE está definida pero el archivo no existe.
    )
)

:: 2. Buscar file.exe en el PATH usando where
if "!git_file_exe!"=="" (
    where file.exe >nul 2>&1
    if %errorlevel%==0 (
        for /f "delims=" %%F in ('where file.exe') do (
            set "git_file_exe=%%F"
        )
    )
)

:: 3. Buscar en ubicaciones comunes de Git for Windows
if "!git_file_exe!"=="" (
    set "common_paths=C:\Program Files\Git\usr\bin\file.exe;C:\Program Files (x86)\Git\usr\bin\file.exe"
    for %%P in (%common_paths%) do (
        if exist "%%P" (
            set "git_file_exe=%%P"
        )
    )
)
:: Si no se encontró file.exe
if "!git_file_exe!"=="" (
    echo [%color_red%ERROR%color_reset%] No se encontró file.exe.
    echo Este comando es requerido para determinar el tipo de archivo.
    echo Soluciones:
    echo   1. Configure la variable YAZI_FILE_ONE con la ruta correcta a file.exe
    echo      Ejemplo: set YAZI_FILE_ONE=C:\Program Files\Git\usr\bin\file.exe
    echo   2. O instale Git for Windows que incluye file.exe
    echo   3. O agregue la ubicación de file.exe al PATH del sistema
    exit /b 1
)


:: #####################################################################
:: Funciones de utilidad
:: #####################################################################

:: ---------------------------------------------------------------------
:: Mostrar mensaje con color
:: ---------------------------------------------------------------------
:COLOR_ECHO
echo %~1
exit /b 0


:: ---------------------------------------------------------------------
:: Mostrar uso del script
:: ---------------------------------------------------------------------
:USAGE
echo.
echo USAGE: go_files_new_termtab.cmd [OPTIONS] file1 file2 ... filen
echo.
echo Crea una nueva ventana/tab en WezTerm con un nuevo panel cuyo directorio
echo de trabajo se calcula segun prioridad:
echo   - Directorio especificado por '-w'
echo   - Calculado por '-p' ^(1: directorio actual, 2: directorio del primer archivo^)
echo   - Si no se especifica, no se establece directorio
echo.
echo En el panel creado, se muestran los archivos:
echo   - Si el primer archivo es texto: se abren con %EDITOR%
echo   - Si el primer archivo es binario: se muestra informacion con 'file'
echo.
echo Solo soporta WezTerm en Windows ^(no tmux^).
echo.
echo OPCIONES:
echo   -p 1^|2        Calcula directorio automaticamente:
echo                  1: Usa directorio actual del proceso
echo                  2: Usa directorio padre del primer archivo
echo.
echo   -w ^<path^>    Directorio de trabajo especifico ^(prioridad sobre -p^)
echo.
echo   -l ^<nums^>    Lista de numeros de linea separados por coma
echo                  Solo para archivos de texto con vim/nvim
echo.
echo   ^<Files^>      Lista de archivos ^(primer archivo determina tipo^)
echo.
echo EJEMPLOS:
echo   go_files_new_termtab.cmd C:\code\mynote.txt
echo   go_files_new_termtab.cmd -p 1 C:\code\mynote.txt
echo   go_files_new_termtab.cmd -w "C:\work" -l "10,20" file1.txt file2.txt
echo.
exit /b 0


:: ---------------------------------------------------------------------
:: Verificar si WezTerm está disponible
:: ---------------------------------------------------------------------
:CHECK_WEZTERM
:: Verificar si estamos en WezTerm usando TERM_PROGRAM
if not "%TERM_PROGRAM%"=="WezTerm" (
    echo [%color_red%ERROR%color_reset%] Este script solo funciona dentro de WezTerm.
    echo Variable TERM_PROGRAM actual: "%TERM_PROGRAM%"
    exit /b 1
)

:: Verificar que wezterm CLI esté disponible
where wezterm >nul 2>&1
::if %errorlevel% neq 0 (
if errorlevel 1 (
    echo [%color_red%ERROR%color_reset%] WezTerm CLI no está instalado o no está en el PATH.
    exit /b 1
)

exit /b 0


:: ---------------------------------------------------------------------
:: Determinar si un archivo es de texto
:: Retorna: 0=texto, 1=binario
:: ---------------------------------------------------------------------
:IS_TEXT_FILE
set "FILE_PATH=%~1"
set "_IS_TEXT=1"

if "!git_file_exe!"=="" (
    goto :CHECK_EXTENSION
) else (
    for /f "tokens=*" %%F in ('"!git_file_exe!" -i "!FILE_PATH!" 2^>nul') do set "FILE_INFO=%%F"
    if "!FILE_INFO!"=="" goto :CHECK_EXTENSION

    echo !FILE_INFO! | find /i "text/" >nul && set "_IS_TEXT=0"
    echo !FILE_INFO! | find /i "application/json" >nul && set "_IS_TEXT=0"
    echo !FILE_INFO! | find /i "inode/x-empty" >nul && set "_IS_TEXT=0"

    if "!_IS_TEXT!"=="0" exit /b 0
)


:: ---------------------------------------------------------------------
:: Determiniar si es un archivo o texto segun la extension del archivo
:: ---------------------------------------------------------------------
:CHECK_EXTENSION
set "EXT=%~x1"
set "EXT=!EXT:.=!"
if not "!EXT!"=="" (
    set "TEXT_EXTS=txt md json xml yaml yml js ts py rb java c cpp h cs ps1 bat cmd sh bash config ini cfg log"
    for %%E in (!TEXT_EXTS!) do (
        if /i "!EXT!"=="%%E" set "_IS_TEXT=0"
    )
)

:: Método 3: Intentar leer primeras líneas
if "!_IS_TEXT!"=="1" (
    type "!FILE_PATH!" >nul 2>&1
    if not errorlevel 1 set "_IS_TEXT=0"
)

exit /b !_IS_TEXT!


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



:: #####################################################################
:: Codigo Principal del scrtpt
:: #####################################################################

:: ---------------------------------------------------------------------
:: Procesamiento de argumentos
:: ---------------------------------------------------------------------
set "OPTION_P="
set "OPTION_W="
set "OPTION_L="
set "FILES_INDEX=1"
set "FIRST_FILE="
set "IS_TEXT_FILE=1"
set "WORKING_DIR="
set "WORKING_DIR_SRC=3"  :: 0=-w, 1=-p 1, 2=-p 2, 3=ninguno

:: Procesar opciones
:PARSE_ARGS_LOOP
if "%1"=="" goto :ARGS_DONE

if "%1"=="-h" (
    call :USAGE
    exit /b 0
)

if "%1"=="-p" (
    if "%2"=="1" set "OPTION_P=1" & set "WORKING_DIR_SRC=1"
    if "%2"=="2" set "OPTION_P=2" & set "WORKING_DIR_SRC=2"
    if "%2"=="" (
        echo [ERROR] Opcion -p requiere un valor (1 o 2)
        exit /b 1
    )
    if not "%2"=="1" if not "%2"=="2" (
        echo [ERROR] Valor invalido para -p: %2 (debe ser 1 o 2)
        exit /b 1
    )
    shift & shift
    goto :PARSE_ARGS_LOOP
)

if "%1"=="-w" (
    if "%2"=="" (
        echo [ERROR] Opcion -w requiere un directorio
        exit /b 1
    )
    if not exist "%2\" (
        echo [ERROR] Directorio no existe: %2
        exit /b 1
    )
    set "OPTION_W=%~2"
    set "WORKING_DIR_SRC=0"
    shift & shift
    goto :PARSE_ARGS_LOOP
)

if "%1"=="-l" (
    if "%2"=="" (
        echo [ERROR] Opcion -l requiere una lista de numeros
        exit /b 1
    )
    set "OPTION_L=%~2"
    shift & shift
    goto :PARSE_ARGS_LOOP
)

if "%1"=="--" (
    shift
    goto :ARGS_DONE
)

if "%1:~0,1%"=="-" (
    echo [ERROR] Opcion desconocida: %1
    call :USAGE
    exit /b 1
)

:: Es un archivo
set "ARG_!FILES_INDEX!=%~1"
set /a FILES_INDEX+=1
shift
goto :PARSE_ARGS_LOOP

:ARGS_DONE
set /a FILES_COUNT=FILES_INDEX-1

:: Verificar que tenemos archivos
if !FILES_COUNT! lss 1 (
    echo [ERROR] Debe especificar al menos un archivo
    call :USAGE
    exit /b 1
)


:: ---------------------------------------------------------------------
:: Validaciones principales
:: ---------------------------------------------------------------------

:: 1. Verificar WezTerm
call :CHECK_WEZTERM
if errorlevel 1 exit /b 1

:: 2. Validar primer archivo
set "FIRST_FILE=!ARG_1!"
if not exist "!FIRST_FILE!" (
    echo [ERROR] Primer archivo no existe: !FIRST_FILE!
    exit /b 1
)

:: Verificar si es directorio
if exist "!FIRST_FILE!\" (
    echo [ERROR] Primer argumento no puede ser un directorio: !FIRST_FILE!
    exit /b 1
)

:: 3. Determinar tipo de archivo
call :IS_TEXT_FILE "!FIRST_FILE!"
set "IS_TEXT_FILE=!errorlevel!"
if !IS_TEXT_FILE! equ 0 (
    echo [INFO] Primer archivo es de texto: !FIRST_FILE!
    set "VIEWER_CMD=!EDITOR!"
) else (
    echo [INFO] Primer archivo es binario: !FIRST_FILE!
    where file.exe >nul 2>&1
    if errorlevel 1 (
        set "VIEWER_CMD=dir /b"
    ) else (
        set "VIEWER_CMD=file.exe"
    )
)

:: 4. Determinar directorio de trabajo
if !WORKING_DIR_SRC! equ 0 (
    :: Usar directorio especificado con -w
    set "WORKING_DIR=!OPTION_W!"
    echo [DEBUG] Usando directorio especificado: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 1 (
    :: Obtener directorio actual de WezTerm
    call :GET_WEZTERM_WORKDIR
    echo [DEBUG] Usando directorio actual WezTerm: !WORKDIR!
    set "WORKING_DIR=!WORKDIR!"
) else if !WORKING_DIR_SRC! equ 2 (
    :: Usar directorio del primer archivo
    for %%F in ("!FIRST_FILE!") do set "WORKING_DIR=%%~dpF"
    set "WORKING_DIR=!WORKING_DIR:~0,-1!"
    echo [DEBUG] Usando directorio del archivo: !WORKING_DIR!
) else (
    :: No especificar directorio
    set "WORKING_DIR="
    echo [DEBUG] Sin directorio especifico
)

:: 5. Procesar números de línea (si aplica)
set "LINE_NUMBERS="
if not "!OPTION_L!"=="" if !IS_TEXT_FILE! equ 0 (
    echo !EDITOR! | find /i "vim" >nul
    if not errorlevel 1 (
        set "LINE_NUMBERS=!OPTION_L!"
        echo [DEBUG] Numeros de linea: !LINE_NUMBERS!
    )
)


:: ---------------------------------------------------------------------
:: Filtrar y procesar archivos
:: ---------------------------------------------------------------------
set "FILE_LIST="
set "VALID_FILE_COUNT=0"

:: Procesar primer archivo
set "FIRST_FULL_PATH=!FIRST_FILE!"
if not "!WORKING_DIR!"=="" (
    :: Convertir a ruta relativa si es posible
    set "FIRST_FULL_PATH=!FIRST_FILE!"
    set "FIRST_FULL_PATH=!FIRST_FULL_PATH:%WORKING_DIR%\=!"
)

set "FILE_LIST=!FIRST_FULL_PATH!"
set /a VALID_FILE_COUNT=1

:: Procesar archivos restantes
if !FILES_COUNT! gtr 1 (
    set /a I=2
    :PROCESS_FILES_LOOP
    if !I! gtr !FILES_COUNT! goto :FILES_DONE

    set "CURRENT_FILE=!ARG_%I%!"

    :: Verificar que existe y es archivo
    if exist "!CURRENT_FILE!" if not exist "!CURRENT_FILE!\" (

        :: Determinar tipo del archivo actual
        call :IS_TEXT_FILE "!CURRENT_FILE!"
        set "CURRENT_IS_TEXT=!errorlevel!"

        :: Solo agregar si es del mismo tipo
        if !CURRENT_IS_TEXT! equ !IS_TEXT_FILE! (

            :: Obtener ruta completa
            for %%F in ("!CURRENT_FILE!") do set "CURRENT_FULL=%%~fF"

            :: Convertir a ruta relativa si hay directorio de trabajo
            if not "!WORKING_DIR!"=="" (
                set "CURRENT_FULL=!CURRENT_FULL:%WORKING_DIR%\=!"
            )

            :: Agregar a la lista
            set "FILE_LIST=!FILE_LIST! "!CURRENT_FULL!""
            set /a VALID_FILE_COUNT+=1
        ) else (
            echo [WARN] Omitiendo archivo tipo diferente: !CURRENT_FILE!
        )
    ) else (
        echo [WARN] Omitiendo (no es archivo valido): !CURRENT_FILE!
    )

    set /a I+=1
    goto :PROCESS_FILES_LOOP
)

:FILES_DONE

if !VALID_FILE_COUNT! equ 0 (
    echo [ERROR] No hay archivos validos para mostrar
    exit /b 1
)

echo [DEBUG] Archivos a procesar: !VALID_FILE_COUNT!


:: ---------------------------------------------------------------------
:: Construir comando para ejecutar
:: ---------------------------------------------------------------------
set "COMMAND_TO_EXEC="

if !IS_TEXT_FILE! equ 0 (
    :: Archivos de texto
    echo !VIEWER_CMD! | find /i "vim" >nul
    if not errorlevel 1 (
        :: Editor vim/nvim - soporte para números de línea
        set "COMMAND_TO_EXEC=!VIEWER_CMD!"

        :: Convertir lista de números de línea a array
        set "LINE_INDEX=0"
        set "FILE_INDEX=0"

        for %%F in (!FILE_LIST!) do (
            set "CURRENT_FILE=%%~F"
            set "CURRENT_LINE="

            :: Obtener número de línea correspondiente
            if not "!LINE_NUMBERS!"=="" (
                for /f "tokens=1,* delims=," %%A in ("!LINE_NUMBERS!") do (
                    if !LINE_INDEX! equ 0 set "CURRENT_LINE=%%A"
                    set "LINE_NUMBERS=%%B"
                )
                set /a LINE_INDEX+=1
            )

            if !FILE_INDEX! equ 0 (
                :: Primer archivo
                if not "!CURRENT_LINE!"=="" (
                    set "COMMAND_TO_EXEC=!VIEWER_CMD! +!CURRENT_LINE! "!CURRENT_FILE!""
                ) else (
                    set "COMMAND_TO_EXEC=!VIEWER_CMD! "!CURRENT_FILE!""
                )
            ) else (
                :: Archivos subsiguientes
                if not "!CURRENT_LINE!"=="" (
                    set "COMMAND_TO_EXEC=!COMMAND_TO_EXEC! -c "e "!CURRENT_FILE!"^|!CURRENT_LINE!""
                ) else (
                    set "COMMAND_TO_EXEC=!COMMAND_TO_EXEC! -c "e "!CURRENT_FILE!""
                )
            )
            set /a FILE_INDEX+=1
        )
    ) else (
        :: Otros editores (VS Code, Notepad++, etc.)
        set "COMMAND_TO_EXEC=!VIEWER_CMD! !FILE_LIST!"
    )
) else (
    :: Archivos binarios
    if "!VIEWER_CMD!"=="file.exe" (
        set "COMMAND_TO_EXEC=file.exe !FILE_LIST!"
    ) else (
        set "COMMAND_TO_EXEC=for %%f in (!FILE_LIST!) do @echo %%~nxf"
    )
)

echo [DEBUG] Comando: !COMMAND_TO_EXEC!


:: ---------------------------------------------------------------------
:: Crear panel y ejecutar comando
:: ---------------------------------------------------------------------

:: 1. Crear nuevo panel
call :CREATE_WEZTERM_PANE "!WORKING_DIR!"
if "!PANE_ID!"=="" (
    echo [ERROR] No se pudo crear panel en WezTerm
    exit /b 1
)

echo [INFO] Panel creado con ID: !PANE_ID!

:: 2. Ejecutar comando en el panel
call :SEND_TO_PANE "!PANE_ID!" "!COMMAND_TO_EXEC!"
if errorlevel 1 (
    echo [ERROR] No se pudo ejecutar comando en el panel
    exit /b 1
)

echo [INFO] Comando ejecutado exitosamente
exit /b 0


:: ---------------------------------------------------------------------
:: Manejo de errores inesperados
:: ---------------------------------------------------------------------

:ERROR
echo [ERROR] Error inesperado en la ejecucion
exit /b 1
