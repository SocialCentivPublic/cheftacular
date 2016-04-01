
class Cheftacular
  class StatelessActionDocumentation
    def update_cookbook
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft update_cookbook [COOKBOOK_NAME] [INSTALL_VERSION|local]` allows you to specifically update a single cookbook",

        [
          "    1. This command passed with no arguments will update TheCheftacularCookbook",

          "    2. If the 2nd argument is local, the command will drop a local version of the cookbook onto your chef-repo",

          "    3. Aliased to `cft uc`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Useful for updating specific cookbooks'
    end
  end

  class InitializationAction
    def update_cookbook

    end
  end

  class StatelessAction
    def update_cookbook cookbook='TheCheftacularCookbook', version='latest'
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      cookbook = ARGV[1] if ARGV[1]
      version  = ARGV[2] if ARGV[2]

      if version == 'local' 
        if File.exists?(File.expand_path("#{ @config['locs']['true-root'] }/#{ cookbook }"))
          `rm -Rf #{ @config['locs']['cookbooks'] }/#{ cookbook }` if File.exists?(File.expand_path("#{ @config['locs']['cookbooks'] }/#{ cookbook }"))
          `cp -Rf #{ @config['locs']['true-root'] }/#{ cookbook } #{ @config['locs']['cookbooks'] }/#{ cookbook }`

          `rm -Rf #{ @config['locs']['cookbooks'] }/#{ cookbook }/.git`
        else
          puts "You do not have #{ cookbook } under the #{ @config['locs']['true-root'] } directory!"
        end
      else
        @config['cheftacular']['wrapper_cookbooks'].split(',').each do |wrapper_cookbook|
          wrapper_cookbook_loc = "#{ @config['locs']['cookbooks'] }/#{ wrapper_cookbook }"
          FileUtils.rm_rf(File.expand_path("#{ @config['locs']['berks'] }/cookbooks")) if File.exists?(File.expand_path("#{ @config['locs']['berks'] }/cookbooks"))
          
          Dir.chdir wrapper_cookbook_loc
          puts "Installing new cookbooks..."
          out = `berks install`
          puts "#{out}\nFinished fetching cookbooks, moving #{ cookbook } into local chef repo"

          specific_cookbook = @config['filesystem'].parse_berkshelf_cookbook_versions(version).select {|key| key.include?(cookbook)}[cookbook]

          puts "Moving #{ cookbook } (#{ specific_cookbook['version'] })[#{ specific_cookbook['mtime'] }] to your chef-repo!"

          `rm -Rf #{ @config['locs']['cookbooks'] }/#{ cookbook }` if File.exists?(File.expand_path("#{ @config['locs']['cookbooks'] }/#{ cookbook }"))
          `cp -Rf #{ @config['locs']['berks'] }/#{ specific_cookbook['location'] } #{ @config['locs']['cookbooks'] }/#{ cookbook }`
          
          break
        end
      end
    end

    alias_method :uc, :update_cookbook
  end
end
