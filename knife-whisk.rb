require 'chef/knife'
require 'yaml'

module ConfigLoader
  def get_config
    # if File.exists?('/Users/ngrayson/banno/knife-whisk/whisk.yml')
    if File.exists?(::Chef::Knife::chef_config_dir+"/whisk.yml")
      YAML.load_file(::Chef::Knife::chef_config_dir+"/whisk.yml")
    else
      puts "Required whisk.yml does not exist"
      exit 1
    end
  end
end

module KnifeWhisk
  class Whisk < Chef::Knife
    banner "knife whisk"
    def run
      ui.fatal "Did you mean \"knife whisk list\" instead?"
      show_usage
      exit 1
    end
  end
  
  class WhiskList < Chef::Knife
    include ConfigLoader
    banner "knife whisk list"
    def run
      full_hash = get_config
      server_list = full_hash["servers"]
      server_list.each do |server|
        puts server.first
      end
    end
  end
  
  class WhiskShow < Chef::Knife
    include ConfigLoader
    banner "knife whisk show TEMPLATENAME"
    def run
      unless name_args.size == 1
        ui.fatal "You must specify a template name"
        show_usage
        exit 1
      end
      config_file = get_config
      puts config_file["#{name_args.first}"]
    end
  end

  class WhiskGenerate < Chef::Knife
    banner "knife whisk generate NODENAME"
  end

  class WhiskHistory < Chef::Knife
    banner "knife whisk history"
  end
end
