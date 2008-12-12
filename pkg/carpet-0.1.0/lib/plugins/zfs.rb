require 'capistrano'

module Zfs
  def exists?(fs, options={})
    run("/usr/sbin/zfs list -t snapshot,filesystem,volume #{fs}", options)
    true
  rescue
    false
  end
  
  def create(fs, properties=nil, options={})
    pfexec("/usr/sbin/zfs create #{fs}", options) unless exists?(fs, options)
    set_properties(fs, properties, options) unless properties.nil?
  end
  
  def destroy(fs, options={})
    pfexec("/usr/sbin/zfs destroy -rf #{fs}", options)
  end
  
  def set_properties(fs, properties, options={})
    properties.each do |prop, value|
      set_property(fs, prop, value, options)
    end
  end
  
  def set_property(fs, prop, value, options={})
    pfexec("/usr/sbin/zfs set #{prop}=#{value} #{fs}", options) unless capture("/usr/sbin/zfs list -o #{prop} #{fs}").split("\n")[1] == value
  end
  
  def property(fs, prop, options={})
    capture("/usr/sbin/zfs get #{prop} #{fs}", options).split(" ")[6]
  end
  
  def share(fs, options={})
    set_property(fs, "sharenfs", "on", options)
  end
end

Capistrano.plugin :zfs, Zfs