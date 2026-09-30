{
  description = "NixOS + Garuda Mokka configuration";

  inputs = {
    prismlauncher-cracked.url = "github:Diegiwg/PrismLauncher-Cracked";
    wayvibes.url = "github:sahaj-b/wayvibes";
    wayvibes.inputs.nixpkgs.follows = "garuda/nixpkgs";
    garuda.url = "gitlab:garuda-linux/garuda-nix-subsystem/stable";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  };

  outputs = { garuda, wayvibes, ... }@inputs: {
    nixosConfigurations."garuda" = garuda.lib.garudaSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [ ./configuration.nix ];
    };
  };
}
