# ComfyUI

## Description
This is a nix flake for running ComfyUI. There are some tricks to work around nix inablity to make changes in the source tree (as ComfyUI uses internal directories and files to configure itself and output the generated images).

## Installation
Make a directory where the files and directories that ComfyUI needs for configuration or outputs will be stored. The default is /var/ComfyUI/. Make sure it has full access rights.

i.e. `sudo mkdir /var/ComfyUI`, followed by `sudo chmod -R 777 /var/ComfyUI`.

If you want to place it somewhere else, update `flake.nix` (the `user_directory` key).

Run `nix build` in the directory containing the flake.

This will probably take a long time, we're talking hours on a good computer.

After this is done, run the command `result/bin/create_comfy_structure.sh`. This will create the necessary structure in the ComfyUI folder created above.

## Running
The structure doesn't contain anything. You need to download models and other things you need and store them in the appropriate directory.

To start, run `nix run` from the flakes directory, or run the shell script `comfyUI_start.sh`, stored in the 'result/bin' directory under the directory where the flake is stored.

## Development shell
If you want to test another version or do something to the source code of ComfyUI, run `nix develop` and all the necessary packages will be in your shell environment. The path to the source of CompyUI will be printed so you can run it (`python 'the path printed'/main.py`).

You can now download and run whatever version of ComfyUI you want (as long as it doesn't add to the prerequisites).

Please the Tip so make sure you don't need to compile everything again.

## Tip
When running `nix build` a directory named `result` will be generated. Don't remove this directory. If you do a cleanup (`nix-collect-garbage`) all the generated files will be deleted unless the directory is kept.

## Tip 2
If you are using Automatic1111 and you don't want to have your models in two places, update the file `extra_model_paths.yaml` in the ComfyUI directory.

## About this flake
Please note that I'm very new to nix. I have only used it for a few weeks so there might be some bad design decisions. It only work on x86_64-linux as that is my computer, feel free to test it on other systems (you will need to update the flake). It builds everything with CUDA support, so you need a good nvidia graphics card.

## License
Feel free to use and update this flake as you whish. As I don't own ComfyUI, make sure to follow their license.
