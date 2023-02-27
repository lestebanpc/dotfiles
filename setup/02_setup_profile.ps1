
function m_update_repository($p_path) 
{
    if(!(Test-Path $p_path)) {
        Write-Host "Folder `"${p_path}`" not exists"
        return 9
    }

    Write-Host "-------------------------------------------------------------------------------------------------"
    Write-Host "- Repository Git para VIM: `"${p_path}`""
    Write-Host "-------------------------------------------------------------------------------------------------"

    cd $p_path
    
    #Obtener el directorio .git pero no imprimir su valor ni los errores. Si no es un repositorio valido salir
    git rev-parse --git-dir > $null 2>&1
    if (! $?)
    {
        #Si no es un repositorio valido salir
        Write-Host 'Invalid git repository'
        return 8
    }

    $l_local_branch="$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)"
    $l_remote="$(git config branch.${l_local_branch}.remote)"
    $l_remote_branch="$(git rev-parse --abbrev-ref --symbolic-full-name `@`{u`})"

    Write-Host "> Fetching from remote repository `"${l_remote}`"..."
    git fetch $l_remote

    Write-Host "> Updating local branch `"${l_local_branch}`"..."
    git merge-base --is-ancestor ${l_remote_branch} HEAD
    if (! $?) {
        Write-Host '> Fast-forward not possible. Rebasing...'
        #git rebase --preserve-merges --stat ${l_remote_branch}
        git rebase --rebase-merges --stat ${l_remote_branch}
        #git rebase --stat ${l_remote_branch}
        return 2
    }

    Write-Host '> Fast-forward possible. Merging...'
    git merge --ff-only --stat ${l_remote_branch}
    #$l_status=$?
    #Write-Host "$?"
    #Retornar un valor si no se actulizo (el repositorio ya estaba actualizado)
    return 0   

}

function m_update_vim_repository()
{
    $folders = Get-ChildItem ~\vimfiles\pack\ -Attributes Directory+Hidden -ErrorAction SilentlyContinue -Filter ".git" -Recurse | Select-Object "FullName"
    foreach ( $folder in $folders ) {
        $repo_path = Split-Path -Parent $folder.FullName
        m_update_repository $repo_path
    }

    #Si se actualizo de paquete de fzf seguir los siguientes pasos en Vim y NeoVim
    #en fzf descargar el repositorio temporalmente y traer los archivos, comprararlo y actualizar ~/files/vim/plugin/fzf
    
    #~\vimfiles\pack\ui\opt\fzf.vim
    #Restaurar el archivo 
    #comprar con lo que se tiene en y actualizar el repo 

}

function m_fix_fzf() 
{
    Write-Host "Restaurando las version del archivos desde repositorio git ..."
    cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf
    git pull origin master
    git restore plugin\fzf.vim

    cd ${env:USERPROFILE}\vimfiles\pack\ui\opt\fzf.vim
    git pull origin master
    git restore autoload\fzf\vim.vim

    cd ${env:LOCALAPPDATA}\nvim-data\site\pack\packer\opt\fzf
    git pull origin master
    git restore plugin\fzf.vim

    cd ${env:LOCALAPPDATA}\nvim-data\site\pack\packer\opt\fzf.vim
    git pull origin master
    git restore autoload\fzf\vim.vim

    Write-Host ""
    Write-Host "Fixing Vim ..."
    Write-Host "Last vs Fixed (fzf)     : Use 'diffget' para corregir la version ultima, 'windo diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:USERPROFILE`}\vimfiles\pack\ui\opt\fzf\plugin\fzf.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf\plugin\fzf.vim"
    Write-Host "Last vs Fixed (fzf.vim) : Use 'diffget' para corregir la version ultima, windo 'diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:USERPROFILE`}\vimfiles\pack\ui\opt\fzf.vim\autoload\fzf\vim.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim"
    Write-Host ""
    Write-Host ""
    Write-Host "Fixing NeoVim ..."
    Write-Host "Last vs Fixed (fzf)     : Use 'diffget' para corregir la version ultima, 'windo diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:LOCALAPPDATA`}\nvim-data\site\pack\packer\opt\fzf\plugin\fzf.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf\plugin\fzf.vim"
    Write-Host "Last vs Fixed (fzf.vim) : Use 'diffget' para corregir la version ultima, 'windo diffoff' para ingresar al modo normal, luego guarde y salga"
    Write-Host "     vim -d `$`{env:LOCALAPPDATA`}\nvim-data\site\pack\packer\opt\fzf.vim\autoload\fzf\vim.vim `$`{env:USERPROFILE`}\.files\vim\packages\fixes\fzf.vim\autoload\fzf\vim.vim"
    
    Write-Host ""
    Write-Host "Revise los singuientes enlaces simbolicos al script '%USERPROFILE%\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1':"
    Write-Host "En Vim   : dir `$`{env:USERPROFILE`}\vimfiles\pack\ui\opt\fzf.vim\bin\preview.ps1"
    Write-Host "     MKLINK %USERPROFILE%\vimfiles\pack\ui\opt\fzf.vim\bin\preview.ps1 %USERPROFILE%\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1"
    Write-Host "En NeoVim: dir %LOCALAPPDATA%\nvim-data\site\pack\packer\opt\fzf.vim\bin\preview.ps1"
    Write-Host "     MKLINK %LOCALAPPDATA%\nvim-data\site\pack\packer\opt\fzf.vim\bin\preview.ps1 %USERPROFILE%\.files\vim\packages\fixes\fzf.vim\bin\preview.ps1"

}

$g_fix_fzf=0
if($args.count -ge 1) {
    if($args[0] -eq "1") {
        $g_fix_fzf=1
    }
}

if($g_fix_fzf -eq 0) {
    m_update_vim_repository
}
else {
    m_fix_fzf
}

