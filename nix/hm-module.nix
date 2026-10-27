# Home Manager module for the qFioofa opencode configuration.
#
# Usage (flakes):
#
#   imports = [ qfioofa-opencode.homeManagerModules.default ];
#   programs.qfioofa-opencode.enable = true;
#
# This links ./src to ~/.config/opencode (the same target scripts/deploy.sh
# uses), so opencode.jsonc, tui.json, agents, commands, skills and themes are
# managed declaratively. The config directory is read-only under Home Manager;
# use scripts/deploy.sh in copy mode if you need `opencode plugin` to mutate it.
{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.qfioofa-opencode;
in
{
  options.programs.qfioofa-opencode = {
    enable = lib.mkEnableOption "the qFioofa opencode configuration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      defaultText = lib.literalExpression "null";
      example = lib.literalExpression "pkgs.opencode";
      description = ''
        opencode package to install alongside the config. Leave null (the
        default) to manage only the config files and get opencode from the
        system profile, matching scripts/deploy.sh.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile."opencode" = {
      recursive = true;
      source = self + "/src";
    };
  };
}
