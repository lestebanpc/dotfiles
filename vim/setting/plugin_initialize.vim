"###################################################################################
" Package Manager : Carga manual de Paquetes y su configuracion basica
"###################################################################################

if g:is_neovim

    "El ESQUEMA DE COLOR del tema SIEMPRE debera configurarse antes de la carga de una UI
    
    "Inicializar los packetes gestionados por Packer
     lua require('plugin_initialize')

    "Plug-In> UI> CORE> Tema 'Tokyo Night' (carga automatica)
    "packadd tokyonight.nvim

    "Esquema de color del tema usuado por NeoVim
    colorscheme tokyonight-night

    "Plug-In> UI> CORE> Barra de estado o 'SatusLine' (carga automatica)
    "packadd lualine.nvim

    if g:use_tabline
    
        "Plug-In> UI> CORE> Barra de buffers/tabs o 'TabLine'
        packadd bufferline.nvim
    
    endif
    
    "Package UI> EXTENDED> Explorador de archivos (deben cargarse antes de 'Vim-DevIcons')
    packadd nvim-tree.lua

else

    "El ESQUEMA DE COLOR del tema SIEMPRE debera configurarse antes de la carga de una UI
    
    "Plug-In> UI> CORE> Tema Molakai
    packadd molokai

    "Esquema de color del tema usuado por NeoVim
    colorscheme molokai
    "let g:molokai_original = 1

    "Plug-In> UI> CORE> Barra de estado AirLine (incluye 'SatusLine' y 'TabLine'. Debe cargarse antes de 'Vim-DevIcos')
    packadd vim-airline
    packadd vim-airline-themes
    
    "Package UI> EXTENDED> Explorador de archivos (deben cargarse antes de 'Vim-DevIcons')
    packadd nerdtree

endif



if g:use_ide

    if g:use_typing_surround 
        "Package UI> IDE> TYPING> Encerrar/Modificar con (), {}, [] un texto
        packadd vim-surround
    endif

    if g:use_typing_visual_multi
        "Package UI> IDE> TYPING> Selector multiple de texto
        packadd vim-visual-multi
    endif

    if g:is_neovim

        "Package UI> IDE> Core> Resaltador de sintexis o semantica
        packadd nvim-treesitter

        "Package UI> IDE> Core> Linting, Fixing, LSP Client.. (nativo de NeoVim)
        packadd nvim-lspconfig
        
        "Package UI> IDE> Core> CMP (Framework de autocompletado)
        packadd nvim-cmp

        "Package UI> IDE> Core> Fuente CMP: Cliente LSP
        packadd cmp-nvim-lsp

        "Package UI> IDE> Core> Fuente CMP: Buffer (Sugiere palabras que se encuentra en el archivo actual)
        packadd cmp-buffer

        "Package UI> IDE> Core> Fuente CMP: FileSystem Path
        packadd cmp-path

        "Package UI> IDE> Core> Motor/Frameework de Snippet
        "  Muestra los snippets cargados. Si elegimos un snippet lo expande.
        packadd LuaSnip  

        "Package UI> IDE> Core> Implementacion de Snippet para LuaSnip
        packadd friendly-snippets

        "Package UI> IDE> Core> Fuente CMP: Snippet tipo LuaSnip
        packadd cmp_luasnip

    else

        "Package UI> IDE> Core> Linting y LSP Client para VIM
        "   Desabilitar LSP : Se usara Vim-LSP
        let g:ale_disable_lsp = 1
        "   Desabilitar Completition : Se usara CoC.nvim
        let g:ale_completion_enabled = 0
        packadd ale
        "   No se cargaran todos los linter existes por lenguajes (se cargar segun lo que se requiera)
        let g:ale_linters = {}

        "Pacakege UtilSnips usa Python3
        if g:has_python3

            "Package UI> IDE> Core> UltiSnips: Motor/Framework de Snippets
            packadd ultisnips

            "Package UI> IDE> Core> UltiSnips: Implementacion de Snippet para diferentes lenguajes de programacion
            packadd vim-snippets

        endif

        "Package UI> IDE> Core> LSP Client, Complete (y muchos complementos de 3ros)
        "   El diganostico se enviara ALE (no se usara el del CoC)
        "   Complementos que se sugiere instalar:
        "     - Soporte a desarrollo web :CocInstall coc-tsserver coc-json coc-html coc-css
        "     - Soporte a Python3 :CocInstall coc-pyright
        "     - Soporte a UtilSnips :CocInstall coc-ultisnips
        packadd coc.nvim
    
        "Package UI> IDE> Core> C#> LSP Cliente de Roslyn para C# y adaptadores para usar con otros plugins
        packadd omnisharp-vim
        
        "Plug-In UI> IDE> Core> C#> Mappings, Code-actions para OmniSharp
        packadd vim-sharpenup

    endif

endif


"###################################################################################
" Plug-In Manager (Vim-Plug): Registro de Plugins y su Carga automatica
"###################################################################################

"----------------------------- Plug-In Manager - INIT  -----------------------------
call plug#begin()


"----------------------------- Plug-in Manager - LOAD  -----------------------------
"Plug-In> UI> CORE> Crear paneles TMUX desde VIM (en Windows no existe TMUX)
if g:os != "Windows"
    Plug 'preservim/vimux'
endif

"Plug-In> Search Files> FZF (FuZzy Finder"), instalacion manual del binario
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

"ONLY VIM : Iconos, para Neovim se usa la version lua
if !g:is_neovim
    "Plug-In> UI> Iconos para NERDTree y AirLine
    Plug 'ryanoasis/vim-devicons'
endif

if g:use_typing_html_emmet
    "Plug-In> UI> IDE> TYPING> Crear elementos HTML por comandos
    Plug 'mattn/emmet-vim'
endif


"----------------------------- Plug-In Manager - END   -----------------------------
call plug#end()



"###################################################################################
" Package Manager : Carga manual paquetes y configuracion basica
"###################################################################################


"Vim-DevIcons : Loading the plugin
"Es requierdo aqui?
"let g:webdevicons_enable = 1

"Paquete UI> CORE> Permite navegar entre split VIM y paneles TMUX como el mismo comando
if g:os != "Windows"
    packadd vim-tmux-navigator
endif



