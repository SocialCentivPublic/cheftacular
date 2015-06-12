class CloudInteractor
  ALLOWED_HLMS = ['domain', 'flavor', 'image', 'server', 'volume']

  def initialize auth_hash, options
    @main_obj, @classes = {},{}
    @options            = options
    @main_obj['output'] = {}
    @auth_hash          = auth_hash
    @classes['helper']  = Helper.new(@main_obj, @classes, @options)
    @classes['domain']  = Domain.new(@main_obj, @auth_hash, @classes, @options)
    @classes['flavor']  = Flavor.new(@main_obj, @classes, @options)
    @classes['image']   = Image.new(@main_obj, @classes, @options)
    @classes['server']  = Server.new(@main_obj, @classes, @options)
    @classes['volume']  = Volume.new(@main_obj, @classes, @options)
    @classes['auth']    = Authentication.new(@auth_hash, @options)
  end

  def run args
    parse_args(args) unless args.empty?

    #clear out the main_obj so repeated runs do not cause strange data
    @main_obj = @main_obj.keep_if {|key, value| key == 'output'}

    @main_obj['output']
  end
end
