class Cheftacular
  class ActionDocumentation
    def verify
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description']  = [
        "`cft verify` Checks to see if the servers for the current state are running the latest commits. ",
        [
          "    1. This command is functionally the same as `cft check verify`."
        ]
      ]
      @config['documentation']['action'][__method__]['short_description'] = "Checks the commits currently deployed to an env for your repo"
    end
  end

  class Action
    def verify
      @config['action'].check('verify')
    end
  end
end
