
class Cheftacular
  class Auditor
    def initialize options, config
      @options, @config = options, config
    end

    def audit_run
      current_day  = Time.now.strftime('%Y%m%d')
      current_time = Time.now.strftime('%H:%M')

      @config[@options['env']]['audit_bag_hash']['audit_log'][current_day] ||= {}
      @config[@options['env']]['audit_bag_hash']['audit_log'][current_day][current_time] ||= []
      @config[@options['env']]['audit_bag_hash']['audit_log'][current_day][current_time] << read_audit_cache_file_to_hash

      @config['ChefDataBag'].save_audit_bag
    end

    def write_audit_cache_file
      File.open( @config['helper'].current_audit_file_path, "w") { |f| f.write( fetch_audit_data_hash ) }
    end

    def read_audit_cache_file_to_hash ret_hash={}
      ret_hash = Hash.class_eval( File.read( @config['helper'].current_audit_file_path ))
      ret_hash['command']   = @options['command']
      ret_hash['options']   = @options.except(:preferred_cloud, :preferred_cloud_region, :preferred_cloud_image) #TODO load preferred_X options if they are not the default?
      ret_hash['arguments'] = ARGV[1..ARGV.length]

      ret_hash
    end

    def fetch_audit_data_hash ret_hash={}, ip=""
      begin
        Timeout::timeout(10) do
          response = Net::HTTP.get URI.parse('http://checkip.dyndns.org')
          ip = response.match( /(?:Address: )([\d\.]+)/ )[1]
        end
      rescue StandardError => e
        tries ||= 4

        puts "Unable to fetch remote IP address for auditing hash. Trying #{tries} more times."

        tries -= 1

        if tries > 0
          sleep(15)

          retry
        else
          ip = "Unable to fetch"
        end
      end

      ret_hash['hostname']  = Socket.gethostname
      ret_hash['true_ip']   = ip

      ret_hash
    rescue StandardError => exception
      @config['helper'].cleanup_file_caches('current-audit-only')

      @config['helper'].exception_output "Unable to finish parsing auditing hash", exception
    end
  end
end
