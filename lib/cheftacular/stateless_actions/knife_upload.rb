
class Cheftacular
  class StatelessActionDocumentation
    def knife_upload
      @config['documentation']['stateless_action'] <<  [
        "`cft knife_upload` will resync the chef-server with the local chef-repo code. " + 
        "This command is analog for `knife upload /`"
      ]
    end
  end

  class StatelessAction
    def knife_upload
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      puts("Starting upload...") unless @options['quiet']

      out = `knife upload / --chef-repo-path #{ @config['locs']['chef-repo'] }`

      puts out
    end
  end
end