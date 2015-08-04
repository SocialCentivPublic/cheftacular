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

* Added new command `cft chef_server [restart|processes|memory]` that will allow a devops mode repo to interact directly with the chef server.

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
