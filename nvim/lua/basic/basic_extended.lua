------------------------------------------------------------------------------------------------
-- Treesitter (ofrece un AST y 'Syntax Highlighting')
------------------------------------------------------------------------------------------------
--
-- URL        : https://github.com/nvim-treesitter/nvim-treesitter
-- Treesitter como un analizador del arbol sinstanctico de codigo (AST) el cual permite:
--  - Resaltado de sintaxis de codigo (highlighting)
--  - Navegar y selecionar objetos del arbol AST.
--  - Indentación automática mejorada.
--  - Incremental selection (seleccionar nodos de sintaxis con combinaciones de teclas).
--  - Folding basado en estructura sintáctica.
--

-- Data usado para configurar el treesitter
local treesitter_data= {

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    -- Enable syntax highlighting
    highlight = {
        enable = true
    },

    -- Enable indentation
    indent = {
        enable = true
    },

    -- Habilitar acciones para el 'Smart selection' de nodos del AST
    -- Se permite incremantar la selección ('Expand Selection') y reducir la selección ('Shrink Selection')
    incremental_selection = {
        enable = true,
        keymaps = {
            -- Accion de modo NORMAL :
            init_selection = "<C-]>",
            -- Acciones del modo VISUAL :
            node_incremental = "<C-]>",
            scope_incremental = false,
            node_decremental = "<bs>",
        },
    },
}

-- Definir la lista de parser tree-sitter que debera ser compilados/instalados (se valida durante el inicio)
if vim.g.enable_compile_treesitter then

    local parsers =  {
        "html", "css", "javascript", "jq", "json", "yaml", "xml",
        "toml", "typescript", "proto", "make", "sql",
        "vim", "vimdoc", "markdown", "markdown_inline",
        "bash", "c", "cpp", "lua", "java", "kotlin", " rust",
        "go", "c_sharp"
    }


    if vim.g.use_ide then
        parsers =  {
            "html", "css", "javascript", "jq", "json", "yaml", "xml",
            "toml", "typescript", "latex", "proto", "make", "sql",
            "vim", "vimdoc", "markdown", "markdown_inline",
            "bash", "c", "cpp", "lua", "java", "kotlin", " rust",
            "swift", "go", "c_sharp"
        }
    end

    treesitter_data.ensure_installed = parsers

end

-- Configurar treesitter
local treesitter = require("nvim-treesitter")
--local treesitter = require("nvim-treesitter.configs")
treesitter.setup(treesitter_data)


------------------------------------------------------------------------------------------------
-- Treesitter> Plugin 'TextObjects'
------------------------------------------------------------------------------------------------
--
-- URL                 : https://github.com/nvim-treesitter/nvim-treesitter-textobjects
-- Builtin TextObjects :
--   > https://github.com/nvim-treesitter/nvim-treesitter-textobjects/blob/main/BUILTIN_TEXTOBJECTS.md
--   > Permite generar 'query string' requerido para definir el keymap, por ejemplo:
--     > '@function.inner' que representa el contenido interno de la funcion.
-- Examples            :
--  > Old configuration (usa la rama 'master')
--    > https://www.josean.com/posts/nvim-treesitter-and-textobjects
--    > https://github.com/josean-dev/dev-environment-files/blob/main/.config/nvim/lua/josean/plugins/nvim-treesitter-text-objects.lua
--    > https://www.youtube.com/watch?v=CEMPq_r8UYQ
-- > New configuration (usa la rama 'main')
--    >
--

-- Disable entire built-in ftplugin mappings to avoid conflicts.
-- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
vim.g.no_plugin_maps = true

-- Configuracion del modulo de navigacion de objetos de TreeSitter.
local ts_textobjects_data = {

    -- Opciones de configuracion para 'selection of continues AST nodes'.
    -- > Usa keymappings en el modo visual o el submodo 'operator-pending' del modo normal.
    select = {

        -- Si no este dentro del objeto, busca el siguiente mas cercadno (similar to targets.vim)
        lookahead = true,

        -- Personalizar el modo de seleccion (por caracter o por linea o bloque) segun el 'query string' usado.
        -- > Puede ser una funcion que tiene 2 parametros (el 'query string' y el 'modo de seleccion' como 'v', 'V','<c-v>')
        --   y retorna una table donde indica el 'query string' y el modo de seleccion.
        --selection_modes = {
        --    ['@parameter.outer']  = 'v',
        --    ['@function.outer']   = 'V',
        --    ['@class.outer']      = '<c-v>',
        --},

        -- If you set this to `true` then any textobject is extended to include preceding or succeeding whitespace.
        -- > Succeeding whitespace has priority in order to act similarly to eg the built-in `ap`.
        -- > Valor por defecto es 'false'.
        -- > Puede ser una funcion que tiene 2 parametros (el 'query string' y el 'modo de seleccion' como 'v', 'V','<c-v>')
        --   y retorna true o false.
        include_surrounding_whitespace = false,
    },

    -- Opciones de configuracion para 'swapping AST nodes'.
    -- > Usa keymappings en el modo normal.
    --swap = {
    --},

    -- Opciones de configuracion para 'move between AST nodes'
    -- > Usa keymappings en el modo normal, visual o el submodo 'operator-pending' del modo normal.
    move = {

        -- Permite adicionar los jumps al jumplist de VIM.
        -- Ello permite avanzar y retroceder a través de ellos usuando con <C-o>(atrás) y <C-i> (adelante).
        set_jumps = true,

    },
}

local ts_to = require("nvim-treesitter-textobjects")
ts_to.setup(ts_textobjects_data)


-- Keymaps usados para la 'selección de nodos AST continuos'.
-- > Esto keymaps solo aplica en los siguiente modos:
--   > Si esta en el modo visual:
--     > Selección x caracter: v, keymap
--     > Selección x lineas  : V, keymap
--     > Selección x bloques : ctrl + v/q, keymap
--   > Si es en submodo 'operator-pending' del modo normal:
--     > Delete              : d, keymap
--     > Change              : c, keymap
--     > Yank                : y, keymap
local function ts_to_keymap_select(p_keys, p_query_string, p_description)
    local l_ts_to_select = require("nvim-treesitter-textobjects.select")
    vim.keymap.set({"x", "o"}, p_keys, function() l_ts_to_select.select_textobject(p_query_string, "textobjects") end, { noremap = true, buffer = false, desc = p_description })
end

ts_to_keymap_select("a=", "@assignment.outer" , "Select outer part of an assignment")
ts_to_keymap_select("i=", "@assignment.inner" , "Select inner part of an assignment")

ts_to_keymap_select("l=", "@assignment.lhs"   , "Select left hand side of an assignment")
ts_to_keymap_select("r=", "@assignment.rhs"   , "Select right hand side of an assignment")

ts_to_keymap_select("aa", "@parameter.outer"  , "Select outer part of a parameter/argument")
ts_to_keymap_select("ia", "@parameter.inner"  , "Select inner part of a parameter/argument")

ts_to_keymap_select("ai", "@conditional.outer", "Select outer part of a conditional")
ts_to_keymap_select("ii", "@conditional.inner", "Select inner part of a conditional")

ts_to_keymap_select("al", "@loop.outer"       , "Select outer part of a loop")
ts_to_keymap_select("il", "@loop.inner"       , "Select inner part of a loop")

ts_to_keymap_select("af", "@call.outer"       , "Select outer part of a function call")
ts_to_keymap_select("if", "@call.inner"       , "Select inner part of a function call")

ts_to_keymap_select("am", "@function.outer"   , "Select outer part of a method/function definition")
ts_to_keymap_select("im", "@function.inner"   , "Select inner part of a method/function definition")

ts_to_keymap_select("ac", "@class.outer"      , "Select outer part of a class")
ts_to_keymap_select("ic", "@class.inner"      , "Select inner part of a class")



-- Keymap para 'swapping AST nodes' (intercambios de nodos AST).
-- > Este keymaps solo aplica en el modo normal.
local function ts_to_keymap_swap_next(p_keys, p_query_string, p_description)
    local l_ts_to_swap = require("nvim-treesitter-textobjects.swap")
    vim.keymap.set("n", p_keys, function() l_ts_to_swap.swap_next(p_query_string) end, { noremap = true, buffer = false, desc = p_description })
end

local function ts_to_keymap_swap_prev(p_keys, p_query_string, p_description)
    local l_ts_to_swap = require("nvim-treesitter-textobjects.swap")
    vim.keymap.set("n", p_keys, function() l_ts_to_swap.swap_previous(p_query_string) end, { noremap = true, buffer = false, desc = p_description })
end

ts_to_keymap_swap_next("<space>na", "@parameter.inner", "Swap parameters/argument with next")
ts_to_keymap_swap_next("<space>nm", "@function.outer" , "Swap function with next")

ts_to_keymap_swap_prev("<space>pa", "@parameter.inner", "Swap parameters/argument with prev")
ts_to_keymap_swap_prev("<space>pm", "@function.outer" , "Swap function with previous")


-- Keymaps usados 'move between AST nodes'
-- > Esto keymaps solo aplica en los siguiente modos:
--   > Si esta en el modo normal.
--   > Si esta en el modo visual:
--     > Selección x caracter: v, keymap
--     > Selección x lineas  : V, keymap
--     > Selección x bloques : ctrl + v/q, keymap
--   > Si es en submodo 'operator-pending' del modo normal:
--     > Delete              : d, keymap
--     > Change              : c, keymap
--     > Yank                : y, keymap

-- > Argumentos
--   > p_query_group
--     > You can pass a query group to use query from `queries/<lang>/<queriy_group>.scm file in your runtime path.
--       Ejemplos: `locals.scm` o `folds.scm`
local function ts_to_keymap_move_goto_next(p_keys, p_query_string, p_query_group, p_description)
    local l_ts_to_move = require("nvim-treesitter-textobjects.move")
    local l_query_group = p_query_group or "textobjects"
    vim.keymap.set({ "n", "x", "o" }, p_keys, function() l_ts_to_move.goto_next(p_query_string, l_query_group) end, { noremap = true, buffer = false, desc = p_description })
end

local function ts_to_keymap_move_goto_prev(p_keys, p_query_string, p_query_group, p_description)
    local l_ts_to_move = require("nvim-treesitter-textobjects.move")
    local l_query_group = p_query_group or "textobjects"
    vim.keymap.set({ "n", "x", "o" }, p_keys, function() l_ts_to_move.goto_previous(p_query_string, l_query_group) end, { noremap = true, buffer = false, desc = p_description })
end

local function ts_to_keymap_move_goto_next_start(p_keys, p_query_string, p_query_group, p_description)
    local l_ts_to_move = require("nvim-treesitter-textobjects.move")
    local l_query_group = p_query_group or "textobjects"
    vim.keymap.set({ "n", "x", "o" }, p_keys, function() l_ts_to_move.goto_next_start(p_query_string, l_query_group) end, { noremap = true, buffer = false, desc = p_description })
end

local function ts_to_keymap_move_goto_next_end(p_keys, p_query_string, p_query_group, p_description)
    local l_ts_to_move = require("nvim-treesitter-textobjects.move")
    local l_query_group = p_query_group or "textobjects"
    vim.keymap.set({ "n", "x", "o" }, p_keys, function() l_ts_to_move.goto_next_end(p_query_string, l_query_group) end, { noremap = true, buffer = false, desc = p_description })
end

local function ts_to_keymap_move_goto_prev_start(p_keys, p_query_string, p_query_group, p_description)
    local l_ts_to_move = require("nvim-treesitter-textobjects.move")
    local l_query_group = p_query_group or "textobjects"
    vim.keymap.set({ "n", "x", "o" }, p_keys, function() l_ts_to_move.goto_previous_start(p_query_string, l_query_group) end, { noremap = true, buffer = false, desc = p_description })
end

local function ts_to_keymap_move_goto_prev_end(p_keys, p_query_string, p_query_group, p_description)
    local l_ts_to_move = require("nvim-treesitter-textobjects.move")
    local l_query_group = p_query_group or "textobjects"
    vim.keymap.set({ "n", "x", "o" }, p_keys, function() l_ts_to_move.goto_previous_end(p_query_string, l_query_group) end, { noremap = true, buffer = false, desc = p_description })
end

ts_to_keymap_move_goto_next_start( "]f", "@call.outer"       , nil       , "Next function call start"      )
ts_to_keymap_move_goto_next_start( "]m", "@function.outer"   , nil       , "Next method/function def start")
ts_to_keymap_move_goto_next_start( "]c", "@class.outer"      , nil       , "Next class start"              )
ts_to_keymap_move_goto_next_start( "]i", "@conditional.outer", nil       , "Next conditional start"        )
ts_to_keymap_move_goto_next_start( "]l", "@loop.outer"       , nil       , "Next loop start"               )
ts_to_keymap_move_goto_next_start( "]s", "@scope"            , "locals"  , "Next scope"                    )
ts_to_keymap_move_goto_next_start( "]z", "@fold"             , "folds"   , "Next fold"                     )

ts_to_keymap_move_goto_next_end(   "]F", "@call.outer"       , nil       , "Next function call end"      )
ts_to_keymap_move_goto_next_end(   "]M", "@function.outer"   , nil       , "Next method/function def end")
ts_to_keymap_move_goto_next_end(   "]C", "@class.outer"      , nil       , "Next class end"              )
ts_to_keymap_move_goto_next_end(   "]I", "@conditional.outer", nil       , "Next conditional end"        )
ts_to_keymap_move_goto_next_end(   "]L", "@loop.outer"       , nil       , "Next loop end"               )

ts_to_keymap_move_goto_prev_start( "[f", "@call.outer"       , nil       , "Prev function call start"      )
ts_to_keymap_move_goto_prev_start( "[m", "@function.outer"   , nil       , "Prev method/function def start")
ts_to_keymap_move_goto_prev_start( "[c", "@class.outer"      , nil       , "Prev class start"              )
ts_to_keymap_move_goto_prev_start( "[i", "@conditional.outer", nil       , "Prev conditional start"        )
ts_to_keymap_move_goto_prev_start( "[l", "@loop.outer"       , nil       , "Prev loop start"               )

ts_to_keymap_move_goto_prev_end(   "[F", "@call.outer"       , nil       , "Prev function call end"      )
ts_to_keymap_move_goto_prev_end(   "[M", "@function.outer"   , nil       , "Prev method/function def end")
ts_to_keymap_move_goto_prev_end(   "[C", "@class.outer"      , nil       , "Prev class end"              )
ts_to_keymap_move_goto_prev_end(   "[I", "@conditional.outer", nil       , "Prev conditional end"        )
ts_to_keymap_move_goto_prev_end(   "[L", "@loop.outer"       , nil       , "Prev loop end"               )

-- Permitir repitir el ultimo moviento de objeto realizado
local function ts_to_keymap_repeat_move_last(p_keys, p_previous, p_description)
    local l_ts_to_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
    local l_function = nil
    if p_previous then
        l_function = l_ts_to_repeat_move.repeat_last_move_previous
    else
        l_function = l_ts_to_repeat_move.repeat_last_move_next
    end

    vim.keymap.set({ "n", "x", "o" }, p_keys, l_function, { noremap = true, buffer = false, desc = p_description })
end

--local function ts_to_keymap_repeat_move_builtin(p_keys, p_type, p_description)
--    local l_ts_to_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
--    local l_function = nil
--
--    vim.keymap.set({ "n", "x", "o" }, p_keys, l_function, { expr = true, desc = p_description })
--end

ts_to_keymap_repeat_move_last(',' , 'Repeat the last move next')
ts_to_keymap_repeat_move_last('\\', 'Repeat the last move previous')

-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
--vim.keymap.set({ "n", "x", "o" }, "f", ts_texobjs_repeatable_move.builtin_f_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "F", ts_texobjs_repeatable_move.builtin_F_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "t", ts_texobjs_repeatable_move.builtin_t_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "T", ts_texobjs_repeatable_move.builtin_T_expr, { expr = true })



--------------------------------------------------------------------------------------------------
-- Completion> Auto-completado del 'command line'
--------------------------------------------------------------------------------------------------

if vim.g.cmdline_completion then

    --1. Configuración de las fuentes de completado
    --   Se usara los valores pore defecto.

    --2. Autocompletion for '/' and '?'
    --   > If you enabled `native_menu`, this won't work anymore).
    --   > Source : buffer
    local cmp = require('cmp')

    cmp.setup.cmdline({ '/', '?' }, {

        mapping = cmp.mapping.preset.cmdline(),

        -- Lista de source del modo insert
        -- > keyword_length     : cantidad de caracteres necesarios realizar la busqueda en la fuente y mostrar el popup.
        -- > trigger_characters : si no se tiene la cantidad de caracteres necesarios, es decir lenght(keyword) = 0,
        --   pero esta antes de un caracter especial de la lista, se muestra el popup de completado
        -- > group_index        : 'nvim-cmp' solo muestra los elementos de un 'group_index', el grupo source con menor
        --   valor y que tenga elementos. Si el grupo no general elementos, se va con el siguiente grupo.
        --   Por defecto su valor es 1.
        -- > prioirity          : orden que asigna un peso mayor para aparecer en la lista de autocompletado dentro de
        --   un mismo grupo 'group_index'. Valor entero que inicia desde 1, cuanto mayor es valor, mayor peso se tendra.
        sources = {
            { name = 'buffer', keyword_length = 3, },
        },

    })


    --3. Autocompletion for ':'
    --   > If you enabled `native_menu`, this won't work anymore).
    --   > Source : cmdline, path
    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = 'cmdline'        , group_index = 1, keyword_length = 2, },
            { name = 'path'           , group_index = 2, keyword_length = 2, },
        },
        matching = { disallow_symbol_nonprefix_matching = false },
    })

end


------------------------------------------------------------------------------------------------
-- UI> render-markdown
------------------------------------------------------------------------------------------------

local t_file_types= { 'markdown' }

if vim.g.use_ai_agent ~= vim.NIL and vim.g.use_ai_agent == 0 then
    -- Si se usa un agente de AI integrado al IDE (Avente)
    table.insert(t_file_types, 'Avante')
end

require('render-markdown').setup({

    file_types = t_file_types,

    -- Render se activa solo en los modos: 'normal', 'command' y 'terminal'.
    -- Si establece a 'true', se activa el render en todos los modos (incluyendo 'insert')
    render_modes = { 'n', 'c', 't' },

    -- Notas especiales de Markdown con un estilo especial
    -- Vease: https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Callouts
    callout = {
        note      = { raw = '[!NOTE]',      rendered = '󰋽 Note',      highlight = 'RenderMarkdownInfo',    category = 'github'   },
        tip       = { raw = '[!TIP]',       rendered = '󰌶 Tip',       highlight = 'RenderMarkdownSuccess', category = 'github'   },
        important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'RenderMarkdownHint',    category = 'github'   },
        warning   = { raw = '[!WARNING]',   rendered = '󰀪 Warning',   highlight = 'RenderMarkdownWarn',    category = 'github'   },
        caution   = { raw = '[!CAUTION]',   rendered = '󰳦 Caution',   highlight = 'RenderMarkdownError',   category = 'github'   },
        abstract  = { raw = '[!ABSTRACT]',  rendered = '󰨸 Abstract',  highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        summary   = { raw = '[!SUMMARY]',   rendered = '󰨸 Summary',   highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        tldr      = { raw = '[!TLDR]',      rendered = '󰨸 Tldr',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        info      = { raw = '[!INFO]',      rendered = '󰋽 Info',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        todo      = { raw = '[!TODO]',      rendered = '󰗡 Todo',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
        hint      = { raw = '[!HINT]',      rendered = '󰌶 Hint',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        success   = { raw = '[!SUCCESS]',   rendered = '󰄬 Success',   highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        check     = { raw = '[!CHECK]',     rendered = '󰄬 Check',     highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        done      = { raw = '[!DONE]',      rendered = '󰄬 Done',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
        question  = { raw = '[!QUESTION]',  rendered = '󰘥 Question',  highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        help      = { raw = '[!HELP]',      rendered = '󰘥 Help',      highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        faq       = { raw = '[!FAQ]',       rendered = '󰘥 Faq',       highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        attention = { raw = '[!ATTENTION]', rendered = '󰀪 Attention', highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
        failure   = { raw = '[!FAILURE]',   rendered = '󰅖 Failure',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
        fail      = { raw = '[!FAIL]',      rendered = '󰅖 Fail',      highlight = 'RenderMarkdownError',   category = 'obsidian' },
        missing   = { raw = '[!MISSING]',   rendered = '󰅖 Missing',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
        danger    = { raw = '[!DANGER]',    rendered = '󱐌 Danger',    highlight = 'RenderMarkdownError',   category = 'obsidian' },
        error     = { raw = '[!ERROR]',     rendered = '󱐌 Error',     highlight = 'RenderMarkdownError',   category = 'obsidian' },
        bug       = { raw = '[!BUG]',       rendered = '󰨰 Bug',       highlight = 'RenderMarkdownError',   category = 'obsidian' },
        example   = { raw = '[!EXAMPLE]',   rendered = '󰉹 Example',   highlight = 'RenderMarkdownHint' ,   category = 'obsidian' },
        quote     = { raw = '[!QUOTE]',     rendered = '󱆨 Quote',     highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
        cite      = { raw = '[!CITE]',      rendered = '󱆨 Cite',      highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
    },
})
