Capistrano::Configuration.instance(:must_exist).load do
  task :haproxy do

    haproxy_dir = "/export/home/#{application_user}/haproxy"
    haproxy_cfg = <<-CFG
# nothing to see here
    CFG

    assure :directory, "#{haproxy_dir}", {:owner => application_user, :group => "staff", :mode => 755}

    assure :command, 'gcc' do
      gcc.install!
    end

    assure(:package, 'SUNWpcre')

    assure :command, "#{haproxy_dir}/haproxy" do
      src.install("http://haproxy.1wt.eu/download/1.3/src/haproxy-1.3.18.tar.gz",
        :install_cmd => "make TARGET=solaris CC=gcc CFLAGS=-I/usr/include/pcre USE_PCRE=1 && cp haproxy #{haproxy_dir}"
      )
    end

    assure(:file, "/var/svc/manifest/haproxy-smf.xml",
           render("haproxy_smf.xml.erb", {
               :service_name => "haproxy", :working_directory => haproxy_dir
           }),
           {:owner => application_user, :group => "staff", :mode => 775}
    )
    svc.import_cfg_for("haproxy-smf")


    assure :file, "#{haproxy_dir}/haproxy.cfg", render(haproxy_cfg_erb, {
      :port => get_attribute(:port, 80),
      :app_servers => roles[:app].servers,
      :working_directory => haproxy_dir
    })
    assure(:file, "#{haproxy_dir}/503.http", File.read(haproxy_503_http)) if exists?(:haproxy_503_http)
    svc.restart("network/haproxy-#{deploy_env}")
  end
end