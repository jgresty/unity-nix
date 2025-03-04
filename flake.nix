{
  description = "Unity3D game engine packaged as a nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      # cba supporting stuff I don't use
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = rec {
        unity_2022_3_22-unwrapped = pkgs.stdenv.mkDerivation {
          pname = "unity-editor";
          version = "2022.3.22f1";

          src = pkgs.fetchurl {
            url = "https://download.unity3d.com/download_unity/887be4894c44/LinuxEditorInstaller/Unity-2022.3.22f1.tar.xz";
            hash = "sha256-eE//d2kFHA9p7bA52NCUMeeuQASmSh20QDcJ3biKpQY=";
          };

          sourceRoot = ".";

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.wrapGAppsHook3
          ];
          # avoid double-wrapping
          dontWrapGApps = true;

          buildInputs = with pkgs; [
            eudev
            gdk-pixbuf
            glib
            gtk3
            libGL
            libnotify
            libxml2
            lttng-ust_2_12
            ocl-icd
            openssl
            xorg.libX11
            xorg.libXcursor
            xorg.libXrandr
            zlib
          ];

          # These come bundled
          autoPatchelfIgnoreMissingDeps = [
            "etccompress.so"
            "libcompress_bc7e.so"
            "libembree.so"
            "libfbxsdk.so"
            "libfreeimage-3.18.0.so"
            "libispc_texcomp.so"
            "libRadeonRays.so"
            "libRadeonRays.so.2.0"
            "libre2.so"
            "libre2.so.0"
            "libRL.so"
            "libtbbmalloc.so.2"
            "libtbb.so.2"
            "libumbraoptimizer64.so"
            "s3tcompress.so"
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/opt
            cp -r Editor $out/opt

            runHook postInstall
          '';

          # .net dynamically loads openssl, but does not mark it as required in
          # any compiled binary
          preFixup = ''
            files=(
              "il2cpp/build/deploy/libSystem.Security.Cryptography.Native.OpenSsl.so"
              "NetCoreRuntime/shared/Microsoft.NETCore.App/6.0.21/libSystem.Security.Cryptography.Native.OpenSsl.so"
              "Resources/Licensing/Client/libSystem.Security.Cryptography.Native.OpenSsl.so"
              "Tools/ilpp/Unity.ILPP.Runner/libSystem.Security.Cryptography.Native.OpenSsl.so"
              "Tools/ilpp/Unity.ILPP.Trigger/Unity.ILPP.Trigger"
              "Tools/netcorerun/libSystem.Security.Cryptography.Native.OpenSsl.so"
            )
            for toPatch in "''${files[@]}"
            do
              patchelf \
              --add-needed libssl.so \
              "$out/opt/Editor/Data/''$toPatch"
            done
          '';

          postFixup = ''
            makeWrapper $out/opt/Editor/Unity $out/bin/unity-editor \
              --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1 \
              "''${gappsWrapperArgs[@]}"
          '';

          meta = {
            homepage = "https://unity.com/";
            description = "Cross-platform game engine";
            platforms = [ "${system}" ];
            #license = pkgs.lib.licenses.unfree;
            sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
          };
        };

        # The Unity package manager copies files from BuiltInPackages into new
        # projects which preserve permissions, which then errors when it uses
        # them.
        unity_2022_3_22 = pkgs.writeShellScriptBin "unity-editor" ''
          TMPDIR=$(${pkgs.mktemp}/bin/mktemp --directory)
          cp -r ${unity_2022_3_22-unwrapped}/opt/Editor/Data/Resources/PackageManager/BuiltInPackages $TMPDIR
          chmod -R u+w $TMPDIR/BuiltInPackages

          ${pkgs.bubblewrap}/bin/bwrap \
          --dev-bind / / \
          --bind $TMPDIR/BuiltInPackages ${unity_2022_3_22-unwrapped}/opt/Editor/Data/Resources/PackageManager/BuiltInPackages \
          ${unity_2022_3_22-unwrapped}/bin/unity-editor "$@"

          rm -rf $TMPDIR
        '';

        default = unity_2022_3_22;
      };
    };
}
