"-------------------------

" Vundle it!

filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

"-------------------------

" Add my bundles here:

" The bundle manager.
Plugin 'gmarik/Vundle.vim'

" Provides autoclose feature. Repeat with me: Hail Thiago Alves!
Plugin 'vim-scripts/AutoClose--Alves'

" The awesome commenter.
Plugin 'scrooloose/nerdcommenter'

" Overload the fucking tab!
Plugin 'ervandew/supertab'

" Surround the shit outta 'em.
Plugin 'tpope/vim-surround'

" And repeat the surrounds. Hallelujah!
Plugin 'tpope/vim-repeat'

" Graphical UNDO
Plugin 'mbbill/undotree'

" Use multiple cursors - needs more practice.
Plugin 'mg979/vim-visual-multi'

" Mofo plugin: Tabular.vim - needs more practice.
Plugin 'godlygeek/tabular'

" FZF for fuzzy searching
Plugin 'junegunn/fzf', { 'do': { -> fzf#install() } }

" Ack for vim
Plugin 'mileszs/ack.vim'

" Github CoPilot
Plugin 'github/copilot.vim'

" Better matching on language elements
Plugin 'andymass/vim-matchup'

" Snippets even though Copilot
Plugin 'SirVer/UltiSnips'
Plugin 'honza/vim-snippets'

" Ale for LSP
Plugin 'dense-analysis/ale'

" Sending commands from vim to tmux
Plugin 'jpalardy/vim-slime'

"-------------------------

" Language specific plugins

" Latex suite.
Plugin 'gerw/vim-latex-suite'

" Better folding for Python
Plugin 'tmhedberg/SimpylFold'

" Javascript indentation for vim.
Plugin 'pangloss/vim-javascript'

" Julia for Vim.
Plugin 'JuliaLang/julia-vim'

" TOC for markdown
Plugin 'mzlogin/vim-markdown-toc'

" Pasting for markdown
Plugin 'akhilsbehl/md-image-paste'

"-------------------------

" Stuff to make things prettier

" Escape shell color codes in Vim.
Plugin 'AnsiEsc.vim'

" Colorschemes.
Plugin 'morhetz/gruvbox'
Plugin 'tomasr/molokai'
Plugin 'joshdick/onedark.vim'

" Airline for statusline.
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

"-------------------------

call vundle#end()

"-------------------------

" These are global Vim options.

" Auto-detect the file type.
filetype indent plugin on

" Highlight syntax.
syntax enable

" Colorscheme.
set termguicolors
let &t_8f="\<Esc>[38:2:%lu:%lu:%lum"
let &t_8b="\<Esc>[48:2:%lu:%lu:%lum"
set background=dark
let g:gruvbox_contrast_dark='hard'
" silent! colorscheme gruvbox
" silent! colorscheme molokai
silent! colorscheme onedark

"-------------------------

" These are values for global vim `options'. To deactivate any option,
" prepend `no' to the option. To activate, simply remove the `no'.

" Use Vim defaults.
set nocompatible

" Auto-switch to dir of the file.
set autochdir

" Look and feel options.
set cursorline cursorcolumn ruler number numberwidth=4 showmode showcmd
set textwidth=79 colorcolumn=+1 laststatus=2 mousefocus

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

" Printing options.
set printdevice=pdf
set printoptions=right:10pc,left:10pc,top:5pc,bottom:5pc,syntax:y,wrap:y,header:0,paper:A4

" End-of-line formats: 'dos', 'unix' or 'mac'.
set fileformat=unix fileformats=unix,dos,mac

" Function for filetype-specific insert.
set omnifunc=syntaxcomplete#Complete

" Folding text.
set foldmethod=indent foldlevel=0 nofoldenable

" Stop backups and swap files.
set nobackup noswapfile

" Set hidden: Seems like I want it afterall.
set hidden

" Always keep at least 3 lines above and below the cursor, except at the ends
" of the file.
set scrolloff=3

" Formatting options: read 'help formatoptions'.
set formatoptions=tcqn

" Filename completion in ex mode.
set wildmenu wildmode=longest,list,full

" Config.
set history=50 undolevels=500 tabpagemax=100 t_Co=256 t_ut="" winaltkeys=no
set showtabline=1 timeout timeoutlen=500 ttimeout ttimeoutlen=20

" Buffer switching behavior.
set switchbuf="useopen,usetab"

"-------------------------

" Set the leaders.

nnoremap "," <NOP>
nnoremap "\<Space>" <NOP>

let mapleader=","
let maplocalleader="\<Space>"

"-------------------------

" Configure airline themes & statusline.

let g:airline#extensions#ale#enabled       = 1
let g:airline_powerline_fonts              = 1
" let g:airline_theme                        = 'base16_gruvbox_dark_hard'
" let g:airline_theme                        = 'molokai'
let g:airline_theme                        = 'onedark'
let g:ariline#extensions#tabline#enabled   = 1
let g:ariline#extensions#tabline#formatter = 'default'

"-------------------------

" FZF

let g:fzf_action = {
      \ 'ctrl-e': 'e',
      \ 'ctrl-t': 'tabedit',
      \ 'ctrl-v': 'vertical botright split',
      \ 'ctrl-s': 'botright split',
      \ 'ctrl-m': 'vertical topleft split',
      \ 'ctrl-q': 'topleft split'}

function FuzzyFind()
  " Contains a null-byte that is stripped.
  let gitparent=system('git rev-parse --show-toplevel')[:-2]
  if empty(matchstr(gitparent, '^fatal:.*'))
    silent execute ':FZF ' . gitparent
  else
    silent execute ':FZF .'
  endif
endfunction

nnoremap <silent> <leader>fz :call FuzzyFind()<CR>
nnoremap <silent> <leader>fh :FZF ~<CR>
nnoremap <silent> <leader>fd :FZF /mnt/d<CR>
nnoremap <silent> <leader>fr :call fzf#run({
      \ 'source': v:oldfiles,
      \ 'sink' : 'e ',
      \ 'options' : '-m',
      \ })<CR>

"-------------------------

" Ale related configuration

let g:ale_change_sign_column_color = 1
let g:ale_comletion_autoimport = 1
let g:ale_completion_delay = 20
let g:ale_completion_enabled = 1
let g:ale_cursor_detail = 1
let g:ale_detail_to_floating_preview = 1
let g:ale_enabled = 1
let g:ale_fixers = {
      \ 'python': [
            \ 'add_blank_lines_for_python_control_statements',
            \ 'autoimport',
            \ 'black',
            \ 'remove_trailing_lines',
            \ 'trim_whitespace',
      \ ],
      \ 'r': ['styler'],
      \ 'markdown': ['prettier'],
      \ 'sh': ['shfmt'],
      \ 'bash': ['shfmt'],
      \ }
let g:ale_floating_preview = 1
let g:ale_hover_to_floating_preview = 1
let g:ale_lint_delay = 1000
let g:ale_lint_on_enter = 1
let g:ale_lint_on_filetype_changed = 1
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_linter_aliases = {
      \ 'rmarkdown': 'r',
      \ 'rmd': 'r',
      \ 'zsh': 'sh',
      \}
let g:ale_linters = {
      \ 'python': ['flake8', 'pyright'],
      \ 'r': ['lintr', 'styler'],
      \ 'markdown': ['mdl', 'textlint'],
      \ 'sh': ['shellcheck'],
      \ 'bash': ['shellcheck'],
      \ 'zsh': ['shellcheck'],
      \ 'vim': ['vint', 'vimls'],
      \  }
let g:ale_linters_explicit = 1
let g:ale_lsp_suggestions = 1
let g:ale_python_flake8_change_directory = 'file'
let g:ale_set_highlights = 1
let g:ale_set_quickfix = 0
let g:ale_set_loclist = 1
let g:ale_set_signs = 1
let g:ale_sign_column_always = 1
let g:ale_virtualenv_dir_names = ['.virtualenv']
let g:ale_virtualtext_cursor = 0
set omnifunc=ale#completion#OmniFunc  " Overrides global omnifunc.
nnoremap <leader>aD <Plug>(ale_go_to_type_definition_in_split)
nnoremap <leader>aF :ALEInfoToFile<Space>
nnoremap <leader>ah <Plug>(ale_hover)
nnoremap <leader>aI <Plug>(ale_import)
nnoremap <leader>aR <Plug>(ale_find_references)
nnoremap <leader>aT <Plug>(ale_Reset)
nnoremap <leader>ad <Plug>(ale_go_to_definition_in_split)
nnoremap <leader>af <Plug>(ale_fix)
nnoremap <leader>aH <Plug>(ale_documentation)
nnoremap <leader>ai <Plug>(ale_go_to_implementation_in_split)
nnoremap <leader>aj <Plug>(ale_next_wrap)
nnoremap <leader>ak <Plug>(ale_previous_wrap)
nnoremap <leader>al <Plug>(ale_lint)
nnoremap <leader>ar <Plug>(ale_rename)
nnoremap <leader>at <Plug>(ale_toggle)

" Show function signature after dot-completion
augroup ALEHoverAfterComplete
  autocmd!
  autocmd User ALECompletePost ALEHover
augroup END

"-------------------------

" NerdCommenter

let NERDRemoveExtraSpaces = 1
let NERDSpaceDelims = 1
let NERDToggleCheckAllLines = 1
let g:NERDCreateDefaultMappings = 0

" Normal & visual mode map
nnoremap <silent> <leader>c<space> <Plug>NERDCommenterToggle
vnoremap <silent> <leader>c<space> <Plug>NERDCommenterToggle
nnoremap <silent> <leader>cA <Plug>NERDCommenterAppend

"-------------------------

" Latex-Suite

let g:Tex_DefaultTargetFormat='pdf'
let g:Tex_FoldedEnvironments=""
let g:Tex_FoldedMisc=""
let g:Tex_FoldedSections=""
let g:Tex_SmartKeyQuote=0
let g:Tex_UseMakefile=0
let g:Tex_ViewRule_pdf='mupdf'
let g:tex_flavor='latex'
set grepprg=grep\ -nH\ $*

"-------------------------

" AutoClose

let g:AutoClosePairs = {'(': ')', '{': '}', '[': ']', '"': '"'}

"-------------------------

" UltiSnips

let g:UltiSnipsListSnippets="<c-l>"
let g:UltiSnipsSnippetDirectories=["mysnippets", "UltiSnips"]
let g:UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit="~/.vim/mysnippets"

"-------------------------

" Supertab

let g:SuperTabDefaultCompletionType = 'context'

"-------------------------

" Undotree

let g:undotree_DiffpanelHeight = 20
let g:undotree_WindowLayout = 2

nnoremap <leader>ut :UndotreeToggle<CR>

"-------------------------

" Slime configuration

let g:slime_bracketed_paste = 1
let g:slime_paste_file = "/tmp/slime_paste_file"
let g:slime_preserve_curpos = 1
let g:slime_target = "tmux"
xnoremap <buffer> <localleader>s <Plug>SlimeRegionSend
nnoremap <buffer> <localleader>l <Plug>SlimeLineSend
nnoremap <buffer> <localleader>p <Plug>SlimeParagraphSend
nnoremap <buffer> <localleader>M <Plug>SlimeMotionSend

"-------------------------

" Python configuration

function! AddPyBreakpoint()
  let l:line = line('.')
  let l:col = col('.')
  call feedkeys('Oimport pdb;pdb.set_trace()', 'nx')
  call cursor(l:line + 1, l:col)
endfunction

function RemovePyBreakpoint()
  let l:line = line('.')
  let l:col = col('.')
  call feedkeys('kdd', 'nx')
  call cursor(l:line - 1, l:col)
endfunction

function ActivateVirtualEnv()
python3 << EOF
import os
import sys
if 'VIRTUAL_ENV' in os.environ:
  env_path = os.environ['VIRTUAL_ENV']
  to_activate = os.path.join(env_path, 'bin', 'activate_this.py')
  with open(to_activate) as f:
    code = compile(f.read(), to_activate, 'exec')
    exec(code, dict(__file__=to_activate))
EOF
endfunction

augroup PythonSetup
  autocmd!
  autocmd FileType python call ActivateVirtualEnv()
  autocmd FileType python nnoremap <buffer> <localleader>ba
        \ :call AddPyBreakpoint()<CR>
  autocmd FileType python nnoremap <buffer> <localleader>br
        \ :call RemovePyBreakpoint()<CR>
augroup END

"-------------------------

" Julia plugin

augroup JuliaSetup
  autocmd!
  autocmd FileType julia nnoremap <buffer>
        \ <localleader>h <Plug>(JuliaDocPrompt)
augroup END

"------------------------

" Github Copilot

let g:copilot_enabled = v:true
let g:copilot_no_tab_map = v:true

inoremap <C-d> <Plug>(copilot-dismiss)
inoremap <C-j> <Nop>
inoremap <C-j> <Plug>(copilot-next)
inoremap <C-k> <Plug>(copilot-previous)
inoremap <C-s> <Plug>(copilot-suggest)
inoremap <expr> <S-Tab> copilot#Accept("")
nnoremap <leader>cs :Copilot<CR>

" For whatever reason copilot$Accept mapping requires sourcing the rc once
" again
augroup CopilotHack
  autocmd!
  autocmd VimEnter * source $MYVIMRC
augroup END

"-------------------------

" Markdown config

let g:vmt_auto_update_on_save = 1
let g:vmt_fence_closing_text = 'toc-marker : do-not-edit-this-line'
let g:vmt_fence_hidden_markdown_style = 'GFM'
let g:vmt_fence_text = 'toc-marker : do-not-edit-this-line'

function PreviewMarkdown()
  let outFile = './' . expand('%:r') . '.html'
  silent execute '!cd %:p:h'
  silent execute '!md2html % >' . outFile
  silent execute 'redraw!'
endfunction

function! DecorateSelection(str)
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
  autocmd BufNewFile,BufRead *.md,*.markdown setlocal textwidth=0
  autocmd FileType markdown nnoremap <buffer> <localleader>t :GenTocGFM<CR>
  autocmd FileType markdown nnoremap <buffer> <localleader>u :UpdateToc<CR>
  autocmd FileType markdown nnoremap <buffer> <localleader>p
        \ :call PreviewMarkdown()<CR>
  autocmd FileType markdown vnoremap <buffer> <localleader>i
        \ :call DecorateSelection('*')<CR>
  autocmd FileType markdown vnoremap <buffer> <localleader>b
        \ :call DecorateSelection('**')<CR>
augroup END

"-------------------------

" HTML / JS: Don't break my lines; just wrap them visually.

augroup HTMLSetup
  autocmd!
  autocmd FileType html setlocal textwidth=0 wrapmargin=0 wrap nolist
  autocmd FileType html setlocal filetype=html.javascript
  autocmd FileType javascript setlocal textwidth=0 wrapmargin=0 wrap nolist
augroup END

"-------------------------

" Make a file executable if found #!/bin/ at the start of a file.

function ModeChange()
  if getline(1) =~ "^#!"
    if getline(1) =~ "/bin/"
      silent execute "!chmod u+x <afile>"
    endif
  endif
endfunction

augroup ModeChange
  autocmd!
  autocmd BufWritePost * call ModeChange()
augroup END

"-------------------------

" Navigate between and delete tabs.

nnoremap tt <C-w><S-t><CR>
nnoremap te :e<Space>
nnoremap tE :tabnew<Space>
nnoremap to :only<CR>
nnoremap tj <C-w>j<CR>
nnoremap tk <C-w>k<CR>
nnoremap th <C-w>h<CR>
nnoremap tl <C-w>l<CR>
nnoremap tr <C-w>r<CR>
nnoremap tJ :tabprevious<CR>
nnoremap tK :tabnext<CR>
nnoremap tH :tabfirst<CR>
nnoremap tL :tablast<CR>
nnoremap tc :close<CR>
nnoremap td :bdelete<CR>
nnoremap ts :split<CR><C-w>j<CR>:buffers<CR>:buffer<Space>
nnoremap tS :split<Space>
nnoremap tv :vsplit<CR><C-w>l<CR>:buffers<CR>:buffer<Space>
nnoremap tV :vsplit<Space>
nnoremap tb :buffers<CR>:buffer<Space>

"-------------------------

" Move by display lines in place of actual lines.

nnoremap j gj
nnoremap k gk

"-------------------------

" Puts an empty line above and below the cursor position and enters the insert
" mode.

nnoremap <leader>oo <Esc>O<CR>

"-------------------------

" Fix whitespace issues

" Delete all trailing whitespace.
function DeleteTrailingWhitespace()
  :%s/\s\+$//e
  :%s///e
  :let @/=''
endfunction
nnoremap <leader>dtw :call DeleteTrailingWhitespace()<CR>

" Delete blank lines (or containing only whitespace).
function DeleteBlankLines()
  :g:^\s*$:d
  :let @/=''
endfunction
nnoremap <leader>bd :call DeleteBlankLines()<CR>

" Condense multiple blank lines (or containing only whitespace)
function CondenseBlankLines()
  :call DeleteTrailingWhitespace()
  :%s/\(\n\n\)\n\+/\1/
  :let @/=''
endfunction
nnoremap <leader>bc :call CondenseBlankLines()<CR>

" All of the above
function TreatAllWhitespace()
  :call CondenseBlankLines()
  :call DeleteBlankLines()
endfunction
nnoremap <leader>wa :call TreatAllWhitespace()<CR>

"-------------------------

" Remove control characters

function DeleteCtrlChars()
  :%s/[[:cntrl:]]//e
  :let @/=''
endfunction
nnoremap <leader>dcc :call DeleteCtrlChars<CR>

"-------------------------

" Save when file was opened without sudo.

function SudoOnTheFly()
  write !sudo tee % > /dev/null
endfunction
nnoremap <leader>sd :call SudoOnTheFly()<CR>

"-------------------------

" Toggle search highlighting.

function ToggleHighLightsearch()
  if &hlsearch
    set nohlsearch
  else
    set hlsearch
  endif
endfunction

nnoremap <leader>hs :let @/=''<CR>

" Toggle paste mode.

function TogglePasteMode()
  if &paste
    set nopaste
  else
    set paste
  endif
endfunction

nnoremap <leader>tpm :call TogglePasteMode()<CR>

"-------------------------

" Reformat the paragraph.

nnoremap <leader>fp gqipj

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

"-------------------------

" Remap file path completion bindings.

inoremap <C-p> <C-x><C-f>

"-------------------------

" Reload and source the vim config at will

nnoremap <leader>ev :20split $MYVIMRC<CR>
nnoremap <leader>eg :tabnew $MYGVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

"-------------------------

" Forward the clipboard over SSH when connected with forwarding.

vnoremap "sy :!xclip -f -sel clip
nnoremap "sp :r!xclip -o -sel clip

"-------------------------

" Fix the weird issue with backspace not behaving correctly around linebreaks
" and indentation stops
set backspace=indent,eol,start

"-------------------------

" Making the cursor more conspicuous so I don't keep losing it.

function HighlightCursor()
  :normal zz
  match PmenuSel /\k*\%#\k*/
  let s:highlightcursor=1
endfunction

function NoHighlightCursor()
  match None
  unlet s:highlightcursor
endfunction

function ToggleHighlightCursor()
  if !exists("s:highlightcursor")
    call HighlightCursor()
  else
    call NoHighlightCursor()
  endif
endfunction

nnoremap <leader>hc :call ToggleHighlightCursor()<CR>

" Only show cursorline in the current window and in normal mode

augroup FindCursor
  autocmd!
  autocmd WinEnter * call HighlightCursor()
  autocmd InsertEnter * call NoHighlightCursor()
  autocmd InsertLeave * call HighlightCursor()
  autocmd CursorMoved * call HighlightCursor()
  autocmd WinEnter,InsertLeave * set cursorline
  autocmd WinLeave,InsertEnter * set nocursorline
augroup END

"-------------------------

" Ack

if executable('ag')
  let g:ackprg = 'ag --vimgrep --smart-case'
endif

" Use rg where available
if executable('rg')
  let g:ackprg = 'rg --vimgrep --smart-case'
endif

function FindGitRoot()
  return system('git rev-parse --show-toplevel 2> /dev/null')[:-2]
endfunction

command! -nargs=1 Ag execute "Ack! <args> " . FindGitRoot()

nnoremap <leader>aG :Ag<Space>
nnoremap <leader>ag :execute 'Ack! ' .
      \ expand('<cword>') . ' ' .
      \ FindGitRoot()<CR>

"-------------------------

" Working with diffs

nnoremap <leader>dgr :diffget RE<CR>
nnoremap <leader>dgl :diffget LO<CR>
nnoremap <leader>dpr :diffput RE<CR>
nnoremap <leader>dpl :diffput LO<CR>

"-------------------------

" Working with quickfix and loclist

nnoremap <leader>qo :copen<CR>
nnoremap <leader>qc :cclose<CR>
nnoremap <leader>qn :cnext<CR>
nnoremap <leader>qp :cprev<CR>
nnoremap <leader>qf :cfirst<CR>
nnoremap <leader>ql :clast<CR>

nnoremap <leader>lo :lopen<CR>
nnoremap <leader>lc :lclose<CR>
nnoremap <leader>ln :lnext<CR>
nnoremap <leader>lp :lprev<CR>
nnoremap <leader>lf :lfirst<CR>
nnoremap <leader>ll :llast<CR>

"-------------------------

function! SaveAsInPlace()
" Rename current buffer's filename
" delete old file from buffer
" reload new file into buffer
  let l:oldname = expand('%:p')
  let l:newname = input('New name: ', expand('%:p'))
  if l:newname != l:oldname
    silent! execute 'silent! write ' . l:newname
    silent! execute 'silent! bdelete ' . l:oldname
    silent! execute 'silent! edit ' . l:newname
    silent! execute '!rm ' . l:oldname
  endif
endfunction

nnoremap <leader>sr :call SaveAsInPlace()<CR>

"-------------------------

" Fixing the cursor shapes in WSL vim
" https://github.com/microsoft/terminal/issues/4335

if &term =~ '^tmux'
    " Link: https://vim.fandom.com/wiki/Configuring_the_cursor
    " 0 -> blinking block not working in wsl
    " 1 -> blinking block
    " 2 -> solid block
    " 3 -> blinking underscore
    " 4 -> solid underscore
    " Recent versions of xterm (282 or above) also support
    " 5 -> blinking vertical bar
    " 6 -> solid vertical bar
    " normal mode
    let &t_EI .= "\e[1 q"
    " replace mode
    let &t_SR .= "\e[3 q"
    " insert mode
    let &t_SI .= "\e[5 q"
endif
