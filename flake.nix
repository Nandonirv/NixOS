{
  description = "NixOS Flake";
  
  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nixos-cosmic.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, nixpkgs, home-manager, nixos-cosmic, ... }: {
    
    nixosConfigurations.officepc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        
        # System Configuration
        ./nixos/configuration.nix
        
        # Enable Home Manager
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.matt = import ./home-manager/home.nix;
        }

        Enable Cosmic DE
       {
         nix.settings = {
           substituters = [ "https://cosmic.cachix.org/" ];
           trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
         };
       }
       nixos-cosmic.nixosModules.default
            
      ];
    };

  };
}
