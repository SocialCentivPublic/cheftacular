class Cheftacular
  class ActionDocumentation
    def migrate
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft migrate` this command will grab the first alphabetical node for a repository " +
        "and run a migration that will hit the database primary server.",

        [
          "    1. Currently only supports rails stacks."
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Creates a database migration on the current environment'
    end
  end

  class Action
    def migrate nodes=[]
      self.send("migrate_#{ @config['getter'].get_current_stack }", nodes)
    end

    def migrate_ruby_on_rails nodes=[]
      nodes = @config['getter'].get_true_node_objects if nodes.empty?

      #must have rails stack to run migrations, only want ONE node
      nodes = @config['parser'].exclude_nodes(nodes, [{ unless: "role[#{ @options['role'] }]" }, { unless: 'role[rails]' }], true)

      log_data = ""

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning migration run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        log_data, timestamp, exit_status = start_task( n.name, n.public_ipaddress, n.run_list, "#{ bundle_command } exec rake db:migrate", options, locs, cheftacular)

        logs_bag_hash["#{ n.name }-#{ __method__ }"] = { "text" => log_data.scrub_pretty_text, "timestamp" => timestamp, "exit_status" => exit_status }
      end

      @config['ChefDataBag'].save_logs_bag

      @config['helper'].send_log_bag_hash_slack_notification(logs_bag_hash, __method__, 'Failing migration detected, please fix this and deploy again, exiting...')

      @options['run_migration_already'] = true

      #restart the servers again after a deploy with a migration just in case
      deploy if !log_data.empty? && log_data != @config['cheftacular']['repositories'][@options['role']]['not_a_migration_message']
    end

    def migrate_wordpress nodes=[]
      puts "Method #{ __method__ } is not yet implemented"

      exit
    end

    def migrate_nodejs nodes=[]
      puts "Method #{ __method__ } is not yet implemented"

      exit
    end

    def migrate_all nodes=[]
      raise "You attempted to migrate the all role, this is not possible."
    end

    def migrate_ nodes=[]
      puts "Migrate method tried to migrate the role \"#{ @options['role'] }\" but it doesn't appear to have a repository set! Skipping..."

      return false
    end
  end
end
