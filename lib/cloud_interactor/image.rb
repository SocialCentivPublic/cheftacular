
class CloudInteractor
  class Image #http://docs.rackspace.com/servers/api/v2/cs-devguide/content/List_Images-d1e4435.html
    IDENTITY = 'images'
    RESOURCE = 'compute'

    def initialize main_obj, classes, options={} 
      @main_obj  = main_obj
      @options   = options
      @classes   = classes
    end
    
    def run method, args
      self.send(method, args)
    end

    def list args, output=true
      @classes['helper'].generic_list_call IDENTITY, RESOURCE, output
    end

    def read args, output=true
      list [], false

      @classes['helper'].generic_read_parse args, IDENTITY, output
    end
  end
end
