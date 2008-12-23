require File.dirname(__FILE__) + '/../spec_helper'

describe "Src plugin" do
  before do
    @config = Capistrano::Configuration.new
    @config.load("spec/Capfile")
    @config.stub!(:invoke_command)
    @config.stub!(:run)
    @src = @config.src
  end
  
  describe "- install method" do
  
    it "should be there" do
      @src.respond_to?(:install).should be(true)
    end
  
    it "should take URL and options hash as parameters" do
      @src.install("url", {})
    end
    
    it "should assure, that there is a compiler installed" do
      @src.should_receive(:assure).with(:command, "cc")
      @src.install("url")
    end
    
    it "should download the source tarball" do
      @config.should_receive(:invoke_command).with("test -f ruby-1.8.7-p72.tar.gz || wget --progress=dot:mega -N ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz", {})
      @src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz")
    end
    
    it "should untar the .tar.gz tarball" do
      @config.should_receive(:invoke_command).with("/usr/gnu/bin/tar xzf ruby-1.8.7-p72.tar.gz", {})
      @src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz")
    end

    it "should untar the .tgz tarball" do
      @config.should_receive(:invoke_command).with("/usr/gnu/bin/tar xzf rubygems-1.3.1.tgz", {})
      @src.install("http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz")
    end
    
    it "should configure, make and install the src package" do
      @config.should_receive(:invoke_command).with("cd ruby-1.8.7-p72 && ./configure && make && pfexec make install", {})
      @src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz")
    end
    
    it "should accept and use configure options" do
      @config.should_receive(:invoke_command).with("cd ruby-1.8.7-p72 && ./configure --without-gcc && make && pfexec make install", {})
      @src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz", :configure_opts => "--without-gcc")
    end
    
    it "should use a provided install_cmd instead of the default configure/make/make install" do
      @config.should_receive(:invoke_command).with("cd ruby-1.8.7-p72 && ./setup.rb", {})
      @src.install("ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz", :install_cmd => "./setup.rb")
    end
  end
end
