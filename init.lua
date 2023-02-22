VA = vim.api
VC = vim.cmd
VF = vim.fn
VG = vim.g
VL = vim.lsp
VK = vim.keymap.set
VO = vim.opt

VG.mapleader = ','
VG.maplocalleader = ' '

local ensure_packer = function()
    local install_path = VF.stdpath('data') ..
    '/site/pack/packer/start/packer.nvim'
    if VF.empty(VF.glob(install_path)) > 0 then
        VF.system({
            'git', 'clone', '--depth', '1',
            'https://github.com/wbthomason/packer.nvim', install_path
        })
        VC [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function(use)

    use 'wbthomason/packer.nvim'               -- Package manager

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            {'neovim/nvim-lspconfig'},
            {'williamboman/mason-lspconfig.nvim'},
            {'williamboman/mason.nvim'},
            {'hrsh7th/cmp-buffer'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'hrsh7th/cmp-nvim-lua'},
            {'hrsh7th/cmp-path'},
            {'hrsh7th/nvim-cmp'},
            {'L3MON4D3/LuaSnip'},  -- Only to stop cmp's bitching
            {'quangnguyen30192/cmp-nvim-ultisnips'},
            {'dmitmel/cmp-digraphs'},
            {'amarakon/nvim-cmp-lua-latex-symbols'},
        },
        config = function()
            local lsp = require('lsp-zero').preset({
                name                = 'recommended',
                set_lsp_keymaps     = false,
                manage_nvim_cmp     = true,
                suggest_lsp_servers = true,
            })
            local cmp = require('cmp')
            lsp.on_attach(function(client, bufnr)
                local o = {buffer = bufnr}
                VK('n', '<localleader>lD', 'lua VL.buf.declaration()<cr>', o)
                VK('n', '<localleader>lH', 'lua VL.buf.signature_help()<cr>', o)
                VK('n', '<localleader>lR', 'lua VL.buf.rename()<cr>', o)
                VK('n', '<localleader>la', 'lua VL.buf.code_action()<cr>', o)
                VK('n', '<localleader>ld', 'lua VL.buf.definition()<cr>', o)
                VK('n', '<localleader>lh', 'lua VL.buf.hover()<cr>', o)
                VK('n', '<localleader>li', 'lua VL.buf.implementation()<cr>', o)
                VK('n', '<localleader>lj', 'lua VL.buf.goto_prev()<cr>', o)
                VK('n', '<localleader>lk', 'lua VL.buf.goto_next()<cr>', o)
                VK('n', '<localleader>lo', 'lua VL.buf.open_float()<cr>', o)
                VK('n', '<localleader>lr', 'lua VL.buf.references()<cr>', o)
                VK('n', '<localleader>lt', 'lua VL.buf.type_definition()<cr>', o)
                VK('n', '<localleader>lf', '<cmd>LspZeroFormat<cr>', o)
                VK('n', '<localleader>lW', '<cmd>LspZeroWorkspaceRemove<cr>', o)
                VK('n', '<localleader>lw', '<cmd>LspZeroWorkspaceAdd<cr>', o)
                VK('n', '<localleader>ll', '<cmd>LspZeroWorkspaceList<cr>', o)
            end)
            lsp.ensure_installed({
                'pyright',
            })
            require('cmp_nvim_ultisnips').setup({})
            lsp.setup_nvim_cmp({
                sources = {
                    {name = 'buffer'},
                    {name = 'cmdline'},
                    {name = 'digraphs'},
                    {name = 'nvim_lsp'},
                    {name = 'nvim_lua'},
                    {name = 'path'},
                    {name = 'ultisnips'},
                    {
                        name     = 'lua-latex-symbols',
                        option   = {cache = true},
                        filetype = {'tex', 'plaintex', 'markdown'},
                    },
                },
                snippet = {
                    expand = function(args)
                        VF['UltiSnips#Anon'](args.body)
                    end,
                },
                view = {
                    entries = {
                        name            = 'custom',
                        selection_order = 'near_cursor',
                    }
                },
                mapping = cmp.mapping.preset.insert({
                    ['<c-e>']   = vim.NIL,
                    ['<C-t>']   = cmp.mapping.complete(),
                    ['<cr>']    = cmp.mapping.confirm({select = true}),
                    ['<C-a>']   = cmp.mapping.close(),
                    ['<C-e>']   = cmp.mapping.abort(),
                    ['<tab>']   = cmp.mapping.select_next_item(),
                    ['<S-tab>'] = cmp.mapping.select_prev_item(),
                    ['<C-n>']   = cmp.mapping.scroll_docs(3),
                    ['<C-p>']   = cmp.mapping.scroll_docs(-3),
                }),
            })
            lsp.setup()
            local signs = {
                Error = ' ',
                Warn  = ' ',
                Hint  = ' ',
                Info  = ' ',
            }
            for type, icon in pairs(signs) do
                local hl = 'DiagnosticSign' .. type
                VF.sign_define(hl, {text = icon, texthl = hl, numhl = hl})
            end
            vim.diagnostic.config({
                virtual_text     = false,
                virtual_lines    = false,
                signs            = true,
                update_in_insert = false,
                underline        = false,
                severity_sort    = true,
                float = {
                    focusable = false,
                    style     = 'minimal',
                    border    = 'rounded',
                    source    = 'always',
                    header    = '',
                    prefix    = '',
                },
            })
        end,
    }
    use {
        'jose-elias-alvarez/null-ls.nvim',
        config = function()
            local nls = require('null-ls')
            local fmt = nls.builtins.formatting
            local lint = nls.builtins.diagnostics
            local act = nls.builtins.code_actions
            nls.setup({
                sources = {
                    fmt.black,
                    fmt.reorder_python_imports,
                    lint.flake8,
                    lint.markdownlint,
                    lint.pydocstyle,
                }
            })
        end,
    }
    use({
        'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
        config = function()
            require('lsp_lines').setup()
            VK('n', '<leader>vt', require('lsp_lines').toggle)
        end,
    })

    use { -- Fuzzy finder
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        requires = {{'nvim-lua/plenary.nvim'}},
        config = function()
            local actions = require('telescope.actions')
            local qfix = actions.smart_send_to_qflist + actions.open_qflist
            require('telescope').setup({
                defaults = {
                    mappings = {
                        i = {
                            ["<C-/>"]      = actions.which_key,
                            ["<C-_>"]      = actions.which_key,
                            ["<C-e>"]      = actions.select_default,
                            ["<C-h>"]      = actions.preview_scrolling_down,
                            ["<C-j>"]      = actions.nop,
                            ["<C-l>"]      = actions.preview_scrolling_up,
                            ["<C-m>"]      = actions.toggle_selection,
                            ["<C-n>"]      = actions.results_scrolling_down,
                            ["<C-p>"]      = actions.results_scrolling_up,
                            ["<C-q>"]      = qfix,
                            ["<C-s>"]      = actions.select_horizontal,
                            ["<C-t>"]      = actions.select_tab,
                            ["<C-v>"]      = actions.select_vertical,
                            ["<C-w>"]      = actions.nop,
                            ["<C-x>"]      = actions.nop,
                            ["<Down>"]     = actions.nop,
                            ["<Esc>"]      = actions.close,
                            ["<M-q>"]      = actions.nop,
                            ["<PageDown>"] = actions.nop,
                            ["<PageUp>"]   = actions.nop,
                            ["<S-Tab>"]    = actions.move_selection_next,
                            ["<Tab>"]      = actions.move_selection_previous,
                            ["<Up>"]       = actions.nop,
                            ["<cr>"]       = actions.select_default,
                        },
                    },
                    layout_config = {
                        prompt_position = 'top',
                        preview_cutoff  = 120,
                        width           = 0.9,
                        height          = 0.4,
                        horizontal      = {mirror = false,},
                        vertical        = {mirror = false,},
                    },
                    extensions = {
                        fzf = {
                            fuzzy                   = false,
                            override_generic_sorter = false,
                            override_file_sorter    = true,
                            case_mode               = 'smart_case',
                        },
                    },
                },
            })
            require('telescope').load_extension('fzf')
            require('telescope').load_extension('ultisnips')
            VK('n', '<leader>ff'    , '<cmd>Telescope git_files<cr>')
            VK('n', '<leader>fd'    , '<cmd>Telescope find_files<cr>')
            VK('n', '<leader>fG'    , '<cmd>Telescope live_grep<cr>')
            VK('n', '<leader>fb'    , '<cmd>Telescope buffers<cr>')
            VK('n', '<leader>fh'    , '<cmd>Telescope help_tags<cr>')
            VK('n', '<leader>fR'    , '<cmd>Telescope oldfiles<cr>')
            VK('n', '<leader>fc'    , '<cmd>Telescope commands<cr>')
            VK('n', '<leader>ft'    , '<cmd>Telescope tags<cr>')
            VK('n', '<leader>f:'    , '<cmd>Telescope command_history<cr>')
            VK('n', '<leader>f/'    , '<cmd>Telescope search_history<cr>')
            VK('n', '<leader>f`'    , '<cmd>Telescope marks<cr>')
            VK('n', '<leader>fq'    , '<cmd>Telescope quickfix<cr>')
            VK('n', '<leader>fQ'    , '<cmd>Telescope quickfixhistory<cr>')
            VK('n', '<leader>fl'    , '<cmd>Telescope loclist<cr>')
            VK('n', '<leader>fj'    , '<cmd>Telescope jumplist<cr>')
            VK('n', '<leader>fo'    , '<cmd>Telescope vim_options<cr>')
            VK('n', '<leader>f@'    , '<cmd>Telescope registers<cr>')
            VK('n', '<leader>f?'    , '<cmd>Telescope keymaps<cr>')
            VK('n', '<leader>fH'    , '<cmd>Telescope highlights<cr>')
            VK('n', '<leader>fr'    , '<cmd>Telescope resume<cr>')
            VK('n', '<leader>fF'    , '<cmd>Telescope pickers<cr>')
            VK('n', '<leader>fF'    , '<cmd>Telescope pickers<cr>')
            VK('n', '<leader>fs'    , '<cmd>Telescope ultisnips<cr>')
            VK('n', '<localleader>D', '<cmd>Telescope diagnostics<cr>')
            VK('n', '<localleader>r', '<cmd>Telescope lsp_references<cr>')
            VK('n', '<localleader>d', '<cmd>Telescope lsp_definitions<cr>')
            VK('n', '<localleader>I', '<cmd>Telescope lsp_incoming_calls<cr>')
            VK('n', '<localleader>O', '<cmd>Telescope lsp_outgoing_calls<cr>')
            VK('n', '<localleader>m', '<cmd>Telescope lsp_implementations<cr>')
            VK('n', '<localleader>t', '<cmd>Telescope lsp_type_definitions<cr>')
            VK('n', '<localleader>S', '<cmd>Telescope lsp_document_symbols<cr>')
            VK('n', '<localleader>w', '<cmd>Telescope lsp_workspace_symbols<cr>')
        end,
    }
    use {
        'nvim-telescope/telescope-fzf-native.nvim',
        run = 'make'
    }
    use 'fhill2/telescope-ultisnips.nvim'

    use { -- Treesitter text objects
        'nvim-treesitter/nvim-treesitter-textobjects',
        after = 'nvim-treesitter',
        requires = 'nvim-treesitter/nvim-treesitter',
    }
    use { -- Treesitter
        'nvim-treesitter/nvim-treesitter',
        run = function()
            local ts_update = require('nvim-treesitter.install')
            .update({with_sync = true})
            ts_update()
        end,
        config = function()
            VA.nvim_create_autocmd(
                {'BufEnter','BufAdd','BufNew','BufNewFile','BufWinEnter'},
                {
                    group = VA.nvim_create_augroup('TS_FOLD_WORKAROUND', {}),
                    callback = function()
                        VO.foldmethod = 'expr'
                        VO.foldexpr   = 'nvim_treesitter#foldexpr()'
                    end
                }
            )
            require('nvim-treesitter.configs').setup({
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
                        init_selection    = '<cr>',
                        node_incremental  = '<cr>',
                        node_decremental  = '<bs>',
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
            })
        end,
    }

    use { -- Slime
        'hkupty/iron.nvim',
        config = function()
            local icore = require('iron.core')
            local iview = require('iron.view')
            icore.setup({
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
                    send_motion    = '<localleader>is',
                    visual_send    = '<localleader>is',
                    send_line      = '<localleader>il',
                    send_file      = '<localleader>if',
                    clear          = '<localleader>iL',
                    interrupt      = '<localleader>ic',
                    exit           = '<localleader>iq',
                },
            })
            VK('n', '<localleader>io', '<cmd>IronRepl<cr>')
            VK('n', '<localleader>iF', '<cmd>IronFocus<cr>')
            VK('n', '<localleader>iH', '<cmd>IronHide<cr>')
        end,
    }

    use { -- Search in git tree
        'mileszs/ack.vim',
        config = function()
            VG.ackprg = 'rg --vimgrep --no-heading --smart-case'
            VC [[
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
            VK('n', '<leader>fg', '<cmd>AckCword<cr>')
        end,
    }

    use { -- Markdown preview
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function()
            VG.mkdp_filetypes = {"markdown"}
        end,
        ft = {"markdown"},
        config = function()
            VG.mkdp_auto_start         = 0
            VG.mkdp_auto_close         = 0
            VG.mkdp_refresh_slow       = 1
            VG.mkdp_command_for_global = 0
            VG.mkdp_open_to_the_world  = 0
            VG.mkdp_page_title         = '「${name}」'
            VG.mkdp_filetypes          = {'markdown'}
        end
    }

    use { -- Show newlines
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            VO.list = true
            VO.listchars:append('lead:·')
            VO.listchars:append('trail:⋅')
            VO.listchars:append('nbsp:␣')
            VO.listchars:append('eol:↴')
            VO.listchars:append('tab:▸ ')
            require('indent_blankline').setup({
                space_char_blankline            = ' ',
                show_end_of_line                = true,
                show_current_context            = true,
                show_current_context_start      = true,
            })
        end
    }

    use { -- AI
        'github/copilot.vim',
        config = function()
            VG.copilot_enabled = 1
            VG.copilot_no_tab_map = 1
            VK('n', '<leader>cs', '<cmd>Copilot<cr>')
            VK('i', '<C-s>', '<Plug>(copilot-suggest)')
            VK('i', '<C-d>', '<Plug>(copilot-dismiss)')
            VK('i', '<C-j>', '<Plug>(copilot-next)')
            VK('i', '<C-k>', '<Plug>(copilot-previous)')
            VK('i', '<S-Tab>', 'copilot#Accept("")', {
                expr = true, replace_keycodes = false,
            })
        end,
    }

    use { -- Snippets engine
        'SirVer/UltiSnips',
        config = function()
            VG.UltiSnipsExpandTrigger            = '<c-e>'
            VG.UltiSnipsListSnippets             = '<c-l>'
            VG.UltiSnipsJumpForwardTrigger       = '<c-k>'
            VG.UltiSnipsJumpBackwardTrigger      = '<c-j>'
            VG.UltiSnipsRemoveSelectModeMappings = 0
            VG.UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit =
            '~/.vim/mysnippets'
            VG.UltiSnipsSnippetDirectories  = {
                'mysnippets', 'UltiSnips'
            }
        end
    }
    use 'honza/vim-snippets'

    use { -- Commenting
        'scrooloose/nerdcommenter',
        config = function()
            VG.NERDCreateDefaultMappings = 0
            VG.NERDRemoveExtraSpaces     = 1
            VG.NERDSpaceDelims           = 1
            VG.NERDToggleCheckAllLines   = 1
            VK({'n', 'v'}, '<leader>c ', '<Plug>NERDCommenterToggle')
            VK('n', '<leader>cA', '<Plug>NERDCommenterAppend<cr>')
        end,
    }

    use { -- Pretty icons everywhere
        'nvim-tree/nvim-web-devicons',
        config = function()
            require('nvim-web-devicons').setup({
                default                          = true,
                color_icons                      = true,
            })
        end
    }

    use { -- Status line
        'nvim-lualine/lualine.nvim',
        config = function()
            require('lualine').setup({
                options = {
                    theme = 'tokyonight',
                }
            })
        end
    }

    use { -- Show git signs
        'airblade/vim-gitgutter',
        config = function()
            VG.gitgutter_map_keys = 0
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

    use 'mg979/vim-visual-multi'               -- Multiple cursors

    use 'akhilsbehl/md-image-paste'            -- Paste images in md files

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

end)

VC [=[

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
set mouse-=a mousefocus
set textwidth=79 colorcolumn=+1 laststatus=2 signcolumn=yes
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
nnoremap tr :e<CR>
nnoremap tR <C-w>r<CR>
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
  autocmd FileType markdown nnoremap <buffer> <localleader>p
        \ <Plug>MarkdownPreviewToggle
  autocmd FileType markdown vnoremap <buffer> <localleader>i
        \ :call DecorateSelection('*')<CR>
  autocmd FileType markdown vnoremap <buffer> <localleader>b
        \ :call DecorateSelection('**')<CR>
  autocmd FileType markdown vnoremap <buffer> <localleader>d
        \ :call DecorateSelection('$')<CR>
augroup END

]=]


-- TODOs:
-- 1. Debug Adaptor Protocol
--     1.1. rcarriga/nvim-dap-ui
--     1.2. mfussenegger/nvim-dap
--     1.3. mfussenegger/nvim-dap-python
-- 2. Literate programming:
--     2.1. zyedidia/Literate
--     2.2. zyedidia/literate.vim
