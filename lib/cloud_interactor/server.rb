
class CloudInteractor
  class Server #http://docs.rackspace.com/servers/api/v2/cs-devguide/content/Servers-d1e2073.html
    IDENTITY = 'servers'
    RESOURCE = 'compute'

    def initialize main_obj, classes, options={} 
      @main_obj  = main_obj
      @options   = options
      @classes   = classes
    end
    
    def run method, args
      args['name'] = args['name'].gsub('_', '-')

      self.send(method, args)
    end
  end
end
