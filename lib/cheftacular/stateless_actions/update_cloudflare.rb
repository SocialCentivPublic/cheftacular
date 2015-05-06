class Cheftacular
  class StatelessActionDocumentation
    def update_cloudflare_dns_from_cloud
      @config['documentation']['stateless_action'] <<  [
        "`cft update_cloudflare_dns_from_cloud` command will force a full dns update for cloudflare. ",

        [
          "    1. It will ensure all the subdomain entries are correct (based on the contents of the addresses data bag) " +
          "and update them if they are not. It will also create the local subdomain for the entry as well if it " +
          "does exist and point it to the correct private address for an environment.",

          "    2. This command will also ensure any dns records on your cloud are also migrated over to cloudflare as well. " +
          "This also includes the reverse in the event you would like to turn off cloudflare."
        ]
      ]
    end
  end

  class StatelessAction
    def update_cloudflare_dns_from_cloud
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      target_domain = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']

      @config['stateless_action'].update_tld 'self'

      target_domain_records = @config['stateless_action'].cloud('domain', "read:#{ target_domain }")["records_for_#{ target_domain }"]

      @config['DNS'].update_cloudflare_from_array_of_domain_hashes target_domain, target_domain_records
    end
  end
end
