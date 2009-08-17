require File.dirname(__FILE__) + '/../../spec_helper'

describe "RemoteDependency Extension" do
  
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @dep = Capistrano::Deploy::RemoteDependency.new(@config)
  end
  
  describe "(service dependency)" do
    before do
      @svc = @config.svc
      @svc.stub!(:online?).and_return(false)
    end
    
    it "should be successful, if service already online" do
      @svc.should_receive(:online?).with("network/ssh", {}).and_return(true)
      @dep.service("network/ssh")
    end
    
    it "should try to install given package, if service not online" do
      @dep.should_receive(:package).with("SUNWrcap", {})
      @dep.service("network/ssh", {:package => "SUNWrcap"})
    end
    
    it "should import the config for the new service" do
      @svc.should_receive(:import_cfg_for).with("network/ssh:default", {})
      @dep.service("network/ssh:default")
    end
    
    it "should import the correct config even if no service instance is provided" do
      @svc.should_receive(:import_cfg_for).with("network/ssh", {})
      @dep.service("network/ssh")
    end
    
    it "should enable the given service instance" do
      @svc.should_receive(:enable).with("network/ssh:default", {})
      @dep.service("network/ssh:default")
    end

    it "should set @success to true" do
      @dep.service("network/ssh")
      @dep.instance_variable_get(:@success).should be(true)
    end
    
    it "should return itself" do
      result = @dep.service("network/ssh")
      result.should be(@dep)
    end
  end
  
  describe "(file dependency)" do
    before do
      @false_dep = Capistrano::Deploy::RemoteDependency.new(@config)
      @false_dep.stub!(:pass?).and_return(false)
      @true_dep = Capistrano::Deploy::RemoteDependency.new(@config)
      @true_dep.stub!(:pass?).and_return(true)
      @dep.stub!(:check_for_file).and_return(@dep)
      @dep.stub!(:directory).and_return(@true_dep)
    end
    
    it "should check whether the file exists" do
      @dep.should_receive(:check_for_file).with("/bla/a.txt", {}).and_return(@dep)
      @dep.file("/bla/a.txt", "bla, bla")
    end
    
    it "should check whether the file content matches" do
      @dep.should_receive(:match).with("cat /bla/a.txt", "bla, bla", {}).and_return(@dep)
      @dep.file("/bla/a.txt", "bla, bla")
    end
    
    it "should put the file if it is not there" do
      @dep.stub!(:check_for_file).and_return(@false_dep)
      @config.should_receive(:pf_put).with("bla, bla", "/bla/a.txt", {})
      @dep.file("/bla/a.txt", "bla, bla")
    end
    
    it "should put the file if the content doesn't match" do
      @adm.stub!(:chkdir)
      @dep.stub!(:match).and_return(@false_dep)
      @config.should_receive(:pf_put).with("bla, bla", "/bla/a.txt", {})
      @dep.file("/bla/a.txt", "bla, bla")
    end
    
    it "should not put the file if file is there and content matches" do
      @dep.stub!(:check_for_file).and_return(@true_dep)
      @dep.stub!(:match).and_return(@true_dep)
      @config.should_not_receive(:pf_put).with("bla, bla", "/bla/a.txt", {})
      @dep.file("/bla/a.txt", "bla, bla")
    end
    
    it "should return itself when checking for a directory" do
      @config.stub!(:pf_put)
      result = @dep.file("/blah/a.txt", "bla, bla")
      result.should be(@dep)
    end
    
    it "should set @success to true" do
      @dep.directory("/blah")
      @dep.instance_variable_get(:@success).should be(true)
    end
  end

  describe "(gem dependency)" do
    before do
      @false_dep = Capistrano::Deploy::RemoteDependency.new(@config)
      @false_dep.stub!(:pass?).and_return(false)
      @true_dep = Capistrano::Deploy::RemoteDependency.new(@config)
      @true_dep.stub!(:pass?).and_return(true)
      @dep.stub!(:check_for_gem).and_return(@dep)
      @config.stub!(:fetch).with(:run_method, :sudo).and_return(:sudo)
    end
    
    it "should check whether the gem exists" do
      @dep.should_receive(:check_for_gem).with("rails", "2.1.2", {}).and_return(@dep)
      @dep.gem("rails", "2.1.2")
    end
    
    it "should install the gem if it is not there" do
      @dep.stub!(:check_for_gem).and_return(@false_dep)
      @config.should_receive(:invoke_command).with("gem install rails --no-rdoc --no-ri --version 2.1.2", {:via => :sudo})
      @dep.gem("rails", "2.1.2")
    end
    
    it "should install the gem using given run_method if it is not there" do
      @dep.stub!(:check_for_gem).and_return(@false_dep)
      @config.stub!(:fetch).with(:run_method, :sudo).and_return(:bla)
      @config.should_receive(:invoke_command).with("gem install rails --no-rdoc --no-ri --version 2.1.2", {:via => :bla})
      @dep.gem("rails", "2.1.2")
    end
    
    it "should pass given options to the gem install command" do
      @dep.stub!(:check_for_gem).and_return(@false_dep)
      @config.should_receive(:invoke_command).with("gem install mysql --no-rdoc --no-ri --version 2.7 -- --with-mysql-dir=/usr/mysql/5.0", {:via => :sudo})
      @dep.gem("mysql", "2.7", :gem_opts => "-- --with-mysql-dir=/usr/mysql/5.0")
    end
    
    it "should not try to install a gem if it is already there" do
      @dep.stub!(:check_for_gem).and_return(@true_dep)
      @config.should_not_receive(:invoke_command).with("gem install mysql --no-rdoc --no-ri --version 2.7", {:via => :sudo})
      @dep.gem("mysql", "2.7")
    end
    
    it "should return itself when checking for a gem" do
      result = @dep.gem("mysql", "2.7")
      result.should be(@dep)
    end
    
    it "should set @success to true" do
      @dep.gem("mysql", "2.7")
      @dep.instance_variable_get(:@success).should be(true)
    end
    
    it "should not kill a given :via option" do
      @dep.stub!(:check_for_gem).and_return(@false_dep)
      @config.should_receive(:invoke_command).with("gem install mysql --no-rdoc --no-ri --version 2.7", {:zone => "web1", :via => :zlogin})
      @dep.gem("mysql", "2.7", :via => :zlogin, :zone => "web1")
    end
    
  end

  describe "(package dependency)" do
    
    before do
      @pkg = @config.pkg
    end
    
    it "should check, whether the package is already installed using the pkg plugin" do
      @pkg.should_receive(:installed?).with("SUNWrcap", {})
      @dep.package("SUNWrcap")
    end
    
    it "should refresh the package list using the pkg plugin" do
      @pkg.stub!(:installed?).and_return(false)
      @pkg.should_receive(:refresh).with({})
      @dep.package("SUNWrcap")
    end
    
    it "should install the package using the pkg plugin" do
      @pkg.stub!(:installed?).and_return(false)
      @pkg.should_receive(:install).with("SUNWrcap", {})
      @dep.package("SUNWrcap")
    end
    
    it "should return itself" do
      result = @dep.package("SUNWrcap")
      result.should be(@dep)
    end
    
    it "should set @success to true" do
      @dep.package("SUNWrcap")
      @dep.instance_variable_get(:@success).should be(true)
    end
  end

  describe "(user dependency)" do
    before do
      @adm = @config.adm
      @adm.stub!(:useradd)
    end
    it "should try to create a user" do
      @adm.should_receive(:useradd).with("carpet", {})
      @dep.user("carpet")
    end
    
    it "should return itself when checking for a directory" do
      result = @dep.user("blah")
      result.should be(@dep)
    end
    
    it "should set @success to true" do
      @dep.user("blah")
      @dep.instance_variable_get(:@success).should be(true)
    end
  end
  
  describe "(directory dependency)" do
  
    before do
      @dir_check_dep = Capistrano::Deploy::RemoteDependency.new(@config)
      @dir_check_dep.stub!(:pass?).and_return(false)
      @dep.stub!(:check_for_directory).and_return(@dir_check_dep)
      @dep.stub!(:pass?).and_return(false)
      @adm = @config.adm
    end
    
    it "should verify given attributes" do
      @adm.should_receive(:chkdir).twice
      @dep.directory("/export/home/apl/.ssh", :owner => "carpet")
    end
    
    it "should not kill a given :via option" do
      @adm.should_receive(:chkdir).twice.with("/export/home/apl/.ssh", {:zone => "web1", :via => :zlogin})
      @dep.directory("/export/home/apl/.ssh", :via => :zlogin, :zone => "web1")
    end
    
    it "should attempt to create a directory" do
      @adm.stub!(:chkdir).and_return(false)
      @adm.should_receive(:mkdir).with("/blah", {})
      @dep.directory("/blah")
    end
    
    it "should set the dir variable" do
      @adm.stub!(:chkdir)
      @config.should_receive(:set).with(:dir, "/blah")
      @dep.directory("/blah")
    end
  
    it "should return itself when checking for a directory" do
      @adm.stub!(:chkdir)
      result = @dep.directory("/blah")
      result.should be(@dep)
    end
    
    it "should set @success to true" do
      @adm.stub!(:chkdir)
      @dep.directory("/blah")
      @dep.instance_variable_get(:@success).should be(true)
    end
    
    it "should accept the after_directory call and reset the dir var" do
      @adm.stub!(:chkdir)
      @config.should_receive(:unset).with(:dir)
      @dep.after_directory
    end
  end
end