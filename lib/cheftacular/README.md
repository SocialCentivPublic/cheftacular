# Table of Contents for Cheftacular Commands

1. [Cheftacular Arguments and Flags](https://github.com/SocialCentivPublic/cheftacular/blob/master/lib/cheftacular/README.md#arguments-and-flags-for-cheftacular)

2. [Application Commands](https://github.com/SocialCentivPublic/cheftacular/blob/master/lib/cheftacular/README.md#commands-that-can-be-run-in-the-application-context)

3. [DevOps Commands](https://github.com/SocialCentivPublic/cheftacular/blob/master/lib/cheftacular/README.md#commands-that-can-only-be-run-in-the-devops-context)


## Arguments and flags for cheftacular

### Environment flags

1.  `-d|--dev-remote` toggles on dev-remote mode. Commands passed to cft will hit the devremote server(s) instead of the default server(s)

2.  `--env ENV` sets the environment commands hit to one you specify instead of the default one.

3.  `-p|--prod` toggles on production mode. Commands passed to cft will hit the production server(s) instead of the default server(s)

4.  `-Q|--qa` toggles on QA mode. Commands passed to cft will hit the QA server(s) instead of the default server(s)

5.  `-s|--staging` toggles on staging mode. Commands passed to cft will hit the staging server(s) instead of the default server(s)

6.  `--split-env SPLIT_ENV_NAME` sets the sub-environment to SPLIT_ENV_NAME. This only slightly affects certain commands.

7.  `-t|--test` toggles on test mode. Commands passed to cft will hit the test server(s) instead of the default server(s)

### General Flags

1.  `-a|--address ADDRESS` will force the command to only run against the specified address if it belongs to a node

2.  `-D|--debug` toggles on extremely verbose logging. Chef-client runs will generate ~10 times the amounts of logs including any additional effects that the `-v` flag will activate

3. `--no-logs` will make the cft commands not generate log files, you must still specify `-v` if you want output of most verbose commands to your terminal.

4.  `-n|--node-name NODE_NAME` will force the command to only run against the specified name if it belongs to a node

5.  `-q|--quiet` will make the cft commands only output information that is a direct result of the command being run

6.  `-r|--role-name ROLE_NAME` will force the command to only run against the specified role if it exists (this argument is generally not needed though it can be used to deploy a codebase for an application you're not currently cd'd into when running this as a gem)

7.  `-R|--repository NAME` will make the command run against a specific repository or context (automatically set for application mode)

8.  `-N|--search-node-name NODE_NAME` option will make this command return results that INCLUDE the NODE_NAME.

9.  `-L|--search-role-name ROLE_NAME` option will make this command return results that INCLUDE the ROLE_NAME.

10. `-E|--search-env-name ENV_NAME` option will make this command return results that have this environment.

11.  `-v|--verbose` toggles on verbose logging. All commands that write logs will also output to terminal AND write the logs.

### Help Related

1. `-h|--help` Displays the full readme and exits.

### Action Flags

1.  `-e|--except-role ROLE_NAME` will *prevent* any server with this role from being *deployed to* for the deploy command. Other commands will ignore this argument.

2.  `-z|--unset-github-deploy-args` will unset a custom revision specified in the arg below and make the codebase utilize the default.

3.  `-Z|--revision REVISION` will force the role you're deploying to to utilize the revision specified here. This can be a specific commit, a branch name or even a tag.

    1. Note: The system does not check if the revision exists, if you pass a non-existent revision no one will be able to deploy to that role until -Z with a correction revision or -z is passed.

4.  The `-O ORGANIZATION` flag can be used with TheCheftacularCookbook to set an *organization* your app can try deploying from, your git user needs access to these forks / organization(s).

    3.  The `-z|--unset-github-deploy-args` option will clear your current `-Z` and `-O` flags.


## Commands that can be run in the application context

1. `cft backups [activate|deactivate|fetch|load|restore]` this command sets the fetch_backups and restore_backups flags in your config data bag for an environment. These can be used to give application developers a way to trigger / untrigger restores in an environment

    1. `activate` will turn on automated backup running (turns on the flag for the env in the config bag).

    2. `deactivate` will turn off automated backup running.

    3. `fetch` will fetch the latest backup and drop it onto your machine. This argument accepts the --save-to-file LOCATION flag.

    4. `load` will fetch the latest backup from the production primary **if it doesn't already exist on the server** and run the _backup loading command_ to load this backup into the env.

    5. `restore` will simply just run the _backup loading command_ to load the latest backup onto the server. This command is REPOSITORY SENSITIVE, to restore a repo other than default, you must use the -R REPOSITORY flag.

    6. `status` will display the current state of the backups

    6. By default, the backups command will use the context of your current environment to trigger backup related commands.

2. `cft check [all|verify]` Checks the commits for all servers for a repository (for an environment) and returns them in a simple chart. Also shows when these commits were deployed to the server.

    1. If the node has special repository based keys from TheCheftacularCookbook, this command will also display information about the branch and organization currently deployed to the node(s).

    2. If the all argument is provided, all repositories will be checked for the current environment

    3. If the verify argument is provided, cft will attempt to see if the servers are using the latest commits. This is also aliased to `cft ch ve`

    4. Aliased to `cft ch`

3. `cft chef_server [restart|processes|memory]` this command can be used to query the chef server for stats if the cheftacular.yml has the chef_server key filled out. Useful for low resource chef-servers.

    1. `restart` restarts all chef processes on the chef server which may alleviate slow cheftacular load times for some users. (NOTE) do not run this command while the chef-server is performing actions or instability may result! Not tested for high volume chef servers.

    2. `processes` runs `ps aux` on the server to return the running processes and their stats.

    3. `memory` runs `free -m` on the server to return the current memory usage.

    4. NOTE! This command (and all arguments to it) bypass the normal environment loading like the help command.

    5. NOTE 2! Cheftacular does not (and will not) support accessing your chef server over ssh with password auth. If you have done this, you should feel bad and immediately switch ssh access to key authentication...

4. `cft cheftacular_config [diff|display|sync|overwrite]` this command Allows you to interact with your complete cheftacular configuration, the union of all repository's cheftacular.ymls. 

    1. `display` will show the current overall configuration for cheftacular.

    2. `diff` will show the difference between your current cheftacular.yml and the server's. Run automatically on a sync.

    3. `sync` will sync your local cheftacular yaml keys ONTO the server's keys. Will send a slack notification if slack is configured (the slack notification contains the diffed keys). The sync only occurs if there are CHANGES to the file.

    4. This command is aliased to `cc`

5. `cft cheftacular_yml_help KEY` this commandallows you to get help on the meaning of each key in your cheftacular.yml overall config.

    1. This command can also by run with `cft yaml_help`.

    2. To examine nested keys, you can use colons inbetween the keys like cloud_authentication:rackspace:email

6. `cft cleanup_logs [DIRECTORIES_TO_NOT_DELETE]` this command allows you to clear your local log files

    1. By default, this command will delete all the cheftacular directories in your log folder.

    2. This command supports a comma separated list of folders you don't want to delete.

7. `cft clear_caches` this command allows you to clear all of your local caches.

    1. This command will force you to refetch all previously cached chef server data on the next `cft` run.

8. `cft client_list` Allows you check the basic information for all the servers setup via chef. Shows the server's short name, its public ip address and roles (run_list) by default.

    1. `-v` option will make this command display the server's domain name, whether its password is stored on the chef server and what that password is.

    2. `-W|--with-priv` option will make this command display the server's local (private) ip address. This address is also the server's `local.<SERVER_DNS_NAME>`.

    3. `-s|--search-node-name NODE_NAME` option will make this command return results that INCLUDE the NODE_NAME.

    4. `-S|--search-role-name ROLE_NAME` option will make this command return results that INCLUDE the ROLE_NAME.

    5. `-E|--search-env-name ENV_NAME` option will make this command return results that have this environment.

    6. This command is aliased to `cft clients` and `cft cl`

9. `cft console` will create a console session on the first node found for a repository.

    1. Attempts to setup a console for the unique stack, stacks currently supported for console is only Rails.

    2. If there is a node in the repository set that has the role `preferred_console`, this node will come before others.

    3. Aliased to `cft co`

10. `cft db_console` will create a database console session on the first node found for a database stack in the current environment.

    1. This command is aliased to psql, typing `cft psql` will drop you into a rails stack database psql session.

    2. This command is also aliased to mongo, typing `cft mongo` will drop you into a mongodb mongo session.

11. `cft deploy [check|verify]` will do a simple chef-client run on the servers for a role. Logs of the run itself will be sent to the local log directory in the application (or chef-repo) where the run was conducted.

    1.  The `-Z REVISION` flag can be used with TheCheftacularCookbook to set a revision your app will run. 

    2.  The `-O ORGANIZATION` flag can be used with TheCheftacularCookbook to set an *organization* your app can try deploying from, your git user needs access to these forks / organization(s).

    3.  The `-z|--unset-github-deploy-args` option will clear your current `-Z` and `-O` flags.

    4.  This command will also run migrations on both an role's normal servers and its split servers if certain conditions are met (such as the role having a database, etc).

    5. The `-v|--verbose` option will cause failed deploys to output to the terminal window and to their normal log file. Useful for debugging.

    6. The `cft deploy check` argument will force a check run under the same environment as the initial deploy. This is also aliased to `cft d ch`

    7. The `cft deploy verify` argument will force a check AND verify run under the same environment as the initial deploy. This is also aliased to `cft d ve`

    8. Deploy locks (if set in the cheftacular.yml for the repo(s)) can be bypassed with the `--override-deploy-locks` flag

    9. Aliased to `cft d`

12. `cft disk_report` will fetch useful statistics from every server for every environment and output it into your log directory.

13. `cft environment boot|boot_without_deploy|destroy|destroy_raw_servers [SERVER_NAMES]` will boot / destroy the current environment

    1. `boot` will spin up servers and bring them to a stable state. This includes setting up their subdomains for the target environment.

    2. `destroy` will destroy all servers needed for the target environment

    3. `destroy_raw_servers` will destroy the servers without destroying the node data.

    4. `boot_without_deploy` will spin up servers and bring them to a state where they are ready to be deployed

    5. This command will prompt when attempting to destroy servers in staging or production. Additionally, only devops clients will be able to destroy servers in those environments.

    6. This command also accepts a *comma delimited list* of server names to boot / destroy instead of all the stored ones for an environment.

    7. This command works with all the flags that `cft deploy` works with, like -Z -z -O and so on.

    8. Aliased to `cft e`

14. `cft file NODE_NAME LOCATION_ALIAS MODE FILE_NAME` interacts with a file on the remote server

    1. `LOCATION_ALIAS` will be parsed as a path if it has backslash characters. Otherwise it will be parsed from your location_aliases hash in your cheftacular.yml

    2. `FILE_NAME` is the actual name (can also be additional path to the file) of the file to be interacted with. If no value is passed or the file does not exist in the LOCATION_ALIAS, the command will return the entries in LOCATION_ALIAS

        1. *NOTE! If you plan to use FILE_NAME as a path, do prepend the path with a / character!*

    3. `MODE` can be `cat|display|edit|fetch|list|scp|tail|tail-f`.

        1. The default mode is display, this is what will be run at LOCATION_ALIAS for FILE_NAME if no MODE is passed.

        2. `cat|display` will attempt to display the FILE_NAME listed to your terminal.

        3. `edit:TEXT_EDITOR` will attempt to edit the file with the TEXT_EDITOR listed. NOTE! This editor must be installed on the node you're accessing. If the editor is not present via a `which` command, the cft file command will say so.

        4. `fetch|scp` will attempt to fetch the FILE_NAME listed via SCP. This file is saved to /Users/louis/Code/chef-repo/log (based on your directory structure) under the same FILE_NAME as the remote file.

            1. The deploy must have access to said file without sudo!

        5. `list` the default behavior if the file does not exist. Otherwise must be manually called.

        6. `tail:NUMBER_OF_LINES` tails the file for the last `NUMBER_OF_LINES` lines, defaults to 500.

        7. `tail-f` enables continuous output of the file.

    4. `--save-to-file FILE_NAME option will save the output of `cat|display|tail` to a file on your local system instead of displaying the file to your terminal window.

        1. `--save-to-file FILE_PATH` can also be used in the `fetch` context to specify where exactly to save the file and what to name it as.

15. `cft fix_known_hosts [HOSTNAME]` this command will delete entries in your known_hosts file for all the servers that are in our system (ip addresses AND dns names)

    1. Passing in a hostname will make the command only remove entries with that hostname / ip specifically

    2. Aliased to `cft fkh`

16. `cft get_active_ssh_connections` will fetch the active ssh connections from every server and output it into your log directory.

    1. This command runs on all servers in an environment by default

    2. Packets can be examined more closely with `tcpdump src port PORT`

17. `cft get_haproxy_log` this command will generate a haproxy html file for the load balancer(s) associated with a repository in the log directory. Opening this log file in the browser will show the status of that haproxy at the time of the log. 

    1. In devops mode, this command will not do anything without the -R repository passed.

18. `cft get_log_from_bag <NODE_NAME-COMMAND_TYPE>` this command grabs the latest command run log from the data bags and saves it to your log directory. There are different types of logs saved per server depending on command.

19. `cft get_pg_pass ['clip']` command will output the current environment's pg_password to your terminal. Optionally you can pass in clip like `cft get_pg_pass clip` to have it also copy the pass to your clipboard.

20. `cft help COMMAND|MODE` this command returns the documentation for a specific command if COMMAND matches the name of a command. Alternatively, it can be passed `action|arguments|application|current|devops|stateless_action` to fetch the commands for a specific mode.Misspellings of commands will display near hits.

21. `cft list_toggleable_roles NODE_NAME` This command will allow you to see all toggleable roles for a node

22. `cft location_aliases` will list all location aliases listed in your cheftacular.yml. These aliases can be used in the `cft file` command.

    1. This command is aliased to `cft la`

23. `cft log` this command will output the last 500 lines of logs from every server set for the repository (can be given additional args to specify) to the log directory

    1.  `--nginx` will fetch the nginx logs as well as the application logs

    2.  `--full` will fetch the entirety of the logs (will fetch the entire nginx log too if `--nginx` is specified)

    3. `--num INTEGER` will fetch the last INTEGER lines of logs

        1. `-l|--lines INTEGER` does the exact same thing as `--num INTEGER`.

    4. `--fetch-backup` If doing a pg_data log, this will fetch the latest logs from the pg_data log directory for each database.

24. `cft migrate` this command will grab the first alphabetical node for a repository and run a migration that will hit the database primary server.

    1. Currently only supports rails stacks.

25. `cft pass NODE_NAME` will drop the server's sudo password into your clipboard. Useful for when you need to ssh into the server itself and try advanced linux commands

26. `cft role_toggle NODE_NAME ROLE_NAME activate|deactivate` This command will allow you to **toggle** roles on nodes without using `cft upload_nodes`

    1. This command uses your *role_toggling:deactivated_role_suffix* attribute set in your cheftacular.yml to toggle the role, it checks to see if the toggled name exists then sets the node's run_list to include the toggled role

    2. EX: `cft role_toggle api01 worker activate` will find the node api01 and attempt to toggle the worker role to on. If the node does NOT have the worker_deactivate role, then it will add it if *role_toggling:strict_roles* is set to **false**

        1. If *role_toggling:strict_roles* is set to true, then cheftacular would raise an error saying this role is unsettable on the node. On the other hand, if the node already has the worker_deactivaterole, then this command will succeed even if *strict_roles* is set.

    3. In case it isn't obvious, this command ONLY supports deactivation suffix roles like worker_deactivate or worker_off, with theiron counterpart just being the role itself, like "worker".

        1. Please run `cft list_toggleable_roles NODE_NAME` to get a list of your org's toggleable roles for a node.

    4. Aliased to `cft rt`

27. `cft run COMMAND [--all]` will trigger the command on the first server in the role. Can be used to run rake commands or anything else.

    1. `--all` will make the command run against all servers in a role rather than the first server it comes across. Don't do this if you're modifying the database with the command.

    2. EX: `cft run rake routes`

    3. EX: `cft run ruby lib/one_time_fix.rb staging 20140214` This command can be used to run anything, not just rake tasks. It prepends bundle exec to your command for rails stack repositories

    4. IMPORTANT NOTE: You cannot run `cft run rake -T` as is, you have to enclose any command that uses command line dash arguments in quotes like `cft run "rake -T"`

    5. Can also be used to run meteor commands and is aliased to `cft meteor`

28. `cft scale up|down [NUM_TO_SCALE]` will add (or remove) NUM_TO_SCALE servers from the server array. This command will not let you scale down below 1 server.

    1. In the case of server creation, this command takes a great deal of time to execute. It will output what stage it is currently on to the terminal but <b>you must not kill this command while it is executing</b>.A failed build may require the server to be destroyed / examined by a DevOps engineer.

29. `cft ssh NODE_NAME [exec] [command]` ssh you into the node name you are trying to access. It will also drop the server's sudo password into your clipboard. 

    1. `cft ssh NODE_NAME exec COMMAND` will execute a command on the server as root

30. `cft tail [PATTERN_TO_MATCH]` will tail the logs (return continuous output) of the first node if finds that has an application matching the repository running on it. Currently only supports rails stacks

    1. pass `-n NODE_NAME` to grab the output of a node other than the first.

    2. Workers and job servers change the output of this command heavily. Worker and job servers should tail their log to the master log (/var/log/syslog) where <b>all</b> of the major processes on the server output to. While the vast majority of this syslog will be relevant to application developers, some will not (usually firewall blocks and the like).

    3. if the `PATTERN_TO_MATCH` argument exists, the tail will only return entries that have that pattern rather than everything written to the file.

31. `cft update_cheftacular` this command attempts to update cheftacular to the latest version.

32. `cft verify` Checks to see if the servers for the current state are running the latest commits. 

    1. This command is functionally the same as `cft check verify`.

    2. This command is aliased to `cft ve`

33. `cft version` this command prints out the current version of cheftacular.

    1. Aliased to `cft v`


## Commands that can ONLY be run in the devops context

1. [NYI]`cft update_chef_client` attempts to update the chef-client of all nodes to the latest version. Should be done with caution and with the chef_server's version in mind.

2. `cft add_ssh_key_to_bag "<NEW SSH PUB KEY>" [SPECIFIC_REPOSITORY]` this command will add the given ssh key to the default authentication data bag. After this your server recipes should read the contents of the 'default' 'authentication' bag for the authorized_keys array.

    1. `SPECIFIC_REPOSITORY` is a special argument, if left blank the key will be placed in the authorized_keys array in the bag, otherwise it will be placed in the specific_authorized_keys hash under a key named for the repository that is passed. The script will error if SPECIFIC_REPOSITORY does not exist in the cheftacular.yml respositories hash. You can then use this data to give users selective ssh access to certain servers.

3. `cft check_cheftacular_yml_keys` allows you to check to see if your cheftacular yml keys are valid to the current version of cheftacular. It will also set your missing keys to their likely default and let you know to update the cheftacular.yml file.

4. `cft chef_bootstrap_from_queue` allows you to register a node in the chef system, remove any lingering data that may be associated with it and update the node's runlist if it has an entry in nodes_dir for its NODE_NAME.

    1. This command is part of the `cft full_bootstrap` command and cannot be called directly

5. `cft chef_server [restart|processes|memory]` this command can be used to query the chef server for stats if the cheftacular.yml has the chef_server key filled out. Useful for low resource chef-servers.

    1. `restart` restarts all chef processes on the chef server which may alleviate slow cheftacular load times for some users. (NOTE) do not run this command while the chef-server is performing actions or instability may result! Not tested for high volume chef servers.

    2. `processes` runs `ps aux` on the server to return the running processes and their stats.

    3. `memory` runs `free -m` on the server to return the current memory usage.

    4. NOTE! This command (and all arguments to it) bypass the normal environment loading like the help command.

    5. NOTE 2! Cheftacular does not (and will not) support accessing your chef server over ssh with password auth. If you have done this, you should feel bad and immediately switch ssh access to key authentication...

6. `cft cheftacular_config [diff|display|sync|overwrite]` this command Allows you to interact with your complete cheftacular configuration, the union of all repository's cheftacular.ymls. 

    1. `display` will show the current overall configuration for cheftacular.

    2. `diff` will show the difference between your current cheftacular.yml and the server's. Run automatically on a sync.

    3. `sync` will sync your local cheftacular yaml keys ONTO the server's keys. Will send a slack notification if slack is configured (the slack notification contains the diffed keys). The sync only occurs if there are CHANGES to the file.

    4. This command is aliased to `cc`

7. `cft cheftacular_yml_help KEY` this commandallows you to get help on the meaning of each key in your cheftacular.yml overall config.

    1. This command can also by run with `cft yaml_help`.

    2. To examine nested keys, you can use colons inbetween the keys like cloud_authentication:rackspace:email

8. `cft clean_cookbooks [force] [remove_cookbooks]` allows you to update the internal chef-repo's cookbooks easily. By default this script will force you to decide what to do with each cookbook individually (shows version numbers and whether to overwrite it to cookbooks or not).

    1. `force` argument will cause the downloaded cookbooks to *always* overwrite the chef-repo's cookbooks as long as the downloaded cookbook has a higher version number.

    2. If you would like to remove all the cookbooks on the chef server, run `knife cookbook bulk delete '.*' -p -c ~/.chef/knife.rb`

9. `cft cleanup_logs [DIRECTORIES_TO_NOT_DELETE]` this command allows you to clear your local log files

    1. By default, this command will delete all the cheftacular directories in your log folder.

    2. This command supports a comma separated list of folders you don't want to delete.

10. `cft clear_caches` this command allows you to clear all of your local caches.

    1. This command will force you to refetch all previously cached chef server data on the next `cft` run.

11. `cft client_list` Allows you check the basic information for all the servers setup via chef. Shows the server's short name, its public ip address and roles (run_list) by default.

    1. `-v` option will make this command display the server's domain name, whether its password is stored on the chef server and what that password is.

    2. `-W|--with-priv` option will make this command display the server's local (private) ip address. This address is also the server's `local.<SERVER_DNS_NAME>`.

    3. `-s|--search-node-name NODE_NAME` option will make this command return results that INCLUDE the NODE_NAME.

    4. `-S|--search-role-name ROLE_NAME` option will make this command return results that INCLUDE the ROLE_NAME.

    5. `-E|--search-env-name ENV_NAME` option will make this command return results that have this environment.

    6. This command is aliased to `cft clients` and `cft cl`

12. `cft cloud <FIRST_LEVEL_ARG> [<SECOND_LEVEL_ARG>[:<SECOND_LEVEL_ARG_QUERY>]*] ` this command handles talking to various cloud APIs. If no args are passed nothing will happen.

    1. `domain` first level argument for interacting with cloud domains

        1. `list` default behavior

        2. `read:TOP_LEVEL_DOMAIN` returns detailed information about all subdomains attached to the TOP_LEVEL_DOMAIN

        3. `read_record:TOP_LEVEL_DOMAIN:QUERY_STRING` queries the top level domain for all subdomains that have the QUERY_STRING in them.

        4. `create:TOP_LEVEL_DOMAIN` creates the top level domain on rackspace

        5. `create_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME:IP_ADDRESS[:RECORD_TYPE[:TTL]]` IE: `cft cloud domain create:mydomain.com:myfirstserver:1.2.3.4` will create the subdomain 'myfirstserver' on the mydomain.com domain.

        6. `destroy:TOP_LEVEL_DOMAIN` destroys the top level domain and all of its subdomains

        7. `destroy_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME` deletes the subdomain record for TOP_LEVEL_DOMAIN if it exists.

        8. `update:TOP_LEVEL_DOMAIN` takes the value of the email in the authentication data bag for your specified cloud and updates the TLD.

        9. `update_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME:IP_ADDRESS[:RECORD_TYPE[:TTL]]` similar to `create_record`.

    2. `server` first level argument for interacting with cloud servers, if no additional args are passed the command will return a list of all servers on the preferred cloud.

        1.  `list` default behavior

        2. `read:SERVER_NAME` returns all servers that have SERVER_NAME in them (you want to be as specific as possible for single matches)

        3. `create:SERVER_NAME:FLAVOR_ALIAS` IE: `cft cloud server "create:myserver:1 GB Performance"` will create a server with the name myserver and the flavor "1 GB Performance". Please see flavors section.

            1. NOTE! If you forget to pass in a flavor alias the script will not error! It will attempt to create a 512MB Standard Instance!

            2. NOTE! Most flavors have spaces in them, you must use quotes at the command line to utilize them!

        4. `destroy:SERVER_NAME` destroys the server on the cloud. This must be an exact match of the server's actual name or the script will error.

        5. `poll:SERVER_NAME` polls the cloud's server for the status of the SERVER_NAME. This command will stop polling if / when the status of the server is ACTIVE and its build progress is 100%.

        6. `attach_volume:SERVER_NAME:VOLUME_NAME[:VOLUME_SIZE[:DEVICE_LOCATION]]` If VOLUME_NAME exists it will attach it if it is unattached otherwise it will create it

            1. NOTE! If the system creates a volume the default size is 100 GB!

            2. DEVICE_LOCATION refers to the place the volume will be mounted on, a place like `/dev/xvdb`, from here it must be added to the filesystem to be used.

            3. If you want to specify a location, you must specify a size, if the volume already exists it wont be resized but will be attached at that location!

            4. If DEVICE_LOCATION is blank the volume will be attached to the first available slot.

        7. `detach_volume:SERVER_NAME:VOLUME_NAME` Removes the volume from the server if it is attached. If this operation is performed while the volume is mounted it could corrupt the volume! Do not do this unless you know exactly what you're doing!

        8. `list_volumes:SERVER_NAME` lists all volumes attached to a server

        9. `read_volume:SERVER_NAME:VOLUME_NAME` returns the data of VOLUME_NAME if it is attached to the server.

    3. `volume` first level argument for interacting with cloud storage volumes, if no additional args are passed the command will return a list of all cloud storage containers.

        1. `list` default behavior

        2. `read:VOLUME_NAME` returns the details for a specific volume.

        3. `create:VOLUME_NAME:VOLUME_SIZE` IE `cft rax volume create:staging_db:256`

        4. `destroy:VOLUME_NAME` destroys the volume. This operation will not work if the volume is attached to a server.

    4. `flavor` first level argument for listing the flavors available on the cloud service

        1. `list` default behavior

        2. `read:FLAVOR SIZE` behaves the same as list unless a flavor size is supplied.

            1. Standard servers are listed as XGB with no spaces in their size, performance servers are listed as X GB with a space in their size. If you are about to create a server and are unsure, query flavors first.

    5. `image` first level argument for listing the images available on the cloud service

        1. `list` default behavior

        2. `read:NAME` behaves the same as list unless a specific image name is supplied

    6. `region` first level argument for listing the regions available on the cloud service (only supported by DigitalOcean)

        1. `list` default behavior

        2. `read:REGION` behaves the same as list unless a specific region name is supplied

    7. `sshkey` first level argument for listing the sshkeys added to the cloud service (only supported by DigitalOcean)

        1. `list` default behavior

        2. `read:KEY_NAME` behaves the same as list unless a specific sshkey name is supplied

        3. `"create:KEY_NAME:KEY_STRING"` creates an sshkey object. KEY_STRING must contain the entire value of the ssh public key file. The command must be enclosed in quotes.

        4. `destroy:KEY_NAME` destroys the sshkey object

        5. `bootstrap` captures the current computer's hostname and checks to see if a key matching this hostname exists on the cloud service. If the key does not exist, the command attempts to read the contents of the ~/.ssh/id_rsa.pub file and create a new key with that data and the hostname of the current computer. Run automatically when creating DigitalOcean servers. It's worth noting that if the computer's key already exists on DigitalOcean under a different name, this specific command will fail with a generic error. Please check your keys.

13. `cft cloud_bootstrap NODE_NAME FLAVOR_NAME [DESCRIPTOR] [--with-dn DOMAIN]` uses a cloud api to create a server and attaches its DOMAIN_NAME to the TLD specified for that environment (IE: example-staging.com for staging)

    1. If no DOMAIN_NAME is supplied it will use the node's NODE_NAME (IE: api01.example-staging.com)

    2. If the `--with-dn DOMAIN` argument is supplied the rax api will attempt to attach the node to the top level domain instead of the default environment one. This tld must be attached to the cloud service. This also allows you to attach to custom subdomains instead of NODE_NAME.ENV_TLD

    3. `cft cloud_bootstrap myserver "1 GB Performance" --with-dn myserver.example-staging.com` The "1 GB Perfomance" does not have to be exact, "1 GB" will match "1 GB Performance" and "1GB" will match "1GB Standard" (for rackspace flavors)

    4. DESCRIPTOR is used as an internal tag for the node, if left blank it will become the name of the node. It is recommended to enter a custom repository-dependent tag here to make nodes easier to load-balance like "lb:[CODEBASE_NAME]"

    5. Aliased to `cft cb`

14. `cft cloud_bootstrap_from_queue` uses a cloud api to create several servers. It is a wrapper around the cloud_bootstrap command that tries to queue server creation.

    1. This command cannot be called directly and can only be utilized from `cft environment boot`

15. `cft compile_audit_log [clean]` compiles the audit logs in each environment's audit data bag a audit-log-CURRENTDAY.md file in the log folder of the application. Bear in mind that the bag can only hold 100K bytes and will need to have that data removed to store more than that.

16. `cft compile_readme` compiles all documentation methods and creates a README.md file in the log folder of the application.

17. `cft create_git_key ID_RSA_FILE [OAUTH_TOKEN]` This command will update the default/authentication data bag with new credentials. The [ID_RSA_FILE](https://help.github.com/articles/generating-ssh-keys) needs to exist beforehand.

    1. This command will upload both the private and public key to the data bag. The public key should be the one that matches the github user for your deployment github user.

    2. `OAUTH_TOKEN` *must* be generated by logging into github and generating an access token in the account settings -> applications -> personal access tokens

    3. NOTE! The ID_RSA_FILE should be in your .chef folder in the root of your home directory!

18. `cft disk_report` will fetch useful statistics from every server for every environment and output it into your log directory.

19. `cft environment boot|boot_without_deploy|destroy|destroy_raw_servers [SERVER_NAMES]` will boot / destroy the current environment

    1. `boot` will spin up servers and bring them to a stable state. This includes setting up their subdomains for the target environment.

    2. `destroy` will destroy all servers needed for the target environment

    3. `destroy_raw_servers` will destroy the servers without destroying the node data.

    4. `boot_without_deploy` will spin up servers and bring them to a state where they are ready to be deployed

    5. This command will prompt when attempting to destroy servers in staging or production. Additionally, only devops clients will be able to destroy servers in those environments.

    6. This command also accepts a *comma delimited list* of server names to boot / destroy instead of all the stored ones for an environment.

    7. This command works with all the flags that `cft deploy` works with, like -Z -z -O and so on.

    8. Aliased to `cft e`

20. `cft file NODE_NAME LOCATION_ALIAS MODE FILE_NAME` interacts with a file on the remote server

    1. `LOCATION_ALIAS` will be parsed as a path if it has backslash characters. Otherwise it will be parsed from your location_aliases hash in your cheftacular.yml

    2. `FILE_NAME` is the actual name (can also be additional path to the file) of the file to be interacted with. If no value is passed or the file does not exist in the LOCATION_ALIAS, the command will return the entries in LOCATION_ALIAS

        1. *NOTE! If you plan to use FILE_NAME as a path, do prepend the path with a / character!*

    3. `MODE` can be `cat|display|edit|fetch|list|scp|tail|tail-f`.

        1. The default mode is display, this is what will be run at LOCATION_ALIAS for FILE_NAME if no MODE is passed.

        2. `cat|display` will attempt to display the FILE_NAME listed to your terminal.

        3. `edit:TEXT_EDITOR` will attempt to edit the file with the TEXT_EDITOR listed. NOTE! This editor must be installed on the node you're accessing. If the editor is not present via a `which` command, the cft file command will say so.

        4. `fetch|scp` will attempt to fetch the FILE_NAME listed via SCP. This file is saved to /Users/louis/Code/chef-repo/log (based on your directory structure) under the same FILE_NAME as the remote file.

            1. The deploy must have access to said file without sudo!

        5. `list` the default behavior if the file does not exist. Otherwise must be manually called.

        6. `tail:NUMBER_OF_LINES` tails the file for the last `NUMBER_OF_LINES` lines, defaults to 500.

        7. `tail-f` enables continuous output of the file.

    4. `--save-to-file FILE_NAME option will save the output of `cat|display|tail` to a file on your local system instead of displaying the file to your terminal window.

        1. `--save-to-file FILE_PATH` can also be used in the `fetch` context to specify where exactly to save the file and what to name it as.

21. `cft fix_known_hosts [HOSTNAME]` this command will delete entries in your known_hosts file for all the servers that are in our system (ip addresses AND dns names)

    1. Passing in a hostname will make the command only remove entries with that hostname / ip specifically

    2. Aliased to `cft fkh`

22. `cft full_bootstrap_from_queue` This command performs both ubuntu_bootstrap and chef_bootstrap.

    1. This command is run by `cft cloud_bootstrap` and should not be run on its own.

23. `cft get_active_ssh_connections` will fetch the active ssh connections from every server and output it into your log directory.

    1. This command runs on all servers in an environment by default

    2. Packets can be examined more closely with `tcpdump src port PORT`

24. `cft get_haproxy_log` this command will generate a haproxy html file for the load balancer(s) associated with a repository in the log directory. Opening this log file in the browser will show the status of that haproxy at the time of the log. 

    1. In devops mode, this command will not do anything without the -R repository passed.

25. `cft get_log_from_bag <NODE_NAME-COMMAND_TYPE>` this command grabs the latest command run log from the data bags and saves it to your log directory. There are different types of logs saved per server depending on command.

26. `cft get_pg_pass ['clip']` command will output the current environment's pg_password to your terminal. Optionally you can pass in clip like `cft get_pg_pass clip` to have it also copy the pass to your clipboard.

27. `cft help COMMAND|MODE` this command returns the documentation for a specific command if COMMAND matches the name of a command. Alternatively, it can be passed `action|arguments|application|current|devops|stateless_action` to fetch the commands for a specific mode.Misspellings of commands will display near hits.

28. `cft initialize_cheftacular_yml [application|TheCheftacularCookbook]` will create a cheftacular.yml file in your config folder (and create the config folder if it does not exist). If you already have a cheftacular.yml file in the config folder, it will create a cheftacular.example.yml file that will contain the new changes / keys in the latest cheftacular version.

    1. If `TheCheftacularCookbook` is passed, the generated cheftacular.yml file will include the additional TheCheftacularCookbook keys.

    2. If `application` is passed, the generated cheftacular.yml file will look like one you could use in an application directory.

29. `cft initialize_data_bag_contents ENVIRONMENT_NAME` will ensure the data bags always have the correct structure before each run. This command is run every time the gem is started and if called directly, will exit after completion.

30. `cft knife_upload [force]` will resync the chef-server with the local chef-repo code. This command is analog for `knife upload /`

    1. The force option will add the force option to knife upload.

    2. Utilize `knife cookbook upload -a -V --cookbook-path ./cookbooks` if this command gives you trouble

    3. Aliased to `cft ku`

31. `cft list_toggleable_roles NODE_NAME` This command will allow you to see all toggleable roles for a node

32. `cft location_aliases` will list all location aliases listed in your cheftacular.yml. These aliases can be used in the `cft file` command.

    1. This command is aliased to `cft la`

33. `cft pass NODE_NAME` will drop the server's sudo password into your clipboard. Useful for when you need to ssh into the server itself and try advanced linux commands

34. `cft reinitialize IP_ADDRESS NODE_NAME` will reconnect a server previously managed by chef to a new chef server. The node name MUST MATCH THE NODE'S ORIGINAL NODE NAME for the roles to be setup correctly.

35. `cft remove_client NODE_NAME [destroy]` removes a client (and its node data) from the chef-server. It also removes its dns records from the cloud service (if possible). This should not be done lightly as you will have to wipe the server and trigger another chef-client run to get it to register again. Alternatively, you can run `cft reinitialize IP_ADDRESS NODE_NAME as well.

    1. `destroy` deletes the server as well as removing it from the chef environment.

    2. This command is aliased to `cft remove_node` and `cft rc`

36. `cft replication_status` will check the status of the database master and slaves in every environment. Also lists how far behind the slaves are from the master in milliseconds.

37. `cft reset_bag BAG_NAME` this command allows you to reset a data bag item to an empty state. Run this on full data bags to clear them out. 

38. `cft restart_swap` will restart the swap on every server that doesn't have swap currently on. Useful if you notice servers with no swap activated from `cft disk_report`

    1. There is no risk in running this command. Sometimes swap doesnt reactivate if the server was rebooted and this command fixes that.

39. `cft role_toggle NODE_NAME ROLE_NAME activate|deactivate` This command will allow you to **toggle** roles on nodes without using `cft upload_nodes`

    1. This command uses your *role_toggling:deactivated_role_suffix* attribute set in your cheftacular.yml to toggle the role, it checks to see if the toggled name exists then sets the node's run_list to include the toggled role

    2. EX: `cft role_toggle api01 worker activate` will find the node api01 and attempt to toggle the worker role to on. If the node does NOT have the worker_deactivate role, then it will add it if *role_toggling:strict_roles* is set to **false**

        1. If *role_toggling:strict_roles* is set to true, then cheftacular would raise an error saying this role is unsettable on the node. On the other hand, if the node already has the worker_deactivaterole, then this command will succeed even if *strict_roles* is set.

    3. In case it isn't obvious, this command ONLY supports deactivation suffix roles like worker_deactivate or worker_off, with theiron counterpart just being the role itself, like "worker".

        1. Please run `cft list_toggleable_roles NODE_NAME` to get a list of your org's toggleable roles for a node.

    4. Aliased to `cft rt`

40. `cft rvm [COMMAND] [ADDITIONAL_COMMANDS]*` will run rvm commands on the remote servers. Output from this command for each server will go into your rvm directory under the log directory. Please refer to [the rvm help page](https://rvm.io/rvm) for more information on rvm commands.

    1. When no commands are passed, rvm will just run `rvm list` on each server on all servers in the current environment.

    2. When `list|list_rubies` is passed, rvm will run `rvm list rubies` on all servers in the current environment.

    3. When `install RUBY_TO_INSTALL` is passed, rvm will attempt to install that ruby on each system in the current environment. It is a good idea to use strings like ruby-2.2.1

    4. `run [RVM_COMMANDS]+` will run the rest of the arguments as a complete rvm command. An example of this being `cft rvm run gemset update`. This will run on all servers in the current environment.

    5. `all_environments [RVM_COMMANDS]+` will run the rest of the arguments as a complete rvm command *on all of the servers in every environment*.

    6. `test [RVM_COMMANDS]+` will run the rest of the arguments as a complete rvm command with scoping. By default, rvm commands run against all servers in the environment but with test you can pass -n NODE_NAME  or -r ROLE_NAME flags to scope the servers the rvm command will be run on. Useful for testing.

    7. `upgrade_rvm` will run `rvm get stable --auth-dotfiles` on all servers for the current environment. It will also check and attempt to upgrade pre 1.25 installations of RVM to 1.26+ (which requires a GPG key).

41. `cft server_update [restart]` allows you to force update all nodes' packages for a specific environment. This should be done with caution as this *might* break something.

    1. `cft server_update restart` will prompt to ask if you also want to restart all servers in a rolling restart. This should be done with extreme caution and only in a worst-case scenario.

42. `cft service [COMMAND] [SERVICE]` will run service commands on remote servers. This command only runs on the first server it comes across. Specify others with -n NODE_NAME.

    1. When no commands are passed, the command will list all the services in the /etc/init directory

    2. When `list` is passed, the above behavior is performed 

    3. When `restart|stop|start SERVICE` is passed, the command will attempt to restart|stop|start the service if it has a .conf file on the remote server in the /etc/init directory.

43. `cft slack "MESSAGE" [CHANNEL]` will attempt to post the message to the webhook set in your cheftacular.yml. Slack posts to your default channel by default but if the CHANNEL argument is supplied the message will post there.

    1. NOTE: To prevent confusing spam from many possible sources, the username posted to slack will always be *Cheftacular*. This can be overloaded in the StatelessAction method "slack" but this is not recommended.

    2. Remember, if you have auditing turned on in your cheftacular.yml, you can track who sends what to slack.

44. `cft ssh NODE_NAME [exec] [command]` ssh you into the node name you are trying to access. It will also drop the server's sudo password into your clipboard. 

    1. `cft ssh NODE_NAME exec COMMAND` will execute a command on the server as root

45. `cft test_env [TARGET_ENV] boot|destroy` will create (or destroy) the test nodes for a particular environment (defaults to staging, prod split-envs can be set with `-p`). Please read below for how TARGET_ENV works

    1. TARGET_ENV changes functionality depending on the overall (like staging / production) environment

        1. In staging, it cannot be set and defaults to split (splitstaging).

        2. In production, it can be splita, splitb, splitc, or splitd.

        3. The default tld used should change depending on which environment you are booting / destroying. This is set in the environment's config data bag under the tld key

46. `cft ubuntu_bootstrap_from_queue` This command will bring a fresh server to a state where chef-client can be run on it via `cft chef-bootstrap`. It should be noted that it is in this step where a server's randomized deploy_user sudo password is generated.

47. `cft update_cheftacular` this command attempts to update cheftacular to the latest version.

48. `cft update_cloudflare_dns_from_cloud [skip_update_tld]` command will force a full dns update for cloudflare. 

    1. It will ensure all the subdomain entries are correct (based on the contents of the addresses data bag) and update them if they are not. It will also create the local subdomain for the entry as well if it does exist and point it to the correct private address for an environment.

    2. This command will also ensure any dns records on your cloud are also migrated over to cloudflare as well. This also includes the reverse in the event you would like to turn off cloudflare.

    3. The argument `skip_update_tld` will stop the long process of checking and updating all the server domains _before_ cloudflare is updated. Only skip if you believe your domain info on your cloud is accurate.

49. `cft update_cookbook [COOKBOOK_NAME] [INSTALL_VERSION|local]` allows you to specifically update a single cookbook

    1. This command passed with no arguments will update TheCheftacularCookbook

    2. If the 2nd argument is local, the command will drop a local version of the cookbook onto your chef-repo

    3. Aliased to `cft uc`

50. `cft update_split_branches` will perform a series of git commands that will merge all the split branches for your split_branch enabled repositories with what is currently on master and push them.

    1. Repository must be set with `-R REPOSITORY_NAME` for this command to work.

    2. Attempting to run this command in other repositories that do not have the branches listed in run_list_environments OR do not have split_branch set to true will raise an error.

    3. This command will only succeed *IF THERE ARE NO MERGE CONFLICTS*.

    4. This command will return a helpful error statement if you attempt to run the command with changes to your current working directory. You must commit these changes before running this command.

51. `cft update_the_cheftacular_cookbook_and_knife_upload` update your local cheftacular cookbook with your local (out of chef-repo) cheftacular cookbook and knife_upload afterwards.

    1. This method is aliased to `cft utccaku` and `cft utcc`.

52. `cft update_tld TLD` command will force a full dns update for a tld in the preferred cloud. It will ensure all the subdomain entries are correct (based on the contents of the addresses data bag) and update them if they are not. It will also create the local subdomain for the entry as well if it does exist and point it to the correct private address.

53. `cft upload_nodes` This command will resync the chef server's nodes with the data in our chef-repo/node_roles. 

    1. This command changes behavior depending on several factors about both your mode and the state of your environment

    2. In Devops mode, being run directly, this command will prompt you to update a data bag of node_role data that will help non-devops runs perform actions that involve setting roles on servers.

        1. In this setting, any time the chef server's data bag hash differs from the hash stored on disk for a role, you will be prompted to see if you really want to overwrite.

    3. When building new servers *in any mode*, this command will check the node_roles stored in the data bag only and update the run lists of the nodes from that data, NOT from the node_roles data stored on disk in the nodes_dir.

        1. Due to this, only users running this against their chef-repo need to worry about having a nodes_dir, the way it should be.

    4. Aliased to `cft un`

54. `cft upload_roles` This command will resync the chef server's roles with the data in the chef-repo/roles.

    1. Aliased to `cft ur`

55. `cft version` this command prints out the current version of cheftacular.

    1. Aliased to `cft v`