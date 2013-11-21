"-------------------------

" Vundle it!

filetype off
set rtp+=~/.vim/bundle/vundle
call vundle#rc()

"-------------------------

" Add my bundles here:

" The bundle manager.
Bundle 'gmarik/vundle'

" Provides autoclose feature. Repeat with me: Hail Thiago Alves!
Bundle 'vim-scripts/AutoClose--Alves'

" The awesome commenter.
Bundle 'scrooloose/nerdcommenter'

" The awesome dirtree.
Bundle 'scrooloose/nerdtree'

" The screen / tmux plugin.
Bundle 'ervandew/screen'

" Overload the fucking tab!
Bundle 'ervandew/supertab'

" Surround the shit outta 'em.
Bundle 'tpope/vim-surround'

" And repeat the surrounds. Hallelujah!
Bundle 'tpope/vim-repeat'

" Snippets FTW \m/.
Bundle 'vim-scripts/UltiSnips'

" R plugin.
Bundle 'vim-scripts/Vim-R-plugin'

" Latex suite.
Bundle 'vim-scripts/LaTeX-Suite-aka-Vim-LaTeX'

" Graphical UNDO
Bundle 'sjl/gundo.vim'

" Markdown highlighting.
Bundle 'tpope/vim-markdown'

" Vim-flavored-markdown.
Bundle 'jtratner/vim-flavored-markdown'

" YankRing like the EMACS kill ring.
Bundle 'vim-scripts/YankRing.vim'

" Escape shell color codes in Vim.
Bundle 'AnsiEsc.vim'

" Escape shell color codes in Vim.
Bundle 'vim-scripts/CSApprox'

"-------------------------

" These are global Vim options.

" Auto-detect the file type.
filetype indent plugin on

" Highlight syntax.
syntax enable

" Colorscheme.
if has('gui_running')
  colorscheme desert
else
  colorscheme desert
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

"-------------------------

let mapleader=","

let maplocalleader=","

"-------------------------

" These options are for the vim-R-plugin

let vimrplugin_underscore = 0

let vimrplugin_by_vim_instance = 1

let vimrplugin_vimpager = "vertical"

let vimrplugin_editor_w = 80

let vimrplugin_editor_h = 60

let vimrplugin_notmuxconf = 1

let vimrplugin_routmorecolors = 1

let vimrplugin_indent_commented = 0

" Custom commands.

map <LocalLeader>nr :call RAction("rownames")<CR>
map <LocalLeader>nc :call RAction("colnames")<CR>
map <LocalLeader>n2 :call RAction("names")<CR>
map <LocalLeader>nn :call RAction("dimnames")<CR>
map <LocalLeader>nd :call RAction("dim")<CR>
map <LocalLeader>nh :call RAction("head")<CR>
map <LocalLeader>nt :call RAction("tail")<CR>
map <LocalLeader>nl :call RAction("length")<CR>
map <LocalLeader>cc :call RAction("class")<CR>
map <LocalLeader>nw :call SendCmdToR("system('clear')")<CR>
map <LocalLeader>ne :call SendCmdToR("system('traceback()')")<CR>
map <LocalLeader>sb :call SendCmdToR("system.time({")<CR>
map <LocalLeader>se :call SendCmdToR("})")<CR>

"-------------------------

" These options are for UltiSnips.

let g:UltiSnipsEditSplit = "horizontal"

let g:UltiSnipsSnippetsDir = "~/git/configs/snippets"

let g:UltiSnipsSnippetDirectories = ["snippets"]

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

" Supertab config. For some reason filename completion does not work anymore.

let g:SuperTabDefaultCompletionType = 'context'

"-------------------------

" Gundo's config.

nnoremap gu :GundoToggle<CR>

let g:gundo_preview_bottom = 1

let g:gundo_right = 1

"-------------------------

" YankRing configuration.

let g:yankring_min_element_length = 2

let g:yankring_max_display = 79

let g:yankring_persist = 0

let g:yankring_paste_using_g = 0

let g:yankring_history_file = '.yankring'

nnoremap <silent> gp :YRShow<CR>

"-------------------------

" Turn on PEP8 style guidelines for python files.

autocmd BufRead,BufNewFile *.py setlocal shiftwidth=4 tabstop=4 softtabstop=4

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

" Navigate between and delete tabs.

"-------------------------

if has("gui_running")
  nnoremap <M-j> :tabprevious<CR>
  nnoremap <M-k> :tabnext<CR>
  nnoremap <M-h> :tabfirst<CR>
  nnoremap <M-l> :tablast<CR>
  nnoremap <M-d> :bdelete<CR>
endif

nnoremap gj :tabprevious<CR>
nnoremap gk :tabnext<CR>
nnoremap gh :tabfirst<CR>
nnoremap gl :tablast<CR>
nnoremap gd :bdelete<CR>

"-------------------------

" Move by display lines in place of actual lines.

nnoremap j gj
nnoremap k gk

"-------------------------

" Puts an empty line above and below the cursor position and enters the insert
" mode.

nnoremap <leader><leader>o <Esc>O<CR>

"-------------------------

" Delete all trailing whitespace.

nnoremap <leader><leader>w :%s/\s\+$//e<CR>:let @/=''<CR>

"-------------------------

" Delete all blank lines (or containing only whitespace).

nnoremap <leader><leader>d :g:^\s*$:d<CR>

"-------------------------

" Condense multiple blanks lines (or containing only whitespace) into one.

nnoremap <leader><leader>c :%s/\s\+$//e<CR>:let @/=''<CR>:g/^$/,/./-j<CR>

"-------------------------

" Save when file was opened without sudo.

function SaveWithoutSudo()
  write !sudo tee % > /dev/null
endfunction
nnoremap <leader><leader>s :call SaveWithoutSudo()<CR>

"-------------------------

" Toggle search highlighting.

function ToggleHighLightsearch()
  if &hlsearch
    set nohlsearch
  else
    set hlsearch
  endif
endfunction

nnoremap <leader><leader>h :call ToggleHighLightsearch()<CR>

"-------------------------

" Reformat the paragraph.

nnoremap <leader><leader>f gqipj

"-------------------------

" Copy a paragraph to the os clipboard.

nnoremap <leader><leader>y mz"+yip`z

" Copy the whole buffer to the os clipboard.
 
nnoremap <leader><leader>Y mzgg"+yG`z

"-------------------------

" Remap file path completion bindings.

inoremap <C-z> <C-x><C-f>

"-------------------------

" Turn on spell-check and en_US language for text files.

autocmd BufRead,BufNewFile *.txt setlocal spell spelllang=en_us

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

" Use the github flavored markdown by default.

augroup markdown
    au!
    au BufNewFile,BufRead *.md,*.markdown setlocal filetype=ghmarkdown textwidth=0 wrapmargin=79 colorcolumn=80
augroup END
