
class Cheftacular
  class StatelessActionDocumentation
    def upload_nodes
      @config['documentation']['stateless_action'] <<  [
        "`cft upload_nodes` This command will resync the chef server's nodes with the data in our chef-repo/node_roles. ",

        [
          "    1. This command changes behavior depending on several factors about both your mode and the state of your environment",

          "    2. In Devops mode, being run directly, this command will prompt you to update a data bag of node_role data that will help " +
          "non-devops runs perform actions that involve setting roles on servers.",

          "        1. In this setting, any time the chef server's data bag hash differs from the hash stored on disk for a role, you will be " +
          "prompted to see if you really want to overwrite.",

          "    3. When building new servers *in any mode*, this command will check the node_roles stored in the data bag only and update the " +
          "run lists of the nodes from that data, NOT from the node_roles data stored on disk in the nodes_dir.",

          "        1. Due to this, only users running this against their chef-repo need to worry about having a nodes_dir, the way it should be."
        ]
      ]
    end
  end

  class StatelessAction
    def upload_nodes invalidate_file_node_cache=false
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']

      @config['chef_environments'].each do |env|
        @config['initializer'].initialize_data_bags_for_environment env, false, ['node_roles']

        @config['initializer'].initialize_node_roles_bag_contents env
      end

      nodes = @options['multi-step'] ? @config['getter'].get_true_node_objects(true,true) : @config['getter'].get_true_node_objects(true)

      node_roles_hash, bag_hash, allowed_changes_hash = {},{},{}

      Dir.foreach(@config['locs']['nodes']) do |fr|
        next if @config['helper'].is_junk_filename?(fr)

        Dir.foreach("#{ @config['locs']['nodes'] }/#{ fr }") do |f|
          next if @config['helper'].is_junk_filename?(f)

          node_roles_hash[f.split('.json').first] = JSON.parse(File.read("#{ @config['locs']['nodes'] }/#{ fr }/#{ f }"))
        end
      end if @config['helper'].running_in_mode?('devops') #only devops modes should have a nodes_dir

      @config['chef_environments'].each do |env|
        @config[env]['node_roles_bag_hash']['node_roles'].each_pair do |role_name, role_hash|
          bag_hash[role_hash['name']] = role_hash.to_hash #hashes from chef server are stored as hashie objects until forced into hashes
        end
      end

      if !@options['force_yes'] && @config['helper'].running_in_mode?('devops') 
        node_roles_hash.each_pair do |role_name, role_hash|
          overwrite = false
          if bag_hash[role_name] != role_hash
            puts "Detected difference between saved roles hash and updated node_roles json hash for #{ role_name }."

            puts "Saved roles hash:"
            ap(bag_hash[role_name])

            puts "New roles hash:"
            ap(role_hash)

            puts "Preparing to overwrite the saved roles hash with the node_roles hash, enter Y/y to confirm."

            input = STDIN.gets.chomp

            overwrite = true if ( input =~ /y|Y|yes|Yes/ ) == 0

            allowed_changes_hash[role_name] = role_hash if overwrite
          else #bag_hash does not have a key for that role, populate it.
            allowed_changes_hash[role_name] = role_hash
          end

          @config[role_hash['chef_environment']]['node_roles_bag_hash']['node_roles'][role_name] = role_hash
        end
      else
        allowed_changes_hash = bag_hash
      end

      #force add any roles that are not in the bag in the event force yes is turned on
      (node_roles_hash.keys - bag_hash.keys).each do |role_not_in_node_roles_bag|

        new_role = node_roles_hash[role_not_in_node_roles_bag]

        allowed_changes_hash[role_not_in_node_roles_bag] = bag_hash[role_not_in_node_roles_bag]

        @config[new_role['chef_environment']]['node_roles_bag_hash']['node_roles'][new_role['name']] = new_role
      end if @options['force_yes'] && @config['helper'].running_in_mode?('devops')

      nodes.each do |node|
        # if there is a node_roles file that completely matches the name of the file, use it
        changes_for_current_node = false

        if allowed_changes_hash[node.name]
          allowed_changes_hash[node.name].each_pair do |node_key, node_val|
            if (node_key =~ /name/) != 0 && node.send(node_key) != node_val
              puts("Updating #{ node.name } with attribute #{ node_key } = #{ node_val } from #{ node.name }.json") unless @options['quiet']

              node.send("#{ node_key }=", node_val)

              changes_for_current_node, invalidate_file_node_cache = true, true
            end
          end

        elsif allowed_changes_hash.keys.include?(node.name.gsub(/\d/,'')) #if there is a template file that matches the stripped down name, use it
          allowed_changes_hash[node.name.gsub(/\d/,'')].each_pair do |node_key, node_val|
            if (node_key =~ /name/) != 0 && node.send(node_key) != node_val
              puts("Updating #{ node.name } with attribute #{ node_key } = #{ node_val } from template json file") unless @options['quiet']
              
              node.send("#{ node_key }=", node_val)

              changes_for_current_node, invalidate_file_node_cache = true, true
            end
          end
        end

        node.save if changes_for_current_node
      end

      @config['chef_environments'].each do |env|
        @config['ChefDataBag'].save_node_roles_bag env
      end if !@options['force_yes'] && @config['helper'].running_in_mode?('devops')

      @config['helper'].cleanup_file_caches('current') if invalidate_file_node_cache
    end
  end
end
