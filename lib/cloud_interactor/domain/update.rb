#TODO Grant more options to update?
class CloudInteractor
  class Domain
    def update args
      read args, false

      if (@main_obj["specific_#{ IDENTITY }"].nil? || @main_obj["specific_#{ IDENTITY }"].empty?) && @main_obj["specific_#{ IDENTITY }"].last[IDENTITY.singularize] != args[IDENTITY.singularize]
        puts "#{ IDENTITY } #{ args[IDENTITY.singularize] } doesn't exist... returning."

        return false
      end

      @classes['auth'].auth_service(resource).instance_eval('zones').get(@main_obj["specific_#{ IDENTITY }"].last['id']).update(ttl: 5, email: @auth_hash['cloud_authentication'][@options['preferred_cloud']]['email'])

      puts "Updated #{ IDENTITY } #{ args[IDENTITY.singularize] }..."
    end
  end
end
