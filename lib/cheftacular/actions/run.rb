class Cheftacular
  class ActionDocumentation
    def run
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft run COMMAND [--all]` will trigger the command on the first server in the role. " + 
        "Can be used to run rake commands or anything else.",

        [
          "    1. `--all` will make the command run against all servers in a role rather than the first server it comes across. " +
          "Don't do this if you're modifying the database with the command.",

          "    2. EX: `cft run rake routes`",

          "    3. EX: `cft run ruby lib/one_time_fix.rb staging 20140214` This command can be used to run anything, not just rake tasks. " +
          "It prepends bundle exec to your command for rails stack repositories",

          "    4. IMPORTANT NOTE: You cannot run `cft run rake -T` as is, you have to enclose any command that uses command line dash " +
          'arguments in quotes like `cft run "rake -T"`'
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Runs a command on the current environment for the current repository'
    end
  end

  class Action
    def run
      self.send("run_#{ @config['getter'].get_current_stack }")
    end

    def run_ruby_on_rails
      nodes   = @config['getter'].get_true_node_objects
      command = @config['parser'].parse_runtime_arguments 0, 'range'

      #must have rails stack to run migrations and not be a db, only want ONE node
      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @options['role'] }]" }], !@options['run_on_all'] )

      nodes = @config['parser'].exclude_nodes( nodes, [{ if: "role[#{ @options['negative_role'] }]" }]) if @options['negative_role']

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning task run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        log_data, timestamp, exit_status = start_task( n.name, n.public_ipaddress, n.run_list, "#{ bundle_command } exec #{ command }", options, locs, cheftacular, passwords)

        logs_bag_hash["#{ n.name }-#{ __method__ }"] = { "text" => log_data.scrub_pretty_text, "timestamp" => timestamp, "exit_status" => exit_status }
      end

      @config['ChefDataBag'].save_logs_bag

      @config['helper'].send_log_bag_hash_slack_notification(logs_bag_hash, __method__, 'Failing command detected, exiting...')
    end

    def run_nodejs
      raise "Not yet implemented"
    end

    def run_wordpress
      raise "Not yet implemented"
    end

    def run_all
      raise "You attempted to run a command for the all role, this is not possible."
    end

    def run_
      puts "Run method tried to run a command for the role \"#{ @options['role'] }\" but it doesn't appear to have a repository set! Skipping..."

      return false
    end
  end
end
