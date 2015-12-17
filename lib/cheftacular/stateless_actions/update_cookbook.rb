
class Cheftacular
  class StatelessActionDocumentation
    def update_cookbook
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft update_cookbook [COOKBOOK_NAME]` allows you to specifically update a single cookbook",

        [
          "    1. This command passed with no arguments will update TheCheftacularCookbook"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Useful for updating specific cookbooks'
    end
  end

  class StatelessAction
    def update_cookbook cookbook='TheCheftacularCookbook', local_options={'interactive' => true}
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      cookbook = ARGV[1] if ARGV[1]

      @config['cheftacular']['wrapper_cookbooks'].split(',').each do |wrapper_cookbook|
        wrapper_cookbook_loc = "#{ @config['locs']['cookbooks'] }/#{ wrapper_cookbook }"
        FileUtils.rm_rf(File.expand_path("#{ @config['locs']['berks'] }/cookbooks")) if File.exists?(File.expand_path("#{ @config['locs']['berks'] }/cookbooks"))
        
        Dir.chdir wrapper_cookbook_loc
        puts "Installing new cookbooks..."
        out = `berks install`
        puts "#{out}\nFinished fetching cookbooks, moving #{ cookbook } into local chef repo"

        specific_cookbook = @config['filesystem'].parse_latest_berkshelf_cookbook_versions.select {|key| key.include?(cookbook)}[cookbook]

        puts "Moving #{ cookbook } (#{ specific_cookbook['version'] })[#{ specific_cookbook['mtime'] }] to your chef-repo!"

        `rm -Rf #{ @config['locs']['cookbooks'] }/#{ cookbook }` if File.exists?(File.expand_path("#{ @config['locs']['cookbooks'] }/#{ cookbook }"))
        `cp -Rf #{ @config['locs']['berks'] }/#{ specific_cookbook['location'] } #{ @config['locs']['cookbooks'] }/#{ cookbook }`
        
        break
      end
    end
  end
end
