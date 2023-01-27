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

" Mostly for the boxed comments
Plugin 'honza/vim-snippets'

"-------------------------

" Language specific plugins

" Latex suite.
Plugin 'gerw/vim-latex-suite'

" R plugin.
Plugin 'jalvesaq/Nvim-R'

" Python mode
Plugin 'python-mode/python-mode'

" Plugin to send commands to an external terminal - I use for Python
Plugin 'jalvesaq/vimcmdline'

" Better indentation for Python
Plugin 'hynek/vim-python-pep8-indent'

" Jedi for Python
Plugin 'davidhalter/jedi-vim'

" Flake8 linter.
Plugin 'nvie/vim-flake8'

" Javascript indentation for vim.
Plugin 'pangloss/vim-javascript'

" Julia for Vim.
Plugin 'JuliaLang/julia-vim'

" TOC for markdown
Plugin 'mzlogin/vim-markdown-toc'

" Pasting for markdown
Plugin 'akhilsbehl/md-image-paste'

"-------------------------

" Coloring related stuff

" Escape shell color codes in Vim.
Plugin 'AnsiEsc.vim'

" Gruvbox colorscheme.
Plugin 'morhetz/gruvbox'

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
silent! colorscheme gruvbox

"-------------------------

" These are values for global vim `options'. To deactivate any option,
" prepend `no' to the option. To activate, simply remove the `no'.

" Use Vim defaults.
set nocompatible

" Auto-switch to dir of the file.
set autochdir

" Look and feel options.
set cursorline cursorcolumn ruler number numberwidth=4 showmode showcmd mousefocus
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

nnoremap "," <NOP>
nnoremap "\<Space>" <NOP>

let mapleader=","
let maplocalleader="\<Space>"

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

" NerdCommenter

let g:NERDCreateDefaultMappings = 0

let NERDSpaceDelims = 1

let NERDRemoveExtraSpaces = 1

let NERDToggleCheckAllLines = 1

" Normal & visual mode map
nnoremap <silent> <leader>c<space> <Plug>NERDCommenterToggle
vnoremap <silent> <leader>c<space> <Plug>NERDCommenterToggle
nnoremap <silent> <leader>cA <Plug>NERDCommenterAppend

"-------------------------

" Nvim-R plugin

let g:Rout_prompt_str = 'R> '

let R_external_term = 'tmux split-pane'

let R_assign = 0

let R_nvimpager = "vertical"

let R_editor_w = 80

let R_editor_h = 60

let Rout_more_colors = 1

let R_indent_commented = 0

let R_user_maps_only = 1

augroup R
  autocmd!
  autocmd FileType r nmap <buffer> K <Plug>RHelp
  autocmd FileType r nmap <buffer> <localleader>o <Plug>RStart
  autocmd FileType r nmap <buffer> <localleader>q <Plug>RClose
  autocmd FileType r nmap <buffer> <localleader>l <Plug>RDSendLine
  autocmd FileType r vmap <buffer> <localleader>s <Plug>REDSendSelection
  autocmd FileType r nmap <buffer> <localleader>b <Plug>REDSendMBlock
  autocmd FileType r nmap <buffer> <localleader>p <Plug>REDSendParagraph
  autocmd FileType r nmap <buffer> <localleader>f <Plug>RSendFunction
  autocmd FileType r nmap <buffer> <localleader>F <Plug>RSendFile
  autocmd FileType r nmap <buffer> <localleader>g <Plug>RPlot
  autocmd FileType r nmap <buffer> <localleader>D <Plug>RSetwd
  autocmd FileType r nmap <buffer> <localleader>r :call RAction("rownames")<CR>
  autocmd FileType r nmap <buffer> <localleader>c :call RAction("colnames")<CR>
  autocmd FileType r nmap <buffer> <localleader>n :call RAction("names")<CR>
  autocmd FileType r nmap <buffer> <localleader>N :call RAction("dimnames")<CR>
  autocmd FileType r nmap <buffer> <localleader>d :call RAction("dim")<CR>
  autocmd FileType r nmap <buffer> <localleader>H :call RAction("head")<CR>
  autocmd FileType r nmap <buffer> <localleader>T :call RAction("tail")<CR>
  autocmd FileType r nmap <buffer> <localleader>L :call RAction("length")<CR>
  autocmd FileType r nmap <buffer> <localleader>C :call RAction("class")<CR>
  autocmd FileType r nmap <buffer> <localleader>m <Plug>RClearAll
  autocmd FileType r nmap <buffer> <localleader>t :call
        \ SendCmdToR("system.time({")<CR>
  autocmd FileType r nmap <buffer> <localleader>a :call SendCmdToR("})")<CR>
  autocmd FileType r nmap <buffer> <localleader>cc <Plug>RClearConsole
  autocmd FileType r nmap <localleader>tb :call SendCmdToR("traceback()")<CR>
augroup END

"-------------------------

" Latex-Suite

set grepprg=grep\ -nH\ $*

let g:tex_flavor='latex'

let g:Tex_ViewRule_pdf='mupdf'

let g:Tex_DefaultTargetFormat='pdf'

let g:Tex_SmartKeyQuote=0

let g:Tex_UseMakefile=0

let g:Tex_FoldedSections=""

let g:Tex_FoldedEnvironments=""

let g:Tex_FoldedMisc=""

"-------------------------

" AutoClose

let g:AutoClosePairs = {'(': ')', '{': '}', '[': ']', '"': '"'}

"-------------------------

" UltiSnips

let g:UltiSnipsListSnippets="<c-l>"

let g:UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit="~/.vim/mysnippets"

let g:UltiSnipsSnippetDirectories=["mysnippets", "UltiSnips"]

"-------------------------

" Supertab

let g:SuperTabDefaultCompletionType = 'context'

"-------------------------

" Undotree

nnoremap <leader>ut :UndotreeToggle<CR>

let g:undotree_WindowLayout = 2

let g:undotree_DiffpanelHeight = 20

"-------------------------

" Python plugins

let cmdline_vsplit                    = 0

let g:jedi#auto_vim_configuration     = 1

let g:jedi#popup_on_dot               = 1

let g:jedi#popup_select_first         = 1

let g:jedi#completions_enabled        = 1

let g:jedi#show_call_signatures       = 1

let g:jedi#smart_auto_mappings        = 1

let g:flake8_show_in_gutter           = 1

let cmdline_app                       = {}

let cmdline_term_width                = 120

let g:jedi#show_call_signatures_delay = 200

let cmdline_app['python']             = 'ipython'

let g:jedi#use_splits_not_buffers     = "winwidth"

let g:jedi#environment_path           = '.virtualenv'

let g:jedi#documentation_command      = "K"
let cmdline_map_start                 = '<localleader>o'
let cmdline_map_send                  = '<localleader>s'
let cmdline_map_source_fun            = '<localleader>F'
let cmdline_map_send_paragraph        = '<localleader>p'
let cmdline_map_send_block            = '<localleader>b'
let cmdline_map_quit                  = '<localleader>q'
let g:jedi#goto_definitions_command   = "<localleader>d"
let g:jedi#goto_assignments_command   = "<localleader>g"
let g:jedi#call_signatures_command    = '<localleader>S'
let g:jedi#rename_command_keep_name   = "<localleader>r"
let g:jedi#usages_command             = "<localleader>u"

augroup python
  autocmd!
  autocmd BufRead,BufNewFile *.py setlocal shiftwidth=4 tabstop=4 softtabstop=4
  autocmd FileType python nmap <buffer> <localleader>f :call Flake8()<CR>
augroup END

"-------------------------

" Julia plugin

augroup julia
  autocmd!
  autocmd FileType julia nmap <buffer> <localleader>h <Plug>(JuliaDocPrompt)
augroup END

"------------------------

" Github Copilot

let g:copilot_enabled = v:true

let g:copilot_no_tab_map = v:true

nmap <leader>cs :Copilot<CR>

imap <C-s> <Plug>(copilot-suggest)

imap <C-j> <Plug>(copilot-next)

imap <C-k> <Plug>(copilot-previous)

imap <silent><script><expr> <C-a> copilot#Accept("\<CR>")

imap <C-d> <Plug>(copilot-dismiss)

"-------------------------

" Markdown config

" vim-markdown-toc

let g:vmt_auto_update_on_save = 1

let g:vmt_fence_text = 'toc-marker : do-not-edit-this-line'

let g:vmt_fence_closing_text = 'toc-marker : do-not-edit-this-line'

let g:vmt_fence_hidden_markdown_style = 'GFM'

"-------------------------

" Preview markdown

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

" Use the github flavored markdown by default.

augroup markdown
    autocmd!
    autocmd BufNewFile,BufRead *.md,*.markdown setlocal filetype=markdown
    autocmd BufNewFile,BufRead *.md,*.markdown setlocal textwidth=0
    autocmd FileType markdown nmap <buffer> <localleader>t :GenTocGFM<CR>
    autocmd FileType markdown nmap <buffer> <localleader>u :UpdateToc<CR>
    autocmd FileType markdown nmap <buffer> <localleader>p
          \ :call PreviewMarkdown()<CR>
    autocmd FileType markdown vmap <buffer> <localleader>i
          \ :call DecorateSelection('*')<CR>
    autocmd FileType markdown vmap <buffer> <localleader>b
          \ :call DecorateSelection('**')<CR>
augroup END

"-------------------------

" HTML / JS: Don't break my lines; just wrap them visually.

augroup html
  autocmd!
  autocmd FileType html set textwidth=0 wrapmargin=0 wrap nolist
  autocmd FileType html set filetype=html.javascript
  autocmd FileType javascript set textwidth=0 wrapmargin=0 wrap nolist
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

augroup modechange
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

" Copy a paragraph to the os clipboard.

nnoremap <leader>yp mzyip`z

" Copy the whole buffer to the os clipboard.

nnoremap <leader>yb mzggyG`z

" Copy up to point to the os clipboard.

nnoremap <leader>yu mzygg`z

" Copy from point to the os clipboard.

nnoremap <leader>yf mzyG`z

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

vmap "sy :!xclip -f -sel clip
map "sp :r!xclip -o -sel clip

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

augroup findcursor
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
    let &t_EI .= "\<Esc>]12;orange\x7"
    " insert mode
    let &t_SI .= "\e[6 q"

    augroup windows_term
      autocmd!
      autocmd VimEnter * silent !echo -ne "\<Esc>]12;orange\x7"
      autocmd VimLeave * silent !echo -ne "\033]112\007"
    augroup END
endif
