{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-small;
          inherit (pkgs.texlive) latexmk pgf pgfplots tikzsymbols biblatex beamer;
          inherit (pkgs.texlive) silence appendixnumberbeamer fira fontaxes mwe;
          inherit (pkgs.texlive) noto csquotes babel helvetic transparent;
          inherit (pkgs.texlive) xpatch hyphenat wasysym algorithm2e listings;
          inherit (pkgs.texlive) lstbayes ulem subfigure ifoddpage relsize;
          inherit (pkgs.texlive) adjustbox media9 ocgx2 biblatex-apa wasy;
        };
      in
      {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              typos.enable = true;
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs;[
            bashInteractive
            # pdfpc # FIXME: broken on darwin
            typos
          ];

          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };
        packages.default = pkgs.stdenvNoCC.mkDerivation rec {
          name = "slides";
          src = self;
          buildInputs = with pkgs; [
            coreutils
            tex
            gnuplot
            biber
          ];
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath buildInputs}";
            export HOME=$(pwd)
            latexmk -pdflatex -shell-escape slides.tex
          '';
          installPhase = ''
            mkdir -p $out
            cp slides.pdf $out/
          '';
        };
      });
}
