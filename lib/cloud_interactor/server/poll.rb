class CloudInteractor
  class Server
    def poll args
      read args, false

      raise "Server #{ args['name'] } does not exist!" if @main_obj["specific_#{ IDENTITY }"].empty?

      puts "Polling #{ args['name'] } for status...(execution will continue when the server is finished building)"

      specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval(IDENTITY).get @main_obj["specific_#{ IDENTITY }"].last['id']

      #specific_servers is an ARRAY, the latest status of the server is the LAST ENTRY
      duration_hash = specific_fog_object.wait_for { ready? }

      @main_obj['output']["created_servers"] ||= []

      @main_obj['output']["created_servers"] << JSON.parse(specific_fog_object.reload.to_json)

      puts "#{ args['name'] } became active in #{ duration_hash[:duration] } seconds!"
    end
  end
end
