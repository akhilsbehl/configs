"-----------------------
" Look and feel options
"-----------------------

" Set colorscheme.
colorscheme tokyonight

" Auto-switch to dir of the file.
set autochdir

" Look and feel options.
set cursorline ruler number relativenumber numberwidth=4
set showmode showcmd
set mouse-=a mousefocus
set textwidth=79 colorcolumn=+1 laststatus=2 signcolumn=yes
set termguicolors background=light
let &t_8f = "\<Esc>[38:2:%lu:%lu:%lum"
let &t_8b = "\<Esc>[48:2:%lu:%lu:%lum"

" Search options.
set incsearch ignorecase smartcase hlsearch

" Indentations (tabstops).
set autoindent smartindent expandtab tabstop=8 softtabstop=4 shiftwidth=4

" Round to 'shiftwidth' for '<<' and '>>'.
set shiftround

" Don't use two spaces when joining a line after a '.', '?' or '!'.
set nojoinspaces

" Keep local rcs from executing harmful commands.
set secure

" End-of-line formats: 'dos', 'unix' or 'mac'.
set fileformat=unix fileformats=unix,dos,mac

" Folding text.
set foldmethod=expr  " Uses tree-sitter
set foldexpr=nvim_treesitter#foldexpr()
set foldlevel=0 nofoldenable

" Stop backups and swap files.
set nobackup noswapfile

" Set hidden: Seems like I want it afterall.
set hidden

" Formatting options: read 'help formatoptions'.
set formatoptions=tcqn

" Filename completion in ex mode.
set wildmenu wildmode=longest,list,full

" Config.
set history=50 undolevels=500 tabpagemax=100 t_Co=256 t_ut="" winaltkeys=no
set showtabline=1 timeout timeoutlen=500 ttimeout ttimeoutlen=20

" Buffer switching behavior.
set switchbuf="useopen,usetab"

" Fix the weird issue with backspace not behaving correctly around linebreaks
" and indentation stops
set backspace=indent,eol,start

"-----------------------
" Navigate between buffers, tabs, and windows.
"-----------------------

function! ZoomBuffer() abort
    let row = line('.')
    let col = col('.')
    tabnew %
    call cursor(row, col)
endfunction

nnoremap tt <C-w><S-t><CR>
nnoremap te :e<Space>
nnoremap tE :tabnew<Space>
nnoremap tz :call ZoomBuffer()<CR>
nnoremap to :only<CR>
nnoremap tj <C-w>j<CR>
nnoremap tk <C-w>k<CR>
nnoremap th <C-w>h<CR>
nnoremap tl <C-w>l<CR>
nnoremap tx <C-w>x<CR>
nnoremap tr :e<CR>
nnoremap tR <C-w>r<CR>
nnoremap tmh <C-w>t<C-w>K<CR>
nnoremap tmv <C-w>t<C-w>H<CR>
nnoremap t= <C-w>=<CR>
nnoremap tJ :tabprevious<CR>
nnoremap tK :tabnext<CR>
nnoremap tH :tabfirst<CR>
nnoremap tL :tablast<CR>
nnoremap tc :close<CR>
nnoremap tC :tabclose<CR>
nnoremap td :bdelete<CR>
nnoremap ts :split<CR><C-w>j<CR>:buffers<CR>:buffer<Space>
nnoremap tS :split<Space>
nnoremap tv :vsplit<CR><C-w>l<CR>:buffers<CR>:buffer<Space>
nnoremap tV :vsplit<Space>
nnoremap tb :buffers<CR>:buffer<Space>

"-------------------------
" Working with quickfix
"-------------------------

nnoremap qo :copen<CR>
nnoremap qc :cclose<CR>
nnoremap qn :cnext<CR>
nnoremap qp :cprev<CR>
nnoremap qf :cfirst<CR>
nnoremap ql :clast<CR>

"-------------------------
" Working with loclist
"-------------------------

nnoremap <localleader>lo :lopen<CR>
nnoremap <localleader>lc :lclose<CR>
nnoremap <localleader>ln :lnext<CR>
nnoremap <localleader>lp :lprev<CR>
nnoremap <localleader>lf :lfirst<CR>
nnoremap <localleader>ll :llast<CR>

"-------------------------
" Working with diffs
"-------------------------

nnoremap <leader>dgr :diffget RE<CR>
nnoremap <leader>dgl :diffget LO<CR>
nnoremap <leader>dpr :diffput RE<CR>
nnoremap <leader>dpl :diffput LO<CR>

"-------------------------
" Start a new paragraph.
"-------------------------

nnoremap <leader>oo <Esc>O<CR>

"-------------------------
" Reformat the paragraph.
"-------------------------

nnoremap <leader>fp gqipj

"-------------------------
" Copy-paste behavior
"-------------------------

set clipboard=unnamedplus

" Copy the whole buffer to the os clipboard.
nnoremap <leader>yb mzggyG`z
" Copy from point to the os clipboard.
nnoremap <leader>yf mzyG`z
" Copy a paragraph to the os clipboard.
nnoremap <leader>yp mzyip`z
" Copy up to point to the os clipboard.
nnoremap <leader>yu mzygg`z
" When pasting do not clobber the original yank
vnoremap p "_dP

"-------------------------
" Remap file path completion bindings.
"-------------------------

inoremap <C-p> <C-x><C-f>

"-------------------------
" Reload and source the vim config at will.
"-------------------------

function! EditRC() abort
    tabnew ~/.config/nvim/vimrc
    vsplit ~/.config/nvim/init.lua
endfunction

nnoremap <leader>ve :call EditRC()<CR>
nnoremap <leader>vs :source $MYVIMRC<CR>

"-------------------------
" Forward the clipboard over SSH when connected with forwarding.
"-------------------------

vnoremap "sy :!xclip -f -sel clip
nnoremap "sp :r!xclip -o -sel clip

"-------------------------
" Toggle search highlighting.
"-------------------------

nnoremap <leader>hs :let @/ = ''<CR>

"-------------------------
" Delete all trailing whitespace.
"-------------------------

function! DeleteTrailingWhitespace() abort
    %s/\s\+$//e
    %s///e
    let @/ = ''
endfunction
nnoremap <leader>dtw :silent! call DeleteTrailingWhitespace()<CR>

"-------------------------
" Delete control characters.
"-------------------------

function! DeleteCtrlChars() abort
    %s/[[:cntrl:]]//eg
    let @/ = ''
endfunction
nnoremap <leader>dcc :call DeleteCtrlChars()<CR>

"-------------------------
" Squeeze multiple blank lines.
"-------------------------

function! SqueezeMultipleBlankLines()
    let current_position = getpos(".")
    execute ":%!cat -s"
    call setpos('.', current_position)
endfunction
nnoremap <leader>dmb :call SqueezeMultipleBlankLines()<CR>

"-------------------------
" Save when file was opened without sudo.
"-------------------------

function! SudoOnTheFly() abort
    write !sudo tee % > /dev/null
endfunction
nnoremap <leader>sd :call SudoOnTheFly()<CR>

"-------------------------
" Toggle paste mode.
"-------------------------

function! TogglePasteMode() abort
    if &paste
        set nopaste
    else
        set paste
    endif
endfunction
nnoremap <leader>tpm :call TogglePasteMode()<CR>

"-------------------------
" Keep the cursor centered.
"-------------------------

function! CenterCursor() abort
    if &buftype == 'terminal'
        return
    endif
    if line('.') == line('$')
        return
    endif
    let pos = getpos(".")
    normal! zz
    call setpos(".", pos)
endfunction

augroup CenterCursor
    autocmd!
    autocmd CursorMoved,CursorMovedI * call CenterCursor()
augroup END

"-------------------------
" Making the cursor more conspicuous so I don't keep losing it.
"-------------------------

function! HighlightCursor() abort
    match PmenuSel /\k*\%#\k*/
    let g:myrc_highlight_cursor = 1
endfunction

function! NoHighlightCursor() abort
    match None
    let g:myrc_highlight_cursor = 0
endfunction

function! ToggleHighlightCursor() abort
    if !exists("g:myrc_highlight_cursor")
        call HighlightCursor()
    else
        call NoHighlightCursor()
    endif
endfunction
nnoremap <leader>hc :call ToggleHighlightCursor()<CR>

"-------------------------
" Rename the current buffer's file in place and reload.
"-------------------------

function! SaveAsInPlace() abort
    let l:oldname = expand('%:p')
    let l:newname = input('New name: ', expand('%:p'))
    if empty(l:newname)
        echo "Need a name for the new file"
        return
    endif
    if l:newname != l:oldname
        try
            execute 'write ' . l:newname
            execute 'edit ' . l:newname
        catch /^Vim\%((\a\+)\)\=:/
            echomsg ' '
            echohl ErrorMsg
            echomsg substitute(v:exception, '^\CVim\%((\a\+)\)\=:', '', '')
            echohl None
            return
        endtry
        execute 'bdelete ' . l:oldname
        execute '!rm ' . l:oldname
    endif
endfunction
nnoremap <leader>sr :call SaveAsInPlace()<CR>

"-------------------------
" Toggle a simple terminal and scratch buffer.
"-------------------------

function! DisplayBufInFloatingWin(buf) abort
    let ui = nvim_list_uis()[0]
    let opts = {
                \ 'relative': 'editor',
                \ 'width': ui.width - 20,
                \ 'height': ui.height - 10,
                \ 'col': 10,
                \ 'row': 5 - 1,
                \ 'anchor': 'NW',
                \ 'style': 'minimal',
                \ 'border': 'rounded',
                \ }
    let win = nvim_open_win(a:buf, v:true, opts)
endfunction

function! QuitFloatingTerm() abort
    if exists('g:myrc_fterm_buf')
        execute 'bwipeout! ' . g:myrc_fterm_buf
        unlet g:myrc_fterm_buf
    endif
endfunction

function! OpenFloatingTerm() abort
    if !exists('g:myrc_fterm_buf')
        let g:myrc_fterm_buf = nvim_create_buf(v:false, v:true)
        call DisplayBufInFloatingWin(g:myrc_fterm_buf)
        call termopen('zsh')
        startinsert!
        call nvim_buf_set_keymap(g:myrc_fterm_buf, 't', '<leader>tt',
                    \ '<C-\><C-n><C-w>q', {'nowait': v:true})
        call nvim_buf_set_keymap(g:myrc_fterm_buf, 'n', '<leader>tt',
                    \ '<C-\><C-n><C-w>q', {'nowait': v:true})
        call nvim_buf_set_keymap(g:myrc_fterm_buf, 't', '<leader>tq',
                    \ '<C-\><C-n>:call QuitFloatingTerm()<cr>',
                    \ {'nowait': v:true})
        call nvim_buf_set_keymap(g:myrc_fterm_buf, 'n', '<leader>tq',
                    \ ':call QuitFloatingTerm()<cr>', {'nowait': v:true})
    else
        call DisplayBufInFloatingWin(g:myrc_fterm_buf)
        startinsert!
    endif
endfunction

function! QuitScratch() abort
    if exists('g:myrc_scratch')
        execute 'bwipeout! ' . g:myrc_scratch
        unlet g:myrc_scratch
    endif
endfunction

function! OpenScratch() abort
    if !exists('g:myrc_scratch')
        let g:myrc_scratch = nvim_create_buf(v:false, v:true)
        call DisplayBufInFloatingWin(g:myrc_scratch)
        call nvim_buf_set_keymap(g:myrc_scratch, 'n', '<leader>ss',
                    \ '<C-\><C-n><C-w>q', {'nowait': v:true})
        call nvim_buf_set_keymap(g:myrc_scratch, 'n', '<leader>sq',
                    \ ':call QuitScratch()<cr>', {'nowait': v:true})
    else
        call DisplayBufInFloatingWin(g:myrc_scratch)
    endif
endfunction

nnoremap <leader>tt :call OpenFloatingTerm()<CR>
nnoremap <leader>ss :call OpenScratch()<CR>
tnoremap t<Esc> <C-\><C-n><Esc>
tnoremap tj <Cmd>wincmd j<CR>
tnoremap tk <Cmd>wincmd k<CR>

"-------------------------
" Markdown files config.
"-------------------------

function! DecorateSelection(str) abort
    normal gv"xy
    let cursor_pos = getpos('.')
    let cursor_pos[2] = cursor_pos[2] - 1
    let @x = a:str . @x . a:str
    normal gvd
    call setpos('.', cursor_pos)
    normal "xp
endfunction

augroup MarkdownSetup
    autocmd!
    autocmd BufNewFile,BufRead *.md,*.markdown setlocal filetype=markdown
    autocmd BufNewFile,BufRead *.md,*.markdown setlocal 
            \ textwidth=0 softtabstop=2 shiftwidth=2
    autocmd FileType markdown nnoremap <buffer> <localleader>p
            \ <Plug>MarkdownPreviewToggle
    autocmd FileType markdown vnoremap <buffer> <localleader>i
            \ :call DecorateSelection('*')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>b
            \ :call DecorateSelection('**')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>d
            \ :call DecorateSelection('$')<CR>
augroup END

"-------------------------
" Some themes need to be reapplied. Unclear why
"-------------------------

augroup ChangeTheme
    autocmd!
    autocmd VimEnter,SourcePost $MYVIMRC colorscheme tokyonight
    autocmd VimEnter,SourcePost $MYVIMRC lua require('lualine').setup()
augroup END

"-------------------------
" Language specific file config for some cases
"-------------------------

augroup Python
    autocmd!
    autocmd BufNewFile,BufRead *.py setlocal foldmethod=indent
augroup END

augroup Ocaml
    autocmd!
    autocmd BufNewFile,BufRead *.ml setlocal shiftwidth=2
augroup END

augroup Shell
    autocmd!
    autocmd BufNewFile,BufRead *.sh,*.bash,*.zsh setlocal shiftwidth=2
augroup END

"-------------------------
" Colorscheme backgournd
"-------------------------

nnoremap <localleader>cd :set background=dark<CR>
nnoremap <localleader>cl :set background=light<CR>

"-------------------------
" AI helpers
"-------------------------

augroup AI
    autocmd!
    autocmd BufNewFile,BufRead * if expand($HAS_GH_COPILOT) == '1' |
            \ let g:copilot_enabled = 1 |
            \ let g:codeium_enabled = 0 |
    \ endif
augroup END
