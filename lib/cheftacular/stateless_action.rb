
class Cheftacular
  class StatelessActionDocumentation
    def initialize options, config
      @options, @config = options, config
    end
  end

  class StatelessAction
    include RbConfig
    
    def initialize options, config
      @options, @config = options, config
    end
  end
end
