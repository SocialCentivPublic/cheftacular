class CloudInteractor
  class Volume
    def destroy args
      read args, false

      #TODO strict checking on volumes to ensure a volume can't be destroyed when it is still attached

      @classes['helper'].generic_destroy_parse args, IDENTITY, RESOURCE, 'display_name'
    end
  end
end
