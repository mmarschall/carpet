require File.dirname(__FILE__) + '/../spec_helper'

describe "Pkg plugin" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @pkg = @config.pkg
  end

  it "should refresh the package list" do
    @config.should_receive(:invoke_command).with("pfexec /usr/bin/pkg refresh", {})
    @pkg.refresh
  end
  
  it "should install a given package" do
    @config.should_receive(:invoke_command).with("pfexec /usr/bin/pkg install sunsolarisexpress", {})
    @pkg.install("sunsolarisexpress")
  end
  
  it "should find out, whether a package is installed" do
    @config.should_receive(:invoke_command).with("/usr/bin/pkg list sunsolarisexpress", {}).and_return(true)
    @pkg.installed?("sunsolarisexpress").should be(true)
  end
  
  it "should find out that a package is not installed" do
    @config.should_receive(:invoke_command).with("/usr/bin/pkg list sunsolarisexpress", {}).and_raise(Capistrano::CommandError)
    @pkg.installed?("sunsolarisexpress").should be(false)
  end
  
  it "should be able to add a new authority for getting packages" do
    @pkg.should_receive(:pfexec).with("/usr/bin/pkg set-authority -O http://pkg.sunfreeware.com:9000/ sunfreeware.com", {})
    @pkg.set_authority("sunfreeware.com", "http://pkg.sunfreeware.com:9000/")
  end
  
  it "should provide a helper to add sunfreeware authority" do
    @pkg.should_receive(:set_authority).with("sunfreeware.com", "http://pkg.sunfreeware.com:9000/", {})
    @pkg.add_sunfreeware
  end
  
  it "should be able to check for authorities" do
    @pkg.should_receive(:capture).with("pfexec /usr/bin/pkg authority", {}).and_return("")
    @pkg.authority?("sunfreeware.com")
  end

  it "should find out, that an authority is available" do
    @pkg.stub!(:capture).and_return("AUTHORITY                           URL
    opensolaris.org (preferred)         http://pkg.opensolaris.org:80/
    sunfreeware.com                     http://pkg.sunfreeware.com:9000/
    ")
    @pkg.authority?("sunfreeware.com").should be(true)
  end

  it "should find out, that an authority is not available" do
    @pkg.stub!(:capture).and_return("AUTHORITY                           URL
    opensolaris.org (preferred)         http://pkg.opensolaris.org:80/
    ")
    @pkg.authority?("sunfreeware.com").should be(false)
  end
end
