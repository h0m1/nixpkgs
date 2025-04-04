{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.bloop;

in
{

  options.services.bloop = {
    extraOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "-J-Xmx2G"
        "-J-XX:MaxInlineLevel=20"
        "-J-XX:+UseParallelGC"
      ];
      description = ''
        Specifies additional command line argument to pass to bloop
        java process.
      '';
    };

    install = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to install a user service for the Bloop server.

        The service must be manually started for each user with
        "systemctl --user start bloop".
      '';
    };
  };

  config = lib.mkIf (cfg.install) {
    systemd.user.services.bloop = {
      description = "Bloop Scala build server";

      environment = {
        PATH = lib.mkForce "${lib.makeBinPath [ config.programs.java.package ]}";
      };
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.bloop}/bin/bloop start";
        ExecStop = "${pkgs.bloop}/bin/bloop exit";
        Restart = "always";
      };
    };

    environment.systemPackages = [ pkgs.bloop ];
  };
}
