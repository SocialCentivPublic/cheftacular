## 2.10.1

* Updating documentation and testing new self-updating feature.

## 2.10.0

* Added psuedo command, `cft flags` which is an alias to `cft arguments` and just outputs all the arguments / flags available

* Added `cft update_cheftacular` which is called in very specific situations to attempt to self-update the gem

    * This behavior is only triggered when the cheftacular.yml key: **self_update_repository** matches the current working directory

* New cheftacular.yml keys

    * **self_update_repository** (the repository cheftacular should try and update itself in, defaults to blank)

* Fix to sshkit commands hitting an error when an environment without a split_environment in the **run_list_environments** is run

* Reduced the number of concurrent deploys to 6 at once from 10

* Auditor now records current working directory if activated

* `cft migrate` no longer exits cheftacular when a nodejs or wordpress stack is attempted to migrate

## 2.9.2

* Tweak the slack message for detected deployment args to also include the environment.

* Removed calls in auditor for an audit cache, functionality is mostly redundant and has no practical use currently

* Modified auditor to also slack the currently executing command if *notify_on_command_execute* is set.

* Fixed issue with `check_cheftacular_yml_keys` setting some new slack defaults to booleans instead of blank strings

* Added all slack calls to the slack queue to be sent at the end of the run

* Added check in `slack` command to skip execution if there is no slack webhook set

* Added `cft version` and `cft -V` to quickly display the installed version of cheftacular.

* New cheftacular.yml keys

    * **slack:notify_on_command_execute** (send a slack notification if a cft command is executed)

## 2.9.1

* Fix issue with `cft` not returning all the available commands for a context.

## 2.9.0

* Updated all documentation to use the new structure, added short descriptions for commands that will be seen when only `cft` is entered.

* Removed `client-list` command. The only way to see the client list data is to use `cft client_list`.

* Removed auto-syncing on the cheftacular.yml configs. Now an actual sync ONTO the server's cheftacular configs will only occur with `cft cheftacular_config sync`.

    * Removed due to various issues regarding passive syncing on a version-controlled config file.

* Added much better error handling for `cft migrate` and `cft run`, these commands will now send slack notifications containing errors and log error output to the log bag.

* Fixed issue with several instances of not clearing caches correctly before run.

* Added checks if the gem is installed in the global gemset and will notify if out of date with a special command to update (rather than the bundle update command).

* **DigitalOcean v1 deprecation** NOTES

    * Added dependency on fog version 1.35 (>=) due to DigitalOcean deprecating their v1 api

    * DigitalOcean client_id key in cloud_providers is no longer needed

    * Several minor tweaks to the CloudInteractor class to handle new api changes

* Added new command `cft update_thecheftacularcookbook`, only useful if you need to do rapid iterating on this cookbook without wanting to berks every time

* New cheftacular.yml keys

    * **slack:notify_on_deployment_args** (send a slack notification if a repository is changing its deployment args)

* Deleted cheftacular.yml keys

    * **sync_application_cheftacular_yml** (due to the removal of automatic syncing, this key is unnecessary)

## 2.8.1

* Fixing issue with Cloudflare always creating new records with cloudflare turned on when the domain name does not match exactly.

* Fixing issue with `cft tail PATTERN_TO_MATCH` not allowing you to send in strings like "this is a broken request". Specifically you can now search for strings with spaces in them if it is enclosed by quotes.

* Added support for mongo databases to `cft db_console` which can now be aliased to `cft mongo`.

* `cft` itself will now return a list of commands

* `cft log` and other stateful commands will now check `-e|--except-role NAME_OF_ROLE`

## 2.8.0

* Added `-O | --deploy-org ORGANIZATION` flag, to be used with `cft deploy`. Please see the documentation for more details

* Changed the functionality of `-z|--unset-github-deploy-args` to deactivate both `-O` and `-Z` flags

* Slightly modified the layout of revisions stored in the config data bag.

* `cft check` now displays organizations for users utilizing TheCheftacularCookbook

* Minor fix to server bootstrapping to not fail when using `cft environment boot` to boot nodes with basic descriptors (just their node name)

* Major fixes to `cft backups load` and `cft backups run` is now `cft backups restore`.

## 2.7.2

* `cft check` now displays revisions for users utilizing TheCheftacularCookbook

## 2.7.1

* Fixed issue with `cft help COMMAND` not working on application clients due to having an incomplete cheftacular.yml (and being unable to check the server)

## 2.7.0

* Created [a TheCheftacularCookbook cheftacular.yml](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/thecheftacularcookbook.cheftacular.yml)

    * This config file serves as an example of how to utilize TheCheftacularCookbook cookbook with this gem.

* Implemented loose syncing between application cheftacular.ymls and DevOps cheftacular.ymls

    * The chef server stores the ENTIRE state of the current "cheftacular.yml", due to this, configurations seen in `cft cheftacular_config display` is what the server will utilize.

    * Because of this, users may now have "incomplete" cheftacular.ymls in repo directories, an example of this can be seen [here](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/application.cheftacular.yml)

        * It is not necessary to include the **repository's** top level key but it does allow for application developers to modify the chef environment if the [TheCheftacularCookbook](https://github.com/SocialCentivPublic/TheCheftacularCookbook) cookbook is being used and the key **sync_application_cheftacular_yml** is set to true.

* New cheftacular.yml keys

    * **backup_config:global_backup_role_name** (matcher config that is used to find the primary backup server)

    * **backup_config:global_backup_environ** (matcher config that is used to find the primary backup server)

    * **backup_config:global_backup_path** (location of the database backups directory on the server)

    * **backup_config:backup_dir_mode** (mode to write new backup directories with on `cft backups load`)

    * **backup_config:backup_load_command** (command to run to run a backup, can also be a path and args to a script)

    * **backup_config:db_primary_backup_path** (root directory of backups on database primaries)

    * **TheCheftacularCookbook:ALL_NESTED_KEYS** * (keys for TheCheftacularCookbook cookbook, **none of these are required for cheftacular itself**)

* Deleted cheftacular.yml keys

    * **backup_directory**

    * **backup_server**

    * **repositories:REPOSITORY_ROLE_NAME:backup_server**

* Added new functionality to `cft backups`, now supports `activate|deactivate|load|run` please see documentation for more details.

* Added new functionality to `cft tail [PATTERN_TO_MATCH]`, now supports the PATTERN_TO_MATCH argument to only send specific matching patterns to the terminal.

* Added functionality to `cft initialize_cheftacular_yml [application|TheCheftacularCookbook]` to allow for slightly customized generated cheftacular.ymls

* Added new autocompiling bag: `default:environment_config` that stores the bags currently available in all chef environments.

* Added new command `cft cheftacular_config display|sync` that allows you to see compiled cheftacular.ymls and sync your own repository's one

    * This will create a new data bag called *cheftacular* under *default*, this bag will be updated with the cheftacular keys roughly once a day (sync is run automatically)

    * The precedence order will be application cheftacular change triggers a slack notification and a forced check against devops clients, devops clients *should* then update their local cheftacular.yml with the new keys as the chef-repo is the central repository for all the cheftacular.yml keys.

    * NOTE! Clients will **NOT** overwrite changed cheftacular.yml keys with their old keys! The keys must be manually updated in the cheftacular.yml file to the new values if slack / devops clients constantly get notifications about new keys!

* Added new command `cft clear_caches` that will wipe out all local caches for them to be repopulated on the next cheftacular run.

* Added new command `cft reset_bag BAG_NAME` that will destroy and recreate a bag with empty data. Only works on addresses, audit, cheftacular, environment_config, and node_roles bags to prevent unintended behavior and/or loss of critical data if backups for bag contents are not in place. Only works on DevOps clients.

* Fixed regression with `-Z REVISION` flag not setting correctly and causing an error when used.

## 2.6.0

* Created [initial setup documentation](https://github.com/SocialCentivPublic/cheftacular/blob/master/doc/initial_setup.md)

* New cheftacular.yml keys

    * **route_dns_changes_via** (tells cheftacular to send dns changes to this provider instead of the preferred_cloud_option)

    * **node_name_separator** (On rackspace, can be anything except a space, on most other hosting sites, it must be a valid url character)

    * **cloud_authentication** (Use this key's children to store your authentication details for the various services you use)

    * **chef_server** (Use this key's children to utilize the `cft chef_server` command. Please run `cft help chef_server` for docs.)

    * _**chef_version**_ (The key **chef_client_version** has been renamed to _**chef_version**_ and now reflects the major version of chef being run)

    * **pre_install_packages** (Space delimited list of packages to install during a  node's initial setup process, can be blank)

    * Please check the [cheftacular.yml](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/cheftacular.yml) example file for documentation on new keys

* Added new command `cft chef_server restart|processes|memory` that will allow a devops mode repo to interact directly with the chef server.

* Added new command `cft initialize_cheftacular_yml` that will initialize a cheftacular.yml file or create a cheftacular.example.yml file if one already exists.

* `cft help`, `cft initialize_cheftacular_yml`, `cft arguments`, and `cft chef_server` will not talk directly with the chef server and have had their run times dramatically sped up

    * These commands will not fetch the state of the environment on their runs and thus will not be logged in the audit bag when run!

    * Created initialization_action class to define the commands that will bypass talking directly with the chef server via api calls

    * Heavily modified the initialization process that occurs every run to accomadate for initialization_actions that bypass chef server

* Added new options to `cft cloud`. The *sshkey* and *region* options have been added to interact with DigitalOcean. Please see `cft help cloud`.

* Added DigitalOcean support. Currently supported top level action(s) for the `cft cloud` command are **server, sshkey, region, flavor, image**.

* Added DNSimple support. Current supported top level action(s) for the `cft cloud` command are **domain**.

* Refactored all of the filesystem and caching logic into the FileSystem class from the Helper class.

* Added new command `cft check_cheftacular_yml_keys` to verify that cheftacular.ymls contain the correct keys after version 2.5.0 (this is run automatically)

* Added new command `cft arguments` that simply displays its documentation and exits. This command returns the same output as `cft help arguments`.

* Added new command `cft location_aliases` that will list the location aliases that can be used in the `cft file` command. These aliases are set in the cheftacular.yml under the **location_aliases** key.

* `cft cloud_bootstrap` has a rescue / retries in place for the first major ssh command. This is to prevent DigitalOcean servers that are not actually active from failing the entire process.

* `cft role_toggle NODE_NAME ROLE_NAME activate|deactivate` will toggle toggleable roles and deploy the new role to the server. Please run `cft help role_toggle` for more information.

* `cft list_toggleable_roles NODE_NAME` will list all toggleable roles for a node (roles that have a deactivation suffix).

## 2.5.0

* Fixed issue where most commands that interacted with servers still used the deploy user rather than using the *deploy_user* set in the cheftacular.yml

* Removed stateless command files for commands that are either superfluous, empty, or no current plans to implement.

* Created errors class for better handling of large errors in the code

* Implemented new command `file` that will be extremely useful for interacting with files on remote servers, supports `cat|display|edit|fetch|list|scp|tail|tail-f`.

## 2.4.1

* **Modified readable attributes in cheftacular.yml** Added **slack** key with nested keys **webhook** and **default channel**

* Logs bag will now store the exit status on deploys. Successful deploys will only store a "Successful Deploy" but failed deploys will store the last 100 lines of logs

* Saving to logs bag will now correctly be disabled when executing on nodes

* Created new "failed-deploy" log directory to store the output of failed deploys

* Fixed issue with running cft clean_cookbooks

* Improved slack command to allow it to accept arguments from other methods as well as being a standalone command

* Failed deploys will now send slack notifications if *slack:webhook* is set.
