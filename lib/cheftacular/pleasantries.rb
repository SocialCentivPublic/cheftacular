class Cheftacular
  class Pleasantries
    def initialize options, config
      @options, @config  = options, config
    end

    def good_luck_fridays #https://gist.github.com/exAspArk/4f18795bc89b6e2666ee
      friday_jumper = %{
┓┏┓┏┓┃
┛┗┛┗┛┃⟍ ○⟋
┓┏┓┏┓┃  ∕       Friday
┛┗┛┗┛┃ノ)
┓┏┓┏┓┃          deploy,
┛┗┛┗┛┃
┓┏┓┏┓┃          good
┛┗┛┗┛┃
┓┏┓┏┓┃          luck!
┃┃┃┃┃┃
┻┻┻┻┻┻
      }.strip!

      puts(friday_jumper) if Time.now.friday? && @options['env'] == 'production'
    end
  end
end
