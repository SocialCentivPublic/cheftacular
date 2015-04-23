class CloudInteractor
  class Server
    def detach_volume args, out=""
      read args, false, 'name', 'server_name'

      read_volume args, false, true

      puts "Detaching #{ args['volume_name'] } from #{ args['server_name'] } in #{ IDENTITY }..."

      specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval(IDENTITY).get @main_obj["specific_#{ IDENTITY }"].last['id']

      specific_fog_object.attachments.each do |attachment|
        next unless attachment.volume_id == @main_obj["specific_attached_volumes"].first['id']
        
        out << attachment.detach.to_s
      end

      puts "The state of the volume detachment is #{ out } for #{ args['server_name'] } in #{ IDENTITY }"
    end
  end
end
