{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

        home-manager = {
            url = "github:/nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        stylix = {
            url = "github:danth/stylix";

            inputs = {
                nixpkgs.follows = "nixpkgs";
                home-manager.follows = "home-manager";
            };
        };
    };

    outputs =
        {self, nixpkgs, ... }:
        let
            inherit (nixpkgs.lib) nixosSystem genAttrs replaceStrings;
            inherit (nixpkgs.lib.filesystem) packagesFromDirectoryRecursive listFilesRecursive;

            forAllSystems =
                function:
                genAttrs [
                    "x86_64-linux"
                    "aarch64-linux"
                ] (system: function nixpkgs.legacyPackages.${system});

            nameOf = path: replaceStrings [ ".nix" ] [ "" ] (baseNameOf (toString path));
        in
        let
            recursiveImport = dir:
                let
                    files = builtins.filter
                        (file: builtins.match ".*\\.nix$" file != null)
                        (builtins.attrNames (builtins.readDir dir));
                in
                   builtins.listToAttrs (
                       map (file: {
                           name = builtins.replaceStrings [".nix"] [""] file;
                           value = import (dir + "/${file}");
                       }) files
                   );
        in
        {
            packages = forAllSystems (
                pkgs:
                    packagesFromDirectoryRecursive {
                        inherit (pkgs) callPackage;

                        directory = ./packages;
                    }
            );

            nixosModules = genAttrs (map nameOf (listFilesRecursive ./modules)) (
                name: import ./modules/${name}.nix
            );

            homeModules = genAttrs (map nameOf (listFilesRecursive ./home)) (name: import ./home/${name}.nix);

            #overlays = genAttrs (map nameOf (listFilesRecursive ./overlays)) (
            #    name: import ./overlays/${name}.nix
            #);
            overlays = if builtins.pathExists ./overlays then recursiveImport ./overlays else {};
            #checks = forAllSystems (
            #    pkgs:
            #    genAttrs (map nameOf (listFilesRecursive ./tests)) (
            #        name:
            #            import ./tests/${name}.nix {
            #                inherit self pkgs;
            #            }
            #    )
            #);

            nixosConfigurations = {
                 desktop = nixosSystem {
                    system = "x86_64-linux";
                    specialArgs.nix-config = self;
                    #modules = listFilesRecursive ./hosts/Desktop/configuration.nix;
                    modules = [ ./hosts/Desktop/configuration.nix ];
                };
            };

            formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
        };
}
