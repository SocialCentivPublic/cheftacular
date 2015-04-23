class CloudInteractor
  class Volume
    def list args={}, output=true
      @classes['helper'].generic_list_call IDENTITY, RESOURCE, output
    end
  end
end
