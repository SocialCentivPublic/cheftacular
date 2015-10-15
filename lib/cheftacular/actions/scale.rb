
# all in one method that will interact with cloud interactor to bring up the server and obtain its initial root pass then run ubuntu bootstrap and chef_bootstrap
class Cheftacular
  class ActionDocumentation
    def scale
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft scale up|down [NUM_TO_SCALE]` will add (or remove) NUM_TO_SCALE servers from the server array. " +
        "This command will not let you scale down below 1 server.",

        [
          "    1. In the case of server creation, this command takes a great deal of time to execute. " +
          "It will output what stage it is currently on to the terminal but <b>you must not kill this command while it is executing</b>." +
          "A failed build may require the server to be destroyed / examined by a DevOps engineer."
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Scales an environment up or down (relies on roles)'
    end
  end

  class Action
    def scale type="up", num_to_scale=1
      type         = ARGV[1] if ARGV[1]
      num_to_scale = ARGV[2] if ARGV[2]

      raise "Unknown type for scaling: #{ type }" unless (type =~ /up|down/) == 0
      raise "Unknown scaling: #{ num_to_scale }"  unless num_to_scale.is_a?(Fixnum) && num_to_scale >= 1

      nodes = @config['getter'].get_true_node_objects

      base_node_names = {}

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: 'role[scalable]' }] )

      nodes.each do |n|
        #names are stored alphabetically so this will always put the result hash in the form of {base_name => highest N}
        base_node_names[n.name.gsub(/\d/,'')] ||= {}
        base_node_names[n.name.gsub(/\d/,'')][n.name]        = n.name.gsub(/[^\d]/,'')

        if base_node_names[n.name.gsub(/\d/,'')][n.name] > base_node_names[n.name.gsub(/\d/,'')]['highest_val'] || base_node_names[n.name.gsub(/\d/,'')]['highest_val'].nil?
          base_node_names[n.name.gsub(/\d/,'')]['highest_val'] = n.name.gsub(/[^\d]/,'').to_i 
        end
      end

      base_node_names.each_pair do |base_name, nodes_under_name_hash|
        raise "Cannot scale lower than 1" if (nodes_under_name_hash.keys-1).count <= num_to_scale && type == 'down'
      end

      if base_node_names.empty?
        puts("There are no nodes for #{ @options['role'] } in env #{ @options['env'] } that have scaling enabled.") unless options['quiet']
      end

      @options['force_yes']  = true
      @options['in_scaling'] = true

      scaling_node_defaults = @config['cheftacular']['scaling_nodes']

      (1..num_to_scale).each do |i|
        case type
        when 'up'
          base_node_names.each_pair do |base_name, nodes_under_name_hash|
            @options['node_name']   = base_name + ( node_under_name_hash['highest_val'] + i ).to_s.rjust(2, '0')

            if scaling_node_defaults.has_key?(base_name)
              @options['flavor_name'] = scaling_node_defaults[base_name].has_key?('flavor') ? scaling_node_defaults[base_name]['flavor'] : @config['cheftacular']['default_flavor_name']
              @options['descriptor']  = scaling_node_defaults[base_name].has_key?('descriptor') ? scaling_node_defaults[base_name]['descriptor'] : @options['node_name']
            else
              @options['flavor_name'] = @config['cheftacular']['default_flavor_name']
              @options['descriptor']  = @options['node_name']
            end

            puts("Preparing to scale #{ type } server #{ @options['node_name'] } on role #{ @options['role'] }!") unless @options['quiet']

            @config['stateless_action'].cloud_bootstrap
          end
        when 'down'
          base_node_names.each_pair do |base_name, nodes_under_name_hash|
            @options['node_name']   = base_name + ( node_under_name_hash['highest_val'] + i ).to_s.rjust(2, '0')

            puts("Preparing to scale #{ type } server #{ @options['node_name'] } on role #{ @options['role'] }!") unless @options['quiet']

            remove_client true
          end
        end

        sleep 15 if num_to_scale > 1
      end

      @config['ChefDataBag'].save_server_passwords_bag #we must save the auth bag here and not in the individual rax_bootstrap runs so they don't corrupt the bags

      @options['node_name'] = nil #if this is not nil deploy_role will try to deploy to a single server instead of the group

      @config['action'].deploy
    end
  end
end
