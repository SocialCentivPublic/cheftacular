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

8.  `-v|--verbose` toggles on verbose logging. All commands that write logs will also output to terminal AND write the logs.

### Help Related

1. `-h|--help` Displays the full readme and exits.

### Action Flags

1.  `-e|--except-role ROLE_NAME` will *prevent* any server with this role from being *deployed to* for the deploy command. Other commands will ignore this argument.

2.  `-z|--unset-revision` will unset a custom revision specified in the arg below and make the codebase utilize the default (staging branch for staging and master for production)

3.  `-Z|--revision REVISION` will force the role you're deploying to to utilize the revision specified here. This can be a specific commit or a branch name.

    1. Note: The system does not check if the revision exists, if you pass a non-existent revision no one will be able to deploy to that role until -Z with a correction revision or -z is passed.

    2. *You will not be able to set a custom revision for beta environments.* The beta environments are tied to split-staging and splita/b/c/d respectively.

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

8.  `-v|--verbose` toggles on verbose logging. All commands that write logs will also output to terminal AND write the logs.

### Help Related

1. `-h|--help` Displays the full readme and exits.

### Action Flags

1.  `-e|--except-role ROLE_NAME` will *prevent* any server with this role from being *deployed to* for the deploy command. Other commands will ignore this argument.

2.  `-z|--unset-revision` will unset a custom revision specified in the arg below and make the codebase utilize the default (staging branch for staging and master for production)

3.  `-Z|--revision REVISION` will force the role you're deploying to to utilize the revision specified here. This can be a specific commit or a branch name.

    1. Note: The system does not check if the revision exists, if you pass a non-existent revision no one will be able to deploy to that role until -Z with a correction revision or -z is passed.

    2. *You will not be able to set a custom revision for beta environments.* The beta environments are tied to split-staging and splita/b/c/d respectively.


## Commands that can be run in the application context

1. `cft backup [activate|deactivate]` this command sets the fetch_backups and restore_backups flags in your config data bag for an environment. These can be used to give application developers a way to trigger / untrigger restores in an environment

2. `cft check` Checks the commits for all servers for a repository (for an environment) and returns them in a simple chart. Also shows when these commits were deployed to the server.

3. `cft chef_environment ENVIRONMENT_NAME [create|destroy]` will allow you to interact with chef environments on the chef server.

    1.  `create` will create an environment if it does not exist.

    2.  `destroy` will destroy a chef environment *IF IT HAS NO NODES*

4. `cft client_list` Allows you check the basic information for all the servers setup via chef. Shows the server's short name, its public ip address and roles (run_list) by default.

    1. `-v` option will make this command display the server's domain name, whether its password is stored on the chef server and what that password is.

    2. `-W|--with-priv` option will make this command display the server's local (private) ip address. This address is also the server's `local.<SERVER_DNS_NAME>`.

    3. This command is aliased to `client-list` with no arguments or cft prefix.

5. `cft console` will create a pry session on the first node found for a codebase.

6. `cft db_console` will create a database console session on the first node found for a database stack in the current environment.

    1. This command is aliased to psql, typing `cft psql` will drop you into a rails stack database psql session.

7. `cft deploy` will do a simple chef-client run on the servers for a role. Logs of the run itself will be sent to the local log directory in the application (or chef-repo) where the run was conducted.

    1.  This command also restarts services on the server and updates the code. Changes behavior slightly with the `-z|-Z` args.

8. `cft disk_report` will fetch useful statistics from every server for every environment and output it into your log directory.

9. `cft environment boot|destroy` will boot / destroy the current environment

    1. `boot` will spin up servers and bring them to a stable state. This includes setting up their subdomains for the target environment.

    2. `destroy` will destroy all servers needed for the target environment

    3. This command will prompt when attempting to destroy servers in staging or production

10. `cft fix_known_hosts [HOSTNAME]` this command will delete entries in your known_hosts file for all the servers that are in our system (ip addresses AND dns names)

    1. Passing in a hostname will make the command only remove entries with that hostname / ip specifically

11. `cft get_active_ssh_connections` will fetch the active ssh connections from every server and output it into your log directory.

12. `cft get_haproxy_log` this command will generate a haproxy html file for the load balancer(s) associated with a repository in the log directory. Opening this log file in the browser will show the status of that haproxy at the time of the log. 

    1. In devops mode, this command will not do anything without the -R repository passed.

13. `cft get_log_from_bag <NODE_NAME-COMMAND_TYPE>` this command grabs the latest command run log from the data bags and saves it to your log directory. There are different types of logs saved per server depending on command.

14. `cft get_pg_pass ['clip']` command will output the current environment's pg_password to your terminal. Optionally you can pass in clip like `cft get_pg_pass clip` to have it also copy the pass to your clipboard.

15. `cft help COMMAND|MODE` this command returns the documentation for a specific command if COMMAND matches the name of a command. Alternatively, it can be passed `action|arguments|application|current|devops|stateless_action` to fetch the commands for a specific mode.Misspellings of commands will display near hits.

16. `cft log` this command will output the last 500 lines of logs from every server set for CODEBASE (can be given additional args to specify) to the log directory

    1.  `--nginx` will fetch the nginx logs as well as the application logs

    2.  `--full` will fetch the entirety of the logs (will fetch the entire nginx log too if `--nginx` is specified)

    3. `--num INTEGER` will fetch the last INTEGER lines of logs

        1. `-l|--lines INTEGER` does the exact same thing as `--num INTEGER`.

    4. `--fetch-backup` If doing a pg_data log, this will fetch the latest logs from the pg_data log directory for each database.

17. `cft migrate` this command will grab the first alphabetical node for a repository and run a migration that will hit the database primary server.

18. `cft pass NODE_NAME` will drop the server's sudo password into your clipboard. Useful for when you need to ssh into the server itself and try advanced linux commands

19. `cft reinitialize IP_ADDRESS NODE_NAME` will reconnect a server previously managed by chef to a new chef server. The node name MUST MATCH THE NODE'S ORIGINAL NODE NAME for the roles to be setup correctly.

20. `cft remove_client -n NODE_NAME` removes a client (and its node data) from the chef-server. It also removes its dns records from the cloud service (if possible). This should not be done lightly as you will have to wipe the server and trigger another chef-client run to get it to register again

21. `cft run COMMAND [--all]` will trigger the command on the first server in the role. Can be used to run rake commands or anything else.

    1. `--all` will make the command run against all servers in a role rather than the first server it comes across. Don't do this if you're modifying the database with the command.

    2. EX: `cft run rake routes`

    3. EX: `cft run ruby lib/one_time_fix.rb staging 20140214` This command can be used to run anything, not just rake tasks. It prepends bundle exec to your command for rails stack repositories

    4. IMPORTANT NOTE: You cannot run `cft run rake -T` as is, you have to enclose any command that uses command line dash arguments in quotes like `cft run "rake -T"`

22. `cft scale up|down [NUM_TO_SCALE]` will add (or remove) NUM_TO_SCALE servers from the server array. This command will not let you scale down below 1 server.

    1. In the case of server creation, this command takes a great deal of time to execute. It will output what stage it is currently on to the terminal but <b>you must not kill this command while it is executing</b>.A failed build may require the server to be destroyed / examined by a DevOps engineer.

23. `cft tail` will tail the logs (return continuous output) of the first node if finds that has an application matching the repository running on it. Currently only supports rails stacks

    1. pass `-n NODE_NAME` to grab the output of a node other than the first.

    2. Workers and job servers change the output of this command heavily. Worker and job servers should tail their log to the master log (/var/log/syslog) where <b>all</b> of the major processes on the server output to. While the vast majority of this syslog will be relevant to application developers, some will not (usually firewall blocks and the like).


## Commands that can ONLY be run in the devops context

1. `cft add_ssh_key_to_bag "<NEW SSH PUB KEY>" [SPECIFIC_REPOSITORY]` this command will add the given ssh key to the default authentication data bag. After this your server recipes should read the contents of the 'default' 'authentication' bag for the authorized_keys array.

    1. `SPECIFIC_REPOSITORY` is a special argument, if left blank the key will be placed in the authorized_keys array in the bag, otherwise it will be placed in the specific_authorized_keys hash under a key named for the repository that is passed. The script will error if SPECIFIC_REPOSITORY does not exist in the cheftacular.yml respositories hash. You can then use this data to give users selective ssh access to certain servers.

2. `cft backup [activate|deactivate]` this command sets the fetch_backups and restore_backups flags in your config data bag for an environment. These can be used to give application developers a way to trigger / untrigger restores in an environment

3. `cft chef_bootstrap ADDRESS NODE_NAME` allows you to register a node in the chef system, remove any lingering data that may be associated with it and update the node's runlist if it has an entry in nodes_dir for its NODE_NAME.

4. `cft clean_cookbooks [force] [remove_cookbooks]` allows you to update the internal chef-repo's cookbooks easily. By default this script will force you to decide what to do with each cookbook individually (shows version numbers and whether to overwrite it to cookbooks or not).

    1. `force` argument will cause the downloaded cookbooks to *always* overwrite the chef-repo's cookbooks as long as the downloaded cookbook has a higher version number.

    2. If you would like to remove all the cookbooks on the chef server, run `knife cookbook bulk delete '.*' -p -c ~/.chef/knife.rb`

5. `cft clean_sensu_plugins` [NYI] will checkout / update the sensu community plugins github repo on your local machine and sync any sensu plugin files in your wrapper cookbook directory with what is in the repo.

6. `cft client_list` Allows you check the basic information for all the servers setup via chef. Shows the server's short name, its public ip address and roles (run_list) by default.

    1. `-v` option will make this command display the server's domain name, whether its password is stored on the chef server and what that password is.

    2. `-W|--with-priv` option will make this command display the server's local (private) ip address. This address is also the server's `local.<SERVER_DNS_NAME>`.

    3. This command is aliased to `client-list` with no arguments or cft prefix.

7. `cft cloud <FIRST_LEVEL_ARG> [<SECOND_LEVEL_ARG>[:<SECOND_LEVEL_ARG_QUERY>]*] ` this command handles talking to various cloud apis. If no args are passed nothing will happen.

    1. `domain` 1st level argument for interacting with cloud domains

        1. `list` default behavior

        2. `read:TOP_LEVEL_DOMAIN` returns detailed information about all subdomains attached to the TOP_LEVEL_DOMAIN

        3. `read_record:TOP_LEVEL_DOMAIN:QUERY_STRING` queries the top level domain for all subdomains that have the QUERY_STRING in them.

        4. `create:TOP_LEVEL_DOMAIN` creates the top level domain on rackspace

        5. `create_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME:IP_ADDRESS[:RECORD_TYPE[:TTL]]` IE: `cft cloud domain create:mydomain.com:myfirstserver:1.2.3.4` will create the subdomain 'myfirstserver' on the mydomain.com domain.

        6. `destroy:TOP_LEVEL_DOMAIN` destroys the top level domain and all of its subdomains

        7. `destroy_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME` deletes the subdomain record for TOP_LEVEL_DOMAIN if it exists.

        8. `update:TOP_LEVEL_DOMAIN` takes the value of the email in the authentication data bag for your specified cloud and updates the TLD.

        9. `update_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME:IP_ADDRESS[:RECORD_TYPE[:TTL]]` similar to `create_record`.

    2. `server` 1st level argument for interacting with cloud servers, if no additional args are passed the command will return a list of all servers on the preferred cloud.

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

    3. `volume` 1st level argument for interacting with cloud storage volumes, if no additional args are passed the command will return a list of all cloud storage containers.

        1. `list` default behavior

        2. `read:VOLUME_NAME` returns the details for a specific volume.

        3. `create:VOLUME_NAME:VOLUME_SIZE` IE `cft rax volume create:staging_db:256`

        4. `destroy:VOLUME_NAME` destroys the volume. This operation will not work if the volume is attached to a server.

    4. `flavor` 1st level argument for listing the flavors available on the cloud service

        1. `list` default behavior

        2. `read:FLAVOR SIZE` behaves the same as list unless a flavor size is supplied.

            1. Standard servers are listed as XGB with no spaces in their size, performance servers are listed as X GB with a space in their size. If you are about to create a server and are unsure, query flavors first.

8. `cft cloud_bootstrap NODE_NAME FLAVOR_NAME [DESCRIPTOR] [--with-dn DOMAIN]` uses a cloud api to create a server and attaches its DOMAIN_NAME to the TLD specified for that environment (IE: example-staging.com for staging)

    1. If no DOMAIN_NAME is supplied it will use the node's NODE_NAME (IE: api01.example-staging.com)

    2. If the `--with-dn DOMAIN` argument is supplied the rax api will attempt to attach the node to the top level domain instead of the default environment one. This tld must be attached to the cloud service. This also allows you to attach to custom subdomains instead of NODE_NAME.ENV_TLD

    3. `cft cloud_bootstrap myserver "1 GB Performance" --with-dn myserver.example-staging.com` The "1 GB Perfomance" does not have to be exact, "1 GB" will match "1 GB Performance" and "1GB" will match "1GB Standard" (for rackspace flavors)

    4. DESCRIPTOR is used as an internal tag for the node, if left blank it will become the name of the node. It is recommended to enter a custom repository-dependent tag here to make nodes easier to load-balance like "lb:[CODEBASE_NAME]"

9. `cft compile_audit_log [clean]` compiles the audit logs in each environment's audit data bag a audit-log-CURRENTDAY.md file in the log folder of the application. Bear in mind that the bag can only hold 100K bytes and will need to have that data removed to store more than that.

10. `cft compile_readme` compiles all documentation methods and creates a README.md file in the log folder of the application.

11. `cft create_git_key ID_RSA_FILE [OAUTH_TOKEN]` This command will update the default/authentication data bag with new credentials. The [ID_RSA_FILE](https://help.github.com/articles/generating-ssh-keys) needs to exist beforehand.

    1. This command will upload both the private and public key to the data bag. The public key should be the one that matches the github user for your deployment github user.

    2. `OAUTH_TOKEN` *must* be generated by logging into github and generating an access token in the account settings -> applications -> personal access tokens

12. `cft disk_report` will fetch useful statistics from every server for every environment and output it into your log directory.

13. `cft environment boot|destroy` will boot / destroy the current environment

    1. `boot` will spin up servers and bring them to a stable state. This includes setting up their subdomains for the target environment.

    2. `destroy` will destroy all servers needed for the target environment

    3. This command will prompt when attempting to destroy servers in staging or production

14. `cft fetch_file NODE_NAME LOCATION_ALIAS FILE_NAME` fetches a file from the remote node. 

    1. `LOCATION_ALIAS` will be parsed as a path if it has backslash characters. Otherwise it will be parsed from your location_aliases hash in your cheftacular.yml

    2. `FILE_NAME` is the actual name of the file to be fetched. If no value is passed or the file does not exist in the LOCATION_ALIAS, the command will return the entries in LOCATION_ALIAS

15. `cft fix_known_hosts [HOSTNAME]` this command will delete entries in your known_hosts file for all the servers that are in our system (ip addresses AND dns names)

    1. Passing in a hostname will make the command only remove entries with that hostname / ip specifically

16. `cft full_bootstrap ADDRESS ROOT_PASS NODE_NAME` This command performs both ubuntu_bootstrap and chef_bootstrap.

17. `cft get_active_ssh_connections` will fetch the active ssh connections from every server and output it into your log directory.

18. `cft get_haproxy_log` this command will generate a haproxy html file for the load balancer(s) associated with a repository in the log directory. Opening this log file in the browser will show the status of that haproxy at the time of the log. 

    1. In devops mode, this command will not do anything without the -R repository passed.

19. `cft get_log_from_bag <NODE_NAME-COMMAND_TYPE>` this command grabs the latest command run log from the data bags and saves it to your log directory. There are different types of logs saved per server depending on command.

20. `cft get_pg_pass ['clip']` command will output the current environment's pg_password to your terminal. Optionally you can pass in clip like `cft get_pg_pass clip` to have it also copy the pass to your clipboard.

21. `cft help COMMAND|MODE` this command returns the documentation for a specific command if COMMAND matches the name of a command. Alternatively, it can be passed `action|arguments|application|current|devops|stateless_action` to fetch the commands for a specific mode.Misspellings of commands will display near hits.

22. `cft initialize_data_bag_contents ENVIRONMENT_NAME` will ensure the data bags always have the correct structure before each run. This command is run every time the gem is started and if called directly, will exit after completion.

23. `cft knife_upload` will resync the chef-server with the local chef-repo code. This command is analog for `knife upload /`

24. `cft pass NODE_NAME` will drop the server's sudo password into your clipboard. Useful for when you need to ssh into the server itself and try advanced linux commands

25. `cft replication_status` will check the status of the database master and slaves in every environment. Also lists how far behind the slaves are from the master in milliseconds.

26. `cft restart_swap` will restart the swap on every server that doesn't have swap currently on. Useful if you notice servers with no swap activated from `hip disk_report`

    1. There is no risk in running this command. Sometimes swap doesnt reactivate if the server was rebooted and this command fixes that.

27. `cft server_update [restart]` allows you to force update all nodes' packages for a specific environment. This should be done with caution as this *might* break something.

    1. `hip apt_update restart` will prompt to ask if you also want to restart all servers in a rolling restart. This should be done with extreme caution and only in a worst-case scenario.

28. `cft test_env [TARGET_ENV] boot|destroy` will create (or destroy) the test nodes for a particular environment (defaults to staging, prod split-envs can be set with `-p`). Please read below for how TARGET_ENV works

    1. TARGET_ENV changes functionality depending on the overall (like staging / production) environment

        1. In staging, it cannot be set and defaults to split (splitstaging).

        2. In production, it can be splita, splitb, splitc, or splitd.

        3. The default tld used should change depending on which environment you are booting / destroying. This is set in the environment's config data bag under the tld key

29. `cft ubuntu_bootstrap ADDRESS ROOT_PASS` This command will bring a fresh server to a state where chef-client can be run on it via `cft chef-bootstrap`. It should be noted that it is in this step where a server's randomized deploy_user sudo password is generated.

30. `cft update_split_branches` will perform a series of git commands that will merge all the split branches for your split_branch enabled repositories with what is currently on master and push them.

    1. Repository must be set with `-R REPOSITORY_NAME` for this command to work.

    2. Attempting to run this command in other repositories that do not have the branches listed in run_list_environments OR do not have split_branch set to true will raise an error.

    3. This command will only succeed *IF THERE ARE NO MERGE CONFLICTS*.

    4. This command will return a helpful error statement if you attempt to run the command with changes to your current working directory. You must commit these changes before running this command.

31. `cft update_tld TLD` command will force a full dns update for a tld in the preferred cloud. It will ensure all the subdomain entries are correct (based on the contents of the addresses data bag) and update them if they are not. It will also create the local subdomain for the entry as well if it does exist and point it to the correct private address.

32. `cft upload_nodes` This command will resync the chef server's nodes with the data in our chef-repo/node_roles. 

    1. This command changes behavior depending on several factors about both your mode and the state of your environment

    2. In Devops mode, being run directly, this command will prompt you to update a data bag of node_role data that will help non-devops runs perform actions that involve setting roles on servers.

        1. In this setting, any time the chef server's data bag hash differs from the hash stored on disk for a role, you will be prompted to see if you really want to overwrite.

    3. When building new servers *in any mode*, this command will check the node_roles stored in the data bag only and update the run lists of the nodes from that data, NOT from the node_roles data stored on disk in the nodes_dir.

        1. Due to this, only users running this against their chef-repo need to worry about having a nodes_dir, the way it should be.

33. `cft upload_roles` This command will resync the chef server's roles with the data in the chef-repo/roles.