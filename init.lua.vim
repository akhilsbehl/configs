lua << EOF

vf = vim.fn
vo = vim.opt
vk = vim.keymap
vg = vim.g
vc = vim.cmd

vg.mapleader = ','
vg.maplocalleader = ' '

local current_theme = 'onedark'

local ensure_packer = function()
    local install_path = vf.stdpath('data') ..
    '/site/pack/packer/start/packer.nvim'
    if vf.empty(vf.glob(install_path)) > 0 then
        vf.system({
            'git', 'clone', '--depth', '1',
            'https://github.com/wbthomason/packer.nvim', install_path
        })
        vc [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()
local use = require('packer').use

require('packer').startup(

    function(use)

        -- Some day look at this:
        -- rockerBOO/awesome-neovim

        use 'wbthomason/packer.nvim'               -- Package manager

        use 'neovim/nvim-lspconfig'                -- Easily configure LSPs

        use 'williamboman/mason.nvim'              -- Easily installl stuff

        use 'hrsh7th/cmp-nvim-lsp'                 -- LSP completions

        use 'hrsh7th/cmp-buffer'                   -- Buf tokens completions

        use 'hrsh7th/cmp-path'                     -- Path completions

        use 'hrsh7th/cmp-cmdline'                  -- Command line completions

        use 'hrsh7th/nvim-cmp'                     -- Completion engine

        use 'nvim-treesitter/nvim-treesitter'      -- The main reason

        use 'L3MON4D3/LuaSnip'                     -- Snippets engine

        use 'rafamadriz/friendly-snippets'         -- Snippets library

        use {
            'hkupty/iron.nvim',                    -- Slime
            config = function ()
                local icore = require('iron.core')
                local iview = require('iron.view')
                icore.setup {
                    config = {
                        scratch_repl = true,
                        repl_defintion = {
                            sh     = {'zsh'},
                            python = {'ipython'},
                            r      = {'R', '--no-save'},
                            julia  = {'julia', '--color  = yes'},
                        },
                        repl_open_cmd = iview.split.bot('40%')
                    },
                    ignore_blank_lines = true,
                    keymaps = {
                        send_motion    = '<localleader>s',
                        visual_send    = '<localleader>s',
                        send_line      = '<localleader>l',
                        send_file      = '<localleader>f',
                        clear          = '<localleader>L',
                        interrupt      = '<localleader>K',
                        exit           = '<localleader>Q',
                    },
                }
                vk.set('n', '<localleader>O', '<cmd>IronRepl<cr>')
                vk.set('n', '<localleader>F', '<cmd>IronFocus<cr>')
                vk.set('n', '<localleader>H', '<cmd>IronHide<cr>')
            end,
        }

        use {
            'mileszs/ack.vim',                     -- Search
            config = function()
                vg.ackprg = 'rg --vimgrep --no-heading --smart-case'
                vc [[
                    function! FindGitRoot()
                        return system(
                                    \ 'git rev-parse 
                                    \ --show-toplevel
                                    \ 2> /dev/null')[:-2]
                    endfunction
                    command! -nargs=1 AckInput 
                                \ execute 'Ack! <args> ' . FindGitRoot()
                    command! -nargs=0 AckCword
                                \ execute 'Ack! ' .
                                \ expand('<cword>') . ' ' . FindGitRoot()
                ]]
                vk.set('n', '<leader>ag', '<cmd>AckCword<cr>')
                vk.set('n', '<leader>aG', ':AckInput ')
            end,
        }

        use {
            'github/copilot.vim',                  -- AI
            config = function()
                vg.copilot_enabled = 1
                vg.copilot_no_tab_map = 1
                vk.set('i', '<C-s>', '<Plug>(copilot-suggest)')
                vk.set('i', '<C-d>', '<Plug>(copilot-dismiss)')
                vk.set('i', '<C-j>', '<Plug>(copilot-next)')
                vk.set('i', '<C-k>', '<Plug>(copilot-previous)')
                vk.set('i', '<S-Tab>', 'copilot#Accept("")', {expr = true})
                vk.set('n', '<leader>cs', '<cmd>Copilot<cr>')
            end,
        }

        use {
            'scrooloose/nerdcommenter',            -- Commenting
            config = function()
                vg.NERDCreateDefaultMappings = 0
                vg.NERDRemoveExtraSpaces     = 1
                vg.NERDSpaceDelims           = 1
                vg.NERDToggleCheckAllLines   = 1
                vk.set({'n', 'v'}, '<leader>c ', '<Plug>NERDCommenterToggle')
                vk.set('n', '<leader>cA', '<Plug>NERDCommenterAppend<cr>')
            end,
        }

        use 'junegunn/fzf'                         -- Fuzzy finder
        -- Stick with FZF until I have time to look at Telescope
        --   use {                                 -- Fuzzy finder
        --     'nvim-telescope/telescope.nvim',
        --     branch = '0.1.x',
        --     requires = { {'nvim-lua/plenary.nvim'} }
        --   }

        use {
            'lukas-reineke/indent-blankline.nvim', -- Show newlines
            config = function ()
                vo.list = true
                vo.listchars:append('lead:·')
                vo.listchars:append('trail:⋅')
                vo.listchars:append('nbsp:␣')
                vo.listchars:append('eol:↴')
                vo.listchars:append('tab:▸ ')
                require("indent_blankline").setup {
                    space_char_blankline = " ",
                    show_end_of_line = true,
                    show_current_context = true,
                    show_current_context_start = true,
                }
            end
        }

        use {
            'nvim-tree/nvim-web-devicons',         -- Pretty icons everywhere
            config = function ()
                require('nvim-web-devicons').setup {
                    default = true,
                    color_icons = true,
                }
            end
        }

        use {
            'nvim-lualine/lualine.nvim',           -- Status line
            config = function()
                require('lualine').setup {
                    options = { theme = current_theme },
                }
            end
        }

        use {
            'airblade/vim-gitgutter',              -- Show git signs
            config = function()
                vg.gitgutter_map_keys = 0
            end,
        }

        use {
            'jiaoshijie/undotree',                 -- Undo history
            requires = {'nvim-lua/plenary.nvim'},
        }

        use {
            'windwp/nvim-autopairs',               -- Match pairs
            config = function()
                require('nvim-autopairs').setup({})
            end,
        }

        use {
            'folke/which-key.nvim',                -- Show keybindings
            config = function()
                require('which-key').setup({})
            end,
        }

        use 'mg979/vim-visual-multi'               -- Multiple cursors

        -- use 'akhilsbehl/md-image-paste'         -- Paste images in md files

        use 'tpope/vim-surround'                   -- Use surround movements

        use 'tpope/vim-repeat'                     -- Repeat commands

        use 'godlygeek/tabular'                    -- Align rows

        use 'powerman/vim-plugin-AnsiEsc'          -- Escape shell color codes

        use 'morhetz/gruvbox'                      -- Theme: gruvbox

        use 'tomasr/molokai'                       -- Theme: molokai

        use 'joshdick/onedark.vim'                 -- Theme: onedark

        use 'folke/tokyonight.nvim'                -- Theme: tokyonight

        if packer_plugins['gruvbox'] and
           packer_plugins['gruvbox'].loaded then
            vg.gruvbox_contrast_dark = 'hard'
        end

        if packer_plugins['tokyonight'] and
           packer_plugins['tokyonight'].loaded then
            vg.tokyonight_style = 'night'
        end

        vc(string.format([[ silent! colorscheme %s ]], current_theme))

        if packer_bootstrap then
            require('packer').sync()
        end

    end
)

-- Lualine

EOF

"-------------------------

" These are values for global vim `options'. To deactivate any option,
" prepend `no' to the option. To activate, simply remove the `no'.

" Auto-detect the file type.
filetype indent plugin on

" Highlight syntax.
syntax enable

" Auto-switch to dir of the file.
set autochdir

" Look and feel options.
set termguicolors
set background=dark
set cursorline cursorcolumn ruler number relativenumber numberwidth=4
set textwidth=79 colorcolumn=+1 showmode showcmd laststatus=2
set mouse= mousefocus mousehide
let &t_8f="\<Esc>[38:2:%lu:%lu:%lum"
let &t_8b="\<Esc>[48:2:%lu:%lu:%lum"

" Search options.
set incsearch ignorecase smartcase hlsearch

" Indentation and tabstops.
set autoindent smartindent expandtab tabstop=8 softtabstop=4 shiftwidth=4

" Round to 'shiftwidth' for '<<' and '>>'.
set shiftround

" Don't use two spaces when joining a line after a '.', '?' or '!'.
set nojoinspaces

" Keep local rcs from executing harmful commands.
set secure

" End-of-line formats: 'dos', 'unix' or 'mac'.
set fileformat=unix fileformats=unix,dos,mac

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

" Fix the weird issue with backspace not behaving correctly around linebreaks
" and indentation stops
set backspace=indent,eol,start

"-------------------------

" Reload and source the vim config at will

nnoremap <leader>ev :20split $MYVIMRC<CR>
nnoremap <leader>eg :tabnew $MYGVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

"-------------------------

" Move by display lines in place of actual lines.

nnoremap j gj
nnoremap k gk

" Puts an empty line above and below the cursor position and enters the insert
" mode.

nnoremap <leader>oo <Esc>O<CR>

"-------------------------

" Navigate between and delete buffers, files, tabs.

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

" Working with diffs

nnoremap <leader>dgr :diffget RE<CR>
nnoremap <leader>dgl :diffget LO<CR>
nnoremap <leader>dpr :diffput RE<CR>
nnoremap <leader>dpl :diffput LO<CR>

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

" Forward the clipboard over SSH when connected with forwarding.

vnoremap "sy :!xclip -f -sel clip
nnoremap "sp :r!xclip -o -sel clip

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

" Making the cursor more conspicuous so I don't keep losing it.

function HighlightCursor()
    :normal zz
    match PMenuSel /\k*\%#\k*/
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

augroup HighLightCursor
    autocmd!
    autocmd WinEnter,BufEnter * call HighlightCursor()
    autocmd InsertEnter * call NoHighlightCursor()
    autocmd InsertLeave * call HighlightCursor()
    autocmd CursorMoved * call HighlightCursor()
augroup END

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

augroup PythonSetup
  autocmd!
  autocmd FileType python nnoremap <buffer> <localleader>ba
        \ :call AddPyBreakpoint()<CR>
  autocmd FileType python nnoremap <buffer> <localleader>br
        \ :call RemovePyBreakpoint()<CR>
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
