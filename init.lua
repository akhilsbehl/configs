V = vim
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

local lazypath = VF.stdpath("data") .. "/lazy/lazy.nvim"
if not V.loop.fs_stat(lazypath) then
    VF.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
VO.rtp:prepend(lazypath)

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
                            ['<c-e>'] = V.NIL,
                            ['<C-t>'] = cmp.mapping.complete(),
                            ['<cr>'] = cmp.mapping.confirm({ select = true }),
                            ['<C-c>'] = cmp.mapping.close(),
                            ['<C-d>'] = cmp.mapping.abort(),
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
                    VK('n', '<localleader>jD',
                        '<cmd>Telescope diagnostics<cr>')
                    VK('n', '<localleader>jr',
                        '<cmd>Telescope lsp_references<cr>')
                    VK('n', '<localleader>jd',
                        '<cmd>Telescope lsp_definitions<cr>')
                    VK('n', '<localleader>jI',
                        '<cmd>Telescope lsp_incoming_calls<cr>')
                    VK('n', '<localleader>jO',
                        '<cmd>Telescope lsp_outgoing_calls<cr>')
                    VK('n', '<localleader>jm',
                        '<cmd>Telescope lsp_implementations<cr>')
                    VK('n', '<localleader>jt',
                        '<cmd>Telescope lsp_type_definitions<cr>')
                    VK('n', '<localleader>jS',
                        '<cmd>Telescope lsp_document_symbols<cr>')
                    VK('n', '<localleader>jw',
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
                            'markdown'
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
                        case_insensitive = true,
                        multi_windows = true,
                    })
                    VK({ 'n', 'o', 'v' }, 'b', '<cmd>HopChar2<CR>')
                    VK({ 'n', 'o', 'v' }, '&', '<cmd>HopPattern<CR>')
                    VK({ 'n', 'o', 'v' }, '_', '<cmd>HopLineStart<CR>')
                    VK({ 'n', 'o', 'v' }, '<LocalLeader>f', _f)
                    VK({ 'n', 'o', 'v' }, '<LocalLeader>F', _F)
                    VK({ 'n', 'o', 'v' }, '<LocalLeader>t', _t)
                    VK({ 'n', 'o', 'v' }, '<LocalLeader>T', _T)
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
                    V.treesitter.language.register('markdown', 'telekasten')
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
                -- Markdown rendering in Vim
                "MeanderingProgrammer/render-markdown.nvim",
                dependencies = {
                    { "nvim-treesitter/nvim-treesitter" },
                    { "echasnovski/mini.icons" },
                },
                ---@module 'render-markdown'
                ---@type render.md.UserConfig
                opts = {
                    file_types = { 'markdown', 'copilot-chat', 'telekasten' },
                    render_modes = true,
                    anti_conceal = { enabled = true },
                    pipe_table = { preset = 'round' },
                },
            },

            {
                -- AI - Copilot
                'github/copilot.vim',
                config = function()
                    VG.copilot_enabled = (VF.getenv("HAS_GH_COPILOT") == "1") and 1 or 0
                    VG.copilot_no_tab_map = 1
                    VK('i', '<C-s>', '<Plug>(copilot-suggest)')
                    VK('i', '<C-c>', '<Plug>(copilot-dismiss)')
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
                    { "nvim-lua/plenary.nvim", branch = "master" },
                },
                build = "make tiktoken",
                opts = {
                    model = 'gpt-4o',
                    temperature = 0.0,
                    window = {
                        layout = "horizontal",
                        relative = "editor",
                        width = 1,
                        height = 0.3,
                        row = nil,
                        col = nil,
                    },
                    auto_insert_mode = false,
                    insert_at_end = true,
                    question_header = "# Me: ",
                    answer_header = "# Copilot: ",
                    error_header = "> [!ERROR] Error: ",
                    separator = "---",
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
                            normal = '<C-d>',
                            insert = '<C-d>'
                        },
                        submit_prompt = {
                            normal = '<CR>',
                            insert = '<C-s>'
                        },
                        accept_diff = {
                            normal = 'da',
                        },
                        yank_diff = {
                            normal = 'dy',
                            register = '+',
                        },
                        jump_to_diff = {
                            normal = 'dj',
                        },
                        quickfix_diffs = {
                            normal = 'dq',
                        },
                        show_diff = {
                            normal = 'ds'
                        },
                        show_info = {
                            normal = 'di'
                        },
                        show_context = {
                            normal = 'dc'
                        },
                        show_help = {
                            normal = '?'
                        },
                    },
                },
                config = function(_, opts)
                    local prompts = {
                        Explain = {
                            prompt =
                            '> /COPILOT_EXPLAIN\n\nExplain this code in English focusing on the What, How, and Why in that order.',
                            description = 'Explain this code in detail',
                        },
                        Docstring = {
                            prompt =
                            '> /COPILOT_GENERATE\n\nGenerate inline docstrings for this code in English. For python use numpydocstyle. For JS use JSDoc style. For others, pick a similar widely-accepted standard. Also cover exceptions raised.',
                            description = 'Generate inline docstrings',
                        },
                        Test = {
                            prompt =
                            '> /COPILOT_GENERATE\n\nWrite unit tests for this code covering all paths. Add tests at the end of the file. For python use pytest. For JS use Jest. For others, pick a similar widely-accepted standard.',
                            description = 'Write unit tests for the code',
                        },
                        Userdoc = {
                            prompt =
                            '> /COPILOT_GENERATE\n\nWrite user documentation for this code in English in a helpful and empathetic tone. Include examples and explanations. Explain the defaults, edge cases, possible exceptions. Also add notes, if relevant, about time and space complexity.',
                            description = 'Write user documentation',
                        },
                        Annotate = {
                            prompt =
                            '> /COPILOT_GENERATE\n\nAnnotate this code with high quality and comprehensive type hints for all function signatures and variable declarations.',
                            description = 'Annotate code with type hints',
                        },
                        Fixwidth = {
                            prompt =
                            '> /COPILOT_GENERATE\n\nResize this code to fit in under 79 columns of width. Do NOT change the contents in any way.',
                            description = 'Resize code to fit under 79 columns',
                        },
                        Review = {
                            prompt =
                            '> /COPILOT_REVIEW\n\nReview this code for correctness, style, and performance. Provide feedback in English.',
                            description = 'Review code for correctness, style, and performance',
                        },
                        Fix = {
                            prompt =
                            '> /COPILOT_GENERATE\n\nThere is a bug in this code. Identify and rewrite the code to fix it.',
                            description = 'Identify and fix bugs in the code',
                        }
                    }
                    local chat = require("CopilotChat")
                    chat.prompts = function()
                        return prompts
                    end
                    local select = require("CopilotChat.select")
                    local actions = require("CopilotChat.actions")
                    local ccti = require(
                        'CopilotChat.integrations.telescope'
                    )
                    chat.setup(opts)
                    opts.selection = function(source)
                        return select.visual(source) or select.buffer(source)
                    end
                    VA.nvim_create_autocmd(
                        "BufEnter", {
                            pattern = "copilot-*",
                            callback = function()
                                V.opt_local.relativenumber = true
                                V.opt_local.number = true
                                local ft = V.bo.filetype
                                if ft == "copilot-chat" then
                                    V.bo.filetype = "markdown"
                                end
                            end,
                        }
                    )
                    VA.nvim_create_user_command(
                        "CopilotChatJustChat",
                        function()
                            local input = VF.input("Ask: ")
                            if input ~= "" then
                                chat.ask(input)
                            end
                        end,
                        { nargs = "*", range = true }
                    )
                    VA.nvim_create_user_command(
                        "CopilotChatVisual",
                        function(args)
                            chat.ask(args.args, { selection = select.visual })
                        end,
                        { nargs = "*", range = true }
                    )
                    VA.nvim_create_user_command(
                        "CopilotChatBuffer",
                        function(args)
                            chat.ask(args.args, { selection = select.buffer })
                        end,
                        { nargs = "*", range = true }
                    )
                    VA.nvim_create_user_command(
                        "CopilotChatPickActionVisual",
                        function()
                            ccti.pick(
                                actions.prompt_actions(
                                    { selection = select.visual }
                                )
                            )
                        end,
                        { nargs = "*", range = true }
                    )
                    VA.nvim_create_user_command(
                        "CopilotChatPickActionBuffer",
                        function()
                            ccti.pick(
                                actions.prompt_actions(
                                    { selection = select.buffer }
                                )
                            )
                        end,
                        { nargs = "*", range = true }
                    )
                end,
                keys = {
                    {
                        "<LocalLeader>cc",
                        ":CopilotChatJustChat<CR>",
                        desc = "CopilotChat - Just Chat with the model",
                    },
                    {
                        "<LocalLeader>cv",
                        ":CopilotChatVisual<CR>",
                        mode = "x",
                        desc = "CopilotChat - Chat over visual selection",
                    },
                    {
                        "<LocalLeader>cb",
                        ":CopilotChatBuffer<CR>",
                        desc = "CopilotChat - Chat over the buffer contents",
                    },
                    {
                        "<LocalLeader>cp",
                        ":CopilotChatPickActionVisual<CR>",
                        mode = "x",
                        desc = "CopilotChat - Pick prompt actions over visual selection",
                    },
                    {
                        "<LocalLeader>cp",
                        ":CopilotChatPickActionBuffer<CR>",
                        desc = "CopilotChat - Pick prompt actions over the buffer contents",
                    },
                },
            },

            {
                -- Traverse windows easier
                'https://gitlab.com/yorickpeterse/nvim-window.git',
                config = function()
                    require('nvim-window').setup({
                        chars = {
                            'e', 't', 'o', 'v', 'x', 'q', 'p', 'd', 'y', 'g',
                            'f', 'b', 'l', 'z', 'h', 'c', 'k', 'i', 's', 'u',
                            'r', 'a',
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
                -- The plugin insists on all 3 shortcuts. I only use the first
                keys = {
                    '<LocalLeader>m',
                    '<LocalLeader>#',
                    '<LocalLeader>$',
                },
                config = function()
                    require('treesj').setup({
                        use_default_keymaps = false,
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
                -- Neo Magit
                'NeogitOrg/neogit',
                dependencies = {
                    "nvim-lua/plenary.nvim",
                    "sindrets/diffview.nvim",
                    "nvim-telescope/telescope.nvim"
                },
                config = function()
                    require('neogit').setup({
                        graph_style = 'kitty',
                        git_services = {
                            ["github.com"] = "https://github.com/${owner}/${repository}/compare/${branch_name}?expand=1",
                            ["fractal.ai"] =
                            "https://gitlab.fractal.ai/${owner}/${repository}/pull-requests/new?source=${branch_name}&t=1",
                            ["gitlab.com"] =
                            "https://gitlab.com/${owner}/${repository}/merge_requests/new?merge_request[source_branch]=${branch_name}",

                        },
                        use_default_keymaps = false,
                        kind = 'floating',
                        commit_editor = {
                            kind = 'tab',
                        },
                        commit_select_view = {
                            kind = 'tab',
                        },
                        commit_view = {
                            kind = 'floating',
                            verify_commit = false,
                        },
                        log_view = {
                            kind = 'floating',
                        },
                        rebase_editor = {
                            kind = 'floating',
                        },
                        reflog_view = {
                            kind = 'floating',
                        },
                        merge_editor = {
                            kind = 'floating',
                        },
                        description_editor = {
                            kind = 'floating',
                        },
                        tag_editor = {
                            kind = 'floating',
                        },
                        preview_buffer = {
                            kind = 'floating',
                        },
                        popup = {
                            kind = 'floating',
                        },
                        stash = {
                            kind = 'floating',
                        },
                        refs_view = {
                            kind = 'floating',
                        },
                        integrations = {
                            telescope = true,
                            diffview = true,
                        },
                        mappings = {
                            commit_editor = {
                                ["<Esc>"] = "Close",
                                ["<C-a>"] = "Submit",
                                ["<C-c>"] = "Abort",
                                ["<C-j>"] = "PrevMessage",
                                ["<C-k>"] = "NextMessage",
                                ["<C-d>"] = "ResetMessage",
                            },
                            commit_editor_I = {
                                ["<C-a>"] = "Submit",
                                ["<C-c>"] = "Abort",
                            },
                            rebase_editor = {
                                ["p"] = "Pick",
                                ["r"] = "Reword",
                                ["e"] = "Edit",
                                ["s"] = "Squash",
                                ["f"] = "Fixup",
                                ["x"] = "Execute",
                                ["d"] = "Drop",
                                ["b"] = "Break",
                                ["q"] = "Close",
                                ["<cr>"] = "OpenCommit",
                                ["gk"] = "MoveUp",
                                ["gj"] = "MoveDown",
                                ["<C-a>"] = "Submit",
                                ["<C-c>"] = "Abort",
                                ["<C-k>"] = "OpenOrScrollUp",
                                ["<C-j>"] = "OpenOrScrollDown",
                            },
                            rebase_editor_I = {
                                ["<C-a>"] = "Submit",
                                ["<C-c>"] = "Abort",
                            },
                            finder = {
                                ["<cr>"] = "Select",
                                ["<C-c>"] = "Close",
                                ["<esc>"] = "Close",
                                ["<C-k>"] = "Next",
                                ["<C-j>"] = "Previous",
                                ["<down>"] = "Next",
                                ["<tab>"] = "InsertCompletion",
                                ["<space>"] = "NOP",
                                ["<s-space>"] = "NOP",
                                ["<ScrollWheelDown>"] = "ScrollWheelDown",
                                ["<ScrollWheelUp>"] = "ScrollWheelUp",
                                ["<ScrollWheelLeft>"] = "NOP",
                                ["<ScrollWheelRight>"] = "NOP",
                                ["<LeftMouse>"] = "MouseClick",
                                ["<2-LeftMouse>"] = "NOP",
                            },
                            popup = {
                                ["?"] = "HelpPopup",
                                ["A"] = "CherryPickPopup",
                                ["d"] = "DiffPopup",
                                ["M"] = "RemotePopup",
                                ["P"] = "PushPopup",
                                ["X"] = "ResetPopup",
                                ["Z"] = "StashPopup",
                                ["i"] = "IgnorePopup",
                                ["t"] = "TagPopup",
                                ["b"] = "BranchPopup",
                                ["B"] = "BisectPopup",
                                ["w"] = "WorktreePopup",
                                ["c"] = "CommitPopup",
                                ["f"] = "FetchPopup",
                                ["l"] = "LogPopup",
                                ["m"] = "MergePopup",
                                ["p"] = "PullPopup",
                                ["r"] = "RebasePopup",
                                ["v"] = "RevertPopup",
                            },
                            status = {
                                ["j"] = "MoveDown",
                                ["k"] = "MoveUp",
                                ["o"] = "OpenTree",
                                ["q"] = "Close",
                                ["<Esc>"] = "Close",
                                ["I"] = "InitRepo",
                                ["1"] = "Depth1",
                                ["2"] = "Depth2",
                                ["3"] = "Depth3",
                                ["4"] = "Depth4",
                                ["Q"] = "Command",
                                ["<tab>"] = "Toggle",
                                ["x"] = "Discard",
                                ["s"] = "Stage",
                                ["S"] = "StageUnstaged",
                                ["<c-s>"] = "StageAll",
                                ["u"] = "Unstage",
                                ["K"] = "Untrack",
                                ["U"] = "UnstageStaged",
                                ["y"] = "ShowRefs",
                                ["$"] = "CommandHistory",
                                ["Y"] = "YankSelected",
                                ["<c-r>"] = "RefreshBuffer",
                                ["<cr>"] = "GoToFile",
                                ["<S-p>"] = "PeekFile",
                                ["<C-v>"] = "VSplitOpen",
                                ["<C-e>"] = "SplitOpen",
                                ["<C-t>"] = "TabOpen",
                                ["gj"] = "GoToPreviousHunkHeader",
                                ["gk"] = "GoToNextHunkHeader",
                                ["<C-j>"] = "OpenOrScrollUp",
                                ["<C-k>"] = "OpenOrScrollDown",
                                ["<C-k>"] = "PeekUp",
                                ["<C-f>"] = "PeekDown",
                                ["<C-n>"] = "NextSection",
                                ["<C-p>"] = "PreviousSection",
                            },
                        },
                    })
                    VK('n', '<LocalLeader>gs', "<Cmd>Neogit<CR>")
                    VK('n', '<LocalLeader>gc', "<Cmd>Neogit<CR>")
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
            'echasnovski/mini.icons', -- Additional icons

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


            'gpanders/nvim-parinfer',      -- Auto indent parantheses for lisp

            'mg979/vim-visual-multi',      -- Multiple cursors

            'akhilsbehl/md-image-paste',   -- Paste images in md files

            'tpope/vim-surround',          -- Use surround movements

            'powerman/vim-plugin-AnsiEsc', -- Escape shell color codes

            -- Themes:
            'folke/tokyonight.nvim',
            'catppuccin/nvim',
            'sainnhe/sonokai',
            'sainnhe/gruvbox-material',
            'navarasu/onedark.nvim',
            'rebelot/kanagawa.nvim',

        },
        {
            checker = {
                enabled = true,
            }
        }
    )

    VC [[ source ~/.config/nvim/vimrc ]]
end
