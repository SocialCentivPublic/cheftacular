class CloudInteractor
  class Domain
    def create_record args, already_created=false
      args['type']          ||= 'A'
      args['ttl']           ||= 300
      args['target_domain'] ||= @classes['clouds'].parse_provider_domain_record_name(args)
      args['target_domain']   = args[IDENTITY.singularize] if args['subdomain'].blank?

      read args, false

      @main_obj['specific_records'][args[IDENTITY.singularize]].each do |record_hash|
        already_created = true if record_hash['name'] == args['target_domain'] && record_hash['type'] == args['type']

        break if already_created
      end

      if already_created
        update_record args

      else
        specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval('zones').get @main_obj["specific_#{ IDENTITY }"].last['id']

        specific_fog_object.records.create(name: args['target_domain'], value: args['target_ip'], type: args['type'], ttl: args['ttl'])

        puts "Attached #{ args['subdomain'] } (#{ args['target_ip'] }) to #{ args[IDENTITY.singularize] } (#{ args['target_domain'] })..."
      end
    end
  end
end
