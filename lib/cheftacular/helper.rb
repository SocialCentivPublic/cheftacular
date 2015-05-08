
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

    def running_on_chef_node?
      Dir.entries('/etc').include?('chef')
    rescue StandardError => e
      exception_output "An error occurred while trying to see if this system is a chef node. Assuming the system is not a chef node.", e, false
    end

    def running_in_mode? mode
      @config['cheftacular']['mode'] == mode
    end

    def fetch_remote_version
      puts "Checking remote #{ declassify } version..."

      `gem list #{ declassify } --remote`[/(\d+\.\d+\.\d+)/]
    end

    def is_junk_filename? filename
      filename =~ /.DS_Store|.com.apple.timemachine.supported|README.*/ || filename == '.' || filename == '..' && File.directory?(filename)
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

    def write_version_file version
      File.open( current_version_file_path, "w") { |f| f.write(version) }
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

    def exception_output message, exception='', exit_on_call=true, suppress_error_output=false
      puts "#{ message }\n"

      puts("Error message: #{ exception }\n#{ exception.backtrace.join("\n") }") unless suppress_error_output

      exit if exit_on_call
    end

    def write_nodes_file_cache nodes
      nodes.each do |node|
        File.open( File.join( current_nodes_file_cache_path, "#{ node.name }.json"), "w") { |f| f.write(node.to_json) }
      end
    end

    def check_nodes_file_cache nodes=[]
      Dir.entries(current_nodes_file_cache_path).each do |location|
        next if is_junk_filename?(location)

        nodes << @config['ridley'].node.from_file("#{ current_nodes_file_cache_path }/#{ location }" )
      end

      nodes
    end

    def current_version_file_path
      current_file_path 'version-check.txt'
    end

    def current_audit_file_path
      current_file_path 'audit-check.txt'
    end

    def compare_file_node_cache_against_chef_nodes mode='include?'
      chef_server_names, nodes_file_cache_names = [],[]
      included = true 

      @config['chef_nodes'].each { |node| chef_server_names << node.name }

      check_nodes_file_cache.each { |node| nodes_file_cache_names << node.name }

      nodes_file_cache_names.each do |node_name|
        unless chef_server_names.include?(node_name)
          included = false

          break
        end
      end

      case mode
      when 'include?'  then return included
      when 'not_equal' then return check_nodes_file_cache.count != names.count
      when 'equal'     then return chef_server_names.sort == nodes_file_cache_names.sort
      end
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
      chef_ver = @config['cheftacular']['chef_client_version']

      "knife bootstrap #{ address } -x #{ user } -P #{ password } -N #{ nodename } --sudo --use-sudo-password --bootstrap-version #{ chef_ver }"
    end

    #the documentation hashes must be populated *before* this method runs for it to return anything!
    def compile_documentation_lines mode, out=[]
      doc_arr = case mode
                when 'action'           then @config['documentation']['action']
                when 'application'      then @config['documentation']['action'] + @config['documentation']['application']
                when 'stateless_action' then @config['documentation']['stateless_action']
                when 'devops'           then @config['documentation']['action'] + @config['documentation']['stateless_action']
                end

      count = 1

      doc_arr.sort {|a, b| a[0] <=> b[0]}.flatten(1).each do |line|

        out << "#{ count }. #{ line }" if line.class.to_s == 'String'

        out << line if line.class.to_s == 'Array'

        count += 1 if line.class.to_s == 'String'

        #puts("#{ out[out.index("#{ count }. #{ line }")] }::#{ line.class }::#{ count }\n") unless line.class.to_s == 'Array'
      end

      out
    end

    #compares how close str1 is to str2
    def compare_strings str1, str2
      str1_chars = str1.split('').uniq
      str2_chars = str2.split('').uniq

      ((str1_chars + str2_chars).uniq.length * 1.0) / (str1_chars.length + str2_chars.length)
    end

    def set_cloud_options
      @options['preferred_cloud']        = @options['preferred_cloud'].nil? ?        @config['cheftacular']['preferred_cloud'] :        @options['preferred_cloud']
      @options['preferred_cloud_image']  = @options['preferred_cloud_image'].nil? ?  @config['cheftacular']['preferred_cloud_image'] :  @options['preferred_cloud_image']
      @options['preferred_cloud_region'] = @options['preferred_cloud_region'].nil? ? @config['cheftacular']['preferred_cloud_region'] : @options['preferred_cloud_region']
      @options['virtualization_mode']    = @options['virtualization_mode'].nil? ?    @config['cheftacular']['virtualization_mode'] :    @options['virtualization_mode']
    end

    def current_nodes_file_cache_path
      current_file_path 'node_cache'
    end

    def cleanup_file_caches mode='old', check_current_day_entry=false
      base_dir = File.join( @config['locs']['app-root'], 'tmp', declassify )

      Dir.entries(base_dir).each do |entry|
        next if is_junk_filename?(entry)

        case mode
        when 'old'
          FileUtils.rm("#{ base_dir }/#{ entry }") if File.file?("#{ base_dir }/#{ entry }") && !entry.include?(Time.now.strftime("%Y%m%d"))
        when 'current'
          check_current_day_entry = true
        when 'current-audit-only'
          FileUtils.rm("#{ base_dir }/#{ entry }") if File.file?("#{ base_dir }/#{ entry }") && entry.include?(Time.now.strftime("%Y%m%d"))
        end


        if File.exists?("#{ base_dir }/#{ entry }") && File.directory?("#{ base_dir }/#{ entry }")
          FileUtils.rm_rf("#{ base_dir }/#{ entry }") if !check_current_day_entry && !entry.include?(Time.now.strftime("%Y%m%d"))
          
          FileUtils.rm_rf("#{ base_dir }/#{ entry }") if check_current_day_entry && entry.include?(Time.now.strftime("%Y%m%d"))

          FileUtils.mkdir_p @config['helper'].current_nodes_file_cache_path
        end
      end
    end

    def remove_current_file_node_cache
      base_dir = File.join( @config['locs']['app-root'], 'tmp', declassify )

      Dir.entries(base_dir).each do |entry|
        next if is_junk_filename?(entry)

        FileUtils.rm_rf("#{ base_dir }/#{ entry }") if File.directory?("#{ base_dir }/#{ entry }") && entry.include?(Time.now.strftime("%Y%m%d"))
      end      
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

    private
    def current_file_path file_name
      File.join( @config['locs']['app-root'], 'tmp', declassify, "#{ Time.now.strftime("%Y%m%d") }-#{ file_name }")
    end
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
