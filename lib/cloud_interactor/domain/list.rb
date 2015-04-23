class CloudInteractor
  class Domain
    def list args={}, output=true
      @classes['helper'].generic_list_call 'zones', RESOURCE, output

      @main_obj[IDENTITY] = @main_obj['zones']
    end
  end
end
