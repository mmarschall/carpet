Capistrano::Configuration.instance(:must_exist).load do 
  task :memcache do
    size = current_node.options[:memcached_size] || fetch(:memcached_size, "1024")
    port = fetch(:memcached_port, "11211")
    user = fetch(:memcached_user, "nobody")
    
    assure :package, "SUNWmemcached"
    svc.setprop("svc:/application/database/memcached", "memcached/options", "'(\"-u\" \"#{user}\" \"-m\" \"#{size}\" \"-p\" \"#{port}\")'")
    svc.refresh("svc:/application/database/memcached")
    svc.enable("svc:/application/database/memcached")
  end
end