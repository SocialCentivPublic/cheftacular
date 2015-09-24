
class Cheftacular
  class QueueMaster
    def initialize options, config
      @options, @config  = options, config
    end

    def work_off_slack_queue
      return true if @config['slack_queue'].empty?
      
      @config['slack_queue'].each do |message|
        @config['stateless_action'].slack(message)
      end
    end
  end
end
