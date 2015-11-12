
class Cheftacular
  class StatelessActionDocumentation
    def update_cheftacular
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft #{ __method__ }` this command attempts to update cheftacular to the latest version."
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Update cheftacular to the latest version'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def update_cheftacular status_hash={}
      update_cheftacular_not_configured_to_update if @config['cheftacular']['self_update_repository'] != @config['locs']['root']

      @config['helper'].set_detected_cheftacular_version

      puts "Attempting to update cheftacular from #{ Cheftacular::VERSION } to #{ @config['detected_cheftacular_version'] }..."

      status_hash['gemfile_is_latest_version'] = update_cheftacular_from_git
      status_hash['gemfile_is_latest_version'] = update_cheftacular_gemfile unless status_hash['gemfile_is_latest_version']
      status_hash['bundled_latest_version']    = update_cheftacular_bundle if status_hash['gemfile_is_latest_version']

      if !status_hash['gemfile_is_latest_version'] || !status_hash['bundled_latest_version']
        puts(
          "Issues occured in automatically updating your cheftacular " +
          "to #{ @config['detected_cheftacular_version'] }, please send " +
          "the output of this command to your DevOps administrator or add " +
          "it as an issue at this gem's github page."
        )
      else
        puts "Successfully installed version #{ @config['detected_cheftacular_version'] }, please re-run your command."
      end
    end

    private
    def update_cheftacular_from_git out=[]
      out << `git reset --hard origin/master && git pull origin master`

      parsed_gemfile_version = @config['filesystem'].parse_gemfile_gem_version('cheftacular')

      puts "After git update, Gemfile lists version #{ parsed_gemfile_version } versus latest version: #{ @config['detected_cheftacular_version'] }"

      return parsed_gemfile_version == @config['detected_cheftacular_version']
    end

    def update_cheftacular_gemfile
      puts "Forcing gemfile update to the latest version of cheftacular..."

      gemfile_path           = File.expand_path("#{ @config['locs']['root'] }/Gemfile")
      parsed_gemfile_version = @config['filesystem'].parse_gemfile_gem_version('cheftacular')
      new_file_content       = File.read(gemfile_path).gsub(parsed_gemfile_version, @config['detected_cheftacular_version'])

      File.open( gemfile_path, "w") { |f| f.write(new_file_content) }

      new_parsed_gemfile_version = @config['filesystem'].parse_gemfile_gem_version('cheftacular')

      puts "After forced gemfile update, Gemfile lists version #{ new_parsed_gemfile_version } versus latest version: #{ @config['detected_cheftacular_version'] }"

      return new_parsed_gemfile_version == @config['detected_cheftacular_version']
    end

    def update_cheftacular_bundle out=[]
      puts "Running bundle install..."

      out << `bundle install`

      cheftacular_bundle_version = out.first[/cheftacular.*([\d\.]+)/][/([\d\.]+)/]

      puts "After bundle install, version is #{ cheftacular_bundle_version } versus latest version: #{ @config['detected_cheftacular_version'] }"

      return cheftacular_bundle_version == @config['detected_cheftacular_version']
    end

    def update_cheftacular_not_configured_to_update
      puts "Please update the gemfile to #{ @config['detected_cheftacular_version'] }, bundle install and then restart this process.\n"

      exit
    end
  end
end
