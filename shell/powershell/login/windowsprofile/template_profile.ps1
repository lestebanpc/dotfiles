#------------------------------------------------------------------------------------------------
# Variables globales basicas
#------------------------------------------------------------------------------------------------

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME.
$g_repo_name= '.files'

# Folder base donde se almacena los subfolderes de los programas.
$g_tools_path= 'D:\apps\tools'
#$g_tools_path= 'C:\apps\tools'

# Folder donde se almacena los binarios de tipo comando.
$g_bin_path='D:\apps\cmds\bin'
#$g_bin_path='C:\apps\cmds\bin'

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
$g_prompt_theme= "${env:USERPROFILE}\${g_repo_name}\etc\cli\oh-my-posh\default_settings.json"
#$g_prompt_theme= "${env:USERPROFILE}\${g_repo_name}\etc\cli\oh-my-posh\lepc-montys-green1.json"


#------------------------------------------------------------------------------------------------
# Variable de entorno PATH
#------------------------------------------------------------------------------------------------

# Si path no contiene la ruta de comandos, adicionarlos.
if(-not ("$env:PATH" -match ";?$($g_bin_path.Replace("\", "\\"));?")) {
    $env:PATH= "${g_bin_path};${env:PATH}"
}

## Binarios de compresor 7zip
#if(Test-Path "C:\Program Files\7-Zip") {
#    $env:PATH= "C:\Program Files\7-Zip;${env:PATH}"
#}
#
## Binarios de CTags
#if(Test-Path "${g_tools_path}\ctags\bin") {
#    $env:PATH= "${g_tools_path}\ctags\bin;${env:PATH}"
#}
#
## Binarios de compresor 7zip
#if(Test-Path "C:\Program Files\7-Zip") {
#    $env:PATH= "C:\Program Files\7-Zip;${env:PATH}"
#}
#
## Binarios de Git
#if(Test-Path "${g_tools_path}\git\cmd") {
#    $env:PATH= "${g_tools_path}\git\cmd;${env:PATH}"
#}
#
## Binario de NeoVIM
#if(Test-Path "${g_tools_path}\neovim\bin") {
#    $env:PATH= "${g_tools_path}\neovim\bin;${env:PATH}"
#}
#
## Binario de VIM
#if(Test-Path "${g_tools_path}\vim") {
#    $env:PATH= "${g_tools_path}\vim;${env:PATH}"
#}
#
## Binario de Node.JS
#if(Test-Path "${g_tools_path}\node") {
#    $env:PATH= "${g_tools_path}\node;${env:PATH}"
#}
#
## Binario de Python3
#if(Test-Path "${g_tools_path}\python3") {
#    $env:PATH= "${g_tools_path}\python3;${env:PATH}"
#}
#
## Binario de MinGW-64
#if(Test-Path "${g_tools_path}\mingw64\bin") {
#    $env:PATH= "${env:PATH};${g_tools_path}\mingw64\bin"
#}
#
## Binario de DevToys CLI
#if(Test-Path "${g_tools_path}\devtoys\cli") {
#    $env:PATH= "${env:PATH};${g_tools_path}\devtoys\cli"
#}

## Binario de LLVM y Clang
#if(Test-Path "${g_tools_path}\llvm\bin") {
#    $env:PATH= "${g_tools_path}\llvm\bin;${env:PATH}"
#}


#------------------------------------------------------------------------------------------------
# Personalizacion de la terminal
#------------------------------------------------------------------------------------------------

# Cambiar el color de los folderes
#PSStyle.FileInfo.Directory="`e[44;1m"
$PSStyle.FileInfo.Directory="`e[44;30m"


#------------------------------------------------------------------------------------------------
# Comando> Oh-My-Posh
#------------------------------------------------------------------------------------------------

oh-my-posh init pwsh --config "${g_prompt_theme}" | Invoke-Expression


#------------------------------------------------------------------------------------------------
# Comando> FZF (fzf.exe)
#------------------------------------------------------------------------------------------------

$env:FZF_COMPLETION_PATH_OPTS = "--walker=file,dir,hidden,follow"
$env:FZF_COMPLETION_DIR_OPTS  = "--walker=dir,hidden,follow"

$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color=bg+:#293739,bg:#0F0F0F,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"
#$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --info=inline --border --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"

$env:FZF_CTRL_T_COMMAND  = "fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
$env:FZF_ALT_C_COMMAND   = "fd -H -t d -E '.git' -E 'node_modules'"

$env:FZF_CTRL_R_OPTS = "--prompt 'History> '"
$env:FZF_CTRL_T_OPTS = "--prompt 'Select> ' --preview 'if exist {}\ ( eza --tree --color=always --icons always -L 5 {} ) else ( bat --color=always --style=numbers,header-filename --line-range :500 {} )'"
$env:FZF_ALT_C_OPTS  = "--prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {}'"

#Sobrescribir 'Ctrl+t' y 'Ctrl+r' para usar FZF para el listado de archivos y el historial.
#Requiere tener instalado el modulo 'PSFzf' ("Install-Module -Name PSFzf -Scope AllUsers").
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'


#------------------------------------------------------------------------------------------------
# Comando> Zoxide (zoxide.exe)
#------------------------------------------------------------------------------------------------

#Personalizar el uso comando 'zi'
$env:_ZO_FZF_OPTS="${env:FZF_DEFAULT_OPTS} --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {2}' --preview-window=down,70%"

#Inicializacion de zoxide: crea el alias del comando 'zi' y 'z'
Invoke-Expression (& { (zoxide init powershell | Out-String) })


#------------------------------------------------------------------------------------------------
# Comando> Yazi (yazi.exe)
#------------------------------------------------------------------------------------------------

# Wrapper que abre yazi y se mueve al ultimo directorio navegado
function y {

    # Crea un un archivo temporal creeado y luego lo almacena su ruta en la variable 'l_tmp'
    $tmp = (New-TemporaryFile).FullName

    # Ejecuta el comando yazi, ignorando cualquier alias o función que también se llame yazi.
    # > '--cwd-file' cuando cierra yazi, escribe el 'working directory' actual de yazi en este archivo temporal ($tmp).
    yazi.exe $args --cwd-file="$tmp"

    # Leer el contenido de archivo temporal y lo almacena en '$cwd'
    $cwd = Get-Content -Path $tmp -Encoding UTF8

    # Si el 'working directory' no es vacio y no es diferente del actual, ejecuta el comando interno 'cd' (omite alias y funciones)
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }

    # Elimina el archivo temporal
    Remove-Item -Path $tmp
}


#------------------------------------------------------------------------------------------------
# Soporte a Microsoft CoreUtils
#------------------------------------------------------------------------------------------------
#
# > Installer : https://github.com/microsoft/coreutils
# > Info      : https://deepwiki.com/microsoft/coreutils
# > Obtenido del codigo generado por el script:
#   .\pwsh-install.ps1 -Action Install -Scope CurrentUser -CmdDir 'C:\Program Files\coreutils\cmd'
# > Resumen   :
#   > Por cada comando se tiene 2 binarios identidos '.cmd' y '.exe'.
#   > Para modificar dinamicamente el alias se usa la version '.cmd' para evitar que powershell realize ciertas expansiones antes
#     de ejecutar el comando y se comporte algo similar a linux.
#   > Modifica el controlador de evento 'PSConsoleHostReadLine' ejecutado automaticamente antes que se ejecute el comando
#     interactivo escrito en el prompt.
#   > El los alias de powershell, que estan en reservados en linux ('ls', ...), no se cambia estaticamente, se modifica dinamicamente
#     cuando se evalua cada comando a ejecutar.
#

if(Test-Path "${g_tools_path}\coreutils\cmd\ls.cmd") {

    # Inlining the template into the profile shaves off ~10ms (25%).
    $script:__COREUTILS__ = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@('arch','b2sum','base32','base64','basename','basenc','cat','cksum','comm','cp','csplit','cut','date','df','dirname','du','echo','env','expr','factor','false','find','fmt','fold','grep','head','hostname','join','la','link','ln','ls','md5sum','mkdir','mktemp','mv','nl','nproc','numfmt','od','paste','pathchk','pr','printenv','printf','ptx','pwd','readlink','realpath','rm','rmdir','seq','sha1sum','sha224sum','sha256sum','sha384sum','sha512sum','shuf','sleep','sort','split','stat','sum','tac','tail','tee','test','touch','tr','true','truncate','tsort','unexpand','uniq','unlink','uptime','wc','xargs','yes'),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $script:__COREUTILS_FAST_SKIP__ = [regex]::new(
        '\b(?:' + ($script:__COREUTILS__ -join '|') + ')\b',
        [System.Text.RegularExpressions.RegexOptions]::Compiled -bor `
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    # Casting the scriptblock to Func<Ast,bool> once and reusing it avoids the
    # per-FindAll scriptblock-to-delegate wrapping overhead (~1.7x faster).
    $script:__COREUTILS_CMD_PREDICATE__ = [System.Func[System.Management.Automation.Language.Ast, bool]] {
        param($n) $n -is [System.Management.Automation.Language.CommandAst]
    }

    $script:__COREUTILS_ARG_SPECIAL__ = [char[]] @("'", '"', '`', '$')

    # Wrap arguments into quotes. By being a function we can properly handle $variables.
    # As per MSVCRT, any `\` before `"` must be doubled to escape them.
    function global:__coreutils_q {
        param($s)
        '"' + (([string]$s) -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
    }

    # PowerShell tokenizes `*"a"*` as [BareWord] instead of the expected [DoubleQuoted, BareWord, DoubleQuoted].
    # To work around that we use... regex. Group 1 = 'single', 2 = "double", 3 = `escape, 4 = bare run.
    $script:__COREUTILS_ARG_RX__ = [regex]::new(
        "'((?:[^']|'')*)'|""((?:[^""``]|""""|``.)*)""|``(.)|([^'""``]+)",
        [System.Text.RegularExpressions.RegexOptions]::Compiled
    )
    $script:__COREUTILS_ARG_EVAL__ = [System.Text.RegularExpressions.MatchEvaluator] {
        param($m)
        if ($m.Groups[1].Success) {
            # Single-quoted: literal. PS '' -> ', then MSVCRT-quote.
            $body = $m.Groups[1].Value.Replace("''", "'")
            if ($body -match '^(.*?)(\\+)$') {
                return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
            }
            return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
        }
        if ($m.Groups[2].Success) {
            # Double-quoted: collapse PS quote-escapes to raw " / ', let ExpandString
            # resolve `n / `t / $var, then MSVCRT-quote.
            $body = $m.Groups[2].Value.
            Replace('`"', '"').
            Replace("``'", "'").
            Replace('""', '"')
            $body = $ExecutionContext.InvokeCommand.ExpandString($body)
            if ($body -match '^(.*?)(\\+)$') {
                return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
            }
            return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
        }
        if ($m.Groups[3].Success) {
            # Backtick-escaped char outside a string: " -> \"; everything else
            # becomes a one-char quoted region so glob metas stay literal.
            $c = $m.Groups[3].Value
            if ($c -eq '"') {
                return '\"'
            }
            return '"' + $c + '"'
        }
        # Bare run: passed through unquoted so coreutils can glob it; expand $vars.
        return $ExecutionContext.InvokeCommand.ExpandString($m.Groups[4].Value)
    }

    # 0: not tested, 1: coreutils not installed, 2: coreutils installed.
    $script:__COREUTILS_CMD_DIR_TEST__ = 0

    # PSConsoleHostReadLine override that rewrites coreutils command names to their
    # .cmd equivalents after PSReadLine returns (history keeps the original).
    #
    # Why .cmd over .exe: PSNativeCommandArgumentPassing = 'Windows' results in a behavior
    # where passing bare quotes to CreateProcess() is impossible. This prevents us from
    # passing "*" as "*" to coreutils and instead will be given as a bare *.
    # This causes it to treat it as a glob pattern. "*.cmd" files however are automatically
    # treated as PSNativeCommandArgumentPassing = 'Legacy', which preserves quotes.
    # It is the only possible workaround and the only way coreutils can work at all.
    function PSConsoleHostReadLine {
        [System.Diagnostics.DebuggerHidden()]
        param()

        $lastRunStatus = $?
        Microsoft.PowerShell.Core\Set-StrictMode -Off
        $line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)

        # If the line contains no coreutils name, we don't need to parse the AST at all.
        if (-not $script:__COREUTILS_FAST_SKIP__.IsMatch($line)) {
            return $line
        }

        # Roamed/synced profiles can load this snippet on machines where coreutils is not installed.
        # Test for the existence of the command directory once and remember the result.
        if ($script:__COREUTILS_CMD_DIR_TEST__ -eq 0) {
            $script:__COREUTILS_CMD_DIR_TEST__ = 1
            if (Test-Path -LiteralPath "${g_tools_path}\coreutils\cmd\" -PathType Container -ErrorAction Ignore) {
                $script:__COREUTILS_CMD_DIR_TEST__ = 2
            }
        }
        if ($script:__COREUTILS_CMD_DIR_TEST__ -ne 2) {
            return $line
        }

        $ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$null, [ref]$null)
        $commands = $ast.FindAll($script:__COREUTILS_CMD_PREDICATE__, $true)

        # Process right-to-left so earlier offsets stay valid after each splice.
        # In-place reverse beats Sort-Object for the typical 1-command line.
        if ($commands.Count -gt 1) {
            $commands = [System.Collections.Generic.List[object]]::new($commands)
            $commands.Reverse()
        }

        foreach ($cmd in $commands) {
            $name = $cmd.GetCommandName()
            if (!$name) {
                continue
            }

            $baseName = $name
            if ($name.EndsWith('.exe') -or $name.EndsWith('.cmd')) {
                $baseName = $name.Substring(0, $name.Length - 4)
            }
            if (!$script:__COREUTILS__.Contains($baseName)) {
                continue
            }

            # ls/la get colour + listing flags injected; la also rewrites to ls.
            $cmdElement = $cmd.CommandElements[0]
            $start = $cmdElement.Extent.StartOffset
            $end = $cmdElement.Extent.EndOffset
            $replacement = "& '${g_tools_path}\coreutils\cmd\"

            switch ($baseName) {
                'la' { $replacement += "ls.cmd' --color=auto -AFhl" }
                'ls' { $replacement += "ls.cmd' --color=auto" }
                default { $replacement += "$baseName.cmd'" }
            }

            # Walk command elements, merging adjacent ones whose extents touch
            # (e.g. `'a'*` parses as [SingleQuoted, BareWord] but is one shell word).
            # The inverse case `*'a'*` parses as a single BareWord whose text
            # contains the embedded quotes, which is why AST-only analysis
            # isn't enough and we still need to re-tokenize the source span.
            $argsStart = $end
            $argsEnd = $cmd.Extent.EndOffset
            $rewrittenArgs = ''
            $elements = $cmd.CommandElements
            $count = $elements.Count
            $i = 1
            while ($i -lt $count) {
                $first = $elements[$i]
                $wordStart = $first.Extent.StartOffset
                $wordEnd = $first.Extent.EndOffset
                $merged = $false
                while ($i + 1 -lt $count -and $elements[$i + 1].Extent.StartOffset -eq $wordEnd) {
                    $i++
                    $wordEnd = $elements[$i].Extent.EndOffset
                    $merged = $true
                }
                $source = $line.Substring($wordStart, $wordEnd - $wordStart)
                $rewrittenArgs += $line.Substring($argsStart, $wordStart - $argsStart)
                $argsStart = $wordEnd
                # IndexOfAny beats running the regex per arg.
                if ($source.IndexOfAny($script:__COREUTILS_ARG_SPECIAL__) -lt 0) {
                    $rewrittenArgs += $source
                    $i++
                    continue
                }
                # A single un-merged PS expression that needs $var resolution
                # (bare $var, "...$var...", $x.Member, $($expr), etc.).
                # Defer evaluation to runtime so the value reaches coreutils as a literal arg.
                # This matches POSIX behaviour where variable expansions don't result in globbing.
                if (-not $merged -and
                    ($first -is [System.Management.Automation.Language.VariableExpressionAst] -or
                    $first -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -or
                    $first -is [System.Management.Automation.Language.MemberExpressionAst])) {
                    $rewrittenArgs += '(__coreutils_q ' + $source + ')'
                    $i++
                    continue
                }
                # Slow path: re-tokenise and re-emit as MSVCRT-style quoting,
                # then wrap in PS single quotes so PS hands the body verbatim.
                $windowsQuoted = $script:__COREUTILS_ARG_RX__.Replace($source, $script:__COREUTILS_ARG_EVAL__)
                $rewrittenArgs += "'" + $windowsQuoted.Replace("'", "''") + "'"
                $i++
            }
            $rewrittenArgs += $line.Substring($argsStart, $argsEnd - $argsStart)

            $line = $line.Substring(0, $start) + $replacement + $rewrittenArgs + $line.Substring($argsEnd)
        }

        return $line
    }

}


#------------------------------------------------------------------------------------------------
# Personalizacion
#------------------------------------------------------------------------------------------------

# ...
