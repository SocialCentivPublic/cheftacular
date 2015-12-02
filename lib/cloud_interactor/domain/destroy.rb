class CloudInteractor
  class Domain
    def destroy args
      read args, false

      if @main_obj["specific_#{ IDENTITY }"].empty? && @main_obj["specific_#{ IDENTITY }"].last[IDENTITY.singularize] != args[IDENTITY.singularize]
        puts "(#{ IDENTITY.capitalize }) #{ IDENTITY } #{ args[IDENTITY.singularize] } doesn't exist... returning."

        return false
      end

      @classes['auth'].auth_service(RESOURCE).instance_eval('zones').get(@main_obj["specific_#{ IDENTITY }"].last['id']).destroy

      puts "(#{ IDENTITY.capitalize }) Destroyed #{ IDENTITY.singularize } #{ args[IDENTITY.singularize] }..."
    end
  end
end
