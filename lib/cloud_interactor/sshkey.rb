
class CloudInteractor
  class SSHKey
    IDENTITY = 'ssh_keys'
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

    def read args, output=true
      list [], false

      @classes['helper'].generic_read_parse args, IDENTITY, output
    end

    #special method for digitalocean api, will attempt to create the sshkeyid on DO if one matching the user's hostname is not found
    def bootstrap_and_set output=true

    end
  end
end
