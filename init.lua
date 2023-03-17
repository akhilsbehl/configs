VA = vim.api
VC = vim.cmd
VD = vim.diagnostic
VF = vim.fn
VG = vim.g
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
    use 'wbthomason/packer.nvim' -- Package manager

    use {                        -- LSP & CMP
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason-lspconfig.nvim' },
            { 'williamboman/mason.nvim' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },
            { 'hrsh7th/cmp-path' },
            { 'hrsh7th/nvim-cmp' },
            { 'L3MON4D3/LuaSnip' }, -- Only to stop cmp's bitching
            { 'quangnguyen30192/cmp-nvim-ultisnips' },
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
                local o = { buffer = bufnr }
                VK('n', '<leader>lD', '<cmd>lua vim.lsp.buf.declaration()<cr>', o)
                VK('n', '<leader>lH', '<cmd>lua vim.lsp.buf.signature_help()<cr>', o)
                VK('n', '<leader>lR', '<cmd>lua vim.lsp.buf.rename()<cr>', o)
                VK('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<cr>', o)
                VK('n', '<leader>ld', '<cmd>lua vim.lsp.buf.definition()<cr>', o)
                VK('n', '<leader>lh', '<cmd>lua vim.lsp.buf.hover()<cr>', o)
                VK('n', '<leader>li', '<cmd>lua vim.lsp.buf.implementation()<cr>', o)
                VK('n', '<leader>lr', '<cmd>lua vim.lsp.buf.references()<cr>', o)
                VK('n', '<leader>lt', '<cmd>lua vim.lsp.buf.type_definition()<cr>', o)
                VK('n', '<leader>lk', '<cmd>lua vim.diagnostic.goto_prev()<cr>', o)
                VK('n', '<leader>lj', '<cmd>lua vim.diagnostic.goto_next()<cr>', o)
                VK('n', '<leader>lo', '<cmd>lua vim.diagnostic.open_float()<cr>', o)
                VK('n', '<leader>lf', '<cmd>LspZeroFormat<cr>', o)
                VK('n', '<leader>lW', '<cmd>LspZeroWorkspaceRemove<cr>', o)
                VK('n', '<leader>lw', '<cmd>LspZeroWorkspaceAdd<cr>', o)
                VK('n', '<leader>ll', '<cmd>LspZeroWorkspaceList<cr>', o)
            end)
            lsp.ensure_installed({
                'pyright',
            })
            require('cmp_nvim_ultisnips').setup({})
            lsp.setup_nvim_cmp({
                sources = {
                    { name = 'buffer' },
                    { name = 'nvim_lsp' },
                    { name = 'nvim_lua' },
                    { name = 'path' },
                },
                view = {
                    entries = {
                        name            = 'custom',
                        selection_order = 'near_cursor',
                    }
                },
                mapping = cmp.mapping.preset.insert({
                        ['<c-e>'] = vim.NIL,
                        ['<C-t>'] = cmp.mapping.complete(),
                        ['<cr>'] = cmp.mapping.confirm({ select = true }),
                        ['<C-a>'] = cmp.mapping.close(),
                        ['<C-e>'] = cmp.mapping.abort(),
                        ['<tab>'] = cmp.mapping.select_next_item(),
                        ['<S-tab>'] = cmp.mapping.select_prev_item(),
                        ['<C-n>'] = cmp.mapping.scroll_docs(3),
                        ['<C-p>'] = cmp.mapping.scroll_docs(-3),
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
                VF.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
            end
            local diagnostic_config = {
                virtual_text     = false,
                signs            = false,
                update_in_insert = false,
                underline        = false,
                severity_sort    = true,
                float            = {
                    focusable = false,
                    style     = 'minimal',
                    border    = 'rounded',
                    source    = 'always',
                    header    = '',
                    prefix    = '',
                },
            }
            local switch_diagnostics = function(option, state)
                if option == 'signs' then
                    VG.myrc_diagnostics = state
                    diagnostic_config[option] = VG.myrc_diagnostics
                    if state == false then
                        diagnostic_config['virtual_text'] = false
                    else
                        diagnostic_config['virtual_text'] =
                            VG.myrc_diagnostics_vtext
                    end
                    VD.config(diagnostic_config)
                elseif option == 'virtual_text' then
                    VG.myrc_diagnostics_vtext = state
                    diagnostic_config[option] = VG.myrc_diagnostics_vtext
                    if VG.myrc_diagnostics then
                        VD.config(diagnostic_config)
                    end
                end
            end
            local toggle_diagnostics = function()
                switch_diagnostics('signs', not VG.myrc_diagnostics)
            end
            local toggle_diagnostics_vtext = function()
                switch_diagnostics('virtual_text',
                    not VG.myrc_diagnostics_vtext)
            end
            VG.myrc_diagnostics = false
            VG.myrc_diagnostics_vtext = true
            switch_diagnostics('signs', VG.myrc_diagnostics)
            VK('n', '<leader>vd', toggle_diagnostics)
            VK('n', '<leader>vv', toggle_diagnostics_vtext)
        end,
    }
    use {
        'jose-elias-alvarez/null-ls.nvim',
        config = function()
            local nls = require('null-ls')
            local fmt = nls.builtins.formatting
            local lint = nls.builtins.diagnostics
            -- local act = nls.builtins.code_actions
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

    use { -- Fuzzy finder
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } },
        config = function()
            local actions = require('telescope.actions')
            local qfix = actions.smart_send_to_qflist + actions.open_qflist
            require('telescope').setup({
                defaults = {
                    default_mappings = {
                        i = {
                                ["<C-/>"]  = actions.which_key,
                                ["<C-_>"]  = actions.which_key,
                                ["<C-e>"]  = actions.select_default,
                                ["<C-h>"]  = actions.preview_scrolling_down,
                                ["<C-j>"]  = actions.nop,
                                ["<C-l>"]  = actions.preview_scrolling_up,
                                ["<C-m>"]  = actions.toggle_selection,
                                ["<C-n>"]  = actions.results_scrolling_down,
                                ["<C-p>"]  = actions.results_scrolling_up,
                                ["<C-q>"]  = qfix,
                                ["<C-s>"]  = actions.select_horizontal,
                                ["<C-t>"]  = actions.select_tab,
                                ["<C-v>"]  = actions.select_vertical,
                                ["<C-w>"]  = actions.nop,
                                ["<C-x>"]  = actions.nop,
                                ["<Down>"] = actions.nop,
                                ["<Esc>"]  = actions.close,
                                ["<M-q>"]  = actions.nop,
                                ["<PageDown>"] = actions.nop,
                                ["<PageUp>"] = actions.nop,
                                ["<S-Tab>"] = actions.move_selection_next,
                                ["<Tab>"]  = actions.move_selection_previous,
                                ["<Up>"]   = actions.nop,
                                ["<cr>"]   = actions.select_default, -- buggy
                        },
                    },
                    layout_config = {
                        prompt_position = 'top',
                        preview_cutoff  = 120,
                        width           = 0.9,
                        height          = 0.4,
                        horizontal      = { mirror = false, },
                        vertical        = { mirror = false, },
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
            VK('n', '<leader>ff', '<cmd>Telescope git_files<cr>')
            VK('n', '<leader>fd', '<cmd>Telescope find_files<cr>')
            VK('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
            VK('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')
            VK('n', '<leader>fR', '<cmd>Telescope oldfiles<cr>')
            VK('n', '<leader>fc', '<cmd>Telescope commands<cr>')
            VK('n', '<leader>fC', '<cmd>Telescope colorscheme<cr>')
            VK('n', '<leader>ft', '<cmd>Telescope tags<cr>')
            VK('n', '<leader>f:', '<cmd>Telescope command_history<cr>')
            VK('n', '<leader>f/', '<cmd>Telescope search_history<cr>')
            VK('n', '<leader>f`', '<cmd>Telescope marks<cr>')
            VK('n', '<leader>fq', '<cmd>Telescope quickfix<cr>')
            VK('n', '<leader>fQ', '<cmd>Telescope quickfixhistory<cr>')
            VK('n', '<leader>fl', '<cmd>Telescope loclist<cr>')
            VK('n', '<leader>fj', '<cmd>Telescope jumplist<cr>')
            VK('n', '<leader>fo', '<cmd>Telescope vim_options<cr>')
            VK('n', '<leader>f@', '<cmd>Telescope registers<cr>')
            VK('n', '<leader>f?', '<cmd>Telescope keymaps<cr>')
            VK('n', '<leader>fH', '<cmd>Telescope highlights<cr>')
            VK('n', '<leader>fr', '<cmd>Telescope resume<cr>')
            VK('n', '<leader>fF', '<cmd>Telescope pickers<cr>')
            VK('n', '<leader>fF', '<cmd>Telescope pickers<cr>')
            VK('n', '<leader>fs', '<cmd>Telescope ultisnips<cr>')
            VK('n', '<localleader>tD', '<cmd>Telescope diagnostics<cr>')
            VK('n', '<localleader>tr', '<cmd>Telescope lsp_references<cr>')
            VK('n', '<localleader>td', '<cmd>Telescope lsp_definitions<cr>')
            VK('n', '<localleader>tI', '<cmd>Telescope lsp_incoming_calls<cr>')
            VK('n', '<localleader>tO', '<cmd>Telescope lsp_outgoing_calls<cr>')
            VK('n', '<localleader>tm', '<cmd>Telescope lsp_implementations<cr>')
            VK('n', '<localleader>tt', '<cmd>Telescope lsp_type_definitions<cr>')
            VK('n', '<localleader>tS', '<cmd>Telescope lsp_document_symbols<cr>')
            VK('n', '<localleader>tw', '<cmd>Telescope lsp_workspace_symbols<cr>')
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
                .update({ with_sync = true })
            ts_update()
        end,
        config = function()
            VA.nvim_create_autocmd(
                { 'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile', 'BufWinEnter' },
                {
                    group = VA.nvim_create_augroup('TS_FOLD_WORKAROUND', {}),
                    callback = function()
                        VO.foldmethod = 'expr'
                        VO.foldexpr   = 'nvim_treesitter#foldexpr()'
                    end
                }
            )
            require('nvim-treesitter.configs').setup({
                ensure_installed = { 'python', 'bash', 'r', 'lua' },
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

    use { -- Hoppity hop
        'phaazon/hop.nvim',
        branch = 'v2',
        config = function()
            local hop = require('hop')
            local direcn = require('hop.hint').HintDirection
            local _f = function()
                hop.hint_char1({
                    direction = direcn.AFTER_CURSOR,
                    current_line_only = true,
                })
            end
            local _F = function()
                hop.hint_char1({
                    direction = direcn.BEFORE_CURSOR,
                    current_line_only = true,
                })
            end
            local _t = function()
                hop.hint_char1({
                    direction = direcn.AFTER_CURSOR,
                    current_line_only = true,
                    hint_offset = -1,
                })
            end
            local _T = function()
                hop.hint_char1({
                    direction = direcn.BEFORE_CURSOR,
                    current_line_only = true,
                    hint_offset = 1,
                })
            end
            require('hop').setup({
                keys = 'etovxqpdygfblzhckisuran',
                quit_key = '<Esc>',
                jump_on_sole_occurrence = true,
                case_insesitive = false,
                multi_windows = true,
            })
            VK({ 'n', 'o', 'v' }, 'b', '<cmd>HopChar2<CR>')
            VK({ 'n', 'o', 'v' }, 'f', _f)
            VK({ 'n', 'o', 'v' }, 'F', _F)
            VK({ 'n', 'o', 'v' }, 't', _t)
            VK({ 'n', 'o', 'v' }, 'T', _T)
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
                        sh     = { 'zsh' },
                        python = { 'python', '-m', 'IPython' },
                        r      = { 'R', '--no-save' },
                        julia  = { 'julia', '--color  = yes' },
                    },
                    repl_open_cmd = iview.split.bot('40%')
                },
                ignore_blank_lines = true,
                keymaps = {
                    send_motion = '<localleader>s',
                    visual_send = '<localleader>s',
                    send_line   = '<localleader>S',
                    send_file   = '<localleader>f',
                    clear       = '<localleader>L',
                    interrupt   = '<localleader>c',
                    exit        = '<localleader>iq',
                },
            })
            VK('n', '<localleader>ir', '<cmd>IronRepl<cr>')
            VK('n', '<localleader>io', '<cmd>IronFocus<cr>')
            VK('n', '<localleader>ih', '<cmd>IronHide<cr>')
            VK('t', 'ty', require('nvim-window').pick)
            VC [[
                augroup IronTerm
                    autocmd!
                    autocmd BufNew,BufEnter term://* startinsert!
                    autocmd BufLeave term://* stopinsert!
                augroup END
            ]]
        end,
    }

    use { -- Search in git tree
        'mileszs/ack.vim',
        config = function()
            VG.ackprg = 'rg --vimgrep --no-heading --smart-case'
            VC [[
                function! FindGitRoot() abort
                    return system(
                                \ 'git rev-parse
                                \ --show-toplevel
                                \ 2> /dev/null')[:-2]
                endfunction
                command! -nargs=0 AckCword
                            \ execute 'Ack! ' .
                            \ expand('<cword>') . ' ' . FindGitRoot()
                command! -nargs=1 AckInput
                            \ execute 'Ack! <args> ' . FindGitRoot()
                ]]
            VK('n', '<leader>fg', '<cmd>AckCword<cr>')
            VK('n', '<leader>fG', ':AckInput ')
        end,
    }

    use { -- Markdown preview
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function()
            VG.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
        config = function()
            VG.mkdp_auto_start         = 0
            VG.mkdp_auto_close         = 0
            VG.mkdp_refresh_slow       = 1
            VG.mkdp_command_for_global = 0
            VG.mkdp_open_to_the_world  = 0
            VG.mkdp_page_title         = '「${name}」'
            VG.mkdp_filetypes          = { 'markdown' }
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
            VK('i', '<C-a>', 'copilot#Accept("")', {
                expr = true, replace_keycodes = false,
            })
        end,
    }

    use { -- Snippets engine
        'SirVer/UltiSnips',
        config = function()
            VG.UltiSnipsExpandTrigger                           = '<c-e>'
            VG.UltiSnipsListSnippets                            = '<c-l>'
            VG.UltiSnipsJumpForwardTrigger                      = '<c-k>'
            VG.UltiSnipsJumpBackwardTrigger                     = '<c-j>'
            VG.UltiSnipsRemoveSelectModeMappings                = 0
            VG.UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit =
            '~/.vim/mysnippets'
            VG.UltiSnipsSnippetDirectories                      = {
                'mysnippets', 'UltiSnips'
            }
        end
    }
    use 'honza/vim-snippets'

    use { -- Traverse windows easier
        'https://gitlab.com/yorickpeterse/nvim-window.git',
        config = function()
            require('nvim-window').setup({
                chars = {
                    'e', 't', 'o', 'v', 'x', 'q', 'p', 'd', 'y', 'g', 'f',
                    'b', 'l', 'z', 'h', 'c', 'k', 'i', 's', 'u', 'r', 'a',
                },
                normal_hl = 'PmenuSel',
                hint_hl = 'Bold',
                border = 'double',
            })
            VK('n', 'ty', require('nvim-window').pick)
        end
    }

    use { -- Show newlines
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            VO.list = true
            VO.listchars:append('trail:▸')
            require('indent_blankline').setup({
                space_char_blankline       = ' ',
                show_current_context       = true,
                show_current_context_start = true,
            })
        end
    }

    use { -- Commenting
        'scrooloose/nerdcommenter',
        config = function()
            VG.NERDCreateDefaultMappings = 0
            VG.NERDRemoveExtraSpaces     = 1
            VG.NERDSpaceDelims           = 1
            VG.NERDToggleCheckAllLines   = 1
            VK({ 'n', 'v' }, '<leader>c ', '<Plug>NERDCommenterToggle')
            VK('n', '<leader>cA', '<Plug>NERDCommenterAppend<cr>')
        end,
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

    use { -- Undo history
        'jiaoshijie/undotree',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('undotree').setup({
                window = { winblend = 0 }
            })
            VK('n', '<localleader>u', require('undotree').open)
        end
    }

    use { -- Pretty icons everywhere
        'nvim-tree/nvim-web-devicons',
        config = function()
            require('nvim-web-devicons').setup({
                default     = true,
                color_icons = true,
            })
        end
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

    use { -- Dim inactive windows
        'blueyed/vim-diminactive',
        config = function()
            VG.diminactive_buftype_whitelist = { 'terminal' }
        end
    }

    use 'mg979/vim-visual-multi'      -- Multiple cursors

    use 'akhilsbehl/md-image-paste'   -- Paste images in md files

    use 'tpope/vim-surround'          -- Use surround movements

    use 'tpope/vim-repeat'            -- Repeat commands

    use 'godlygeek/tabular'           -- Align rows

    use 'powerman/vim-plugin-AnsiEsc' -- Escape shell color codes

    use 'folke/tokyonight.nvim'       -- Theme: tokyonight

    if packer_bootstrap then
        require('packer').sync()
    end
end)

VC [[ source ~/.config/nvim/vimrc ]]

-- TODOs:
-- 1. Debug Adaptor Protocol
--     1.1. rcarriga/nvim-dap-ui
--     1.2. mfussenegger/nvim-dap
--     1.3. mfussenegger/nvim-dap-python
-- 2. Literate programming?
--     2.1. zyedidia/Literate
--     2.2. zyedidia/literate.vim
