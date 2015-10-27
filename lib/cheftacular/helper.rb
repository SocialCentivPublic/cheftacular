
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

      `gem list #{ declassify } --remote`[/(\d+\.\d+\.\d+)/]
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

    def knife_bootstrap_command
      address  = @options['address']
      user     = @config['cheftacular']['deploy_user']
      password = @config['server_passwords'][@options['address']]
      nodename = @options['node_name']
      chef_ver = @config['cheftacular']['chef_version'].to_i >= 12 ? '12.4.0' : '11.16.4'

      "knife bootstrap #{ address } -x #{ user } -P #{ password } -N #{ nodename } --sudo --use-sudo-password --bootstrap-version #{ chef_ver }"
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

    def install_rvm_sh_file out=[]
      puts("Starting rvm.sh installation...") unless @options['quiet']

      commands = [
        "#{ @config['helper'].sudo(@options['address']) } mv /home/deploy/rvm.sh /etc/profile.d",
        "#{ @config['helper'].sudo(@options['address']) } chmod 755 /etc/profile.d/rvm.sh",
        "#{ @config['helper'].sudo(@options['address']) } chown root:root /etc/profile.d/rvm.sh"
      ]

      out << `scp -oStrictHostKeyChecking=no #{ @config['locs']['cheftacular-lib-files'] }/rvm.sh #{ @config['cheftacular']['deploy_user'] }@#{ @options['address'] }:/home/#{ @config['cheftacular']['deploy_user'] }`

      commands.each do |command|
        out << `ssh -t -oStrictHostKeyChecking=no #{ @config['cheftacular']['deploy_user'] }@#{ @options['address'] } "#{ command }"`
      end

      puts("Completed rvm.sh installation into /etc/profile.d/rvm.sh") unless @options['quiet']
    end

    def send_log_bag_hash_slack_notification logs_bag_hash, method, on_failing_exit_status_message=''
      if @config['cheftacular']['slack']['webhook']
        logs_bag_hash.each_pair do |key, hash|
          next unless key.include?(method.to_s)

          if hash['exit_status'] && hash['exit_status'] == 1
            @config['stateless_action'].slack(hash['text'].prepend('```').insert(-1, '```'))

            @config['error'].exception_output(on_failing_exit_status_message) if !on_failing_exit_status_message.blank?
          end
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
