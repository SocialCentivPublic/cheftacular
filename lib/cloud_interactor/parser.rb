class CloudInteractor
  def parse_args args, final_args={}
    args[0] = args[0].singularize
    #example args: domain "create:mydomain.us:23.253.44.192:my"

    raise "This class does not support #{ args[0] } at this time" unless ALLOWED_HLMS.include?(args[0])

    @classes[args[0]].send(:run, args[1].split(':').first, parse_args_hash(args))
  end

  def parse_args_hash args, hash_args={}
    prep_args = args[1].split(':')

    hash_args[prep_args[0]] = {}

    if prep_args.count > 1
      prep_args[1..(prep_args.count-1)].each do |arg|
        hash_args[prep_args[0]][prep_args.index(arg)] = arg
      end
    else
      hash_args[prep_args[0]]['type'] = prep_args[0]
    end

    mappings = case
               #this case should always be first or else "server" case overrides
               when prep_args[0] =~ /attach_volume|detach_volume|list_volumes|read_volume/ then { 1 => "server_name", 2 => "volume_name", 3 => "size", 4 => "device_location", 5 => 'volume_type'}
               #remap the args from generic args to ones specific for a case
               when args[0] =~ /domain/                                                    then { 1 => "domain", 2 => "subdomain", 3 => "target_ip", 4 => 'type' }
               when args[0] =~ /server/                                                    then { 1 => "name", 2 => "flavor" }
               when args[0] =~ /volume/                                                    then { 1 => "display_name", 2 => "size", 3 => 'volume_type' }
               when args[0] =~ /flavor|image|region|sshkey/                                then { 1 => "name" }
               else raise "FATAL! Unsupported High Level Class #{ args[0] } for CloudInteractor! Please raise an issue on github with this stacktrace! args:#{ args }"
               end 

    Hash[hash_args[hash_args.keys.first].map {|k,v| [mappings[k], v]}]
  end
end
