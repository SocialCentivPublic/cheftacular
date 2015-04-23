class CloudInteractor
  class Volume
    def create args
      puts "Creating #{ args['display_name'] } in #{ IDENTITY }..."

      puts("Creating #{ IDENTITY.singularize } with args #{ ap(args) }") if @options['verbose']

      args['volume_type'] = 'SSD' unless args['volume_type']

      @main_obj["#{ IDENTITY }_create_request"] = JSON.parse(@classes['auth'].auth_service(RESOURCE).instance_eval(IDENTITY).create(args).to_json)
    end
  end
end
