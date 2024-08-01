"####################################################################################
" Carga manual de plugin
"####################################################################################

"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
" CORE> Basico y extendido (Mejorar la experiencia de usuario)
"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if g:is_neovim

    "El ESQUEMA DE COLOR del tema SIEMPRE debera configurarse antes de la carga de una UI

    packadd nvim-web-devicons
    packadd plenary.nvim    

    "Plug-In> UI> CORE> Tema 'Tokyo Night' (carga automatica)
    packadd tokyonight.nvim

    "Esquema de color del tema usuado por NeoVim
    colorscheme tokyonight-night

    "Plug-In> UI> CORE> Barra de estado o 'SatusLine' (carga automatica)
    packadd lualine.nvim

    if g:use_tabline
    
        "Plug-In> UI> CORE> Barra de buffers/tabs o 'TabLine'
        packadd bufferline.nvim
    
    endif
   
    packadd telescope.nvim

    "Package UI> EXTENDED> Explorador de archivos (deben cargarse antes de 'Vim-DevIcons')
    packadd nvim-tree.lua

else

    "El ESQUEMA DE COLOR del tema SIEMPRE debera configurarse antes de la carga de una UI
    
    "Plug-In> UI> CORE> Tema Molakai
    packadd molokai

    "Esquema de color del tema usuado por NeoVim
    colorscheme molokai
    "let g:molokai_original = 1

    "Plug-In> UI> CORE> Barra de estado AirLine (incluye 'SatusLine' y 'TabLine')
    "Segun la documentación oficial, se deben cargarse antes de 'Vim-DevIcons'.
    packadd vim-airline
    packadd vim-airline-themes

    "Plug-In> UI> Iconos para NERDTree y AirLine
    packadd vim-devicons
    
    "Plug-In> UI> EXTENDED> Explorador de archivos.
    "Segun la documentación oficial, se deben cargarse antes de 'Vim-DevIcons', pero no esta funcionado.
    packadd nerdtree

endif

"Plug-In> UI> EXTENDED> FZF ("FuZzy Finder") - Funciones basicas para integrar usar el cmd
packadd fzf
"Plug-In> UI> EXTENDED> FZF ("FuZzy Finder") - Comanfos VIM para usar mejor FzF
packadd fzf.vim



if g:use_ide

"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"IDE> Basico
"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if g:is_neovim

        "Package UI> IDE> Core> Resaltador de sintexis o semantica
        packadd nvim-treesitter

    endif

    "Package IDE> Soporte a Universal CTags
    packadd vim-gutentags

"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"IDE> Completition, LSP Client, Snippets
"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    "Si es VIM siempre usar CoC.nVim, si es NeoVim solo si se habilita el flag    
    if !g:is_neovim || (g:is_neovim && g:use_coc_in_nvim)
 
        "Package UI> IDE> Core> Linting (analisis y diagnostico sin compilar)
        "   Desabilitar LSP : Se usara CoC o Vim-LSP.
        let g:ale_disable_lsp = 1
        "   Desabilitar 'Completition' : Se usara CoC o comp-nvim.
        let g:ale_completion_enabled = 0

        "   Cargar el paquete
        packadd ale


        "Pacakege UI> IDE> Core> Motor de Snippets
        if g:has_python3

            "Package UI> IDE> Core> UltiSnips: Motor/Framework de Snippets
            packadd ultisnips

            "Package UI> IDE> Core> UltiSnips: Implementacion de Snippet para diferentes lenguajes de programacion
            packadd vim-snippets

        endif

        "Package UI> IDE> Core> Completado, LSP Client (y otros complementos de 3ros)
        "   El diganostico se enviara ALE (no se usara el integrado de CoC).
        "   El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')
        "   Se deberá instalar los adaptadores a los diferentes servidores LSP.
        "   Se integrará con el motor de snippets 'UtilSnips' (no usara el por defecto)
        packadd coc.nvim
    
        "Package UI> IDE> Core> C#> LSP Cliente de Roslyn para C# y adaptadores para usar con otros plugins
        packadd omnisharp-vim
        
        "Plug-In UI> IDE> Core> C#> Mappings, Code-actions para OmniSharp
        "packadd vim-sharpenup

    else

        "Package UI> IDE> Core> LSP Client (nativo de NeoVim)
        packadd nvim-lspconfig
        
        "Package UI> IDE> Core> CMP (Framework de autocompletado)
        packadd nvim-cmp

        "Package UI> IDE> CORE> Mejor soporte a popup 'signature-help' en el completado de un metodo
        "packadd cmp-nvim-lsp-signature-help
        packadd lsp_signature.nvim

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
        
        "Package UI> IDE> Core> Linting, Code Formatting (Fixing) de servidores No-LSP
        packadd null-ls.nvim

        "Package UI> IDE> Core> Lightbulb para Code Actions 
        packadd nvim-lightbulb

        "Package UI> IDE> Core> Wizard para instalar adaptadores LSP y de depuracion 
        "packadd mason.nvim
        
        "Package UI> IDE> Core> Permite configurar adaptadores LSP usando 'nvim-lspconfig' usando Mason
        "packadd mason-lspconfig.nvim

    endif

"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"IDE> Debuggers
"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if g:is_neovim

        "Package UI> IDE> CORE> Depurador (Cliente DAP y los adaptadores depuracion)
        packadd nvim-dap

        "Package UI> IDE> CORE> A library for asynchronous IO in Neovim
        packadd nvim-nio

        "Package UI> IDE> CORE> DAP> Mejora de UI para nVim-DAP
        packadd nvim-dap-ui

        "Package UI> IDE> CORE> DAP> Mejora de UI para nVim-DAP
        packadd nvim-dap-virtual-text

        "Package UI> IDE> CORE> DAP> Mejora de UI para nVim-DAP
        packadd telescope-dap.nvim

        "if !g:use_coc_in_nvim

            "Package UI> IDE> Core> Permite configurar adaptadores depuracion 'nvim-dap' usando Mason
            "packadd mason-nvim-dap.nvim

        "endif

    elseif g:has_python3

        "Package UI> IDE> Core> Graphical Debugger
        "Habilitar el tipo de key-mapping por defecto de tipo 'HUMAN'
        let g:vimspector_enable_mappings = 'HUMAN'
        "let g:vimspector_enable_mappings = 'VISUAL_STUDIO'
        packadd vimspector

    endif

endif



"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
" CORE> Basico y extendido (Mejorar la experiencia de usuario)
"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if g:use_typing_surround 
    "Package UI> IDE> TYPING> Encerrar/Modificar con (), {}, [] un texto
    packadd vim-surround
endif

if g:use_typing_visual_multi
    "Package UI> IDE> TYPING> Selector multiple de texto
    packadd vim-visual-multi
endif

if g:use_typing_html_emmet
    "Package UI> IDE> TYPING> Crear elementos HTML por comandos
    packadd emmet-vim
endif

"Solo en Linux (incluyendo WSL, solo en Linux y MacOS)
if (g:os_type != 0) && g:use_tmux
    "Package UI> CORE> Crear paneles TMUX desde VIM (en Windows no existe TMUX)
    packadd vimux
endif

"Solo en Linux (incluyendo WSL, solo en Linux y MacOS)
"if (g:os_type != 0) && g:use_tmux
if (g:os_type != 0)
    "Paquete UI> CORE> Permite navegar entre split VIM y hacia paneles TMUX.
    "Pemite ir de un split VIM a un panel tmux (identifica si existe un panel TMUX, y genera comando tmux para ir panel)
    "Pero, para ir de panel TMUX a un split VIM, requiere configurar estos keybinding en el tmux.config, para reenviar las
    "teclas en VIM.
    "Los default keybinding se mantiene:
    "  > En VIM  'CTRL + w, ...' 
    "  > En TMUX 'CTRL + b, ...' 
    "Los keybinding defenidos por este mantiene:
    "  > <CTRL-h> => Left
    "  > <CTRL-j> => Down
    "  > <CTRL-k> => Up
    "  > <CTRL-l> => Right
    "  > <CTRL-\> => Previous split
    packadd vim-tmux-navigator
endif



