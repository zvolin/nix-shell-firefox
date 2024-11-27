{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    {
      devShells.aarch64-linux =
        let
          pkgs = import nixpkgs { system = "aarch64-linux"; };
          wasiSysRoot = pkgs.runCommand "wasi-sysroot" { } ''
            mkdir -p $out/lib/wasm32-wasi
            for lib in ${pkgs.pkgsCross.wasi32.llvmPackages.libcxx}/lib/*; do
              ln -s $lib $out/lib/wasm32-wasi
            done
          '';
        in
        with pkgs;
        {
          default = pkgs.mkShell {
            inputsFrom = [
              firefox
              firefox-devedition
              firefox-unwrapped
              geckodriver
            ];

            packages = [
              mercurial
              unzip

              llvm
              llvmPackages.bintools-unwrapped

              alsa-lib
              gnum4
              libpulseaudio
              pkg-config
              rust-cbindgen
            ];

            shellHook = # bash
              ''
                export CLANG_PATH="${llvmPackages.clang}/bin/clang"
                export LIBCLANG_PATH="${llvmPackages.clang.cc.lib}/lib"
                export WASM_CC="${pkgsCross.wasi32.stdenv.cc}/bin/${pkgsCross.wasi32.stdenv.cc.targetPrefix}cc"
                export WASM_CXX="${pkgsCross.wasi32.stdenv.cc}/bin/${pkgsCross.wasi32.stdenv.cc.targetPrefix}c++"
                unset AS

                # generate mozconfig
                cxxLib=$( echo -n ${stdenv.cc.cc}/include/c++/* )
                archLib=$cxxLib/$( ${stdenv.cc.cc}/bin/gcc -dumpmachine )

                cat > .mozconfig <<EOF
                ac_add_options --disable-bootstrap
                ac_add_options --with-wasi-sysroot="${wasiSysRoot}"
                ac_add_options --with-clang-path="$CLANG_PATH"
                ac_add_options --with-libclang-path="$LIBCLANG_PATH"
                mk_add_options AUTOCONF="${autoconf271}/bin/autoconf"
                export BINDGEN_CFLAGS="-cxx-isystem $cxxLib -isystem $archLib"
                export CC="${stdenv.cc}/bin/cc"
                export CXX="${stdenv.cc}/bin/c++"
                EOF
              '';
          };
        };
    };
}
