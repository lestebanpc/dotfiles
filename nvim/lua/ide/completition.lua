--------------------------------------------------------------------------------------------------
--Configuración del Completado (Source: LSP, Snippets, Buffer, ...)
--------------------------------------------------------------------------------------------------

--1. Extendiendo las capacidad de autocompletado de LSPConfig: Usando la fuente CMP para LSP 
local lsp_config = require('lspconfig')
local cmp_lsp = require('cmp_nvim_lsp')

lsp_config.util.default_config.capabilities = vim.tbl_deep_extend(
    'force',
    lsp_config.util.default_config.capabilities,
    cmp_lsp.default_capabilities()
)

--2. Configurar el completado para todos los tipos de archivos
local cmp = require('cmp')
local snippet = require('luasnip')

--Cargar '.lazy_load()' las implementacion de snippet (por ejemplo 'friendly-snippets') que estan 'runtimepath'
--snippet.loaders.from_vscode.lazy_load()
require("luasnip.loaders.from_vscode").lazy_load()

--xxx
local select_opts = {behavior = cmp.SelectBehavior.Select}

cmp.setup({

    --Configuracion de los Snippets
    snippet = {
        --Expansion de un snippets
        expand = function(args)
                --Usar los snippets registros por LuaSnip para expnadirlos
                snippet.lsp_expand(args.body)    
            end
    },

    --Fuentes de completado: Se colocan los nombres con que registro la fuente en CMP
    --  'prioirity': orden en que aparecen las sugerencias en las lista de autocompletado
    --  'keyword_length': cantidad de caracteres necesarios realizar la busqueda en la fuente y mostrar el popup
    --  'trigger_characters': si esta antes de un caracter espcial, el lenght(keyword) = 0, pero  mostrar el popup
    sources = {
        { name = 'path' },
        { name = 'nvim_lsp' },
        --{ name = 'nvim_lsp', keyword_length = 3, trigger_characters = { '.', '[' } },
        --{ name = 'nvim_lsp', keyword_length = 3 },
        { name = 'buffer', keyword_length = 3 },
        { name = 'luasnip', keyword_length = 2 },
    },

    --Controla la apariencia de la ventana donde se muestra la documentación: usar bordes
    window = {
        documentation = cmp.config.window.bordered()
    },

    --Formateo de cada elemento del popup de completado
    formatting = {
        --Controla el orden en el que aparecen los elementos de un item.
        fields = {'menu', 'abbr', 'kind'},
        --Determina el formado del item
        format = function(entry, item)
                --Iconos de tipo de item
                local kind_icons = {
                    Class = "ﴯ",
                    Color = "",
                    Constant = "",
                    Constructor = "",
                    Enum = "",
                    EnumMember = "",
                    Event = "",
                    Field = "",
                    File = "",
                    Folder = "",
                    Function = "",
                    Interface = "",
                    Keyword = "",
                    Method = "",
                    Module = "",
                    Operator = "",
                    Property = "ﰠ",
                    Reference = "",
                    Snippet = "",
                    Struct = "",
                    Text = "",
                    TypeParameter = "",
                    Unit = "",
                    Value = "",
                    Variable = "",
                }
                
                --Mostrar tipo de elemento con su icono antepuesto (concetenadolo)
                item.kind = string.format("%s %s", kind_icons[item.kind], item.kind)

                --Icono por cada fuente de completado (los que no se encuentra, se mostraran en vacio)
                local menu_icons = {
                    nvim_lsp = 'λ',
                    luasnip = '',
                    buffer = '',
                    path = '',
                    nvim_lsp_signature_help = '',                
                }

                --Mostrar solo el icono (no se concatena el icono con el nombre)
                item.menu = menu_icons[entry.source.name]
                return item
        end,
    },

    --Reglas de busqueda con la que se encuentra un item del popup de completado
    --matching = {
    --    --Por defecto la busqueda es difusa y no una busqueda exacta.
    --    disallow_fuzzy_matching = false,
    --},

    --Atajos de teclado usado en el completado
    mapping = {
        --Navegar entre las sugerencias
        ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
        ['<Down>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<C-n>'] = cmp.mapping.select_next_item(select_opts),
       
        --Desplazar el texto de la ventada de navegacion
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),

        --Cancelar el completado
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({select = false}),
        
        --Salta al proximo placeholder de un snippet
        ['<C-d>'] = cmp.mapping(function(fallback)
                if snippet.jumpable(1) then
                    snippet.jump(1)
                else
                    fallback()
                end
            end, {'i', 's'}),

        --Salta al placeholder anterior de snippet
        ['<C-b>'] = cmp.mapping(function(fallback)
                if snippet.jumpable(-1) then
                    snippet.jump(-1)
                else
                    fallback()
                end
            end, {'i', 's'}),

        --Autocmpletado con 'Tab' (si la linea es vacia, no se autocompleta y escribe 'Tab')
        ['<Tab>'] = cmp.mapping(function(fallback)
                local col = vim.fn.col('.') - 1

                if cmp.visible() then
                    cmp.select_next_item(select_opts)
                elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                    fallback()
                else
                    cmp.complete()
                end
            end, {'i', 's'}),

        --Si la lista de sugerencias es visible, navega al item anterior
        ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item(select_opts)
                else
                    fallback()
                end
            end, {'i', 's'}),
    },
})


--3. Configurar el completado para un tipos de archivo especifico
--cmp.setup.filetype({ 'yourfiletype' }, {
--   -- Options here
--
--})


--------------------------------------------------------------------------------------------------
--Configuración del Popup de 'Signature Help'
--------------------------------------------------------------------------------------------------

local cfg = {
    debug = false,              -- set to true to enable debug logging
    log_path = vim.fn.stdpath("cache") .. "/lsp_signature.log", -- log dir when debug is on
                                                                -- default is  ~/.cache/nvim/lsp_signature.log
    verbose = false,            -- show debug line number
  
    bind = true,                -- This is mandatory, otherwise border config won't get registered.
                                -- If you want to hook lspsaga or other signature handler, pls set to false
    doc_lines = 10,             -- will show two lines of comment/doc(if there are more than two lines in doc, will be truncated);
                                -- set to 0 if you DO NOT want any API comments be shown
                                -- This setting only take effect in insert mode, it does not affect signature help in normal
                                -- mode, 10 by default
  
    max_height = 25,            -- max height of signature floating_window
    max_width = 130,             -- max_width of signature floating_window
    noice = false,              -- set to true if you using noice to render markdown
    wrap = true,                -- allow doc/signature text wrap inside floating_window, useful if your lsp return doc/sig is too long
    
    floating_window = true,     -- show hint in a floating window, set to false for virtual text only mode
  
    floating_window_above_cur_line = true,  -- try to place the floating above the current line when possible Note:
                                            -- will set to true when fully tested, set to false will use whichever side has more space
                                            -- this setting will be helpful if you do not want the PUM and floating win overlap
  
    floating_window_off_x = 1,  -- adjust float windows x position. 
                                -- can be either a number or function
    floating_window_off_y = 0,  -- adjust float windows y position. e.g -2 move window up 2 lines; 2 move down 2 lines
                                -- can be either number or function, see examples
  
    close_timeout = 4000,       -- close floating window after ms when laster parameter is entered
    fix_pos = false,            -- set to true, the floating window will not auto-close until finish all parameters
    hint_enable = true,         -- virtual hint enable
    hint_prefix = "📜 ",        -- Panda for parameter, NOTE: for the terminal not support emoji, might crash
    hint_scheme = "String",
    hi_parameter = "LspSignatureActiveParameter",   -- how your parameter will be highlight
    handler_opts = {
        border = "rounded"        -- double, rounded, single, shadow, none, or a table of borders
    },
  
    always_trigger = false,     -- sometime show signature on new line or in middle of parameter can be confusing, set it to false for #58
  
    auto_close_after = nil,     -- autoclose signature float win after x sec, disabled if nil.
    extra_trigger_chars = {},   -- Array of extra characters that will trigger signature completion, e.g., {"(", ","}
    zindex = 200,               -- by default it will be on top of all floating windows, set to <= 50 send it to bottom
  
    padding = '',               -- character to pad on left and right of signature can be ' ', or '|'  etc
  
    transparency = nil,         -- disabled by default, allow floating win transparent value 1~100
    shadow_blend = 36,          -- if you using shadow as border use this set the opacity
    shadow_guibg = 'Black',     -- if you using shadow as border use this set the color e.g. 'Green' or '#121315'
    timer_interval = 200,       -- default timer check interval set to lower value if you want to reduce latency

    --> Teclas para manejo del popup 'Signature Popup'

    --Abrir/cerrar el popup en modo edición (no se mapea en modo normal)
    toggle_key = '<C-\\>',
  
    --Coloca la siguente 'signature' en la actual (solo en modo insert>popup).
    --generalmente no se usa debido a que automaticamente trata de ubicar el 'signature' segun los
    --argumentos escritos.
    select_signature_key = '<C-k>',

    --imap, use nvim_set_current_win to move cursor between current win and floating
    move_cursor_key = nil,
}

local signature = require('lsp_signature')
signature.setup(cfg)




