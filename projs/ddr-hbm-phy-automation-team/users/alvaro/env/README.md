
# Common Environment files

All the scripts that are here are intentionally separated in files defined by their respective use or definitions.

To install those scripts in your `$HOME` directory you only need to run the script:
- [run.csh](run.csh)

It will create the `env` directory with the following scripts in your `$HOME` directory. --> $HOME/env
- config.csh
- modules.csh
- prompts.csh
  - prompts-runner.csh
- variables.csh
- .alias

Also, it will add a first version of .alias file and if you have one in your $HOME directory, it will append it too.
You can edit the .alias file that is in `$HOME/env/.alias.$USER` where `$USER` should have been change to your username.

The script will update and never remove your files. 

You can find your old file in the `env.$instance` folder or called as `.cshrc.user.$instance`, where instance would be the datetime formatted as `year-month-day-hour-minute`


## Terminal Autocompleter

Now you can start looking for old commands faster! Start typing the command and look on your history pressing the `key Up or Down` to move on the previous commands that started with the first part that you typed! It works exactly as `CTRL+R`

## The New Format

When you `start` a terminal, `refresh` it, or you call the alias `mystatus` you will be able to see the following information:
```
| USER: alvaro                   |                                                                     
| HOST: us01odcvde35982          |                                                                     
| P4Client: msip_cd_alvaro       |                                                                     
[ /remote/us01home50/haashim ]       
```
When you change directory, or if you are in a new different branch, the prompt will show the current location and git repository

```
[ /slowfs/dcopt103/alvaro/GitLab/ddr-hbm-phy-automation-team/ddr-utils-lay/dev/main/bin ]          
(alvaro_branch) 
```

The following symbol indicates you can type a new command:
```
⌲  
```

And you will see it in each new prompt till you call using the `dot key` ".", or something we you are change, it will show you the `current directory` and `git branch` that we are on.

You can create your own version using the prompt-runner instructions. You will have to create an external file in your $HOME.

## Modules

Please use `refresh` and you will see the following list of modules or latest versions:

``` 
  1) msip_shared_lib/2022.04                      12) msip_hipre_lef_utils/2022.09
  2) no_module_env/2022.10                        13) msip_hipre_netlist_utils/2023.01
  3) msip_shell_calex/2022.07                     14) msip_hipre_hspiceibiswaveform_utils/2022.11
  4) msip_lynx_hipre/latest                       15) msip_hipre_lib_utils/2023.01
  5) msip_shell_storage_utils/2023.01             16) msip_hipre_pkg_utils/2023.01
  6) msip_shell_lay_utils/2022.12                 17) msip_hipre_verilog_utils/2022.11
  7) msip_shell_msem_utils/2021.10                18) msip_hipre/2023.01
  8) cad_lookup/2022.03                           19) syn/2022.12-SP1
  9) msip_shell_uge_utils/2022.12                 20) git/2.30.0
 10) msip_hipre_gds_utils/2023.01                 21) vim/8.0
 11) msip_hipre_sim_utils/2023.01                 22) tar/1.32
 ```

## Alias

There are two different files in the env directory:
- `.alias`
- `.alias.$USER` (where user is your username)

The first one is common file, where you can find very useful aliases. Please feel free to play with them!
The second file is yours, and it will keep with your latest directory. You can add whatever you want here but that you don't want to share.

Check your list using the command `alias` in your terminal.

## Extras

All the scripts from `$GITLAB/ddr*/admin` can be called directly as `check_code.csh`. 