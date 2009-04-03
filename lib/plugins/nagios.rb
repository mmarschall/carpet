require 'capistrano'

module Nagios
  def install_plugins(options={})
    cmd = "export CFLAGS=-m64; export LDFLAGS='-Xlinker -64 -L/usr/sfw/lib/amd64 -R/usr/sfw/lib/amd64'; ./configure --prefix=/usr/local/nagios && make && sudo make install"
    src.install("http://switch.dl.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.13.tar.gz", options.merge(:install_cmd => cmd))
  end
  
  def add_host(host, ipaddress)
    host_cfg = <<-CFG
define host{
  use generic-host
  host_name #{host}
  address #{ipaddress}
  check_command check-host-alive
  max_check_attempts 10
  notification_interval 30
  notification_period 24x7
  notification_options d,r
  contact_groups admins
} 
    CFG
    put(host_cfg, "#{nagios_objects_dir}/#{host}.cfg",:hosts => nagios_server)
  end
  
  def add_hostgroup(hostgroup, members)
    hostgroup_cfg = <<-CFG
define hostgroup{
  hostgroup_name #{hostgroup}
  members #{members}
}
    CFG
    put(hostgroup_cfg, "#{nagios_objects_dir}/#{hostgroup}.cfg", :hosts => nagios_server)
  end
  
  def add_service(service, hostgroup, service_details)
    check_command_params = ""
    check_command_params << "!#{service_details[:warn]}" if service_details[:warn]
    check_command_params << "!#{service_details[:critical]}" if service_details[:critical]
    check_command_params << "!#{service_details[:additional_params]}" if service_details[:additional_params]
    service_cfg = <<-CFG
define service{
  hostgroup_name #{hostgroup}
  service_description #{service_details[:description]||service}
  check_command check_#{service_details[:via] ? "by_ssh_" : ""}#{service}#{check_command_params}
  use generic-service
  notification_interval 0 ;
}
    CFG
    put(service_cfg, "#{nagios_objects_dir}/#{service}_on_#{hostgroup}.cfg", :hosts => nagios_server)
  end
  
  def restart!
    sudo("/etc/init.d/nagios restart", :hosts => nagios_server)
  end
end
Capistrano.plugin :nagios, Nagios
