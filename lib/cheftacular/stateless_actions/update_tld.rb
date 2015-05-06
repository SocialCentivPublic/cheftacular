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
    def update_tld target_tld=""
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')
      
      raise "Undefined new tld to migrate to" if ARGV.length <= 1 && target_tld.blank? 

      nodes = @config['getter'].get_true_node_objects(true)

      #We need to manually update beta nodes as they share the same env space as their non-beta counterparts TODO Refactor?
      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}] )

      address_hash = @config['getter'].get_addresses_hash @options['env']

      target_tld = ARGV[1] if target_tld.blank?

      old_tld = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']

      if target_tld == 'self'
        target_tld = old_tld
      end

      nodes.each do |n|

        @options['node_name'] = n.name

        domain_obj = PublicSuffix.parse address_hash[n.public_ipaddress]['dn']

        next unless domain_obj.domain == old_tld #we can't create records for domains not managed under the environment's tld

        #TODO CHECK CLOUD IF TLD EXISTS

        specific_domain = "#{ domain_obj.trd }.#{ target_tld }"

        if specific_domain != "#{ @options['node_name'] }.#{ target_tld }"
          @config['DNS'].create_dns_record_for_domain_from_address_hash(specific_domain, address_hash[n.public_ipaddress], "specific_domain_mode")
        end

        @config['DNS'].create_dns_record_for_domain_from_address_hash(target_tld, address_hash[n.public_ipaddress])

        @config['DNS'].compile_address_hash_for_server_from_options("set_specific_domain_name:#{ specific_domain }")

        sleep 5 #prepare for next domain
      end

      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld'] = target_tld

      puts "BAG TLD::#{ @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld'] }"

      @config['ChefDataBag'].save_config_bag
      @config['ChefDataBag'].save_addresses_bag
    end
  end
end
