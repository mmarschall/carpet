Capistrano::Configuration.instance(:must_exist).load do 
  task :memcached do
    assure :package, "SUNWmemcached"
    svc.setprop("svc:/application/database/memcached", "memcached/options", "'(\"-u\" \"nobody\" \"-m\" \"#{fetch(:memcached_size, "1024")}\" \"-p\" \"#{fetch(:memcached_port, "11211")}\")'")
    svc.refresh("svc:/application/database/memcached")
    svc.enable("svc:/application/database/memcached")
  end
end