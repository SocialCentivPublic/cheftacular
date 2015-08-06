
class Cheftacular
  class StatelessActionDocumentation
    def cloud
      @config['documentation']['stateless_action'] <<  [
        "`cft cloud <FIRST_LEVEL_ARG> [<SECOND_LEVEL_ARG>[:<SECOND_LEVEL_ARG_QUERY>]*] ` this command handles talking to various cloud APIs. " +
        "If no args are passed nothing will happen.",

        [
          "    1. `domain` first level argument for interacting with cloud domains",

          "        1. `list` default behavior",

          "        2. `read:TOP_LEVEL_DOMAIN` returns detailed information about all subdomains attached to the TOP_LEVEL_DOMAIN",

          "        3. `read_record:TOP_LEVEL_DOMAIN:QUERY_STRING` queries the top level domain for all subdomains that have the QUERY_STRING in them.",

          "        4. `create:TOP_LEVEL_DOMAIN` creates the top level domain on rackspace",

          "        5. `create_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME:IP_ADDRESS[:RECORD_TYPE[:TTL]]` " + 
          "IE: `cft cloud domain create:mydomain.com:myfirstserver:1.2.3.4` will create the subdomain 'myfirstserver' on the mydomain.com domain.",

          "        6. `destroy:TOP_LEVEL_DOMAIN` destroys the top level domain and all of its subdomains",

          "        7. `destroy_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME` deletes the subdomain record for TOP_LEVEL_DOMAIN if it exists.",

          "        8. `update:TOP_LEVEL_DOMAIN` takes the value of the email in the authentication data bag for your specified cloud and updates the TLD.",

          "        9. `update_record:TOP_LEVEL_DOMAIN:SUBDOMAIN_NAME:IP_ADDRESS[:RECORD_TYPE[:TTL]]` similar to `create_record`.",

          "    2. `server` first level argument for interacting with cloud servers, " +
          "if no additional args are passed the command will return a list of all servers on the preferred cloud.",

          "        1.  `list` default behavior",

          "        2. `read:SERVER_NAME` returns all servers that have SERVER_NAME in them (you want to be as specific as possible for single matches)",

          "        3. `create:SERVER_NAME:FLAVOR_ALIAS` IE: `cft cloud server \"create:myserver:1 GB Performance\"` " +
          "will create a server with the name myserver and the flavor \"1 GB Performance\". Please see flavors section.",

          "            1. NOTE! If you forget to pass in a flavor alias the script will not error! It will attempt to create a 512MB Standard Instance!",

          "            2. NOTE! Most flavors have spaces in them, you must use quotes at the command line to utilize them!",

          "        4. `destroy:SERVER_NAME` destroys the server on the cloud. This must be an exact match of the server's actual name or the script will error.",

          "        5. `poll:SERVER_NAME` polls the cloud's server for the status of the SERVER_NAME. This command " +
          "will stop polling if / when the status of the server is ACTIVE and its build progress is 100%.",

          "        6. `attach_volume:SERVER_NAME:VOLUME_NAME[:VOLUME_SIZE[:DEVICE_LOCATION]]` " +
          "If VOLUME_NAME exists it will attach it if it is unattached otherwise it will create it",

          "            1. NOTE! If the system creates a volume the default size is 100 GB!",

          "            2. DEVICE_LOCATION refers to the place the volume will be mounted on, a place like `/dev/xvdb`, " +
          "from here it must be added to the filesystem to be used.",

          "            3. If you want to specify a location, you must specify a size, if the volume already exists it wont be resized but will be attached at that location!",

          "            4. If DEVICE_LOCATION is blank the volume will be attached to the first available slot.",

          "        7. `detach_volume:SERVER_NAME:VOLUME_NAME` Removes the volume from the server if it is attached. " +
          "If this operation is performed while the volume is mounted it could corrupt the volume! Do not do this unless you know exactly what you're doing!",

          "        8. `list_volumes:SERVER_NAME` lists all volumes attached to a server",

          "        9. `read_volume:SERVER_NAME:VOLUME_NAME` returns the data of VOLUME_NAME if it is attached to the server.",

          "    3. `volume` first level argument for interacting with cloud storage volumes, if no additional args are passed the command will return a list of all cloud storage containers.",
            
          "        1. `list` default behavior",

          "        2. `read:VOLUME_NAME` returns the details for a specific volume.",

          "        3. `create:VOLUME_NAME:VOLUME_SIZE` IE `cft rax volume create:staging_db:256`",

          "        4. `destroy:VOLUME_NAME` destroys the volume. This operation will not work if the volume is attached to a server.",

          "    4. `flavor` first level argument for listing the flavors available on the cloud service",

          "        1. `list` default behavior",

          "        2. `read:FLAVOR SIZE` behaves the same as list unless a flavor size is supplied.",

          "            1. Standard servers are listed as XGB with no spaces in their size, performance servers are listed as X GB with " +
          "a space in their size. If you are about to create a server and are unsure, query flavors first.",

          "    5. `image` first level argument for listing the images available on the cloud service",

          "        1. `list` default behavior",

          "        2. `read:NAME` behaves the same as list unless a specific image name is supplied",

          "    6. `region` first level argument for listing the regions available on the cloud service (only supported by DigitalOcean)",

          "        1. `list` default behavior",

          "        2. `read:REGION` behaves the same as list unless a specific region name is supplied",

          "    7. `sshkey` first level argument for listing the sshkeys added to the cloud service (only supported by DigitalOcean)",

          "        1. `list` default behavior",

          "        2. `read:KEY_NAME` behaves the same as list unless a specific sshkey name is supplied",

          "        3. `\"create:KEY_NAME:KEY_STRING\"` creates an sshkey object. KEY_STRING must contain the entire value of the ssh public key file. " +
          "The command must be enclosed in quotes.",

          "        4. `destroy:KEY_NAME` destroys the sshkey object",

          "        5. `bootstrap` captures the current computer's hostname and checks to see if a key matching this hostname exists on the cloud service. " +
          "If the key does not exist, the command attempts to read the contents of the ~/.ssh/id_rsa.pub file and create a new key with that data and the " +
          "hostname of the current computer. Run automatically when creating DigitalOcean servers. It's worth noting that if the computer's key already " +
          "exists on DigitalOcean under a different name, this specific command will fail with a generic error. Please check your keys."
        ]
      ]
    end
  end

  class StatelessAction
    def cloud *args
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']

      args = ARGV[1..ARGV.length] if args.empty?

      @config['cloud_interactor'] ||= CloudInteractor.new(@config['cheftacular'], @options)

      @config['cloud_interactor'].run args
    end

    alias_method :aws, :cloud

    alias_method :rax, :cloud
  end
end
