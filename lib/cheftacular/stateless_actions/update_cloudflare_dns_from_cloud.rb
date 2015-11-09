class Cheftacular
  class StatelessActionDocumentation
    def update_cloudflare_dns_from_cloud
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft update_cloudflare_dns_from_cloud [skip_update_tld]` command will force a full dns update for cloudflare. ",

        [
          "    1. It will ensure all the subdomain entries are correct (based on the contents of the addresses data bag) " +
          "and update them if they are not. It will also create the local subdomain for the entry as well if it " +
          "does exist and point it to the correct private address for an environment.",

          "    2. This command will also ensure any dns records on your cloud are also migrated over to cloudflare as well. " +
          "This also includes the reverse in the event you would like to turn off cloudflare.",

          "    3. The argument `skip_update_tld` will stop the long process of checking and updating all the server domains " +
          "_before_ cloudflare is updated. Only skip if you believe your domain info on your cloud is accurate."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Forces a refresh / update of all relevant cloudflare records'
    end
  end

  class StatelessAction
    def update_cloudflare_dns_from_cloud
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      target_domain = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']

      @config['stateless_action'].update_tld 'self' unless ARGV[1] == 'skip_update_tld'

      target_domain_records = @config['stateless_action'].cloud('domain', "read:#{ target_domain }")["records_for_#{ target_domain }"]

      @config['DNS'].update_cloudflare_from_array_of_domain_hashes target_domain, target_domain_records
    end
  end
end
