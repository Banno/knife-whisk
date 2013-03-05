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
    end
  end
      
  class Whisk < Chef::Knife
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
      server_list = get_config["servers"]
      server_list.each do |server|
        puts server.first
      end
    end
  end
  
  class WhiskServerShow < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk server show TEMPLATENAME"
    def run
      unless name_args.size == 1
        ui.fatal "You must specify a template name"
        show_usage
        exit 1
      end
      server_list = get_config["servers"]
      puts name_args.first
      puts server_list["#{name_args.first}"].to_yaml
    end
  end

  class WhiskGenerate < Chef::Knife
    include Knife::WhiskBase
    banner "knife whisk generate SERVERTEMPLATE [OPTION]"
    def run
      unless name_args.size >= 1 
        ui.fatal "no args provided"
        show_usage
        exit 1
      end
      servertemplate = name_args.first
      # overrides = Hash[*name_args[1..-1]]
      # pp overrides
      full_hash = get_config
      server_mixins = full_hash["servers"][servertemplate]["mixins"]
      server_config = full_hash["servers"][servertemplate]["config"]
      output_hash = server_mixins.inject(Hash.new) {|output, mixin| output.merge(full_hash["mixins"][mixin])}
      output_hash = output_hash.merge(server_config)
      output_hash.each do |mixin, value|
        if value.kind_of?(Array)
          output_hash[mixin] = value.join(",")
        end
      end
      output = output_hash.map {|key, value| ["--"+key, value]}.join(" ")
      printf "knife ec2 server create %s\n", output
    end
  end

  class WhiskMixinList < Chef::Knife
  end

  class WhiskMixinShow < Chef::Knife
  end

  class WhiskHistory < Chef::Knife
    banner "knife whisk history"
  end
end
