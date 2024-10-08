if exists('g:loaded_libosc52')
  finish
endif

let g:loaded_libosc52 = 1

"-------------------------------------------------------------------------------------------
"Source> 'https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/osc52.vim'
"-------------------------------------------------------------------------------------------
"
"Es usado como parte de la libreria JS 'hterm' de chromium.
"
"
" Copyright 2012 The ChromiumOS Authors
" Use of this source code is governed by a BSD-style license that can be
" found in the LICENSE file.
"
" This script can be used to send an arbitrary string to the terminal clipboard
" using the OSC 52 escape sequence, as specified in
" http://invisible-island.net/xterm/ctlseqs/ctlseqs.html, section "Operating
" System Controls", Ps => 52.
"
" To add this script to vim...
"  1. Save it somewhere.
"  2. Edit ~/.vimrc to include...
"       source ~/path/to/osc52.vim
"       vmap <C-c> y:call SendViaOSC52(getreg('"'))<cr>
"
" This will map Ctrl+C to copy.  You can now select text in vi using the visual
" mark mode or the mouse, and press Ctrl+C to copy it to the clipboard.
"

" Max length of the OSC 52 sequence.  Sequences longer than this will not be
" sent to the terminal.
let g:max_osc52_sequence=100000


" This function base64's the entire string and wraps it in a single OSC52.
"
" It's appropriate when running in a raw terminal that supports OSC 52.
function! s:get_OSC52 (str)
  let b64 = s:b64encode(a:str, 0)
  let rv = "\e]52;c;" . b64 . "\x07"
  return rv
endfunction

" This function base64's the entire string and wraps it in a single OSC52 for
" tmux.
"
" This is for `tmux` sessions which filters OSC 52 locally.
function! s:get_OSC52_tmux (str)
  let b64 = s:b64encode(a:str, 0)
  let rv = "\ePtmux;\e\e]52;c;" . b64 . "\x07\e\\"
  return rv
endfunction

" This function base64's the entire source, wraps it in a single OSC52, and then
" breaks the result in small chunks which are each wrapped in a DCS sequence.
"
" This is appropriate when running on `screen`.  Screen doesn't support OSC 52,
" but will pass the contents of a DCS sequence to the outer terminal unmolested.
" It imposes a small max length to DCS sequences, so we send in chunks.
function! s:get_OSC52_DCS (str)
  let b64 = s:b64encode(a:str, 76)
  " Remove the trailing newline.
  let b64 = substitute(b64, '\n*$', '', '')
  " Replace each newline with an <end-dcs><start-dcs> pair.
  let b64 = substitute(b64, '\n', "\e/\eP", "g")
  " (except end-of-dcs is "ESC \", begin is "ESC P", and I can't figure out
  "  how to express "ESC \ ESC P" in a single string.  So, the first substitute
  "  uses "ESC / ESC P", and the second one swaps out the "/".  It seems like
  "  there should be a better way.)
  let b64 = substitute(b64, '/', '\', 'g')
  " Now wrap the whole thing in <start-dcs><start-osc52>...<end-osc52><end-dcs>.
  let b64 = "\eP\e]52;c;" . b64 . "\x07\e\x5c"
  return b64
endfunction

" Echo a string to the terminal without munging the escape sequences.
function! s:rawecho (str)
  " We have to use some way to send this message to stdout.
  " Vim's built-in echo does not write to stdout and only displays on the
  " command line in the vim interface.
    if filewritable('/dev/stdout')
      " Write directly to stdout. This will prevent a flicker from occurring
      " since no redraw is required.
      call writefile([a:str], '/dev/stdout', 'b')
    else
      " This will cause a flicker to occur due to a new shell actually
      " appearing, requiring a redraw of vim, but we will use as fallback.
      exec("silent! !echo " . shellescape(a:str))
      redraw!
    endif
endfunction

" Lookup table for s:b64encode.
let s:b64_table = [
      \ "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
      \ "Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f",
      \ "g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v",
      \ "w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"]

" Encode a string of bytes in base 64.
" Based on http://vim-soko.googlecode.com/svn-history/r405/trunk/vimfiles/
" autoload/base64.vim
" If size is > 0 the output will be line wrapped every `size` chars.
function! s:b64encode(str, size)
  let bytes = s:str2bytes(a:str)
  let b64 = []
  for i in range(0, len(bytes) - 1, 3)
    let n = bytes[i] * 0x10000
          \ + get(bytes, i + 1, 0) * 0x100
          \ + get(bytes, i + 2, 0)
    call add(b64, s:b64_table[n / 0x40000])
    call add(b64, s:b64_table[n / 0x1000 % 0x40])
    call add(b64, s:b64_table[n / 0x40 % 0x40])
    call add(b64, s:b64_table[n % 0x40])
  endfor
  if len(bytes) % 3 == 1
    let b64[-1] = '='
    let b64[-2] = '='
  endif
  if len(bytes) % 3 == 2
    let b64[-1] = '='
  endif
  let b64 = join(b64, '')
  if a:size <= 0
    return b64
  endif
  let chunked = ''
  while strlen(b64) > 0
    let chunked .= strpart(b64, 0, a:size) . "\n"
    let b64 = strpart(b64, a:size)
  endwhile
  return chunked
endfunction
function! s:str2bytes(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

" -------------------- PUBLIC   ----------------------------

" Send a string to the terminal's clipboard using the OSC 52 sequence.
function! SendViaOSC52 (str)

  " Since tmux defaults to setting TERM=screen (ugh), we need to detect it here
  " specially.
  if !empty($TMUX)
    let osc52 = s:get_OSC52_tmux(a:str)
  elseif match($TERM, 'screen') > -1
    let osc52 = s:get_OSC52_DCS(a:str)
  else
    let osc52 = s:get_OSC52(a:str)
  endif

  let len = strlen(osc52)
  if len < g:max_osc52_sequence
    call s:rawecho(osc52)
    echo '[OSC52] ' . len . ' characters copied'
  else
    echo "[OSC52] Selection too long to send to terminal: " . len
  endif

endfunction


" Parametros de entrada>
" 1> 'format' tipo de formato a enviar el texto por OSC52. Esto puede ser:
"    0 u otro valor > Formato OSC 52 estandar que es enviado directmente una terminal que NO use como '$TERM' a GNU screen.
"    1 > Formato DSC chunking que es enviado directmente a una terminal que use como '$TERM' a GNU screen.
"        La data es enviada por varias trozos pequeños en formato DSC.
"    2 > Formato DSC enmascarado para TMUX (tmux requiere un formato determinado, y si esta configurado, este se encargara de
"        traducir al formato OSC 52 estandar y reenviarlo a la terminal donde corre tmux).
"        Enmascara el OSC52 como un parametro de una secuancia de escape DSC.
" 2> 'text' que se debe enviar a la terminal.
function! PutClipboard (format, text)

  if a:format == 2
    let l_data = s:get_OSC52_tmux(a:text)
  elseif a:format == 1
    let l_data = s:get_OSC52_DCS(a:text)
  else
    let l_data = s:get_OSC52(a:text)
  endif

  let l_len = strlen(l_data)
  if l_len < g:max_osc52_sequence
    call s:rawecho(l_data)
    echo '[OSC52] ' . l_len . ' characters copied'
  else
    echo "[OSC52] Selection too long to send to terminal: " . l_len
  endif

endfunction


"-------------------------------------------------------------------------------------------
" Source> 'https://github.com/ojroques/vim-oscyank/blob/main/plugin/oscyank.vim'
" Source> 'https://github.com/ojroques/vim-oscyank/blob/v1.0.0/plugin/oscyank.vim'
"-------------------------------------------------------------------------------------------

"NO esta funcionado (se desactiva)

"let s:commands = {
"  \ 'operator': {'block': '`[\<C-v>`]y', 'char': '`[v`]y', 'line': "'[V']y"},
"  \ 'visual': {'': 'gvy', 'V': 'gvy', 'v': 'gvy', '': 'gvy'}}
"
"function s:get_text(mode, type)
"  " Save user settings
"  let l:clipboard = &clipboard
"  let l:selection = &selection
"  let l:register = getreg('"')
"  let l:visual_marks = [getpos("'<"), getpos("'>")]
"
"  " Retrieve text
"  set clipboard=
"  set selection=inclusive
"  silent execute printf('keepjumps normal! %s', s:commands[a:mode][a:type])
"  let l:text = getreg('"')
"
"  " Restore user settings
"  let &clipboard = l:clipboard
"  let &selection = l:selection
"  call setreg('"', l:register)
"  call setpos("'<", l:visual_marks[0])
"  call setpos("'>", l:visual_marks[1])
"
"  return l:text
"endfunction
"
"" -------------------- PUBLIC   ----------------------------
"
"function! OSCYankOperatorCallback(type) abort
"
"  let l:success = 1
"  let l:text = s:get_text('operator', a:type)
"
"  SendViaOSC52(l:text)
"  return l:success
"
"endfunction
"
"function! OSCYankOperator() abort
"  set operatorfunc=OSCYankOperatorCallback
"  return 'g@'
"endfunction
"
"" Send the visual selection to the terminal's clipboard using OSC52.
"" https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
"function! OSCYankVisual() abort
"
"  let l:success = 1
"  "let [line_start, column_start] = getpos("'<")[1:2]
"  "let [line_end, column_end] = getpos("'>")[1:2]
"
"  "let lines = getline(line_start, line_end)
"  "if len(lines) == 0
"  "  return ''
"  "endif
"
"  "let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
"  "let lines[0] = lines[0][column_start - 1:]
"
"  "SendViaOSC52(join(lines, "\n"))
"  "execute "normal! `<"
"
"  let l:text = s:get_text('visual', visualmode())
"
"  SendViaOSC52(l:text)
"  return l:success
"
"endfunction
"
"function! OSCYankRegister(register) abort
"
"  let l:success = 1
"  let l:text = getreg(a:register)
"
"  SendViaOSC52(l:text)
"  return l:success
"
"endfunction
"
"" -------------------- COMMANDS ----------------------------
"
"command! -nargs=1 OSCYank call SendViaOSC52('<args>')
"command! -range OSCYankVisual call OSCYankVisual()
"command! -register OSCYankRegister call OSCYankRegister('<reg>')
"
"nnoremap <expr> <Plug>OSCYankOperator OSCYankOperator()
"vnoremap <Plug>OSCYankVisual :OSCYankVisual<CR>

