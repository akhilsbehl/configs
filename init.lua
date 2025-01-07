VA = vim.api
VC = vim.cmd
VD = vim.diagnostic
VF = vim.fn
VG = vim.g
VK = vim.keymap.set
VO = vim.opt

VG.mapleader = ','
VG.maplocalleader = ' '

-- Even though we have perl, nvim can't find it
-- VG.perl_host_prog = '/usr/bin/perl'
VG.loaded_perl_provider = 0

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

if not VG.vscode then -- Ignore this stuff if I'm running from inside VSCode
    require('lazy').setup(
        {

            {
                -- LSP & CMP
                'VonHeikemen/lsp-zero.nvim',
                branch = 'v4.x',
                dependencies = {
                    { 'neovim/nvim-lspconfig' },
                    { 'williamboman/mason.nvim' },
                    { 'williamboman/mason-lspconfig.nvim' },
                    { 'hrsh7th/nvim-cmp' },
                    { 'hrsh7th/cmp-buffer' },
                    { 'hrsh7th/cmp-nvim-lsp' },
                    { 'hrsh7th/cmp-nvim-lua' },
                    { 'hrsh7th/cmp-path' },
                },
                config = function()
                    local lsp = require('lsp-zero')
                    local lsp_attach = function(client, bufnr)
                        local o = { buffer = bufnr }
                        VK('n', '<leader>lD',
                            '<cmd>lua vim.lsp.buf.declaration()<cr>', o)
                        VK('n', '<leader>lH',
                            '<cmd>lua vim.lsp.buf.signature_help()<cr>', o)
                        VK('n', '<leader>lR',
                            '<cmd>lua vim.lsp.buf.rename()<cr>', o)
                        VK('n', '<leader>la',
                            '<cmd>lua vim.lsp.buf.code_action()<cr>', o)
                        VK('n', '<leader>ld',
                            '<cmd>lua vim.lsp.buf.definition()<cr>', o)
                        VK('n', '<leader>lh',
                            '<cmd>lua vim.lsp.buf.hover()<cr>', o)
                        VK('n', '<leader>li',
                            '<cmd>lua vim.lsp.buf.implementation()<cr>', o)
                        VK('n', '<leader>lr',
                            '<cmd>lua vim.lsp.buf.references()<cr>', o)
                        VK('n', '<leader>lt',
                            '<cmd>lua vim.lsp.buf.type_definition()<cr>', o)
                        VK('n', '<leader>lk',
                            '<cmd>lua vim.diagnostic.goto_prev()<cr>', o)
                        VK('n', '<leader>lj',
                            '<cmd>lua vim.diagnostic.goto_next()<cr>', o)
                        VK('n', '<leader>lo',
                            '<cmd>lua vim.diagnostic.open_float()<cr>', o)
                        VK('n', '<leader>lf', '<cmd>LspZeroFormat<cr>', o)
                        VK('n', '<leader>lW', '<cmd>LspZeroWorkspaceRemove<cr>', o)
                        VK('n', '<leader>lw', '<cmd>LspZeroWorkspaceAdd<cr>', o)
                        VK('n', '<leader>ll', '<cmd>LspZeroWorkspaceList<cr>', o)
                    end
                    lsp.extend_lspconfig({
                        capabilities = require(
                            'cmp_nvim_lsp'
                        ).default_capabilities(),
                        lsp_attach = lsp_attach,
                        float_border = 'rounded',
                        sign_text = true,
                    })
                    require('mason').setup({})
                    require('mason-lspconfig').setup({
                        ensure_installed = {
                            'pyright',
                        },
                        handlers = {
                            function(server_name)
                                require('lspconfig')[server_name].setup({})
                            end,
                        }
                    })
                    local cmp = require('cmp')
                    local cmp_format = require('lsp-zero').cmp_format()
                    cmp.setup({
                        formatting = cmp_format,
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
                            ['<C-c>'] = cmp.mapping.close(),
                            ['<C-c>'] = cmp.mapping.abort(),
                            ['<tab>'] = cmp.mapping.select_next_item(),
                            ['<S-tab>'] = cmp.mapping.select_prev_item(),
                            ['<C-n>'] = cmp.mapping.scroll_docs(3),
                            ['<C-p>'] = cmp.mapping.scroll_docs(-3),
                        }),
                    })
                    local signs = {
                        Error = '✘', -- Bold "X" for errors
                        Warn  = '⚐', -- Flag symbol for warnings
                        Hint  = '➔', -- Arrow for hints
                        Info  = '', -- Info symbol as an information icon
                    }
                    for type, icon in pairs(signs) do
                        local hl = 'DiagnosticSign' .. type
                        VF.sign_define(hl, {
                            text = icon,
                            texthl = hl,
                            numhl = hl,
                        })
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
                    lsp.setup()
                end,
            },

            {
                -- Fuzzy finder
                'nvim-telescope/telescope.nvim',
                branch = '0.1.x',
                dependencies = { 'nvim-lua/plenary.nvim' },
                config = function()
                    local ac = require('telescope.actions')
                    local qfix = ac.smart_send_to_qflist + ac.open_qflist
                    require('telescope').setup({
                        defaults = {
                            default_mappings = {
                                i = {
                                    ["<C-/>"]      = ac.which_key,
                                    ["<C-_>"]      = ac.nop,
                                    ["<cr>"]       = ac.select_default, -- buggy
                                    ["<C-e>"]      = ac.select_default,
                                    ["<C-k>"]      = ac.move_selection_previous,
                                    ["<C-j>"]      = ac.move_selection_next,
                                    ["<Tab>"]      = ac.move_selection_previous,
                                    ["<S-Tab>"]    = ac.move_selection_next,
                                    ["<Up>"]       = ac.move_selection_previous,
                                    ["<Down>"]     = ac.move_selection_next,
                                    ["<C-h>"]      = ac.preview_scrolling_down,
                                    ["<C-l>"]      = ac.preview_scrolling_up,
                                    ["<C-m>"]      = ac.toggle_selection,
                                    ["<C-n>"]      = ac.results_scrolling_down,
                                    ["<C-p>"]      = ac.results_scrolling_up,
                                    ["<C-s>"]      = ac.select_horizontal,
                                    ["<C-t>"]      = ac.select_tab,
                                    ["<C-v>"]      = ac.select_vertical,
                                    ["<Esc>"]      = ac.close,
                                    ["<C-q>"]      = qfix,
                                    ["<C-w>"]      = ac.nop,
                                    ["<C-x>"]      = ac.nop,
                                    ["<M-q>"]      = ac.nop,
                                    ["<PageDown>"] = ac.nop,
                                    ["<PageUp>"]   = ac.nop,
                                },
                            },
                            layout_config = {
                                prompt_position = 'top',
                                preview_cutoff  = 32,
                                width           = 0.9,
                                height          = 0.9,
                                horizontal      = { mirror = false, },
                                vertical        = { mirror = false, },
                            },
                            extensions = {
                                fzf = {
                                    fuzzy                   = false,
                                    override_generic_sorter = true,
                                    override_file_sorter    = true,
                                    case_mode               = 'smart_case',
                                },
                            },
                        },
                    })
                    require('telescope').load_extension('fzf')
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
                    VK('n', '<leader>gc', '<cmd>Telescope git_commits<cr>')
                    VK('n', '<leader>gC', '<cmd>Telescope git_bcommits<cr>')
                    VK('n', '<leader>gv', '<cmd>Telescope git_bcommits_range<cr>')
                    VK('n', '<leader>gb', '<cmd>Telescope git_branches<cr>')
                    VK('n', '<leader>gs', '<cmd>Telescope git_status<cr>')
                    VK('n', '<leader>gS', '<cmd>Telescope git_stash<cr>')
                    VK('n', '<localleader>tD',
                        '<cmd>Telescope diagnostics<cr>')
                    VK('n', '<localleader>tr',
                        '<cmd>Telescope lsp_references<cr>')
                    VK('n', '<localleader>td',
                        '<cmd>Telescope lsp_definitions<cr>')
                    VK('n', '<localleader>tI',
                        '<cmd>Telescope lsp_incoming_calls<cr>')
                    VK('n', '<localleader>tO',
                        '<cmd>Telescope lsp_outgoing_calls<cr>')
                    VK('n', '<localleader>tm',
                        '<cmd>Telescope lsp_implementations<cr>')
                    VK('n', '<localleader>tt',
                        '<cmd>Telescope lsp_type_definitions<cr>')
                    VK('n', '<localleader>tS',
                        '<cmd>Telescope lsp_document_symbols<cr>')
                    VK('n', '<localleader>tw',
                        '<cmd>Telescope lsp_workspace_symbols<cr>')
                end,
            },
            {
                -- Telescope FZF
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make'
            },

            {
                -- Treesitter
                'nvim-treesitter/nvim-treesitter',
                build = function()
                    local ts_update = require('nvim-treesitter.install')
                        .update({ with_sync = true })
                    ts_update()
                end,
                dependencies = 'nvim-treesitter/nvim-treesitter-textobjects',
                config = function()
                    VA.nvim_create_autocmd(
                        {
                            'BufEnter', 'BufAdd', 'BufNew',
                            'BufNewFile', 'BufWinEnter',
                        },
                        {
                            group = VA.nvim_create_augroup(
                                'TS_FOLD_WORKAROUND', {}
                            ),
                            callback = function()
                                VO.foldmethod = 'expr'
                                VO.foldexpr   = 'nvim_treesitter#foldexpr()'
                            end
                        }
                    )
                    require('nvim-treesitter.configs').setup({
                        ensure_installed = {
                            'python',
                            'bash',
                            'r',
                            'lua',
                            'ocaml',
                            'javascript',
                            'typescript',
                            'commonlisp',
                        },
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
            },

            {
                -- Hoppity hop
                'smoka7/hop.nvim',
                version = '*',
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
            },

            { -- Search and replace
                "roobert/search-replace.nvim",
                config = function()
                    require("search-replace").setup({
                        default_replace_single_buffer_options = "gcI",
                        default_replace_multi_buffer_options = "egcI",
                    })
                    VK(
                        "v",
                        "<leader>rs",
                        "<CMD>SearchReplaceWithinVisualSelection<CR>",
                        {}
                    )
                    VK(
                        "v",
                        "<leader>ro",
                        "<CMD>SearchReplaceSingleBufferVisualSelection<CR>",
                        {}
                    )
                    VK(
                        "n",
                        "<leader>rs",
                        "<CMD>SearchReplaceSingleBufferOpen<CR>",
                        {}
                    )
                    VK(
                        "n",
                        "<leader>ro",
                        "<CMD>SearchReplaceSingleBufferSelections<CR>",
                        {}
                    )
                    VK(
                        "n",
                        "<leader>rO",
                        "<CMD>SearchReplaceMultiBufferSelections<CR>",
                        {}
                    )
                    VK(
                        "n",
                        "<leader>rS",
                        "<CMD>SearchReplaceMultiBufferOpen<CR>",
                        {}
                    )
                end,
            },

            {
                -- Zettelkasten
                'renerocksai/telekasten.nvim',
                config = function()
                    require('telekasten').setup({
                        home = VF.expand('~/zettelkasten'),
                    })
                    VK("n", "<leader>z", "<cmd>Telekasten panel<CR>")
                    VK("n", "<leader>z.", "<cmd>Telekasten toggle_todo<CR>")
                    VK("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
                    VK("n", "<leader>zc", "<cmd>Telekasten show_calendar<CR>")
                    VK("n", "<leader>zf", "<cmd>Telekasten find_notes<CR>")
                    VK("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>")
                    VK("n", "<leader>zh", "<cmd>Telekasten show_tags<CR>")
                    VK("n", "<leader>zi", "<cmd>Telekasten insert_img_link<CR>")
                    VK("n", "<leader>zl", "<cmd>Telekasten insert_link<CR>")
                    VK("n", "<leader>zL", "<cmd>Telekasten follow_link<CR>")
                    VK("n", "<leader>zn", "<cmd>Telekasten new_note<CR>")
                    VK("n", "<leader>zp", "<cmd>Telekasten preview_image<CR>")
                    VK("n", "<leader>zr", "<cmd>Telekasten rename_note<CR>")
                    VK("n", "<leader>zT", "<cmd>Telekasten goto_today<CR>")
                    VK("n", "<leader>zw", "<cmd>Telekasten goto_thisweek<CR>")
                    VK("n", "<leader>zy", "<cmd>Telekasten yank_notelink<CR>")
                    VK("n", "<leader>zt", "<cmd>Telekasten toggle_todo<CR>")
                end,
                dependencies = {
                    'nvim-telescope/telescope.nvim',
                    'renerocksai/calendar-vim',
                },
            },

            {
                -- REPLs
                'jalvesaq/vimcmdline',
                config = function()
                    VG.cmdline_app                = {
                        sh = 'zsh',
                        python = 'ipy',
                        julia = 'julia --color=yes',
                    }
                    VG.cmdline_vsplit             = 1
                    VG.cmdline_term_height        = 50
                    VG.cmdline_term_width         = 120
                    VG.cmdline_in_buffer          = 0
                    VG.cmdline_map_start          = '<LocalLeader>io'
                    VG.cmdline_map_send           = '<LocalLeader>il'
                    VG.cmdline_map_send_and_stay  = '<LocalLeader>is'
                    VG.cmdline_map_source_fun     = '<LocalLeader>if'
                    VG.cmdline_map_send_paragraph = '<LocalLeader>ip'
                    VG.cmdline_map_send_block     = '<LocalLeader>ib'
                    VG.cmdline_map_send_motion    = '<LocalLeader>im'
                    VG.cmdline_map_quit           = '<LocalLeader>iq'
                end,
            },
            {
                -- R REPL :/
                'jalvesaq/Nvim-R',
                config = function()
                    VG.R_args = { '--no-save', '--no-restore-data' }
                    VG.R_assign = 0
                    VG.R_source = '~/configs/nvim-r-tmux-split.vim'
                    VG.R_notmux_conf = 1
                    VG.R_rconsole_width = 120
                    VG.R_rconsole_height = 0
                    VG.R_user_maps_only = 1
                    VC [[
                function! s:CustomNvimRMappings()
                    nmap <buffer> <LocalLeader>io <Plug>RStart
                    nmap <buffer> <LocalLeader>il <Plug>RSendLine
                    vmap <buffer> <LocalLeader>is <Plug>RSendSelection
                    nmap <buffer> <LocalLeader>if <Plug>RSendFunction
                    nmap <buffer> <LocalLeader>ip <Plug>RSendParagraph
                    nmap <buffer> <LocalLeader>ib <Plug>RSendBlock
                    nmap <buffer> <LocalLeader>im <Plug>RSendMotion
                    nmap <buffer> <LocalLeader>iq <Plug>RClose
                endfunction
                augroup MyNvimR
                    autocmd!
                    autocmd FileType r call s:CustomNvimRMappings()
                augroup end
            ]]
                end,
            },

            {
                -- Commenting
                'scrooloose/nerdcommenter',
                config = function()
                    VG.NERDRemoveExtraSpaces   = 1
                    VG.NERDSpaceDelims         = 1
                    VG.NERDToggleCheckAllLines = 1
                    VK({ 'n', 'v' }, '<leader>c ', '<Plug>NERDCommenterToggle')
                    VK('n', '<leader>cA', '<Plug>NERDCommenterAppend<cr>')
                    VG.NERDCreateDefaultMappings = 0 -- Doesn't work >.<
                    VC [[
                    unmap <leader>c$
                    unmap <leader>ca
                    unmap <leader>cb
                    unmap <leader>cc
                    unmap <leader>ci
                    unmap <leader>cl
                    unmap <leader>cm
                    unmap <leader>cn
                    unmap <leader>cs
                    unmap <leader>cu
                    unmap <leader>cy
                ]]
                end,
            },

            {
                -- Search in git tree
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
            },

            {
                -- Markdown preview
                "iamcco/markdown-preview.nvim",
                cmd = {
                    "MarkdownPreviewToggle",
                    "MarkdownPreview",
                    "MarkdownPreviewStop",
                },
                build = "cd app && yarn install",
                ft = { "markdown" },
                init = function()
                    VG.mkdp_auto_start         = 0
                    VG.mkdp_auto_close         = 0
                    VG.mkdp_refresh_slow       = 1
                    VG.mkdp_command_for_global = 0
                    VG.mkdp_open_to_the_world  = 0
                    VG.mkdp_page_title         = '「${name}」'
                    VG.mkdp_filetypes          = { 'markdown' }
                end
            },

            {
                -- AI - Copilot
                'github/copilot.vim',
		tag = "v1.32.0",
                config = function()
                    VG.copilot_enabled = (VF.getenv("HAS_GH_COPILOT") == "1") and 1 or 0
                    VG.copilot_no_tab_map = 1
                    VK('i', '<C-s>', '<Plug>(copilot-suggest)')
                    VK('i', '<C-d>', '<Plug>(copilot-dismiss)')
                    VK('i', '<C-j>', '<Plug>(copilot-next)')
                    VK('i', '<C-k>', '<Plug>(copilot-previous)')
                    VK('i', '<C-w>', '<Plug>(copilot-accept-word)')
                    VK('i', '<C-l>', '<Plug>(copilot-accept-line)')
                    VK('i', '<C-a>', 'copilot#Accept("\\<CR>")', {
                        expr = true,
                        replace_keycodes = false
                    })
                end,
            },

            {
                -- AI - CopilotChat
                "CopilotC-Nvim/CopilotChat.nvim",
                dependencies = {
                    { "github/copilot.vim" },
                    { "nvim-lua/plenary.nvim",  branch = "master" },
                },
                build = "make tiktoken",
                opts = {
                    auto_follow_cursor = false,
                    debug = false,
                    mappings = {
                        complete = {
                            detail = 'Use @<Tab> or /<Tab> for options.',
                            insert = '<Tab>',
                        },
                        close = {
                            normal = '<Esc>',
                            insert = '<C-c>'
                        },
                        reset = {
                            normal = '<C-l>',
                            insert = '<C-l>'
                        },
                        submit_prompt = {
                            normal = '<CR>',
                            insert = '<C-s>'
                        },
                        accept_diff = {
                            normal = '<C-a>',
                            insert = '<C-a>'
                        },
                        yank_diff = {
                            normal = 'dy',
                            register = '"',
                        },
                        show_diff = {
                            normal = 'ds'
                        },
                        show_help = {
                            normal = '?'
                        },
                    },
                },
                config = function(_, opts)
                    local chat = require("CopilotChat")
                    local select = require("CopilotChat.select")
                    opts.selection = function(source)
                        return
                            select.visual(source) or
                            select.buffer(source) or
                            select.unnamed(source)
                    end
                    chat.setup(opts)
                    vim.api.nvim_create_user_command(
                        "CopilotChatVisual",
                        function(args)
                            chat.ask(args.args, { selection = select.visual })
                        end,
                        { nargs = "*", range = true }
                    )
                    vim.api.nvim_create_user_command(
                        "CopilotChatInline",
                        function(args)
                            chat.ask(
                                args.args,
                                {
                                    selection = select.visual,
                                    window = {
                                        layout = "float",
                                        relative = "cursor",
                                        width = 1,
                                        height = 0.4,
                                        row = 1,
                                    },
                                }
                            )
                        end,
                        { nargs = "*", range = true }
                    )
                    vim.api.nvim_create_user_command(
                        "CopilotChatBuffer",
                        function(args)
                            chat.ask(args.args, { selection = select.buffer })
                        end,
                        { nargs = "*", range = true }
                    )
                    vim.api.nvim_create_autocmd(
                        "BufEnter", {
                            pattern = "copilot-*",
                            callback = function()
                                vim.opt_local.relativenumber = true
                                vim.opt_local.number = true
                                local ft = vim.bo.filetype
                                if ft == "copilot-chat" then
                                    vim.bo.filetype = "markdown"
                                end
                            end,
                        })
                end,
                event = "VeryLazy",
                keys = {
                    {
                        "<LocalLeader>ch",
                        function()
                            local actions = require("CopilotChat.actions")
                            require(
                                "CopilotChat.integrations.telescope"
                            ).pick(actions.help_actions())
                        end,
                        desc = "CopilotChat - Help actions",
                    },
                    {
                        "<LocalLeader>cp",
                        function()
                            local actions = require("CopilotChat.actions")
                            require(
                                "CopilotChat.integrations.telescope"
                            ).pick(actions.prompt_actions())
                        end,
                        desc = "CopilotChat - Prompt actions",
                    },
                    {
                        "<LocalLeader>cp",
                        ":lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').prompt_actions({selection = require('CopilotChat.select').visual}))<CR>",
                        mode = "x",
                        desc = "CopilotChat - Prompt actions",
                    },
                    {
                        "<LocalLeader>ce",
                        "<cmd>CopilotChatExplain<cr>",
                        desc = "CopilotChat - Explain code",
                    },
                    {
                        "<LocalLeader>ct",
                        "<cmd>CopilotChatTests<cr>",
                        desc = "CopilotChat - Generate tests",
                    },
                    {
                        "<LocalLeader>cr",
                        "<cmd>CopilotChatReview<cr>",
                        desc = "CopilotChat - Review code",
                    },
                    {
                        "<LocalLeader>cR",
                        "<cmd>CopilotChatRefactor<cr>",
                        desc = "CopilotChat - Refactor code",
                    },
                    {
                        "<LocalLeader>cn",
                        "<cmd>CopilotChatBetterNamings<cr>",
                        desc = "CopilotChat - Better Naming",
                    },
                    {
                        "<LocalLeader>cv",
                        ":CopilotChatVisual<CR>",
                        mode = "x",
                        desc = "CopilotChat - Open in vertical split",
                    },
                    {
                        "<LocalLeader>ci",
                        ":CopilotChatInline<cr>",
                        mode = "x",
                        desc = "CopilotChat - Inline chat",
                    },
                    {
                        "<LocalLeader>cc",
                        function()
                            local input = vim.fn.input("Ask Copilot: ")
                            if input ~= "" then
                                vim.cmd("CopilotChat " .. input)
                            end
                        end,
                        desc = "CopilotChat - Ask input",
                    },
                    {
                        "<LocalLeader>cm",
                        "<cmd>CopilotChatCommit<cr>",
                        desc = "CopilotChat - Generate commit message for all changes",
                    },
                    {
                        "<LocalLeader>cM",
                        "<cmd>CopilotChatCommitStaged<cr>",
                        desc = "CopilotChat - Generate commit message for staged changes",
                    },
                    {
                        "<LocalLeader>cq",
                        function()
                            local input = vim.fn.input("Quick Chat: ")
                            if input ~= "" then
                                vim.cmd("CopilotChatBuffer " .. input)
                            end
                        end,
                        desc = "CopilotChat - Quick chat",
                    },
                    {
                        "<LocalLeader>cD",
                        "<cmd>CopilotChatDebugInfo<cr>",
                        desc = "CopilotChat - Debug Info",
                    },
                    {
                        "<LocalLeader>cf",
                        "<cmd>CopilotChatFixDiagnostic<cr>",
                        desc = "CopilotChat - Fix Diagnostic",
                    },
                    {
                        "<LocalLeader>cC",
                        "<cmd>CopilotChatReset<cr>",
                        desc = "CopilotChat - Clear buffer and chat history",
                    },
                    {
                        "<LocalLeader>cv",
                        "<cmd>CopilotChatToggle<cr>",
                        desc = "CopilotChat - Toggle",
                    },
                    {
                        "<LocalLeader>cs",
                        "<cmd>CopilotChatModels<cr>",
                        desc = "CopilotChat - Select Models",
                    }
                }
            },

            {
                -- Traverse windows easier
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
            },

            {
                -- Wrap arguments and lists
                'Wansmer/treesj',
                dependencies = { 'nvim-treesitter/nvim-treesitter' },
                config = function()
                    require('treesj').setup({
                        use_default_keymaps = true,
                        check_syntax_error = true,
                        max_join_length = 79,
                        cursor_behavior = 'hold',
                        notify = true,
                        dot_repeat = true,
                    })
                end,
            },

            {
                -- Simple file management
                'stevearc/oil.nvim',
                config = function()
                    require('oil').setup({
                        default_file_explorer = true,
                        columns = {
                            "icon",
                            "permissions",
                            "size",
                            "mtime",
                        },
                        skip_confirm_for_simple_edits = true,
                        prompt_save_on_select_new_entry = true,
                        watch_for_changes = true,
                        use_default_keymaps = false,
                        keymaps = {
                            ["?"] = "actions.show_help",
                            ["<CR>"] = "actions.select",
                            ["<LocalLeader>v"] = {
                                "actions.select",
                                opts = { vertical = true },
                                desc = "Open the entry in a vertical split",
                            },
                            ["<LocalLeader>h"] = {
                                "actions.select",
                                opts = { horizontal = true },
                                desc = "Open the entry in a horizontal split",
                            },
                            ["<LocalLeader>t"] = {
                                "actions.select",
                                opts = { tab = true },
                                desc = "Open the entry in new tab",
                            },
                            ["<LocalLeader>p"] = "actions.preview",
                            ["<Esc>"] = "actions.close",
                            ["<LolcalLeader>r"] = "actions.refresh",
                            ["<LocalLeader>u"] = "actions.parent",
                            ["<LocalLeader>o"] = "actions.open_cwd",
                            ["<LocalLeader>c"] = "actions.cd",
                            ["<LocalLeader>C"] = {
                                "actions.cd",
                                opts = { scope = "tab" },
                                desc = ":tcd to the current oil directory",
                            },
                            ["<LocalLeader>s"] = "actions.change_sort",
                            ["<LocalLeader>x"] = "actions.open_external",
                            ["<LocalLeader>."] = "actions.toggle_hidden",
                        },
                        view_options = {
                            show_hidden = true,
                        },
                        VK('n', '-', require("oil").toggle_float)
                    })
                end
            },

            {
                -- Show special characters
                'lukas-reineke/indent-blankline.nvim',
                main = "ibl",
                opts = {
                    space_char_blankline       = ' ',
                    show_current_context       = true,
                    show_current_context_start = true,
                },
                config = function()
                    local highlight = {
                        "RainbowRed",
                        "RainbowYellow",
                        "RainbowBlue",
                        "RainbowOrange",
                        "RainbowGreen",
                        "RainbowViolet",
                        "RainbowCyan"
                    }
                    local hooks = require("ibl.hooks")
                    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                        VA.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
                        VA.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
                        VA.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
                        VA.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
                        VA.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
                        VA.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
                        VA.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
                    end)
                    require("ibl").setup({
                        scope = {
                            highlight = highlight,
                            show_start = false,
                            show_end = false,
                        }
                    })
                    VO.list = true
                    VO.listchars:append('trail:▸')
                    hooks.register(
                        hooks.type.SCOPE_HIGHLIGHT,
                        hooks.builtin.scope_highlight_from_extmark
                    )
                end
            },

            {
                -- Status line
                'nvim-lualine/lualine.nvim',
                config = function()
                    require('lualine').setup({
                        options = {
                            theme = 'auto'
                        },
                        sections = {
                            lualine_b = {},
                        },
                    })
                end
            },

            {
                -- Undo history
                'jiaoshijie/undotree',
                dependencies = { 'nvim-lua/plenary.nvim' },
                config = function()
                    require('undotree').setup({
                        window = { winblend = 0 }
                    })
                    VK('n', '<localleader>u', require('undotree').open)
                end
            },

            {
                -- Pretty icons everywhere
                'nvim-tree/nvim-web-devicons',
                config = function()
                    require('nvim-web-devicons').setup({
                        default     = true,
                        color_icons = true,
                    })
                end
            },

            {
                -- Match pairs
                'windwp/nvim-autopairs',
                config = function()
                    require('nvim-autopairs').setup({})
                end,
            },

            {
                -- Show keybindings
                'folke/which-key.nvim',
                config = function()
                    require('which-key').setup({})
                end,
            },

            'echasnovski/mini.icons',      -- Icons provider for nvim

            'gpanders/nvim-parinfer',      -- Auto indent parantheses for lisp

            'mg979/vim-visual-multi',      -- Multiple cursors

            'akhilsbehl/md-image-paste',   -- Paste images in md files

            'tpope/vim-surround',          -- Use surround movements

            'powerman/vim-plugin-AnsiEsc', -- Escape shell color codes

            'folke/tokyonight.nvim',       -- Theme: tokyonight
            'catppuccin/nvim',             -- Theme: catppuccin
            'sainnhe/sonokai',             -- Theme: sonokai
            'sainnhe/gruvbox-material',    -- Theme: gruvbox-material
            'navarasu/onedark.nvim',       -- Theme: onedark
            'rebelot/kanagawa.nvim',       -- Theme: kanagawa

        },
        {
            checker = {
                enabled = true,
            }
        }
    )

    VC [[ source ~/.config/nvim/vimrc ]]
end
