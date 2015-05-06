
class Cheftacular
  class DNS
    def initialize options, config
      @options, @config  = options, config
    end

    def update_cloudflare_from_array_of_domain_hashes target_domain, target_domain_records
      unless @config['helper'].does_cheftacular_config_have?(['cloudflare:api_key', 'cloudflare:user_email'])
        puts "Critical! You tried to run update_cloudflare but have not set a cloudflare_api_key or cloudflare_user_email! Please set these keys and run this method again!"

        exit
      end

      if @config[@options['env']]['config_bag_hash'][@options['sub_env']]['cloudflare_activated_domains'].empty?
        puts "Critical! Tere are no entries in the 'cloudflare_activated_domains' array for domain #{ target_domain }! Please open the #{ @options['env'] } data bag item " +
        "\"config\" and add the domains you want to be protected by cloudflare to the array as strings!"

        exit
      end

      @config['cloudflare'] = CloudFlare::connection(@config['cheftacular']['cloudflare']['api_key'], @config['cheftacular']['cloudflare']['user_email'])

      puts("Preparing to update cloudflare for domain #{ target_domain }...") unless @options['quiet']

      cloudflare_records_hash = fetch_cloudflare_records_as_hash target_domain

      puts('#'.ljust(4) + 'subdomain'.ljust(50) + 'type'.ljust(6) + 'ttl'.ljust(5) + 'mode'.ljust(20) + 'value') unless @options['quiet']

      domain_count = 1

      target_domain_records.each do |record_hash|
        next if record_hash['type'] =~ /NS/

        if record_hash['type'] =~ /A/
          record_hash['activate_cloudflare'] = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['cloudflare_activated_domains'].include?(record_hash['name'])
        end

        print(domain_count.to_s.ljust(4, '_') + record_hash['name'].ljust(50, '_') + record_hash['type'].ljust(6, '_') + record_hash['ttl'].to_s.ljust(5, '_'))

        if cloudflare_records_hash.has_key?("#{ record_hash['name'] }-#{ record_hash['type'] }") && ( !cloudflare_records_hash["#{ record_hash['name'] }-#{ record_hash['type'] }"].empty? ||
          cloudflare_record_does_include_value?(cloudflare_records_hash["#{ record_hash['name'] }-#{ record_hash['type'] }"], record_hash['value']) )

          edit_cloudflare_record target_domain, record_hash, cloudflare_records_hash
        else
          compile_cloudflare_record_srv_attributes_on_record_hash record_hash, target_domain

          @config['cloudflare'].rec_new(
            target_domain,
            record_hash['type'],
            record_hash['name'],
            record_hash['value'],
            record_hash['ttl'],
            record_hash['SRV_service'],
            record_hash['SRV_srvname'],
            record_hash['SRV_protocol'],
            record_hash['SRV_weight'],
            record_hash['SRV_port'],
            record_hash['SRV_target'],
            (record_hash['activate_cloudflare'] ? '1' : '0') #service_mode
          )

          print 'create'.ljust(20, '_')
        end

        domain_count += 1

        print record_hash['value'] unless @options['quiet']

        puts unless @options['quiet']
      end
    end

    def create_dns_record_for_domain_from_address_hash domain, address_hash, *args
      domain_obj = PublicSuffix.parse domain

      if args.include?('specific_domain_mode')
        puts("running cloud domain create_record:#{ domain_obj.domain }:#{ domain_obj.trd }:#{ address_hash['public'] }") if @options['verbose']

        @config['stateless_action'].cloud "domain", "create_record:#{ domain_obj.domain }:#{ domain_obj.trd }:#{ address_hash['public'] }"

        sleep 5

        puts("running cloud domain create_record:#{ domain_obj.domain }:local.#{ domain_obj.trd }:#{ address_hash['address'] }") if @options['verbose']

        @config['stateless_action'].cloud "domain", "create_record:#{ domain_obj.domain }:local.#{ domain_obj.trd }:#{ address_hash['address'] }"

        #set the wildcard domain for frontend load balancers
        if should_route_wildcard_requests?(address_hash['name'], @options['env'], address_hash['descriptor'])
          puts("running cloud domain create_record:#{ domain_obj.domain }:*:#{ address_hash['public'] }") if @options['verbose']
          
          @config['stateless_action'].cloud "domain", "create_record:#{ domain_obj.domain }:*:#{ address_hash['public'] }"
        end
      elsif args.empty?
        puts("running cloud domain create_record:#{ domain }:#{ address_hash['name'] }:#{ address_hash['public'] }") if @options['verbose']

        @config['stateless_action'].cloud "domain", "create_record:#{ domain }:#{ address_hash['name'] }:#{ address_hash['public'] }"

        sleep 5

        puts("running cloud domain create:create_record:#{ domain }:local.#{ address_hash['name'] }:#{ address_hash['address'] }") if @options['verbose']

        @config['stateless_action'].cloud "domain", "create_record:#{ domain }:local.#{ address_hash['name'] }:#{ address_hash['address'] }"
      end

      unless @config[@options['env']]['config_bag_hash'][@options['sub_env']]['cloudflare_activated_domains'].empty?
        return true unless @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld'] != domain_obj.tld

        target_domain_records  = []
        target_domain_records << {
          'name' => "#{ domain_obj.trd }.#{ domain_obj.domain }",
          'type' => 'A',
          'value' => address_hash['public'],
          'ttl'   => 300
        }

        target_domain_records << {
          'name' => "local.#{ domain_obj.trd }.#{ domain_obj.domain }",
          'type' => 'A',
          'value' => address_hash['address'],
          'ttl'   => 300
        }

        update_cloudflare_from_array_of_domain_hashes domain_obj.tld, target_domain_records
      end
    end

    def should_route_wildcard_requests? node_name, env, descriptor, should_route_requests=false
      repository_hash = descriptor.blank? ? {} : @config['parser'].parse_repository_hash_from_string(descriptor)

      if repository_hash.empty?
        puts "Blank repository hash parsed for #{ node_name } in #{ env } with descriptor #{ descriptor }. Setting should route wildcard requests for server to false."
      end

      #puts "repositories:#{ repository_hash['role'] }:#{ repository_hash['repo_name'] }:route_wildcard_requests_for_tld"

      if @config['helper'].does_cheftacular_config_have?(["repositories:#{ repository_hash['role'] }:route_wildcard_requests_for_tld"])
        should_route_requests = @config['cheftacular']['repositories'][repository_hash['role']]['route_wildcard_requests_for_tld'] == 'true'
      end

      should_route_requests
    end

    def compile_address_hash_for_server_from_options *args
      target_serv_index = nil
      tld               = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']

      args.each do |arg|
        if arg.include?('set_specific_domain:')
          full_domain = arg.split(':').last

          args << 'set_domain_name'
        end
      end

      full_domain ||= "#{ @options['node_name'] }.#{ tld }"

      @config[@options['env']]['addresses_bag_hash']['addresses'].each do |serv_hash|
        target_serv_index = @config[@options['env']]['addresses_bag_hash']['addresses'].index(serv_hash) if serv_hash['name'] == @options['node_name']
      end

      #EX: "name": "api1", "public": "1.2.3.4", "address": "10.208.1.2", "dn":"api1.example.com", "descriptor": "lb:my-backend-codebase"
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index] ||= {}                                      unless args.include?('set_hash_to_nil')
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['name']       = @options['node_name']       if args.include?('set_node_name') || args.include?('set_all_attributes')
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['public']     = @options['address']         if args.include?('set_public_address') || args.include?('set_all_attributes')
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['address']    = @options['private_address'] if args.include?('set_private_address') || args.include?('set_all_attributes')
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['dn']         = full_domain                 if args.include?('set_domain_name') || args.include?('set_all_attributes')
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['descriptor'] = (@options['descriptor'].nil? ? @options['node_name'] : @options['descriptor']) if args.include?('set_descriptor') || args.include?('set_all_attributes')

      if !target_serv_index.nil? && target_serv_index.is_a?(Fixnum) && !@options['dont_remove_address_or_server'] && args.include?('set_hash_to_nil')
        puts("Found entry in addresses data bag corresponding to #{ @options['node_name'] } for #{ @options['env'] }, removing...") unless @options['quiet']

        @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index] = nil
      
        @config[@options['env']]['addresses_bag_hash']['addresses'] = @config[@options['env']]['addresses_bag_hash']['addresses'].compact

        domain_obj = PublicSuffix.parse @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['dn']

        @config['stateless_action'].cloud "domain", "destroy_record:#{ domain_obj.tld }:#{ domain_obj.trd }" if domain_obj.tld == @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']
      end

      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index] unless args.include?('set_hash_to_nil')
    end

    private

    def fetch_cloudflare_records_as_hash target_domain, ret_hash={}
      request                 = @config['cloudflare'].rec_load_all(target_domain)['response']['recs']
      original_records, count = [], 0

      while request['has_more']
        original_records << request['objs']

        count += request['count']

        request = @config['cloudflare'].rec_load_all(target_domain, count)['response']['recs']
      end

      original_records << request['objs']

      original_records.flatten.each do |record_hash|
        ret_hash["#{ record_hash['name'] }-#{ record_hash['type'] }"] ||= []
        ret_hash["#{ record_hash['name'] }-#{ record_hash['type'] }"]  << record_hash
      end

      ret_hash
    end

    def edit_cloudflare_record target_domain, record_hash, cloudflare_records_hash
      possible_matches = cloudflare_records_hash["#{ record_hash['name'] }-#{ record_hash['type'] }"]

      raise "Critical! No cloudflare record was found to edit for #{ target_domain }: #{ record_hash['name'] }!" if possible_matches.nil?

      if possible_matches.count > 1
        possible_matches.each do |match_hash|
          if match_hash.has_key?('matched_already')
            next
          else
            compile_cloudflare_record_srv_attributes_on_record_hash record_hash, target_domain

            begin
              @config['cloudflare'].rec_edit(
                target_domain,
                record_hash['type'],
                match_hash['rec_id'],
                record_hash['name'],
                record_hash['value'],
                record_hash['ttl'],
                record_hash['activate_cloudflare'],
                record_hash['priority'],
                record_hash['SRV_service'],
                record_hash['SRV_srvname'],
                record_hash['SRV_protocol'],
                record_hash['SRV_weight'],
                record_hash['SRV_port'],
                record_hash['SRV_target']
              )

              match_hash['matched_already'] = true

              print 'edit_on_multi_match_'.ljust(19, '_')
            rescue CloudFlare::RequestError => e
              if e.message == 'A record with those settings already exists.'
                print 'edit_fail_match_'

                next
              else
                @config['helper'].exception_output "There was an issue updating Cloudflare! Please create an issue on the cheftacular repository with this stacktrace!", e
              end
            end

            break
          end
        end
      else
        print 'edit'.ljust(20, '_')

        @config['cloudflare'].rec_edit(target_domain, record_hash['type'], possible_matches[0]['rec_id'], record_hash['name'], record_hash['value'], record_hash['ttl'])
      end
    end

    def cloudflare_record_does_include_value? cloudflare_record, record_hash_value
      cloudflare_record.each do |match_record|
        return true if record_hash_value == match_record['content']
      end

      false
    end

    def compile_cloudflare_record_srv_attributes_on_record_hash record_hash, target_domain
      return false unless record_hash['type'].upcase == 'SRV'

      record_hash['SRV_service']  = record_hash['name'].split('.')[0]
      record_hash['SRV_srvname']  = target_domain
      record_hash['SRV_protocol'] = record_hash['name'].split('.')[1]
      record_hash['SRV_weight']   = record_hash['value'].split(' ')[0].to_i
      record_hash['SRV_port']     = record_hash['value'].split(' ')[1].to_i
      record_hash['SRV_target']   = record_hash['value'].split(' ')[2]
      record_hash['value']        = "#{ record_hash['priority'] } IN SRV #{ record_hash['SRV_weight'] } #{ record_hash['SRV_port'] } #{ record_hash['SRV_target'] }."#10 IN SRV 5 8806 somewhere.com
      #record_hash['name']         = ''
    end
  end
end