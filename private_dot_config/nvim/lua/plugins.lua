-- This file can be loaded by calling `lua require('plugins')` from your init.vim

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use 'preservim/nerdtree' -- file management

  use 'tpope/vim-commentary' -- For commenting gcc and gc

  use 'vim-airline/vim-airline' -- status bar

  use 'rafi/awesome-vim-colorschemes' -- retro scheme

  use 'preservim/tagbar' --tag bar for code navigation
end)
