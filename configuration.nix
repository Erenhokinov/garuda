{ inputs, pkgs, lib, config, ... }:
let
  customEdid = pkgs.runCommandNoCC "custom-100hz-edid" { } ''
    mkdir -p $out/lib/firmware/edid
    cp ${./100hz.bin} $out/lib/firmware/edid/100hz.bin
  '';
in
{
  imports = [
    inputs.spicetify-nix.nixosModules.default
    ./hardware-configuration.nix
  ];

  nixpkgs.config.problems.handlers.cups.broken = "warn";
  nixpkgs.config.allowUnfree = true;

  programs.command-not-found.enable = false;

  garuda.mokka.enable = true;
  garuda.gaming.enable = true;
  garuda.performance-tweaks.enable = true;
  garuda.btrfs-maintenance.enable = true;
    home-manager.users."garuda" = {
    imports = [ inputs.wayvibes.nixosModules.default ];

    services.wayvibes = {
      enable = true;
      soundpack = "${inputs.wayvibes}/soundpacks/nk-cream";
      volume = 2;
    };
  };

  garuda.impermanence.enable = true;
  garuda.impermanence.device = "/dev/disk/by-uuid/9f05d16e-0378-4643-93a6-7c4969435dd4";

  hardware.firmware = [ customEdid ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    kernelModules = lib.mkAfter [ "v4l2loopback" "uinput" "usbhid" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    extraModprobeConfig = "options usbhid mousepoll=1";

    kernelParams = [
      "usbhid.mousepoll=1"
      "drm.edid_firmware=eDP-1:edid/100hz.bin"
      "nowatchdog"
    ];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };

  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
      ];
      enabledCustomApps = with spicePkgs.apps; [
        newReleases
        ncsVisualizer
      ];
      enabledSnippets = with spicePkgs.snippets; [
        rotatingCoverart
        pointer
      ];

      theme = spicePkgs.themes.catppuccin;
      colorScheme = "frappe";
    };

  programs.gamemode.enable = true;
  programs.ydotool.enable = true;
  services.flatpak.enable = true;

    lib.mkForce = {
    zramSwap = {
                enable = true;
                priority = 100;
                memoryPercent = 150;
                swapDevices = 1;
                algorithm = "zstd";
              };
	      };

  systemd.services.cpu-freq-cap = {
    description = "Enable boost but cap CPU frequency at 3.1GHz";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "cpu-freq-cap" ''
        echo 1 > /sys/devices/system/cpu/cpufreq/boost
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
          echo performance > "$cpu/scaling_governor"
          echo 2900000 > "$cpu/scaling_max_freq"
        done
      '';
    };
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libGL
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.new_feature;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  environment.persistence."/persist".users."garuda".directories = [
    ".mozilla"                          
    ".config/vesktop"                   
    ".config/spotify"                   
    ".config/rustdesk"                  
    ".local/share/Steam/config"         
    ".local/share/Steam/userdata"       
    ".local/share/materialgram"         
    ".var/app/org.vinegarhq.Sober"       
    "Gaming"                            
  ];

  environment.systemPackages = with pkgs; [
    git
    ydotool
    rustdesk
    ffmpeg
    neovim
    pciutils
    osu-lazer
    materialgram
    inputs.prismlauncher-cracked.packages.${pkgs.stdenv.hostPlatform.system}.prismlauncher
    vesktop
    devin-desktop
    vscode
  ];

  networking.hostName = "garuda";
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users."garuda" = {
    isNormalUser = true;
    description = "garuda";
    extraGroups = [ "networkmanager" "wheel" "ydotool" "input" "video" ];
    hashedPassword = "$y$j9T$8TJmbz35wWXLfa/j/8zz51$0jxAdfZm.n45QF9ng11jw1RlbcJQxosORf1J/376doA";
  };

  system.stateVersion = "26.05";
}
