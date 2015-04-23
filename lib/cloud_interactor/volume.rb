
class CloudInteractor
  class Volume #http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/volumes.html
    IDENTITY = 'volumes'
    RESOURCE = 'volume'
    
    def initialize main_obj, classes, options={} 
      @main_obj  = main_obj
      @options   = options
      @classes   = classes
    end
    
    def run method, args, mode="name"
      case method
      when "read" then self.send(method, args, mode)
      else             self.send(method, args)
      end
    end
  end
end
