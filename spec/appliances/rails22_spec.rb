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
  
  it "should assure the rspec gem" do
    @config.should_receive(:assure).with(:gem, "rspec", "1.1.12")
    @config.load do
      rails22
    end
  end
  
  it "should assure the rspec-rails gem" do
    @config.should_receive(:assure).with(:gem, "rspec-rails", "1.1.12")
    @config.load do
      rails22
    end
  end
  
  it "should assure the cucumber gem" do
    @config.should_receive(:assure).with(:gem, "cucumber", "0.1.15")
    @config.load do
      rails22
    end
  end
  
  it "should patch rails for OpenSolaris" do
    @config.should_receive(:patch_inflector_rb)
    @config.load do
      rails22
    end
  end
  
  it "should upload the patch file" do
    patch = <<-PATCH
    275a276
    >     rescue Iconv::InvalidEncoding
    PATCH
    @config.should_receive(:pf_put).with(patch, "patch.txt")
    @config.load do
      patch_inflector_rb
    end
  end
  
  it "should capture the gemdir" do
    @config.should_receive(:capture).with("gem env gemdir")
    @config.load do
      patch_inflector_rb
    end
  end
  
  it "should apply the patch file" do
    gemdir = "a/path/to/gems"
    @config.stub!(:capture).and_return(gemdir)
    @config.stub!(:invoke_command)
    @config.should_receive(:invoke_command).with("sudo patch -i patch.txt #{gemdir}/gems/activesupport-2.2.2/lib/active_support/inflector.rb")
    @config.load do
      patch_inflector_rb
    end
  end

  it "should delete the patch file after applying it"
end