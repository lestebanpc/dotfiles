
--Si se usa COC
if (vim.g.use_coc_in_nvim == 1) then
    return
end

--------------------------------------------------------------------------------------------------
-- Configuracion inicial del LSP Client nativo (Keymapping y otros)
---------------------------------------------------------------------------------------------------

require('ide.native_lsp')



--------------------------------------------------------------------------------------------------
-- Completition y Popup de 'Signature Help'
--------------------------------------------------------------------------------------------------

require('ide.completion')



--------------------------------------------------------------------------------------------------
-- Diagnostic (incluyendo un Lightbulb)
--------------------------------------------------------------------------------------------------

require('ide.diagnostic')



--------------------------------------------------------------------------------------------------
-- Adaptadores LSP
--------------------------------------------------------------------------------------------------

-- Configuraciones del cliente LSP usando adapatadores de 'lspconfig' o custom
require('ide.adapters.lsp_basics')

-- Configuraciones del cliente LSP usando adaptadores creados por un plugin
require('ide.adapters.lsp_plugins')


