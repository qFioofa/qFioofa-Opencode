{
  description = "qFioofa opencode configuration — Home Manager module and portable deploy scripts";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # Symlinks ./src to ~/.config/opencode. Enable with:
      #   programs.qfioofa-opencode.enable = true;
      homeManagerModules.default = import ./nix/hm-module.nix { inherit self; };
      homeManagerModules.qfioofa-opencode = self.homeManagerModules.default;

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
