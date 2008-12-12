Capistrano::Configuration.instance(:must_exist).load do 
  task :apache_lb do
    assure :service, "network/http:apache22", :package => "SUNWapch22"
    assure :package, "SUNWapch22m-dtrace"

    assure :file, "/etc/apache2/2.2/conf.d/vhost.conf", render(vhost_conf_erb, {
      :hostname => capture("hostname").strip,
      :web_servers => roles[:web].servers,
      :app_servers => roles[:app].servers,
      :apache_log_dir => "/var/apache2/2.2/logs",
      :apache_auth_user_file => "/etc/apache2/2.2/htpasswd"
    }) if exists?(:vhost_conf_erb)
    svc.refresh("network/http:apache22")
    pfexec("/usr/sbin/logadm -w apache -C 7 -z 0 -a '/usr/sbin/svcadm restart apache22' -p 1d /var/apache2/2.2/logs/*.log")
  end
end