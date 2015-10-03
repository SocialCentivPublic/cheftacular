class Cheftacular
  class ActionDocumentation
    def check
      @config['documentation']['action'] <<  [
        "`cft check` Checks the commits for all servers for a repository (for an environment) and returns them in a simple chart. " +
        "Also shows when these commits were deployed to the server.",

        [
          "    1. If the node has special repository based keys from TheCheftacularCookbook, this command will also display information " +
          "about the branch and organization currently deployed to the node(s)."
        ]
      ]
    end
  end

  class Action
    def check commit_hash={}, have_revisions=false, have_changed_orgs=false
      @config['filesystem'].cleanup_file_caches('current-nodes')
      
      nodes = @config['getter'].get_true_node_objects

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :parallel do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning commit check run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        commit_hash[n.name]                      = start_commit_check( n.name, n.public_ipaddress, options, locs, cheftacular)

        if n.normal_attributes.has_key?(options['repository'])
          commit_hash[n.name]['branch']       = n.normal_attributes[options['repository']]['repo_branch'] if n.normal_attributes[options['repository']].has_key?('repo_branch')
          commit_hash[n.name]['organization'] = n.normal_attributes[options['repository']]['repo_group']  if n.normal_attributes[options['repository']].has_key?('repo_group')
        end

        have_revisions    = true if commit_hash[n.name].has_key?('branch')
        have_changed_orgs = true if commit_hash[n.name].has_key?('organization')
      end

      puts "\n#{ 'name'.ljust(21) }#{ 'deployed_on'.ljust(22) } #{ 'commit'.ljust(40) } #{'revision'.ljust(29) if have_revisions } #{'organization'.ljust(30) if have_changed_orgs }"
      nodes.each do |n|
        unless commit_hash[n.name]['name'].blank?
          out  = []
          out << n.name.ljust(20, '_')
          out << commit_hash[n.name]['time'].ljust(21)
          out << commit_hash[n.name]['name'].ljust(39)
          out << commit_hash[n.name]['branch'].ljust(29)       if commit_hash[n.name].has_key?('branch')
          out << commit_hash[n.name]['organization'].ljust(30) if commit_hash[n.name].has_key?('organization') 

          puts out.join(' ')
        end
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_commit_check name, ip_address, options, locs, cheftacular, out={'name'=>'', 'time'=> ''}
        app_loc = "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/releases"
        
        if test("[ -d #{ app_loc } ]") #true if file exists
          within app_loc do
            out['name'] = capture( :ls, '-rt', :|, :tail, '-1' )

            out['time'] = Time.parse(capture( :stat, out['name'], '--printf=%y' )).strftime('%Y-%m-%d %I:%M:%S %p')
          end
        end

        out
      end
    end
  end
end
