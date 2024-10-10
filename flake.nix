# vim: expandtab shiftwidth=2
{
  description = "Neovim with Idris2-vim plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        vim-plug = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/junegunn/vim-plug/0.14.0/plug.vim";
          sha256 = "sha256-ILTIlfmNE4SCBGmAaMTdAxcw1OfJxLYw1ic7m5r83Ns=";
        };
        idris2-vim = pkgs.fetchFromGitHub {
          owner = "edwinb";
          repo = "idris2-vim";
          rev = "964cebee493c85f75796e4f4e6bbb4ac54e2da9e";
          hash = "sha256-v2oNgtjreNpbN0LV1RIdrcYLjFWj/k9fqGf/w4ig8cE=";
        };
        config = derivation {
          inherit system;
          name = "neovim-idris2-config";
          builder = pkgs.writeShellScript "build-neovim-idris2-config" ''
            set -e
            ${pkgs.coreutils}/bin/mkdir -p $out
            ${pkgs.coreutils}/bin/ln -s ${self} $out/flake

            ${pkgs.coreutils}/bin/mkdir -p $out/autoload
            ${pkgs.coreutils}/bin/ln -s ${vim-plug} $out/autoload/plug.vim

            printf "\
            call plug#begin()
            Plug '${idris2-vim}'
            call plug#end()
            lua require('idris2terminal')
            colorscheme lunaperche
            syntax enable
            filetype plugin indent on
            " > $out/init.vim

            ${pkgs.coreutils}/bin/mkdir -p $out/lua/idris2terminal
            printf "\
            function idris2terminal()
              vim.cmd('split')
              vim.cmd('terminal nix-shell -p rlwrap -p idris2 --run \"rlwrap --ansi-colour-aware --no-children idris2 --find-ipkg\"')
            end
            vim.api.nvim_set_keymap('n', '<F2>', '<CMD>lua require(\"idris2terminal\")()<CR>',
              { noremap = true, silent = false }
            )
            return idris2terminal
            " > $out/lua/idris2terminal/init.lua
            '';
        };
      in
      {
        packages.default = pkgs.writeShellScriptBin "nvim-configured" ''
          ${pkgs.neovim}/bin/nvim --cmd "set runtimepath+=${config}" -u ${config}/init.vim "$@"
        '';
      }
    );
}
