class CloudInteractor
  class Helper
    def initialize main_obj, classes, options={}
      @main_obj  = main_obj
      @options   = options
      @classes   = classes
    end

    def set_specific_identity args, key_to_extract
      case args.class.to_s
      when "Hash"   then args[key_to_extract]
      when "String" then args
      end
    end

    def generic_list_call identity, resource, output=true
      puts "(#{ identity.capitalize }) Returning list of #{ identity } for #{ resource == 'DNS' ? @options['route_dns_changes_via'] : @options['preferred_cloud'] }..."

      @main_obj[identity] = JSON.parse(@classes['auth'].auth_service(resource).instance_eval(identity).to_json)

      ap(@main_obj[identity]) if output && !@options['in_scaling']
    end

    def generic_read_parse args, identity, output=true, mode='name', search_key='name'
      search_key = mode if mode != 'name' && search_key == 'name'

      specific_identity = set_specific_identity args, search_key

      @main_obj["specific_#{ identity }"] ||= []

      @main_obj[identity].each do |identity_hash|
        if specific_identity.nil?
          puts("(#{ identity.capitalize }) Query arguments \"#{ args }\" are not being mapped correctly for #{ identity.singularize } reads from method #{ caller[3][/`.*'/][1..-2] }! This read will return no objects.")
        
          break
        end

        next if identity_hash[mode] && !identity_hash[mode].include?(specific_identity)
        next if identity == 'servers' && identity_hash['state'] == 'DELETED' #FOR SOME REASON you will get status 'DELETED' items on reads sometimes for rackspace servers

        case identity
        when 'image' then @main_obj["specific_#{ identity }"] << identity_hash unless identity_hash[mode].include?(@options['virtualization_mode'])
        else              @main_obj["specific_#{ identity }"] << identity_hash
        end

        ap(identity_hash) if output
      end

      puts("(#{ identity.capitalize }) #{ specific_identity } matched and being utilized for #{ identity }.") unless @main_obj["specific_#{ identity }"].empty?
      puts("(#{ identity.capitalize }) #{ specific_identity } not found in #{ identity }!")                       if @main_obj["specific_#{ identity }"].empty?
    end

    def generic_destroy_parse destroy_hash, identity, resource, mode='name'
      puts("Queried #{ identity } #{ ap @main_obj["specific_#{ identity }"] }") if @options['verbose']

      raise "#{ identity.singularize } not found for #{ destroy_hash[mode] }" unless @main_obj["specific_#{ identity }"]

      if destroy_hash[mode].empty? || @main_obj["specific_#{ identity }"].last[mode] != destroy_hash[mode] #without this it will delete the first object in the list, this is obviously bad
        raise "Name mismatch on destroy! Expected #{ destroy_hash[mode] } and was going to destroy #{ @main_obj["specific_#{ identity }"].last[mode] }"
      end

      puts "(#{ identity.capitalize }) Destroying #{ destroy_hash[mode] }..."

      specific_fog_object = @classes['auth'].auth_service(resource).instance_eval(identity).get @main_obj["specific_#{ identity }"].last['id']

      if specific_fog_object.respond_to?(:delete)
        @main_obj["#{ identity }_destroy_request"] = specific_fog_object.delete
      else
        @main_obj["#{ identity }_destroy_request"] = specific_fog_object.destroy
      end

      puts "(#{ identity.capitalize }) REMINDER! This destroy is not instant! It can take up to a few minutes for a #{ identity.singularize } to actually be fully destroyed!"
    end
  end
end
