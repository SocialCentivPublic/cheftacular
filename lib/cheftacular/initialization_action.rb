
class Cheftacular
  class InitializationAction
  	include SSHKit::DSL
  	
    def initialize options, config
      @options, @config = options, config
    end
  end
end
