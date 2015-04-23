class CloudInteractor
  class Domain
    def read_record args, output=true, strict_match=false

      specific_record = args['subdomain']

      read args, false

      @main_obj['specific_records'][args[IDENTITY.singularize]].each do |record_hash|
        if strict_match
          next unless record_hash['name'] == (specific_record)
        else
          next unless record_hash['name'].include?(specific_record)
        end

        @main_obj['specific_queried_domains'] ||= {}

        @main_obj['specific_queried_domains'][args[IDENTITY.singularize]] ||= []
        @main_obj['specific_queried_domains'][args[IDENTITY.singularize]]  << record_hash

        ap(record_hash) if output
      end

      puts("#{ args[IDENTITY.singularize] } does not have the subdomain #{ args['subdomain'] }!") if @main_obj["specific_queried_domains"].nil?
    end
  end
end
