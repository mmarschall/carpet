Capistrano::Configuration.instance(:must_exist).load do 
  task :a_zone do
    assure(:service, "system/rcap:default", :package => "SUNWrcap")
    zfs.create("rpool/zones", { :mountpoint => "/zones" })
    zone.create_configuration(zone_name, zone_options)
    zone.install(zone_name, zone_options)
    zone.configure_memory(zone_name, zone_options)
    zone.configure_net(zone_name, zone_options)
    zone.configure_autoboot(zone_name, true, zone_options)
    zone.set_quota(zone_name, zone_options[:disk], zone_options)
    zone.configure_system_id(zone_name, zone_options)
    if exists?(:sshd_config)
      assure(:file, "/etc/ssh/sshd_config", File.read(sshd_config), :via => :zlogin, :zone => zone_name)
      svc.restart("svc:/network/ssh:default", :via => :zlogin, :zone => zone_name)
    end
    assure(:package, "SUNWsudo", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:user, application_user, zone_options.merge({:sudoers => true, :profiles => "Primary Administrator", :via => :zlogin, :zone => zone_name, :uid => uid_for(application_user)}))
    assure(:file, "/export/home/#{application_user}/.profile", dot_profile, :via => :zlogin, :zone => zone_name) if exists?(:dot_profile)
    assure(:file, "/export/home/#{application_user}/.bashrc", dot_bashrc, :via => :zlogin, :zone => zone_name) if exists?(:dot_bashrc)
    assure(:file, "/export/home/#{application_user}/.bash_profile", ". ~/.profile\n. ~/.bashrc", :via => :zlogin, :zone => zone_name) if exists?(:dot_bashrc) && exists?(:dot_profile)
    assure(:package, "SUNWtop", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWcurl", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWloc", zone_options.merge({:via => :zlogin, :zone => zone_name})) # locale support
    assure(:package, "SUNWuiu8", zone_options.merge({:via => :zlogin, :zone => zone_name})) # iconv modules for UTF-8 locale (required by GLoc)
    assure(:package, "SUNWlang-enUS", zone_options.merge({:via => :zlogin, :zone => zone_name})) # en_US.UTF-8 locale
    assure(:package, "SUNWlang-deDE", zone_options.merge({:via => :zlogin, :zone => zone_name})) # de_DE.UTF-8 locale
    assure(:package, "SUNWless", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWman", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWwget", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWgnu-coreutils", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWgnu-gettext", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure :package, "SUNWlxml"
    assure :package, "SUNWgnu-libiconv"
    adm.ln("/usr/gnu/lib/libiconv.so.2", "/usr/lib/libiconv.so.2") # needed as /usr/gnu/lib is not in libary load path
    assure :package, "SUNWzlib"
    assure(:package, "SUNWgmake", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWgtar", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWggrp", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWbtool", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWperl584core", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWperl584usr", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:package, "SUNWperl584man", zone_options.merge({:via => :zlogin, :zone => zone_name}))
    assure(:file, "/export/home/#{application_user}/.ssh/known_hosts", get_attribute(:known_hosts,""))
  end
end

def uid_for(username)
  capture("id -u #{username}").strip!
end