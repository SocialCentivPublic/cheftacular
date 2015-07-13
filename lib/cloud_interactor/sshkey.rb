
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

    def create args
      puts "Creating #{ args['name'] } in #{ IDENTITY }..."

      puts("Creating #{ IDENTITY.singularize } with args #{ ap(args) }") if @options['verbose']

      @main_obj["#{ IDENTITY }_create_request"] = JSON.parse(@classes['auth'].auth_service(RESOURCE).instance_eval(IDENTITY).create(args).to_json)
    end

    def destroy args
      read args, false

      @classes['helper'].generic_destroy_parse args, IDENTITY, RESOURCE
    end

    #special method for digitalocean api, will attempt to create the sshkeyid on DO if one matching the user's hostname is not found
    def bootstrap output=true
      read Socket.gethostname, false

      if @main_obj["specific_#{ IDENTITY }"].empty?
        puts "Did not detect an SSHKey on DigitalOcean for the system #{ Socket.gethostname }, creating..."
        create_hash = {}
        create_hash['name']       = Socket.gethostname
        create_hash['ssh_pub_key'] = File.read(File.expand_path('~/.ssh/id_rsa.pub'))

        create create_hash

        sleep 5

        read Socket.gethostname, false
      end
    end
  end
end
