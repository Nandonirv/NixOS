{ config, pkgs, ...}:

{
  home.username = "matt";
  home.homeDirectory = "/home/matt";

  home.packages = with pkgs; [
    neofetch
    steam
    google-chrome
  ];

  programs.home-manager.enable = true;
  programs.git = {
    userName = "Nandonirv";
    userEmail = "matthewknowles@live.fr";
  };

  home.stateVersion = "24.05";

}
