{
  description = "memgraph nix support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    # For more information about the C/C++ infrastructure in nixpkgs: https://nixos.wiki/wiki/C
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pname = "memgraph"; # package name
        version = "3.10.x";
        src = ./.;
        nativeBuildInputs = with pkgs; [
          lld
          libllvm
          clang-tools
          clang
          cppcheck

          git # source code control
          # gcc
          gnumake
          cmake
          pkg-config # build system
          curl
          wget # for downloading libs
          libuuid
          jre25_minimal # required by antlr
          readline # for memgraph console
          python312
          openssl
          libseccomp
          netcat-gnu # tests are using nc to wait for memgraph
          iptables # for stress tests that simulate network failures
          curlFull
          sbcl # for custom Lisp C++ preprocessing
          mono
          zip
          unzip
          jdk25_headless
          jdk17_headless
          maven # for driver tests
          dotnetCorePackages.dotnet_8.sdk
          libmd

          go
          nodejs_24
          autoconf # for jemalloc code generation
          libtool # for protobuf code generation
          gsasl
          ninja
          # Pulsar dependencies
          # libnghttp2-dev libpsl-dev libkrb5-dev librtmp-dev libldap2-dev libidn2-dev libbrotli-dev libidn2-dev libssh-dev
          fakeroot
          debianutils
        ];
        buildInputs = with pkgs; [
          gnumake # generic build tools
          gnutar
          gzip
          bzip2
          xz # used for archive unpacking
          zlib # zlib library used for all builds
          # libexpat1
          # libipt2
          # libbabeltrace1
          # liblzma5
          python312 # for gdb
          curlFull # for cmake
          # libreadline8t64 # for cmake and llvm
          # libffi8
          # libxml2 # for llvm
          # libssl-dev # for libevent

          # clangd language server.
          clang-tools
        ];
      in
      {
        devShells.default = pkgs.mkShell.override { stdenv = pkgs.libcxxStdenv; } {
          inherit buildInputs nativeBuildInputs;
          LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib];
          CC="clang";
          CXX="clang++";
          shellHook = ''
            rm -Rf .toolchain
            mkdir -p .toolchain/bin
            tools=("llvm-ar" "llvm-ranlib" "llvm-nm" "llvm-objcopy" "llvm-objdump" "llvm-strip" "clang-scan-deps" "clang" "clang++" "clang-format" "lld")
            for t in ''${tools[@]}; do
              ln -s `which $t` .toolchain/bin/$t
            done
            export MG_TOOLCHAIN_ROOT=`pwd`/.toolchain
          '';

          # You can use NIX_CFLAGS_COMPILE to set the default CFLAGS for the shell
          #NIX_CFLAGS_COMPILE = "-g";
          # You can use NIX_LDFLAGS to set the default linker flags for the shell
          #NIX_LDFLAGS = "-L${lib.getLib zstd}/lib -lzstd";
        };

        # Pinned gcc: remain on gcc10 even after `nix flake update`
        #default = pkgs.mkShell.override { stdenv = pkgs.gcc10Stdenv; } {
        #  inherit buildInputs nativeBuildInputs;
        #};

        # Clang example:
        #default = pkgs.mkShell.override { stdenv = pkgs.clangStdenv; } {
        #  inherit buildInputs nativeBuildInputs;
        #};

        packages.default = pkgs.stdenv.mkDerivation {
          inherit
            buildInputs
            nativeBuildInputs
            pname
            version
            src
            ;
        };
      }
    );
}
