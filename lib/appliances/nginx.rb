Capistrano::Configuration.instance(:must_exist).load do 
  task :nginx do
    assure :command, 'gcc' do
      gcc.install!
    end

    assure :command, :git do
      src.install("http://kernel.org/pub/software/scm/git/git-1.6.1.tar.gz")
    end

    nginx_install_dir = get_attribute(:nginx_install_dir, "/opt/nginx")
    assure(:command, "#{nginx_install_dir}/sbin/nginx") do
      src.install('http://sysoev.ru/nginx/nginx-0.7.61.tar.gz', :cc => 'gcc', :configure_opts => "--prefix=#{nginx_install_dir}")
    end

    assure(:file, "#{nginx_install_dir}/conf/nginx.conf", render(nginx_conf_erb, {
      :server_name => get_attribute(:server_name, '*'),  
      :haproxy_port => get_attribute(:haproxy_port, 8000),
      :application_directory => current_path,
      :deploy_env => deploy_env   
    })) if exists?(:nginx_conf_erb)

    service_name = "nginx-#{application}-#{deploy_env}"
    assure(:file, "/var/svc/manifest/#{service_name}-smf.xml",
           render("nginx_smf.xml.erb",{
                      :service_name => service_name,
                      :installation_directory => nginx_install_dir
           })
    )
    svc.import_cfg_for("#{service_name}-smf")
    svc.restart("network/#{service_name}}")
    
    pfexec("/usr/sbin/logadm -w nginx -C 7 -z 0 -a '/usr/sbin/svcadm restart #{service_name}' -p 1d #{nginx_install_dir}/logs/*.log")
  end
end
