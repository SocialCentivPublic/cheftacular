class Cheftacular
  class ActionDocumentation
    def deploy
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft deploy [check|verify]` will do a simple chef-client run on the servers for a role. " + 
        "Logs of the run itself will be sent to the local log directory in the application (or chef-repo) where the run was conducted.",
        
        [
          "    1.  The `-Z REVISION` flag can be used with TheCheftacularCookbook to set a revision your app will run. ",

          "    2.  The `-O ORGANIZATION` flag can be used with TheCheftacularCookbook to set an *organization* your app can try " +
          "deploying from, your git user needs access to these forks / organization(s).",

          "    3.  The `-z|--unset-github-deploy-args` option will clear your current `-Z` and `-O` flags.",

          "    4.  This command will also run migrations on both an role's normal servers and its split servers if certain " +
          "conditions are met (such as the role having a database, etc).",

          "    5. The `-v|--verbose` option will cause failed deploys to output to the terminal window and to their normal log file. Useful for debugging.",

          "    6. The `cft deploy check` argument will force a check run under the same environment as the initial deploy. This is also aliased to `cft d ch`",

          "    7. The `cft deploy verify` argument will force a check AND verify run under the same environment as the initial deploy. This is also aliased to `cft d ve`",

          "    8. Deploy locks (if set in the cheftacular.yml for the repo(s)) can be bypassed with the `--override-deploy-locks` flag",

          "    9. Aliased to `cft d`"
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = "Deploys the current code in the repository (runs chef-client)"
    end
  end

  class Action
    def deploy deployment_args={ in: :groups, limit: 6, wait: 5 }
      run_check  = ARGV[1] == 'check' || ARGV[1] == 'ch'
      run_verify = ARGV[1] == 'verify' || ARGV[1] == 've'

      nodes = @config['getter'].get_true_node_objects(false) #when this is run in scaling we'll need to make sure we deploy to new nodes

      nodes = @config['parser'].exclude_nodes( nodes, [{ if: "role[#{ @options['negative_role'] }]" }]) if @options['negative_role']
      
      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      deployment_args = { in: :groups, limit: 10, wait: 5 } if @options['env'] == 'production'

      @config['pleasantries'].good_luck_fridays if @config['cheftacular']['pleasantries']

      #on is namespaced to SSHKit::Backend::Netssh.on 
      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), deployment_args do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning chef client run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        log_data, timestamp, exit_status = start_deploy( n.name, n.public_ipaddress, options, locs, passwords)

        logs_bag_hash["#{ n.name }-#{ __method__ }"] = { "text" => log_data.scrub_pretty_text, "timestamp" => timestamp, "exit_status" => exit_status }
      end

      @config['helper'].send_log_bag_hash_slack_notification(logs_bag_hash, __method__)
      
      @config['ChefDataBag'].save_logs_bag unless @options['debug'] #We don't really need to store entire chef runs in the logs bag

      @config['action'].check if run_check && !@options['run_migration_already']

      @config['action'].check('verify') if run_verify && !@options['run_migration_already']

      @config['auditor'].notify_slack_on_completion_for_deploy(nodes.map {|n| n.name }, logs_bag_hash) if @config['cheftacular']['auditing'] && !@options['run_migration_already']

      @config['action'].migrate(nodes) if @config['getter'].get_current_repo_config['database'] != 'none' && !@options['run_migration_already']

      split_nodes_hash = {}

      if @config['cheftacular']['run_list_environments'].has_key?(@options['env'])
        @config['cheftacular']['run_list_environments'][@options['env']].each_key do |role_name|
          split_nodes_hash[role_name] = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ role_name }]" }])
        end

        split_nodes_hash.each_pair do |role, split_nodes|
          next if split_nodes.empty?

          unless @options["run_#{ role }_migrations_already"]
            @options["run_#{ role }_migrations_already"] = true
            
            if @config['getter'].get_current_repo_config['database'] != 'none'
              puts("Running migration on split environment #{ role }...") if !@options['quiet']
              
              migrate(split_nodes)
            end
          end
        end
      end
    end

    alias_method :d, :deploy
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_deploy name, ip_address, options, locs, passwords, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts "Generating log file for #{ name } (#{ ip_address }) at #{ log_loc }/deploy/#{ name }-deploy-#{ timestamp }.txt"

        capture_args = [ "chef-client" ]
        capture_args << [ '-l', 'debug' ] if options['debug']
        #capture_args << [ '>', '/dev/tty']

        out << sudo_capture( passwords[ip_address], *capture_args.flatten )

        ::File.open("#{ log_loc }/deploy/#{ name }-deploy-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        puts(out) if options['output'] || options['verbose']

        puts "Succeeded deploy of #{ name } (#{ ip_address }) on role #{ options['role'] }"

        ['Successful Deploy', timestamp, 0] #return out to send to logs_bag
      rescue SSHKit::Command::Failed => e
        puts "@@@@@CRITICAL! Deploy failed for #{ name } (#{ ip_address })! Please check your #{ log_loc }/failed-deploy for the logs!@@@@@"

        puts(e.message) if options['verbose']

        lines = e.message.split("\n").last(100).join("\n")

        ::File.open("#{ log_loc }/failed-deploy/#{ name }-deploy-#{ timestamp }.txt", "w") { |f| f.write(e.message.scrub_pretty_text) }

        [lines, timestamp, 1]
      end
    end
  end
end
