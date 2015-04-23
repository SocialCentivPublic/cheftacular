class CloudInteractor
  class Domain
    def destroy_record args, already_exists=false
      read args, false

      @main_obj['specific_records'][args[IDENTITY.singularize]].each do |record_hash|
        already_exists = true if record_hash['name'] == "#{ args['subdomain'] }.#{ args[IDENTITY.singularize] }"

        args['id'] = record_hash['id']

        break if already_exists
      end

      raise "Subdomain not found for #{ args[IDENTITY.singularize] }" unless already_exists

      puts "Destroying #{ args['subdomain'] } from #{ args[IDENTITY.singularize] }..."

      specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval('zones').get @main_obj["specific_#{ IDENTITY }"].last['id']

      specific_fog_object.records.get(args['id']).destroy
    end
  end
end
