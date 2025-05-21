--------------------------------------------------------------------------------------------------
-- Snippets> LuaSnip
--------------------------------------------------------------------------------------------------
--
-- URL : https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
--       https://github.com/L3MON4D3/LuaSnip/wiki/Nice-Configs
--
-- > El snippet siempre se muestra como parte de 'completion' (manual o automatico).
--   Cuando se acepta el item vinculado al snippet este se expande y se inicia la navegación al
--   1er nodo del snippet.
-- > Un snippet esta formado por 1 o mas nodos. Un nodo del snippet es un placeholder/fragmento
--   que se permite una modificación
--

local luasnip = require('luasnip')
local types = require("luasnip.util.types")

luasnip.config.setup({

    history = true,

    update_events = { "TextChanged", "TextChangedI" },

    --region_check_events = "CursorHold",

    --enable_autosnippets = true,

    -- Establecer un indicar del tipo de nodo de un snippet
    -- > Ver el 'Highlight Group' disponibles usando ':highlight'
    -- > Los highlight groups usados y definidos por tema 'Catppuccin' son:
    --   https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md
	ext_opts = {
		[types.choiceNode] = {
			active = {
				virt_text = { { "●", "Error" } },
			}
		},
		[types.insertNode] = {
			active = {
				virt_text = { { "●", "Title" } },
			}
		}
	},
})


--1. Cargar la implementacion de snippet
--   Debera incluir los snippet en las carpetas reservadas
--   Usando el plugin 'friendly-snippets' que estan 'runtimepath'
--   https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#add-snippets
require("luasnip.loaders.from_vscode").lazy_load()


--2. Saltar entre los nodos de un snippet expandido

-- Ir al nodo siguiente
vim.keymap.set({"i", "s"}, "<C-f>", function()
    if luasnip.expand_or_jumpable() then
    --if luasnip.expand_or_locally_jumpable() then
        --luasnip.jump(1)
        luasnip.expand_or_jump()
    else
        return '<C-f>'
    end
end , { silent = true, noremap = true, expr = true, })

-- Ir al nodo anterior
vim.keymap.set({"i", "s"}, "<C-b>", function()
    if luasnip.jumpable(-1) then
        luasnip.jump(-1)
    else
        return '<C-f>'
    end
end, { silent = true, noremap = true, expr = true, })



--3. Navegar entre valores/opciones de un mismo nodo
vim.keymap.set({"i", "s"}, "<C-E>", function()
	if luasnip.choice_active() then
		luasnip.change_choice(1)
    else
        return '<C-E>'
	end
end, { silent = true, noremap = true, expr = true, })

--------------------------------------------------------------------------------------------------
-- Completition> Configuración del Completado y sus fuentes
--------------------------------------------------------------------------------------------------
--
-- TODO Modificar para usar directamente el API de NeoVim 0.11
--
-- File          = "󰈙",
-- Module        = "",
-- Namespace     = "󰦮",
-- Package       = "",
-- Class         = "󰆧",
-- Method        = "󰊕",
-- Property      = "",
-- Field         = "",
-- Constructor   = "",
-- Enum          = "",
-- Interface     = "",
-- Function      = "󰊕",
-- Variable      = "󰀫",
-- Constant      = "󰏿",
-- String        = "",
-- Number        = "󰎠",
-- Boolean       = "󰨙",
-- Array         = "󱡠",
-- Object        = "",
-- Key           = "󰌋",
-- Null          = "󰟢",
-- EnumMember    = "",
-- Struct        = "󰆼",
-- Event         = "",
-- Operator      = "󰆕",
-- TypeParameter = "󰗴",
--

--1. Fuente de completado: Valores de 'choice nodes'
require('cmp_luasnip_choice').setup({
    -- Automatically open nvim-cmp on choice node (default: true)
    auto_open = true,
});

--2. Fuentes de completado: Otros
--   Se usara los valores pore defecto.

--2. Configurar el completado para todos los tipos de archivos
local cmp = require('cmp')

-- Valores usados durante la definicion del completado.
-- Opcion de la seleccion de un item del completado.
local select_opts = { behavior = cmp.SelectBehavior.Select }

-- Puntero a la funcion usado para validar si el cursor está al principio de la línea o si el
-- carácter anterior es un espacio en blanco.
local check_backspace = function()
    -- Obtiene la posicion del caracter anterior al cursor actual.
    local col = vim.fn.col "." - 1

    -- Obtiene el caracter y valida que sea un espacio en blanco (espacio, tabulacion, etc)
    return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
end


cmp.setup({

    --preselect = cmp.PreselectMode.None,

    -- Funciones invocados por el completado cuando el elemento es un snippet.
    snippet = {

        -- Expansion del snippet cuando el elemento es aceptado y es un snippet.
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },

    -- Fuentes de completado: Se colocan los nombres con que registro la fuente en CMP
    -- > prioirity : orden en que aparecen las sugerencias en las lista de autocompletado
    -- > keyword_length : cantidad de caracteres necesarios realizar la busqueda en la fuente y mostrar el popup
    -- > trigger_characters : si esta antes de un caracter espcial, el lenght(keyword) = 0, pero  mostrar el popup
    sources = {
        { name = 'path', priority = 4, },
        { name = 'nvim_lsp', keyword_length = 1, priority = 8, },
        --{ name = 'nvim_lsp', keyword_length = 2, trigger_characters = { '.', '[' } },
        { name = 'buffer', keyword_length = 3, priority = 7, },
        { name = 'luasnip', priority = 5, },
        { name = 'luasnip_choice', },
    },

    --sorting = {
    --    priority_weight = 1.0,
    --    comparators = {
    --        cmp.config.compare.locality,
    --        cmp.config.compare.recently_used,
    --        cmp.config.compare.score,
    --        cmp.config.compare.offset,
    --        cmp.config.compare.order,
    --    },
    --},

    -- Controla la apariencia de la ventana donde se muestra la documentación: usar bordes
    window = {
        documentation = cmp.config.window.bordered()
    },

    -- Formateo de cada elemento del popup de completado
    formatting = {
        --Controla el orden en el que aparecen los elementos de un item.
        fields = {'menu', 'abbr', 'kind'},
        --Determina el formado del item
        format = function(entry, item)
                --Iconos de tipo de item
                local kind_icons = {
                     Text = " ",
                     Method = "󰆧 ",
                     Function = "󰊕 ",
                     Constructor = " ",
                     Field = "󰇽 ",
                     Variable = "󰂡 ",
                     Class = "󰠱 ",
                     Interface = " ",
                     Module = " ",
                     Property = "󰜢 ",
                     Unit = " ",
                     Value = "󰎠 ",
                     Enum = " ",
                     Keyword = "󰌋 ",
                     Snippet = " ",
                     Color = "󰏘 ",
                     File = "󰈙 ",
                     Reference = " ",
                     Folder = "󰉋 ",
                     EnumMember = " ",
                     Constant = "󰏿 ",
                     Struct = " ",
                     Event = " ",
                     Operator = "󰆕 ",
                     TypeParameter = "󰅲 ",
               }

                --Mostrar tipo de elemento con su icono antepuesto (concetenadolo)
                item.kind = string.format("%s %s", kind_icons[item.kind], item.kind)

                --Icono por cada fuente de completado (los que no se encuentra, se mostraran en vacio)
                local menu_icons = {
                    nvim_lsp = 'λ',
                    luasnip = '',
                    buffer = '',
                    path = '',
                    nvim_lsp_signature_help = '⋗',
                }

                --Mostrar solo el icono (no se concatena el icono con el nombre)
                item.menu = menu_icons[entry.source.name]
                return item
        end,
    },

    -- Reglas de busqueda con la que se encuentra un item del popup de completado
    --matching = {
    --    --Por defecto la busqueda es difusa y no una busqueda exacta.
    --    disallow_fuzzy_matching = false,
    --},

    -- Atajos de teclado usado en el popup de completado
    -- Ejemplo de configuracion: https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings
    mapping = {

        -- ----------------------------------------------------------------------------------
        -- Popup de completado
        -- ----------------------------------------------------------------------------------

        --Navegar entre los item (sugerencias) de completado mostrado en el popup
        ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
        ['<Down>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<C-n>'] = cmp.mapping.select_next_item(select_opts),

        --Desplazar el texto en el popup de documentación o preview
        ['<PageDown>'] = cmp.mapping.scroll_docs(-4),
        ['<PageUp>'] = cmp.mapping.scroll_docs(4),

        --Cancelar el completado (Cerrar el popup de completado)
        ['<C-e>'] = cmp.mapping.abort(),

        -- Aceptar el completado
        -- > Confirma el item actualmente seleccionado en la lista de completado.
        -- > Si no hay ninguno seleccionado pero 'select = true', el primer item será automáticamente elegido y confirmado.

        --['<CR>'] = cmp.mapping.confirm({select = true}),
        ['<CR>'] = cmp.mapping(function(fallback)
                if cmp.visible() then

                    -- Confimar el item (si contiene snippet, cmp llamará a 'snippet.expand()')
                    cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })

                else
                    -- Inserta la tecla (salto de línea) y no ejecuta accion alguna.
                    fallback()
                end
            end),

        -- Si no hay elemento selecionado se comporta como <C-e> (solo cierra el popup de completado)
        ['<C-y>'] = cmp.mapping.confirm({ select = false, }),


        --Si se muestra el popup de completado (si la esta en un espacio, no se realiza el completado y escribe 'Tab')
        ['<Tab>'] = cmp.mapping(function(fallback)

                -- Si el popup de completado esta visible
                if cmp.visible() then
                    cmp.select_next_item(select_opts)

                --Si caracter anterior son vacios o es inicio de linea
                elseif check_backspace() then

                    -- Inserta la tecla (<Tab>) y no ejecuta accion alguna.
                    fallback()

                else
                    -- Abre manualmente el menú de completado
                    cmp.complete()
                end

            end, {'i', 's'}),

        --Si se muestra el popup de completado, navega al item anterior
        ['<S-Tab>'] = cmp.mapping(function(fallback)

                -- Si el popup de completado esta visible
                if cmp.visible() then
                    cmp.select_prev_item(select_opts)

                --Si caracter anterior son vacios o es inicio de linea
                elseif check_backspace() then

                    -- Inserta la tecla (<Tab>) y no ejecuta accion alguna.
                    fallback()

                else
                    -- Abre manualmente el menú de completado
                    cmp.complete()
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
--Completition> Configuración del Popup de 'Signature Help'
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
