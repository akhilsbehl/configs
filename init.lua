vc = vim.cmd
vf = vim.fn
vg = vim.g
vk = vim.keymap
vo = vim.opt

vg.mapleader = ','
vg.maplocalleader = ' '

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

        use {
            'williamboman/mason.nvim',             -- Easily installl stuff
            config = function ()
                require('mason').setup()
            end
        }

        use {
            'williamboman/mason-lspconfig.nvim',             -- Easily installl stuff
            config = function ()
                require('mason-lspconfig').setup()
            end
        }

        -- TODO
        use 'hrsh7th/cmp-nvim-lsp'                 -- LSP completions
        use 'hrsh7th/cmp-buffer'                   -- Buf tokens completions
        use 'hrsh7th/cmp-path'                     -- Path completions
        use 'hrsh7th/cmp-cmdline'                  -- Command line completions
        use 'hrsh7th/nvim-cmp'                     -- Completion engine

        use {
            'nvim-treesitter/nvim-treesitter',     -- Treesitter
            run = function()
                local ts_update = require('nvim-treesitter.install')
                    .update({ with_sync = true })
                ts_update()
            end,
            config = function ()
                vim.api.nvim_create_autocmd(
                    {'BufEnter','BufAdd','BufNew','BufNewFile','BufWinEnter'},
                    {
                        group = vim.api.
                            nvim_create_augroup('TS_FOLD_WORKAROUND', {}),
                        callback = function()
                            vim.opt.foldmethod = 'expr'
                            vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
                        end
                    }
                )
                require('nvim-treesitter.configs').setup {
                    ensure_installed = {'python', 'bash', 'r', 'lua'},
                    auto_install = true,
                    highlight = {
                        enable = true,
                    },
                    indent = {
                        enable = true,
                    },
                    incremental_selection = {
                        enable = true,
                        keymaps = {
                            init_selection = 'gss',
                            node_incremental = 'gin',
                            scope_incremental = 'gis',
                            node_decremental = 'gdn',
                        },
                    },
                    textobjects = {
                        select = {
                            enable = true,
                            keymaps = {
                                ['af'] = '@function.outer',
                                ['if'] = '@function.inner',
                                ['ac'] = '@class.outer',
                                ['ic'] = '@class.inner',
                            },
                        },
                        move = {
                            enable = true,
                            set_jumps = true,
                            goto_next_start = {
                                ['gnf'] = '@function.outer',
                                ['gnc'] = '@class.outer',
                            },
                            goto_next_end = {
                                ['gnF'] = '@function.outer',
                                ['gnC'] = '@class.outer',
                            },
                            goto_previous_start = {
                                ['gpf'] = '@function.outer',
                                ['gpc'] = '@class.outer',
                            },
                            goto_previous_end = {
                                ['gpF'] = '@function.outer',
                                ['gpC'] = '@class.outer',
                            },
                        },
                    },
                }
            end,
        }

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
            'junegunn/fzf',                        -- Fuzzy finder
            config = function ()
                vg.fzf_action = {
                    ['ctrl-e'] = 'e',
                    ['ctrl-t'] = 'tabedit',
                    ['ctrl-v'] = 'vertical botright split',
                    ['ctrl-s'] = 'botright split',
                    ['ctrl-m'] = 'vertical topleft split',
                    ['ctrl-q'] = 'topleft split',
                }
                vc [[
                    function! FuzzyFind()
                        let gitparent=system('git rev-parse
                                    \ --show-toplevel')[:-2]
                        if empty(matchstr(gitparent, '^fatal:.*'))
                            silent execute ':FZF ' . gitparent
                        else
                            silent execute ':FZF .'
                        endif
                    endfunction
                    command! -nargs=0 FindInGitRoot execute 'call FuzzyFind()'
                    command! -nargs=0 FindInFRU execute 'call fzf#run({
                                \ "source": v:oldfiles,
                                \ "sink": "e",
                                \ "options": "-m"
                                \ })'
                ]]
                vk.set('n', '<leader>fz', '<cmd>FindInGitRoot<cr>')
                vk.set('n', '<leader>fr', '<cmd>FindInFRU<cr>')
            end,
        }

        use {                                 -- Fuzzy finder
          'nvim-telescope/telescope.nvim',
          branch = '0.1.x',
          requires = {{'nvim-lua/plenary.nvim'}}
          config = function()
            local actions = require('telescope.actions')
            require('telescope').setup {
                defaults = {mappings = {i = {
                    ["<esc>"] = actions.close,
                    ["<C-h>"] = actions.which_key,
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                },},},
            }
            vk.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
            vk.set('n', '<leader>fz', '<cmd>Telescope live_grep<cr>')
            vk.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
            vk.set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')
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
            'lukas-reineke/indent-blankline.nvim', -- Show newlines
            config = function ()
                vo.list = true
                vo.listchars:append('lead:·')
                vo.listchars:append('trail:⋅')
                vo.listchars:append('nbsp:␣')
                vo.listchars:append('eol:↴')
                vo.listchars:append('tab:▸ ')
                require('indent_blankline').setup {
                    space_char_blankline = ' ',
                    show_end_of_line = true,
                    show_current_context = true,
                    show_current_context_start = true,
                }
            end
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

        use {
            'mzlogin/vim-markdown-toc',            -- Markdown TOC
            config = function()
                vg.vmt_auto_update_on_save = 1
                vg.vmt_fence_closing_text = 'toc-marker : do-not-edit'
                vg.vmt_fence_hidden_markdown_style = 'GFM'
                vg.vmt_fence_text = 'toc-marker : do-not-edit'
            end,
        }

        -- TODO
        -- use iamcco/markdown-preview.nvim        -- Markdown preview

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
                    options = {
                        theme = 'tokyonight',
                    }
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

        -- TODO
        -- use 'akhilsbehl/md-image-paste'         -- Paste images in md files

        use 'tpope/vim-surround'                   -- Use surround movements

        use 'tpope/vim-repeat'                     -- Repeat commands

        use 'godlygeek/tabular'                    -- Align rows

        use 'powerman/vim-plugin-AnsiEsc'          -- Escape shell color codes

        use 'morhetz/gruvbox'                      -- Theme: gruvbox

        use 'tomasr/molokai'                       -- Theme: molokai

        use 'joshdick/onedark.vim'                 -- Theme: onedark

        use 'folke/tokyonight.nvim'                -- Theme: tokyonight

        if packer_bootstrap then
            require('packer').sync()
        end

    end

)

vc [=[

"-----------------------
" Look and feel options
"-----------------------

" Set colorscheme.
colorscheme tokyonight

" Auto-switch to dir of the file.
set autochdir

" Look and feel options.
set cursorline cursorcolumn ruler number relativenumber numberwidth=4
set showmode showcmd
set mouse-=a
set textwidth=79 colorcolumn=+1 laststatus=2 
set termguicolors background=dark
let &t_8f="\<Esc>[38:2:%lu:%lu:%lum"
let &t_8b="\<Esc>[48:2:%lu:%lu:%lum"

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

"-----------------------
" Navigate between buffers, tabs, and windows.
"-----------------------

nnoremap tt <C-w><S-t><CR>
nnoremap te :e<Space>
nnoremap tE :tabnew<Space>
nnoremap to :only<CR>
nnoremap tj <C-w>j<CR>
nnoremap tk <C-w>k<CR>
nnoremap th <C-w>h<CR>
nnoremap tl <C-w>l<CR>
nnoremap tr <C-w>r<CR>
nnoremap tmh <C-w>t<C-w>K<CR>
nnoremap tmv <C-w>t<C-w>H<CR>
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

nnoremap <leader>lo :lopen<CR>
nnoremap <leader>lc :lclose<CR>
nnoremap <leader>ln :lnext<CR>
nnoremap <leader>lp :lprev<CR>
nnoremap <leader>lf :lfirst<CR>
nnoremap <leader>ll :llast<CR>

"-------------------------
" Working with diffs
"-------------------------

nnoremap <leader>dgr :diffget RE<CR>
nnoremap <leader>dgl :diffget LO<CR>
nnoremap <leader>dpr :diffput RE<CR>
nnoremap <leader>dpl :diffput LO<CR>

"-------------------------
" Move by display lines in place of actual lines.
"-----------------------

nnoremap j gj
nnoremap k gk

"-------------------------
" Start a new paragraph.
"-------------------------

nnoremap <leader>oo <Esc>O<CR>

"-------------------------
" Reformat the paragraph.
"-------------------------

nnoremap <leader>fp gqipj

"-------------------------
" Copy to clipboard.
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
"-------------------------

inoremap <C-p> <C-x><C-f>

"-------------------------
" Reload and source the vim config at will.
"-------------------------

nnoremap <leader>ev :20split $MYVIMRC<CR>
nnoremap <leader>eg :tabnew $MYGVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

"-------------------------
" Forward the clipboard over SSH when connected with forwarding.
"-------------------------

vnoremap "sy :!xclip -f -sel clip
nnoremap "sp :r!xclip -o -sel clip

"-------------------------
" Delete all trailing whitespace.
"-------------------------

function! DeleteTrailingWhitespace()
  :%s/\s\+$//e
  :%s///e
  :let @/=''
endfunction
nnoremap <leader>dtw :call DeleteTrailingWhitespace()<CR>

"-------------------------
" Delete control characters.
"-------------------------

function! DeleteCtrlChars()
  :%s/[[:cntrl:]]//e
  :let @/=''
endfunction
nnoremap <leader>dcc :call DeleteCtrlChars<CR>

"-------------------------
" Save when file was opened without sudo.
"-------------------------

function! SudoOnTheFly()
  write !sudo tee % > /dev/null
endfunction
nnoremap <leader>sd :call SudoOnTheFly()<CR>

"-------------------------
" Toggle search highlighting.
"-------------------------

function! ToggleHighLightsearch()
  if &hlsearch
    set nohlsearch
  else
    set hlsearch
  endif
endfunction
nnoremap <leader>hs :let @/=''<CR>

"-------------------------
" Toggle paste mode.
"-------------------------

function! TogglePasteMode()
  if &paste
    set nopaste
  else
    set paste
  endif
endfunction
nnoremap <leader>tpm :call TogglePasteMode()<CR>

"-------------------------
" Making the cursor more conspicuous so I don't keep losing it.
"-------------------------

function! HighlightCursor()
  :normal zz
  match PmenuSel /\k*\%#\k*/
  let s:highlightcursor=1
endfunction

function! NoHighlightCursor()
  match None
  let s:highlightcursor=0
endfunction

function! ToggleHighlightCursor()
  if !exists("s:highlightcursor")
    call HighlightCursor()
  else
    call NoHighlightCursor()
  endif
endfunction
nnoremap <leader>hc :call ToggleHighlightCursor()<CR>

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
" Rename the current buffer's file in place and reload.
"-------------------------

function! SaveAsInPlace()
  let l:oldname = expand('%:p')
  let l:newname = input('New name: ', expand('%:p'))
  if l:newname != l:oldname
    execute 'write ' . l:newname
    execute 'bdelete ' . l:oldname
    execute 'edit ' . l:newname
    execute '!rm ' . l:oldname
  endif
endfunction
nnoremap <leader>sr :call SaveAsInPlace()<CR>

"-------------------------
" Markdown files config.
"-------------------------

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
  autocmd FileType markdown vnoremap <buffer> <localleader>i
        \ :call DecorateSelection('*')<CR>
  autocmd FileType markdown vnoremap <buffer> <localleader>b
        \ :call DecorateSelection('**')<CR>
  autocmd FileType markdown vnoremap <buffer> <localleader>d
        \ :call DecorateSelection('$')<CR>
augroup END

]=]

-- TODOs:
