class Cheftacular
  class ActionDocumentation
    def console
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft console` will create a console session on the first node found for a repository.",
        [
          "    1. Attempts to setup a console for the unique stack, stacks currently supported for console is only Rails.",

          "    2. If there is a node in the repository set that has the role `preferred_console`, this node will come before others.",

          "    3. Aliased to `cft co`"
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Create a remote console for the current repository'
    end
  end

  class Action
    def console
      self.send("console_#{ @config['getter'].get_current_stack }")

      @config['auditor'].notify_slack_on_completion("console run completed\n") if @config['cheftacular']['auditing']
    end

    def console_ruby_on_rails node_args=[{unless: 'role[rails]'}]
      nodes = @config['getter'].get_true_node_objects

      #must have rails stack to run migrations and not be a db, only want ONE node
      node_args << { unless: "role[#{ @options['role'] }]" }

      consolable_nodes = @config['parser'].exclude_nodes( nodes, (node_args + [{ unless: "role[preferred_console]" }]).flatten, true )

      consolable_nodes = @config['parser'].exclude_nodes( nodes, node_args, true ) if consolable_nodes.empty?

      consolable_nodes.each do |n|
        puts("Beginning console run for #{ n.name } (#{ n.public_ipaddress }) on role #{ @options['role'] }") unless @options['quiet']

        start_console_ruby_on_rails(n.public_ipaddress, n.run_list)
      end
    end

    def console_nodejs
      raise "Not yet implemented"
    end

    def console_wordpress
      raise "Not yet implemented"
    end

    def console_all
      raise "You attempted to create a console for the all role, this is not possible."
    end

    private 

    def start_console_ruby_on_rails ip_address, run_list
      app_loc  = "#{ @config['cheftacular']['base_file_path'] }/#{ @options['repository'] }/current"
      true_env = @config['dummy_sshkit'].get_true_environment run_list, @config['cheftacular']['run_list_environments'][@options['env']], @options['env']

      #the >/dev/tty after the ssh block redirects the full output to stdout, not /dev/null where it normally goes  
      `ssh #{ Cheftacular::SSH_INLINE_VARS } -tt #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } "cd #{ app_loc } && RAILS_ENV=#{ true_env } #{ @config['bundle_command'] } exec rails c" > /dev/tty`
    end

    def start_console_nodejs
      raise "Not yet implemented"
    end

    def start_console_wordpress
      raise "Not yet implemented"
    end

    def start_console_all
      raise "Not yet implemented"
    end

    def console_
      puts "Console method tried to create a console for the role \"#{ @options['role'] }\" but it doesn't appear to have a repository set! Skipping..."

      return false
    end

    alias_method :co, :console
  end
end
