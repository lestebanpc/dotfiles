------------------------------------------------------------------------------------------------
-- Treesitter (ofrece un AST y 'Syntax Highlighting')
------------------------------------------------------------------------------------------------
--
-- URL        : https://github.com/nvim-treesitter/nvim-treesitter
-- Submodulos :
--     https://github.com/nvim-treesitter/nvim-treesitter-textobjects
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
            init_selection = "<C-space>",
            -- Acciones del modo VISUAL :
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
        },
    },

    -- Configuracion del modulo de navigacion de objetos de TreeSitter (submodulos 'nvim-treesitter-textobjects')
    -- > Listado de objetos soportados segun lenguajes:
    --   https://github.com/nvim-treesitter/nvim-treesitter-textobjects#built-in-textobjects
    textobjects = {

        -- Habilitar en la selección o operaciones de un rango de texto asociado a un nodo del AST.
        -- > Las acciones para seleccionar un rango de texto son del modo visual (v + keymap).
        -- > Las acciones como delete, change y yank del rango de texto son del submodo 'operator-pending' del modo normal:
        --   > Delete   : d + keymap
        --   > Change   : c + keymap
        --   > Yank     : y + keymap
        --
        select = {
            enable = true,

            -- Si no este dentro del objeto, busca el siguiente mas cercadno (similar to targets.vim)
            lookahead = true,

            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
                ["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
                ["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
                ["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },

                ["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter/argument" },
                ["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter/argument" },

                ["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
                ["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

                ["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
                ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },

                ["af"] = { query = "@call.outer", desc = "Select outer part of a function call" },
                ["if"] = { query = "@call.inner", desc = "Select inner part of a function call" },

                ["am"] = { query = "@function.outer", desc = "Select outer part of a method/function definition" },
                ["im"] = { query = "@function.inner", desc = "Select inner part of a method/function definition" },

                ["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
                ["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },
            },
        },

        -- Intercambiar la posición de nodos actual respecto al nodo anterior o siguiente nodo.
        -- Acciones del modo NORMAL.
        swap = {
            enable = true,
            swap_next = {
                -- swap parameters/argument with next
                ["<space>na"] = "@parameter.inner",
                -- swap function with next
                ["<space>nm"] = "@function.outer",
            },
            swap_previous = {
                -- swap parameters/argument with prev
                ["<space>pa"] = "@parameter.inner",
                -- swap function with previous
                ["<space>pm"] = "@function.outer",
            },
        },

        -- Navegar/Moverse entre nodos especiales del AST
        -- Acciones del modo NORMAL.
        move = {
            enable = true,

            -- Permite adicionar los jumps al jumplist de VIM. Ello permite avanzar y retroceder a través de ellos
            -- usuando con <C-o>(atrás) y <C-i> (adelante).
            set_jumps = true,

            goto_next_start = {
                ["]f"] = { query = "@call.outer", desc = "Next function call start" },
                ["]m"] = { query = "@function.outer", desc = "Next method/function def start" },
                ["]c"] = { query = "@class.outer", desc = "Next class start" },
                ["]i"] = { query = "@conditional.outer", desc = "Next conditional start" },
                ["]l"] = { query = "@loop.outer", desc = "Next loop start" },

                -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
                -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
                ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
                ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
            },
            goto_next_end = {
                ["]F"] = { query = "@call.outer", desc = "Next function call end" },
                ["]M"] = { query = "@function.outer", desc = "Next method/function def end" },
                ["]C"] = { query = "@class.outer", desc = "Next class end" },
                ["]I"] = { query = "@conditional.outer", desc = "Next conditional end" },
                ["]L"] = { query = "@loop.outer", desc = "Next loop end" },
            },
            goto_previous_start = {
                ["[f"] = { query = "@call.outer", desc = "Prev function call start" },
                ["[m"] = { query = "@function.outer", desc = "Prev method/function def start" },
                ["[c"] = { query = "@class.outer", desc = "Prev class start" },
                ["[i"] = { query = "@conditional.outer", desc = "Prev conditional start" },
                ["[l"] = { query = "@loop.outer", desc = "Prev loop start" },
            },
            goto_previous_end = {
                ["[F"] = { query = "@call.outer", desc = "Prev function call end" },
                ["[M"] = { query = "@function.outer", desc = "Prev method/function def end" },
                ["[C"] = { query = "@class.outer", desc = "Prev class end" },
                ["[I"] = { query = "@conditional.outer", desc = "Prev conditional end" },
                ["[L"] = { query = "@loop.outer", desc = "Prev loop end" },
            },
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
local treesitter_cfg = require("nvim-treesitter.configs")
treesitter_cfg.setup(treesitter_data)

-- Permitir repitir el ultimo moviento de objeto realizado
local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

vim.keymap.set({ "n", "x", "o" }, ';', ts_repeat_move.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, '\\', ts_repeat_move.repeat_last_move_previous)


-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
--vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })



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
})
