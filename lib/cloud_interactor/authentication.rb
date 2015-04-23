
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
                            case @options['preferred_cloud']
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
                       provider:            @options['preferred_cloud'].capitalize,
                       rackspace_username:  @auth_hash['cloud_auth'][@options['preferred_cloud']]['username'],
                       rackspace_api_key:   @auth_hash['cloud_auth'][@options['preferred_cloud']]['api_key'],
                       version:             :v2,
                       rackspace_region:    @options['preferred_cloud_region'].to_sym,
                       connection_options:  {}
                     }.delete_if { |key, value| except_keys.flatten.include?(key) }
                   else raise "CloudInteractor Does not currently support #{ @options['preferred_cloud'] } at this time"
                   end

      Fog.class_eval(classes_to_inject.join('::')).new(cloud_hash)
    end
  end
end
