{
  description = "AttendanceTracker – Phoenix attendance kiosk dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs;
          [
            # BEAM toolchain (elixir pulls in erlang)
            elixir
            # Language server, picked up by editors (e.g. Zed) from $PATH
            elixir-ls
          ]
          ++ lib.optionals stdenv.isLinux [
            # for Phoenix live-reload file watching
            inotify-tools
          ];
      };
    });
  };
}
