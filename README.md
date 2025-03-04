# Unity Editor Nix Flake

If you are like me then having layers of package management is annoying. I
should not be required to run a proprietary package manager when I have a
perfectly good one on my system.

## Usage

To open a project in the current directory with the default editor version use:
```sh
nix run github:jgresty/unity-nix -- -projectPath .
```

Starting with no arguments will prompt to create a new empty project.

To prevent the package being garbage collected, I recommend adding a devShell
to your project. Create a `flake.nix` file:
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    unity = {
      url = "github:jgresty/unity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      unity,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ unity.packages.${system}.unity_2022_3_22 ];
      };
    };
}
}
```
Then enter it with `nix develop` and launch the editor with `unity-editor`.


## Versions

Currently there is only version 2022.3.22f1 on x86_64-linux as that is the only
one I use. Contributions are welcome to add more.


## Limitations

This does not provide any way to manage licensing. A valid license is required
to use the editor, which must be generated using Unity Hub. Run Unity Hub from
nixpkgs to generate a license once, which will be written to your home
directory:
```sh
nix run nixpkgs#unityhub
```


## Disclaimer

"Unity", Unity logos, and other Unity trademarks are trademarks or registered
trademarks of Unity Technologies or its affiliates in the U.S. and elsewhere.

I am in no way affiliated with Unity Technologies.
