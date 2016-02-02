
class Cheftacular
  class StatelessActionDocumentation
    def knife_upload
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft knife_upload [force]` will resync the chef-server with the local chef-repo code. " + 
        "This command is analog for `knife upload /`",

        [
          "    1. The force option will add the force option to knife upload.",

          "    2. Utilize `knife cookbook upload -a -V --cookbook-path ./cookbooks` if this command gives you trouble",

          "    3. Aliased to `cft ku`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Uploads your current cookbooks to the chef server'
    end
  end

  class StatelessAction
    def knife_upload
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      arg = ARGV[1]

      option = case arg
               when 'force' then ' --force'
               else ''
               end

      puts("Starting upload...") unless @options['quiet']

      out = `knife upload / --chef-repo-path #{ @config['locs']['chef-repo'] }#{ option }`

      puts out
    end

    alias_method :ku, :knife_upload
  end
end
