require File.dirname(__FILE__) + '/../spec_helper'

describe "apache loadbalancer appliance recipe" do
  
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @config.stub!(:put)
    @config.stub!(:assure)
    @config.stub!(:needs)
    @config.stub!(:exists?).with(:vhost_conf_erb).and_return(true)
    @config.stub!(:vhost_conf_erb).and_return("recipes/appliances/vhost.conf.erb")
    File.stub!(:read).and_return("")
    @svc = @config.svc
  end
  
  it "should assure the apache service" do
    @config.should_receive(:assure).with(:service, "network/http:apache22", :package => "SUNWapch22")
    @config.load do
      apache_lb
    end
  end
  
  it "should install the apache dtrace extensions" do
    @config.should_receive(:assure).with(:package, "SUNWapch22m-dtrace")
    @config.load do
      apache_lb
    end
  end
  
  it "should render the vhost configuration template" do
    @config.stub!(:capture).with("hostname").and_return("web1")
    @config.stub!(:current_path).and_return("/current")
    web_role = mock(Capistrano::Role)
    web_role.stub!(:servers).and_return(["10.20.2.159"])
    app_role = mock(Capistrano::Role)
    app_role.stub!(:servers).and_return(["10.20.2.250"])
    @config.stub!(:roles).and_return({:web => web_role, :app => app_role})
    options = {
        :hostname => "web1",
        :web_servers => ["10.20.2.159"],
        :app_servers => ["10.20.2.250"],
        :apache_log_dir => "/var/apache2/2.2/logs",
        :apache_auth_user_file => "/etc/apache2/2.2/htpasswd"
    }
    @config.should_receive(:render).with("recipes/appliances/vhost.conf.erb", options)
    @config.load do
      apache_lb
    end
  end
  
  it "should upload the vhost config file" do
    @config.stub!(:render).and_return("blah")
    @config.should_receive(:assure).with(:file, "/etc/apache2/2.2/conf.d/vhost.conf", "blah")
    @config.load do
      apache_lb
    end
  end
  
  it "should make sure apache refreshes it's config" do
    @svc.should_receive(:refresh).with("network/http:apache22")
    @config.load do
      apache_lb
    end
  end

  it "should ask logadm to rotate the apache log files daily and compress 'em" do
    @config.should_receive(:pfexec).with("/usr/sbin/logadm -w apache -C 7 -z 0 -a '/usr/sbin/svcadm restart apache22' -p 1d /var/apache2/2.2/logs/*.log")
    @config.load do
      apache_lb
    end
  end
end
