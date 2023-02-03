local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'              -- Package manager

  -- General plugins
  use 'neovim/nvim-lspconfig'               -- Easily configure LSPs
  use 'williamboman/mason.nvim'             -- Easily installl stuff
  use 'hrsh7th/cmp-nvim-lsp'                -- LSP completion server
  use 'hrsh7th/cmp-buffer'                  -- Buf tokens completion server
  use 'hrsh7th/cmp-path'                    -- Path completion server
  use 'hrsh7th/cmp-cmdline'                 -- Command line completion server
  use 'hrsh7th/nvim-cmp'                    -- Completion engine
  use 'nvim-treesitter/nvim-treesitter'     -- The main reason
  use 'windwp/nvim-autopairs'               -- Match pairs
  use 'folke/which-key.nvim'                -- Show keybindings
  use 'jiaoshijie/undotree'                 -- Undo history
  use 'L3MON4D3/LuaSnip'                    -- Snippets engine
  use 'rafamadriz/friendly-snippets'        -- Snippets library
  use 'hkupty/iron.nvim'                    -- Slime
  use 'tpope/vim-commentary'                -- Commenting
  -- Or? use 'jpalardy/vim-slime'

  use {                                     -- Fuzzy finder
    'nvim-telescope/telescope.nvim', branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  -- Look back at this at some point:
  -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v1.x/doc/md/lsp.md#you-might-not-need-lsp-zero

  -- Ported from my vimrc - legacy plugins I love
  use 'tpope/vim-surround'                  -- Use surround movements
  use 'tpope/vim-repeat'                    -- Repeat commands
  use 'mg979/vim-visual-multi'              -- Multiple cursors
  use 'godlygeek/tabular'                   -- Align rows
  use 'github/copilot.vim'                  -- AI

  -- Need to port this - look at pynvim
  -- use 'akhilsbehl/md-image-paste'        -- Paste images in md files
  
  -- Make shit look good
  use 'powerman/vim-plugin-AnsiEsc'         -- Escape shell color codes
  use 'nvim-tree/nvim-web-devicons'         -- Pretty icons everywhere
  use "lukas-reineke/indent-blankline.nvim" -- Show newlines
  use 'airblade/vim-gitgutter'              -- Show git sign

  use 'morhetz/gruvbox'
  use 'tomasr/molokai'
  use 'joshdick/onedark.vim'
  use 'folke/tokyonight.nvim'
  use 'nvim-lualine/lualine.nvim'

  -- Some day look at this:
  -- rockerBOO/awesome-neovim

  if packer_bootstrap then
    require('packer').sync()
  end
end)
