
class Cheftacular
  class StatelessActionDocumentation
    def update_the_cheftacular_cookbook_and_knife_upload
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft update_the_cheftacular_cookbook_and_knife_upload` update your local cheftacular cookbook with your local (out of chef-repo) cheftacular " + 
        "cookbook and knife_upload afterwards.",

        [
          "    1. This method is aliased to `cft utccaku` and `cft utcc`."
        ]
      ]

      @config['documentation']['stateless_action']['utccaku']['short_description'] = 'Runs `update_cookbook` and `knife_upload` for the cheftacular cookbook'
    end
  end

  class StatelessAction
    def update_the_cheftacular_cookbook_and_knife_upload
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      @config['stateless_action'].update_cookbook('TheCheftacularCookbook', 'local')

      @config['stateless_action'].knife_upload
    end

    alias_method :utccaku, :update_the_cheftacular_cookbook_and_knife_upload
    alias_method :utcc, :update_the_cheftacular_cookbook_and_knife_upload
  end
end
