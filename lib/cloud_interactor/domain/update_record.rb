class CloudInteractor
  class Domain
    def update_record args, already_created=false
      args['type'] ||= 'A'
      args['ttl']  ||= 300

      read args, false

      puts "Updating #{ args['subdomain'] } for #{ args[IDENTITY.singularize] }..."

      @main_obj['specific_records'][args[IDENTITY.singularize]].each do |record_hash|
        already_created = true if record_hash['name'] == "#{ args['subdomain'] }.#{ args[IDENTITY.singularize] }"

        args['id'] = record_hash['id']

        break if already_created
      end

      if already_created
        specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval('zones').get @main_obj["specific_#{ IDENTITY }"].last['id']

        #the fact that there is no public update method is silly
        specific_record = specific_fog_object.records.get(args['id'])

        case @options['preferred_cloud']
        when 'rackspace'
          specific_record.type  = args['type']
          specific_record.value = args['target_ip']
          specific_record.ttl   = args['ttl']

          specific_record.save
        else
          raise "Unsupported action #{ __method__ } for #{ @options['preferred_cloud'] }. Please create an issue on github or submit a PR to fix this issue."
        end

        puts "Updated #{ args['subdomain'] } (#{ args['target_ip'] }) to #{ args[IDENTITY.singularize] }..."
      else
        create_record [ args ]
      end
    end
  end
end