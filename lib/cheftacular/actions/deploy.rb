class Cheftacular
  class ActionDocumentation
    def deploy
      @config['documentation']['action'] <<  [
        "`cft deploy` will do a simple chef-client run on the servers for a role. " + 
        "Logs of the run itself will be sent to the local log directory in the application (or chef-repo) where the run was conducted.",
        
        [
          "    1.  This command also restarts services on the server and updates the code. Changes behavior slightly with the `-z|-Z` args " +
          "but only if your cookbooks support switching revisions based on tags / branch names.",

          "    2.  This command will also run migrations on both an role's normal servers and its split servers if certain " +
          "conditions are met (such as the role having a database, etc)."
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
      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :groups, limit: 10, wait: 5 do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning chef client run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        log_data, timestamp, exit_status = start_deploy( n.name, n.public_ipaddress, options, locs, passwords)

        logs_bag_hash["#{ n.name }-deploy"] = { "text" => log_data.scrub_pretty_text, "timestamp" => timestamp, "exit_status" => exit_status }
      end

      #Yes, you will get pinged on EVERY deploy until you fix the problem
      if @config['cheftacular']['slack']['webhook']
        logs_bag_hash.each_pair do |key, hash|
          @config['stateless_action'].slack(hash['text'].prepend('```').insert(-1, '```')) if hash['exit_status'] && hash['exit_status'] == 1
        end
      end
      
      @config['ChefDataBag'].save_logs_bag unless @options['debug'] #We don't really need to store entire chef runs in the logs bag

      migrate(nodes) if @config['getter'].get_current_repo_config['database'] != 'none' && !@options['run_migration_already']

      split_nodes_hash = {}

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

        lines = e.message.split("\n").last(100).join("\n")

        ::File.open("#{ log_loc }/failed-deploy/#{ name }-deploy-#{ timestamp }.txt", "w") { |f| f.write(e.message.scrub_pretty_text) }

        [lines, timestamp, 1]
      end
    end
  end
end
