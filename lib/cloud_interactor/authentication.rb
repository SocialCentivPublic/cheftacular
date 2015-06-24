
class CloudInteractor
  class Authentication
    def initialize auth_hash, options={} 
      @auth_hash = auth_hash
      @options   = options
    end

    def auth_service interaction_class
      except_keys = []

      interaction_class = case interaction_class.downcase
                          when 'volume'
                            case @options['preferred_cloud']
                            when 'rackspace'
                              except_keys = [:provider, :version]

                              'Rackspace::BlockStorage'
                            else
                              raise "CloudInteractor Does not currently support this #{ options['preferred_cloud'] }'s' volume creation at this time"
                            end
                          when 'dns'
                            case @options['route_dns_changes_via']
                            when 'rackspace' 
                              except_keys = [:version, :rackspace_region]

                              interaction_class
                            else
                              except_keys = [:version]

                              interaction_class
                            end
                          else
                            interaction_class
                          end

      classes_to_inject = interaction_class.split('::')
      classes_to_inject = classes_to_inject.map { |str| str.camelcase }  

      cloud_hash = case @options['preferred_cloud']
                   when 'rackspace' 
                     {
                       provider:            'Rackspace',
                       rackspace_username:  @auth_hash['cloud_authentication'][@options['preferred_cloud']]['username'],
                       rackspace_api_key:   @auth_hash['cloud_authentication'][@options['preferred_cloud']]['api_key'],
                       version:             :v2,
                       rackspace_region:    @options['preferred_cloud_region'].to_sym,
                       connection_options:  {}
                     }
                   when 'digitalocean'
                     {
                       provider:               'DigitalOcean',
                       digitalocean_api_key:   @auth_hash['cloud_authentication'][@options['preferred_cloud']]['api_key'],
                       digitalocean_client_id: @auth_hash['cloud_authentication'][@options['preferred_cloud']]['client_id'],
                       version:                :v1
                     }
                   else raise "CloudInteractor Does not currently support #{ @options['preferred_cloud'] } at this time"
                   end

      if interaction_class == 'DNS'
        cloud_hash = if @options['route_dns_changes_via'] == @options['preferred_cloud']
                       cloud_hash
                     else 
                       case @options['route_dns_changes_via']
                       when 'rackspace'
                         cloud_hash
                       when 'dnsimple'
                         {
                           provider: 'dnsimple',
                           dnsimple_email:    @auth_hash['cloud_authentication'][@options['route_dns_changes_via']]['email'],
                           dnsimple_password: @auth_hash['cloud_authentication'][@options['route_dns_changes_via']]['password'],
                           dnsimple_token:    @auth_hash['cloud_authentication'][@options['route_dns_changes_via']]['token']
                         }
                       else raise "CloudInteractor does not currently support #{ @options['route_dns_changes_via'] } as a DNS creation provider at this time"
                       end
                     end
      end

      Fog.class_eval(classes_to_inject.join('::')).new(cloud_hash.delete_if { |key, value| except_keys.flatten.include?(key) })
    end
  end
end
