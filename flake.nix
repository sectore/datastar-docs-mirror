{
  description = "datastar-docs-mirrored";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in
      with pkgs; {
        devShells.default = mkShell {
          buildInputs = [
            python3
            uv
            curl
          ];

          shellHook = ''
            if [ ! -d ".venv" ]; then
              uv venv
            fi
            source .venv/bin/activate
            uv pip install --quiet trafilatura

            echo "datastar-docs-mirrored development environment"
            echo ""
            echo "Python:      $(python --version)"
            echo "trafilatura: $(trafilatura --version 2>&1 | head -1)"
            echo ""
            echo "Run: ./mirror-datastar-docs.sh"
          '';
        };
      });
}
