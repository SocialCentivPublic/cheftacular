
class Cheftacular
  class StatelessActionDocumentation
    def role_toggle
      #set these config vars as they may not be loaded on an initialization run in a application repo
      @config['cheftacular']['role_toggling'] ||= {}
      @config['cheftacular']['role_toggling']['deactivated_role_suffix'] ||= '_deactivate'
      
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft role_toggle NODE_NAME ROLE_NAME activate|deactivate` This command will allow you to **toggle** roles on nodes without using `cft upload_nodes`",

        [
          "    1. This command uses your *role_toggling:deactivated_role_suffix* attribute set in your cheftacular.yml to toggle the role, " +
          "it checks to see if the toggled name exists then sets the node's run_list to include the toggled role",

          "    2. EX: `cft role_toggle api01 worker activate` will find the node api01 and attempt to toggle the worker role to on. " +
          "If the node does NOT have the worker#{ @config['cheftacular']['role_toggling']['deactivated_role_suffix'] } role, then it will " +
          "add it if *role_toggling:strict_roles* is set to **false**",

          "        1. If *role_toggling:strict_roles* is set to true, then cheftacular would raise an error saying this role is unsettable " +
          "on the node. On the other hand, if the node already has the worker#{ @config['cheftacular']['role_toggling']['deactivated_role_suffix'] }" +
          "role, then this command will succeed even if *strict_roles* is set.",

          "    3. In case it isn't obvious, this command ONLY supports deactivation suffix roles like worker_deactivate or worker_off, with their" +
          "on counterpart just being the role itself, like \"worker\".",

          "        1. Please run `cft list_toggleable_roles NODE_NAME` to get a list of your org's toggleable roles for a node."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Attempts to toggle the specified role on the specified node'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def role_toggle state_toggle='', target_run_list=[], skip_confirm=false
      @options['node_name'] = ARGV[1] unless @options['node_name']
      @config['parser'].parse_role(ARGV[2])
      state_toggle          = ARGV[3] if state_toggle.blank?

      raise "You have yet to fully configure your role toggling settings! Exiting..." if @config['cheftacular']['role_toggling'].has_key?('do_not_allow_toggling')
      raise "You may only enter activate or deactivate for the state toggle argument for the #{ __method__ } command." unless (state_toggle =~ /activate|deactivate/) == 0

      @config['initializer'].initialize_data_bags_for_environment @options['env'], false, ['node_roles']

      @config['initializer'].initialize_node_roles_bag_contents @options['env']

      @config['filesystem'].cleanup_file_caches('current')

      nodes = @config['error'].is_valid_node_name_option?

      suffix = @config['cheftacular']['role_toggling']['deactivated_role_suffix']

      if @options['role'].include?(suffix)
        unless @config['parser'].parse_role("#{ @options['role'].gsub(suffix,'') }", 'boolean')
          puts "Role #{ @options['role'] } does not have an activated role! There is no #{ @options['role'].gsub(suffix,'') } role!"

          return false
        end
      else
        unless @config['parser'].parse_role("#{ @options['role'] }#{ suffix }", 'boolean')
          puts "Role #{ @options['role'] } does not have a deactivated role! There is no #{ @options['role'] }#{ suffix } role!"

          return false
        end
      end

      current_node_roles = nodes.first.run_list

      if current_node_roles.include?("role[#{ @options['role'] }]") && !@options['role'].include?(suffix)
        if state_toggle == 'activate'
          puts "The role #{ @options['role'] } is already activated for #{ nodes.first.name }!"
        else
          puts "The role #{ @options['role'] } is currently activated, setting it to #{ @options['role'] }#{ suffix }"

          target_run_list = current_node_roles.map {|r| r.gsub(@options['role'], "#{ @options['role'] }#{ suffix }") if current_node_roles.include?("role[#{ @options['role'] }]") }
        end
      elsif current_node_roles.include?("role[#{ @options['role'] }]") && @options['role'].include?(suffix)
        if state_toggle == 'activate'
          puts "The role #{ @options['role'] } is currently deactivated, setting it to #{ @options['role'].gsub(suffix, '') }"

          target_run_list = current_node_roles.map {|r| r.gsub(@options['role'], "#{ @options['role'].gsub(suffix, '') }") if current_node_roles.include?("role[#{ @options['role'] }]") }
        else
          puts "The role #{ @options['role'] } is already deactivated for #{ nodes.first.name }!"
        end
      elsif current_node_roles.include?("role[#{ @options['role'] }#{ suffix }]") #they passed in the reverse of a role that was already deactivated
        if state_toggle == 'activate'
          puts "The role #{ @options['role'] } is currently deactivated, setting it to it's activated state"

          target_run_list = current_node_roles.map {|r| r.gsub("#{ @options['role'] }#{ suffix }", "#{ @options['role'] }") if current_node_roles.include?("role[#{ @options['role'] }#{ suffix }]") }
        else
          puts "The role #{ @options['role'] } is already deactivated for #{ nodes.first.name }!"
        end
      elsif current_node_roles.include?("role[#{ @options['role'].gsub(suffix, '') }]") #they passed in the reverse of a role that was already activated
        if state_toggle == 'activate'
          puts "The role #{ @options['role'] } is already activated for #{ nodes.first.name }!"
        else
          puts "The role #{ @options['role'] } is currently activated, setting it to it's deactivated state"
          
          target_run_list = current_node_roles.map {|r| r.gsub("#{ @options['role'].gsub('suffix','') }", "#{ @options['role'] }") if current_node_roles.include?("role[#{ @options['role'].gsub('suffix','') }]") }
        end
      elsif !current_node_roles.include?("role[#{ @options['role'] }]") && @config['cheftacular']['role_toggling']['strict_roles']
        puts "The node does not have #{ @options['role'] } and strict roles is set to true, exiting..."

        return false
      elsif !current_node_roles.include?("role[#{ @options['role'] }]") && !@config['cheftacular']['role_toggling']['strict_roles']
        puts "The node does not have #{ @options['role'] } and strict roles is set to false, setting this new role..."

        target_run_list = current_node_roles + "role[#{ @options['role'] }"
      end

      unless target_run_list.empty?
        puts "Updating node run list for #{ nodes.first.name } from"

        ap current_node_roles

        puts "to:"

        ap target_run_list

        if skip_confirm || !@config['cheftacular']['role_toggling']['skip_confirm']
          puts "Enter Y/y to confirm."

          input = STDIN.gets.chomp

          return false unless ( input =~ /y|Y|yes|Yes/ ) == 0
        end

        @config[@options['env']]['node_roles_bag_hash']['node_roles'][nodes.first.name.gsub(/\d/,'')]['run_list'] = target_run_list

        nodes.first.send("run_list=", target_run_list)

        nodes.first.save

        @config['ChefDataBag'].save_node_roles_bag @options['env']

        @config['filesystem'].cleanup_file_caches('current')

        puts "Triggering deploy to set the new role..."

        @config['action'].deploy
      end
    end
  end
end
