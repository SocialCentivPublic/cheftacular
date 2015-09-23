## 2.7.0

* Created [a businessbook cheftacular.yml](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/thebusinessbook.cheftacular.yml)

    * This config file serves as an example of how to utilize thebusinessbook cookbook with this gem.

* New cheftacular.yml keys

    * **backup_config:global_backup_role_name** (matcher config that is used to find the primary backup server)

    * **backup_config:global_backup_environ** (matcher config that is used to find the primary backup server)

    * **backup_config:global_backup_path** (location of the database backups directory on the server)

    * **backup_config:backup_dir_mode** (mode to write new backup directories with on `cft backups load`)

    * **backup_config:backup_load_command** (command to run to run a backup, can also be a path and args to a script)

    * **backup_config:db_primary_backup_path** (root directory of backups on database primaries)

    * **thebusinessbook:ALL_NESTED_KEYS** * (keys for thebusinessbook cookbook, **none of these are required for cheftacular itself**)

* Deleted cheftacular.yml keys

    * **backup_directory**

    * **backup_server**

    * **repositories:REPOSITORY_ROLE_NAME:backup_server**

* Added new functionality to `cft backups`, now supports `activate|deactivate|load|run` please see documentation for more details.

* Added new functionality to `cft tail [PATTERN_TO_MATCH]`, now supports the PATTERN_TO_MATCH argument to only send specific matching patterns to the terminal.

* Added functionality to `cft initialize_cheftacular_yml [thebusinessbook]`, it now can take an arg "thebusinessbook" to generate a businessbook cheftacular.yml

* Added new autocompiling bag: `default:environment_config` that stores the bags currently available in all chef environments.

* Added new command `cft cheftacular_config display|sync` that allows you to see compiled cheftacular.ymls and sync your own repository's one

    * This will create a new data bag called *cheftacular* under *default*, this bag will be updated with the cheftacular keys roughly once a day (sync is run automatically)

    * The precedence order will be application cheftacular change triggers a slack notification and a forced check against devops clients, devops clients *should* then update their local cheftacular.yml with the new keys as the chef-repo is the central repository for all the cheftacular.yml keys.

    * NOTE! Clients will **NOT** overwrite changed cheftacular.yml keys with their old keys! The keys must be manually updated in the cheftacular.yml file to the new values if slack / devops clients constantly get notifications about new keys!

* Added new command `cft clear_caches` that will wipe out all local caches for them to be repopulated on the next cheftacular run.

* Added new command `cft reset_bag BAG_NAME` that will destroy and recreate a bag with empty data. Only works on addresses, audit, cheftacular, environment_config, and node_roles bags to prevent unintended behavior and/or loss of critical data if backups for bag contents are not in place. Only works on DevOps clients.

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
