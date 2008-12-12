require File.dirname(__FILE__) + '/../spec_helper'


describe "Zone plugin (with stubbed wait_for_ssh_ready method)" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @config.stub!(:put)
    @zone = @config.zone
    @pkg = @config.pkg
    @zfs = @config.zfs
    @zfs.stub!(:create)
    @zone.stub!(:pfexec)
    @svc = @config.svc
    @svc.stub!(:wait_for)
    @zone.stub!(:assure)
  end
  
  describe "- install method" do
    it "should install a configured zone" do
      @zone.stub!(:state).and_return("configured")
      @zone.should_receive(:pfexec).with("/usr/sbin/zoneadm -z master install", {})
      @zone.install("master")
    end
    
    it "should not try to attempt to install a zone, if the state is installed" do
      @zone.stub!(:state).and_return("installed")
      @zone.should_not_receive(:pfexec).with("/usr/sbin/zoneadm -z master install", {})
      @zone.install("master")
    end
  end

  describe "- clone method" do
    it "should clone the master if the zone is configured but not installed and the zfs fs is not existing" do
      @zone.stub!(:state).and_return("configured")
      @zfs.stub!(:exists?).and_return(false)
      @zone.should_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 clone master", {})
      @zone.clone("web1", "master")
    end
    
    it "should attach an existing filesystem instead of cloning" do
      @zone.stub!(:state).and_return("configured")
      @zfs.stub!(:exists?).and_return(true)
      @zone.should_not_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 clone master", {})
      @zone.should_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 attach", {})
      @zone.clone("web1", "master")
    end
    
    it "should not attempt to clone the master if zone is already installed" do
      @zone.should_receive(:state).with("web1", {}).and_return("installed")
      @zone.should_not_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 clone master", {})
      @zone.clone("web1", "master")
    end
    
    it "should disable atime for the cloned zones filesystem" do
      @zone.stub!(:state).and_return("configured")
      @zfs.stub!(:exists?).and_return(false)
      @zfs.should_receive(:set_property).with("rpool/zones/web1", "atime", "off", {})
      @zone.clone("web1", "master")
    end
  end
  
  describe "- configure zone methods" do
    it "should be possible, to configure the zone's memory" do
      @zone.should_receive(:capture).with("/usr/sbin/zonecfg -z web1 info capped-memory", {}).and_return("")
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"add capped-memory; set physical=512M; set swap=512M; end\"", {})
      @zone.configure_memory("web1", {:mem => "512m", :swap => "512m"})
    end
    
    it "should be able to deal with upper or lower case letters in mem and swap" do
      @zone.should_receive(:capture).with("/usr/sbin/zonecfg -z web1 info capped-memory", {}).and_return("")
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"add capped-memory; set physical=512M; set swap=512M; end\"", {})
      @zone.configure_memory("web1", {:mem => "512m", :swap => "512M"})
    end
    
    it "should use default values, if I do not pass :mem and :swap to configure_memory" do
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"add capped-memory; set physical=512M; set swap=512M; end\"", {})
      @zone.configure_memory("web1", {})
    end
    
    it "should be possible to change a zone's memory config" do
      mem_info = <<-MEM
capped-memory:
	physical: 512M
	[swap: 512M]
      MEM
      @zone.should_receive(:capture).with("/usr/sbin/zonecfg -z web1 info capped-memory", {}).and_return(mem_info)
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"select capped-memory physical=512M; set physical=768M; set swap=768M; end\"", {})
      @zone.configure_memory("web1", {:mem => "768M", :swap => "768M"})
    end

    it "should not attempt to change a zone's memory config, if it is already as it should be" do
      mem_info = <<-MEM
capped-memory:
	physical: 512M
	[swap: 512M]
      MEM
      @zone.should_receive(:capture).with("/usr/sbin/zonecfg -z web1 info capped-memory", {}).and_return(mem_info)
      @zone.should_not_receive(:pfexec)
      @zone.configure_memory("web1", {:mem => "512M", :swap => "512M"})
    end
    
    it "should be possible, to configure the zone's network settings" do
      @zone.should_receive(:capture).any_number_of_times.with("/usr/sbin/zonecfg -z web1 info net", {}).and_return("")
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"add net; set physical=e1000g0; set address=10.20.2.230; end\"", {})
      @zone.configure_net("web1", {:ipaddress => "10.20.2.230", :interface => "e1000g0"})
    end
    
    it "should be possible to change a zones net setting" do
      net_info = <<-NET
net:
	address: 10.0.0.230
	physical: e1000g0
	defrouter not specified
      NET
      @zone.should_receive(:capture).any_number_of_times.with("/usr/sbin/zonecfg -z web1 info net", {}).and_return(net_info)
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"select net physical=e1000g0; set physical=bnx0; set address=10.20.2.100; end\"", {})
      @zone.configure_net("web1", {:ipaddress => "10.20.2.100", :interface => "bnx0"})
    end
    
    it "should not attempt to change the zones net setting, if it is already as given" do
      net_info = <<-NET
net:
	address: 10.0.0.230
	physical: e1000g0
	defrouter not specified
      NET
      @zone.should_receive(:capture).any_number_of_times.with("/usr/sbin/zonecfg -z web1 info net", {}).and_return(net_info)
      @zone.should_not_receive(:pfexec)
      @zone.configure_net("web1", {:ipaddress => "10.0.0.230", :interface => "e1000g0"})
    end
    
    it "should be possible, to configure the zone's autoboot option" do
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"set autoboot=true\"", {})
      @zone.configure_autoboot("web1", true)
    end
    
    it "should be possible, to configure the zone's disk quota" do
      @zfs = @config.zfs
      @zfs.should_receive(:set_property).with("rpool/zones/web1", "quota", "20G", {})
      @zone.set_quota("web1", :disk => "20G")
    end
  end
  
  describe "- create_configuration method" do
    it "should create a configuration, if zone does not exist" do
      @zone.should_receive(:exists?).and_return(false)
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"create; set zonepath=/zones/web1\"", {})
      @zone.create_configuration("web1")
    end
    
    it "should not attempt to create a new config, if zone already exists" do
      @zone.should_receive(:exists?).and_return(true)
      @zone.should_not_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 \"create; set zonepath=/zones/web1\"", {})
      @zone.create_configuration("web1")
    end
  end
  
  describe "- delete_configuration method" do
    it "should delete a configuration" do
      @zone.should_receive(:pfexec).with("/usr/sbin/zonecfg -z web1 delete -F", {})
      @zone.delete_configuration("web1")
    end
  end
  
  describe "- sysidcfg_changed? method" do
    before do
      @dep = Capistrano::Deploy::RemoteDependency.new(@zone)
      Capistrano::Deploy::RemoteDependency.stub!(:new).and_return(@dep)
      @dep.stub!(:match).and_return(@dep)
    end
    
    it "should return true, if sysidcfg has changed" do
      @dep.should_receive(:pass?).and_return(false)
      @zone.sysidcfg_changed?("web1", "bla").should be(true)
    end
    
    it "should return false if sysidcfg is the same" do
      @dep.stub!(:pass).and_return(true)
      @zone.sysidcfg_changed?("web1", "bla").should be(false)
    end
  end
  
  describe "- configure_system_id method" do
    before do
      @zone.stub!(:sysidcfg_changed?).and_return(true)
      @zone.stub!(:root_password_hash).and_return("ASDF§$%")
      @zone.stub!(:timezone).and_return("Europe/Berlin")
    end
    
    it "should start the zone before attempting to put the sysidcfg file into the zone's root dir, as only booting the zone will mount it (since snv_99)" do
      @zone.should_receive(:start).with("web1", {})
      @zone.configure_system_id("web1")
    end
  
    it "should restart the zone after putting the sysidcfg file into the zone's root dir" do
      @zone.should_receive(:restart).with("web1", {})
      @zone.configure_system_id("web1")
    end
    
    it "should not attempt to restart the zone, if sysidcfg was not changed" do
      @zone.stub!(:sysidcfg_changed?).and_return(false)
      @zone.should_not_receive(:restart).with("web1", {})
      @zone.configure_system_id("web1")
    end
    
    it "should upload a given sysidcfg file to the zone's /etc directory" do
      @zone.stub!(:assure)
      # see: http://docs.sun.com/app/docs/doc/817-5504/6mkv4nh2r?a=view
      sysidcfg = <<-CFG
network_interface=NONE {
  hostname=web1
  protocol_ipv6=no
}
system_locale=C
terminal=xterms
security_policy=NONE
name_service=DNS {
  domain_name=example.com
  name_server=10.0.0.140,192.168.0.1,192.168.0.4
}
timezone=Europe/Berlin
root_password=ASDF§$%
nfs4_domain=dynamic
      CFG
      @zone.should_receive(:assure).with(:file, "/zones/web1/root/etc/sysidcfg", sysidcfg, {:name_server => ["10.0.0.140", "192.168.0.1", "192.168.0.4"], :domain => "example.com"})
      @zone.configure_system_id("web1", {:name_server => ["10.0.0.140", "192.168.0.1", "192.168.0.4"], :domain => "example.com"})
    end
    
    it "should be able to deal with missing domain and name servers using default values instead" do
      @zone.stub!(:assure)
      sysidcfg = <<-CFG
network_interface=NONE {
  hostname=web1
  protocol_ipv6=no
}
system_locale=C
terminal=xterms
security_policy=NONE
name_service=DNS {
  domain_name=
  name_server=
}
timezone=Europe/Berlin
root_password=ASDF§$%
nfs4_domain=dynamic
      CFG
      @zone.should_receive(:assure).with(:file, "/zones/web1/root/etc/sysidcfg", sysidcfg, {})
      @zone.configure_system_id("web1")
    end

    it "should upload a correct resolv.conf" do
      @zone.stub!(:assure)
      resolv_conf = <<-RES
domain example.com
nameserver 10.0.0.140
nameserver 192.168.0.1
nameserver 192.168.0.4
      RES
      @zone.should_receive(:assure).with(:file, "/zones/web1/root/etc/resolv.conf", resolv_conf, {:name_server => ["10.0.0.140", "192.168.0.1", "192.168.0.4"], :domain => "example.com"})
      @zone.configure_system_id("web1", {:name_server => ["10.0.0.140", "192.168.0.1", "192.168.0.4"], :domain => "example.com"})
    end
    
    it "should make sure the corrct nsswitch.conf is used" do
      @zone.should_receive(:pfexec).with("cp /zones/web1/root/etc/nsswitch.dns /zones/web1/root/etc/nsswitch.conf", {})
      @zone.configure_system_id("web1")
    end

    it "should be able to deal with a single name_server instead of an array" do
      @zone.stub!(:assure)
      sysidcfg = <<-CFG
network_interface=NONE {
  hostname=web1
  protocol_ipv6=no
}
system_locale=C
terminal=xterms
security_policy=NONE
name_service=DNS {
  domain_name=example.com
  name_server=10.0.0.140
}
timezone=Europe/Berlin
root_password=ASDF§$%
nfs4_domain=dynamic
      CFG
      @zone.should_receive(:assure).with(:file, "/zones/web1/root/etc/sysidcfg", sysidcfg, {:name_server => "10.0.0.140", :domain => "example.com"})
      @zone.configure_system_id("web1", {:name_server => "10.0.0.140", :domain => "example.com"})
    end
    
    it "should enable the dns/client service after configuring DNS settings" do
      @svc.should_receive(:enable).with("network/dns/client", {:via => :zlogin, :zone => "web1", :name_server => "10.0.0.140", :domain => "example.com"})
      @zone.configure_system_id("web1", {:name_server => "10.0.0.140", :domain => "example.com"})
    end
  end
  
  describe "- exists? method" do
    it "should be there" do
      @zone.respond_to?(:exists?).should be(true)
    end
    
    it "should return true, if the zone exists" do
      @zone.should_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 list", {}).and_return(true)
      @zone.exists?("web1").should be(true)
    end
    
    it "should return false, if the command fails" do
      @zone.should_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 list", {}).and_raise(Capistrano::CommandError)
      @zone.exists?("web1").should be(false)
    end
  end
  
  describe "- start method" do
    
    it "should start the zone" do
      @zone.should_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 boot", {})
      @zone.start("web1")
    end
  end

  describe "- restart method" do
    it "should restart the zone if already running" do
      @zone.should_receive(:pfexec).with("/usr/sbin/zoneadm -z web1 reboot", {})
      @zone.restart("web1")
    end
  end
  
  describe "- stop method" do
    it "should stop the zone, if it is running" do
      @zone.should_receive(:state).with("web1", {}).and_return("running")
      @zone.should_receive(:pfexec).with("/usr/sbin/zlogin web1 halt", {})
      @zone.stop("web1")
    end
    
    it "should not attempt to stop the zone if it is not running" do
      @zone.should_receive(:state).with("web1", {}).and_return("installed")
      @zone.should_not_receive(:pfexec).with("zlogin web1 halt", {})
      @zone.stop("web1")
    end
  end
  
  describe "- state method" do
    it "should return the state of a zone" do
      @zone.should_receive(:capture).with("/usr/sbin/zoneadm -z web1 list -p | cut -d':' -f 3", {}).and_return("running")
      @zone.state("web1")
    end
    
    it "should cut off any superfluous white spaces off the captured state string" do
      @zone.stub!(:capture).and_return("running ")
      @zone.state("web1").should eql("running")
    end
  end
end
