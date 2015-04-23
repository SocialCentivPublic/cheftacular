module SSHKit
  module Backend
    class Netssh
      def get_repository_from_role_name name, repositories, *args
        args = args.flatten

        repo_role_name = ""

        repositories.each_pair { |key, repo_hash| repo_role_name = key if repo_hash['repo_name'] == name }

        if repositories.has_key?(name) && args.empty?
          return repositories[name]['repo_name']
        elsif !repo_role_name.empty? && args.empty?
          return repo_role_name
        end

        if args.include?('has_key?')
          return repositories.has_key?(name)
        elsif args.include?('has_value?')
          return !repo_role_name.empty?
        end

        raise "Unknown repository or rolename for #{ name }"
      end

      def get_node_from_address nodes, address, ret_node = nil
        nodes.each do |n|
          if n.public_ipaddress == address
            ret_node = n

            break
          end
        end

        ret_node
      end

      def get_true_environment run_list, chef_env_roles, default_env
        chef_env_roles.each_pair do |role, env|
          if run_list.include?("role[#{ role }]")
            default_env = env

            break
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
    end
  end
end
