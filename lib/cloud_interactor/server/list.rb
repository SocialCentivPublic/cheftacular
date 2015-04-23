class CloudInteractor
  class Server
    def list args={}, output=true
      @classes['helper'].generic_list_call IDENTITY, RESOURCE, output
    end
  end
end
