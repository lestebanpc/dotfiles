
function m_update_repository($p_path) 
{
    if(Test-Path $p_path) {
        Write-Host "Folder \"${p_path}\" not exists"
        return 9
    }

    Write-Host "-------------------------------------------------------------------------------------------------"
    Write-Host "- Repository Git para VIM: \"${p_path}\""
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
    $l_remote_branch="$(git rev-parse --abbrev-ref --symbolic-full-name @{u})"

    Write-Host "Fetching from remote repository \"${l_remote}\"..."
    git fetch $l_remote

    Write-Host "Updating local branch \"${l_local_branch}\"..."

    git merge-base --is-ancestor ${l_remote_branch} HEAD
    if (! $?) {
        Write-Host 'Fast-forward not possible. Rebasing...'
        git rebase --preserve-merges --stat ${l_remote_branch}
        return 2
    }

    Write-Host 'Fast-forward possible. Merging...'
    git merge --ff-only --stat ${l_remote_branch}
    return 0   

}

function m_update_vim_repository()
{
    $folders = Get-ChildItem .\vimfiles\pack\ -Attributes Directory+Hidden -ErrorAction SilentlyContinue -Filter ".git" -Recurse | Select-Object "FullName"
    foreach ( $folder in $folders ) {
        $repo_path = Split-Path -Parent $folder.FullName
        m_update_repository $repo_path
    }

}

