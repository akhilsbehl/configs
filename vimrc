"-------------------------

" These are the requirements to use the `pathogen' plugin

filetype off
call pathogen#infect()
call pathogen#runtime_append_all_bundles()
"call pathogen#helptags()

"-------------------------

" These are global Vim options.

" auto-detect the file type
filetype indent plugin on

" highlight syntax
syntax enable

" colorscheme
"colorscheme desert
colorscheme default

"-------------------------

" These are values for global vim `options'. To deactivate any option,
" prepend `no' to the option. To activate, simply remove the `no'.

" Use Vim defaults (much better!)
set nocompatible

" auto-switch to dir of the file
set autochdir

" look and feel options
set cursorline ruler number numberwidth=4 showmode showcmd mousefocus textwidth=79

" search options
set incsearch ignorecase smartcase nohlsearch

" indentations (tabstops)
set autoindent smartindent expandtab tabstop=8 softtabstop=2 shiftwidth=2

" round to 'shiftwidth' for '<<' and '>>'
set shiftround

" save hidden buffers
set hidden

" don't use two spaces when joining a line after a '.', '?' or '!'
set nojoinspaces

" keep local rcs from executing harmful commands.
set secure

" config
set history=50 undolevels=100 tabpagemax=100 t_Co=256 winaltkeys=no showtabline=1
" printing options
set printdevice=pdf printoptions=right:10pc,left:10pc,top:5pc,bottom:5pc,syntax:y,wrap:y,header:0,paper:A4

" end-of-line formats: 'dos', 'unix' or 'mac'
set fileformat=unix fileformats=unix,dos,mac

" function for filetype-specific Insert
set omnifunc=syntaxcomplete#Complete

" folding text
" set foldmethod=marker foldmarker=#<<<,>>>#

"-------------------------

let mapleader=","

let maplocalleader=","

"-------------------------

" These options are for the vim-R-plugin

" don't replace underscores in R
let vimrplugin_underscore=0

" use a single R process for all buffers of a single instance	
let vimrplugin_by_vim_instance=1

" use gnome-terminal with profile R
let vimrplugin_term_cmd = "gnome-terminal --profile R -e"

" help-pager configuration
let vimrplugin_vimpager = "vertical"
let vimrplugin_editor_w = 80
let vimrplugin_editor_h = 60

" Define new commands
map <LocalLeader>nr :call RAction("rownames")<CR>
map <LocalLeader>nc :call RAction("colnames")<CR>
map <LocalLeader>nh :call RAction("head")<CR>
map <LocalLeader>nt :call RAction("tail")<CR>
map <LocalLeader>nl :call RAction("length")<CR>
map <LocalLeader>nw :call SendCmdToR("system('clear')")<CR>
map <LocalLeader>sb :call SendCmdToR("system.time({")<CR>
map <LocalLeader>se :call SendCmdToR("})")<CR>

" Misc options
let vimrplugin_tmux = 0
let vimrplugin_routmorecolors = 1
let vimrplugin_indent_commented = 0

"-------------------------
" These options are for UltiSnips

let g:UltiSnipsEditSplit="vertical"

let g:UltiSnipsSnippetsDir="~/.vim/bundle/UltiSnips-1.5/UltiSnips/"

let g:UltiSnipsJumpForwardTrigger="<C-k>"

let g:UltiSnipsJumpBackwardTrigger="<C-j>"
"-------------------------

" These options are for the showmarks plugin

" keep these marks visible
let showmarks_include="abcdefghijklmnopqrstuvwxyz"

" I don't frickin' know what that means
let marksCloseWhenSelected=1

"-------------------------

" These options are for the tex-suite plugin.

" required for the tex-suite plugin
set grepprg=grep\ -nH\ $*

" required for the tex-suite plugin
let g:tex_flavor='latex'

" sets the pdflatex compile rule
let g:Tex_CompileRule_pdf='pdflatex -interaction=nonstopmode'

" sets the pdf file viewer
let g:Tex_ViewRule_pdf='evince'

" sets the default build format to pdf
let g:Tex_DefaultTargetFormat='pdf'

" do not convert my quotes
let g:Tex_SmartKeyQuote=0
"-------------------------

" This setting stops the annoying autocompletion of single quotes

let g:AutoClosePairs={'(': ')', '{': '}', '[': ']', '"': '"'}

"-------------------------

" These settings are for Taglist plugin

let Tlist_Exit_OnlyWindow=1

let Tlist_Show_One_File=1

"-------------------------

" This is a setting that helps `supertab' to switch between the various forms
" of text-completion on its own based on the context in which it is being used.

let g:SuperTabDefaultCompletionType='context'

"-------------------------

" Some nifty hacks from all over (some are my own)

" Make a file executable if found #!/bin/ at the start of a file.
au BufWritePost * if getline(1) =~ "^#!" | if getline(1) =~ "/bin/" | silent !chmod u+x <afile> | endif | endif

" This one helps one toggle search highlighting

function ToggleHighLightsearch()
  if &hlsearch
    set nohlsearch
  else
    set hlsearch
  endif
endfunction

imap <C-h> <Esc>:call ToggleHighLightsearch()<CR>
nmap <C-h> <Esc>:call ToggleHighLightsearch()<CR>
vmap <C-h> <Esc>:call ToggleHighLightsearch()<CR>

" Change tabs, buffers and delete buffers.

imap <M-j> <Esc>:tabp<CR>
nmap <M-j> <Esc>:tabp<CR>
vmap <M-j> <Esc>:tabp<CR>

imap <M-k> <Esc>:tabn<CR>
nmap <M-k> <Esc>:tabn<CR>
vmap <M-k> <Esc>:tabn<CR>

imap <M-p> <Esc>:bprevious<CR>
nmap <M-p> <Esc>:bprevious<CR>
vmap <M-p> <Esc>:bprevious<CR>

imap <M-n> <Esc>:bnext<CR>
nmap <M-n> <Esc>:bnext<CR>
vmap <M-n> <Esc>:bnext<CR>

imap <M-d> <Esc>:bdelete<CR>
nmap <M-d> <Esc>:bdelete<CR>
vmap <M-d> <Esc>:bdelete<CR>

" puts an empty line above and below the cursor position and enters the insert
" mode.

imap <M-o> <Esc>o<Esc>O
vmap <M-o> <Esc>o<Esc>O
nmap <M-o> <Esc>o<Esc>O

" Taken from command-line fu. Save system files when you forget to sudo while
" opening vim.

function SaveWithoutSudo()
  write !sudo tee %
endfunction
nmap <M-w> <Esc>:call SaveWithoutSudo()<CR>

" Move by display lines in place of actual lines.

nnoremap j gj
nnoremap k gk

" format a paragraph after making changes to it.

nmap <M-f> gqapgw$j
