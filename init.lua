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

        use 'wbthomason/packer.nvim'               -- Package manager

        use 'neovim/nvim-lspconfig'                -- Easily configure LSPs

        use { -- Easily installl stuff
            'williamboman/mason.nvim',
            config = function ()
                require('mason').setup()
            end
        }

        use { -- Easily installl stuff
            'williamboman/mason-lspconfig.nvim',
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

        use { -- Snippets engine
            'SirVer/UltiSnips',
            config = function()
                vg.UltiSnipsExpandTrigger       = "<c-e>"
                vg.UltiSnipsListSnippets        = "<c-l>"
                vg.UltiSnipsJumpForwardTrigger  = "<c-k>"
                vg.UltiSnipsJumpBackwardTrigger = "<c-j>"
                vg.UltiSnipsSnippetDirectories  = {"mysnippets", "UltiSnips"}
                vg.UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit =
                "~/.vim/mysnippets"
            end
        }
        use 'honza/vim-snippets'                   -- Snippets library

        use {
            'nvim-telescope/telescope.nvim',
            branch = '0.1.x',
            requires = {{'nvim-lua/plenary.nvim'}},
            config = function()
                local actions = require('telescope.actions')
                require('telescope').setup {
                    defaults = {
                        mappings = {
                            i = {
                                ["<esc>"]   = actions.close,
                                ["<C-?>"]   = actions.which_key,
                                ["<C-l>"]   = actions.move_selection_next,
                                ["<C-k>"]   = actions.move_selection_previous,
                                ["<cr>"]    = actions.select_default +
                                    actions.center,
                                ["<C-t>"]   = actions.select_tab,
                                ["<C-s>"]   = actions.select_horizontal,
                                ["<C-v>"]   = actions.select_vertical,
                                ["<C-u>"]   = actions.preview_scrolling_up,
                                ["<C-d>"]   = actions.preview_scrolling_down,
                                ["<C-f>"]   = actions.results_scrolling_up,
                                ["<C-b>"]   = actions.results_scrolling_down,
                                ["<C-q>"]   = actions.smart_send_to_qflist +
                                    actions.open_qflist,
                                ["<Tab>"]   = actions.toggle_selection +
                                    actions.move_selection_worse,
                                ["<S-Tab>"] = actions.toggle_selection +
                                    actions.move_selection_better,
                            },
                            n = {
                                ["<esc>"]   = actions.close,
                                ["?"]       = actions.which_key,
                                ["j"]       = actions.move_selection_next,
                                ["k"]       = actions.move_selection_previous,
                                ["<cr>"]    = actions.select_default +
                                    actions.center,
                                ["t"]       = actions.select_tab,
                                ["s"]       = actions.select_horizontal,
                                ["v"]       = actions.select_vertical,
                                ["u"]       = actions.preview_scrolling_up,
                                ["d"]       = actions.preview_scrolling_down,
                                ["f"]       = actions.results_scrolling_up,
                                ["b"]       = actions.results_scrolling_down,
                                ["gg"]      = actions.move_to_top,
                                ["G"]       = actions.move_to_bottom,
                                ["m"]       = actions.move_to_middle,
                                ["q"]       = actions.smart_send_to_qflist +
                                    actions.open_qflist,
                                ["<Tab>"]   = actions.toggle_selection +
                                    actions.move_selection_worse,
                                ["<S-Tab>"] = actions.toggle_selection +
                                    actions.move_selection_better,
                            },
                        },
                        layout_config = {
                            prompt_position = 'top',
                            preview_cutoff = 120,
                            width = 0.9,
                            height = 0.4,
                            horizontal = { mirror = false, },
                            vertical = { mirror = false, },
                        },
                        extensions = {
                            fzf = {
                                fuzzy = false,
                                override_generic_sorter = false,
                                override_file_sorter = true,
                                case_mode = 'smart_case',
                            },
                        },
                    },
                }

                require('telescope').load_extension('fzf')

                vk.set('n', '<leader>ff', '<cmd>Telescope git_files<cr>')
                vk.set('n', '<leader>fd', '<cmd>Telescope find_files<cr>')
                vk.set('n', '<leader>fG', '<cmd>Telescope live_grep<cr>')
                vk.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
                vk.set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')
                vk.set('n', '<leader>fR', '<cmd>Telescope oldfiles<cr>')
                vk.set('n', '<leader>fc', '<cmd>Telescope commands<cr>')
                vk.set('n', '<leader>ft', '<cmd>Telescope tags<cr>')
                vk.set('n', '<leader>f:', '<cmd>Telescope command_history<cr>')
                vk.set('n', '<leader>f/', '<cmd>Telescope search_history<cr>')
                vk.set('n', '<leader>f`', '<cmd>Telescope marks<cr>')
                vk.set('n', '<leader>fq', '<cmd>Telescope quickfix<cr>')
                vk.set('n', '<leader>fQ', '<cmd>Telescope quickfixhistory<cr>')
                vk.set('n', '<leader>fl', '<cmd>Telescope loclist<cr>')
                vk.set('n', '<leader>fj', '<cmd>Telescope jumplist<cr>')
                vk.set('n', '<leader>fo', '<cmd>Telescope vim_options<cr>')
                vk.set('n', '<leader>f@', '<cmd>Telescope registers<cr>')
                vk.set('n', '<leader>f?', '<cmd>Telescope keymaps<cr>')
                vk.set('n', '<leader>fH', '<cmd>Telescope highlights<cr>')
                vk.set('n', '<leader>fr', '<cmd>Telescope resume<cr>')
                vk.set('n', '<leader>fF', '<cmd>Telescope pickers<cr>')

                vk.set('n', '<leader>tD', '<cmd>Telescope diagnostics<cr>')
                vk.set('n', '<leader>tr', '<cmd>Telescope lsp_references<cr>')
                vk.set('n', '<leader>td', '<cmd>Telescope lsp_definitions<cr>')
                vk.set('n', '<leader>ti', '<cmd>Telescope lsp_incoming_calls<cr>')
                vk.set('n', '<leader>to', '<cmd>Telescope lsp_outgoing_calls<cr>')
                vk.set('n', '<leader>ti', '<cmd>Telescope lsp_implementations<cr>')
                vk.set('n', '<leader>tt',
                    '<cmd>Telescope lsp_type_definitions<cr>')
                vk.set('n', '<leader>ts',
                    '<cmd>Telescope lsp_document_symbols<cr>')
                vk.set('n', '<leader>tS',
                    '<cmd>Telescope lsp_workspace_symbols<cr>')

            end,
        }

        use { -- Treesitter text objects
            'nvim-treesitter/nvim-treesitter-textobjects',
            after = 'nvim-treesitter',
            requires = 'nvim-treesitter/nvim-treesitter',
        }
        use { -- Treesitter
            'nvim-treesitter/nvim-treesitter',
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
                            init_selection = '<cr>',
                            node_incremental = '<cr>',
                            node_decremental = '<bs>',
                            scope_incremental = '<S-cr>',
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
                                ['<leader>nf'] = '@function.outer',
                                ['<leader>nc'] = '@class.outer',
                            },
                            goto_next_end = {
                                ['<leader>nF'] = '@function.outer',
                                ['<leader>nC'] = '@class.outer',
                            },
                            goto_previous_start = {
                                ['<leader>pf'] = '@function.outer',
                                ['<leader>pc'] = '@class.outer',
                            },
                            goto_previous_end = {
                                ['<leader>pF'] = '@function.outer',
                                ['<leader>pC'] = '@class.outer',
                            },
                        },
                    },
                }
            end,
        }

        use { -- Slime
            'hkupty/iron.nvim',
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
                        send_motion    = '<>s',
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
        use { -- Fuzzy finder
            'nvim-telescope/telescope-fzf-native.nvim',
            run = 'make'
        }

        use { -- Search in git tree
            'mileszs/ack.vim',
            config = function()
                vg.ackprg = 'rg --vimgrep --no-heading --smart-case'
                vc [[
                    function! FindGitRoot()
                        return system(
                                    \ 'git rev-parse
                                    \ --show-toplevel
                                    \ 2> /dev/null')[:-2]
                    endfunction
                    command! -nargs=0 AckCword
                                \ execute 'Ack! ' .
                                \ expand('<cword>') . ' ' . FindGitRoot()
                ]]
                vk.set('n', '<leader>fg', '<cmd>AckCword<cr>')
            end,
        }

        use { -- Show newlines
            'lukas-reineke/indent-blankline.nvim',
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

        use { -- AI
            'github/copilot.vim',
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

        use { -- Commenting
            'scrooloose/nerdcommenter',
            config = function()
                vg.NERDCreateDefaultMappings = 0
                vg.NERDRemoveExtraSpaces     = 1
                vg.NERDSpaceDelims           = 1
                vg.NERDToggleCheckAllLines   = 1
                vk.set({'n', 'v'}, '<leader>c ', '<Plug>NERDCommenterToggle')
                vk.set('n', '<leader>cA', '<Plug>NERDCommenterAppend<cr>')
            end,
        }

        use { -- Markdown TOC
            'mzlogin/vim-markdown-toc',
            config = function()
                vg.vmt_auto_update_on_save = 1
                vg.vmt_fence_closing_text = 'toc-marker : do-not-edit'
                vg.vmt_fence_hidden_markdown_style = 'GFM'
                vg.vmt_fence_text = 'toc-marker : do-not-edit'
            end,
        }

        use { -- Pretty icons everywhere
            'nvim-tree/nvim-web-devicons',
            config = function ()
                require('nvim-web-devicons').setup {
                    default = true,
                    color_icons = true,
                }
            end
        }

        use { -- Status line
            'nvim-lualine/lualine.nvim',
            config = function()
                require('lualine').setup {
                    options = {
                        theme = 'tokyonight',
                    }
                }
            end
        }

        use { -- Show git signs
            'airblade/vim-gitgutter',
            config = function()
                vg.gitgutter_map_keys = 0
            end,
        }

        use { -- Undo history
            'jiaoshijie/undotree',
            requires = {'nvim-lua/plenary.nvim'},
        }

        use { -- Match pairs
            'windwp/nvim-autopairs',
            config = function()
                require('nvim-autopairs').setup({})
            end,
        }

        use { -- Show keybindings
            'folke/which-key.nvim',
            config = function()
                require('which-key').setup({})
            end,
        }

        use 'akhilsbehl/md-image-paste'            -- Paste images in md files

        use 'mg979/vim-visual-multi'               -- Multiple cursors

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

nnoremap <leader>ve :20split $MYVIMRC<CR>
nnoremap <leader>vg :tabnew $MYGVIMRC<CR>
nnoremap <leader>vs :source $MYVIMRC<CR>

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
nnoremap <leader>dtw :silent! call DeleteTrailingWhitespace()<CR>

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
-- Look at this for any other good ideas: rockerBOO/awesome-neovim
-- Markdown preview: use iamcco/markdown-preview.nvim
