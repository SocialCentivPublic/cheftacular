
class CloudInteractor
  class Server #http://docs.rackspace.com/servers/api/v2/cs-devguide/content/Servers-d1e2073.html
    def create args
      @classes['image'].read @options['preferred_cloud_image'], false

      #Note, if no flavor is passed it defaults to a 512MB standard!
      @classes['flavor'].read args['flavor'], @options.has_key?('verbose')

      @classes['region'].read(@options['preferred_cloud_region'], false) if @options['preferred_cloud'] == 'digitalocean'
      @classes['sshkey'].bootstrap if @options['preferred_cloud'] == 'digitalocean'

      read args, false

      unless @main_obj["specific_#{ IDENTITY }"].empty?
        puts "(#{ IDENTITY }) #{ IDENTITY } #{ args['name'] } already exists... returning."

        return false
      end

      puts "(#{ IDENTITY }) Creating #{ args['name'] } in #{ IDENTITY }..."

      final_create_args = {
        name:      args['name'],
        flavor_id: @main_obj['specific_flavors'].first['id'],
        image_id:  @main_obj['specific_images'].first['id']
      }

      if @options['preferred_cloud'] == 'digitalocean'
        final_create_args[:region]             = @main_obj['specific_regions'].first['slug']
        final_create_args[:ssh_keys]           = [@main_obj['specific_ssh_keys'].first['id']]
        final_create_args[:size]               = @main_obj['specific_flavors'].first['slug']
        final_create_args[:image]              = @main_obj['specific_images'].first['slug']
        final_create_args[:private_networking] = true

        final_create_args.delete(:flavor_id)
        final_create_args.delete(:image_id)
      end

      @main_obj["#{ IDENTITY }_create_request"] = JSON.parse(@classes['auth'].auth_service(RESOURCE).instance_eval(IDENTITY).create(final_create_args).to_json)

      @main_obj["#{ IDENTITY }_created_passwords"] ||= {}
      @main_obj["#{ IDENTITY }_created_passwords"][args['name']] = @main_obj["#{ IDENTITY }_create_request"]['password']

      @main_obj["#{ IDENTITY }_created_details"] ||= {}
      @main_obj["#{ IDENTITY }_created_details"][args['name']] = @main_obj["#{ IDENTITY }_create_request"]

      puts "(#{ IDENTITY }) Successfully created #{ args['name'] } with pass #{ @main_obj["#{ IDENTITY }_created_passwords"][args['name']] }"

      @main_obj['output']['admin_passwords'] = { args['name'] => @main_obj["#{ IDENTITY }_created_passwords"][args['name']] }
    end
  end
end
