require 'capistrano'

module Nfs
  def enable_client(options={})
    svc.enable("network/nfs/nlockmgr", options)
    svc.enable("network/nfs/status", options)
    svc.enable("network/nfs/client", options)
  end
  
  def mount(share, mountpoint, options={})
    unless mounted?(mountpoint, options)
      assure :directory, mountpoint
      pfexec("/usr/sbin/mount -F nfs #{share} #{mountpoint}", options)
      vfstab = capture("cat /etc/vfstab", options).strip
      vfstab << "\n#{share}\t-\t#{mountpoint}\tnfs\t-\tyes\t-\n" unless vfstab.include?(share)
      assure :file, "/etc/vfstab", vfstab
      enable_client(options)
    end
  end
  
  def mounted?(mountpoint, options={})
    capture("/usr/sbin/mount", options).include?(mountpoint)
  end
end

Capistrano.plugin :nfs, Nfs