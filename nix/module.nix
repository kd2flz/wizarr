{ pkgs, wizarrPkg }:

{ config, lib, pkgs, ... }:

let
  cfg = config.services.wizarr;
in
{
  options.services.wizarr = {
    enable = lib.mkEnableOption "Wizarr - Media Server User Invitation System";

    package = lib.mkOption {
      type = lib.types.package;
      default = wizarrPkg;
      description = "The Wizarr package to use.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5690;
      description = "Port to listen on.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host to bind to.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/wizarr";
      description = "Directory where Wizarr stores its data.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall ports for Wizarr.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Environment variables to pass to Wizarr.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.wizarr = {
      description = "Wizarr - Media Server User Invitation System";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10";
        User = "wizarr";
        Group = "wizarr";
        StateDirectory = "wizarr";
        RuntimeDirectory = "wizarr";
        CacheDirectory = "wizarr";
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        ExecStart = "${cfg.package}/bin/wizarr";

        Environment = [
          "PUID=1000"
          "PGID=1000"
          "FLASK_ENV=production"
        ] ++ (lib.mapAttrsToList (name: value: "${name}=${value}") cfg.settings);
      };

      environment = {
        PORT = toString cfg.port;
        HOST = cfg.host;
      };
    };

    users.users.wizarr = {
      description = "Wizarr service user";
      group = "wizarr";
      isSystemUser = true;
      home = cfg.dataDir;
      useDefaultShell = true;
    };

    users.groups.wizarr = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 wizarr wizarr - -"
    ];

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
