
if get(b:, 'csharp_ftplugin_loaded', 0) | finish | endif

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
let b:csharp_ftplugin_loaded = 1
let b:undo_ftplugin .= '| unlet b:csharp_ftplugin_loaded'

let s:save_cpo = &cpoptions
set cpoptions&vim


"The following commands are contextual, based on the cursor position.
nmap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)
nmap <silent> <buffer> <Leader>fu <Plug>(omnisharp_find_usages)
nmap <silent> <buffer> <Leader>fi <Plug>(omnisharp_find_implementations)
nmap <silent> <buffer> <Leader>pd <Plug>(omnisharp_preview_definition)
nmap <silent> <buffer> <Leader>pi <Plug>(omnisharp_preview_implementations)

nmap <silent> <buffer> <Leader>t <Plug>(omnisharp_type_lookup)
nmap <silent> <buffer> <Leader>d <Plug>(omnisharp_documentation)

nmap <silent> <buffer> <Leader>fs <Plug>(omnisharp_find_symbol)
nmap <silent> <buffer> <Leader>ft <Plug>(omnisharp_find_type)

nmap <silent> <buffer> <Leader>fx <Plug>(omnisharp_fix_usings)

nmap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
imap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)

"Navigate up and down by method/property/field
map <silent> <buffer> [[ <Plug>(omnisharp_navigate_up)
map <silent> <buffer> ]] <Plug>(omnisharp_navigate_down)

"Find all code errors/warnings for the current solution and populate the quickfix window
nmap <silent> <buffer> <Leader>gcc <Plug>(omnisharp_global_code_check)

nmap <silent> <buffer> <Leader>hi <Plug>(omnisharp_highlight_type)

"Contextual code actions (uses fzf, vim-clap, CtrlP or unite.vim selector when available)
nmap <silent> <buffer> <Leader>ca <Plug>(omnisharp_code_actions)
xmap <silent> <buffer> <Leader>ca <Plug>(omnisharp_code_actions)

"Repeat the last code action performed (does not use a selector)
nmap <silent> <buffer> <Leader>. <Plug>(omnisharp_code_action_repeat)
xmap <silent> <buffer> <Leader>. <Plug>(omnisharp_code_action_repeat)

nmap <silent> <buffer> <Leader>nm <Plug>(omnisharp_rename)
nmap <silent> <buffer> <Leader>= <Plug>(omnisharp_code_format)

nmap <silent> <buffer> <Leader>re <Plug>(omnisharp_restart_server)
nmap <silent> <buffer> <Leader>st <Plug>(omnisharp_start_server)
nmap <silent> <buffer> <Leader>sp <Plug>(omnisharp_stop_server)

nmap <silent> <buffer> <Leader>re <Plug>(omnisharp_run_test)
nmap <silent> <buffer> <Leader>rnt <Plug>(omnisharp_run_test_no_build)
nmap <silent> <buffer> <Leader>rat <Plug>(omnisharp_run_tests_in_file)
nmap <silent> <buffer> <Leader>rant <Plug>(omnisharp_run_tests_in_file_no_build)
nmap <silent> <buffer> <Leader>rdt <Plug>(omnisharp_debug_test)
nmap <silent> <buffer> <Leader>rdnt <Plug>(omnisharp_debug_test_no_build)

if g:csharp_codeactions

    if g:csharp_codeactions_set_signcolumn
        setlocal signcolumn=yes
        let b:undo_ftplugin .= '| setlocal signcolumn<'
    endif

    augroup csharp_ftplugin
        autocmd! * <buffer>
        for au in split(g:csharp_codeactions_autocmd, ',')
            execute 'autocmd' au '<buffer> call ui_ide_lsp_cs#codeactions_count()'
        endfor
    augroup END

    let b:undo_ftplugin .= '| execute "autocmd! csharp_ftplugin * <buffer>"'
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo

