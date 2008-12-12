require File.dirname(__FILE__) + '/spec_helper'

describe "node definitions" do 
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
  end
  
  it "should make it possible, to describe a node having a name and a type" do
    @config.load do
      node 'apl1', :physical_node
    end
  end
  
  it "should make it possible to pass an parameter hash to the node" do
    @config.load do
      node '200', :physical_node, { :ipaddress => "10.20.2.200" }
    end
    @config.find_servers(:only => { :name => "200"})[0].options[:ipaddress].should eql("10.20.2.200")
  end
  
  it "should register a ServerDefinition for each node with the given ipaddress as name and the type as role" do
    @config.should_receive(:server).with("10.20.2.200", :physical_node, {:ipaddress => "10.20.2.200", :name => "apl1"})
    @config.load do
      node 'apl1', :physical_node, { :ipaddress => "10.20.2.200" }
    end
  end
  
  it "should register a task for configuring the node with the type as role" do
    @config.should_receive(:task).with("apl1", :roles => :physical_node)
    @config.load do
      node 'apl1', :physical_node
    end
  end
  
  it "should set the nfs_server variable, if the according parameter is given" do
    @config.should_receive(:set).with(:nfs_server, "100.200.300.400")
    @config.load do
      node 'apl1', :physical_node, { :nfs_server => true, :ipaddress => "100.200.300.400"}
    end
  end
end

describe "find_param_by_node_name" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.load do
      node 'gaga', :physical_node, { :ipaddress => "10.20.2.200" }
    end
  end

  it "should be able to find an existing node and return an existing parameter" do
    ipaddress = ""
    @config.load do
      ipaddress = find_param_by_node_name(:ipaddress, "gaga")
    end
    ipaddress.should eql("10.20.2.200")
  end
  
  it "should return nil if node not found" do
    ipaddress = ""
    @config.load do
      ipaddress = find_param_by_node_name(:whatever, "lalu")
    end
    ipaddress.should be(nil)
  end

  it "should return nil if the node is found but the param is not found" do
    ipaddress = ""
    @config.load do
      ipaddress = find_param_by_node_name(:notfound, "gaga")
    end
    ipaddress.should be(nil)
  end
end

describe "find_param" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.load do
      node 'gaga', :physical_node, { :ipaddress => "10.20.2.200" }
      node 'blubb', :app, { :ipaddress => "10.20.2.230"}
    end
  end

  it "should be able to find an existing node and return an existing parameter" do
    ipaddress = ""
    @config.load do
      ipaddress = find_param(:ipaddress, :only => { :name => "gaga"})
    end
    ipaddress.should eql("10.20.2.200")
  end
  
  it "should return nil if node not found" do
    ipaddress = ""
    @config.load do
      ipaddress = find_param(:whatever, :only => { :name => "lalu"})
    end
    ipaddress.should be(nil)
  end

  it "should return nil if the node is found but the param is not found" do
    ipaddress = ""
    @config.load do
      ipaddress = find_param(:notfound, :only => { :name => "gaga"})
    end
    ipaddress.should be(nil)
  end
  
  it "should be able to find an existing node and return an existing parameter even if HOSTS env is set" do
    ipaddress = ""
    @config.load do
      with_env("HOSTS", "10.20.2.230") do
        ipaddress = find_param(:ipaddress, :only => { :name => "gaga"})
      end
    end
    ipaddress.should eql("10.20.2.200")
  end
  
end

describe "find_node_by_param" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.load do
      node 'gaga', :physical_node, { :ipaddress => "10.20.2.200" }
      node 'blubb', :app, { :ipaddress => "10.20.2.230"}
    end
  end

  it "should find a node if param and value are ok" do
    node = nil
    @config.load do
      node = find_node_by_param(:ipaddress, "10.20.2.200")
    end
    node.options[:name].should eql("gaga")
  end
  
  it "should return nil, if the param value does not match" do
    node = nil
    @config.load do
      node = find_node_by_param(:ipaddress, "300.300.300.300")
    end
    node.should be(nil)
  end

  it "should return nil, if the there is no node with such a param" do
    node = nil
    @config.load do
      node = find_node_by_param(:notthere, "does_not_matter")
    end
    node.should be(nil)
  end
  
  it "should find the correct host even if HOSTS env is set" do
    node = nil
    @config.load do
      with_env("HOSTS", "10.20.2.230") do
        node = find_node_by_param(:ipaddress, "10.20.2.200")
      end
    end
    node.options[:name].should eql("gaga")
  end
end

describe "rake" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
  end
  
  it "should invoke the rake command" do
    @config.stub!(:deploy_env).and_return("testing")
    @config.stub!(:current_path).and_return("/current")
    @config.stub!(:fetch).and_return("my_rake")
    @config.should_receive(:invoke_command).with("cd /current; my_rake RAILS_ENV=testing go:west", {})
    @config.load do
      rake("go:west")
    end
  end
end

describe "current_host" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.load do
      node 'gaga', :physical_node, { :ipaddress => "10.20.2.200" }
      node 'blubb', :app, { :ipaddress => "10.20.2.230"}
    end
  end

  it "should find the host for the current task (assuming there is only one)" do
    host = nil
    ENV['HOSTS'] = "10.20.2.230"
    @config.load do
      task :bla do
        host = current_host
      end
      bla
    end
    host.should eql("10.20.2.230")
  end
end

describe "node task" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @config.stub!(:put)
  end

  describe "physical node" do
    before do
      @config.load do
        node 'apl1', :physical_node, { :ipaddress => "10.20.2.200" }
      end
    end
    
    it "should execute the task for configuring it's type" do
      @config.should_receive(:needs).with(:physical_node)
      @config.apl1
    end

    it "should make sure that the hosts env is set to ensure that subsequent tasks run only on the desired host(s)" do
      @config.should_receive(:with_env).with("HOSTS", "10.20.2.200")
      @config.apl1
    end
  end
  
  describe "virtual node" do
    before do
      @config.zone.stub!(:wait_for_ssh_ready)
      @config.load do
        node 'web1', :web, { 
          :hosted_on => 'apl1',
          :ipaddress => "10.20.2.230"
        }
      end
    end
    
    it "should execute the task for configuring it's host before it executes the task to configure it's type" do
      @config.should_receive(:needs).with('apl1').ordered
      @config.should_receive(:needs).with(:a_zone).ordered
      @config.should_receive(:needs).with(:web).ordered
      @config.web1
    end
  
    it "should make sure that there is a virtual machine/zone to run in, if hosted_on is set" do
      @config.stub!(:web)
      @config.stub!(:apl1)
      @config.stub!(:needs)
      @config.should_receive(:set).with(:zone_name, "web1")
      @config.should_receive(:set).with(:zone_options, {:hosted_on => 'apl1', :ipaddress => "10.20.2.230", :name => "web1"})
      @config.should_receive(:needs).with(:a_zone)
      @config.should_receive(:unset).with(:zone_name)
      @config.should_receive(:unset).with(:zone_options)
      @config.web1
    end
    
    it "should make sure, that first the host, then the zone and last the type are established" do
      @config.should_receive(:need_host_for_node).with("10.20.2.230", "apl1").ordered
      @config.should_receive(:assure_zone_on_host).with("web1", "apl1", { :hosted_on => 'apl1', :ipaddress => "10.20.2.230", :name => "web1" }).ordered
      @config.should_receive(:need_type).with("10.20.2.230", :web).ordered
      @config.web1
    end
    
    describe "need_host_for_node" do
      it "should set the HOSTS environment to the node's ipaddress to ensure subsequent tasks run on the correct box" do
        @config.should_receive(:with_env).with("HOSTS", "10.20.2.230")
        @config.load do
          need_host_for_node("10.20.2.230", "apl1")
        end
      end
    end
    
    describe "assure_zone_on_host" do
      it "should set the HOSTS environment to the ipaddress of the hosted_on box" do
        ENV["HOSTS"] = nil
        @config.load do
          node "virt", :web, {
            :hosted_on => "phys"
          }
          node "phys", :physical_node, { 
            :ipaddress => "10.20.2.200"
          }
        end
        @config.should_receive(:with_env).with("HOSTS", "10.20.2.200")
        @config.load do
          assure_zone_on_host("virt", "phys", {})
        end
      end
    end
    
    describe "need_type" do
      it "should set the HOSTS environment to the node's ipaddress" do
        @config.should_receive(:with_env).with("HOSTS", "10.20.2.230")
        @config.load do
          need_type("10.20.2.230", "web")
        end
      end
    end
  end
end

describe "type definitions" do 
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
  end
  
  it "should make it possible, to describe a type with a block" do
    @config.load do
      type :physical_node do
      end
    end
  end
  
  it "should create a task for each type with the type as role" do
    @config.should_receive(:task).with(:physical_node, :roles => :physical_node)
    @config.load do
      type :physical_node
    end
  end
  
  it "should create execute tasks for needs definitions" do
    @config.should_receive(:find_and_execute_task).with(:ruby)
    @config.load do
      needs :ruby
    end
  end
end

describe "zlogin" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
  end
  
  it "should be possible to issue calls with zlogin" do
    @config.should_receive(:run).with("/usr/sbin/zlogin web1 'hostname'", {:shell => "pfsh", :zone => "web1"})
    @config.load do
      zlogin("hostname", {:zone => "web1"})
    end
  end

  it "should pass a given block to the pfexec call (e.g. when calling capture(..., {:via => :zlogin, :zone => 'web1'}))" do
    block = Proc.new do a = 1 end
    @config.should_receive(:run).and_yield(block)
    @config.load do
      zlogin("hostname", {:zone => "web1"}, &block)
    end
  end
end

describe "pfexec" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @config.stub!(:put)
  end
  
  it "should be possible to issue calls with pfexec" do
    @config.should_receive(:run).with("pfexec ls -l", {:shell => "pfsh"})
    @config.load do
      pfexec("ls -l")
    end
  end

  it "should pass given blocks to the run method (e.g. when calling capture(..., :via => :pfexec))" do
    block = Proc.new do a = 1 end
    @config.should_receive(:run).and_yield(block)
    @config.load do
      pfexec("ls -l", &block)
    end
  end
  
  it "should keep the given option intact" do
    options = {:via => :zlogin, :zone => "web1"}
    @config.should_receive(:zlogin).with("pfexec ls -l", {:via => :zlogin, :zone => "web1"})
    @config.load do
      pfexec("ls -l", options)
    end
    options.should == {:via => :zlogin, :zone => "web1"}
  end
  
  it "should call zlogin if :via => :zlogin is given" do
    @config.should_receive(:zlogin).with("pfexec ls -l", {:via => :zlogin, :zone => "web1"})
    @config.load do
      pfexec("ls -l", {:via => :zlogin, :zone => "web1"})
    end
  end
end

describe "pf_put" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:pfexec)
    @config.stub!(:put)
    @adm = @config.adm
    @adm.stub!(:chgrp)
    @adm.stub!(:chown)
    @adm.stub!(:chmod)
  end
  
  describe " - directly to box" do
    it "should upload the given data to /tmp" do
      @config.should_receive(:put).with("bla, bla", "/tmp/bla.txt", {})
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt")
      end
    end
  
    it "should upload the given data to the given temp location" do
      @config.should_receive(:put).with("bla, bla", "/home/apl/temp/bla.txt", {})
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt", :tmp => "/home/apl/temp")
      end
    end
  
    it "should move the uploaded file from temp to final destination using pfexec" do
      @config.should_receive(:pfexec).with("mv /tmp/bla.txt /blubb/bla.txt", {})
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt")
      end
    end

    it "should change the owner of the file, if given" do
      @adm.should_receive(:chown).with("/blubb/bla.txt", :owner => "root")
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt", :owner => "root")
      end
    end

    it "should not pass any :via params to pfexec when moving" do
      @config.should_receive(:pfexec).with("mv /tmp/bla.txt /blubb/bla.txt", {})
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt")
      end
    end

    it "should not pass any :via params to pfexec when chown'ing" do
      @adm.should_receive(:chown).with("/blubb/bla.txt", :owner => "root")
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt", :owner => "root")
      end
    end

    it "should change the group of the file, if given" do
      @adm.should_receive(:chgrp).with("/blubb/bla.txt", :group => "root")
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt", :group => "root")
      end
    end
  
    it "should not attempt to change the group or owner of the file, if non given" do
      @config.should_not_receive(:chown)
      @config.should_not_receive(:chgrp)
      @config.should_not_receive(:chmod)
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt")
      end
    end
  end

  describe " - zlogin given: upload to zone" do
    it "should not pass any :via params to put (upload the file to the zone's host)" do
      @config.should_receive(:put).with("bla, bla", "/tmp/bla.txt", {})
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt", :via => :zlogin)
      end
    end
    
    it "should move the file to the target directory within the zone (on the zone's host)" do
      @config.should_receive(:pfexec).with("mv /tmp/bla.txt /zones/web1/root/blubb/bla.txt", {:zone => "web1"})
      @config.load do
        pf_put("bla, bla", "/blubb/bla.txt", {:via => :zlogin, :zone => "web1"})
      end
    end
  end
end

describe "render" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:pfexec)
    @config.stub!(:put)
  end
  
  it "should load a ERB template and execute it" do
    File.should_receive(:read).with("bla.erb").and_return('bla <%= number %>')
    result = ""
    @config.load do
      result = render("bla.erb", :number => 1)
    end
    result.should eql("bla 1")
  end
end

describe "schedule_rake_task" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:deploy_env).and_return("testing")
    @config.stub!(:current_path).and_return("/current")
    @config.stub!(:shared_path).and_return("/shared")
  end
  
  it "should return a crontab formatted line for a valid call to the given rake task" do
    crontab_line = "13 3 31 1 0 /usr/local/bin/ruby /usr/local/bin/rake RAILS_ENV=testing --trace --rakefile /current/Rakefile --libdir=/current cache:invalidate > /shared/log/crontab.log 2>&1\n"
    result = ""
    @config.load do
      result = schedule_rake_task("cache:invalidate", :minute => "13", :hour => "3", :day_of_month => "31", :month => "1", :day_of_week => "0")
    end
    result.should eql(crontab_line)
  end

  it "should fill in stars for not given params" do
    crontab_line = "* * * * * /usr/local/bin/ruby /usr/local/bin/rake RAILS_ENV=testing --trace --rakefile /current/Rakefile --libdir=/current cache:invalidate > /shared/log/crontab.log 2>&1\n"
    result = ""
    @config.load do
      result = schedule_rake_task("cache:invalidate")
    end
    result.should eql(crontab_line)
  end

  it "should be able to give only some params" do
    crontab_line = "* 3 * 1 * /usr/local/bin/ruby /usr/local/bin/rake RAILS_ENV=testing --trace --rakefile /current/Rakefile --libdir=/current cache:invalidate > /shared/log/crontab.log 2>&1\n"
    result = ""
    @config.load do
      result = schedule_rake_task("cache:invalidate", :hour => "3", :month => "1")
    end
    result.should eql(crontab_line)
  end
end

describe "assurances" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @dep = Capistrano::Deploy::RemoteDependency.new(@config)
    Capistrano::Deploy::RemoteDependency.should_receive(:new).with(@config).and_return(@dep)
    @dep.should_receive(:hamberger).with("cheese and bacon").and_return(@dep)
  end
  
  it "should be possible to assure a hamberger" do
    @config.load do
      assure :hamberger, "cheese and bacon"
    end
  end

  it "should try to yield a given block, if dependency does not pass" do
    @dep.stub!(:pass?).and_return(false)
    @config.should_receive(:run).with("ls -l")
    @config.load do
      assure :hamberger, "cheese and bacon" do
        run("ls -l")
      end
    end
  end
  
  it "should not yield a given block, if dependency does pass" do
    @dep.stub!(:pass?).and_return(true)
    @config.should_not_receive(:run)
    @config.load do
      assure :hamberger, "cheese and bacon" do
        run("ls -l")
      end
    end
  end
  
  it "should call the after_hamberger callback only if it is available" do
    @dep.should_receive(:after_hamberger)
    @dep.should_receive(:respond_to?).with("after_hamberger").and_return(true)
    @config.load do
      assure :hamberger, "cheese and bacon"
    end
  end
  
  it "should abort if no block given" do
    @dep.stub!(:pass?).and_return(false)
    @config.should_receive(:abort).with("hamberger dependency with [\"cheese and bacon\"] not met and no block given to resolve it!")
    @config.load do
      assure :hamberger, "cheese and bacon"
    end
  end
end