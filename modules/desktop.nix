{
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (config.modules.system) username;
  inherit (config.boot) isContainer;

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge;

  inherit (cfg) bloat;

  cfg = config.modules.desktop;
in
{
  options.modules.desktop = {
    bloat = mkEnableOption "GUI applications";
  };

  config = {
    # 支持 32bit 图形库
    hardware.graphics.enable32Bit = mkIf (pkgs.system == "x86_64-linux") true;

    programs = {
      hyprland.enable = mkIf (!isContainer) true;
      cdemu.enable = true;

      thunar = {
        enable = true;
        plugins = with pkgs.xfce; [
          thunar-volman
        ];
      };
    };

    # 输入法配置
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [ fcitx5-mozc fcitx5-chinese-addons fcitx5-rime rime-data ];
      };
    };

    # 启用多个桌面环境支持
    services = {
      # ✅ 启用 KDE Plasma 桌面环境
      desktopManager.plasma6.enable = true;
      displayManager.sddm.enable = true;
      displayManager.defaultSession = "plasma";

      # Hyprland 不需要额外注册 displayManager（SDDM 会自动检测）
      # 所以保持 Hyprland 安装即可

      udisks2 = {
        enable = true;
        mountOnMedia = true;
      };

      libinput = {
        touchpad = {
          naturalScrolling = true;
          accelProfile = "flat";
          accelSpeed = "0.75";
        };

        mouse.accelProfile = "flat";
      };

      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };

      tumbler.enable = true;
      gvfs.enable = true;
      gnome.gnome-keyring.enable = true;
      upower.enable = true;
    };

    environment.systemPackages = mkMerge [
      (mkIf bloat (
        with pkgs;
        [
          wineWowPackages.stagingFull
          winetricks
          mullvad-browser
          spek
          audacity
          gimp
          libreoffice
          element-desktop
          signal-desktop-bin
          qbittorrent
          popsicle
          satty
          srb2
          ringracers
          texliveFull
          sqlitebrowser
          qdiskinfo
          shotwell
          mkvtoolnix
          meld
          flacon
          vlc
          picard
          czkawka
          wvkbd
          rehex
        ]
      ))

      (with pkgs; [
        anki
        pulseaudio
        pavucontrol
        grim
        wl-clipboard-rs
        antimicrox
        libnotify
      ])
    ];
  };
}

