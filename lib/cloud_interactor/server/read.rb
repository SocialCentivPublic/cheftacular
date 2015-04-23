class CloudInteractor
  class Server
    def read args, output=true, mode="name", search_key="name"
      list [], false

      @classes['helper'].generic_read_parse args, IDENTITY, output, mode, search_key
    end
  end
end
