"###################################################################################
" IDE> Configuracion exclusivas para NeoVim si no se usa CoC
"###################################################################################
"

let s:use_adapter = v:false

if g:is_neovim && !g:use_coc

    "Package IDE> LSP Client (nativo de NeoVim)
    packadd nvim-lspconfig

    "Package IDE> CMP (Framework de autocompletado)
    packadd nvim-cmp

    "Package IDE> Mejor soporte a popup 'signature-help' en el completado de un metodo
    "packadd cmp-nvim-lsp-signature-help
    packadd lsp_signature.nvim

    "Package IDE> Core> Fuente CMP: Cliente LSP
    packadd cmp-nvim-lsp

    "Package IDE> Fuente CMP: Buffer (Sugiere palabras que se encuentra en el archivo actual)
    packadd cmp-buffer

    "Package UI> Core> Fuente CMP: FileSystem Path
    packadd cmp-path

    "Package IDE> Motor/Frameework de Snippet
    "             Muestra los snippets cargados. Si elegimos un snippet lo expande.
    packadd LuaSnip

    "Package IDE> Implementacion de Snippet para LuaSnip
    packadd friendly-snippets

    "Package IDE> Fuente CMP: Snippet tipo LuaSnip
    packadd cmp_luasnip

    "Package IDE> Code Outline
    packadd aerial.nvim

    "Package IDE> Lightbulb para Code Actions
    packadd nvim-lightbulb

    let s:use_adapter = get(g:use_lsp_adapters, "csharp", v:false)
    if s:use_adapter == v:true

        "Package IDE> Adaptador del cliente LSP para 'Roslyn LSP' para C#
        packadd roslyn.nvim

    endif

    let s:use_adapter = get(g:use_lsp_adapters, "java", v:false)
    if s:use_adapter == v:true

        "Package IDE> Adaptador del cliente LSP para 'Eclipse JDTLS' para Java SE
        packadd nvim-jdtls

    endif

    let s:use_adapter = get(g:use_lsp_adapters, "ansible", v:false)
    if s:use_adapter == v:true

        " Package IDE> FileTypes y Syntax highlighting para Ansible
        "packadd ansible-vim

        augroup my_ft_yaml_ansible
            autocmd!
            autocmd BufNewFile,BufRead */playbooks/*.yml set filetype=yaml.ansible
        augroup END

    endif

    lua require('ide.ide_basic')


endif



"###################################################################################
" IDE> ALE (Diagnostic: Linting y Fixing)
"###################################################################################
"
"https://github.com/dense-analysis/ale/blob/master/doc/ale.txt
"

" Desabilitar cliente LSP de ALE
" Se usara cliente LSP de CoC o el nativo de NeoVim
let g:ale_disable_lsp = 1

" Desabilitar 'Completition'
" Se usara el Completition de CoC o nvim-comp de NeoVim.
let g:ale_completion_enabled = 0

" Plugin IDE> Linting (analisis y diagnostico sin compilar)
packadd ale

" Signos que se mostraran cuando se realizo el diagnostico:
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '▲'
let g:ale_sign_info = ''
let g:ale_sign_style_error = ''
let g:ale_sign_style_warning = '•'

"let g:ale_sign_error = '•'
"let g:ale_sign_warning = '•'
"let g:ale_sign_info = '·'
"let g:ale_sign_style_error = '·'
"let g:ale_sign_style_warning = '·'


" Por defecto se cargan todos los linter que existe de los diferentes lenguajes soportados por ALE
" Para evitar advertencia/errores innecesarios y tener un mayor control, se cargaran manualmente.
"No se cargaran todos los linter existes por lenguajes (se cargar segun lo que se requiera).
let g:ale_linters_explicit = 1


" Establecer los Linters que se usaran
" > Por motivos de facilitar la configuracion, no se usara las variable de buffer ('b:ale_linters')
" > Despues de cargar el plugin, si no se define la variable antes, se define con valor '{}'
if !exists("g:ale_linters") || empty(g:ale_linters)

    "Establecer valores por defecto
    let g:ale_linters = {
    "\   'cpp': ['clangtidy'],
    "\   'c':   ['clangtidy'],
    "\   'rust': ['clippy'],
    "\   'go': ['golangci-lint'],
    "\   'python': ['pylint', 'flake8'],
    \   'dockerfile': ['hadolint'],
    \   'javascript': ['eslint'],
    \   'typescript': ['eslint'],
    \}

endif
"echom 'Linters: ' .. string(g:ale_linters)


" Establecer los Linters que se usaran
" > Por motivos de realizar una facil configuracion, no se usara las variable de buffer ('b:ale_fixers')
" > Despues de cargar el plugin, si no se define la variable antes, se define con valor '{}'
if !exists("g:ale_fixers") || empty(g:ale_fixers)

    "Establecer valores por defecto
    let g:ale_fixers = {
    \   '*': ['remove_trailing_lines', 'trim_whitespace'],
    "\   'cpp': ['clang-format', 'clangtidy'],
    "\   'c':   ['clang-format', 'clangtidy'],
    "\   'rust': ['rustfmt'],
    "\   'go': ['gofmt', 'goimports'],
    "\   'python': ['black', 'isort'],
    \   'javascript': ['prettier', 'eslint'],
    \   'typescript': ['prettier', 'eslint'],
    \   'yaml': ['prettier'],
    \   'json': ['prettier'],
    \   'html': ['prettier'],
    \   'css':  ['prettier'],
    \}

endif
"echom 'Fixers: ' .. string(g:ale_fixers)

" Ejecutar el fixers (si este esta configurado para el filetype actual) cuando se guarda el documento.
" > Si el fixer no tiene un regla configurada o no puede arreglar un error/warning, no lo hace.
" > Muchos fixer incluye en formato del documento como parte de su reglas predefinidas.
let g:ale_fix_on_save = 1


" Ejecutar el linter (si este esta configurado para el filetype actual) cuando se guarda el documento.
" > Los errors/warning que detecta el linter dependera de las reglas configurada (por defecto incluye algunas).
let g:ale_lint_on_save = 1

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
nmap <silent> ]d <Plug>(ale_next)

" > Ir a la anterior diagnostico desde la posicion actual y dentro del buffer
nmap <silent> [d <Plug>(ale_previous)


"Habilitar o desabilitar el diagnostico del buffer
"nmap <silent> <space>dd <Plug>(ale_toggle_buffer)



"###################################################################################
" IDE > UltiSnippets (Framework para snippets)
"###################################################################################
"
"Los snippet son usuados en el modo edición
if g:has_python3 && g:use_coc

    "Plugin IDE> UltiSnips: Motor/Framework de Snippets
    packadd ultisnips

    "Expandir el snippet manualmente :
    " > La mayoria de los 'Completion', cuando se acepta un item de tipo snippet, automaticamente
    "   el snippet se expande.
    " > Cuando se tiene un texto, al apreta <C-s>, se busca el primer snippets que coincide,
    "   si se encuentra, se expande.
    let g:UltiSnipsExpandTrigger="<C-s>"

    "Navegar por cada fragmento del snippet expandido.
    " > Algunos fragmentos pasan desde el modo 'Insert' al modo 'Select' selecionando el fragmento
    "   (similar al modo visual, pero la seleccion es remplazada automaticamente cuando se escribre).
    " > Algunos fragmentos se mantiene en el modo 'Insert'.
    "
    "Ir al siguiente fragmento del Snippets ('f' de 'follow').
    let g:UltiSnipsJumpForwardTrigger="<C-f>"
    "
    "Ir al siguiente fragmento del Snippets ('b' de 'before').
    let g:UltiSnipsJumpBackwardTrigger="<C-b>"

    "Tipo de split para navegar al editar los snippets :UltiSnipsEdit
    let g:UltiSnipsEditSplit="vertical"

    "Listar los snippets existentes para el 'filetype'.
    let g:UltiSnipsListSnippets="<C-;>"



    "Plugin IDE> UltiSnips: Implementacion de Snippet para diferentes lenguajes de programacion
    packadd vim-snippets

endif



"###################################################################################
" IDE > CoC (Conquer Of Completion)
"###################################################################################
"

" Implementa :
"   - Completition,
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

if g:use_coc

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

"Adaptadores de Lenguajes personalizados: C# (OmniSharp)
"Implementa :
"   - LSO cliente para LSP server Roslyn
"   - Source para ALE linting (Linter para C#)
"   - Source de autocompletado para Coc (y otros motores de autocompletado
"   - Source para UltiSnippets
if g:use_coc

    let s:use_adapter = get(g:use_lsp_adapters, "csharp", v:false)
    if s:use_adapter == v:true
        runtime setting/ide/adapters/lsp_cs.vim
    endif

endif


"###################################################################################
" IDE> Otros
"###################################################################################
"

if g:use_coc

    " Package IDE> FileTypes y Syntax highlighting para Ansible
    "packadd ansible-vim

    augroup my_ft_yaml_ansible
        autocmd!
        autocmd BufNewFile,BufRead */playbooks/*.yml set filetype=yaml.ansible
    augroup END


endif
