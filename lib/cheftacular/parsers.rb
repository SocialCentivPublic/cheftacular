
class Cheftacular
  class Parser
    def initialize options, config
      @options, @config  = options, config
    end

    #parses and *validates* the inputs from the initializer
    def parse_context
      return if @config['repository'] && @config['command'] && @config['role']

      roles ||= []

      @config['chef_roles'].each {|r| roles << r.name }

      @options['command'] = ARGV[0] unless @options['command']

      unless @config['helper'].is_stateless_command?(@options['command'])
        parse_repository(@options['repository'])

        parse_role(@options['role'])
      end

      parse_node_name(@options['node_name']) if @options['node_name']

      parse_address(@options['address']) if @options['address']

      parse_and_set_revision if @options['target_revision'] || @options['unset_revision']
    end

    #try and get the most accurate name of the repo
    def parse_application_context
      working_dir = Dir.getwd.split('/').last

      #if there is no mapping setup for the directory, try and parse it from the .ruby-gemset file
      if File.exist?(File.expand_path("#{ @config['locs']['app-root'] }/.ruby-gemset")) && !@config['getter'].get_repository_from_role_name(working_dir, "has_value?")
        working_dir = File.read(File.expand_path("#{ @config['locs']['app-root'] }/.ruby-gemset")).chomp
      end

      if @config['getter'].get_repository_from_role_name(working_dir, "has_value?")
        @options['repository'] = working_dir unless @options['repository'] #enable custom -r or -R flags to get through in application directories

        parse_repository(@options['repository'])

        @options['command']    = ARGV[0] unless @config['helper'].is_not_command_or_stateless_command?(ARGV[0])
      end

      return if !@options['codebase'].nil? && !@options['role'].nil? && !@options['command'].nil?
      return if !@options['command'].nil? && @config['helper'].is_stateless_command?(ARGV[0])
    end

    def parse_repository repository, set_variables=true
      repo_check_array = []

      @config['cheftacular']['repositories'].each_value do |h|
        repo_check_array << h['repo_name'].include?(repository) unless repository.nil?
      end

      if repository.nil? && @config['helper'].running_in_mode?('devops')
        raise "Unable to parse a repository, please pass in the argument -c REPOSITORY to pass a repo"

      elsif repo_check_array.include?(true)
        @config['cheftacular']['repositories'].each_pair do |key, repo_hash|
          @options['role'] = key if repo_hash['repo_name'] == repository && set_variables && @options['role'].nil?
        end
      else
        raise "Unable to parse repository: #{ repository }, the repository you're referring to does not exist in your cheftacular.yml."
      end
    end

    def parse_role role, mode="set"
      roles ||= []
      @config['chef_roles'].each {|r| roles << r.name }

      case mode
      when 'set'
        if role.nil?               then raise "Unable to parse a role, please pass in the argument -r ROLE_NAME to pass a role"
        elsif roles.include?(role) then @options['role'] = role
        else                            raise "Unable to parse role: #{ role }, #{ role } does not represent a valid role"
        end
      when 'boolean'
        roles.include?(role)
      end
    end

    def parse_node_name name
      nodes ||= []
      @config['chef_nodes'].each {|n| nodes << n.name }

      if name.nil?               then raise "You attempted to specify a node_name but did not pass one, please use -n NODE_NAME"
      elsif nodes.include?(name) then @options['node_name'] = name
      else                            raise "Unable to parse node_name: #{ name }, the node you're referring to does not exist."
      end
    end

    def parse_address address
      addresses ||= []
      @config['chef_nodes'].each {|n| addresses << n.public_ipaddress }

      if address.nil?                   then raise "You attempted to specify an address but did not pass one, please use -a IP_ADDRESS"
      elsif addresses.include?(address) then @options['address'] = address
      else                                   raise "Unable to parse address: #{ address }, the address you're referring to is not part of any environment"
      end
    end

    def parse_and_set_revision
      raise "Cannot set or unset target_revision without a role" unless @options['role']

      if @options['target_revision']
        @config[@options['env']]['config_bag_hash'][@options['sub_env']]['app_revisions'][@config['getter'].get_codebase_from_role_name(@options['role'])] = @options['target_revision']

      elsif @options['unset_revision']
        @config[@options['env']]['config_bag_hash'][@options['sub_env']]['app_revisions'][@config['getter'].get_codebase_from_role_name(@options['role'])] = "<use_default>"

      end

      @config['ChefDataBag'].save_config_bag 
    end

    def array_of_nodes_contains_node_name? nodes, node_name, names=[]
      nodes.each { |node| names << node['name'] }

      names.include? node_name
    end

    def index_of_node_name_in_array_of_nodes nodes, node_name, names=[]
      nodes.each { |node| names << node['name'] }

      names.index node_name
    end

    #parse nodes out of array based on hash, ex: [{ unless: 'role[rails]'}, {if: 'role[worker]'}, { if: { run_list: 'role[db]', role: 'pg_data' } }]
    def exclude_nodes nodes, statement_arr, only_one_node = false, ret_arr = []
      nodes.each do |n|
        go_next = false

        statement_arr.each do |statement_hash|
          statement_hash.each_pair do |if_key, statement|
            if statement.is_a?(String)
              self.instance_eval("go_next = true #{ if_key.to_s } n.run_list.include?('#{ statement }')")

            elsif statement.is_a?(Hash)
              eval_string = "go_next = true #{ if_key.to_s } "
              eval_list = []

              statement.each_pair do |run_key, check_val|
                eval_list << "n.run_list.include?('#{ check_val }')"  if run_key == :run_list
                eval_list << "!n.run_list.include?('#{ check_val }')" if run_key == :not_run_list
                eval_list << "n.chef_environment == '#{ check_val }'" if run_key == :env
                eval_list << "n.chef_environment != '#{ check_val }'" if run_key == :not_env
                eval_list << "@options['role'] == '#{ check_val }'"   if run_key == :role
                eval_list << "@options['role'] != '#{ check_val }'"   if run_key == :not_role
                eval_list << "n.name == '#{ check_val }'"             if run_key == :node
                eval_list << "n.name != '#{ check_val }'"             if run_key == :not_node
                eval_list << "#{ check_val }"                         if run_key == :eval #careful with this, you need to pass in an already parsed string
              end

              self.instance_eval(eval_string + eval_list.join(' && '))
            else
              raise "Invalid statement type (#{ statement.class }) - Statement must be string or hash"
            end
          end
        end

        next if go_next

        ret_arr << n

        break if only_one_node
      end

      if @options['verbose'] && @options['command'] != "client_list" 
        puts("Parsed #{ ret_arr.count } nodes. Preparing to run on #{ ret_arr.map { |n| n.name }.join(',') } in env #{ @options['env'] } on role #{ @options['role'] }")
      end

      ret_arr
    end

    def parse_runtime_arguments num_of_args=0, mode='normal'
      case mode
      when 'normal'
        case num_of_args
        when 0      then raise "You attempted to run #{ __method__ } with 0 args! Look up this method from the stacktrace!"
        when 1      then ARGV[num_of_args-1]
        when 2..100 then ARGV[0..(num_of_args-1)]
        end
      when 'range'  then ARGV[1..ARGV.length-1].join(' ')
      else  raise "You passed #{ mode }. This is not yet implemented for #{ __method__ }"
      end
    end

    def parse_to_dns dns_string
      raise "Unable to parse DNS without @option['node_name'] for #{ dns_string }!" if dns_string.include?('NODE_NAME') && @options['node_name'].nil?
      raise "Unable to parse DNS without a tld set in the config bag for #{ @options['env'] }!" if dns_string.include?('ENV_TLD') && @config[@options['env']]['config_bag_hash']['tld'].nil?

      dns_string.gsub('NODE_NAME', @options['node_name']).gsub('ENV_TLD', @config[@options['env']]['config_bag_hash']['tld'])
    end
  end
end
