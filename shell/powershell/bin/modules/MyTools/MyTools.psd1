@{
    RootModule = 'MyTools.psm1'
    ModuleVersion = '1.0.0'

    # Restringir las funciones publicas del modulo
    FunctionsToExport = @(
        'Sync-Folder',
        'Get-SyncFolderHelp',
        'Invoke-WezTermCommand'
    )

    VariablesToExport = @()
    AliasesToExport = @()
}
