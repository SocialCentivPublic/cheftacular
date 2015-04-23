class Cheftacular
  class StatelessActionDocumentation
    def update_tld
      @config['documentation']['stateless_action'] <<  [
        "`cft update_tld TLD` command will force a full dns update for a tld in the preferred cloud. " +
        "It will ensure all the subdomain entries are correct (based on the contents of the addresses data bag) " +
        "and update them if they are not. It will also create the local subdomain for the entry as well if it " +
        "does exist and point it to the correct private address."
      ]
    end
  end

  class StatelessAction
    def update_tld
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')
      
      raise "Undefined new tld to migrate to" if ARGV.length <= 1

      nodes = @config['getter'].get_true_node_objects(true)

      #We need to manually update beta nodes as they share the same env space as their non-beta counterparts TODO Refactor?
      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}] )

      addr_data = @config['getter'].get_addresses_hash @options['env']

      tld = ARGV[1]

      nodes.each do |n|

        @options['node_name'] = n.name

        domain_obj = PublicSuffix.parse addr_data[n.public_ipaddress]['dn']

        next unless domain_obj.domain == @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld'] #we can't create records for domains we dont manage in rax

        @config['stateless_action'].cloud "domain", "create:#{ tld }:#{ domain_obj.trd }:#{ n.public_ipaddress }"

        sleep 5 #don't want to to push updates to rax too fast

        @config['stateless_action'].cloud "domain", "create:#{ tld }:local.#{ domain_obj.trd }:#{ addr_data[n.public_ipaddress]['priv'] }"

        full_domain = "#{ domain_obj.trd }.#{ tld }"

        target_serv_index = @config[@options['env']]['addresses_bag_hash']['addresses'].count

        @config[@options['env']]['addresses_bag_hash']['addresses'].each do |serv_hash|
          target_serv_index = @config[@options['env']]['addresses_bag_hash']['addresses'].index(serv_hash) if serv_hash['name'] == n.name
        end

        @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_hash] ||= {}
        @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_hash]['dn'] = full_domain

        sleep 5 #prepare for next domain
      end

      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld'] = tld

      @config['ChefDataBag'].save_config_bag
      @config['ChefDataBag'].save_addresses_bag
    end
  end
end