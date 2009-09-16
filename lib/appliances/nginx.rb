Capistrano::Configuration.instance(:must_exist).load do 
  task :nginx do
    assure(:package, 'SUNWpcre')

    assure :command, 'gcc' do
      gcc.install!
    end

    assure :command, :git do
      src.install("http://kernel.org/pub/software/scm/git/git-1.6.1.tar.gz")
    end
    known_hosts = <<-KH
github.com,65.74.177.129 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
    KH
    assure :file, "/export/home/#{application_user}/.ssh/known_hosts", known_hosts

    nginx_install_dir = get_attribute(:nginx_install_dir, "/opt/nginx")
    assure :match, "#{nginx_install_dir}/sbin/nginx -v", /0\.7\.62/ do
      src.install('http://sysoev.ru/nginx/nginx-0.7.62.tar.gz', :cc => 'gcc', :configure_opts => "--prefix=#{nginx_install_dir}")
    end

    assure(:file, "#{nginx_install_dir}/sbin/nginx.sh", "#!/usr/bin/env sh\nulimit -s 1048576\n#{nginx_install_dir}/sbin/nginx\n", :mode => 755)

    assure(:file, "#{nginx_install_dir}/conf/nginx.conf", render(nginx_conf_erb, {
      :haproxy_port => get_attribute(:haproxy_port, 8000),
      :application_directory => current_path,
      :deploy_env => deploy_env,
      :basic_auth => get_attribute(:basic_auth, false)   
    })) if exists?(:nginx_conf_erb)

    service_name = "nginx-#{application}-#{deploy_env}"
    assure(:file, "/var/svc/manifest/#{service_name}-smf.xml",
           render("nginx_smf.xml.erb",{
                      :service_name => service_name,
                      :installation_directory => nginx_install_dir
           })
    )
    svc.import_cfg_for("#{service_name}-smf")
    pfexec("/usr/sbin/logadm -w nginx -C 7 -z 0 -a '/usr/sbin/svcadm restart #{service_name}' -p 1d #{nginx_install_dir}/logs/*.log")
    svc.restart("network/#{service_name}")
  end
end
