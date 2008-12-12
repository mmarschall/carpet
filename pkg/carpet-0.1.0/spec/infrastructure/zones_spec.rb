require File.dirname(__FILE__) + '/../spec_helper'

describe "zone infrastructure recipe" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @config.stub!(:put)
    @config.stub!(:assure)
    @config.stub!(:application_user).and_return('carpet')

    @pkg = @config.pkg
    
    @adm = @config.adm

    @zfs = @config.zfs
    @zfs.stub!(:create)

    @zone = @config.zone
    @zone.stub!(:pfexec)
    @zone.stub!(:wait_for_ssh_ready)
    @zone.stub!(:assure)
    @zone.stub!(:configure_system_id)
    

    @svc = @config.svc
  end
  
  describe "a_zone task" do
    before do
      @zone.stub!(:host_configured?).and_return(true)
      @svc.stub!(:wait_for)
      @zone.stub!(:configure_system_id)
      @config.stub!(:zone_name).and_return("web1")
      @config.stub!(:zone_options).and_return({})
    end

    it "should assure rcap service" do
      @config.should_receive(:assure).with(:service, "system/rcap:default", :package => "SUNWrcap")
      @config.a_zone
    end
  
    it "should create the required zfs pools for the zones" do
      @zfs.should_receive(:create).with("rpool/zones", {:mountpoint => "/zones"})
      @config.a_zone
    end
  
    it "should create the zone configuration" do
      @zone.should_receive(:create_configuration).with("web1", {})
      @config.a_zone
    end

    it "should install the zone" do
      @zone.should_receive(:install).with("web1", {})
      @config.a_zone
    end
  
    it "should set the zone configuration values (memory, network, autoboot)" do
      @zone.should_receive(:configure_memory).with("web1", {})
      @zone.should_receive(:configure_net).with("web1", {})
      @zone.should_receive(:configure_autoboot).with("web1", true, {})
      @config.a_zone
    end
  
    it "should set the zones quota in zfs" do
      @zone.should_receive(:set_quota).with("web1", {})
      @config.a_zone
    end
  
    it "should configure the system id" do
      @zone.should_receive(:configure_system_id).with("web1", {})
      @config.a_zone
    end
    
    it "should assure that the application user is installed in the zone" do
      @config.stub!(:uid_for).and_return("104")
      @config.should_receive(:assure).with(:user, "carpet", {:sudoers => true, :profiles => "Primary Administrator", :via => :zlogin, :zone => "web1", :uid => "104"})
      @config.a_zone
    end

    it "should make sure that the man pages are installed" do
      @config.should_receive(:assure).with(:package, "SUNWman", {:via => :zlogin, :zone => "web1"})
      @config.a_zone
    end
    
    it "should make sure that less is installed" do
      @config.should_receive(:assure).with(:package, "SUNWless", {:via => :zlogin, :zone => "web1"})
      @config.a_zone
    end
    
    it "should make sure that the support for locales is installed" do
      @config.should_receive(:assure).with(:package, "SUNWloc", {:via => :zlogin, :zone => "web1"})
      @config.should_receive(:assure).with(:package, "SUNWuiu8", {:via => :zlogin, :zone => "web1"})
      @config.should_receive(:assure).with(:package, "SUNWlang-enUS", {:via => :zlogin, :zone => "web1"})
      @config.should_receive(:assure).with(:package, "SUNWlang-deDE", {:via => :zlogin, :zone => "web1"})
      @config.a_zone
    end
    
    it "should make sure that wget is installed" do
      @config.should_receive(:assure).with(:package, "SUNWwget", {:via => :zlogin, :zone => "web1"})
      @config.a_zone
    end
    
    it "should make sure that GNU tar is installed" do
      @config.should_receive(:assure).with(:package, "SUNWgtar", {:via => :zlogin, :zone => "web1"})
      @config.a_zone
    end
    
    it "should make sure that GNU grep is installed" do
      @config.should_receive(:assure).with(:package, "SUNWggrp", {:via => :zlogin, :zone => "web1"})
      @config.a_zone
    end

    it "should make sure that GNU ar is installed" do
      @config.should_receive(:assure).with(:package, "SUNWbtool", {:via => :zlogin, :zone => "web1"})
      @config.a_zone
    end
  end
end