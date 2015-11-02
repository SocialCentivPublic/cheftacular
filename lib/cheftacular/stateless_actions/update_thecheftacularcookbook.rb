
class Cheftacular
  class StatelessActionDocumentation
    def update_thecheftacularcookbook
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft update_thecheftacularcookbook` allows you to update ONLY the internal chef-repo's TheCheftacularCookbook."
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Useful for ONLY updating TheCheftacularCookbook'
    end
  end

  class StatelessAction
    def update_thecheftacularcookbook local_options={'interactive' => true}
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      @config['cheftacular']['wrapper_cookbooks'].split(',').each do |wrapper_cookbook|
        wrapper_cookbook_loc = "#{ @config['locs']['cookbooks'] }/#{ wrapper_cookbook }"
        FileUtils.rm_rf(File.expand_path("#{ @config['locs']['berks'] }/cookbooks")) if File.exists?(File.expand_path("#{ @config['locs']['berks'] }/cookbooks"))
        
        Dir.chdir wrapper_cookbook_loc
        puts "Installing new cookbooks..."
        out = `berks install`
        puts "#{out}\nFinished fetching cookbooks, moving TheCheftacularCookbook into local chef repo"

        cheftacular_cookbook = @config['filesystem'].parse_latest_berkshelf_cookbook_versions.select {|key| key.include?('TheCheftacularCookbook')}.keys.first

        `rm -Rf #{ @config['locs']['cookbooks'] }/TheCheftacularCookbook` if File.exists?(File.expand_path("#{ @config['locs']['cookbooks'] }/TheCheftacularCookbook"))
        `cp -Rf #{ @config['locs']['berks'] }/#{ cheftacular_cookbook } #{ @config['locs']['cookbooks'] }/TheCheftacularCookbook`

        break
      end
    end
  end
end
