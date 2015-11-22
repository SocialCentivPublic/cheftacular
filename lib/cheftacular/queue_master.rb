
class Cheftacular
  class QueueMaster
    def initialize options, config
      @options, @config  = options, config
    end

    def work_off_slack_queue
      return true if @config['slack_queue'].empty?
      
      @config['slack_queue'].each do |slack_hash|
        @config['stateless_action'].slack(slack_hash[:message], slack_hash[:channel])
      end

      @config['slack_queue'] = []
    end

    def sync_server_hash_into_queue server_hash, server_queue='server_creation_queue', found_result=false
      @config[server_queue].select { |hash| hash['node_name'] == server_hash['node_name']}.each do |queue_hash|
        @config[server_queue][ @config[server_queue].index(queue_hash) ] = queue_hash.merge(server_hash)

        found_result = true
      end

      @config[server_queue] << server_hash unless found_result
    end

    def generate_passwords_for_each_server_hash_in_queue server_queue='server_creation_queue'
      @config[server_queue].each do |queue_hash|
        @config[server_queue][ @config[server_queue].index(queue_hash) ] = queue_hash.merge(
          { 'deploy_password' => @config['helper'].gen_pass(@config['cheftacular']['server_pass_length']) }
        )
      end
    end

    def return_hash_from_queue queue_name, hash, hash_key
      @config[queue_name].select { |queue_hash| queue_hash[hash_key] == hash[hash_key] }.first
    end
  end
end
