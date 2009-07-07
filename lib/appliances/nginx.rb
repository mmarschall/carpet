Capistrano::Configuration.instance(:must_exist).load do 
  task :nginx do
    assure :command, 'gcc' do
      gcc.install!
    end

    assure :command, :git do
      src.install("http://kernel.org/pub/software/scm/git/git-1.6.1.tar.gz")
    end

    nginx_install_dir = get_attribute(:nginx_install_dir, "/opt/nginx")

    # install passenger + nginx combo
    assure(:command, "#{nginx_install_dir}/sbin/nginx") do
      src.install('http://sysoev.ru/nginx/nginx-0.7.61.tar.gz', :cc => 'gcc', :configure_opts => "--prefix=#{nginx_install_dir}")
    end

    assure(:file, "#{nginx_install_dir}/conf/nginx.conf", render(nginx_conf_erb, {
      :server_name => get_attribute(:server_name, '*'),  
      :haproxy_port => get_attribute(:haproxy_port, 8000),
      :application_directory => current_path,
      :deploy_env => deploy_env   
    })) if exists?(:nginx_conf_erb)

    assure(:file, "/var/svc/manifest/#{application}-nginx-smf.xml",
           render("nginx_smf.xml.erb",
                  {
                      :application => application,
                      :installation_directory => nginx_install_dir
                  }
           )
    )
    svc.import_cfg_for("#{application}-nginx-smf")

    pfexec("/usr/sbin/logadm -w nginx -C 7 -z 0 -a '/usr/sbin/svcadm restart #{application}-nginx-#{deploy_env}' -p 1d #{nginx_install_dir}/logs/*.log")
  end
end
