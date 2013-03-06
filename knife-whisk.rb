require 'chef/knife'
require 'yaml'

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
            :proc => Proc.new { |input| input.split(",")}
          
          option :overrides,
            :short => '-O STRING',
            :long => '--overrides STRING',
            :description => "Override flags, takes string containing flags and values",
            :proc => Proc.new {|string| Hash[*string.split]}
        end
      end
            
      def get_config
        if Chef::Config[:knife][:whisk_config_file].nil?
          if File.exists?(::Chef::Knife::chef_config_dir+"/whisk.yml")
            YAML.load_file(::Chef::Knife::chef_config_dir+"/whisk.yml")
          else
            puts "Required whisk.yml does not exist"
            exit 1
          end
        else
          YAML.load_file(Chef::Config[:knife][:whisk_config_file])
        end
      end
      def get_security_groups(groups)
        if get_config["security-groups"].nil?
          puts "security-groups not defined in whisk.yml"
          exit 1
        else
          lookup_hash = get_config["security-groups"]
          groups.split(',').map! { |name| name.replace(lookup_hash[name]) }.join(',')
        end
      end
    end
  end
      
  class Whisk < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk"
    def run
      ui.fatal "Did you mean \"knife whisk mixin list\" or \"knife whisk server list\" instead?"
      show_usage
      exit 1
    end
  end
  
  class WhiskServerList < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk server list"
    def run
      get_config["servers"].each do |server|
        puts server.first
      end
    end
  end
  
  class WhiskServerShow < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk server show SERVER"
    def run
      unless name_args.size == 1
        ui.fatal "You must specify a server name"
        show_usage
        exit 1
      end
      puts name_args.first
      puts get_config["servers"]["#{name_args.first}"].to_yaml
    end
  end

  class WhiskGenerate < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk generate SERVER [OPTION]"
    def run
      full_hash = get_config
      if name_args.size == 0
        server_config = full_hash["mixins"]["defaults"]
        server_mixins = ["defaults"]
      else
        server_mixins = full_hash["servers"][name_args.first]["mixins"]
        server_config = full_hash["servers"][name_args.first]["config"]
      end
      unless @config[:mixins].nil?
        server_mixins = server_mixins + @config[:mixins]
      end
      output_hash = server_mixins.inject(Hash.new) {|output, mixin| output.merge(full_hash["mixins"][mixin])}.merge(server_config)
      output_hash.each do |mixin, value|
        if value.kind_of?(Array)
          output_hash[mixin] = value.join(",")
        end
      end
      output_hash = output_hash.merge(@config[:overrides])
      output_hash["security-groups"] = get_security_groups(output_hash["security-groups"]) unless output_hash["security-groups"].nil?
      printf "knife ec2 server create %s\n", output_hash.map {|key, value| ["--"+key, value]}.join(" ")
    end
  end

  class WhiskMixinList < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk mixin list"
    def run
      get_config["mixins"].each do |mixin|
        puts mixin.first
      end
    end
  end

  class WhiskMixinShow < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk mixin show MIXIN"
    def run
      unless name_args.size == 1
        ui.fatal "You must specify a mixin"
        show_usage
        exit 1
      end
      puts name_args.first
      puts get_config["mixins"]["#{name_args.first}"].to_yaml
    end
  end

  class WhiskHistory < Chef::Knife
    banner "knife whisk history"
  end
end
