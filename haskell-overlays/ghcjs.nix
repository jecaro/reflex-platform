{ haskellLib, nixpkgs, fetchFromGitHub, useReflexOptimizer, hackGet }:

with haskellLib;

self: super: {
  ghcWithPackages = selectFrom: self.callPackage (nixpkgs.path + "/pkgs/development/haskell-modules/with-packages-wrapper.nix") {
    inherit (self) llvmPackages;
#    haskellPackages = self;
    packages = selectFrom self;
    ${if useReflexOptimizer then "ghcLibdir" else null} = "${self.ghc.bootPackages.ghcWithPackages (p: [ p.reflex ])}/lib/${self.ghc.bootPackages.ghc.name}";
  };

  ghcjs-base = overrideCabal (self.callCabal2nix "ghcjs-base" (fetchFromGitHub {
    owner = "ghcjs";
    repo = "ghcjs-base";
    rev = "4560541fbab5b77ee34d0348ec04bb1dda8e5db3";
    sha256 = "0n7m46f32iass89ww4f2c126k4yqhfp95km7c9l6klsh93lp1i8p";
  }) {}) (drv: {
    jailbreak = true;
    doCheck = false; #TODO: This should be unnecessary

    patches = [
      (nixpkgs.fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/ghcjs/ghcjs-base/pull/107.patch";
        sha256 = "1ajsy3yl8mbrdvfw0xskpq3h51m4fphjz3dsvqa10g4hxl0kwcrq";
      })
    ];

    #TODO: This should be unnecessary
    preConfigure = (drv.preConfigure or "") + ''
      sed -i -e '/jsbits\/export.js/d' -e '/GHCJS\.Foreign\.Export/d' *.cabal
    '';
  });

  ghc = super.ghc // {
    withPackages = self.ghcWithPackages;
  };

  diagrams-lib = dontCheck super.diagrams-lib;
  linear = dontCheck super.linear;
  bytes = dontCheck super.bytes;

  hlint = null;
  hscolour = null;
  cabal-macosx = null;

  #TODO: The following packages' tests fail due to this error:
  # installHandler: not available for GHCJS
  tasty-quickcheck = dontCheck super.tasty-quickcheck;
  scientific = dontCheck super.scientific;
  uuid-types = dontCheck super.uuid-types;
  these = dontCheck super.these;

  #TODO: These look like real test failures:
  aeson = dontCheck super.aeson;
  # Also, pureMD5 is failing

  #TODO: The following packages' tests fail with errors like this:
  # Error: Cannot find module '/tmp/nix-build-hspec-discover-2.4.4.drv-0/hspec-discover-2.4.4/var h$currentThread = null;'
  hspec-core = dontCheck super.hspec-core;
  hspec-discover = dontCheck super.hspec-discover;
  hspec = dontCheck super.hspec;
  bifunctors = dontCheck super.bifunctors;
  base-compat = dontCheck super.base-compat;
  generic-deriving = dontCheck super.generic-deriving;
  newtype-generics = dontCheck super.newtype-generics;
  lens = disableCabalFlag (dontCheck super.lens) "test-properties";

  # doctest doesn't work on ghcjs, but sometimes dontCheck doesn't seem to get rid of the dependency
  doctest = builtins.trace "Warning: ignoring dependency on doctest" null;

  # These packages require doctest
  http-types = dontCheck super.http-types;

  #TODO: Fix this; it seems like it might indicate a bug in ghcjs
  parsec = dontCheck super.parsec;

  # Need newer version of colour for some reason.
  colour = dontCheck (super.colour.overrideAttrs (drv: {
    src = nixpkgs.fetchurl {
      url = "http://hackage.haskell.org/package/colour-2.3.4/colour-2.3.4.tar.gz";
      sha256 = "1sy51nz096sv91nxqk6yk7b92b5a40axv9183xakvki2nc09yhqg";
    };
  }));

  primitive = doJailbreak (self.callHackage "primitive" "0.6.3.0" {});
}
