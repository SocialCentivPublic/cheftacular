class Cheftacular
  class ActionDocumentation
    def deploy
      @config['documentation']['action'] <<  [
        "`cft deploy` will do a simple chef-client run on the servers for a role. " + 
        "Logs of the run itself will be sent to the local log directory in the application (or chef-repo) where the run was conducted.",
        
        [
          "    1.  This command also restarts services on the server and updates the code. Changes behavior slightly with the `-z|-Z` args."
        ]
      ]
    end
  end

  class Action
    def deploy
      nodes = @config['getter'].get_true_node_objects false, true #when this is run in scaling we'll need to make sure we deploy to new nodes

      nodes = @config['parser'].exclude_nodes( nodes, [{ if: "role[#{ @options['negative_role'] }]" }]) if @options['negative_role']
      
      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      #on is namespaced to SSHKit::Backend::Netssh.on 
      on ( nodes.map { |n| "deploy@" + n.public_ipaddress } ), in: :groups, limit: 10, wait: 5 do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning chef client run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        log_data, timestamp = start_deploy( n.name, n.public_ipaddress, options, locs, passwords)

        logs_bag_hash["#{ n.name }-deploy"] = { text: log_data.scrub_pretty_text, timestamp: timestamp }
      end
      
      @config['ChefDataBag'].save_logs_bag unless @options['debug'] #the debug chef-client runs are literally too large to POST

      migrate(nodes) if @config['getter'].get_current_repo_config['database'] != 'none' && !@options['run_migration_already']
    end
  end
end
