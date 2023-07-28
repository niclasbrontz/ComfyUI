{
  description = "ComfyUI";

  nixConfig.bash-prompt = "Under development \($PWD\)$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    comfyUi = {
      url = "github:comfyanonymous/ComfyUI";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, comfyUi }:
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
      packages."${system}".default = pkgs.stdenv.mkDerivation  {
        name = "ComfyUI";

        buildInputs = with pkgs; [
          (python311.withPackages python-packages)
        ];
        
#        unpackPhase = "cp ${./extra_model_paths.yaml} ${comfyUi}/extra_model_paths.yaml";
        unpackPhase = ":";

        installPhase = ''
          # An ugly hack to make the patchshebang hook run for the python stuff
          install -m755 -D ${./startComfyUI.py} $out/bin/startComfyUI.py
          echo "
          import sys

          sys.path.insert(1, '${comfyUi}')

          with open(\"${comfyUi}/main.py\") as f:
            exec(f.read())" >> $out/bin/startComfyUI.py

          # We have a few environment variables that needs to be specified
          echo "
          export PIP_PREFIX=$(pwd)/_build/pip_packages
          export PYTHONPATH="$PIP_PREFIX/bin:$PATH"
          unset SOURCE_DATE_EPOCH
          $out/bin/startComfyUI.py " > $out/bin/startComfyUI.sh

          chmod 755 $out/bin/startComfyUI.sh

        '';

        postPatch = "cp ${./extra_model_paths.yaml} ${comfyUi}/extra_model_paths.yaml";
      };

      apps."${system}".default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/startComfyUI.sh";
      };

      devShells."${system}".default = pkgs.mkShell{
        name = "ComfyUI development";

        packages = with pkgs; [
          (python311.withPackages python-packages)
        ];

#        profile = ''export CUDA_PATH=${pkgs.cudatoolkit}'';

        shellHook = ''
          echo "Staring $name"

          echo "${comfyUi}"

          # Make the python virtual environment work
          export PIP_PREFIX=$(pwd)/_build/pip_packages
          export PYTHONPATH="$PIP_PREFIX/bin:$PATH"
          unset SOURCE_DATE_EPOCH
        '';

      };
    };
}
