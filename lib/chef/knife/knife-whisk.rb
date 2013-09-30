require 'chef/knife'
require 'safe_yaml'

class Chef
  class Knife
    module WhiskBase
      def self.included(includer)
        includer.class_eval do

          option :whisk_config_file,
            :short => '-C PATH',
            :long => '--whisk-config PATH',
            :description => "Specify path to your whisk.yml file",
            :proc => Proc.new { |path| Chef::Config[:knife][:whisk_config_file] = path }

          option :mixins,
            :short => '-M MIXINS',
            :long => '--mixins MIXINS',
            :description => "Overrides server mixins, takes comma seperated list of mixins",
            :proc => Proc.new { |input| input.split(",") }

          option :overrides,
            :short => '-O STRING',
            :long => '--overrides STRING',
            :description => "Override flags, takes string containing flags and values",
            :proc => Proc.new { |string|
              # checks if the flags have -- in front, if not error, if so strip them before returning
              if Hash[*string.split].keys.select { |n| n[0..1] != "--" }.size == 0
                Hash[Hash[*string.split].map {|key, val|[key.sub(/^--/, ''), val]}]
              else
                false
              end
            }
        end
      end

      def exit_with_message(message)
        ui.fatal message
        Kernel.exit(1)
      end

      def get_config
        if Chef::Config[:knife][:whisk_config_file].nil?
          if File.exists?(::Chef::Knife::chef_config_dir+"/whisk.yml")
            YAML.load_file(::Chef::Knife::chef_config_dir+"/whisk.yml", :safe => true)
          else
            return false
          end
        else
          YAML.load_file(Chef::Config[:knife][:whisk_config_file], :safe => true)
        end
      end

      def get_security_groups(groups)
        groups.split(',').map! { |name| name.replace(get_config["provider_config"]["aws"]["security-groups"][name]) }.join(',')
      end

      def security_group_exists?(group)
        ! get_config["provider_config"]["aws"]["security-groups"][group].nil?
      end

      def mixin_exists?(mixin)
        ! get_config["mixins"][mixin].nil?
      end

      def server_exists?(server)
        ! get_config["servers"][server].nil?
      end

      def add_quotes(val)
        "\"#{val}\""
      end

    end
  end

  class WhiskServerList < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk server list"

    def run
      exit_with_message("Required whisk.yml does not exist") unless get_config
      get_config["servers"].each do |server|
        puts server.first
      end
    end
  end

  class WhiskServerShow < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk server show SERVER"

    def run
      exit_with_message("Required whisk.yml does not exist") unless get_config
      exit_with_message("You must specify a server name") unless name_args.size == 1

      if server_exists?(name_args.first)
        puts name_args.first
        puts get_config["servers"]["#{name_args.first}"].to_yaml
      else
        exit_with_message("#{name_args.first} server template does not exist")
      end
    end
  end

  class WhiskMixinList < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk mixin list"

    def run
      exit_with_message("Required whisk.yml does not exist") unless get_config
      get_config["mixins"].each do |mixin|
        puts mixin.first
      end
    end
  end

  class WhiskMixinShow < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk mixin show MIXIN"

    def run
      exit_with_message("Required whisk.yml does not exist") unless get_config
      exit_with_message("You must specify a mixin") unless name_args.size == 1

      if mixin_exists?(name_args.first)
        puts name_args.first
        puts get_config["mixins"]["#{name_args.first}"].to_yaml
      else
        exit_with_message("#{name_args.first} mixin does not exist")
      end
    end
  end

  class WhiskGenerate < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk generate [SERVER]"

    def run
      exit_with_message("Required whisk.yml does not exist") unless get_config

      full_hash = get_config

      if name_args.size == 0
        server_config = full_hash["mixins"]["defaults"]
        server_mixins = ["defaults"]
      elsif server_exists?(name_args.first)
        server_mixins = full_hash["servers"][name_args.first]["mixins"]
        server_config = full_hash["servers"][name_args.first]["config"]
      else
        exit_with_message("#{name_args.first} server template does not exist")
      end

      unless @config[:mixins].nil?
        server_mixins = server_mixins + @config[:mixins]
      end

      #checks to make sure all mixins exist
      server_mixins.each { |mixin| exit_with_message("#{mixin} mixin does not exist") unless mixin_exists?(mixin) }

      #merges together all mixin config values with server config values
      output_hash = server_mixins.inject(Hash.new) {|output, mixin| output.merge(full_hash["mixins"][mixin])}.merge(server_config)

      #convert config values that are arrays to comma seperates strings
      output_hash.each do |mixin, value|
        if value.kind_of?(Array)
          output_hash[mixin] = value.join(",")
        end
      end

      unless @config[:overrides].nil?
        exit_with_message("Please use long form flags only in overrides") unless @config[:overrides].kind_of?(Hash)
        output_hash = output_hash.merge(@config[:overrides])
      end

      #check things for aws
      if output_hash["provider"]["aws"]
        #convert security-group names to ids if needed and make sure they exist in the lookup hash
        unless output_hash["security-groups"].nil?
          exit_with_message("security-groups not defined for this config in whisk.yml") unless get_config["provider_config"]["aws"]["security-groups"]
          output_hash["security-groups"].split(',').each { |group| exit_with_message("#{group} security group does not exist in whisk.yml") unless security_group_exists?(group)}
          output_hash["security-group-ids"] = get_security_groups(output_hash["security-groups"])
          output_hash.delete("security-groups")
        end
      end

      #some values need quotes for knife ec2 to accept the arg
      output_hash["run-list"] = add_quotes(output_hash["run-list"]) unless output_hash["run-list"].nil?
      # json doesn't work currently output_hash["json-attributes"] = add_quotes(output_hash["json-attributes"]) unless output_hash["json-attributes"].nil?

      output_hash["node-name"] = name_args.first if output_hash["node-name"].nil?

      #get config string and check to make sure it exists
      exit_with_message("provider attribute must be provided") unless output_hash["provider"]
      exit_with_message("#{output_hash["provider"]} cli_command doesn't exist in whisk.yml") unless full_hash["provider_config"][output_hash["provider"]]["cli_command"]
      cli_command = full_hash["provider_config"][output_hash["provider"]]["cli_command"]

      output_hash.delete("provider")

      printf "knife %s %s\n", cli_command, output_hash.map { |key, value| ["--"+key, value] }.join(" ")
    end
  end
end
