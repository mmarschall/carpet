require File.dirname(__FILE__) + '/../spec_helper'

describe "zfs plugin" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @zfs = @config.zfs
  end
  
  it "should destroy the filesystem" do
    @zfs.should_receive(:pfexec).with("/usr/sbin/zfs destroy -rf web1", {})
    @zfs.destroy("web1")
  end
  
  it "should read a filesystem property" do
    @zfs.should_receive(:capture).with("/usr/sbin/zfs get quota web1", {}).and_return("NAME          PROPERTY  VALUE         SOURCE
    rpool/export  quota     none          default
    ")
    @zfs.property("web1", "quota").should eql("none")
  end
  
  it "should set multiple filesystem properties" do
    @zfs.should_receive(:set_property).with("web1", :quota, "20G", {})
    @zfs.should_receive(:set_property).with("web1", :atime, "off", {})
    @zfs.set_properties("web1", :quota => "20G", :atime => "off")
  end
  
  it "should set a filesystem property" do
    @zfs.should_receive(:pfexec).with("/usr/sbin/zfs set quota=20G web1", {})
    @zfs.set_property("web1", "quota", "20G")
  end
  
  describe "- create method" do
    it "should create a non existing filesystem" do
      @zfs.should_receive(:exists?).with("web1", {}).and_return(false)
      @zfs.should_receive(:pfexec).with("/usr/sbin/zfs create web1", {})
      @zfs.create("web1")
    end
    
    it "should not try to create an existing filesystem" do
      @zfs.should_receive(:exists?).with("web1", {}).and_return(true)
      @zfs.should_not_receive(:pfexec).with("/usr/sbin/zfs create web1", {})
      @zfs.create("web1")
    end
    
    it "should set all given properties" do
      @zfs.should_receive(:set_properties).with("web1", {:quota => "20G", :atime => "off"}, {})
      @zfs.create("web1", :quota => "20G", :atime => "off")
    end
    
    it "should not attempt to set properties, if none are given" do
      @zfs.should_not_receive(:set_properties)
      @zfs.create("web1")
    end
  end

  describe "- exists? method" do
    it "should return true, if the zfs filesystem exists" do
      @zfs.should_receive(:run).with("/usr/sbin/zfs list -t snapshot,filesystem,volume web1", {}).and_return(true)
      @zfs.exists?("web1").should be(true)
    end
    
    it "should return false, if the zfs filesysetm does not exist" do
      @zfs.should_receive(:run).with("/usr/sbin/zfs list -t snapshot,filesystem,volume web1", {}).and_raise(Capistrano::CommandError)
      @zfs.exists?("web1").should be(false)
    end
  end
  
  describe "- share method" do
    it "should set the sharenfs property to on" do
      @zfs.should_receive(:set_property).with("rpool/export/users", "sharenfs", "on", {})
      @zfs.share("rpool/export/users")
    end
  end
end
