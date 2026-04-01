{
  description = "Bitcoin Core (Skrybit fork) — large transaction relay support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Override the nixpkgs bitcoind derivation with our custom source.
        # This gives us the same build infrastructure (cmake, dependencies)
        # but with the Skrybit fork's large-tx patches applied.
        bitcoind-large-tx = pkgs.bitcoind.overrideAttrs (old: {
          pname = "bitcoind-large-tx";
          version = "29.99.0";
          src = ./.;
          doCheck = false; # Fork modifies tx size limits; upstream tests expect default limits

          # Skrybit fork enables larger transaction relay:
          #   maxtxsize=4000000 (vs default 400000)
          #   minrelaytxfee=0.00000100
          #   mintxfee=0.00000010
          meta = (old.meta or {}) // {
            description = "Bitcoin Core with large transaction relay support (Skrybit fork)";
          };
        });
      in
      {
        packages.default = bitcoind-large-tx;
        packages.bitcoind-large-tx = bitcoind-large-tx;

        # Overlay for use in other flakes — replaces standard bitcoind
        overlays.default = final: prev: {
          bitcoind-large-tx = bitcoind-large-tx;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            pkg-config
            boost
            libevent
            zeromq
            sqlite
            python3
          ];
        };
      }
    );
}
