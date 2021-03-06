let
  rev = "1ad3f34a999a3e12dc3b8d8c74c7925a661395bf";
  pkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "17gd72bhg6d4v6gl0rd750p3kz8bx3frx3bj7smrfxp8mc0fy33m";
  };
  nixpkgs = import pkgs {
    config = {
      packageOverrides = pkgs_: with pkgs_; {
        haskell = haskell // {
          packages = haskell.packages // {
            ghc864-profiling = haskell.packages.ghc864.override {
              overrides = self: super: {
                mkDerivation = args: super.mkDerivation (args // {
                  enableLibraryProfiling = true;
                });
              };
            };
            ghc864 = haskell.packages.ghc864.override {
              overrides = self: super: {
                io-capture = haskell.lib.overrideCabal super.io-capture (old: rec {
                  doCheck = false;
                });
              };
            };
          };
        };
      };
    };
  };
in { compiler ? "ghc864", ci ? false }:

let
  inherit (nixpkgs) pkgs haskell;

  f = { mkDerivation, stdenv
      , mtl
      , syb
      , alex
      , base
      , Diff
      , lens
      , text
      , array
      , happy
      , hlint
      , hslua
      , HUnit
      , tasty
      , these
      , filepath
      , hashable
      , hedgehog
      , directory
      , haskeline
      , bytestring
      , containers
      , pretty-show
      , tasty-hunit
      , transformers
      , tasty-ant-xml
      , template-haskell
      , annotated-wl-pprint
      , unordered-containers
      , optparse-applicative
      , tasty-hedgehog
      }:
      let alex' = haskell.lib.dontCheck alex;
          happy' = haskell.lib.dontCheck happy;
          hlint' = haskell.lib.dontCheck hlint;
      in mkDerivation rec {
        pname = "amuletml";
        version = "0.1.0.0";
        src = if pkgs.lib.inNixShell then null else ./.;

        isLibrary = false;
        isExecutable = true;

        libraryHaskellDepends = [
          annotated-wl-pprint array base bytestring containers lens
          mtl pretty-show syb text transformers template-haskell hashable
          unordered-containers these
        ];

        executableHaskellDepends = [
          mtl text base lens bytestring containers pretty-show hslua
          haskeline optparse-applicative
        ];

        testHaskellDepends = [
          base bytestring Diff directory filepath hedgehog HUnit lens mtl
          pretty-show tasty tasty-hedgehog tasty-hunit text
          tasty-ant-xml
        ];

        libraryToolDepends = if ci then [ alex happy ] else [ alex' happy' ];
        buildDepends = libraryToolDepends ++ [ pkgs.cabal-install ] ++ [ hlint' ];

        homepage = "https://amulet.ml";
        description = "A functional programming language";
        license = stdenv.lib.licenses.bsd3;
      };

  haskellPackages = pkgs.haskell.packages.${compiler};

  drv = haskellPackages.callPackage f {};

in
  if pkgs.lib.inNixShell then drv.env else drv
