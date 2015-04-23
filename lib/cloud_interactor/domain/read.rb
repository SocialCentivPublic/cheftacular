class CloudInteractor
  class Domain
    def read args={}, output=true
      list [], false

      @classes['helper'].generic_read_parse args, IDENTITY, output, IDENTITY.singularize

      @main_obj["specific_#{ IDENTITY }"] ||= {}

      specific_identity = @classes['helper'].set_specific_identity args, IDENTITY.singularize

      @main_obj[IDENTITY].each do |identity_hash|
        next if !specific_identity.nil? && !identity_hash[IDENTITY.singularize].include?(specific_identity)

        self.list_records identity_hash
      end

      ap(@main_obj["specific_#{ IDENTITY }"]) if output

      puts("#{ specific_identity } not found in #{ IDENTITY }!") if @main_obj["specific_#{ IDENTITY }"].empty?
    end
  end
end
