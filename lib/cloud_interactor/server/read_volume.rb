class CloudInteractor
  class Server
    def read_volume args, output=true, strict_match=false
      specific_volume = args['volume_name']

      raise "Volume not passed! Value for volume name is: #{ specific_volume }" if specific_volume.nil?

      list_volumes args, false

      @main_obj['server_attached_volumes'][args['server_name']].each do |volume_hash|
        next if strict_match && volume_hash['display_name'] != (specific_volume)
        next if !strict_match && !volume_hash['display_name'].include?(specific_volume)

        @main_obj["specific_attached_volumes"] ||= []
        
        @main_obj["specific_attached_volumes"] << volume_hash

        ap(volume_hash) if output
      end

      puts("(#{ IDENTITY }) #{ specific_volume } not attached to #{ args['server_name'] }!") if @main_obj["specific_attached_volumes"].nil?
    end
  end
end
