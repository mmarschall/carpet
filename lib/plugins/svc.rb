require 'capistrano'

module Svc
  def online?(svc, options={})
    capture("/usr/bin/svcs #{svc}", options).split(" ")[3] == "online"
  rescue
    false
  end
  
  def wait_for(svc, options={})
    timeout = options.delete(:timeout) || 90
    interval = 5
    max_count = timeout / interval
    ready = false
    count = 0
    logger.info("waiting for service: '#{svc}'#{options[:zone].nil? ? "" : " on #{options[:zone]}"} to get online (Timeout: #{timeout}s)")
    while !ready && count < max_count
      begin
        ready = online?(svc, options)
      rescue Capistrano::CommandError
      end
        break if ready
        sleep(interval)
        count += 1
        logger.important("waiting since #{count * interval}s")
    end
    if count >= max_count && !ready
      raise Capistrano::CommandError.new("timeout after #{timeout}s while waiting for service: '#{svc}' on #{options[:zone]} to get online")
    end
  end
  
  def enable(svc, options={})
    svc = "svc:/" + svc unless svc.match(/^svc:\/.*/)
    pfexec("/usr/sbin/svcadm enable #{svc}", options)
  end
  
  def setprop(svc, prop, value, options={})
    svc = "svc:/" + svc unless svc.match(/^svc:\/.*/)
    pfexec("/usr/sbin/svccfg -s #{svc} setprop #{prop} = #{value}", options)
  end
  
  def import_cfg_for(svc, options={})
    service_name = svc.split(":")[0]
    service_instance = svc.split(":")[1]
    cfg_file_name = service_name
    cfg_file_name << "-#{service_instance}" unless service_instance == "default" || service_instance.nil?
    cfg = "/var/svc/manifest/#{cfg_file_name}.xml"
    pfexec("/usr/sbin/svccfg import #{cfg}", options)
  end
  
  def refresh(svc, options={})
    pfexec("/usr/sbin/svcadm refresh #{svc}", options)
  end

  def restart(svc, options={})
    pfexec("/usr/sbin/svcadm restart #{svc}", options)
  end
end

Capistrano.plugin :svc, Svc
