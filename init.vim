"-----------------------
" Look and feel options
"-----------------------

" Auto-switch to dir of the file.
set autochdir

" Look and feel options.
set ruler number relativenumber numberwidth=4
set showmode showcmd
set mouse-=a mousefocus
set textwidth=79 colorcolumn=+1 laststatus=3 signcolumn=yes
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

" Set up some global state for this feature
let g:myrc_highlight_cursor_time = 200 " in milliseconds
let g:myrc_highlight_timer = 0
let g:myrc_cursorline_match_id = 0
let g:myrc_cursorcolumn_match_id = 0
let g:myrc_word_match_id = 0

" Clear any existing highlighting
hi clear

" Define custom highlight groups
highlight MyCursorLine ctermfg=white guifg=white ctermbg=red guibg=red
highlight MyCursorColumn ctermfg=white guifg=white ctermbg=red guibg=red
highlight MySelectedWord ctermfg=white guifg=white ctermbg=green guibg=green

function! HighlightCursor() abort
    call NoHighlightCursor()

    " Set up the custom highlighting using matchadd()
    let g:myrc_cursorline_match_id = matchadd('MyCursorLine', '\%'.line('.').'l')
    let g:myrc_cursorcolumn_match_id = matchadd('MyCursorColumn', '\%'.col('.').'v')
    let g:myrc_word_match_id = matchadd('MySelectedWord', '\k*\%#\k*')

    " Start a timer to disable highlighting after 200ms
    let g:myrc_highlight_timer = timer_start(g:myrc_highlight_cursor_time, 'NoHighlightCursor')
endfunction

function! NoHighlightCursor(...) abort
    if g:myrc_cursorline_match_id != 0
        call matchdelete(g:myrc_cursorline_match_id)
        let g:myrc_cursorline_match_id = 0
    endif
    if g:myrc_cursorcolumn_match_id != 0
        call matchdelete(g:myrc_cursorcolumn_match_id)
        let g:myrc_cursorcolumn_match_id = 0
    endif
    if g:myrc_word_match_id != 0
        call matchdelete(g:myrc_word_match_id)
        let g:myrc_word_match_id = 0
    endif

    if g:myrc_highlight_timer != 0
        call timer_stop(g:myrc_highlight_timer)
        let g:myrc_highlight_timer = 0 " Reset the ID
    endif
endfunction

nnoremap <leader>hc :call HighlightCursor()<CR>

"-------------------------
" Save as new or a copy
"-------------------------

function! SaveAsSwitch(delete_original) abort
    let l:oldbuf  = bufnr('%')
    let l:oldname = expand('%:p')
    let l:newname = input('New name: ', l:oldname)

    if empty(l:newname)
        echo "Need a name for the new file"
        return
    endif

    if l:newname ==# l:oldname
        return
    endif

    if filereadable(l:newname)
        let l:choice = confirm(
            \ '"' . l:newname . '" already exists. Overwrite?',
            \ "&Yes\n&No",
            \ 2
            \ )

        if l:choice != 1
            echo "Save cancelled"
            return
        endif
    endif

    try
        execute 'write! ' . fnameescape(l:newname)
        execute 'edit ' . fnameescape(l:newname)
    catch /^Vim\%((\a\+)\)\=:/
        echomsg ''
        echohl ErrorMsg
        echomsg substitute(v:exception, '^\CVim\%((\a\+)\)\=:', '', '')
        echohl None
        return
    endtry

    if a:delete_original
        execute 'bdelete ' . l:oldbuf

        if delete(l:oldname)
            echohl ErrorMsg
            echomsg 'Failed to delete "' . l:oldname . '"'
            echohl None
        endif
    endif
endfunction

" Rename: save as, switch, delete original.
nnoremap <leader>sr :call SaveAsSwitch(1)<CR>

" Save copy: save as, switch, keep original.
nnoremap <leader>sc :call SaveAsSwitch(0)<CR>

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
" Add/remove pyright ignore for Python files
"-------------------------

function! TogglePyrightIgnore() abort
    let l:line = getline('.')
    let l:pattern = '  # pyright: ignore$'
    if l:line =~ l:pattern
        let l:newline = substitute(l:line, l:pattern, '', '')
    else
        let l:newline = l:line . '  ' . '# pyright: ignore'
    endif
    call setline('.', l:newline)
endfunction

"-------------------------
" Markdown files config.
"-------------------------

function! DecorateSelection(before, ...) abort
    let after = a:0 >= 1 ? a:1 : a:before
    normal! gv"xy
    let @x = a:before . @x . after
    normal! gvd
    let cursor_pos = getpos('.')
    normal! "xP
    call setpos('.', cursor_pos)
endfunction

let g:decorate_presets = {
            \ 'bold':    ['**', '**'],
            \ 'italic':  ['*', '*'],
            \ 'strike':  ['~~', '~~'],
            \ 'math':    ['$', '$'],
            \ 'code':    ['`', '`'],
            \ 'codeblock':    ["\n```\n", "\n```\n"],
            \ 'asb':     ['<<ASB: ', '>>'],
            \ 'asbstrike':     ['<<ASB: ~~', '~~>>'],
            \ }

function! DecorateWithPreset(name) abort
    if !has_key(g:decorate_presets, a:name)
        echoerr 'Unknown decoration preset: ' . a:name
        return
    endif
    let parts = g:decorate_presets[a:name]
    call DecorateSelection(parts[0], parts[1])
endfunction

function! MarkdownToFormat(format) range abort
    let l:format = tolower(a:format)

    if index(['docx', 'pdf'], l:format) < 0
        echohl ErrorMsg
        echom "Error: unsupported format: " . a:format
        echohl None
        return
    endif

    if !executable('pandoc')
        echohl ErrorMsg
        echom "Error: pandoc is not installed."
        echohl None
        return
    endif

    let l:filename = expand('%:t:r')

    if empty(l:filename)
        let l:filename = 'markdown_' . substitute(tempname(), '.*/', '', '')
    endif

    let l:tmp_md_path = '/tmp/' . l:filename . '.md'
    let l:output_path = '/tmp/' . l:filename . '.' . l:format

    if filereadable(l:tmp_md_path)
        call delete(l:tmp_md_path)
    endif

    if filereadable(l:output_path)
        call delete(l:output_path)
    endif

    " Write either the visual selection/range or the whole buffer.
    call writefile(getline(a:firstline, a:lastline), l:tmp_md_path)

    let l:command = 'pandoc ' . shellescape(l:tmp_md_path) .
                \ ' -o ' . shellescape(l:output_path)

    silent! execute '!' . l:command

    if !filereadable(l:output_path)
        echohl ErrorMsg
        echom "Error: pandoc failed to create " . l:output_path
        echohl None
        return
    endif

    if executable('wslview')
        silent! execute '!wslview ' . shellescape(l:output_path)
    else
        echom "Created: " . l:output_path
    endif
endfunction

function! MarkdownToDocx() range abort
    execute a:firstline . ',' . a:lastline . 'call MarkdownToFormat("docx")'
endfunction

function! MarkdownToPdf() range abort
    execute a:firstline . ',' . a:lastline . 'call MarkdownToFormat("pdf")'
endfunction

command! -range=% MarkdownToDocx <line1>,<line2>call MarkdownToDocx()
command! -range=% MarkdownToPdf <line1>,<line2>call MarkdownToPdf()

augroup MarkdownSetup
    autocmd!
    autocmd BufNewFile,BufRead *.md,*.markdown setlocal filetype=markdown
    autocmd BufNewFile,BufRead *.md,*.markdown setlocal
                \ textwidth=0 softtabstop=2 shiftwidth=2
    autocmd FileType markdown nnoremap <buffer> <localleader>p
                \ <Plug>MarkdownPreviewToggle
    autocmd FileType markdown nnoremap <buffer> <localleader>d
                \ :MarkdownToDocx<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>d
                \ :'<,'>MarkdownToDocx<CR>
    autocmd FileType markdown nnoremap <buffer> <localleader>P
                \ :MarkdownToPdf<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>P
                \ :'<,'>MarkdownToPdf<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>b
                \ :call DecorateWithPreset('bold')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>i
                \ :call DecorateWithPreset('italic')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>$
                \ :call DecorateWithPreset('math')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>s
                \ :call DecorateWithPreset('strike')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>c
                \ :call DecorateWithPreset('code')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>C
                \ :call DecorateWithPreset('codeblock')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>a
                \ :call DecorateWithPreset('asb')<CR>
    autocmd FileType markdown vnoremap <buffer> <localleader>A
                \ :call DecorateWithPreset('asbstrike')<CR>
augroup END

"-------------------------
" Some themes need to be reapplied. Unclear why
"-------------------------

augroup ChangeTheme
    autocmd!
    autocmd VimEnter,SourcePost $MYVIMRC colorscheme rose-pine
    autocmd VimEnter,SourcePost $MYVIMRC highlight Visual guibg=#8caed4
    autocmd VimEnter,SourcePost $MYVIMRC lua require('lualine').setup()
augroup END

"-------------------------
" Language specific file config for some cases
"-------------------------

augroup Python
    autocmd!
    autocmd BufNewFile,BufRead *.py setlocal foldmethod=indent
    autocmd FileType python nnoremap <buffer> <leader>ti
                \ :call TogglePyrightIgnore()<CR>
augroup END

augroup Ocaml
    autocmd!
    autocmd BufNewFile,BufRead *.ml setlocal shiftwidth=2
augroup END

augroup Shell
    autocmd!
    autocmd BufNewFile,BufRead *.sh,*.bash,*.zsh setlocal shiftwidth=2
augroup END

augroup TreesitterStart
    autocmd!
    autocmd FileType markdown,telekasten lua vim.treesitter.start()
augroup END

"-------------------------
" Unlimited textwidth for files with no specific filetype
"-------------------------

augroup NoFiletypeTextwidth
  autocmd!
  autocmd BufWinEnter,BufEnter * if empty(&l:filetype) | setlocal textwidth=0 | endif
augroup END

"-------------------------
" Colorscheme backgournd
"-------------------------

nnoremap <localleader>cd :set background=dark<CR>
nnoremap <localleader>cl :set background=light<CR>
