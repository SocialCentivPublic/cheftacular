
class Cheftacular
  class Helper
    def initialize options, config
      @options, @config  = options, config
    end

    def declassify
      #(self.class::TRUENAME.constantize).to_s.underscore.dasherize
      Cheftacular.to_s.underscore.dasherize
    end

    def is_command? command=''
      command ||= ''

      @config['action'].public_methods(false).include?(command.to_sym)
    end

    def is_stateless_command? command=''
      command ||= ''
      
      @config['stateless_action'].public_methods(false).include?(command.to_sym)
    end

    def is_not_command_or_stateless_command? command=''
      command ||= ''

      !@config['action'].public_methods(false).include?(command.to_sym) && !@config['stateless_action'].public_methods(false).include?(command.to_sym)
    end

    def is_initialization_command? command=''
      command ||= ''

      @config['initialization_action'].public_methods(false).include?(command.to_sym) || command.blank?
    end

    def running_on_chef_node? ret = false
      Dir.entries('/etc').include?('chef') && File.exist?('/etc/chef/client.rb') && !File.size?('/etc/chef/client.rb').nil?
    rescue StandardError => e
      @config['error'].exception_output "An error occurred while trying to see if this system is a chef node. Assuming the system is not a chef node.", e, false
    end

    def running_in_mode? mode
      @config['cheftacular']['mode'] == mode
    end

    #TODO, fix for clients that block amazon hosted rubygems?
    def fetch_remote_version
      puts "Checking remote #{ declassify } version..."

      `gem list #{ declassify } --remote`[/([\d\.]+)/]
    end

    def completion_rate? percent, mode
      case mode.to_s
      when 'initializer'           then print("Fetching initialization chef data for #{ @options['env'] }....0%") if !@options['quiet'] && percent == 0
      when 'get_true_node_objects' then print("Retrieving node data from chef server for #{ @config['chef_nodes'].count } nodes....0%") if !@options['quiet'] && percent == 0
      end

      case percent
      when 1..9   then print("\b\b#{ percent.to_i }%")       unless @options['quiet']
      when 10..99 then print("\b\b\b#{ percent.to_i }%")     unless @options['quiet']
      when 100    then print("\b\b\b\b#{ percent.to_i }%\n") unless @options['quiet']
      end
    end

    def display_readme option="", out=""
      puts File.read(File.expand_path('../README.md', __FILE__))
    end

    def gen_pass length=20, mode="truepass"
      lowercase = 'a'..'z'
      uppercase = 'A'..'Z'
      numbers   = 0..9

      length = @config['cheftacular']['server_pass_length'] if length.to_i <= @config['cheftacular']['server_pass_length']

      sets = case mode
             when "truepass"  then [lowercase, uppercase, numbers]
             when "numsonly"  then [numbers]
             when "lowernum"  then [lowercase, numbers]
             when "uppernum"  then [uppercase, numbers]
             when "lowercase" then [lowercase]
             when "uppercase" then [uppercase]
             end

      o = sets.flatten.map { |i| i.to_a }.flatten

      (0...length.to_i).map { o[rand(o.length)] }.join
    end

    def set_location_if_app ret=""
      if get_codebase_from_role_name(Dir.getwd.split('/').last, "has_key?")
        ret = Dir.getwd.split('/').last
      end

      ret
    end

    def sudo ip_address
      "echo #{ @config['server_passwords'][ip_address] } | sudo -S"
    end

    def output_run_stats
      puts("\nDone in #{ Time.now - @config['start_time'] } seconds at #{ Time.now.strftime('%Y-%m-%d %l:%M:%S %P') }.") unless @options['quiet']
    end

    def set_local_instance_vars
      [ 
        @options, 
        @config['locs'],
        @config['ridley'],
        @config[@options['env']]['logs_bag_hash'],
        @config[@options['env']]['chef_passwords_bag_hash'],
        @config['bundle_command'],
        @config['cheftacular'],
        @config['server_passwords']
      ]
    end

    def is_higher_version? vstr1, vstr2
      Gem::Version.new(vstr1) > Gem::Version.new(vstr2)
    end

    def set_log_loc_and_timestamp
      @config['dummy_sshkit'].set_log_loc_and_timestamp @config['locs']
    end

    #the documentation hashes must be populated *before* this method runs for it to return anything!
    def compile_documentation_lines mode, out=[]
      doc_arr = case mode
                when 'action'           then @config['documentation']['action']
                when 'application'      then @config['documentation']['application'].merge(@config['documentation']['action'])
                when 'stateless_action' then @config['documentation']['stateless_action']
                when 'devops'           then @config['documentation']['stateless_action'].merge(@config['documentation']['action'])
                end

      doc_arr = doc_arr.to_a.map { |doc| doc[1]['long_description'] }
      count   = 1

      doc_arr.sort {|a, b| a[0] <=> b[0]}.flatten(1).each do |line|
        out << "#{ count }. #{ line }" if line.class.to_s == 'String'

        out << line if line.class.to_s == 'Array'

        count += 1 if line.class.to_s == 'String'
      end

      out
    end

    def compile_short_context_descriptions documentation_hash, padding_length=25, out=[]
      out << documentation_hash.to_a.map { |doc| "#{ doc[0].to_s.ljust(padding_length, '_') }_#{ doc[1]['short_description'] }" }

      out.flatten.sort {|a, b| a[0] <=> b[0]}.join("\n\n")
    end

    #compares how close str1 is to str2
    def compare_strings str1, str2
      str1_chars = str1.split('').uniq
      str2_chars = str2.split('').uniq

      ((str1_chars + str2_chars).uniq.length * 1.0) / (str1_chars.length + str2_chars.length)
    end

    def set_cloud_options
      @options['preferred_cloud']        = @options['preferred_cloud'].nil? ?        @config['cheftacular']['preferred_cloud'].downcase        : @options['preferred_cloud'].downcase
      @options['preferred_cloud_image']  = @options['preferred_cloud_image'].nil? ?  @config['cheftacular']['preferred_cloud_image']           : @options['preferred_cloud_image']
      @options['preferred_cloud_region'] = @options['preferred_cloud_region'].nil? ? @config['cheftacular']['preferred_cloud_region']          : @options['preferred_cloud_region']
      @options['virtualization_mode']    = @options['virtualization_mode'].nil? ?    @config['cheftacular']['virtualization_mode']             : @options['virtualization_mode']
      @options['route_dns_changes_via']  = @options['route_dns_changes_via'].nil? ?  @config['cheftacular']['route_dns_changes_via'].downcase  : @options['route_dns_changes_via'].downcase
    end

    def does_cheftacular_config_have? key_array
      cheftacular = @config['cheftacular']
      key_array   = [key_array] if key_array.is_a?(String)
      key_checks  = []

      key_array.each do |key|
        key_checks << recursive_hash_check(key.split(':'), @config['cheftacular']).to_s
      end

      !key_checks.include?('false')
    end

    def recursive_hash_check keys, hash
      if hash.has_key?(keys[0]) 
        case hash[keys[0]].class.to_s
        when 'Hash'
          if !hash[keys[0]].empty?
            recursive_hash_check keys[1..keys.count-1], hash[keys[0]] 
          else
            return true
          end
        when 'String'
          return !hash[keys[0]].blank?
        when 'Array'
          return !hash[keys[0]].empty?
        end
      else
        return false
      end
    end

    #this must be in helpers because parser class is not yet loaded at the time this method is needed.
    def parse_node_name_from_client_file ret=""
      config = File.read(File.expand_path("#{ @config['locs']['chef'] }/client.rb"))

      config.split("\n").each do |line|
        next unless line.include?('node_name')

        return line.split('node_name').last.strip.chomp.gsub('"', '')
      end
    end

    #this must be in helpers because getter class is not yet loaded at the time this method is needed.
    def get_cheftacular_yml_as_hash
      config_location = if File.exist?(File.join( Dir.getwd, 'config', 'cheftacular.yml' ))
                          File.join( Dir.getwd, 'config', 'cheftacular.yml' )
                        elsif File.exist?('/root/cheftacular.yml')
                          '/root/cheftacular.yml'
                        else
                          raise "cheftacular.yml configuration file could not be found in either #{ File.join( Dir.getwd, 'config', 'cheftacular.yml' ) } or /root/cheftacular.yml"
                        end

      YAML::load(ERB.new(IO.read(File.open(config_location))).result)
    rescue StandardError => e
      puts "The cheftacular.yml configuration file could not be parsed."
      puts "Error message: #{ e }\n#{ e.backtrace.join("\n") }"
      
      exit
    end

    def compile_chef_repo_cheftacular_yml_as_hash
      master_hash = get_cheftacular_yml_as_hash
      master_hash['replace_keys_in_chef_repo'].each_pair do |key, val|
        master_hash[key] = val
      end

      master_hash
    end

    def send_log_bag_hash_slack_notification logs_bag_hash, method, on_failing_exit_status_message=''
      if @config['cheftacular']['slack']['webhook']
        logs_bag_hash.each_pair do |key, hash|
          next unless key.include?(method.to_s)

          if hash['exit_status'] && hash['exit_status'] == 1
            @config['slack_queue'] << { message: hash['text'].prepend('```').insert(-1, '```') }

            if !on_failing_exit_status_message.blank?
              @config['queue_master'].work_off_slack_queue

              @config['error'].exception_output(on_failing_exit_status_message)
            end
          end
        end
      end
    end

    def slack_current_deploy_arguments
      msg  = "#{ Socket.gethostname } just set for the repository #{ @config['getter'].get_repository_from_role_name(@options['role']) }:\n"
      msg << "the organization to #{ @options['deploy_organization'] }\n" if @options['deploy_organization']
      msg << "the revision to #{ @options['target_revision'] }\n"         if @options['target_revision']
      msg << "In the environment: #{ @options['env'] }"
      
      @config['slack_queue'] << { message: msg.prepend('```').insert(-1, '```'), channel: @config['cheftacular']['slack']['notify_on_deployment_args'] }
    end

    def display_currently_installed_version
      puts "The current version of cheftacular is #{ Cheftacular::VERSION }"
    end

    def set_detected_cheftacular_version
      @config['detected_cheftacular_version'] ||= if File.exists?( @config['filesystem'].current_version_file_path )
                                                    File.read( @config['filesystem'].current_version_file_path )
                                                  else 
                                                    @config['helper'].fetch_remote_version
                                                  end
    end

    def return_options_as_hash options_array, return_hash={}
      options_array.each do |key|
        return_hash[key] = @options[key]
      end

      return_hash
    end

    def check_if_possible_repo_state repo_state_hash, git_output=''
      revision_to_check = repo_state_hash.has_key?('revision')            ? repo_state_hash['revision']            : nil
      org_name_to_check = repo_state_hash.has_key?('deploy_organization') ? repo_state_hash['deploy_organization'] : @config['cheftacular']['TheCheftacularCookbook']['organization_name']
     
      revision_to_check = nil if revision_to_check == '<use_default>'
      org_name_to_check = @config['cheftacular']['TheCheftacularCookbook']['organization_name'] if org_name_to_check.nil?

      @config['cheftacular']['TheCheftacularCookbook']['chef_environment_to_app_repo_branch_mappings'].each_pair do |chef_env, app_env|
        revision_to_check = app_env if @options['env'] == chef_env && revision_to_check.nil?
      end

      git_output = `git ls-remote --heads git@github.com:#{ org_name_to_check }/#{ @options['repository'] }.git`

      if git_output.blank?
        puts "! The remote organization #{ org_name_to_check } does not have the repository: #{ @options['repository'] }! Please verify your repositories and try again"

        exit
      elsif !git_output.include?(revision_to_check)
        puts "! The remote organization #{ org_name_to_check } does not have a revision / branch #{ revision_to_check } for repository: #{ @options['repository'] } !"

        sorted_heads = git_output.scan(/refs\/heads\/(.*)/).flatten.uniq.sort_by { |head| compare_strings(revision_to_check, head)}

        puts "The closest matches for #{ revision_to_check } are:"
        puts "    #{ sorted_heads.at(0) }"
        puts "    #{ sorted_heads.at(1) }"
        puts "    #{ sorted_heads.at(2) }"
        puts "    #{ sorted_heads.at(3) }\n"

        puts "Please verify the correct revision / branch and run this command again."
        
        exit
      end
    end

    def display_cheftacular_config_diff
      diff_hash = @config['initial_cheftacular_yml'].deep_diff(@config['default']['cheftacular_bag_hash'], true).except('mode', 'default_repository').compact

      recursive_hash_scrub(diff_hash)

      recursive_hash_scrub(diff_hash) unless diff_hash.empty? #scrub out any leftover empty hashes

      if diff_hash.empty?
        puts "No difference detected between your cheftacular.yml and the global environment."
      else
        puts "Difference detected between local cheftacular.yml and data bag cheftacular.yml! Displaying...\n\n"

        ap diff_hash
          
        if @config['helper'].running_in_mode?('application') && @config['default']['cheftacular_bag_hash']['slack']['webhook'] && !diff_hash.empty?
          @config['slack_queue'] << { message: diff_hash.awesome_inspect({plain: true, indent: 2}).prepend('```').insert(-1, '```'), channel: @config['cheftacular']['slack']['notify_on_yaml_sync'] }
        end

        puts("If these are your intended changes you want to sync into the environment, you should run `cft cheftacular_config sync`\n\n") if ARGV[0] != 'cheftacular_config' && ARGV[1] != 'sync'
      end
    end

    def recursive_hash_scrub hash
      hash.each_pair do |key, value|
        if value.nil?
          hash.delete(key)
        elsif value.class == Hash && value.empty?
          hash.delete(key)
        elsif value.class == Hash && value[value.keys.first].empty?
          hash.delete(key)
        elsif value.class == Hash
          recursive_hash_scrub(hash[key])
        end
      end
    end
  end
end

class Hash
  def deep_diff(compare_hash, remove_if_nil_on_original=false)
    original_hash = self

    (original_hash.keys | compare_hash.keys).inject({}) do |diff_hash, key|
      if original_hash[key] != compare_hash[key]
        if original_hash[key].respond_to?(:deep_diff) && compare_hash[key].respond_to?(:deep_diff)
          diff_hash[key] = original_hash[key].deep_diff(compare_hash[key], remove_if_nil_on_original)
        else
          if remove_if_nil_on_original
            diff_hash[key]  = []
            diff_hash[key] << original_hash[key] if original_hash.has_key?(key)
            diff_hash[key] << compare_hash[key]  if original_hash.has_key?(key)
            diff_hash.delete(key)                if diff_hash[key].empty?
          else
            diff_hash[key] = [original_hash[key], compare_hash[key]]
          end
        end
      end

      diff_hash
    end
  end

  def compact
    self.select { |_, value| !value.nil? }
  end
end

class String
  def scrub_pretty_text
    self.gsub("",'').gsub(/\[0m|\[1m|\[32m|\[35m|\[36m/,'')
  end
end

class Fixnum
  def digits(base = 10)
    quotient, remainder = divmod(base)
    (quotient > 0 ? quotient.digits : []) + [remainder]
  end
end
