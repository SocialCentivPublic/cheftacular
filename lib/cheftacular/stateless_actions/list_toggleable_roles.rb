
class Cheftacular
  class StatelessActionDocumentation
    def list_toggleable_roles
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft list_toggleable_roles NODE_NAME` This command will allow you to see all toggleable roles for a node"
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Lists toggleable roles for a node'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def list_toggleable_roles possible_toggles=[]
      @options['node_name'] = ARGV[1] unless @options['node_name']

      raise "You have yet to fully configure your role toggling settings! Exiting..." if @config['cheftacular']['role_toggling'].has_key?('do_not_allow_toggling')

      nodes = @config['error'].is_valid_node_name_option?

      suffix = @config['cheftacular']['role_toggling']['deactivated_role_suffix']

      nodes.first.run_list.each do |role|
        role = role.gsub('role[','').gsub(']','')

        if !role.include?(suffix) && @config['parser'].parse_role("#{ role }#{ suffix }", 'boolean')
          possible_toggles << role
          possible_toggles << "#{ role }#{ suffix }"

        elsif role.include?(suffix) && @config['parser'].parse_role("#{ role.gsub(suffix,'') }", 'boolean')
          possible_toggles << role
          possible_toggles << role.gsub(suffix,'')
        end
      end

      puts "The current run_list for #{ @options['node_name'] } is:"

      ap nodes.first.run_list

      puts "\nThe possible toggles for #{ @options['node_name'] } are:"

      ap possible_toggles
    end
  end
end
