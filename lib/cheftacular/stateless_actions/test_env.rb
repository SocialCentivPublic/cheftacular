#boots or destroys the current devstaging environment
class Cheftacular
  class StatelessActionDocumentation
    def test_env
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft test_env [TARGET_ENV] boot|destroy` will create (or destroy) the test nodes for a particular environment " +
        "(defaults to staging, prod split-envs can be set with `-p`). Please read below for how TARGET_ENV works",

        [
          "    1. TARGET_ENV changes functionality depending on the overall (like staging / production) environment",

          "        1. In staging, it cannot be set and defaults to split (splitstaging).",

          "        2. In production, it can be splita, splitb, splitc, or splitd.",

          "        3. The default tld used should change depending on which environment you are booting / destroying. " +
          "This is set in the environment's config data bag under the tld key"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Allows you to boot split environments'
    end
  end

  class StatelessAction
    def test_env split_env="splitstaging", type="boot"
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      env_index = @options['env'] == 'staging' ? 1 : 2

      split_env = ARGV[1] unless @options['env'] == 'staging'

      type = ARGV[env_index] if ARGV[env_index]

      split_envs = @config['cheftacular']['run_list_environments'][@options['env']]

      raise "Unknown split_env: #{ split_env }, can only be #{ split_envs.values.join(', ') }" unless (split_env =~ /#{ split_envs.values.join('|') }/) == 0

      raise "Unknown type: #{ type }, can only be 'boot' or 'destroy'" unless (type =~ /boot|destroy/) == 0

      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ split_env.split('split').join('split_') }]" }, { unless: { env: @options['env'] }}])

      @options['force_yes']  = true
      @options['in_scaling'] = true

      case type
      when 'boot'
        @config['cheftacular']['split_env_nodes'].each_pair do |name, config_hash|
          config_hash           ||= {}
          true_name               = name.gsub('SPLITENV', split_env)
          @options['sub_env']     = split_env
          @options['node_name']   = "#{ true_name }#{ 'p' if @options['env'] == 'production' }" 
          @options['flavor_name'] = config_hash.has_key?('flavor') ? config_hash['flavor'] : @config['cheftacular']['default_flavor_name']
          @options['descriptor']  = config_hash.has_key?('descriptor') ? "#{ config_hash['descriptor'] }-#{ split_env }" : name
          @options['with_dn']     = config_hash.has_key?('dns_config') ? @config['parser'].parse_to_dns(config_hash['dns_config']) : @config['parser'].parse_to_dns('NODE_NAME.ENV_TLD')
                                    
          next if nodes.map { |n| n.name }.include?(@options['node_name'])

          puts("Preparing to boot server #{ @options['node_name'] } for #{ @options['env'] }'s #{ split_env } environment!") unless @options['quiet']

          @config['stateless_action'].cloud_bootstrap

          sleep 15
        end

        @config['ChefDataBag'].save_server_passwords_bag
      when 'destroy'
        @options['delete_server_on_remove'] = true

        nodes.each do |node|

          @options['node_name'] = node.name

          puts("Preparing to destroy server #{ @options['node_name'] } for #{ @options['env'] }'s #{ split_env } environment!") unless @options['quiet']

          @config['stateless_action'].remove_client

          sleep 15
        end
      end
    end
  end
end
