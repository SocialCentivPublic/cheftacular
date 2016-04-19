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
          'arguments in quotes like `cft run "rake -T"`',

          "    5. Can also be used to run meteor commands and is aliased to `cft meteor`"
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Runs a command on the current environment for the current repository'
    end
  end

  class Action
    def run
      command = @config['parser'].parse_runtime_arguments 0, 'range'

      nodes = self.send("run_#{ @config['getter'].get_current_stack }", command)

      @config['auditor'].notify_slack_on_completion("run #{ command } completed on #{ nodes.map { |node| node.name }.join(', ') }\n") if @config['cheftacular']['auditing']
    end

    def run_ruby_on_rails command
      run_command(command, __method__.to_s, "#{ @config['bundle_command'] } exec")
    end

    def run_nodejs command
      self.send("run_#{ @config['getter'].get_current_sub_stack }", command)
    end

    def run_meteor command
      run_command(command, __method__.to_s, '/usr/local/bin/meteor', true)
    end

    def run_wordpress command
      raise "Not yet implemented"
    end

    def run_all command
      raise "You attempted to run a command for the all role, this is not possible."
    end

    def run_ command
      puts "Run method tried to run a command for the role \"#{ @options['role'] }\" but it doesn't appear to have a repository or stack set! Skipping..."

      return false
    end

    alias_method :meteor, :run

    private

    def run_command command, descriptor, executable, sudo=false
      nodes = @config['getter'].get_current_role_nodes

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning #{ descriptor } run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        log_data, timestamp, exit_status = start_task( n.name, n.public_ipaddress, n.run_list, "#{ executable } #{ command }", options, locs, cheftacular, passwords, sudo)

        logs_bag_hash["#{ n.name }-#{ descriptor }"] = { "text" => log_data.scrub_pretty_text.force_encoding('UTF-8'), "timestamp" => timestamp, "exit_status" => exit_status }
      end

      @config['ChefDataBag'].save_logs_bag

      @config['helper'].send_log_bag_hash_slack_notification(logs_bag_hash, __method__, 'Failing command detected, exiting...')

      nodes
    end
  end
end
