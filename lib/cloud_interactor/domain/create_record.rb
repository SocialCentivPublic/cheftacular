class CloudInteractor
  class Domain
    def create_record args, already_created=false
      args['type'] ||= 'A'
      args['ttl']  ||= 300

      read args, false

      @main_obj['specific_records'][args[IDENTITY.singularize]].each do |record_hash|
        already_created = true if record_hash['name'] == "#{ args['subdomain'] }.#{ args[IDENTITY.singularize] }"

        break if already_created
      end

      if already_created
        update_record args

      else
        specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval('zones').get @main_obj["specific_#{ IDENTITY }"].last['id']

        specific_fog_object.records.create(name: "#{ args['subdomain'] }.#{ args[IDENTITY.singularize] }", value: args['target_ip'], type: args['type'], ttl: args['ttl'])

        puts "Attached #{ args['subdomain'] } (#{ args['target_ip'] }) to #{ args[IDENTITY.singularize] }..."
      end
    end
  end
end
