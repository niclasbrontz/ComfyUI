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
      user_directory = "/var/ComfyUI/";

      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };

      comfy_patched = pkgs.runCommand "patch-comfy" {} ''
        set -e

        mkdir $out
        cp -rp ${comfyUi}/* $out
        mv $out/models $out/models-template
        chmod 777 -R $out/output
        rm -rf $out/output
        ln -s ${user_directory}/models $out/models
        ln -s ${user_directory}/output $out/output
        ln -s ${user_directory}/extra_model_paths.yaml $out/extra_model_paths.yaml
      '';

      comfy_start_script = pkgs.writeShellApplication {
        name = "comfyUi_start.sh";

        runtimeInputs = python_input;

        text = ''
          PIP_PREFIX=$(pwd)/_build/pip_packages
          export PIP_PREFIX
          export PYTHONPATH="$PIP_PREFIX/bin:$PATH"
          unset SOURCE_DATE_EPOCH

          python ${comfy_patched}/main.py
        '';
      };

      create_comfy_structure = pkgs.writeScriptBin "create_comfy_structure.sh" ''
        set -e

        mkdir ${user_directory}/models
        cp -rp ${comfy_patched}/models-template/* ${user_directory}/models/

        mkdir ${user_directory}/output

        cp ./extra_model_paths.yaml ${user_directory}/extra_model_paths.yaml

        chmod -R ugo+rwX ${user_directory}*
      '';

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

      python_input = with pkgs; [
        (python311.withPackages python-packages)
      ];
  
    in {
      packages."${system}".default = pkgs.symlinkJoin {
        name = "comfyUI";


        paths = [ comfy_start_script create_comfy_structure ];
      };

      apps."${system}".default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/comfyUi_start.sh";
      };

      devShells."${system}".default = pkgs.mkShell{
        name = "ComfyUI development";

        packages = with pkgs; [
          (python311.withPackages python-packages)
        ];

        shellHook = ''
          echo "Staring $name"

          echo "ComfyUI that is started if we run 'nix run' ${comfy_patched}"

          # Make the python virtual environment work
          export PIP_PREFIX=$(pwd)/_build/pip_packages
          export PYTHONPATH="$PIP_PREFIX/bin:$PATH"
          unset SOURCE_DATE_EPOCH
        '';

      };
    };
}
