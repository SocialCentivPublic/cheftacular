class Cheftacular
  class FileSystem
    def initialize options, config
      @options, @config  = options, config
    end

    def write_version_file version
      File.open( current_version_file_path, "w") { |f| f.write(version) }
    end

    def write_nodes_file_cache nodes
      nodes.each do |node|
        File.open( File.join( current_nodes_file_cache_path, "#{ node.name }.json"), "w") { |f| f.write(node.to_json) }
      end
    end

    def write_environment_config_cache
      File.open( current_environment_config_cache_file_path, "w") { |f| f.write("set for #{ Time.now.strftime("%Y%m%d") }") }
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

    def current_environment_config_cache_file_path
      current_file_path 'environment_config-check.txt'
    end

    def is_junk_filename? filename
      filename =~ /.DS_Store|.com.apple.timemachine.supported|README.*/ || filename == '.' || filename == '..' && File.directory?(filename)
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

    def current_nodes_file_cache_path
      current_file_path 'node_cache'
    end

    def cleanup_file_caches mode='old', check_current_day_entry=false
      base_dir = File.join( @config['locs']['app-root'], 'tmp', @config['helper'].declassify )

      Dir.entries(base_dir).each do |entry|
        next if is_junk_filename?(entry)

        case mode
        when 'old'
          FileUtils.rm("#{ base_dir }/#{ entry }") if File.file?("#{ base_dir }/#{ entry }") && !entry.include?(Time.now.strftime("%Y%m%d"))
        when 'current-nodes'
          check_current_day_entry = true
        when 'all'
          FileUtils.rm("#{ base_dir }/#{ entry }") if File.file?("#{ base_dir }/#{ entry }")

          FileUtils.rm_rf("#{ base_dir }/#{ entry }") if File.exists?("#{ base_dir }/#{ entry }") && File.directory?("#{ base_dir }/#{ entry }")
        when 'current-audit-only'
          FileUtils.rm("#{ base_dir }/#{ entry }") if File.file?("#{ base_dir }/#{ entry }") && entry.include?(Time.now.strftime("%Y%m%d"))
        end

        if File.exists?("#{ base_dir }/#{ entry }") && File.directory?("#{ base_dir }/#{ entry }")
          FileUtils.rm_rf("#{ base_dir }/#{ entry }") if !check_current_day_entry && !entry.include?(Time.now.strftime("%Y%m%d"))
          
          FileUtils.rm_rf("#{ base_dir }/#{ entry }") if check_current_day_entry && entry.include?(Time.now.strftime("%Y%m%d"))

          FileUtils.mkdir_p current_nodes_file_cache_path
        end
      end
    end

    def remove_current_file_node_cache
      base_dir = File.join( @config['locs']['app-root'], 'tmp', @config['helper'].declassify )

      Dir.entries(base_dir).each do |entry|
        next if is_junk_filename?(entry)

        FileUtils.rm_rf("#{ base_dir }/#{ entry }") if File.directory?("#{ base_dir }/#{ entry }") && entry.include?(Time.now.strftime("%Y%m%d"))
      end      
    end

    def current_chef_repo_cheftacular_file_cache_path
      current_file_path "chef_repo_cheftacular_cache"
    end

    def current_local_cheftacular_file_cache_path
      current_file_path "local_cheftacular_cache"
    end

    def write_chef_repo_cheftacular_cache_file hash
      File.open( current_chef_repo_cheftacular_file_cache_path, "w") { |f| f.write(hash) }
    end

    def write_local_cheftacular_cache_file hash_string
      File.open( current_local_cheftacular_file_cache_path, 'w') { |f| f.write(hash_string) }
    end

    def write_chef_repo_cheftacular_yml_file file_location
      File.open( file_location, "w") { |f| f.write(@config['helper'].compile_chef_repo_cheftacular_yml_as_hash.to_yaml) }
    end

    def write_config_cheftacular_yml_file filename='cheftacular.yml'
      File.open( File.join(@config['locs']['chef-repo'], "config", filename), "w") { |f| f.write(File.read(File.join(@config['locs']['examples'], "cheftacular.yml"))) }
    end

    private
    def current_file_path file_name
      File.join( @config['locs']['app-root'], 'tmp', @config['helper'].declassify, "#{ Time.now.strftime("%Y%m%d") }-#{ file_name }")
    end
  end
end
