{
  description = "Include Gardener C++ Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Build tools
            cmake
            ninja
            pkg-config
            
            # C++ compiler and toolchain
            gcc
            clang
            gdb
            valgrind
            
            # Libraries
            boost
            
            # Development tools
            ccls                    # C++ language server
            clang-tools            # clang-format, clang-tidy, etc.
            cppcheck               # Static analysis
            bear                   # Generate compile_commands.json
            
            # Documentation
            doxygen
            graphviz               # For doxygen graphs
            
            # Python (for tests)
            python3
            python3Packages.pip
            
            # Utilities
            git
            gnumake
            tree
            ripgrep
            fd
          ];

          shellHook = ''
            echo "🌱 Include Gardener Development Environment"
            echo "=====================================."
            echo "Available tools:"
            echo "  - CMake: $(cmake --version | head -n1)"
            echo "  - GCC: $(gcc --version | head -n1)"
            echo "  - Clang: $(clang --version | head -n1)"
            echo "  - Boost: $(echo ${pkgs.boost.version})"
            echo "  - Python: $(python3 --version)"
            echo ""
            echo "Build commands:"
            echo "  mkdir -p build && cd build"
            echo "  cmake .."
            echo "  make -j$(nproc)"
            echo ""
            echo "Or with Ninja:"
            echo "  cmake -GNinja .."
            echo "  ninja"
            echo ""
            
            # Set up useful environment variables
            export CMAKE_EXPORT_COMPILE_COMMANDS=ON
            export BOOST_ROOT=${pkgs.boost}
            export CMAKE_PREFIX_PATH=${pkgs.boost}
          '';

          # Environment variables
          CMAKE_EXPORT_COMPILE_COMMANDS = "ON";
          BOOST_ROOT = "${pkgs.boost}";
          CMAKE_PREFIX_PATH = "${pkgs.boost}";
        };

        # Optional: Add a package definition for the project
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "include-gardener";
          version = "dev";
          
          src = ./.;
          
          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
            git
          ];
          
          buildInputs = with pkgs; [
            boost
            doxygen
            graphviz
            gtest
          ];
          
          configurePhase = ''
            mkdir -p build
            cd build
            cmake ..
          '';
          
          buildPhase = ''
            make -j$NIX_BUILD_CORES
          '';
          
          installPhase = ''
            mkdir -p $out/bin
            cp include_gardener $out/bin/
          '';
        };
      });
}
