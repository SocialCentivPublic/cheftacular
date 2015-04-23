class CloudInteractor
  class Volume
    def read args, output=true, mode="display_name"
      list([], false) if @main_obj["specific_#{ IDENTITY }"].nil?

      @classes['helper'].generic_read_parse args, IDENTITY, output, mode
    end
  end
end
