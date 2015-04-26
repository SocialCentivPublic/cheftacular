class Cheftacular
  class StatelessActionDocumentation
    def clean_sensu_plugins
      @config['documentation']['stateless_action'] <<  [
        "[NYI]`cft clean_sensu_plugins` will checkout / update the sensu community plugins github repo on your " +
        "local machine and sync any sensu plugin files in your wrapper cookbook directory with what is in the repo."
      ]
    end
  end

  class StatelessAction
    def clean_sensu_plugins
      raise "This method is not yet implemented"
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')
      
      #TODO use this to keep the cookbook files directory up to date with the sensu community plugins repo
    end
  end
end
