VA = vim.api
VC = vim.cmd
VD = vim.diagnostic
VF = vim.fn
VG = vim.g
VK = vim.keymap.set
VO = vim.opt

VG.mapleader = ','
VG.maplocalleader = ' '

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

if not VG.vscode then
    require('lazy').setup(
        {

            {
                -- LSP & CMP
                'VonHeikemen/lsp-zero.nvim',
                branch = 'v2.x',
                dependencies = {
                    { 'neovim/nvim-lspconfig' },
                    { 'williamboman/mason.nvim' },
                    { 'williamboman/mason-lspconfig.nvim' },
                    { 'hrsh7th/nvim-cmp' },
                    { 'hrsh7th/cmp-buffer' },
                    { 'hrsh7th/cmp-nvim-lsp' },
                    { 'hrsh7th/cmp-nvim-lua' },
                    { 'hrsh7th/cmp-path' },
                    { 'L3MON4D3/LuaSnip' }, -- Only to stop cmp's bitching
                    { 'quangnguyen30192/cmp-nvim-ultisnips' },
                },
                config = function()
                    local lsp = require('lsp-zero').preset({})
                    lsp.on_attach(function(client, bufnr)
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
                    end)
                    local cmp = require('cmp')
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
                            ['<C-c>'] = cmp.mapping.close(),
                            ['<C-c>'] = cmp.mapping.abort(),
                            ['<tab>'] = cmp.mapping.select_next_item(),
                            ['<S-tab>'] = cmp.mapping.select_prev_item(),
                            ['<C-n>'] = cmp.mapping.scroll_docs(3),
                            ['<C-p>'] = cmp.mapping.scroll_docs(-3),
                        }),
                    })
                    local signs = {
                        Error = ' ',
                        Warn  = ' ',
                        Hint  = ' ',
                        Info  = ' ',
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
                tag = '0.1.2',
                dependencies = { 'nvim-lua/plenary.nvim' },
                config = function()
                    local ac = require('telescope.actions')
                    local qfix = ac.smart_send_to_qflist + ac.open_qflist
                    require('telescope').setup({
                        defaults = {
                            default_mappings = {
                                i = {
                                    ["<C-/>"]      = ac.which_key,
                                    ["<C-_>"]      = ac.which_key,
                                    ["<C-e>"]      = ac.select_default,
                                    ["<C-h>"]      = ac.preview_scrolling_down,
                                    ["<C-j>"]      = ac.nop,
                                    ["<C-l>"]      = ac.preview_scrolling_up,
                                    ["<C-m>"]      = ac.toggle_selection,
                                    ["<C-n>"]      = ac.results_scrolling_down,
                                    ["<C-p>"]      = ac.results_scrolling_up,
                                    ["<C-q>"]      = qfix,
                                    ["<C-s>"]      = ac.select_horizontal,
                                    ["<C-t>"]      = ac.select_tab,
                                    ["<C-v>"]      = ac.select_vertical,
                                    ["<C-w>"]      = ac.nop,
                                    ["<C-x>"]      = ac.nop,
                                    ["<Down>"]     = ac.nop,
                                    ["<Esc>"]      = ac.close,
                                    ["<M-q>"]      = ac.nop,
                                    ["<PageDown>"] = ac.nop,
                                    ["<PageUp>"]   = ac.nop,
                                    ["<S-Tab>"]    = ac.move_selection_next,
                                    ["<Tab>"]      = ac.move_selection_previous,
                                    ["<Up>"]       = ac.nop,
                                    ["<cr>"]       = ac.select_default, -- buggy
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
                    VK('n', '<leader>fs', '<cmd>Telescope ultisnips<cr>')
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
            'fhill2/telescope-ultisnips.nvim',

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
                -- AI
                'github/copilot.vim',
                config = function()
                    VG.copilot_enabled = 1
                    VG.copilot_no_tab_map = 1
                    VK('n', '<leader>cd', '<cmd>let copilot_enabled=0<cr>')
                    VK('n', '<leader>ce', '<cmd>let copilot_enabled=1<cr>')
                    VK('n', '<leader>cs', '<cmd>Copilot<cr>')
                    VK('i', '<C-s>', '<Plug>(copilot-suggest)')
                    VK('i', '<C-d>', '<Plug>(copilot-dismiss)')
                    VK('i', '<C-j>', '<Plug>(copilot-next)')
                    VK('i', '<C-k>', '<Plug>(copilot-previous)')
                    VK('i', '<C-a>', 'copilot#Accept("")', {
                        expr = true, replace_keycodes = false,
                    })
                end,
            },

            -- {
                -- -- Free AI
                -- 'Exafunction/codeium.vim',
                -- event = 'BufEnter',
                -- config = function ()
                    -- VG.codeium_enabled = 1
                    -- VG.codeium_disable_bindings = 1
                    -- VG.codeium_no_map_tab = 1
                    -- VK('n', '<leader>cd', '<cmd>let codeium_enabled=0<cr>')
                    -- VK('n', '<leader>ce', '<cmd>let codeium_enabled=1<cr>')
                    -- VK('n', '<leader>cc', '<cmd>call codeium#Chat()<cr>')
                    -- VK('i', '<C-s>', '<cmd>call codeium#CycleOrComplete()<cr>')
                    -- VK('i', '<C-d>', '<cmd>call codeium#Clear()<cr>')
                    -- VK(
                        -- 'i',
                        -- '<C-j>',
                        -- '<cmd>call codeium#CycleCompletions(1)<CR>'
                    -- )
                    -- VK(
                        -- 'i',
                        -- '<C-k>',
                        -- '<cmd>call codeium#CycleCompletions(-1)<cr>'
                    -- )
                    -- VK(
                        -- 'i',
                        -- '<C-a>',
                        -- function ()
                            -- return vim.fn['codeium#Accept']()
                        -- end,
                        -- { expr = true, silent = true }
                    -- )
                -- end,
            -- },

            {
                -- Snippets engine
                'SirVer/UltiSnips',
                config = function()
                    VG.UltiSnipsExpandTrigger                           = '<C-e>'
                    VG.UltiSnipsListSnippets                            = '<C-l>'
                    VG.UltiSnipsJumpForwardTrigger                      = '<C-k>'
                    VG.UltiSnipsJumpBackwardTrigger                     = '<C-j>'
                    VG.UltiSnipsRemoveSelectModeMappings                = 0
                    VG.UltiSnipsSnippetStorageDirectoryForUltiSnipsEdit =
                    '~/.vim/mysnippets'
                    VG.UltiSnipsSnippetDirectories                      = {
                        'mysnippets', 'UltiSnips'
                    }
                end
            },
            'honza/vim-snippets',

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
                -- Show special characters
                'lukas-reineke/indent-blankline.nvim',
                main = "ibl",
                opts = {
                    space_char_blankline       = ' ',
                    show_current_context       = true,
                    show_current_context_start = true,
                },
                config = function()
                    VO.list = true
                    VO.listchars:append('trail:▸')
                end
            },

            {
                -- Status line
                'nvim-lualine/lualine.nvim',
                config = function()
                    custom_theme = require('lualine.themes.gruvbox-material')
                    require('lualine').setup({
                        options = {
                            -- theme = custom_theme,
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

            'tpope/vim-repeat',            -- Repeat commands

            'godlygeek/tabular',           -- Align rows

            'powerman/vim-plugin-AnsiEsc', -- Escape shell color codes

            'folke/tokyonight.nvim',       -- Theme: tokyonight

            'catppuccin/nvim',             -- Themes: catppuccin

            'sainnhe/sonokai',             -- Themes: sonokai

            'sainnhe/gruvbox-material',    -- Themes: gruvbox-material

            'navarasu/onedark.nvim',       -- Themes: onedark

            'rebelot/kanagawa.nvim',       -- Themes: kanagawa

        },
        {
            checker = {
                enabled = true,
            }
        }
    )

    VC [[ source ~/.config/nvim/vimrc ]]
end

-- TODOs:
-- 1. Debug Adaptor Protocol
--     1.1. rcarriga/nvim-dap-ui
--     1.2. mfussenegger/nvim-dap
--     1.3. mfussenegger/nvim-dap-python
-- 2. Literate programming?
--     2.1. zyedidia/Literate
--     2.2. zyedidia/literate.vim
