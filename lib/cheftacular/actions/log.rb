class Cheftacular
  class ActionDocumentation
    def log
      @config['documentation']['action'] <<  [
        "`cft log` this command will output the last 500 lines of logs " +
        "from every server set for CODEBASE (can be given additional args to specify) to the log directory",

        [
          "    1.  `--nginx` will fetch the nginx logs as well as the application logs",

          "    2.  `--full` will fetch the entirety of the logs (will fetch the entire nginx log too if `--nginx` is specified)",

          "    3. `--num INTEGER` will fetch the last INTEGER lines of logs",

          "        1. `-l|--lines INTEGER` does the exact same thing as `--num INTEGER`.",

          "    4. `--fetch-backup` If doing a pg_data log, this will fetch the latest logs from the pg_data log directory for each database."
        ]
      ]
    end
  end

  class Action
    def log
      nodes = @config['getter'].get_true_node_objects

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @options['role'] }]" }] )

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      getter = @config['getter']

      on ( nodes.map { |n| "deploy@" + n.public_ipaddress } ), in: :parallel do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning log fetch run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        if getter.get_current_stack.nil?
          start_log_role_map( name, n.public_ipaddress, getter.get_current_role_map['log_location'], options, locs, cheftacular, passwords)
        else
          self.send("start_log_fetch_#{ getter.get_current_stack }", n.name, n.public_ipaddress, n.run_list, options, locs, cheftacular, passwords)
        end
      end
    end
  end
end
