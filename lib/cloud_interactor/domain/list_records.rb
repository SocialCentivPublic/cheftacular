class CloudInteractor
  class Domain
    def list_records args, output=false
      puts "(#{ IDENTITY.capitalize }) Querying #{ args["domain"] } for records..."

      specific_fog_object = @classes['auth'].auth_service(RESOURCE).instance_eval('zones').get @main_obj["specific_#{ IDENTITY }"].last['id']

      @main_obj['specific_records'] ||= {}
      @main_obj['specific_records'][args[IDENTITY.singularize]]  ||= []
      @main_obj["specific_#{ IDENTITY }"].last['records'] ||= []

      specific_fog_object.records.each do |record|
        record_obj = JSON.parse(record.to_json)

        @main_obj["specific_#{ IDENTITY }"].last['records'] << record_obj
        @main_obj['specific_records'][args[IDENTITY.singularize]] << record_obj
      end

      @main_obj['output']["records_for_#{ @main_obj["specific_#{ IDENTITY }"].last['domain'] }"] = @main_obj["specific_#{ IDENTITY }"].last['records']

      ap(@main_obj["specific_#{ IDENTITY }"].last['records']) if output
    end
  end
end
