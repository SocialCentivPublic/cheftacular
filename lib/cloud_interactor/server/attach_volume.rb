class CloudInteractor
  class Server
    #handles self and create_and_attach case
    def attach_volume args
      @classes['volume'].read args['volume_name'], false

      if @main_obj['specific_volumes'].nil? || @main_obj['specific_volumes'].nil?
        
        create_hash                = { "display_name" => args['volume_name'] }
        create_hash['size']        = args['size'] if args['size']
        create_hash['volume_type'] = args['volume_type'] ? args['volume_type'] : 'SATA'

        @classes['volume'].create create_hash

        sleep 5

        @classes['volume'].read args
      end

      puts "Attaching #{ args['volume_name'] } to #{ args['server_name'] } in #{ IDENTITY }..."

      read args, false, 'name', 'server_name'

      specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval(IDENTITY).get @main_obj["specific_#{ IDENTITY }"].last['id']

      if args['device_location']
        specific_fog_object.attach_volume @main_obj['specific_volumes'].first['id'], args['device_location']
      else
        specific_fog_object.attach_volume @main_obj['specific_volumes'].first['id']
      end
    end
  end
end
