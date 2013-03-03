require 'chef/knife'
require 'yaml'

#module KnifeWhisk
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
      def get_flags
        ec2_flags = [
          "" => "availability-zone",
          "" => "aws-access-key-id",
          "" => "aws-secret-access-key",
          "" => "user-data",
          "" => "bootstrap-version",
          "" => "node-name",
          "" => "server-url",
          "" => "key",
          "" => "[no-]color",
          "" => "config",
          "" => "defaults",
          "" => "disable-editing",
          "" => "distro",
          "" => "ebs-no-delete-on-term",
          "" => "ebs-optimized",
          "" => "ebs-size",
          "" => "editor",
          "" => "environment",
          "" => "ephemeral",
          "" => "flavor",
          "" => "format",
          "" => "hint",
          "" => "[no-]host-key-verify",
          "" => "identity-file",
          "" => "image",
          "" => "json-attributes",
          "" => "user",
          "" => "prerelease",
          "" => "print-after",
          "" => "private-ip-address",
          "" => "region",
          "" => "run-list",
          "" => "security-group-ids",
          "" => "groups",
          "" => "server-connect-attribute",
          "" => "ssh-gateway",
          "" => "ssh-key",
          "" => "ssh-password",
          "" => "ssh-port",
          "" => "ssh-user",
          "" => "subnet",
          "" => "tags",
        ]
        pp ec2_flags
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
      include Knife::WhiskBase
      banner "knife whisk list"
      def run
        server_list = get_config["servers"]
        server_list.each do |server|
          puts server.first
        end
      end
    end
    
    class WhiskShow < Chef::Knife
      include Knife::WhiskBase
      banner "knife whisk show TEMPLATENAME"
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
      banner "knife whisk generate TEMPLATENAME NODENAME"
      def run
        full_hash = get_config
        defaults = full_hash["mixins"]["defaults"]
        puts defaults["ami"]
      end
    end

  class WhiskHistory < Chef::Knife
    banner "knife whisk history"
  end
end
