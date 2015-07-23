class CloudInteractor
  class CloudProvider
    def initialize options={}
      @options   = options
    end

    #args will always be a hash
    def parse_provider_domain_record_name args
      case @options['route_dns_changes_via']
      when 'rackspace'
        "#{ args['subdomain'] }.#{ args['domain'] }"
      when 'dnsimple'
        args['subdomain']
      else
        "#{ args['subdomain'] }.#{ args['domain'] }"
      end
    end
  end
end
