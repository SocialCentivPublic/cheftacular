class Cheftacular
  class ActionDocumentation
    def check
      @config['documentation']['action'] <<  [
        "`cft check` Checks the commits for all servers for a repository (for an environment) and returns them in a simple chart. " +
        "Also shows when these commits were deployed to the server."
      ]
    end
  end

  class Action
    def check commit_hash={}
      nodes = @config['getter'].get_true_node_objects

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| "deploy@" + n.public_ipaddress } ), in: :parallel do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning commit check run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        commit_hash[n.name] = start_commit_check( n.name, n.public_ipaddress, options, locs, cheftacular)
      end

      puts "\n#{ 'name'.ljust(21) }#{ 'deployed_on'.ljust(22) } #{ 'commit'.ljust(40) }"
      nodes.each do |n|
        puts("#{ n.name.ljust(21, '_') }#{ commit_hash[n.name]['time'].ljust(22) } #{ commit_hash[n.name]['name'].ljust(40) }") unless commit_hash[n.name]['name'].blank?
      end
    end
  end
end