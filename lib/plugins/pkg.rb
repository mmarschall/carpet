require 'capistrano'

module Pkg
  def refresh(options={})
    invoke_command("pfexec /usr/bin/pkg refresh", options)
  end
  
  def install(package, options={})
    invoke_command("pfexec /usr/bin/pkg install #{package}", options)
  end
  
  def installed?(package, options={})
    invoke_command("/usr/bin/pkg list #{package}", options)
    true
  rescue Capistrano::CommandError => e
    false
  end
  
  def set_authority(name, url, options={})
    pfexec("/usr/bin/pkg set-authority -O #{url} #{name}", options)
  end
  
  def add_sunfreeware(options={})
    set_authority("sunfreeware.com", "http://pkg.sunfreeware.com:9000/", options)
  end
  
  def authority?(name, options={})
    capture("pfexec /usr/bin/pkg authority", options).split.include?(name)
  end
end

Capistrano.plugin :pkg, Pkg