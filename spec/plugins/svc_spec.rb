require File.dirname(__FILE__) + '/../spec_helper'

describe "Zone plugin" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @svc = @config.svc
    @svc.stub!(:pfexec)
  end
  
  describe "- enable method" do
    it "should enable a given service when svc:/ is omitted" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svcadm enable svc:/system/rcap:default", {})
      @svc.enable("system/rcap:default")
    end
    
    it "should enable a given service when svc:/ is passed" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svcadm enable svc:/system/rcap:default", {})
      @svc.enable("svc:/system/rcap:default")
    end
  end

  describe "- setprop method" do
    it "should set the given properties for service when svc:/ is omitted" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svccfg -s svc:/system/rcap:default setprop stop/exec = :kill", {})
      @svc.setprop("system/rcap:default", "stop/exec", ":kill")
    end
    
    it "should set the given properties for service when svc:/ is passed" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svccfg -s svc:/system/rcap:default setprop stop/exec = :kill", {})
      @svc.setprop("svc:/system/rcap:default", "stop/exec", ":kill")
    end
  end
  
  describe "- import_cfg_for method" do
    it "should import a given service config" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svccfg import /var/svc/manifest/system/rcap.xml", {})
      @svc.import_cfg_for("system/rcap")
    end
    
    it "should cut off the service instance from the service name, if it is 'default'" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svccfg import /var/svc/manifest/system/rcap.xml", {})
      @svc.import_cfg_for("system/rcap:default")
    end
    
    it "should replace the : with a -, if the service instance is other than 'default'" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svccfg import /var/svc/manifest/network/http-apache22.xml", {})
      @svc.import_cfg_for("network/http:apache22")
    end
  end
  
  describe "- refresh method" do
    it "should refresh the service config" do
      @svc.should_receive(:pfexec).with("/usr/sbin/svcadm refresh system/rcap", {})
      @svc.refresh("system/rcap")
    end
  end
  
  describe "- online? method" do
    it "should return true if a service is online" do
      @svc.should_receive(:capture).with("/usr/bin/svcs rcap", {}).and_return("STATE          STIME    FMRI
      online         Sep_10   svc:/system/rcap:default
      ")
      @svc.online?("rcap").should be(true)
    end
    
    it "should return false if the service is not there at all" do
      @svc.should_receive(:capture).with("/usr/bin/svcs rcap", {}).and_raise(Capistrano::CommandError)
      @svc.online?("rcap").should be(false)
    end

    it "should return false if a service is offline" do
      @svc.should_receive(:capture).with("/usr/bin/svcs rcap", {}).and_return("STATE          STIME    FMRI
      disabled         Sep_10   svc:/system/rcap:default
      ")
      @svc.online?("rcap").should be(false)
    end
  end
end
