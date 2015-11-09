
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
    end
  end
end
