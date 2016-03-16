
class Cheftacular
  class ActionDocumentation
    def initialize options, config
      @options, @config = options, config
    end
  end

  class Action
    include SSHKit::DSL
    
    def initialize options, config
      @options, @config = options, config
    end
  end
end
