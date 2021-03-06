
class Cheftacular
  class StatelessActionDocumentation
    def upload_roles
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft upload_roles` This command will resync the chef server's roles with the data in the chef-repo/roles.",

        [
          "    1. Aliased to `cft ur`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Updates all roles based on data in your roles dir'
    end
  end

  class StatelessAction
    def upload_roles
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']

      Dir.foreach(@config['locs']['roles']) do |rd|
        next if @config['filesystem'].is_junk_filename?(rd)

        puts("Loading in role from file #{ rd }") if @options['verbose']

        puts `knife role from file "#{ @config['locs']['roles'] }/#{ rd }"` 
      end
    end

    alias_method :ur, :upload_roles
  end
end
