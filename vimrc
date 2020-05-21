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

" The screen / tmux plugin.
Plugin 'ervandew/screen'

" Overload the fucking tab!
Plugin 'ervandew/supertab'

" Surround the shit outta 'em.
Plugin 'tpope/vim-surround'

" And repeat the surrounds. Hallelujah!
Plugin 'tpope/vim-repeat'

" Snippets FTW \m/.
Plugin 'vim-scripts/UltiSnips'

" Graphical UNDO
Plugin 'sjl/gundo.vim'

" Use multiple cursors a la Sublime Text.
Plugin 'terryma/vim-multiple-cursors'

" Mofo plugin: Tabular.vim
Plugin 'godlygeek/tabular'

" FZF for fuzzy searching
Plugin 'junegunn/fzf', { 'do': { -> fzf#install() } }

" Ctrlp where FZF doesn't work
Plugin 'ctrlpvim/ctrlp.vim'

" Fugitive for git
Plugin 'tpope/vim-fugitive'

"-------------------------

" Language specific plugins

" Latex suite.
Plugin 'vim-scripts/LaTeX-Suite-aka-Vim-LaTeX'

" R plugin.
Plugin 'vim-scripts/Vim-R-plugin'

" Better indentation for Python
Plugin 'hynek/vim-python-pep8-indent'

" Flake8 linter.
Plugin 'nvie/vim-flake8'

" Scala by derekwyatt.
Plugin 'derekwyatt/vim-scala'

" Javascript indentation for vim.
Plugin 'pangloss/vim-javascript'

" Julia for Vim.
Plugin 'JuliaLang/julia-vim'

" GHCi plugin: SHIM for Vim.
Plugin 'vim-scripts/Superior-Haskell-Interaction-Mode-SHIM'

" Jedi for Python
Plugin 'davidhalter/jedi-vim'

" TOC for markdown
Plugin 'mzlogin/vim-markdown-toc'

"-------------------------

" I'm fabulous

" Escape shell color codes in Vim.
Plugin 'AnsiEsc.vim'

" Gruvbox & my edit of Monokai
Plugin 'morhetz/gruvbox'
Plugin 'akhilsbehl/vim-monokai'

"-------------------------

call vundle#end()

"-------------------------

" These are global Vim options.

" Auto-detect the file type.
filetype indent plugin on

" Highlight syntax.
syntax enable

" Colorscheme.
if has('gui_running')
  set background=dark
  colorscheme gruvbox
else
  set background=dark
  colorscheme gruvbox
endif

"-------------------------

" These are values for global vim `options'. To deactivate any option,
" prepend `no' to the option. To activate, simply remove the `no'.

" Use Vim defaults.
set nocompatible

" Auto-switch to dir of the file.
set autochdir

" Look and feel options.
set cursorline ruler number numberwidth=4 showmode showcmd mousefocus
set textwidth=79 colorcolumn=+1 laststatus=2

" Search options.
set incsearch ignorecase smartcase hlsearch

" Indentations (tabstops).
set autoindent smartindent expandtab tabstop=8 softtabstop=2 shiftwidth=2

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
set foldmethod=indent foldlevel=0 foldenable

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
set showtabline=1 timeoutlen=500

" Buffer switching behavior.
set switchbuf="useopen,usetab"

"-------------------------

let mapleader=","

let maplocalleader=","

"-------------------------

"-------------------------

" FZF configuration

if has("gui_running")
  let g:fzf_launcher='roxterm -e zsh -ic %s'
endif

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

" Search in FZF but it does not work on Cygwin
if !has('win32unix')
  nnoremap <silent> <leader>fz :call FuzzyFind()<CR>
  nnoremap <silent> <leader>fh :FZF ~<CR>
  nnoremap <silent> <leader>fd :FZF D:<CR>
  nnoremap <silent> <leader>fr :call fzf#run({
        \ 'source': v:oldfiles,
        \ 'sink' : 'e ',
        \ 'options' : '-m',
        \ })<CR>
else
  let g:ctrlp_map = ''
  let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
  let g:ctrlp_use_caching = 1
  let g:ctrlp_clear_cache_on_exit = 0
  let g:ctrlp_show_hidden = 1
  let g:ctrlp_open_multiple_files = '2vjr'
  let g:ctrlp_arg_map = 1
  let g:ctrlp_prompt_mappings = {
    \ 'PrtSelectMove("j")':   ['<c-j>', '<down>'],
    \ 'PrtSelectMove("k")':   ['<c-k>', '<up>'],
    \ 'PrtHistory(-1)':       ['<c-n>'],
    \ 'PrtHistory(1)':        ['<c-p>'],
    \ 'AcceptSelection("e")': ['<c-e>', '<2-LeftMouse>'],
    \ 'AcceptSelection("h")': ['<c-s>'],
    \ 'AcceptSelection("t")': ['<c-t>'],
    \ 'AcceptSelection("v")': ['<c-v>', '<RightMouse>'],
    \ 'ToggleRegex()':        ['<c-r>'],
    \ 'ToggleByFname()':      ['<c-f>'],
    \ 'ToggleType(1)':        ['<c-h>'],
    \ 'ToggleType(-1)':        ['<c-l>'],
    \ 'PrtClearCache()':      ['<c-d>'],
    \ 'CreateNewFile()':      ['<c-cr>'],
    \ 'MarkToOpen()':         ['<tab>'],
    \ 'OpenMulti()':          ['<cr>'],
    \ 'PrtExit()':            ['<esc>', '<c-c>', '<c-g>'],
    \
    \
    \
    \ 'PrtBS()':              ['<bs>', '<c-]>'],
    \ 'PrtDelete()':          ['<del>'],
    \ 'PrtDeleteWord()':      ['<c-w>'],
    \ 'PrtClear()':           ['<c-u>'],
    \ 'PrtSelectMove("t")':   ['<Home>', '<kHome>'],
    \ 'PrtSelectMove("b")':   ['<End>', '<kEnd>'],
    \ 'PrtSelectMove("u")':   ['<PageUp>', '<kPageUp>'],
    \ 'PrtSelectMove("d")':   ['<PageDown>', '<kPageDown>'],
    \ 'ToggleFocus()':        ['<c-F>'],
    \ 'PrtExpandDir()':       ['<c-X>'],
    \ 'PrtInsert("c")':       ['<MiddleMouse>', '<insert>'],
    \ 'PrtInsert()':          ['<c-\>'],
    \ 'PrtCurStart()':        ['<c-A>'],
    \ 'PrtCurEnd()':          ['<c-E>'],
    \ 'PrtCurLeft()':         ['<left>'],
    \ 'PrtCurRight()':        ['<right>'],
    \ }
  nnoremap <silent> <leader>fz :CtrlP<CR>
  nnoremap <silent> <leader>fh :CtrlP ~/<CR>
  nnoremap <silent> <leader>fd :CtrlP D:/<CR>
  nnoremap <silent> <leader>fr :CtrlPMRU<CR>
endif

"-------------------------

" Options for nerdcommenter to use spaces with the commenting char.

let NERDSpaceDelims=1

let NERDRemoveExtraSpaces=1

"-------------------------

" These options are for the vim-R-plugin

let vimrplugin_assign = 0

let vimrplugin_by_vim_instance = 1

let vimrplugin_vimpager = "vertical"

let vimrplugin_editor_w = 80

let vimrplugin_editor_h = 60

let vimrplugin_notmuxconf = 1

let Rout_more_colors = 1

let vimrplugin_indent_commented = 0

" Custom commands.

map <leader>rr :call RAction("rownames")<CR>
map <leader>rc :call RAction("colnames")<CR>
map <leader>rn :call RAction("names")<CR>
map <leader>rN :call RAction("dimnames")<CR>
map <leader>rd :call RAction("dim")<CR>
map <leader>rh :call RAction("head")<CR>
map <leader>rt :call RAction("tail")<CR>
map <leader>rl :call RAction("length")<CR>
map <leader>rC :call RAction("class")<CR>
map <leader>rL :call SendCmdToR("system('clear')")<CR>
map <leader>rT :call SendCmdToR("system('traceback()')")<CR>
map <leader>rt :call SendCmdToR("system.time({")<CR>
map <leader>ra :call SendCmdToR("})")<CR>

"-------------------------

" These options are for UltiSnips.

let g:UltiSnipsExpandTrigger = "<tab>"

let g:UltiSnipsListSnippets = "<C-tab>"

let g:UltiSnipsEditSplit = "context"

let g:UltiSnipsSnippetsDir = "~/.vim/mysnippets"

let g:UltiSnipsSnippetDirectories = [$HOME.'/.vim/mysnippets']

let g:UltiSnipsJumpForwardTrigger = "<C-k>"

let g:UltiSnipsJumpBackwardTrigger = "<C-j>"

"-------------------------

" These options are for the tex-suite plugin.

set grepprg=grep\ -nH\ $*

let g:tex_flavor='latex'

let g:Tex_CompileRule_pdf='pdflatex -interaction=nonstopmode'

let g:Tex_ViewRule_pdf='evince'

let g:Tex_DefaultTargetFormat='pdf'

" Do not convert my quotes.
let g:Tex_SmartKeyQuote=0

" Ignore any makefiles when called from vim.
let g:Tex_UseMakefile=0

" Do not let this plugin fold anything for me.
let g:Tex_FoldedSections=""
let g:Tex_FoldedEnvironments=""
let g:Tex_FoldedMisc=""

"-------------------------

" Remove single quotes from the set of autocompletions.

let g:AutoClosePairs = {'(': ')', '{': '}', '[': ']', '"': '"'}

"-------------------------

" Supertab config.

let g:SuperTabDefaultCompletionType = 'context'

"-------------------------

" Gundo's config.

nnoremap <leader>gu :GundoToggle<CR>

let g:gundo_preview_bottom = 1

let g:gundo_right = 1

"-------------------------

" Multi-cursor configuration.

let g:multi_cursor_exit_from_visual_mode = 0

let g:multi_cursor_exit_from_insert_mode = 0

let g_multi_cursor_insert_maps = {',': 1, '\': 1}

"-------------------------

" Turn on PEP8 style guidelines for python files.

autocmd BufRead,BufNewFile *.py setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType python map <buffer> <leader>pf :call Flake8()<CR>

"-------------------------

" ervandew/screen configuration to send commands to ipython.

" let g:ScreenImpl = "Tmux"

" Open an ipython3 shell.
autocmd FileType python map <leader>p3 :ScreenShell! ipython<CR>

" Open an ipython2 shell.
autocmd FileType python map <leader>p2 :ScreenShell! ipython2<CR>

" Close whichever shell is running.
autocmd FileType python map <leader>pq :ScreenQuit<CR>

" Send current line to python and move to next line.
autocmd FileType python map <leader>pr V:ScreenSend<CR>j

" Send visual selection to python and move to next line.
autocmd FileType python map <leader>pv :ScreenSend<CR>`>0j

" Send a carriage return line to python.
autocmd FileType python map <leader>pa :call g:ScreenShellSend("\r")<CR>

" Clear screen.
autocmd FileType python map <leader>pc
      \ :call g:ScreenShellSend('!clear')<CR>

" Start a time block to execute code in.
autocmd FileType python map <leader>pt
      \ :call g:ScreenShellSend('%%time')<CR>

" Start a timeit block to execute code in.
autocmd FileType python map <leader>pT
      \ :call g:ScreenShellSend('%%timeit')<CR>

" Start a debugger repl to execute code in.
autocmd FileType python map <leader>pD
      \ :call g:ScreenShellSend('%%debug')<CR>

" Start a profiling block to execute code in.
autocmd FileType python map <leader>pp
      \ :call g:ScreenShellSend('%%prun')<CR>

" Print the current working directory.
autocmd FileType python map <leader>pg
      \ :call g:ScreenShellSend('!pwd')<CR>

" Set working directory to current file's folder.
function SetWD()
  let wd = 'cd ' . expand('%:p:h')
  :call g:ScreenShellSend(wd)
endfunction
autocmd FileType python map <leader>ps :call SetWD()<CR>

" Get ipython help for word under cursor. Complement it with Shift + K.
function GetHelp()
  let w = expand("<cword>") . "??"
  :call g:ScreenShellSend(w)
endfunction
autocmd FileType python map <leader>ph :call GetHelp()<CR>

" Get `dir` help for word under cursor.
function GetDir()
  let w = "dir(" . expand("<cword>") . ")"
  :call g:ScreenShellSend(w)
endfunction
autocmd FileType python map <leader>pd :call GetDir()<CR>

" Get len of the word under cursor.
function GetLen()
  let w = "len(" . expand("<cword>") . ")"
  :call g:ScreenShellSend(w)
endfunction
autocmd FileType python map <leader>pl :call GetLen()<CR>

"-------------------------

" Jedi configuration for Python

let g:jedi#use_splits_not_buffers = "winwidth"
let g:jedi#popup_on_dot = 1
let g:jedi#show_call_signatures = "2"

let g:jedi#goto_command = "<LocalLeader>jg"
let g:jedi#documentation_command = "<LocalLeader>jh"
let g:jedi#rename_command = "<LocalLeader>jr"
let g:jedi#usages_command = "<LocalLeader>ju"

"-------------------------

" Make a file executable if found #!/bin/ at the start of a file.

function ModeChange()
  if getline(1) =~ "^#!"
    if getline(1) =~ "/bin/"
      silent execute "!chmod u+x <afile>"
    endif
  endif
endfunction

au BufWritePost * call ModeChange()

"-------------------------

" Navigate between and delete tabs.

nnoremap gt <C-w><S-t><CR>
nnoremap ge :tabnew<Space>
nnoremap gj :tabprevious<CR>
nnoremap gk :tabnext<CR>
nnoremap gh :tabfirst<CR>
nnoremap gl :tablast<CR>
nnoremap gc :close<CR>
nnoremap gd :bdelete<CR>
nnoremap gs :split<Space>
nnoremap gS :vsplit<Space>
nnoremap gS :vsplit<Space>
nnoremap gb :buffers<CR>:buffer<Space>

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
  :%s/\s\+$//g
  :let @/=''
endfunction
nnoremap <leader>wt :call DeleteTrailingWhitespace()<CR>

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

" Copy a paragraph to the os clipboard.

nnoremap <leader>yp mz"+yip`z

" Copy the whole buffer to the os clipboard.

nnoremap <leader>yb mzgg"+yG`z

" Copy up to point to the os clipboard.

nnoremap <leader>yu mz"+ygg`z

" Copy from point to the os clipboard.

nnoremap <leader>yf mz"+yG`z

"-------------------------

" Remap file path completion bindings.

inoremap <C-z> <C-x><C-f>

"-------------------------

" Only show cursorline in the current window and in normal mode

au WinLeave,InsertEnter * set nocursorline
au WinEnter,InsertLeave * set cursorline

"-------------------------

" Reload and source the vim config at will

nnoremap <leader>ev :tabnew $MYVIMRC<CR>
nnoremap <leader>eg :tabnew $MYGVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

"-------------------------

" Insert table of contents in Markdown

let g:vmt_auto_update_on_save = 1

let g:vmt_fence_text = 'toc-marker : do-not-edit-this-line'

let g:vmt_fence_closing_text = 'toc-marker : do-not-edit-this-line'

let g:vmt_fence_hidden_markdown_style = 'GFM'

"-------------------------

" Preview markdown

function! PreviewMarkdown()
  let outFile = '/tmp/' . expand('%:r') . '.html'
  silent execute '!cd %:p:h'
  silent execute '!md2html % >' . outFile
  silent execute 'redraw!'
endfunction

" Use the github flavored markdown by default.

augroup markdown
    au!
    au BufNewFile,BufRead *.md,*.markdown setlocal filetype=markdown
    au BufNewFile,BufRead *.md,*.markdown setlocal textwidth=0
    autocmd FileType markdown map <leader>pm
          \ :call PreviewMarkdown()<CR>
augroup END

"-------------------------

" HTML / JS: Don't break my lines; just wrap them visually.

autocmd FileType html set textwidth=0 wrapmargin=0 wrap nolist filetype=html.javascript
autocmd FileType javascript set textwidth=0 wrapmargin=0 wrap nolist

"-------------------------

" Forward the clipboard over SSH when connected with forwarding.

vmap "sy :!xclip -f -sel clip
map "sp :r!xclip -o -sel clip

"-------------------------

" Fix the weird issue with backspace not behaving correctly around linebreaks
" and indentation stops
set backspace=indent,eol,start

"-------------------------

nnoremap <silent> <leader>G :Gstatus<CR>
