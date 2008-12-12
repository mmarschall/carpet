require 'capistrano/recipes/deploy/remote_dependency'

module Capistrano
  module Deploy
    class RemoteDependency
      
      def user(username, options={})
        configuration.adm.useradd(username, options)
        @success = true
        self
      end
      
      def package(package, options={})
        unless configuration.pkg.installed?(package, options)
          configuration.pkg.refresh(options)
          configuration.pkg.install(package, options)
        end
        @success = true
        self
      end
      
      def service(service, options={})
        unless configuration.svc.online?(service, options)
          self.package(options.delete(:package), options)
          configuration.svc.import_cfg_for(service, options)
          configuration.svc.enable(service, options)
        end
        @success = true
        self
      end
      
      alias :check_for_directory :directory
      
      def directory(path, options={})
        configuration.set :dir, path
        chkdir_opts = options.dup
        chkdir_opts.merge!(:via => configuration.fetch(:run_method, :sudo)) unless options.include?(:via)
        configuration.adm.mkdir(path, options) unless configuration.adm.chkdir(path, chkdir_opts)
        @success = true
        self
      end
      
      def after_directory
        configuration.unset :dir
      end
      
      alias :check_for_file :file
      
      def file(path, content, options={})
        exists = check_for_file(path, options).pass?
        dir_opts = options.dup
        dir_opts.delete(:mode)
        dir_opts.delete(:owner)
        dir_opts.delete(:group)
        matches = match("cat #{path}", content, options).pass?
        unless exists && matches
          directory(File.dirname(path), dir_opts)
          configuration.load do
            pf_put(content, path, options) # TODO: make solaris independent (pf_put is a solaris only thing....)
          end 
        end
        @success = true
        self
      end
      
      alias :check_for_gem :gem
      
      def gem(name, version, options={})
        unless check_for_gem(name, version, options).pass?
          gem_opts = options.delete(:gem_opts)
          options.merge!(:via => configuration.fetch(:run_method, :sudo)) unless options.include?(:via)
          configuration.invoke_command("gem install #{name} --no-rdoc --no-ri --version #{version}#{' '+gem_opts unless gem_opts.nil?}", options)
        end
        @success = true
        self
      end
    end
  end
end