# Bin directory

## Table of Contents

  * [Purpose](#purpose)
  * [Content](#content)
  * [Tools](#tools)
    + [`add-module`](#-add-module)
  * [Make tools available](#make-tools-available)


## Purpose

This directory contains executable scripts and binary files used to simplify the modification of the project


## Content

As mentioned above the content of this directory is utilitary tools developed
by the BTDP team. Hence, every new tool shall be placed in it and be executable.

To make a tool executable use the following command:

```shell
chmod +x <tool-name>
```

_Exemple:_

```shell
chmod +x add-module
```


## Tools

### `add-module`

This tool is dedicated to create a new module in the project

Features:
- create a module from a template
- delete a module
- clean config files

_Usage:_
```shell
add-module
```
- The module must be created in the `'modules'` subdirectory of your project
- The module created by the commande is a template. So, it must be modified according to your requirements

As a result it will have a new module

_Exemples:_
> new module:
> ```shell
>add-module
>[info ] ............................................................... name of your custom module:
>modules/my-module
>[info ] ..................................................... type of your custom module (gae|gcr):
>gcr
>[info ] ....................... variation of your custom module (flask|restx|restx+alchemy|oauth2):
>flask
>[info ] .............................................. creation from template module-simple-tpl-gcr
>[info ] module created ................................................................... [PASSED]
> ```

#### Commande line:
```shell
NAME

add-module [OPTIONS] ...

OPTIONS:
    -h,--help : show this help text
    -t,--type : type of the module (gae| gcr)
    -v,--variation : variation of the module (flask|restx|restx+alchemy|oauth2)
    -i,--interactive : force interactive mode
    -f,--file : use a config file. When creating a module a configuration file (.config-module) is created in the prject-template/bin/modules/<project-name>/<module-name> directory
    --clean : delete the config file (.config-module)
    --clean_all: delete all config files
    --delete : delete a module ###WARNING: This command removes the selected folder. Be careful to have taken the right path

EXAMPLES:
    add-module modules/my-module -t gcr -v flask
        #This commande create a module named 'my-module' in the 'modules' subfolder, with type gcr and variation flask
    add-module -f .config-module
        #This commande create a module using the configuration in the .config-module file
    add-module modules/my-module -f .config-module
        #This commande create a module using the configuration in the .config-module file by overwriting the name of the module
    add-module modules/my-module --clean
        #This commande delete the config file for the module name 'my-module' of you current project
    add-module modules/my-module --delete
        #WARNING: This commande delete the module (folder) name 'my-module' in the subfolder 'modules'
```

## Make tools available

To make the tools available for execution the `PATH` variable must be updated as
follows:
```
export PATH="${PATH}:/path/to/project-template/bin"
```
To make it persistent, add this line in your ***.bashrc***
