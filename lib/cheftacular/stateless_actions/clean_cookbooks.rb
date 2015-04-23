
class Cheftacular
  class StatelessActionDocumentation
    def clean_cookbooks
      @config['documentation']['stateless_action'] <<  [
        "`cft clean_cookbooks [force] [remove_cookbooks]` allows you to update the internal chef-repo's cookbooks easily. " +
        "By default this script will force you to decide what to do with each cookbook individually (shows version numbers and whether to overwrite it to cookbooks or not).",

        [
          "    1. `force` argument will cause the downloaded cookbooks to *always* overwrite the chef-repo's cookbooks as long as the downloaded cookbook has a higher version number.",

          "    2. If you would like to remove all the cookbooks on the chef server, run `knife cookbook bulk delete '.*' -p -c ~/.chef/knife.rb`"
        ]
      ]
    end
  end

  class StatelessAction
    def clean_cookbooks local_options={'interactive' => true}
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      ARGV.each do |arg|
        case arg
        when "force" then local_options['interactive'] = false
        end
      end

      @config['cheftacular']['wrapper_cookbooks'].split(',').each do |wrapper_cookbook|
        wrapper_cookbook_loc = "#{ @config['locs']['cookbooks'] }/#{ wrapper_cookbook }"
        FileUtils.rm(File.expand_path("#{ wrapper_cookbook_loc }/Berksfile.lock")) if File.exists?(File.expand_path("#{ wrapper_cookbook_loc }/Berksfile.lock"))
        FileUtils.rm_rf(File.expand_path("#{ @config['locs']['berks'] }/cookbooks")) if File.exists?(File.expand_path("#{ @config['locs']['berks'] }/cookbooks"))
        
        Dir.chdir wrapper_cookbook_loc
        puts "Installing new cookbooks..."
        out = `berks install`
        puts "#{out}\nFinished... Beginning directory scanning and conflict resolution..."

        berkshelf_cookbooks = {}

        Dir.foreach(@config['locs']['berks']) do |berkshelf_cookbook|
          next if @config['helper'].is_junk_filename?(berkshelf_cookbook)
          skip = false

          berkshelf_cookbooks.keys.each do |processed_berkshelf_cookbook|
            if processed_berkshelf_cookbook.rpartition('-').first == berkshelf_cookbook.rpartition('-').first
              cookbook_mtime  = File.mtime(File.expand_path("#{ @config['locs']['berks'] }/#{ berkshelf_cookbook }"))
              pcookbook_mtime = File.mtime(File.expand_path("#{ @locs['locs']['berks'] }/#{ processed_berkshelf_cookbook }"))

              skip = true if cookbook_mtime < pcookbook_mtime #get only the latest version, berkshelf pulls in multiple commits from git repos for SOME REASON
            end
          end

          next if skip

          berkshelf_cookbooks[berkshelf_cookbook] = if File.exists?(File.expand_path("#{ @config['locs']['berks'] }/#{ berkshelf_cookbook }/metadata.rb"))
                                                      File.read(File.expand_path("#{ @config['locs']['berks'] }/#{ berkshelf_cookbook }/metadata.rb")).gsub('"',"'").gsub(/^version[\s]*('\d[.\d]+')/).peek[/('\d[.\d]+')/].gsub("'",'')
                                                    else
                                                      berkshelf_cookbook.split('-').last
                                                    end
        end

        chef_repo_cookbooks = {}

        Dir.foreach(@config['locs']['cookbooks']) do |chef_repo_cookbook|
          next if @config['helper'].is_junk_filename?(berkshelf_cookbook)
            
          new_name = chef_repo_cookbook.rpartition('-').first

          chef_repo_cookbooks[chef_repo_cookbook] = if File.exists?(File.expand_path("#{ @config['locs']['cookbooks'] }/#{ chef_repo_cookbook }/metadata.rb"))
                                                      File.read(File.expand_path("#{ @config['locs']['cookbooks'] }/#{ chef_repo_cookbook }/metadata.rb")).gsub('"',"'").gsub(/^version[\s]*('\d[.\d]+')/).peek[/('\d[.\d]+')/].gsub("'",'')
                                                    else
                                                      JSON.parse(File.read(File.expand_path("#{ @config['locs']['cookbooks'] }/#{ chef_repo_cookbook }/metadata.json"))).to_hash['version']
                                                    end
        end

        berkshelf_cookbooks.each_pair do |berkshelf_cookbook, version|
          new_name = berkshelf_cookbook.rpartition('-').first

          if chef_repo_cookbooks.has_key?(new_name) || chef_repo_cookbooks.has_key?(berkshelf_cookbook) #don't overwrite cookbooks without user input
            if local_options['interactive']
              puts "COOKBOOK::~~~~#{ new_name }~~~~::VERSION::~~~~~~~~#{ version } VS #{ chef_repo_cookbooks[new_name] }"
              puts "\nEnter O | o | overwrite to overwrite ~~~~#{ new_name }~~~~ in the chef-repo (THIS SHOULD NOT BE DONE LIGHTLY)"
              puts "Enter N | n | no        to skip to the next conflict"
              puts "If you pass force to this script, it will always overwrite."
              #puts "If you pass a STRING of comma delimited cookbooks, it will skip these cookbooks automatically and overwrite others"
              #puts "Example: ruby ./executables/clean-cookbooks 'application_ruby,wordpress'"
              puts "Input:"
              input = STDIN.gets.chomp

              next if (input =~ /N|n|no/) == 0
            end

            next if @config['helper'].is_higher_version?(chef_repo_cookbooks[new_name], version)
          end

          cmnd = "#{ @config['locs']['berks'] }/#{ berkshelf_cookbook } #{ @config['locs']['cookbooks'] }/#{ new_name }"
          puts "Moving #{ cmnd } (#{ version }:#{ chef_repo_cookbooks[new_name] })" if @options['verbose']
          `rm -Rf #{ @config['locs']['cookbooks'] }/#{ new_name }`
          `cp -Rf #{ cmnd }`
        end
      end
    end
  end
end