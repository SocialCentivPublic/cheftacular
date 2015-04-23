class CloudInteractor
  class Server
    def destroy args
      read args, false

      #TODO strict checking on servers to ensure a server can't be destroyed while it still has volumes attached (which can corrupt the volume)

      @classes['helper'].generic_destroy_parse args, IDENTITY, RESOURCE
    end
  end
end
