class Cheftacular
  class ActionDocumentation
    def tail
      @config['documentation']['action'] <<  [
        "`cft tail` will tail the logs (return continuous output) of the first node if finds " + 
        "that has an application matching the repository running on it. Currently only supports rails stacks",

        [
          "    1. pass `-n NODE_NAME` to grab the output of a node other than the first.",

          "    2. Workers and job servers change the output of this command heavily. " +
          "Worker and job servers should tail their log to the master log (/var/log/syslog) where <b>all</b> of the major processes on the server output to. " +
          "While the vast majority of this syslog will be relevant to application developers, some will not (usually firewall blocks and the like)."
        ]
      ]
    end
  end

  class Action
    #TODO ARG FOR TAILING ANY LOG FILE
    def tail
      nodes = @config['getter'].get_true_node_objects

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @options['role'] }]" }], true )

      nodes.each do |n|
        puts("Beginning tail run for #{ n.name } (#{ n.public_ipaddress }) on role #{ @options['role'] }") unless @options['quiet']

        if @config['dummy_sshkit'].has_run_list_in_role_map?(n.run_list, @config['cheftacular']['role_maps'])
          start_tail_role_map( n.public_ipaddress, n.run_list )
        else
          self.send("start_tail_#{ @config['getter'].get_current_stack }", n.public_ipaddress, n.run_list )
        end
      end
    end

    private

    def start_tail_role_map ip_address, run_list
      log_loc = @config['getter'].get_current_role_map(run_list)['log_location'].split(',').first.gsub('|current_repo_location|', "#{ @config['cheftacular']['base_file_path'] }/#{ @options['repository'] }/current")

      `ssh -oStrictHostKeyChecking=no -tt #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } "#{ @config['helper'].sudo(ip_address) } tail -f #{ log_loc }" > /dev/tty`
    end

    def start_tail_ruby_on_rails ip_address, run_list
      true_env = @config['dummy_sshkit'].get_true_environment run_list, @config['cheftacular']['run_list_environments'][@options['env']], @options['env']

      #special servers should be listed first as most of them will have web role
      log_loc = "#{ @config['cheftacular']['base_file_path'] }/#{ @options['repository'] }/current/log/#{ true_env }.log"
      
      `ssh -oStrictHostKeyChecking=no -tt #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } "#{ @config['helper'].sudo(ip_address) } tail -f #{ log_loc }" > /dev/tty`
    end
  end
end
