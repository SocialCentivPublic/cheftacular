module SSHKit
  module Backend
    class Netssh
      def get_repository_from_role_name name, repositories, *args
        args = args.flatten

        repo_role_name = ""

        repositories.each_pair { |key, repo_hash| repo_role_name = key if repo_hash['repo_name'] == name }

        if repositories.has_key?(name) && ( args.empty? || args.include?('do_not_raise_on_unknown') )
          return repositories[name]['repo_name']
        elsif !repo_role_name.empty? && ( args.empty? || args.include?('do_not_raise_on_unknown') )
          return repo_role_name
        end

        if args.include?('has_key?')
          return repositories.has_key?(name)
        elsif args.include?('has_value?')
          return !repo_role_name.empty?
        end

        raise "Unknown repository or rolename for #{ name }" unless args.include?('do_not_raise_on_unknown')

        nil
      end

      def get_node_from_address nodes, address, ret_node=nil
        nodes.each do |n|
          if n.public_ipaddress == address
            ret_node = n

            break
          end
        end

        ret_node
      end

      def get_true_environment run_list, chef_env_roles, default_env
        unless chef_env_roles.nil?
          chef_env_roles.each_pair do |role, env|
            if run_list.include?("role[#{ role }]")
              default_env = env

              break
            end
          end
        end

        default_env
      end

      def get_worker_role cheftacular, ret=""
        cheftacular['role_maps'].each_pair do |main_role, role_hash|
          ret = role_hash['role_name'] if main_role.include?('worker')
        end

        ret
      end

      def get_role_map cheftacular, target_role, ret=""
        cheftacular['role_maps'].each_pair do |main_role, role_hash|
          ret = role_hash if role_hash['role_name'] == target_role
        end

        ret
      end

      def get_server_hash_from_address array_of_server_hashes, address, ret_hash=nil
        array_of_server_hashes.each do |server_hash|
          ret_hash = server_hash if server_hash['address'] == address
        end

        ret_hash
      end

      def get_override_environment repo_hash, default_env
        repo_hash['db_env_node_bypass'].each_pair do |original_env, original_env_hash|
          next if default_env != original_env

          default_env = original_env_hash['environment_to_bypass_into']

          break
        end if repo_hash.has_key?('db_env_node_bypass')

        default_env
      end
    end
  end
end
