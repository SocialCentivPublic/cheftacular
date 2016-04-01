
class Cheftacular
  class Getter
    def initialize options, config
      @options, @config  = options, config
    end

    def get_repository_from_role_name name, *args
      @config['dummy_sshkit'].get_repository_from_role_name( name, @config['cheftacular']['repositories'], args )
    end

    #[TODO] if ridley changes its parsing strategy
    def get_true_node_objects get_all_nodes=false
      nodes, all_nodes, names, iter_arr, file_cache_nodes, h = [],[],[],[],[],{}

      @config['chef_nodes'] = @config['ridley'].node.all

      @config['helper'].completion_rate? 0, __method__

      file_cache_nodes = @config['filesystem'].check_nodes_file_cache if @config['filesystem'].compare_file_node_cache_against_chef_nodes('equal')

      @config['chef_nodes'].each do |n|
        true_obj = if !file_cache_nodes.empty? && @config['parser'].array_of_nodes_contains_node_name?(file_cache_nodes, n.name)
                     file_cache_nodes[@config['parser'].index_of_node_name_in_array_of_nodes(file_cache_nodes, n.name)]
                   else
                     @config['filesystem'].cleanup_file_caches('current-nodes')

                     @config['ridley'].node.find(n.name)
                   end

        iter_arr << n.name

        progress_value = (( iter_arr.length.to_f/@config['chef_nodes'].length.to_f )*100 ).floor

        @config['helper'].completion_rate? progress_value, __method__

        all_nodes << true_obj

        next if !get_all_nodes && true_obj.chef_environment != @options['env'] && true_obj.chef_environment != '_default'

        if get_all_nodes
          h[n.name] = true_obj
          names << n.name

          next
        end

        if @options['role'] == 'all'
          next if true_obj.chef_environment == '_default'

          h[n.name] = true_obj
          names << n.name

          next
        end

        if @options['node_name'] && true_obj.name == @options['node_name']
          h[n.name] = true_obj
          names << n.name

          next
        end

        if @options['address'] && true_obj.public_ipaddress == @options['address']
          h[n.name] = true_obj
          names << n.name

          next
        end

        unless ( @options['address'] || @options['node_name'] )
          if true_obj.run_list.include?("role[#{ @options['role'] }]")
            h[n.name] = true_obj
            names << n.name

            next #not needed here but good to keep in mind
          end
        end
      end

      names.sort.each { |name| nodes << h[name] }

      @config['filesystem'].write_nodes_file_cache(all_nodes) unless @config['filesystem'].compare_file_node_cache_against_chef_nodes('equal')

      puts("") unless @options['quiet']
      
      nodes
    end

    def get_current_stack 
      get_current_repo_config['stack']
    end

    def get_current_sub_stack
      get_current_repo_config['sub_stack']
    end

    def get_current_database
      get_current_repo_config['database']
    end

    def get_current_repo_config
      if @config['cheftacular']['repositories'].has_key?(@options['role'])
        @config['cheftacular']['repositories'][@options['role']]
      else
        @options['role']
      end
    end

    def get_current_role_map run_list, ret={}
      @config['cheftacular']['role_maps'].each_pair do |main_role, role_hash|
        ret = role_hash if run_list.include?("role[#{ role_hash['role_name'] }]")
      end

      ret
    end

    def get_addresses_hash env='staging', ret_hash={}, mode=""
      @config[env]['addresses_bag_hash']['addresses'].each do |serv_hash|
        ret_hash[serv_hash['public']] = serv_hash
        
      end if @config[env].has_key?('addresses_bag_hash')

      ret_hash
    end

    def get_db_primary_node_and_nodes
      nodes          = get_true_node_objects true
      target_db_role = get_current_repo_config['db_primary_host_role']
      
      [@config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ target_db_role }]" }, { if: { not_env: @options['env'] } }], true), nodes]
    end

    def get_split_branch_hash ret={}
      @config['cheftacular']['repositories'].each_pair do |name, repo_hash|
        ret[repo_hash['name']] = repo_hash if repo_hash.has_key?('has_split_branches') && repo_hash['has_split_branches']
      end

      ret
    end

    def get_address_hash node_name, load_out_of_env_addresses=false, ret={}
      break_on_found = false

      @config['chef_environments'].each do |env|
        next if !load_out_of_env_addresses && !@config.has_key?(env) #in case the env hashes are not loaded
        @config['initializer'].initialize_data_bags_for_environment(env, false, ['addresses']) if @options['env'] != env

        @config[env]['addresses_bag_hash']['addresses'].each do |serv_hash|
          if serv_hash['name'] == node_name
            ret[serv_hash['name']] = { "dn" => serv_hash['dn'], "priv" => serv_hash['address'], "pub" => serv_hash['public'] }
            break_on_found = true

            break
          end
        end

        break if break_on_found
      end

      ret
    end

    def get_repo_names_for_repositories restrict_to=[{}], ret={}
      @config['cheftacular']['repositories'].each_pair do |name, repo_hash|
        unless restrict_to.empty?
          skip = false
          restrict_to.each do |restrict_hash|
            restrict_hash.each_pair do |key, val|
              skip = true if repo_hash[key.to_s] != val && restrict_hash.has_key?(:ignore_value)
              skip = true if val == 'NOT NIL' && repo_hash[key.to_s].nil?
              skip = true if val == 'NIL'     && !repo_hash[key.to_s].nil?
            end
          end

          next if skip
        end

        ret[repo_hash['repo_name']]         = repo_hash
        
        ret[repo_hash['repo_name']]['role'] = name
      end

      ret
    end

    def get_current_real_node_name other_node_name='', ret=''
      ret << @options['env'] + @config['cheftacular']['node_name_separator']
      ret << ( other_node_name.blank? ? @options['node_name'] : other_node_name )

      ret
    end

    def get_current_role_nodes
      nodes = @config['parser'].exclude_nodes( @config['getter'].get_true_node_objects, [{ unless: "role[#{ @options['role'] }]" }], !@options['run_on_all'] )

      nodes = @config['parser'].exclude_nodes( nodes, [{ if: "role[#{ @options['negative_role'] }]" }]) if @options['negative_role']

      nodes
    end
  end
end
