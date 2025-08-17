{
  modulesPath,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    # Minimize the build to produce a smaller closure
    "${modulesPath}/profiles/minimal.nix"
  ];
  # Allow unfree packages (needed for OnePlus firmware)
  nixpkgs.config.allowUnfree = true;

  # Disable boot control to avoid Ruby/Perl build issues during cross-compilation
  mobile.boot.boot-control.enable = false;
  services.openssh = {

    # Enable SSH server (essential for mobile device access)
    enable = true;
    settings.PermitRootLogin = "yes"; # For initial setup
    settings.PasswordAuthentication = true;
  }; # For initial setup

  # Hardcoded WiFi configuration
  networking = {
    networkmanager.enable = false;
    wireless = {
      enable = true;
      networks = {
        # Replace these with your actual WiFi credentials
        "NIKKEG-Mobile" = {
          psk = "givemeinternet";
        };
      };
    };
  };
  networking.hostName = "perseus";

  systemd.services.initialConfig =
    let
      copy-initial-config = pkgs.writeShellScript "copy-initial-config.sh" ''
        ${pkgs.coreutils}/bin/cp --no-preserve=mode ${inputs.self}/* /etc/nixos
      '';
    in
    {
      description = "Copy configuration into microvm";
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionDirectoryNotEmpty = "!/etc/nixos";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = copy-initial-config;
      };
    };

  services.avahi = {
    openFirewall = true;
    nssmdns4 = true; # Allows software to use Avahi to resolve.
    enable = true;
    publish = {
      userServices = true;
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.xserver.desktopManager.phosh = {
    enable = true;
    user = "default";
    group = "users";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  zramSwap.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    gnome-console # Terminal
    vim
    git
  ];

  users.users = {
    root.password = "default";
    default = {
      isNormalUser = true;
      password = "default";
      extraGroups = [
        "dialout"
        "feedbackd"
        "networkmanager"
        "video"
        "wheel"
      ];
    };
  };

  nix = {
    settings = {
      trusted-users = [
        "@wheel"
        "root"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      builders-use-substitutes = true;
      flake-registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}'';
      trust-tarballs-from-git-forges = true;
    };
    package = pkgs.nixVersions.latest;
    registry.nixpkgs.flake = lib.mkForce inputs.nixpkgs;
    registry.nixpkgs.to.path = lib.mkForce inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

}
