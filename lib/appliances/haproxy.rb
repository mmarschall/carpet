Capistrano::Configuration.instance(:must_exist).load do
  task :haproxy do
    haproxy_dir = get_attribute(:haproxy_dir, "/opt/haproxy")

    assure(:directory, "#{haproxy_dir}")

    assure :command, 'gcc' do
      gcc.install!
    end

    assure(:package, 'SUNWpcre')

    assure :command, "#{haproxy_dir}/haproxy" do
      src.install("http://haproxy.1wt.eu/download/1.3/src/haproxy-1.3.18.tar.gz",
        :install_cmd => "make TARGET=solaris CC=gcc CFLAGS=-I/usr/include/pcre USE_PCRE=1 && cp haproxy #{haproxy_dir}"
      )
    end

    assure :file, "#{haproxy_dir}/haproxy.cfg", render(haproxy_cfg_erb, {
      :port => get_attribute(:port, 8000),
      :app_servers => roles[:app].servers,
      :working_directory => haproxy_dir,
      :deploy_env => deploy_env
    })
    assure(:file, "#{haproxy_dir}/503.http", File.read(haproxy_503_http)) if exists?(:haproxy_503_http)

    service_name = "haproxy-#{application}-#{deploy_env}"
    assure(:file, "/var/svc/manifest/#{service_name}-smf.xml",
           render("haproxy_smf.xml.erb", {
               :service_name => service_name, :working_directory => haproxy_dir
           })
    )
    svc.import_cfg_for("#{service_name}-smf")
    svc.restart("network/#{service_name}}")
  end
end