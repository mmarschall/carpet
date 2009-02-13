require 'capistrano'

module Zone
  def exists?(name, options={})
      pfexec("/usr/sbin/zoneadm -z #{name} list", options)
      true
    rescue Capistrano::CommandError => e
      false
  end
  
  def start(name, options={})
    pfexec("/usr/sbin/zoneadm -z #{name} boot", options)
  end
  
  def restart(name, options={})
    pfexec("/usr/sbin/zoneadm -z #{name} reboot", options)
  end
  
  def stop(name, options={})
    pfexec("/usr/sbin/zlogin #{name} halt", options) if state(name, options) == "running"
  end
  
  def state(name, options={})
    capture("/usr/sbin/zoneadm -z #{name} list -p | cut -d':' -f 3", options).strip!
  end
  
  def clone(zone, from, options={})
    if state(zone, options) == "configured"
      unless zfs.exists?("rpool/zones/#{zone}", options)
        pfexec("/usr/sbin/zoneadm -z #{zone} clone #{from}", options) 
        zfs.set_property("rpool/zones/#{zone}", "atime", "off", options)
      else
        pfexec("/usr/sbin/zoneadm -z #{zone} attach", options)
      end
    end
  end

  def configure_memory(name, options={})
    mem = options.delete(:mem) || "512M"
    swap = options.delete(:swap) || "512M"
    mem.upcase!
    swap.upcase!
    cfg = capture("/usr/sbin/zonecfg -z #{name} info capped-memory", options)
    if cfg.empty?
      pfexec("/usr/sbin/zonecfg -z #{name} \"add capped-memory; set physical=#{mem}; set swap=#{swap}; end\"", options)
    else
      unless (cfg.include?("physical: #{mem}") && cfg.include?("swap: #{swap}"))
        current_physical = cfg.split(" ")[2]
        pfexec("/usr/sbin/zonecfg -z #{name} \"select capped-memory physical=#{current_physical}; set physical=#{mem}; set swap=#{swap}; end\"", options)
      end
    end
  end

  def configure_net(name, options={})
    ipaddresses = options.delete(:ipaddress).to_a
    interface = options.delete(:interface)
    cfg = capture("/usr/sbin/zonecfg -z #{name} info net", options)
    pfexec("/usr/sbin/zonecfg -z #{name} remove -F net") unless cfg.empty?
    ipaddresses.each do |ipaddress|
      pfexec("/usr/sbin/zonecfg -z #{name} \"add net; set physical=#{interface}; set address=#{ipaddress}; end\"", options)
    end
  end

  def configure_autoboot(name, value, options={})
    pfexec("/usr/sbin/zonecfg -z #{name} \"set autoboot=#{value}\"", options)
  end

  def set_quota(name, value="20G", options={})
    zfs.set_property("rpool/zones/#{name}", "quota", value, options)
  end
  
  def install(name, options={})
    pfexec("/usr/sbin/zoneadm -z #{name} install", options) if state(name, options) == "configured"
  end
  
  def create_configuration(name, options={})
    pfexec("/usr/sbin/zonecfg -z #{name} \"create; set zonepath=/zones/#{name}\"", options) unless exists?(name, options)
  end
  
  def delete_configuration(name, options={})
    pfexec("/usr/sbin/zonecfg -z #{name} delete -F", options)
  end
  
  def configure_system_id(name, options={})
    domain = options[:domain] || fetch(:default_domain, "")
    name_server = options[:name_server] || fetch(:default_name_server, "")
    name_server_list = (name_server.join(",") if !name_server.nil? && name_server.respond_to?(:join)) || name_server
    sysidcfg = <<-CFG
network_interface=NONE {
  hostname=#{name}
  protocol_ipv6=no
}
system_locale=C
terminal=xterms
security_policy=NONE
name_service=DNS {
  domain_name=#{domain}
  name_server=#{name_server_list}
}
timezone=#{timezone}
root_password=#{root_password_hash}
nfs4_domain=dynamic
    CFG
    start(name, options)
    if sysidcfg_changed?(name, sysidcfg, options)
      assure(:file, "/zones/#{name}/root/etc/sysidcfg", sysidcfg, options)
      throw Exception.new("zone #{name} needs to be restarted for sysidcfg changes to take effect!")
    end
    svc.wait_for("network/ssh", options.merge({:via => :zlogin, :zone => name, :timeout => 120}))
    resolv_conf = "domain #{domain}\n"
    name_server.each do |ns|
      resolv_conf << "nameserver #{ns}\n"
    end
    assure(:file, "/zones/#{name}/root/etc/resolv.conf", resolv_conf, options)
    pfexec("cp /zones/#{name}/root/etc/nsswitch.dns /zones/#{name}/root/etc/nsswitch.conf", options)
    svc.enable("network/dns/client", options.merge({:via => :zlogin, :zone => name}))
  end
  
  def sysidcfg_changed?(name, sysidcfg, options={})
    dep = Capistrano::Deploy::RemoteDependency.new(self)
    !dep.match("pfexec cat /zones/#{name}/root/etc/sysidcfg", sysidcfg, options).pass?
  end
end

Capistrano.plugin :zone, Zone