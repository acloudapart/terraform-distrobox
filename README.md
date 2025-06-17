## To use this repo, first create the distrobox container for tool use

``` bash
distrobox create --name terraform --image ubuntu:24.04 --init-hooks "bash $HOME/devops/terraform-distrobox/provision.sh"
```