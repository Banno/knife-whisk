require 'chef/knife'
require 'yaml'

#module KnifeWhisk
class Chef
  class Knife
    module ConfigLoader
      def self.included(includer)
        includer.class_eval do
          option :custom_path,
            :short => '-C',
            :log => '--config_path',
            :boolean => true,
            :description => "Specify path to your whisk.yml file"
        end
      end
            
      def get_config
        if File.exists?(::Chef::Knife::chef_config_dir+"/whisk.yml")
          YAML.load_file(::Chef::Knife::chef_config_dir+"/whisk.yml")
        else
          puts "Required whisk.yml does not exist"
          exit 1
        end
      end    
    end
  end
      
    class Whisk < Chef::Knife
      banner "knife whisk"
      def run
        ui.fatal "Did you mean \"knife whisk list\" instead?"
        show_usage
        exit 1
      end
    end
    
    class WhiskList < Chef::Knife
      include Knife::ConfigLoader
      banner "knife whisk list"
      def run
        server_list = get_config["servers"]
        server_list.each do |server|
          puts server.first
        end
      end
    end
    
    class WhiskShow < Chef::Knife
      include Knife::ConfigLoader
      banner "knife whisk show TEMPLATENAME"
      def run
        unless name_args.size == 1
          ui.fatal "You must specify a template name"
          show_usage
          exit 1
        end
        server_list = get_config["servers"]
        puts server_list["#{name_args.first}"].to_yaml
      end
    end

    class WhiskGenerate < Chef::Knife
      banner "knife whisk generate NODENAME"
    end

  class WhiskHistory < Chef::Knife
    banner "knife whisk history"
  end
end
