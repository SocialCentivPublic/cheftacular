class Cheftacular
  class StatelessActionDocumentation
    def fetch_file
      @config['documentation']['stateless_action'] <<  [
        "[NYI]`cft fetch_file NODE_NAME LOCATION_ALIAS FILE_NAME` fetches a file from the remote node. ",

        [
          "    1. `LOCATION_ALIAS` will be parsed as a path if it has backslash characters. Otherwise it will be parsed from your " +
          "location_aliases hash in your cheftacular.yml",

          "    2. `FILE_NAME` is the actual name of the file to be fetched. If no value is passed or the file does not exist in the " +
          "LOCATION_ALIAS, the command will return the entries in LOCATION_ALIAS"
        ]
      ]
    end
  end

  class StatelessAction
    def fetch_file out=[]
      #TODO
      raise "Not yet implemented"
    end
  end
end
