{
  description = "Hetzner NixOS vps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere.url = "github:numtide/nixos-anywhere";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }:
  {
    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        disko.nixosModules.disko
        ./disko.nix
        ./configuration.nix
        ./users.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.users.root = import ./home.nix;
        }
      ];
    };
  };
}
