"###################################################################################
" IDE> Configuracion exclusivas para NeoVim si no se usa CoC
"###################################################################################
"

let s:use_adapter = v:false

if g:is_neovim

    "Plugin IDE> Modulos a usar del plugin 'nvim-treeSitter'
    packadd nvim-treesitter-context

    " Si se usa un Noevim con LSP nativo (sin CoC)
    if !g:use_coc

        "Package IDE> LSP Client (nativo de NeoVim)
        packadd nvim-lspconfig

        "Package IDE> Mejor soporte a popup 'signature-help' en el completado de un metodo
        "packadd cmp-nvim-lsp-signature-help
        packadd lsp_signature.nvim

        "Package IDE> Fuente CMP: Cliente LSP
        packadd cmp-nvim-lsp

        "Package IDE> Motor/Frameework de Snippet
        "             Muestra los snippets cargados. Si elegimos un snippet lo expande.
        packadd LuaSnip

        "Package IDE> Implementacion de Snippet para LuaSnip
        packadd friendly-snippets

        "Package IDE> Fuente CMP: Snippet tipo LuaSnip
        packadd cmp_luasnip

        "Package IDE> Fuente CMP: Lista los valores de un 'Choice Nodos' de un snippets
        packadd cmp-luasnip-choice

        "Package IDE> Lightbulb para Code Actions
        packadd nvim-lightbulb


        "packadd roslyn.nvim

        "Package IDE> Adaptador del cliente LSP para 'Eclipse JDTLS' para Java SE
        let s:use_adapter = get(g:use_lsp_adapters, "java", v:false)
        if s:use_adapter == v:true

            packadd nvim-jdtls

        endif

        "Package IDE> Plugin para establer las reglas de filtro de 'JSON Schema Store' para JSON/YAML
        "             Solo se usara para el LSP de archivos JSON.
        let s:use_adapter = get(g:use_lsp_adapters, "json", v:false)
        if s:use_adapter == v:true

            packadd SchemaStore.nvim

        endif

        "Package IDE> Fuente de completado de 'nvim-cmp'
        if g:use_ai_plugins == v:true
            packadd copilot-cmp
        endif

    endif

    "Package IDE> Code Outline
    packadd aerial.nvim

    "Configuración de NeoVim para development
    lua require('ide.ide_development')

endif



"###################################################################################
" IDE> ALE (Diagnostic: Linting y Fixing)
"###################################################################################
"
" URL : https://github.com/dense-analysis/ale/blob/master/doc/ale.txt
" > Por motivos de facilitar la configuracion de linters, no se usara las variable de buffer ('b:ale_linters').
" > Por motivos de realizar una facil configuracion de los fixers, no se usara las variable de buffer ('b:ale_fixers').
" > Despues de cargar el plugin (packadd ale), si no se define estas variables antes, se define con valor '{}'.
"

"echom 'Fixers: ' .. string(g:ale_fixers)
"echom 'Linters: ' .. string(g:ale_linters)

" Desabilitar cliente LSP de ALE
" Se usara cliente LSP de CoC o el nativo de NeoVim
let g:ale_disable_lsp = 1

" Desabilitar 'Completion'
" Se usara el Completion de CoC o nvim-comp de NeoVim.
let g:ale_completion_enabled = 0

" Plugin IDE> Linting (analisis y diagnostico sin compilar)
packadd ale


"echom 'Fixers: ' .. string(g:ale_fixers)
"echom 'Linters: ' .. string(g:ale_linters)

" Signos que se mostraran cuando se realizo el diagnostico:
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '▲'
let g:ale_sign_info = ''
let g:ale_sign_style_error = ''
let g:ale_sign_style_warning = '•'

"highlight ALEErrorSign ctermbg        =NONE ctermfg=red
"highlight ALEWarningSign ctermbg      =NONE ctermfg=yellow

"let g:ale_sign_error = '•'
"let g:ale_sign_warning = '•'
"let g:ale_sign_info = '·'
"let g:ale_sign_style_error = '·'
"let g:ale_sign_style_warning = '·'


" Por defecto se cargan todos los linter que existe de los diferentes lenguajes soportados por ALE
" Para evitar advertencia/errores innecesarios y tener un mayor control, se cargaran manualmente.
"No se cargaran todos los linter existes por lenguajes (se cargar segun lo que se requiera).
let g:ale_linters_explicit = 1


" Ejecutar el fixers (si este esta configurado para el filetype actual) cuando se guarda el documento.
" > Si el fixer no tiene un regla configurada o no puede arreglar un error/warning, no lo hace.
" > Muchos fixer incluye en formato del documento como parte de su reglas predefinidas.
"let g:ale_fix_on_save = get(g:, 'ale_fix_on_save', 1)


" Ejecutar el linter (si este esta configurado para el filetype actual) cuando se guarda el documento.
" > Los errors/warning que detecta el linter dependera de las reglas configurada (por defecto incluye algunas).
let g:ale_lint_on_save = get(g:, 'ale_lint_on_save', 1)

" Por defecto NO activara el linter cuando se escribre.
" > Se recomienda usar las capacidade del linting y fixing basicas que ofrece su LSP.
"   - El LSP cuando se escribe realiza linting basico (analisis no tan profundo y enfocado en responder rapido).
"   - El LSP muestra 'Code Actions', el cual si el usario lo ejecuta, puede ejecutar fixing basico.
" > Solo usa el linting avanzado cuando se guarda el documento.
let g:ale_lint_on_text_changed = get(g:, 'ale_lint_on_text_changed', 'never')


" keep the sign gutter open at all times
"let g:ale_sign_column_always = 1

" Habilitar el uso del 'Virtual Text' para mostrar el diagnostico (solo a partir Vim >= 9.XX o NeoVim)
"  > 2 ('all    ) - Muestra el diagnostico de todas las lineas de texto.
"  > 1 ('current) - Muestra el diagnostico de la linea de texto actual.
"  > 0 ('disable) - No muestra diagnostico en 'Virtual Text'
let g:ale_virtualtext_cursor = 2

" Permitir que el diagnostico en 'Virtual Text' solo se muestre un tiempo determinado
" en ¿milisegundos? (por defecto es 10 ¿milisegundos?). 0 si se muestra siempre.
let g:ale_virtualtext_delay = 10

" Si es NeoVim, enviar los errores y warning al API de Diagnostico y que ALE mueste el diagnostico
" usadno el API de NeoVim.
" Vease :
"    https://github.com/dense-analysis/ale/pull/4345
if g:is_neovim
    let g:ale_use_neovim_diagnostics_api = 1
endif


" Prefijo que aparece en el diagnostico en 'Virtual Text'
"'%type%' es 'E' para error, 'W' para Warning, 'I' para Info.
"let g:ale_virtualtext_prefix = '%comment% %type%: '


" Navegar entre los diganosticos del buffer gestionados por ALE
" > Si usas CoC, todo el diganostico se envia a ALE, asi que tiene el tiene diagnostico del LSP y
"   los diganosticos exlclusivos de sus linters
" > Si usas NeoVim con LSP built-in, el tiene diagnostico del LSP ¿se envia a ALE?. ALE siempre incluye
"   los diganosticos exlclusivos de sus linters.
"
" > Ir al siguiente diagnostico desde la posicion actual y dentro del buffer
nnoremap <silent> ]d <Plug>(ale_next)

" > Ir a la anterior diagnostico desde la posicion actual y dentro del buffer
nnoremap <silent> [d <Plug>(ale_previous)


" Ejecutar el fixing usando los fixers (tool externas)
nnoremap <silent> <space>fx :<C-u>ALEFix<CR>


"###################################################################################
" IDE > CoC (Conquer Of Completion)
"###################################################################################
"

" Implementa :
"   - Completion,
"   - Un cliente LSP,
"   - Adaptadores para cliente LSP para servidores LSP usando extensiones,
"   - Extensiones diversas.
if g:use_coc

    runtime setting/ide/coc_settings.vim

endif



"###################################################################################
" IDE > Code Outline (esquema del codigo del buffer)
"###################################################################################
"
" URL : https://github.com/liuchengxu/vista.vim
"

"if g:use_coc
if !g:is_neovim

    packadd vista.vim

    " How each level is indented and what to prepend.
    " This could make the display more compact or more spacious.
    "let g:vista_icon_indent = ['╰─▸ ', '├─▸ ']

    " Executive used when opening vista sidebar without specifying it.
    " See all the avaliable executives via `:echo g:vista#executives`.
    let g:vista_default_executive = 'ctags'

    " To enable fzf's preview window set g:vista_fzf_preview.
    " The elements of g:vista_fzf_preview will be passed as arguments to fzf#vim#with_preview()
    " For example:
    let g:vista_fzf_preview = ['right:50%']

    " Ensure you have installed some decent font to show these pretty symbols, then you can enable icon for the kind.
    let g:vista#renderer#enable_icon = 1

    " The default icons can't be suitable for all the filetypes, you can extend it as you wish.
    "let g:vista#renderer#icons = {
    "\   'function': "\uf794",
    "\   'variable': "\uf71B",
    "\  }

    " Keymapping para mostrar/ocultar code outline
    nnoremap <silent><nowait> <space>co  :<C-u>Vista!!<cr>

endif


"###################################################################################
" IDE> C#>  Cliente LSP de Roslyn para C#
"###################################################################################
"

" Adaptadores de Lenguajes personalizados: C# (OmniSharp)
" Implementa :
"   - LSO cliente para LSP server Roslyn
"   - Source para ALE linting (Linter para C#)
"   - Source de autocompletado para Coc (y otros motores de autocompletado
"   - Source para UltiSnippets
let s:use_adapter = v:false

if g:use_coc

    let s:use_adapter = get(g:use_lsp_adapters, "omnisharp_vim", v:false)
    if s:use_adapter == v:true

        " IDE > UltiSnippets (Framework para snippets)
        if g:has_python3

            "Plugin IDE> UltiSnips: Motor/Framework de Snippets
            packadd ultisnips

            "1. Los keymapping se definiran solo para el buffer asociado a c#.

            " > Muestra el completado con solo snippet asociado al prompt actual. Si solo existe un snippet,
            "   expande este automaticamente.
            let g:UltiSnipsExpandTrigger="<Nop>"
            "let g:UltiSnipsExpandTrigger="<C-s>"

            "2. Navegar por cada nodo del snippet (placeholder modificable del snippet):

            " > Permite ir al siguiente nodo del snippets ('f' de 'follow').
            " > Reinicar la navegación de un snippet desde un nodo seleccionado.
            let g:UltiSnipsJumpForwardTrigger="<Nop>"
            "let g:UltiSnipsJumpForwardTrigger="<C-f>"

            " > Permite ir al anterior nodo del snippets ('b' de 'before').
            let g:UltiSnipsJumpBackwardTrigger="<Nop>"
            "let g:UltiSnipsJumpBackwardTrigger="<C-b>"

            "3. Tipo de split para navegar al editar los snippets :UltiSnipsEdit
            let g:UltiSnipsEditSplit="vertical"
            "let g:UltiSnipsEditSplit="vertical"

            "4. Listar los snippets existentes para el 'filetype'.
            let g:UltiSnipsListSnippets="<Nop>"
            "let g:UltiSnipsListSnippets="<space>sn"


        endif

        " Iniciar la configuracion del plugin
        runtime setting/ide/adapters/lsp_cs.vim

    endif

endif


"###################################################################################
" IDE> Snippet usados por framework de snippets
"###################################################################################
"
" > Solo es usado por los frameworks (ambos framework requieren python para funcionar):
"   > coc-snippets (si usa CoC, use o no VIM/NeoVim) y
"   > UtilSnips (si usa CoC y el plugin 'omnisharp-vim', use o no VIM/NeoVim).
"     El plugin de omnisharp-vim requiere de un motor de autocompletado y uno de los compatables es CoC.
" > No es usado por el framework LuaSnip en NeoVim sin CoC (este usa 'friendly-snippets').
"

" Habilitar los snippets para ser usuados por lo framework snippet de VIM ()
if g:has_python3 && g:use_coc

    "Plugin IDE> UltiSnips: Implementacion de Snippet para diferentes lenguajes de programacion
    packadd vim-snippets

endif


"###################################################################################
" IDE> Otros
"###################################################################################
"

" Configurar el FileTypes y Syntax highlighting para Ansible
augroup my_ft_yaml_ansible
    autocmd!
    autocmd BufNewFile,BufRead */playbooks/*.yml set filetype=yaml.ansible
augroup END
