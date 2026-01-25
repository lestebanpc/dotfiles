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



if "%EDITOR%"=="" (
    set "EDITOR=nvim.exe"
    rem set "EDITOR=vim.exe"
    rem set "EDITOR=code.exe"
    rem set "EDITOR=notepad++.exe"
    rem set "EDITOR=notepad.exe"
)

rem Buscar file.exe en varios lugares posibles
set "git_file_exe="

rem 1. Intentar usar la variable YAZI_FILE_ONE si está definida
if defined YAZI_FILE_ONE (
    if exist "%YAZI_FILE_ONE%" (
        set "git_file_exe=%YAZI_FILE_ONE%"
    ) else (
        echo [%color_gray%INFO%color_reset%] La variable YAZI_FILE_ONE está definida pero el archivo no existe.
    )
)

rem 2. Buscar file.exe en el PATH usando where
if "!git_file_exe!"=="" (
    where file.exe >nul 2>&1
    if %errorlevel%==0 (
        for /f "delims=" %%F in ('where file.exe') do (
            set "git_file_exe=%%F"
        )
    )
)

rem 3. Buscar en ubicaciones comunes de Git for Windows
if "!git_file_exe!"=="" (
    set "common_paths=C:\Program Files\Git\usr\bin\file.exe;C:\Program Files (x86)\Git\usr\bin\file.exe"
    for %%P in (%common_paths%) do (
        if exist "%%P" (
            set "git_file_exe=%%P"
        )
    )
)


rem Si no se encontró file.exe
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

rem echo "git_file_exe: !git_file_exe!"
goto :MAIN


rem #####################################################################
rem Funciones de utilidad
rem #####################################################################

rem ---------------------------------------------------------------------
rem Mostrar mensaje con color
rem ---------------------------------------------------------------------
:COLOR_ECHO
echo %~1
exit /b 0


rem ---------------------------------------------------------------------
rem Mostrar uso del script
rem ---------------------------------------------------------------------
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


rem ---------------------------------------------------------------------
rem Verificar si WezTerm está disponible
rem ---------------------------------------------------------------------
:CHECK_WEZTERM
rem Verificar si estamos en WezTerm usando TERM_PROGRAM
if not "%TERM_PROGRAM%"=="WezTerm" (
    echo [%color_red%ERROR%color_reset%] Este script solo funciona dentro de WezTerm.
    echo Variable TERM_PROGRAM actual: "%TERM_PROGRAM%"
    exit /b 1
)

rem Verificar que wezterm CLI esté disponible
where wezterm >nul 2>&1
if errorlevel 1 (
    echo [%color_red%ERROR%color_reset%] WezTerm CLI no está instalado o no está en el PATH.
    exit /b 1
)
exit /b 0


rem ---------------------------------------------------------------------
rem Determinar si un archivo es de texto
rem Retorna: 0=texto, 1=binario
rem ---------------------------------------------------------------------
:IS_TEXT_FILE
set "FILE_PATH=%~1"
set "_IS_TEXT=1"

if "!git_file_exe!"=="" (
    goto :CHECK_EXTENSION
) else (
    rem echo "git_file_exe: !git_file_exe!"
    for /f "delims=" %%F in ('""!git_file_exe!" -ib "!FILE_PATH!"" 2^>^&1') do (
       set "FILE_INFO=%%F"
    )

	echo "file output: !FILE_INFO!"
    if "!FILE_INFO!"=="" goto :CHECK_EXTENSION

    echo !FILE_INFO! | find /i "text/" >nul && set "_IS_TEXT=0"
    echo !FILE_INFO! | find /i "application/json" >nul && set "_IS_TEXT=0"
    echo !FILE_INFO! | find /i "inode/x-empty" >nul && set "_IS_TEXT=0"
    rem echo "_IS_TEXT: !_IS_TEXT!"
    if "!_IS_TEXT!"=="0" exit /b 0
)

rem Determiniar si es un archivo o texto segun la extension del archivo
:CHECK_EXTENSION
set "EXT=%~x1"
set "EXT=!EXT:.=!"
if not "!EXT!"=="" (
    set "TEXT_EXTS=txt md json xml yaml yml js ts py rb java c cpp h cs ps1 bat cmd sh bash config ini cfg log toml"
    for %%E in (!TEXT_EXTS!) do (
        if /i "!EXT!"=="%%E" set "_IS_TEXT=0"
    )
)

rem Método 3: Intentar leer primeras líneas
if "!_IS_TEXT!"=="1" (
    type "!FILE_PATH!" >nul 2>&1
    if not errorlevel 1 set "_IS_TEXT=0"
)
exit /b !_IS_TEXT!


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
set "OPTION_L="
set "FILES_INDEX=1"
set "FIRST_FILE="
set "IS_TEXT_FILE=1"
set "WORKING_DIR="
rem Valores poosibles: 0=-w, 1=-p 1, 2=-p 2, 3=ninguno
set "WORKING_DIR_SRC=3"

rem Procesar opciones
:PARSE_ARGS_LOOP

rem Copiamos los parámetros a variables normales para evitar % con bloques y SHIFT
set "ARG=%~1"
set "VAL=%~2"

rem echo "arg: !ARG!, val: !VAL!"
if not defined ARG goto :ARGS_DONE

rem -h / ayuda
if /I "!ARG!"=="-h" (
    call :USAGE
    exit /b 0
)

rem -p <1|2>
if /I "!ARG!"=="-p" (
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

rem -l <nums>
if /I "!ARG!"=="-l" (
    if "!VAL!"=="" (
        echo [ERROR] Opcion -l requiere una lista de numeros
        exit /b 1
    )
    set "OPTION_L=!VAL!"
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


rem Es un archivo
set "ARG_!FILES_INDEX!=!ARG!"
set /a FILES_INDEX+=1
shift
goto :PARSE_ARGS_LOOP


:ARGS_DONE
set /a FILES_COUNT=FILES_INDEX-1


rem echo "OPTION_P: !OPTION_P!"
rem echo "OPTION_W: !OPTION_W!"
rem echo "OPTION_L: !OPTION_L!"
rem echo "FILES_INDEX: !FILES_INDEX!"
rem echo "FIRST_FILE: !FIRST_FILE!"


rem Verificar que tenemos archivos
if !FILES_COUNT! lss 1 (
    echo [ERROR] Debe especificar al menos un archivo
    call :USAGE
    exit /b 1
)


rem ---------------------------------------------------------------------
rem Validaciones principales
rem ---------------------------------------------------------------------
rem echo "IS_TEXT_FILE: !IS_TEXT_FILE!"
rem echo "WORKING_DIR: !WORKING_DIR!"
rem echo "WORKING_DIR_SRC: !WORKING_DIR_SRC!"

rem 1. Verificar WezTerm
call :CHECK_WEZTERM
if errorlevel 1 exit /b 1

rem 2. Validar primer archivo
set "FIRST_FILE=!ARG_1!"
if not exist "!FIRST_FILE!" (
    echo [ERROR] Primer archivo no existe: !FIRST_FILE!
    exit /b 1
)

rem Verificar si es directorio
if exist "!FIRST_FILE!\" (
    echo [ERROR] Primer argumento no puede ser un directorio: !FIRST_FILE!
    exit /b 1
)

rem 3. Determinar tipo de archivo
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

rem 4. Determinar directorio de trabajo
if !WORKING_DIR_SRC! equ 0 (
    rem Usar directorio especificado con -w
    set "WORKING_DIR=!OPTION_W!"
    echo [DEBUG] Usando directorio especificado: !WORKING_DIR!
) else if !WORKING_DIR_SRC! equ 1 (
    rem Obtener directorio actual de WezTerm
    call :GET_WEZTERM_WORKDIR
    echo [DEBUG] Usando directorio actual WezTerm: !WORKDIR!
    set "WORKING_DIR=!WORKDIR!"
) else if !WORKING_DIR_SRC! equ 2 (
    rem Usar directorio del primer archivo
    for %%F in ("!FIRST_FILE!") do set "WORKING_DIR=%%~dpF"
    set "WORKING_DIR=!WORKING_DIR:~0,-1!"
    echo [DEBUG] Usando directorio del archivo: !WORKING_DIR!
) else (
    rem No especificar directorio
    set "WORKING_DIR="
    echo [DEBUG] Sin directorio especifico
)

echo "WORKING_DIR: !WORKING_DIR!"

rem 5. Procesar números de línea (si aplica)
set "LINE_NUMBERS="
if not "!OPTION_L!"=="" if !IS_TEXT_FILE! equ 0 (
    echo !EDITOR! | find /i "vim" >nul
    if not errorlevel 1 (
        set "LINE_NUMBERS=!OPTION_L!"
		set "LINE_REST=!LINE_NUMBERS!"
        echo [DEBUG] Numeros de linea: !LINE_NUMBERS!
    )
)


rem ---------------------------------------------------------------------
rem Filtrar y procesar archivos
rem ---------------------------------------------------------------------
set "FILE_LIST="
set "VALID_FILE_COUNT=0"

rem Procesar primer archivo (Se normaliza a ruta completa y luego recorta contra WORKING_DIR)
for %%F in ("!FIRST_FILE!") do set "FIRST_FULL_PATH=%%~fF"
if not "!WORKING_DIR!"=="" (
  rem set "FIRST_FULL_PATH=!FIRST_FULL_PATH:%WORKING_DIR%\=!"
  call set "FIRST_FULL_PATH=%%FIRST_FULL_PATH:%WORKING_DIR%\=%%"
)

echo "FIRST_FULL_PATH: !FIRST_FULL_PATH!"
set "FILE_LIST="!FIRST_FULL_PATH!""

set /a VALID_FILE_COUNT=1
echo "FIRST_FULL_PATH: !FIRST_FULL_PATH!, FILE_LIST: !FILE_LIST!, FILES_COUNT: !FILES_COUNT!"

rem Procesar archivos restantes (desde 2 hasta FILES_COUNT)
if !FILES_COUNT! gtr 1 (
  for /L %%I in (2,1,!FILES_COUNT!) do (
    call set "CURRENT_FILE=%%ARG_%%I%%"
    if exist "!CURRENT_FILE!" if not exist "!CURRENT_FILE!\" (
      call :IS_TEXT_FILE "!CURRENT_FILE!"
      set "CURRENT_IS_TEXT=!errorlevel!"

      if !CURRENT_IS_TEXT! equ !IS_TEXT_FILE! (
        for %%F in ("!CURRENT_FILE!") do set "CURRENT_FULL=%%~fF"
        if not "!WORKING_DIR!"=="" (
          rem set "CURRENT_FULL=!CURRENT_FULL:%WORKING_DIR%\=!"
          call set "CURRENT_FULL=%%CURRENT_FULL:%WORKING_DIR%\=%%"
        )
        set "FILE_LIST=!FILE_LIST! "!CURRENT_FULL!""
        set /a VALID_FILE_COUNT+=1
      ) else (
        echo [WARN] Omitiendo archivo tipo diferente: !CURRENT_FILE!
      )
    ) else (
      echo [WARN] Omitiendo ^(no es archivo valido^): !CURRENT_FILE!
    )
  )
)


:FILES_DONE
if !VALID_FILE_COUNT! equ 0 (
    echo [ERROR] No hay archivos validos para mostrar
    exit /b 1
)

echo [DEBUG] Archivos a procesar: !VALID_FILE_COUNT!


rem ---------------------------------------------------------------------
rem Construir comando para ejecutar
rem ---------------------------------------------------------------------
set "COMMAND_TO_EXEC="

if !IS_TEXT_FILE! equ 0 (

  rem Si el editor es vim/nvim
  rem echo "Archivo de texto"
  echo !VIEWER_CMD! | find /i "vim" >nul
  if not errorlevel 1 (

    if "!LINE_NUMBERS!"=="" (

      rem Caso sin -l: nvim "f1" "f2" ...
      set "COMMAND_TO_EXEC=!VIEWER_CMD!"
      for %%F in (!FILE_LIST!) do (
        set "CURRENT_FILE=%%~F"
        set "COMMAND_TO_EXEC=!COMMAND_TO_EXEC! ^"!CURRENT_FILE!^""
      )

    ) else (

      rem Caso con -l: +L1 "f1" y luego -c "e f2" [-c L2] ...
      set "LINE_INDEX=0"
      set "COMMAND_TO_EXEC="

      for %%F in (!FILE_LIST!) do (

        set "CURRENT_FILE=%%~F"
        set "CURRENT_LINE="
        rem echo "CURRENT_LINE ini: !CURRENT_LINE!"

        rem Tomar el primer número disponible y acortar la cola
        if defined LINE_REST (
          for /f "tokens=1,* delims=," %%A in ("!LINE_REST!") do (
            set "CURRENT_LINE=%%~A"
            set "LINE_REST=%%~B"
			rem echo "LINE_REST: !LINE_REST!"
          )
        )
        rem echo "CURRENT_LINE fin: !CURRENT_LINE!"

        if "!COMMAND_TO_EXEC!"=="" (
          rem Primer archivo
          if defined CURRENT_LINE (
            set "COMMAND_TO_EXEC=!VIEWER_CMD! +!CURRENT_LINE! ^"!CURRENT_FILE!^""
          ) else (
            set "COMMAND_TO_EXEC=!VIEWER_CMD! ^"!CURRENT_FILE!^""
          )
        ) else (
          rem Archivos siguientes
          if defined CURRENT_LINE (
            set "COMMAND_TO_EXEC=!COMMAND_TO_EXEC! -c ^"e !CURRENT_FILE!^" -c ^"!CURRENT_LINE!^""
          ) else (
            set "COMMAND_TO_EXEC=!COMMAND_TO_EXEC! -c ^"e !CURRENT_FILE!^""
          )
        )

      )

    )

  ) else (
    rem Otros editores
    set "COMMAND_TO_EXEC=!VIEWER_CMD! !FILE_LIST!"
  )

) else (

  rem Archivos binarios
  if "!VIEWER_CMD!"=="file.exe" (
    set "COMMAND_TO_EXEC=file.exe !FILE_LIST!"
  ) else (
    set "COMMAND_TO_EXEC=for %%f in (!FILE_LIST!) do @echo %%~nxf"
  )

)

echo [DEBUG] Comando: !COMMAND_TO_EXEC!



rem ---------------------------------------------------------------------
rem Crear panel y ejecutar comando
rem ---------------------------------------------------------------------

rem 1. Crear nuevo panel
call :CREATE_WEZTERM_PANE "!WORKING_DIR!"
if "!PANE_ID!"=="" (
    echo [ERROR] No se pudo crear panel en WezTerm
    exit /b 1
)

echo [INFO] Panel creado con ID: !PANE_ID!

rem 2. Ejecutar comando en el panel
call :SEND_TO_PANE "!PANE_ID!"
if errorlevel 1 (
    echo [ERROR] No se pudo ejecutar comando en el panel
    exit /b 1
)

echo [INFO] Comando ejecutado exitosamente
exit /b 0


rem ---------------------------------------------------------------------
rem Manejo de errores inesperados
rem ---------------------------------------------------------------------

:ERROR
echo [ERROR] Error inesperado en la ejecucion
exit /b 1
