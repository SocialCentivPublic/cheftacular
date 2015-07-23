
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
      File.open( @config['filesystem'].current_audit_file_path, "w") { |f| f.write( fetch_audit_data_hash ) }
    end

    def read_audit_cache_file_to_hash ret_hash={}, options_to_ignore=[]
      ret_hash = Hash.class_eval( File.read( @config['filesystem'].current_audit_file_path ))
      ret_hash['command']   = @options['command']
      
      options_to_ignore << :preferred_cloud        if @options['preferred_cloud'] == @config['cheftacular']['preferred_cloud']
      options_to_ignore << :preferred_cloud_image  if @options['preferred_cloud_image'] == @config['cheftacular']['preferred_cloud_image']
      options_to_ignore << :preferred_cloud_region if @options['preferred_cloud_region'] == @config['cheftacular']['preferred_cloud_region']
      options_to_ignore << :virtualization_mode    if @options['virtualization_mode'] == @config['cheftacular']['virtualization_mode']
      options_to_ignore << :route_dns_changes_via  if @options['route_dns_changes_via'] == @config['cheftacular']['route_dns_changes_via']

      ret_hash['options']   = @options.dup.delete_if { |key, value| options_to_ignore.include?(key.to_sym) }

      ret_hash['arguments'] = ARGV[1..ARGV.length]

      ret_hash
    end

    def fetch_audit_data_hash ret_hash={}, ip=""
      ret_hash['hostname']  = Socket.gethostname

      ret_hash
    rescue StandardError => exception
      @config['filesystem'].cleanup_file_caches('current-audit-only')

      @config['error'].exception_output "Unable to finish parsing auditing hash", exception
    end
  end
end
