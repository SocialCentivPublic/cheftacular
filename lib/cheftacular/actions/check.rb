class Cheftacular
  class ActionDocumentation
    def check
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description']  = [
        "`cft check [all|verify]` Checks the commits for all servers for a repository (for an environment) and returns them in a simple chart. " +
        "Also shows when these commits were deployed to the server.",
        [
          "    1. If the node has special repository based keys from TheCheftacularCookbook, this command will also display information " +
          "about the branch and organization currently deployed to the node(s).",

          "    2. If the all argument is provided, all repositories will be checked for the current environment",

          "    3. If the verify argument is provided, cft will attempt to see if the servers are using the latest commits. This is also aliased to `cft ch ve`",

          "    4. Aliased to `cft ch`"
        ]
      ]
      @config['documentation']['action'][__method__]['short_description'] = "Checks the branches currently deployed to an env for your repo"
    end
  end

  class Action
    def check mode='', commit_hash={}, have_revisions=false, have_changed_orgs=false, fetch_all_repository_data=false, headers=[], deployment_args={ in: :parallel }
      @config['filesystem'].cleanup_file_caches('current-nodes')

      fetch_all_repository_data = ARGV[1] == 'all'
      verify_state_is_latest    = ARGV[1] == 'verify' || ARGV[1] == 've'
      verify_state_is_latest    = mode    == 'verify' if ARGV[1] != 'verify'
      
      nodes = @config['getter'].get_true_node_objects(fetch_all_repository_data)

      nodes = @config['parser'].exclude_nodes(nodes, [{ if: { not_env: @options['env'] } }])

      repositories_to_check = @config['getter'].get_repo_names_for_repositories
      repositories_to_check = repositories_to_check.reject { |key,val| key != @options['repository'] } unless fetch_all_repository_data 

      deployment_args = { in: :groups, limit: 2, wait: 5 } if fetch_all_repository_data

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), deployment_args do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning commit check run for #{ n.name } (#{ n.public_ipaddress })...") unless options['quiet']

        repositories_to_check.each_pair do |repo, repo_hash|
          next unless n.run_list.include?("role[#{ repo_hash['role'] }]")

          options['repository'] = repo
          commit_hash[n.name] ||= {}

          commit_hash[n.name][repo] = start_commit_check( n.name, n.public_ipaddress, options, locs, cheftacular, passwords)

          next if commit_hash[n.name][repo].nil?

          if n.normal_attributes.has_key?(options['repository'])
            commit_hash[n.name][repo]['branch']       = n.normal_attributes[options['repository']]['repo_branch'] if n.normal_attributes[options['repository']].has_key?('repo_branch')
            commit_hash[n.name][repo]['organization'] = n.normal_attributes[options['repository']]['repo_group']  if n.normal_attributes[options['repository']].has_key?('repo_group')
          end

          have_revisions    = true if commit_hash[n.name].has_key?(repo) && commit_hash[n.name][repo].has_key?('branch')
          have_changed_orgs = true if commit_hash[n.name].has_key?(repo) && commit_hash[n.name][repo].has_key?('organization')

          sleep 5
        end
      end

      headers << "\n#{ 'name'.ljust(20) }"
      headers << 'repository'.ljust(30)   if repositories_to_check.length > 1
      headers << "#{ 'deployed_on'.ljust(22) } #{ 'commit'.ljust(40) }"
      headers << 'revision'.ljust(21)     if have_revisions
      headers << 'organization'.ljust(30) if have_changed_orgs

      puts headers.join(' ')
      nodes.each do |n|
        next if commit_hash[n.name].nil?
        repositories_to_check.each_pair do |repo, repo_hash|
          if commit_hash[n.name].has_key?(repo) && !commit_hash[n.name][repo].nil?
            out  = []
            out << n.name.ljust(20, '_')
            out << repo.ljust(30,'_') if repositories_to_check.length > 1
            out << commit_hash[n.name][repo]['time'].ljust(22)
            out << commit_hash[n.name][repo]['name'].ljust(40)
            out << commit_hash[n.name][repo]['branch'].ljust(21, '_')  if commit_hash[n.name][repo].has_key?('branch')
            out << commit_hash[n.name][repo]['organization'].ljust(30) if commit_hash[n.name][repo].has_key?('organization')

            puts out.join(' ')
          end
        end
      end

      @config['helper'].check_if_possible_repo_state(@config['parser'].parse_repo_state_hash_from_commit_hash(commit_hash), 'display_for_check') if verify_state_is_latest
    end

    alias_method :ch, :check
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_commit_check name, ip_address, options, locs, cheftacular, passwords, out={'name'=>'', 'time'=> ''}
        app_loc = "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/releases"
        
        if test("[ -d #{ app_loc } ]") #true if file exists
          within app_loc do
            out['name'] = capture( :ls, '-rt', :|, :tail, '-1' )

            out['time'] = Time.parse(capture( :stat, out['name'], '--printf=%y' )).strftime('%Y-%m-%d %I:%M:%S %p')
          end
        else
          return nil
        end

        out
      end
    end
  end
end
