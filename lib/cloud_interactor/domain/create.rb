class CloudInteractor
  class Domain
    def create args, already_created=false
      read args, false

      unless @main_obj["specific_#{ IDENTITY }"].empty?
        puts "(#{ IDENTITY.capitalize }) #{ IDENTITY } #{ args[IDENTITY.singularize] } already exists... returning."

        return false
      end

      @classes['auth'].auth_service(RESOURCE).instance_eval('zones').create(domain: args[IDENTITY.singularize], email: @auth_hash['cloud_authentication'][@options['preferred_cloud']]['email'])

      puts "(#{ IDENTITY.capitalize }) Created #{ IDENTITY } #{ args[IDENTITY.singularize] }..."
    end
  end
end
