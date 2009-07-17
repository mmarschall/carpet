Capistrano::Configuration.instance(:must_exist).load do 
  task :passenger_nginx_server do
    rails_default_permissions = {:owner => application_user, :group => "staff", :mode => 775}

    assure :command, 'gcc' do
      gcc.install!
    end

    assure :directory, "#{shared_path}", {:owner => application_user, :group => "staff", :mode => 755}
    assure :directory, "#{shared_path}/log", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/config/environments", fetch(:default_permissions, rails_default_permissions)
    assure :directory, "#{shared_path}/tmp", fetch(:default_permissions, rails_default_permissions)

    assure :match, "ruby --version", /ruby 1\.8\.7 \(2008-08-11 patchlevel 72\)/ do
      pkg.set_authority("pending", "http://pkg.opensolaris.org/pending/") unless pkg.authority?("pending")
      assure :package, "readline5"
      src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz", :cc => 'gcc')
    end

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
    assure :gem, "net-scp", "1.0.1"
    assure :gem, "libxml-ruby", "0.9.7"
    assure :gem, "rspec", "1.2.2"
    assure :gem, "rspec-rails", "1.2.2"
    assure :gem, "cucumber", "0.1.15"
    assure :gem, "passenger", "2.2.4"

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

    app_server_install_directory = get_attribute(:app_server_install_directory, "/export/home/#{application_user}/nginx-passenger")

    # install passenger + nginx combo
    assure(:command, "#{app_server_install_directory}/sbin/nginx") do
      # get latest stable nginx version (passenger downloads 0.6.x)
      nginx_version = 'nginx-0.7.61'
      invoke_command("test -f #{nginx_version}.tar.gz || wget --progress=dot:mega -N http://sysoev.ru/nginx/#{nginx_version}.tar.gz")
      invoke_command("/usr/gnu/bin/tar xzf #{nginx_version}.tar.gz")

      # install passenger using just downloaded nginx sources
      pfexec("/usr/local/lib/ruby/gems/1.8/gems/passenger-2.2.4/bin/passenger-install-nginx-module --auto --prefix=#{app_server_install_directory} --nginx-source-dir=/export/home/#{application_user}/#{nginx_version} --extra-configure-flags=none")
      adm.chown(app_server_install_directory, :owner => application_user)
      adm.chgrp(app_server_install_directory, :group => 'staff')

      # remove nginx sources
      pfexec("rm #{nginx_version}.tar.gz")
      pfexec("rm -rf #{nginx_version}")
    end
    assure(:file, "#{app_server_install_directory}/conf/nginx.conf", render(nginx_conf_erb, {
      :app_server_port => get_attribute(:app_server_port, 80),
      :app_server_pool_size => get_attribute(:app_server_pool_size, 4),
      :app_server_name => get_attribute(:app_server_name, 'localhost'),
      :application_directory => current_path,
      :deploy_env => deploy_env   
    }), rails_default_permissions) if exists?(:nginx_conf_erb)

    assure(:file, "/var/svc/manifest/#{application}-nginx-smf.xml",
           render("nginx_smf.xml.erb",
                  {
                      :application => application,
                      :installation_directory => app_server_install_directory
                  }
           ), rails_default_permissions
    )
    svc.import_cfg_for("#{application}-nginx-smf")

    pfexec("/usr/sbin/logadm -w nginx -C 7 -z 0 -a '/usr/sbin/svcadm restart #{application}-nginx-#{deploy_env}' -p 1d #{app_server_install_directory}/logs/*.log")
    pfexec("/usr/sbin/logadm -w application -C 7 -z 0 -p 1d #{shared_path}/log/*.log")

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
