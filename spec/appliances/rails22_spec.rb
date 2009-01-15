require File.dirname(__FILE__) + '/../spec_helper'

describe "rails appliance recipe" do
  
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:run)
    @config.stub!(:put)
    @config.stub!(:assure)
    @config.stub!(:needs)
    @config.stub!(:application_user).and_return("appuser")
    @config.stub!(:shared_path).and_return("/a/path/shared")
    @svc = @config.svc
  end
  
  it "should assure that ruby is installed" do
    @config.should_receive(:assure).with(:command, :ruby)
    @config.load do
      rails22
    end
  end
  
  it "should assure SUNWimagick" do
    @config.should_receive(:assure).with(:package, "SUNWimagick")
    @config.load do
      rails22
    end
  end
  
  it "should assure SUNWmysql5" do
    @config.should_receive(:assure).with(:package, "SUNWmysql5")
    @config.load do
      rails22
    end
  end

  it "should assure SUNWsvn" do
    @config.should_receive(:assure).with(:package, "SUNWsvn")
    @config.load do
      rails22
    end
  end

  it "should assure the mini_magick gem" do
    @config.should_receive(:assure).with(:gem, "mini_magick", "1.2.3")
    @config.load do
      rails22
    end
  end
  
  it "should assure the rubyzip gem" do
    @config.should_receive(:assure).with(:gem, "rubyzip", "0.9.1")
    @config.load do
      rails22
    end
  end
  
  it "should assure the rails gem" do
    @config.should_receive(:assure).with(:gem, "rails", "2.2.2")
    @config.load do
      rails22
    end
  end
  
  it "should assure the memcache-client gem" do
    @config.should_receive(:assure).with(:gem, "memcache-client", "1.5.0")
    @config.load do
      rails22
    end
  end
  
  it "should assure the fastercsv gem" do
    @config.should_receive(:assure).with(:gem, "fastercsv", "1.4.0")
    @config.load do
      rails22
    end
  end
  
  it "should assure the mysql gem" do
    @config.should_receive(:assure).with(:gem, "mysql", "2.7", :gem_opts => "-- --with-mysql-dir=/usr/mysql")
    @config.load do
      rails22
    end
  end
  
  it "should assure the mongrel gem" do
    @config.should_receive(:assure).with(:gem, "mongrel", "1.1.5")
    @config.load do
      rails22
    end
  end
  
  it "should assure the mongrel_cluster gem" do
    @config.should_receive(:assure).with(:gem, "mongrel_cluster", "1.0.5")
    @config.load do
      rails22
    end
  end
end