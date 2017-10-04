# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];


#  nix.nixPath = [ "/home/sziszi/git" "nixos-config=/etc/nixos/configuration.nix" ];
   nix.buildCores = 8;
   nixpkgs.overlays = [ (import /etc/nixos/overlays/rust-overlay.nix) ];


  hardware.cpu.amd.updateMicrocode = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    extraConfig = ''
     load-module module-combine-sink sink_name=combined
     set-default-sink combined 
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "kvm-amd" "tap" "virtio"];

  networking.hostName = "dinnye"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "en-latin9";
    defaultLocale = "en_US.UTF-8";
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
    KERNEL=="uinput", MODE="0660", GROUP="steam", OPTIONS+="static_node=uinput"
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="steam"
    KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0666"
  '';

  # Set your time zone.
  time.timeZone = "Europe/Budapest";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    avrdude
    axel
    clang
    cmake
    curl
    e2fsprogs
    edac-utils
    firefox
    fortune
    htop
    gcc
    gimp
    git
    gnumake
    go
    kodi
    lm_sensors
    lsof
    mc
    mpv
    mtr
    ncat
    neovim
    netcat
    ngrep
    nodejs
    p7zip
    pciutils
    pcmanfm
    pwgen
    latest.rustChannels.nightly.rust #Rust nightly
    scrot
    siege
    steam
    stress-ng
    tcpdump
    tdesktop
    termite
    traceroute
    usbutils
    vde2
    vim
    wget
    xorg.xkill
  ];

  nixpkgs.config.allowUnfree = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.dhcpd4 = {
    enable = true;
    interfaces = [ "tap0" ];
    extraConfig = 
      ''
        option subnet-mask 255.255.255.0;
        option broadcast-address 10.0.10.255; 
        option routers 10.0.10.1; 
        option domain-name-servers 10.10.10.10;
        option domain-name "home.liszy.hu";
        subnet 10.0.10.0 netmask 255.255.255.0 {
          range 10.0.10.3 10.0.10.30;
        }
      '';
  };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.localCommands = 
    ''
      ${pkgs.vde2}/bin/vde_switch -tap tap0 -mod 660 -group kvm -daemon
      sleep 1
      ${pkgs.iptables}/sbin/iptables -A FORWARD -s 10.0.10.0/24 -d 10.10.10.0/24 -j ACCEPT
      ${pkgs.iptables}/sbin/iptables -A FORWARD -s 10.10.10.0/24 -d 10.0.10.0/24 -j ACCEPT
      ip addr add 10.0.10.1/24 dev tap0
      ip link set dev tap0 up
    '';
  
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp11s0";
  networking.nat.internalInterfaces = [ "tap0" ];
  networking.nat.internalIPs = [ "10.0.10.0/24" ];

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.samsung-unified-linux-driver_1_00_37 ];
  };

  services.redshift = {
    enable = true;
    latitude = "46.25";
    longitude = "20.17";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "colemak";
#  #services.xserver.videoDrivers = [ "nvidiaBeta" ];
  services.xserver.videoDrivers = [ "amdgpu" ];
#  services.xserver.displayManager.sddm = {
#    enable = true;
#  };

#  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.windowManager.i3.enable = true;
  services.xserver.windowManager.i3.package = pkgs.i3-gaps;

#  services.mongodb.enable = true;
#  services.apcupsd = {
#    enable = true;
#    configText = 
#    ''
#      UPSTYPE usb
#      UPSCABLE usb
#      DEVICE
#      NISIP 127.0.0.1
#      BATTERYLEVEL 50
#      MINUTES 5
#    '';
#  };

  programs.fish.enable = true;
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark-gtk;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sziszi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "kvm" "steam" "audio" "wireshark"];
    uid = 1000;
    shell = pkgs.fish;
    home = "/home/sziszi";
    hashedPassword = "$6$sGSriuabHS$Mq/vK.czIq9vUh4eaGRIOVAk0ZgcX..LKACbc5W6xdPrZwgyDSJ6dx7tQ9UdRvaaMbYv63515B0FAMtNflcxC.";
  };
  users.groups = {
    kvm.members = [ "sziszi" ];
    audio.members = [ "sziszi" ];
    steam.members = [ "sziszi" ];
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "18.03";

}
