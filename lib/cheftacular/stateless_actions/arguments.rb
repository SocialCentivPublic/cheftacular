class Cheftacular
  class StatelessActionDocumentation
    def arguments
      @config['documentation']['arguments'] << [
        '## Arguments and flags for cheftacular',

        '### Environment flags',

        '1.  `-d|--dev-remote` toggles on dev-remote mode. Commands passed to cft will hit the devremote server(s) instead of the default server(s)',

        '2.  `--env ENV` sets the environment commands hit to one you specify instead of the default one.',

        '3.  `-p|--prod` toggles on production mode. Commands passed to cft will hit the production server(s) instead of the default server(s)',

        '4.  `-Q|--qa` toggles on QA mode. Commands passed to cft will hit the QA server(s) instead of the default server(s)',

        '5.  `-s|--staging` toggles on staging mode. Commands passed to cft will hit the staging server(s) instead of the default server(s)',

        '6.  `--split-env SPLIT_ENV_NAME` sets the sub-environment to SPLIT_ENV_NAME. This only slightly affects certain commands.',

        '7.  `-t|--test` toggles on test mode. Commands passed to cft will hit the test server(s) instead of the default server(s)',

        '### General Flags',

        '1.  `-a|--address ADDRESS` will force the command to only run against the specified address if it belongs to a node',

        '2.  `-D|--debug` toggles on extremely verbose logging. Chef-client runs will generate ~10 times the amounts of logs including any additional effects that the `-v` flag will activate',

        '3. `--no-logs` will make the cft commands not generate log files, you must still specify `-v` if you want output of most verbose commands to your terminal.',

        '4.  `-n|--node-name NODE_NAME` will force the command to only run against the specified name if it belongs to a node',

        '5.  `-q|--quiet` will make the cft commands only output information that is a direct result of the command being run',

        "6.  `-r|--role-name ROLE_NAME` will force the command to only run against the specified role if it exists (this argument is generally not needed though it can be used to deploy a codebase for an application you're not currently cd'd into when running this as a gem)",

        '7.  `-R|--repository NAME` will make the command run against a specific repository or context (automatically set for application mode)',

        '8.  `-v|--verbose` toggles on verbose logging. All commands that write logs will also output to terminal AND write the logs.',

        '### Help Related',

        '1. `-h|--help` Displays the full readme and exits.',

        '### Action Flags',

        '1.  `-e|--except-role ROLE_NAME` will *prevent* any server with this role from being *deployed to* for the deploy command. Other commands will ignore this argument.',

        '2.  `-z|--unset-github-deploy-args` will unset a custom revision specified in the arg below and make the codebase utilize the default.',

        "3.  `-Z|--revision REVISION` will force the role you're deploying to to utilize the revision specified here. This can be a specific commit, a branch name or even a tag.",

        '    1. Note: The system does not check if the revision exists, if you pass a non-existent revision no one will be able to deploy to that role until -Z with a correction revision or -z is passed.',
        
        "4.  The `-O ORGANIZATION` flag can be used with TheCheftacularCookbook to set an *organization* your app can try " +
        "deploying from, your git user needs access to these forks / organization(s).",

        "    3.  The `-z|--unset-github-deploy-args` option will clear your current `-Z` and `-O` flags."
      ]
    end
  end

  class InitializationAction
    def arguments
      
    end
  end

  class StatelessAction
    def arguments
      @config['stateless_action_documentation'].arguments

      puts @config['documentation']['arguments']
    end

    alias_method :flags, :arguments
  end
end
