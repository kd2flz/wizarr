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
            uv
          ];
          
          installPhase = ''
            mkdir -p $out/lib/wizarr
            cp -r . $out/lib/wizarr
            
            mkdir -p $out/bin
            
            # Main startup script
            cat > $out/bin/wizarr <<'EOF'
            #!/bin/bash
            export FLASK_ENV=production
            SCRIPT_DIR="$(dirname "$0")"
            cd "$SCRIPT_DIR/../lib/wizarr"
            exec gunicorn \
              --config gunicorn.conf.py \
              --bind "0.0.0.0:$PORT" \
              --umask "007" \
              run:app
            EOF
            chmod +x $out/bin/wizarr
            
            # Migration script
            cat > $out/bin/wizarr-migrate <<'EOF'
            #!/bin/bash
            SCRIPT_DIR="$(dirname "$0")"
            cd "$SCRIPT_DIR/../lib/wizarr"
            exec python -m flask db upgrade
            EOF
            chmod +x $out/bin/wizarr-migrate
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
            echo "=========================================="
            echo "1. Install dependencies: uv sync"
            echo "2. Run database migrations: uv run flask db upgrade"
            echo "3. Start server: uv run gunicorn --config gunicorn.conf.py --bind 0.0.0.0:5690 run:app"
            echo ""
            echo "Note: Wizarr uses SQLite by default (wizarr.db)"
          '';
        };
      }
    );
}
