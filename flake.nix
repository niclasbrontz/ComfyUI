{
  description = "ComfyUI";

  nixConfig.bash-prompt = "Under development \($PWD\)$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

#    comfyUi = {
#      url = "github:comfyanonymous/ComfyUI";
#      flake = false;
#    };
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };

      python-packages = ps: with ps; [
        torch
        torchdiffeq
        torchvision
        torchaudio.overrideAttrs({cudaSupport = false;})
        torchsde
        einops
        transformers
        safetensors
        aiohttp
        accelerate
        pyyaml
        pillow
        scipy
        tqdm
        psutil
        pip
        gitpython
      ];

    in {
      devShells."${system}".default = pkgs.mkShell{
        name = "ComfyUI development";

        packages = with pkgs; [
          (python311.withPackages python-packages)
        ];

#        profile = ''export CUDA_PATH=${pkgs.cudatoolkit}'';

        shellHook = ''
          echo "Staring $name"

          # Make the python virtual environment work
          export PIP_PREFIX=$(pwd)/_build/pip_packages
          export PYTHONPATH="$PIP_PREFIX/bin:$PATH"
          unset SOURCE_DATE_EPOCH
        '';

      };
    };
}
