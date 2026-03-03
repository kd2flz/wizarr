{
  description = "Wizarr - Media Server User Invitation System";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        wizarr-pkg = pkgs.stdenv.mkDerivation {
          pname = "wizarr";
          version = "2026.2.1";
          
          src = pkgs.lib.cleanSource ./.;
          
          buildInputs = with pkgs; [
            python3
          ];
          
          installPhase = ''
            mkdir -p $out/lib/wizarr
            cp -r . $out/lib/wizarr
            
            mkdir -p $out/bin
            cat > $out/bin/wizarr <<'EOF'
            #!/bin/bash
            # Wizarr requires dependencies to be installed via uv first:
            #   cd $out/lib/wizarr
            #   uv sync
            #   uv run gunicorn --config gunicorn.conf.py --bind "0.0.0.0:$PORT" run:app
            echo "Wizarr requires dependencies to be installed first!"
            echo "Run: cd $out/lib/wizarr && uv sync"
            echo "Then run: cd $out/lib/wizarr && uv run gunicorn --config gunicorn.conf.py --bind '0.0.0.0:5690' run:app"
            EOF
            chmod +x $out/bin/wizarr
          '';
        };
      in
      {
        packages = {
          wizarr = wizarr-pkg;
          default = wizarr-pkg;
        };

        nixosModules.wizarr = import ./nix/module.nix {
          inherit pkgs;
          wizarrPkg = wizarr-pkg;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            uv
            nodejs
            python3
          ];
          
          shellHook = ''
            echo "Wizarr development environment"
            echo "Run 'uv sync' to install dependencies"
            echo "Run 'uv run gunicorn --config gunicorn.conf.py --bind 0.0.0.0:5690 run:app' to start"
          '';
        };
      }
    );
}
