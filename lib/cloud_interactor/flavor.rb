
class CloudInteractor
  class Flavor #http://docs.rackspace.com/servers/api/v2/cs-devguide/content/List_Flavors-d1e4188.html
    IDENTITY = 'flavors'
    RESOURCE = 'compute'

    def initialize main_obj, classes, options={} 
      @main_obj  = main_obj
      @options   = options
      @classes   = classes
    end
    
    def run method, args
      self.send(method, args)
    end

    def list args={}, output=true
      @classes['helper'].generic_list_call IDENTITY, RESOURCE, output
    end

    def read args, output=true, mode='name'
      list [], false

      if @options['preferred_cloud'] =~ /digitalocean/
        mode         = 'slug'
        args['slug'] = args['name'] if args.class == Hash
      end

      @classes['helper'].generic_read_parse args, IDENTITY, output, mode
    end
  end
end
