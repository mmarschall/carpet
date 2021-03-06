Capistrano::Configuration.instance(:must_exist).load do 
  task :mongrel_cluster do
    rails_default_permissions = {:owner => application_user, :group => "staff", :mode => 775}
    assure :directory, "#{shared_path}", {:owner => application_user, :group => "staff", :mode => 755}
    assure :directory, "#{shared_path}/log", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config/environments", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/tmp", fetch(:default_permissions, rails_default_permissions)
    assure :command, :git do
      src.install("http://kernel.org/pub/software/scm/git/git-1.6.1.tar.gz")
    end
    known_hosts = <<-KH
github.com,65.74.177.129 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
    KH
    assure :file, "/export/home/#{application_user}/.ssh/known_hosts", known_hosts
    assure :match, "gem --version", "1.3.1" do
      src.install("http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz", :install_cmd => "pfexec ruby ./setup.rb")
    end
    assure :package, "SUNWimagick"
    assure :package, "SUNWmysql5"
    assure :package, "SUNWsvn"
    
    assure :gem, "hoe", ">= 1.8.2"
    assure :gem, "mini_magick", "1.2.3"
    assure :gem, "rubyzip", "0.9.1"
    assure :gem, "rack", "0.9.1"
    assure :gem, "rails", "2.3.2"
    assure :gem, "memcache-client", "1.5.0"
    assure :gem, "mysql", "2.7", :gem_opts => "-- --with-mysql-dir=/usr/mysql"
    assure :gem, "mongrel", "1.1.5"
    assure :gem, "mongrel_cluster", "1.0.5"
    assure :gem, "net-scp", "1.0.1"
    assure :gem, "libxml-ruby", "0.9.7"
    assure :gem, "rspec", "1.2.2"
    assure :gem, "rspec-rails", "1.2.2"
    assure :gem, "cucumber", "0.3.11"

    custom_gems = get_attribute(:gems, {})
    custom_gems.each do |gem, version|
      assure(:gem, gem, version)
    end

    custom_application_directories = get_attribute(:custom_application_directories, {})
    custom_application_directories.each do |dir, permissions|
      assure(:directory, dir, permissions)
    end
    
    if current_node.options[:primary]
      crontab = ""
      get_attribute(:scheduled_rake_tasks, {}).each do |task, timing|
        crontab << schedule_rake_task(task, timing)
      end
      assure(:file, "/export/home/#{application_user}/custom_crontab", crontab)
      run("/usr/bin/crontab custom_crontab; rm custom_crontab")
    end

    mongrel_start_port = get_attribute(:mongrel_start_port, 8000)
    mongrel_servers = get_attribute(:mongrel_servers, 4)
    mongrel_mem_warning = get_attribute(:mongrel_mem_warning, 300000)
    mongrel_mem_critical = get_attribute(:mongrel_mem_critical, 350000)
    assure(:file, "#{shared_path}/config/mongrel_cluster.yml", render("mongrel_cluster.yml.erb", { :port => mongrel_start_port, :servers => mongrel_servers}), rails_default_permissions)
    if fetch(:nagios_server, nil) && current_node.options[:nagios_services]
      mongrel_servers.to_i.times do |i|
        port = mongrel_start_port.to_i + i
        nagios.add_service("proc_mem_#{port}", current_node.options[:name], {:check => :proc_mem, :via => :ssh, :warn => mongrel_mem_warning, :critical => mongrel_mem_critical, :description => "MEM mongrel #{port}", :additional_params => "mongrel.*#{port}"})
      end
    end
    
    assure(:file, "/var/svc/manifest/#{application}-smf.xml", render("mongrel_smf.xml.erb", { :service_name => application, :working_directory => current_path}), rails_default_permissions)
    svc.import_cfg_for("#{application}-smf")
    pfexec("/usr/sbin/logadm -w application -C 7 -z 0 -a '/usr/sbin/svcadm restart #{application}-#{deploy_env}' -p 1d #{shared_path}/log/*.log")

    assure(:file, "#{shared_path}/config/database.yml", render("database.yml.erb", {
      :db_host => get_attribute(:db_host, find_node_by_param(:mysql_master, true).host)
    }), rails_default_permissions)

    upload_environment_config
  end

  def upload_environment_config
    template = get_attribute(:environment_config_template, "#{deploy_env}.rb.erb")
    params = get_attribute(:environment_config_params, {}).merge(:memcached_address => "#{current_node.options[:memcached_address]}:11211")
    assure(:file, "#{shared_path}/config/environments/#{deploy_env}.rb", render(template, params), fetch(:default_permissions))
  end
end
