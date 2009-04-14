Capistrano::Configuration.instance(:must_exist).load do 
  task :memcache do
    size = get_attribute(:memcached_size, "1024")
    port = get_attribute(:memcached_port, "11211")
    user = get_attribute(:memcached_user, "nobody")
    
    assure :package, "SUNWmemcached"
    svc.setprop("svc:/application/database/memcached", "memcached/options", "'(\"-u\" \"#{user}\" \"-m\" \"#{size}\" \"-p\" \"#{port}\")'")
    svc.refresh("svc:/application/database/memcached")
    svc.enable("svc:/application/database/memcached")
  end
end