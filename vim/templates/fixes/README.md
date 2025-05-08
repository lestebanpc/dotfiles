Se debe cambiar solo en Windows los siguientes cambios:
Source: `https://github.com/junegunn/fzf.vim/issues/1212`

1. En Powershell profile, se debera usar un comando de busqueda de archivos, se recomienda usar el comando 'fd' para windows
    Ruta de Powershell         : `E:\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
    Ruta de Windows Powershell : `E:\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
    `$env:FZF_DEFAULT_COMMAND = 'fd --type file'`

2. Archivo `..\fzf.vim\autoload\fzf\vim.vim`
	Ruta Fix    : `~\.files\templates\fixes\fzf.vim\autoload\fzf\vim.vim`
	Ruta Vim    : `~\vimfiles\plugged\fzf.vim\autoload\fzf\vim.vim`
	Ruta Neovim : `$env:LOCALAPPDATA\nvim-data\plugged\fzf.vim\autoload\fzf\vim.vim`


    - En Windows 11 no soporta las funciones `exepath()` y `executable()`
    - Se esta usando la capacidad de WSL2 para ejecutar script bash busicados en `~\vimfiles\plugged\fzf.vim\bin\` (`preview.sh` y `tagpreview.sh`)
      Se debera cambiar a powershell.
    - Para WSL2 no se debe usar `bash.exe` se debera usar `wsl -e`

3. Archivo `..\fzf\plugin\fzf.vim`
	Ruta Fix    : `~\vimfiles\plugged\fzf\plugin\fzf.vim`
	Ruta Vim    : `~\vimfiles\plugged\fzf\plugin\fzf.vim`
	Ruta Neovim : `$env:LOCALAPPDATA\nvim-data\plugged\fzf\plugin\fzf.vim`

    - Soporte a Powershell (solo soporta a Windows Powershell)


Pautas para homologar versiones (solo es obligatorio en Windows):


1. Comparando los arreglado con el FZF de VIM
	`vim -d ~\.files\templates\fixes\fzf.vim\autoload\fzf\vim.vim $env:LOCALAPPDATA\nvim-data\plugged\fzf.vim\autoload\fzf\vim.vim`
	`vim -d ~\.files\templates\fixes\fzf\plugin\fzf.vim $env:LOCALAPPDATA\nvim-data\plugged\fzf\plugin\fzf.vim`

2. Comparando FZF de VIM con el FZF de NeoVim
	`vim -d ~\vimfiles\plugged\fzf.vim\autoload\fzf\vim.vim $env:LOCALAPPDATA\nvim-data\plugged\fzf.vim\autoload\fzf\vim.vim`
	`vim -d ~\vimfiles\plugged\fzf\plugin\fzf.vim $env:LOCALAPPDATA\nvim-data\plugged\fzf\plugin\fzf.vim`

3. Copiar el script en 'preview.ps1'
	Ruta Fix    : `~\.files\templates\fixes\fzf.vim\bin\`
	Ruta Vim    : `~\vimfiles\plugged\fzf.vim\bin\`
	Ruta Neovim : `$env:LOCALAPPDATA\nvim-data\plugged\fzf.vim\bin\`
