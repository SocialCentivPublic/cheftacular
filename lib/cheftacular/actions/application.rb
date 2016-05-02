
class Cheftacular
  class ActionDocumentation
    def application
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft application boot|boot_without_deploy|destroy|destroy_raw_servers [SERVER_NAMES]` will boot / destroy the servers for current repository you are connected to",

        [
          "    1. `boot` will spin up servers and bring them to a stable state. " +
          "This includes setting up their subdomains for the target environment.",

          "    2. `destroy` will destroy all servers needed for the target environment",

          "    3. `destroy_raw_servers` will destroy the servers without destroying the node data.",

          "    4. `boot_without_deploy` will spin up servers and bring them to a state where they are ready to be deployed",

          "    5. This command will prompt when attempting to destroy servers in staging or production. " + 
          "Additionally, only devops clients will be able to destroy servers in those environments.",

          "    6. This command also accepts a *comma delimited list* of server names to boot / destroy instead of all the stored ones for an environment.",

          "    7. This command works with all the flags that `cft deploy` works with, like -Z -z -O and so on.",

          "    8. Aliased to `cft a` and `cft app`"
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Boots (or destroys) an application based on data stored in cheftacular.yml'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class Action
    def application type='boot'
      type = ARGV[1] if ARGV[1]

      unless (type =~ /boot|destroy|destroy_raw_servers|boot_without_deploy/) == 0
        raise "Unknown type: #{ type }, can only be 'boot'/'boot_without_deploy'/'destroy'/'destroy_raw_servers'"
      end

      @config['stateless_action'].environment(type, true)
    end

    alias_method :a, :application
    alias_method :app, :application
  end
end
