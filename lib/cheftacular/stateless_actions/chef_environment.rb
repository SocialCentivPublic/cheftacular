class Cheftacular
  class StatelessActionDocumentation
    def chef_environment
      @config['documentation']['stateless_action'] <<  [
        "[NYI]`cft chef_environment ENVIRONMENT_NAME [create|destroy]` will allow you to interact with chef environments on the chef server.",
      
        [
          "    1.  `create` will create an environment if it does not exist.",

          "    2.  `destroy` will destroy a chef environment *IF IT HAS NO NODES*"
        ]
      ]
    end
  end

  class StatelessAction
    def chef_environment
      #TODO
    end
  end
end
