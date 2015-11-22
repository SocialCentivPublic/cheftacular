class CloudInteractor
  class Server
    def list_volumes args, output=true
      puts "(#{ IDENTITY }) Returning list of volumes for #{ args['server_name'] } in #{ IDENTITY }..."

      read(args, false, 'name', 'server_name') if @main_obj["specific_#{ IDENTITY }"].nil?

      specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval(IDENTITY).get @main_obj["specific_#{ IDENTITY }"].last['id']

      @main_obj["#{ IDENTITY }_volume_list_request"] = JSON.parse(specific_fog_object.attachments.all.to_json)

      @main_obj['server_attached_volumes'] ||= {}

      @main_obj['server_attached_volumes'][args['server_name']] ||= []

      @main_obj["#{ IDENTITY }_volume_list_request"].each do |volume_hash|
        @classes['volume'].read volume_hash, false, 'id'

        @main_obj['server_attached_volumes'][args['server_name']] << @main_obj['specific_volumes'].last
      end

      ap( @main_obj['server_attached_volumes'][args['server_name']] ) if output
    end
  end
end
