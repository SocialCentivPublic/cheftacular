$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "cheftacular/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "cheftacular"
  s.version     = Cheftacular::VERSION
  s.authors     = ['Louis Alridge']
  s.email       = ['louis@socialcentiv.com', 'loualrid@gmail.com']
  s.summary     = 'Practically open source heroku'
  s.description = 'Ruby gem for managing a chef stack. Primarily targetted towards rails stacks and is designed to be easy to use like Heroku CLI'
  s.executables = ['cft', 'cheftacular', 'cftclr']

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  #s.test_files = Dir["spec/**/*"]

  s.required_ruby_version = '>= 1.9.1'
  s.add_dependency "hashie", ">= 2.0" #hashie 3.0+ breaks varia_model
  s.add_dependency "chef", ">= 11.12"
  s.add_dependency "httpclient"
  s.add_dependency "ridley"
  s.add_dependency "berkshelf", '>= 4.0'
  s.add_dependency "berkshelf-api-client", '>= 2.0'
  s.add_dependency "highline"
  s.add_dependency "ffi-yajl"
  s.add_dependency "awesome_print"
  s.add_dependency "sshkit"
  s.add_dependency "activesupport"
  s.add_dependency "public_suffix"
  s.add_dependency "rest-client"
  s.add_dependency "fog", ">= 1.35"
  s.add_dependency "slack-notifier"
  s.add_dependency "cloudflare"
end
