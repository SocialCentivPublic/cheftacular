
class CloudInteractor
  class Domain #http://docs.rackspace.com/cdns/api/v1.0/cdns-devguide/content/API_Operations_Wadl-d1e2648.html
    IDENTITY = 'domains'
    RESOURCE = 'DNS'

    def initialize main_obj, auth_hash, classes, options={} 
      @main_obj  = main_obj
      @auth_hash = auth_hash
      @options   = options
      @classes   = classes
    end
    
    def run method, args
      self.send(method, args)
    end
  end
end
