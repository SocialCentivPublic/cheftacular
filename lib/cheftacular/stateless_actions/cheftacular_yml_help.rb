
class Cheftacular
  class StatelessActionDocumentation
    def cheftacular_yml_help
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft cheftacular_yml_help KEY` this command" +
        "allows you to get help on the meaning of each key in your cheftacular.yml overall config.",

        [
          "    1. This command can also by run with `cft yaml_help`.",

          "    2. To examine nested keys, you can use colons inbetween the keys like cloud_authentication:rackspace:email"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Gives help on the keys in your cheftacular.yml'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end

    alias_method :yml_help, :cheftacular_yml_help
  end

  class InitializationAction
    def cheftacular_yml_help
      
    end

    alias_method :yml_help, :cheftacular_yml_help
  end

  class StatelessAction
    def cheftacular_yml_help command='', key_nesting_array=[]
      key_to_check = ARGV[1]

      raise "This command requires a key to check the documentation, please enter one as the first argument" if key_to_check.nil?

      key_to_check.split(':').each { |key| key_nesting_array << key }

      doc_hash = YAML::load(ERB.new(IO.read(File.open(File.expand_path("#{ @config['locs']['doc'] }/cheftacular_yml_help.yml")))).result)

      traverse_documentation_hash(doc_hash, key_nesting_array)
    end

    alias_method :yml_help, :cheftacular_yml_help

    private

    def traverse_documentation_hash doc_hash, key_array, index=0
      if doc_hash.has_key?(key_array[index])
        if doc_hash[key_array[index]].class == Hash && key_array.length-1 == index
          if doc_hash[key_array[index]]['key_description'].nil?
            puts "Missing documentation for key #{ key_array[index] }!"
          else
            puts doc_hash[key_array[index]]['key_description']
          end
        elsif doc_hash[key_array[index]].class != Hash && key_array.length-1 == index
          puts doc_hash[key_array[index]]
        elsif doc_hash[key_array[index]].class == Hash && key_array.length-1 != index
          traverse_documentation_hash(doc_hash[key_array[index]], key_array, index+1)
        else
          puts "You attempted to traverse the documentation with a value that was not a key to a hash (#{ key_array[index] }), the value of this key is:"

          puts doc_hash[key_array[index]]
          
          puts "If this is not what you were searching for, please verify your config tree with `cft cheftacular_config display`"
        end
      elsif doc_hash.has_key?('STAR_MATCHER') && key_array.length-1 != index
        traverse_documentation_hash(doc_hash['STAR_MATCHER'], key_array, index+1)
      elsif doc_hash.has_key?('STAR_MATCHER') && key_array.length-1 == index
        puts doc_hash['STAR_MATCHER']['key_description']
      else
        puts "The documentation hash does not have the key #{ key_array[index] }, the keys available here are:"

        ap doc_hash.keys
      end
    end
  end
end
